"""Validación de las fronteras JSON del catálogo de diálogos."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from build_combination_dialogue import validate_task


class DialogueCatalogTest(unittest.TestCase):
    def setUp(self):
        self.bank = {
            "requests": ["Necesito una mesa.", "¿Me traes una mesa?", "Busco una mesa para dibujar."],
            "thanks": ["¡Gracias por la mesa!", "Ya puedo dibujar sobre la mesa."],
        }

    def test_separate_request_and_thanks_banks_are_valid(self):
        validate_task(self.bank, "Miis / mayak|")

    def test_flat_or_incomplete_banks_are_rejected(self):
        for bank in ([], ["Petición", "Alternativa", "Gracias"], {},
                     {"requests": self.bank["requests"]}, {**self.bank, "extra": []}):
            with self.subTest(bank=bank), self.assertRaises(ValueError):
                validate_task(bank, "Miis / mayak|")

    def test_every_nested_line_is_validated(self):
        for situation in ("requests", "thanks"):
            for invalid in (None, True, {}, [], 42, "", "   ", "x" * 161):
                with self.subTest(situation=situation, invalid=invalid):
                    bank = {key: lines.copy() for key, lines in self.bank.items()}
                    bank[situation][-1] = invalid
                    with self.assertRaises(ValueError):
                        validate_task(bank, "Miis / mayak|")

    def test_counts_and_duplicates_are_rejected_in_each_bank(self):
        for situation in ("requests", "thanks"):
            original = self.bank[situation]
            for invalid in (original[:-1], original + ["Otra frase."],
                            [original[0]] * len(original), "Texto sin lista"):
                with self.subTest(situation=situation, invalid=invalid):
                    with self.assertRaises(ValueError):
                        validate_task({**self.bank, situation: invalid}, "Miis / mayak|")


if __name__ == "__main__":
    unittest.main()
