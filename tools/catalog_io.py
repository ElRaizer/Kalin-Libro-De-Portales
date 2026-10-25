"""Shared deterministic output policy for reviewed content generators."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_manifest(relative):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def literal(value):
    return json.dumps(value, ensure_ascii=False, separators=(", ", ": "))


def write_generated(relative, content, check=False):
    target = ROOT / relative
    if check:
        if not target.is_file() or target.read_text(encoding="utf-8") != content:
            raise SystemExit(f"Contenido desactualizado: {relative}. Ejecuta su generador.")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8", newline="\n")
