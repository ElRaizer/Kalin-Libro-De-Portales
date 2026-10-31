"""SVG art for «Las piedras que cuentan» (Mundo 4 · Nivel 2).

The look references Maya screenfold codices: amate paper, red register lines,
black outlines, Maya blue, ochre and dot-and-bar numerals. Shapes stay flat
like the rest of the project; transparency uses fill-opacity, never rgba().
Run from any folder: python tools/build_counting_art.py
"""
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
NUMBERS = ROOT / "Arte/numeros"
BACKGROUNDS = ROOT / "Arte/backgrounds"

PAPER = "#EAD7A8"
PAPER_DARK = "#D8BF88"
FIBER = "#B89A62"
RED = "#A8342A"
INK = "#2A1C14"
BLUE = "#4E9AA6"
OCHRE = "#D39B34"
GREEN = "#5E7F3C"
CREAM = "#F6E9C4"
CACAO = "#5B3420"
CACAO_LIGHT = "#8A5534"


def svg(width: int, height: int, body: list[str]) -> str:
    head = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
    return "\n".join([head, *body, "</svg>"]) + "\n"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def cacao(cx: float, cy: float, scale: float = 1.0) -> str:
    """Grano de cacao: un punto del numeral (vale 1)."""
    rx, ry = 20 * scale, 13 * scale
    return (
        f'<g><ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{CACAO}" stroke="{INK}" stroke-width="{2.5 * scale:.1f}"/>'
        f'<path d="M{cx - rx * 0.7:.1f} {cy:.1f}Q{cx:.1f} {cy - ry * 0.55:.1f} {cx + rx * 0.7:.1f} {cy:.1f}" stroke="{CACAO_LIGHT}" stroke-width="{3 * scale:.1f}" fill="none" stroke-linecap="round"/>'
        f'<ellipse cx="{cx - rx * 0.35:.1f}" cy="{cy - ry * 0.45:.1f}" rx="{rx * 0.28:.1f}" ry="{ry * 0.2:.1f}" fill="{CREAM}" fill-opacity=".45"/></g>'
    )


def bar(cx: float, cy: float, width: float, scale: float = 1.0) -> str:
    """Varita pintada de rojo: una barra del numeral (vale 5)."""
    height = 22 * scale
    x = cx - width / 2
    y = cy - height / 2
    return (
        f'<g><rect x="{x:.1f}" y="{y:.1f}" width="{width:.1f}" height="{height:.1f}" rx="{height / 2:.1f}" fill="{RED}" stroke="{INK}" stroke-width="{2.5 * scale:.1f}"/>'
        f'<path d="M{x + 12 * scale:.1f} {y + height * 0.32:.1f}H{x + width - 12 * scale:.1f}" stroke="#D86A4E" stroke-width="{3 * scale:.1f}" stroke-linecap="round"/></g>'
    )


def numeral(cx: float, cy: float, value: int, scale: float = 1.0) -> list[str]:
    """Numeral maya: puntos arriba, barras abajo, centrado en (cx, cy)."""
    bars, dots = divmod(value, 5)
    width = 120 * scale
    row_gap = 34 * scale
    rows = bars + (1 if dots else 0)
    top = cy - (rows - 1) * row_gap / 2
    parts: list[str] = []
    if dots:
        spacing = 42 * scale
        start = cx - (dots - 1) * spacing / 2
        parts += [cacao(start + index * spacing, top, scale) for index in range(dots)]
        top += row_gap
    for index in range(bars):
        parts.append(bar(cx, top + index * row_gap, width, scale))
    return parts


def paper_fibers(
    rng: random.Random, width: int, height: int, count: int, left: float = 0, top: float = 0
) -> list[str]:
    parts = []
    for _ in range(count):
        length = rng.uniform(40, min(160, width * 0.6))
        x = left + rng.uniform(0, width - length)
        y = top + rng.uniform(8, height - 8)
        bend = rng.uniform(-10, 10)
        parts.append(
            f'<path d="M{x:.0f} {y:.0f}q{length / 2:.0f} {bend:.0f} {length:.0f} {rng.uniform(-6, 6):.0f}" stroke="{FIBER}" stroke-width="{rng.uniform(1, 2.6):.1f}" stroke-opacity=".28" fill="none" stroke-linecap="round"/>'
        )
    return parts


