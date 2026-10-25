"""Regression tests for the source policy, independent of game execution."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from check_code_policy import check_source


class CodePolicyTest(unittest.TestCase):
    def test_explicit_types_and_json_boundary_are_allowed(self):
        source = """extends RefCounted
var state: Dictionary = {}
func read_value(value: Variant) -> Variant:
	for index: int in range(2):
		var caption: String = 'GameManager is just text'
	return value
"""
        self.assertEqual(check_source(source, "scripts/core/session/sample.gd"), [])

    def test_each_untyped_declaration_is_reported(self):
        for declaration in ["var value", "var value = 1", "var value := 1",
                            "signal changed(value)", "func read(value) -> void:\n\tpass",
                            "func read(value := 1) -> void:\n\tpass",
                            "func read() -> void:\n\tfor index in range(2):\n\t\tpass",
                            "func read() -> void:\n\tvar value := 1"]:
            with self.subTest(declaration=declaration):
                self.assertTrue(check_source("extends RefCounted\n" + declaration + "\n", "scripts/sample.gd"))

    def test_named_functions_require_a_return_type(self):
        self.assertTrue(check_source("func read():\n\tpass\n", "scripts/sample.gd"))

    def test_domain_cannot_depend_on_application_or_ui(self):
        for declaration in ["var view: Control", "func read() -> void:\n\tGameManager.quit_game()"]:
            with self.subTest(declaration=declaration):
                self.assertTrue(check_source(declaration + "\n", "scripts/core/session/sample.gd"))

    def test_files_are_owned_by_persistence(self):
        source = "func read() -> void:\n\tFileAccess.open('user://save.json', FileAccess.READ)\n"
        self.assertTrue(check_source(source, "scripts/core/session/sample.gd"))
        self.assertEqual(check_source(source, "scripts/core/persistence/sample.gd"), [])

    def test_retired_paths_are_rejected(self):
        self.assertTrue(check_source('extends "res://scripts/components/Old.gd"\n', "scripts/sample.gd"))


if __name__ == "__main__":
    unittest.main()
