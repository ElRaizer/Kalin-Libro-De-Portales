"""Compile the reviewed combination manifest into an exportable Godot catalogue."""
import argparse
from catalog_io import literal, read_manifest, write_generated


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = read_manifest("data/combinations/catalog.json")
    seen = set()
    for row in data["rows"]:
        if len(row) != 4 or not all(isinstance(value, str) for value in row):
            raise SystemExit("Cada combinación necesita palabra, cualidad y dos descripciones.")
        key = tuple(row[:2])
        if key in seen or row[0] not in data["basics"]:
            raise SystemExit(f"Combinación duplicada o desconocida: {key}")
        seen.add(key)
    content = (
        "## Generado por tools/build_combination_catalog.py; editar data/combinations/catalog.json.\n"
        "extends RefCounted\nclass_name CombinationData\n\nconst ROWS := [\n"
        + "".join("\t" + literal(row) + ",\n" for row in data["rows"])
        + "]\nconst BASICS := " + literal(data["basics"]) + "\n"
    )
    write_generated("scripts/core/content/combination_data.gd", content, args.check)
    print(f"Combinaciones verificadas: {len(seen)}.")


if __name__ == "__main__":
    main()
