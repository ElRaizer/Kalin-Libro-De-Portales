"""Enforce explicit GDScript types and dependency direction using the syntax tree."""
from pathlib import Path
import re
import sys

from gdtoolkit.parser import parser

ROOT = Path(__file__).resolve().parents[1]
UNTYPED_NODES = {
    "class_var_empty", "class_var_assigned", "class_var_inf",
    "func_var_empty", "func_var_assigned", "func_var_inf",
    "func_arg_regular", "func_arg_inf", "signal_arg_regular", "for_stmt",
}


def check_source(source: str, relative: str) -> list[str]:
    errors: list[str] = []
    tree = parser.parse(source, gather_metadata=True)
    for node in tree.iter_subtrees():
        if node.data in UNTYPED_NODES:
            errors.append(f"{relative}:{node.meta.line}: declara el tipo explícito de {node.children[0]}.")
        if node.data in {"func_header", "abstract_func_header"} and len(node.children) < 3:
            errors.append(f"{relative}:{node.meta.line}: declara el tipo de retorno de {node.children[0]}.")
    if relative.startswith("scripts/core/") or relative == "scripts/features/exercises/domain/phrase_exercise_session.gd":
        # Inspect syntax identifiers, so comments and player-facing text are irrelevant.
        names = {name for token in tree.scan_values(lambda value: getattr(value, "type", "") in {"NAME", "TYPE_HINT"})
                 for name in re.findall(r"\w+", str(token))}
        forbidden = names.intersection({"GameManager", "SceneTree", "FileAccess", "Control"})
        persistence = relative.startswith("scripts/core/persistence/")
        navigation = relative.startswith("scripts/core/navigation/")
        if persistence:
            forbidden.discard("FileAccess")
        if forbidden and not navigation:
            errors.append(f"{relative}: dependencia fuera de su responsabilidad: {', '.join(sorted(forbidden))}.")
    if relative.startswith(("scripts/", "tests/")):
        for resource in re.findall(r'["\'](res://(?:scripts|scenes)/[^"\']+)["\']', source):
            if re.match(r"res://scripts/(?:components|world[1-5])/", resource) or re.match(r"res://scenes/(?:components|world[1-5])/", resource):
                errors.append(f"{relative}: referencia a una estructura retirada: {resource}.")
    return errors


def main() -> int:
    errors: list[str] = []
    count = 0
    for folder in ("scripts", "tests", "tools"):
        for path in sorted((ROOT / folder).rglob("*.gd")):
            relative = path.relative_to(ROOT).as_posix()
            count += 1
            if not re.fullmatch(r"[a-z][a-z0-9_]*", path.stem):
                errors.append(f"{relative}: el archivo debe usar snake_case.")
            try:
                errors.extend(check_source(path.read_text(encoding="utf-8-sig"), relative))
            except Exception as error:
                errors.append(f"{relative}: no se pudo analizar: {error}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Política de código verificada: {count} scripts, tipos explícitos y límites de dependencias.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
