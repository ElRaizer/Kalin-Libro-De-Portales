"""Native SVG variants for the new, explicitly allowed combinations."""
from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Arte/aldea/uso"
ET.register_namespace("", "http://www.w3.org/2000/svg")
NS = "{http://www.w3.org/2000/svg}"


def write(name, node):
    (OUT / name).write_text(ET.tostring(node, encoding="unicode") + "\n", encoding="utf-8", newline="\n")


front = ET.parse(OUT / "hamaca_frente.svg").getroot()
rear = ET.parse(OUT / "hamaca_fondo.svg").getroot()
for quality, color in [("bonita", "#d77555"), ("fuerte", "#256e68")]:
    special = deepcopy(front)
    for child in special:
        if child.get("fill") == "#1b8580":
            child.set("fill", color)
    if quality == "fuerte":
        ET.SubElement(special, NS + "path", {"d": "M56 83Q120 130 184 83M65 103Q120 144 175 103", "fill": "none", "stroke": "#ebd5a2", "stroke-width": "7"})
    else:
        for x in [82, 108, 134, 160]:
            ET.SubElement(special, NS + "circle", {"cx": str(x), "cy": "112", "r": "4", "fill": "#f9d26d"})
    write(f"hamaca_frente_{quality}.svg", special)
    special = deepcopy(rear)
    if quality == "fuerte":
        ET.SubElement(special, NS + "path", {"d": "M24 43L64 81M216 43L176 81", "stroke": "#bca06b", "stroke-width": "9", "stroke-linecap": "round"})
    write(f"hamaca_{quality}.svg", special)
for quality in ["bonita", "fuerte"]:
    table = ET.parse(OUT / "mesa.svg").getroot()
    if quality == "fuerte":
        ET.SubElement(table, NS + "path", {"d": "M59 98L181 149M181 98L59 149", "stroke": "#986330", "stroke-width": "10", "stroke-linecap": "round"})
    else:
        ET.SubElement(table, NS + "path", {"d": "M47 67Q120 88 193 67", "fill": "none", "stroke": "#27867d", "stroke-width": "5"})
        for x in [67, 94, 121, 148, 175]:
            ET.SubElement(table, NS + "circle", {"cx": str(x), "cy": "63", "r": "4", "fill": "#f9d26d"})
    write(f"mesa_{quality}.svg", table)
for name, source in [("platano", "comida_jaas"), ("fruta", "comida_pakal"), ("calabaza", "comida_kuum")]:
    node = ET.parse(ROOT / f"Arte/ilustraciones/{source}.svg").getroot()
    for parent in node.iter():
        for child in list(parent):
            if child.tag == NS + "ellipse" and float(child.get("fill-opacity", 1)) < 1:
                parent.remove(child)
    write(f"{name}.svg", node)
print("Generadas 9 variantes SVG para las combinaciones nuevas.")
