"""Check portable resource references, script UIDs and local documentation links."""
from pathlib import Path, PurePosixPath
import re
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
SKIP = {".git", ".godot", ".ui-review", "builds", "export", "__pycache__"}


def exact_path(relative):
    current = ROOT
    for part in PurePosixPath(relative).parts:
        if part == ".":
            continue
        if part == "..":
            current = current.parent
            continue
        if not current.is_dir() or part not in {p.name for p in current.iterdir()}:
            return False
        current /= part
    return current.exists()


def main():
    errors, references, uid_owners = [], 0, {}
    files = [p for p in ROOT.rglob("*") if p.is_file() and not SKIP.intersection(p.relative_to(ROOT).parts)]
    for path in files:
        relative = path.relative_to(ROOT).as_posix()
        if path.suffix in {".gd", ".tscn", ".tres", ".godot"}:
            source = path.read_text(encoding="utf-8-sig")
            pattern = r'(?:\bpath\s*=\s*|\bpreload\(\s*|\bload\(\s*|\bextends\s*)["\x27](res://[^"\x27]+)["\x27]'
            for target in re.findall(pattern, source):
                if any(marker in target for marker in ["%", "{", "}"]):
                    continue
                references += 1
                if not exact_path(target[6:]):
                    errors.append(f"{relative}: ruta ausente o capitalización diferente: {target}")
            if path.suffix == ".godot":
                for target in re.findall(r'"\*?(res://[^"\n]+)"', source):
                    references += 1
                    if not exact_path(target[6:]):
                        errors.append(f"{relative}: configuración apunta a {target}")
        if path.suffix == ".gd" and relative.startswith(("scripts/", "tests/")):
            uid_path = Path(str(path) + ".uid")
            if not uid_path.is_file():
                errors.append(f"Falta el UID versionable: {relative}.uid")
            else:
                uid = uid_path.read_text(encoding="utf-8").strip()
                if uid in uid_owners:
                    errors.append(f"UID duplicado: {relative} y {uid_owners[uid]}")
                uid_owners[uid] = relative
        if path.suffix == ".md" and not relative.startswith("docs/reviews/"):
            for target in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding="utf-8-sig")):
                target = unquote(target.strip("<> ").split("#", 1)[0])
                if not target or re.match(r"^[a-z]+:", target) or target.startswith("/"):
                    continue
                if not (path.parent / target).exists():
                    errors.append(f"{relative}: enlace local roto: {target}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Estructura verificada: {references} referencias y {len(uid_owners)} UID de scripts.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
