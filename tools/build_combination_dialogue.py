"""Expand the closed catalogue into explicit, editable Spanish dialogue banks.

Existing authored lines are preserved. New lines combine a reviewed animal/object
scene with the exact request label; no anatomy or Maya morphology is generated.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORDS = ["mayak", "k'áanche'", "k'áan", "lak", "janal", "ja'", "ja'as", "ich", "K'úum"]
SCENES = {
    "Peek'": [
        "Recibiremos al grupo del paseo en mi porche.",
        "Quiero sentarme en mi porche a cuidar el camino.",
        "Descansaré mis patas después de recorrer el sendero.",
        "Voy a servir la merienda del grupo del paseo.",
        "Mis compañeros del paseo llegarán con hambre.",
        "Tengo sed después de recorrer los caminos.",
        "Quiero llevar un plátano para la merienda del paseo.",
        "Compartiremos fruta al volver del sendero.",
        "Prepararé calabaza para mis compañeros del paseo.",
    ],
    "Miis": [
        "La reunión de mis amigos será bajo mi balcón.",
        "Quiero sentarme a mirar el jardín desde mi entrada.",
        "Hoy tomaré mi siesta a la sombra del balcón.",
        "Voy a servir la merienda junto a la escalera del balcón.",
        "Mis visitas vendrán a comer bajo mi balcón.",
        "Jugué en el jardín y ahora tengo sed.",
        "Merendaré un plátano después de explorar el jardín.",
        "Invité a mis amigos a comer fruta bajo el balcón.",
        "Quiero compartir calabaza con las visitas de mi balcón.",
    ],
    "Kaax": [
        "Preparé un lugar para reunir a mis amigos junto al nido.",
        "Esperaré sentada junto al nido mientras llegan las visitas.",
        "Descansaré después de acomodar toda la paja de mi casa.",
        "La merienda de hoy se servirá junto a mi nido.",
        "Mis amigos vendrán a merendar a mi casa de paja.",
        "Ordené la paja y ahora quiero beber.",
        "Quiero un plátano para la merienda junto al nido.",
        "Compartiremos fruta con mis visitas junto a la casa.",
        "Hoy serviré calabaza a mis amigos cerca del nido.",
    ],
    "Áak": [
        "Mis amigos y yo comeremos al pie de mi rampa.",
        "Quiero sentarme con calma al pie de la rampa.",
        "Me acostaré a descansar después de mi paseo tranquilo.",
        "Voy a servir mi porción junto a mi casa bajita.",
        "Quiero compartir la merienda con las visitas de mi rampa.",
        "Acabo de volver despacio a casa y tengo sed.",
        "Quiero merendar un plátano a la sombra de mi casa.",
        "Mis visitas y yo comeremos fruta junto a la rampa.",
        "Compartiré calabaza con mis amigos de la casa bajita.",
    ],
    "Kéej": [
        "Mis amigos se reunirán a comer entre mis plantas.",
        "Quiero sentarme a mirar las hojas nuevas de mi jardín.",
        "Descansaré a la sombra después de recorrer el monte.",
        "Serviré la merienda junto a las plantas de mi entrada.",
        "Los amigos del monte llegarán con hambre a mi jardín.",
        "Cuidé las plantas de mi jardín y ahora tengo sed.",
        "Quiero llevar un plátano para merendar después del monte.",
        "Compartiremos fruta en el rincón de mis plantas.",
        "Mis amigos del monte vendrán a comer calabaza al jardín.",
    ],
    "K'éek'en": [
        "Invité a mis amigos a merendar junto a mis flores.",
        "Quiero sentarme frente a las flores de mi casa redonda.",
        "Descansaré después de trabajar en mi jardín de flores.",
        "Serviré la merienda en la entrada de mi casa redonda.",
        "Mis visitas llegarán a comer junto a mis flores.",
        "Terminé de cuidar mis flores y quiero beber.",
        "Merendaré un plátano junto a mi casa redonda.",
        "Quiero recibir a mis visitas con fruta en el jardín.",
        "Prepararé calabaza para compartir entre mis flores.",
    ],
    "Ma'ax": [
        "Bajaremos del árbol para comer al pie de mi escalera.",
        "Quiero sentarme bajo el árbol a recibir a mis visitas.",
        "Ya trepé mucho; descansaré junto a mi escalera de cuerda.",
        "La comida se servirá bajo las ramas de mi casa.",
        "Invité a mis amigos a bajar del árbol para merendar.",
        "Después de subir por mi escalera tengo sed.",
        "Quiero merendar un plátano a la sombra del árbol.",
        "Compartiré fruta con las visitas de mi casa del árbol.",
        "Hoy comeremos calabaza al pie de mi escalera.",
    ],
    "Kuuts": [
        "Los amigos del monte se reunirán junto a mis arbustos.",
        "Quiero sentarme a escuchar las hojas junto a mi casa.",
        "Descansaré después de buscar semillas entre los arbustos.",
        "Serviré la merienda junto a las hojas de mi entrada.",
        "Mis compañeros del monte llegarán con hambre a casa.",
        "Volví de caminar entre los arbustos y tengo sed.",
        "Quiero merendar un plátano junto a las hojas del monte.",
        "Mis compañeros del monte vendrán a compartir fruta.",
        "Compartiremos calabaza en mi rincón entre las hojas.",
    ],
    "Báalam": [
        "Recibiré a mis amigos a la sombra de mi casa de piedra.",
        "Quiero sentarme a cuidar la entrada del monte.",
        "Me acostaré en la sombra al regresar del monte.",
        "Serviré la merienda en mi rincón junto a las piedras.",
        "El grupo del monte vendrá a comer a mi casa de piedra.",
        "El paseo por el monte fue largo y ahora tengo sed.",
        "Quiero merendar un plátano en mi rincón de sombra.",
        "Mis amigos y yo compartiremos fruta junto a las piedras.",
        "Prepararé calabaza para las visitas de mi casa de piedra.",
    ],
    "T'u'ul": [
        "Mis amigos comerán en el jardín frente a mi madriguera.",
        "Quiero sentarme a descansar mis patas después de saltar.",
        "Me acostaré junto a mi madriguera después del paseo.",
        "La merienda se servirá entre las plantas del jardín.",
        "Mis visitas vendrán a comer junto a mi madriguera.",
        "Salté por todo el jardín y ahora quiero beber.",
        "Quiero merendar un plátano después de pasear por el jardín.",
        "Compartiremos fruta en la entrada de mi madriguera.",
        "Mis amigos vendrán a comer calabaza junto a mis plantas.",
    ],
    "Kay": [
        "Mis visitas de tierra comerán en la orilla de mi casa.",
        "Mis amigos se sentarán a conversar conmigo desde la orilla.",
        "Mis amigos de tierra descansarán junto a mi casa del agua.",
        "Serviremos la merienda a las visitas de la orilla.",
        "Quiero compartir comida con los amigos que llegan a la orilla.",
        "Mis visitas de la orilla llegarán con sed.",
        "Mis visitas compartirán un plátano junto al agua.",
        "Recibiré a mis amigos con fruta en la orilla.",
        "Prepararemos calabaza para mis visitas junto al agua.",
    ],
    "Ch'íich'": [
        "Mis amigos bajarán a comer junto a la percha de mi nido.",
        "Quiero sentarme bajo el nido a conversar con mis visitas.",
        "Descansaré bajo mi nido después de volar sobre la aldea.",
        "Serviré la merienda junto al poste de mi nido.",
        "Mis visitas vendrán a merendar bajo las ramas de mi casa.",
        "Volé sobre los techos y ahora tengo sed.",
        "Quiero merendar un plátano después de mi vuelo por la aldea.",
        "Compartiremos fruta bajo las ramas de mi nido.",
        "Mis amigos vendrán a comer calabaza junto a mi percha.",
    ],
}
PLACES = {
    "Peek'": "mi porche", "Miis": "mi balcón", "Kaax": "mi nido",
    "Áak": "mi rampa", "Kéej": "mis plantas", "K'éek'en": "mis flores",
    "Ma'ax": "mi árbol", "Kuuts": "los arbustos", "Báalam": "mi casa de piedra",
    "T'u'ul": "mi madriguera", "Kay": "la orilla", "Ch'íich'": "mi percha",
}


def literal(text):
    return json.loads(re.sub(r",\s*([}\]])", r"\1", text))


catalog = ROOT / "scripts/data/CombinationCatalog.gd"
source = catalog.read_text(encoding="utf-8")
rows = literal(source.split("const ROWS := ", 1)[1].split("\nconst BASICS", 1)[0].strip())
basics = literal(source.split("const BASICS := ", 1)[1].split("\nconst FURNITURE", 1)[0].strip())
path = ROOT / "data/dialogue/VillageDialogueCatalog.gd"
banks = literal(path.read_text(encoding="utf-8").split("const ANIMALS := ", 1)[1].strip())
targets = {word + "|": (word, "", need[0].upper() + need[1:], need) for word, need in basics.items()}
targets.update({word + "|" + quality: (word, quality, label, need) for word, quality, label, need in rows})
for animal, data in banks.items():
    place = PLACES[animal]
    for key, (word, quality, label, need) in targets.items():
        if key in data["tasks"]:
            continue
        context = SCENES[animal][WORDS.index(word)]
        if word == "mayak":
            outcome = f"Nos reuniremos a comer junto a {place}."
        elif word == "k'áanche'":
            outcome = f"Ya podemos sentarnos a conversar junto a {place}."
        elif word == "k'áan":
            outcome = f"El descanso está listo junto a {place}."
        elif word == "lak":
            outcome = f"Serviremos la merienda junto a {place}."
        elif word == "ja'":
            outcome = f"Ya podemos beber y descansar junto a {place}."
        else:
            outcome = f"La compartiremos con mis amigos junto a {place}." if word != "ja'as" else f"Lo compartiremos con mis amigos junto a {place}."
        data["tasks"][key] = [f"{context} Necesito {need}.", f"¿Me traes {need}? {context}", f"¡{label}! {outcome}"]
        assert all(len(line) <= 160 for line in data["tasks"][key]), (animal, key)
header = "extends RefCounted\n\n## Banco explícito de peticiones y saludos. Nuevas combinaciones: tools/build_combination_dialogue.py.\n"
path.write_text(header + "const ANIMALS := " + json.dumps(banks, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8", newline="\n")
print(f"{len(banks)} animales × {len(targets)} pedidos × 3 frases + 60 saludos = {len(banks) * len(targets) * 3 + 60} textos.")
