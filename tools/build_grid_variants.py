"""Compile and verify the 48 reviewed layouts without changing their IDs.

The historical search algorithm was absent from the repository. The recovered
source is the explicit, reviewed manifest; generating new geometries is a
separate authoring decision. This compiler validates witnesses and difficulty.
"""
import argparse
from catalog_io import literal, read_manifest, write_generated


def turns(route):
    steps = [(b[0] - a[0], b[1] - a[1]) for a, b in zip(route, route[1:])]
    if any(abs(x) + abs(y) != 1 for x, y in steps):
        raise ValueError("La ruta contiene celdas no adyacentes.")
    return sum(a != b for a, b in zip(steps, steps[1:]))


def validate(data):
    width, height = data["columns"], data["rows"]
    seen_ids = set()
    for level_id, level in data["levels"].items():
        geometries = set()
        for layout in level["variants"]:
            if layout["id"] in seen_ids:
                raise ValueError("ID de tablero duplicado: " + layout["id"])
            seen_ids.add(layout["id"])
            occupied = set(map(tuple, layout["obstacles"]))
            if len(occupied) != len(layout["obstacles"]):
                raise ValueError("Obstáculos duplicados.")
            if len(layout["solution"]) != 3 or len(layout["starts"]) != 3 or len(layout["goals"]) != 3:
                raise ValueError("Cada tablero necesita tres parejas y sus testigos.")
            lengths, corners = [], []
            for index, route in enumerate(layout["solution"]):
                if len(route) < 2 or route[0] != layout["starts"][index] or route[-1] != layout["goals"][index]:
                    raise ValueError("El testigo no une la pareja correspondiente.")
                lengths.append(len(route) - 1)
                corners.append(turns(route))
                for point in route:
                    cell = tuple(point)
                    if cell in occupied:
                        raise ValueError("El testigo cruza otro camino o un obstáculo.")
                    occupied.add(cell)
            if any(not (0 <= x < width and 0 <= y < height) for x, y in occupied):
                raise ValueError("Hay celdas fuera del tablero.")
            if layout["metrics"] != {"lengths": lengths, "turns": corners}:
                raise ValueError("Las métricas no coinciden con el testigo.")
            if len(layout["obstacles"]) != len(level["base"]["obstacles"]):
                raise ValueError("Cambió la densidad de obstáculos.")
            baseline = level["baseline_metrics"]
            if level_id == "1":
                if lengths[0] != 4 or corners[0] != 0 or sum(lengths) > 29 or max(corners) > 2:
                    raise ValueError("La introducción excede la dificultad acordada.")
            elif (abs(sum(lengths) - sum(baseline["lengths"])) > 4
                  or abs(sum(corners) - sum(baseline["turns"])) > 4
                  or max(lengths) > max(baseline["lengths"]) + 2
                  or max(corners) > max(baseline["turns"]) + 2):
                raise ValueError("La variante excede la dificultad acordada.")
            fingerprint = literal([layout["starts"], layout["goals"], layout["obstacles"]])
            if fingerprint in geometries:
                raise ValueError("Geometría duplicada en el nivel.")
            geometries.add(fingerprint)
    return len(seen_ids)


def render(data):
    lines = [
        "## Generado por tools/build_grid_variants.py; editar data/grid_variants/catalog.json.",
        "extends RefCounted", "class_name GridVariantCatalog", "", "const DATA: Dictionary = {",
        f'\t"version": {data["version"]},', f'\t"columns": {data["columns"]},',
        f'\t"rows": {data["rows"]},', '\t"levels": {',
    ]
    for key, level in data["levels"].items():
        lines.extend([
            f'\t\t"{key}": {{', '\t\t\t"base": ' + literal(level["base"]) + ',',
            '\t\t\t"baseline_metrics": ' + literal(level["baseline_metrics"]) + ',',
            '\t\t\t"variants": [',
            *("\t\t\t\t" + literal(layout) + "," for layout in level["variants"]),
            '\t\t\t],', '\t\t},',
        ])
    return "\n".join([*lines, '\t},', '}']) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = read_manifest("data/grid_variants/catalog.json")
    count = validate(data)
    write_generated("scripts/features/grid_paths/data/grid_variant_catalog.gd", render(data), args.check)
    print(f"Tableros verificados: {count}.")


if __name__ == "__main__":
    main()