def shell(cx: float, cy: float, scale: float = 1.0) -> str:
    """Concha del cero, como en los códices: una concha alargada con su espiral."""
    rx, ry = 34 * scale, 20 * scale
    left, right = cx - rx, cx + rx
    return (
        f'<g><path d="M{left:.1f} {cy:.1f}Q{cx:.1f} {cy - ry * 2.1:.1f} {right:.1f} {cy:.1f}Q{cx:.1f} {cy + ry * 1.5:.1f} {left:.1f} {cy:.1f}Z" fill="{CREAM}" stroke="{INK}" stroke-width="{2.5 * scale:.1f}" stroke-linejoin="round"/>'
        f'<path d="M{left + rx * 0.35:.1f} {cy - ry * 0.15:.1f}Q{cx:.1f} {cy - ry * 1.2:.1f} {right - rx * 0.35:.1f} {cy - ry * 0.15:.1f}" stroke="{BLUE}" stroke-width="{3 * scale:.1f}" fill="none" stroke-linecap="round"/>'
        f'<path d="M{left + rx * 0.6:.1f} {cy + ry * 0.25:.1f}Q{cx:.1f} {cy - ry * 0.35:.1f} {right - rx * 0.6:.1f} {cy + ry * 0.25:.1f}" stroke="{INK}" stroke-width="{2 * scale:.1f}" stroke-opacity=".6" fill="none" stroke-linecap="round"/>'
        f'<circle cx="{right - rx * 0.12:.1f}" cy="{cy - ry * 0.05:.1f}" r="{4 * scale:.1f}" fill="{INK}"/></g>'
    )


def pieces() -> None:
    write(NUMBERS / "pieza_cacao.svg", svg(64, 48, [cacao(32, 24, 1.3)]))
    write(NUMBERS / "pieza_barra.svg", svg(176, 44, [bar(88, 22, 160, 1.4)]))
    write(NUMBERS / "pieza_concha.svg", svg(96, 64, [shell(48, 34, 1.25)]))


def tablet() -> str:
    """Tablilla de dos pisos: arriba las veintenas, abajo las unidades."""
    body = [
        '<ellipse cx="210" cy="272" rx="190" ry="10" fill="#4A3016" fill-opacity=".14"/>',
        f'<rect x="10" y="8" width="400" height="256" rx="24" fill="{PAPER}" stroke="{RED}" stroke-width="8"/>',
        f'<rect x="26" y="22" width="368" height="74" rx="14" fill="{PAPER_DARK}" fill-opacity=".45" stroke="{INK}" stroke-width="2" stroke-opacity=".35"/>',
        f'<rect x="26" y="118" width="368" height="132" rx="14" fill="{PAPER_DARK}" fill-opacity=".45" stroke="{INK}" stroke-width="2" stroke-opacity=".35"/>',
        f'<path d="M14 107H406" stroke="{RED}" stroke-width="6"/>',
    ]
    body += paper_fibers(random.Random(7), 360, 220, 20, 30, 26)
    return svg(420, 280, body)


# ─── Fondo tipo códice ───────────────────────────────────────────────────────
def thatch_stall(x: float, base: float, width: float, roof: str, cloth: str) -> list[str]:
    parts = [
        f'<path d="M{x + 14} {base}V{base - 150}M{x + width - 14} {base}V{base - 150}" stroke="{INK}" stroke-width="8"/>',
        f'<path d="M{x - 18} {base - 140}L{x + width / 2} {base - 214}L{x + width + 18} {base - 140}Z" fill="{roof}" stroke="{INK}" stroke-width="4"/>',
    ]
    for offset in range(0, int(width) + 30, 22):
        parts.append(f'<path d="M{x - 10 + offset} {base - 144}l6 -14" stroke="{INK}" stroke-width="2" stroke-opacity=".5"/>')
    parts += [
        f'<rect x="{x}" y="{base - 62}" width="{width}" height="44" rx="6" fill="{cloth}" stroke="{INK}" stroke-width="4"/>',
        f'<path d="M{x + 8} {base - 40}H{x + width - 8}" stroke="{CREAM}" stroke-width="4" stroke-dasharray="10 8"/>',
    ]
    # Montones de fruta y semillas sobre la mesa del puesto.
    for index in range(3):
        cx = x + width * (index + 1) / 4
        parts.append(f'<ellipse cx="{cx:.0f}" cy="{base - 70}" rx="22" ry="14" fill="{[OCHRE, GREEN, RED][index]}" stroke="{INK}" stroke-width="3"/>')
    return parts


def ceiba(cx: float, base: float) -> list[str]:
    parts = [
        f'<path d="M{cx - 18} {base}Q{cx - 8} {base - 120} {cx - 10} {base - 230}H{cx + 10}Q{cx + 8} {base - 120} {cx + 18} {base}Z" fill="{GREEN}" stroke="{INK}" stroke-width="4"/>',
    ]
    for side in (-1, 1):
        parts.append(
            f'<path d="M{cx} {base - 200}Q{cx + side * 70} {base - 220} {cx + side * 120} {base - 290}" stroke="{GREEN}" stroke-width="16" fill="none" stroke-linecap="round"/>'
        )
        parts.append(
            f'<path d="M{cx} {base - 200}Q{cx + side * 70} {base - 220} {cx + side * 120} {base - 290}" stroke="{INK}" stroke-width="3" fill="none" stroke-opacity=".6"/>'
        )
        for step in range(3):
            leaf_x = cx + side * (60 + step * 30)
            leaf_y = base - 236 - step * 20
            parts.append(f'<ellipse cx="{leaf_x}" cy="{leaf_y}" rx="22" ry="12" fill="{BLUE}" stroke="{INK}" stroke-width="3" transform="rotate({side * -25} {leaf_x} {leaf_y})"/>')
    parts.append(f'<ellipse cx="{cx}" cy="{base - 258}" rx="30" ry="18" fill="{BLUE}" stroke="{INK}" stroke-width="3"/>')
    return parts


def codex_background() -> str:
    rng = random.Random(20261028)
    body = [
        f'<rect width="1280" height="720" fill="{PAPER}"/>',
        f'<rect y="560" width="1280" height="160" fill="{PAPER_DARK}"/>',
    ]
    body += paper_fibers(rng, 1280, 720, 140)
    # Pliegues del biombo: el códice se lee por páginas.
    for x in (320, 640, 960):
        body.append(f'<path d="M{x} 0V720" stroke="{FIBER}" stroke-width="5" stroke-opacity=".35"/>')
        body.append(f'<path d="M{x + 6} 0V720" stroke="{CREAM}" stroke-width="3" stroke-opacity=".5"/>')
    # Registros rojos que dividen la página, como en los códices.
    for y in (96, 548):
        body.append(f'<path d="M0 {y}H1280" stroke="{RED}" stroke-width="10"/>')
        body.append(f'<path d="M0 {y + 12}H1280" stroke="{INK}" stroke-width="2" stroke-opacity=".5"/>')
    # Banda superior: cartuchos con numerales del uno al cinco, repetidos.
    for index in range(14):
        x = 14 + index * 91
        body.append(f'<rect x="{x}" y="12" width="80" height="74" rx="14" fill="{CREAM}" stroke="{RED}" stroke-width="4"/>')
        body += numeral(x + 40, 49, index % 5 + 1, 0.42)
    # Escena del tianguis: ceiba al centro, puestos a los lados, sol k'in.
    body += ceiba(640, 548)
    body += thatch_stall(90, 548, 210, OCHRE, BLUE)
    body += thatch_stall(360, 548, 170, GREEN, RED)
    body += thatch_stall(760, 548, 170, RED, OCHRE)
    body += thatch_stall(990, 548, 210, BLUE, GREEN)
    body.append(f'<circle cx="1150" cy="170" r="40" fill="{OCHRE}" stroke="{INK}" stroke-width="4"/>')
    # Signo k'in: el sol con cuatro pétalos unidos al disco.
    for angle in range(45, 360, 90):
        body.append(f'<path d="M1150 132q-22 -26 0 -46q22 20 0 46z" fill="{RED}" stroke="{INK}" stroke-width="3" transform="rotate({angle} 1150 170)"/>')
    body.append(f'<circle cx="1150" cy="170" r="14" fill="{CREAM}" stroke="{INK}" stroke-width="3"/>')
    # Banda inferior: huellas de pies, el signo de camino de los códices.
    for index in range(22):
        x = 30 + index * 58
        y = 640 + (index % 2) * 22
        body.append(f'<ellipse cx="{x}" cy="{y}" rx="11" ry="17" fill="{INK}" fill-opacity=".55"/>')
        body += [f'<circle cx="{x - 8 + toe * 5}" cy="{y - 22}" r="3" fill="{INK}" fill-opacity=".55"/>' for toe in range(4)]
    return svg(1280, 720, body)


def main() -> None:
    pieces()
    write(NUMBERS / "tablilla.svg", tablet())
    write(BACKGROUNDS / "bg_codice_tianguis.svg", codex_background())
    print("Generado el arte de los números: 4 SVG y el fondo de códice.")


if __name__ == "__main__":
    main()
