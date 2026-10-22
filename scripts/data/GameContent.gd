extends RefCounted
class_name GameContent

## Catálogo estático del juego. No contiene estado de la partida ni lógica de
## navegación: funciona como fuente única para vocabulario, escenas y arte.

const VOCABULARY: Dictionary = {
	"Peek'": {"spanish": "Perro", "emoji": "🐶", "world": 1, "level": 1, "estructura": "In k'aaba'e' Peek'", "traduccion": "Me llamo Perro"},
	"Miis": {"spanish": "Gato", "emoji": "🐱", "world": 1, "level": 1, "estructura": "In k'aaba'e' Miis", "traduccion": "Me llamo Gato"},
	"Kaax": {"spanish": "Gallina", "emoji": "🐔", "world": 1, "level": 1, "estructura": "In k'aaba'e' Kaax", "traduccion": "Me llamo Gallina"},
	"Áak": {"spanish": "Tortuga", "emoji": "🐢", "world": 1, "level": 4, "estructura": "In k'aaba'e' Áak", "traduccion": "Me llamo Tortuga"},
	"Kéej": {"spanish": "Venado", "emoji": "🦌", "world": 1, "level": 2, "estructura": "In k'aaba'e' Kéej", "traduccion": "Me llamo Venado"},
	"K'éek'en": {"spanish": "Cerdo", "emoji": "🐷", "world": 1, "level": 2, "estructura": "In k'aaba'e' K'éek'en", "traduccion": "Me llamo Cerdo"},
	"Ma'ax": {"spanish": "Mono", "emoji": "🐒", "world": 1, "level": 2, "estructura": "In k'aaba'e' Ma'ax", "traduccion": "Me llamo Mono"},
	"T'uut'": {"spanish": "Loro", "emoji": "🦜", "world": 1, "level": 1, "estructura": "In k'aaba'e' T'uut'", "traduccion": "Me llamo Loro"},
	"mayak": {"spanish": "Mesa", "emoji": "🪑", "world": 2, "level": 1, "estructura": "mayak", "traduccion": "Mesa"},
	"lak": {"spanish": "Plato", "emoji": "🍽️", "world": 2, "level": 1, "estructura": "lak", "traduccion": "Plato"},
	"k'áan": {"spanish": "Hamaca", "emoji": "🛏️", "world": 2, "level": 1, "estructura": "k'áan", "traduccion": "Hamaca"},
	"k'áanche'": {"spanish": "Silla", "emoji": "💺", "world": 2, "level": 1, "estructura": "k'áanche'", "traduccion": "Silla"},
	"janal": {"spanish": "Comida", "emoji": "🍲", "world": 2, "level": 1, "estructura": "janal", "traduccion": "Comida"},
	"mejen": {"spanish": "Pequeño/a", "emoji": "🔹", "world": 3, "level": 1, "estructura": "k'áan · mejen", "traduccion": "Hamaca pequeña"},
	"nojoch": {"spanish": "Grande", "emoji": "🔷", "world": 3, "level": 1, "estructura": "mayak · nojoch", "traduccion": "Mesa grande"},
	"Jats'uts": {"spanish": "Bonito/a", "emoji": "✨", "world": 3, "level": 1, "estructura": "lak · Jats'uts", "traduccion": "Plato bonito"},
	"ki'": {"spanish": "Delicioso", "emoji": "😋", "world": 3, "level": 1, "estructura": "janal · ki'", "traduccion": "Comida deliciosa"},
	"chich": {"spanish": "Fuerte", "emoji": "💪", "world": 3, "level": 1, "estructura": "k'áanche' · chich", "traduccion": "Silla fuerte"},
	"ja'": {"spanish": "Agua", "emoji": "💧", "world": 4, "level": 1, "estructura": "In k'a'at ja'", "traduccion": "Yo quiero agua"},
	"ja'as": {"spanish": "Plátano", "emoji": "🍌", "world": 4, "level": 1, "estructura": "In k'a'at ja'as", "traduccion": "Yo quiero plátano"},
	"ich": {"spanish": "Fruta", "emoji": "🍎", "world": 4, "level": 1, "estructura": "In k'a'at ich", "traduccion": "Yo quiero fruta"},
	"K'úum": {"spanish": "Calabaza", "emoji": "🎃", "world": 4, "level": 1, "estructura": "In k'a'at K'úum", "traduccion": "Yo quiero calabaza"},
	"Bix a beel": {"spanish": "Buenos días", "emoji": "☀️", "world": 5, "level": 1, "estructura": "Bix a beel", "traduccion": "Buenos días"},
	"Yuum bo'otik": {"spanish": "Muchas gracias", "emoji": "🙏", "world": 5, "level": 1, "estructura": "Yuum bo'otik", "traduccion": "Muchas gracias"},
	"Ka xi'ik tech jats'uts": {"spanish": "Que te vaya bien", "emoji": "🌿", "world": 5, "level": 1, "estructura": "Ka xi'ik tech jats'uts", "traduccion": "Que te vaya bien"},
	"Tak ti' uláak' k'iin": {"spanish": "Adiós, nos vemos", "emoji": "👋", "world": 5, "level": 1, "estructura": "Tak ti' uláak' k'iin", "traduccion": "Adiós, nos vemos"},
	"Kuuts": {"spanish": "Pavo de monte", "emoji": "🦃", "world": 1, "level": 3, "estructura": "In k'aaba'e' Kuuts", "traduccion": "Me llamo Pavo de monte"},
	"Báalam": {"spanish": "Jaguar", "emoji": "🐆", "world": 1, "level": 3, "estructura": "In k'aaba'e' Báalam", "traduccion": "Me llamo Jaguar"},
	"T'u'ul": {"spanish": "Conejo", "emoji": "🐇", "world": 1, "level": 3, "estructura": "In k'aaba'e' T'u'ul", "traduccion": "Me llamo Conejo"},
	"Kay": {"spanish": "Pez", "emoji": "🐟", "world": 1, "level": 4, "estructura": "In k'aaba'e' Kay", "traduccion": "Me llamo Pez"},
	"Ch'íich'": {"spanish": "Pájaro", "emoji": "🐦", "world": 1, "level": 4, "estructura": "In k'aaba'e' Ch'íich'", "traduccion": "Me llamo Pájaro"},
}

const SCENE_PATHS: Dictionary = {
	"intro": "res://scenes/Intro.tscn", "main_menu": "res://scenes/MainMenu.tscn",
	"world1_level1": "res://scenes/world1/Level1_CaminosBlancos.tscn",
	"world1_level2": "res://scenes/world1/Level2_AnimalesBosque.tscn",
	"world1_level3": "res://scenes/world1/Level3_GuardianesMonte.tscn",
	"world1_level4": "res://scenes/world1/Level4_AguaYCielo.tscn",
	"world1_cine1": "res://scenes/world1/Cine1_NocheHuracan.tscn",
	"world1_explore1": "res://scenes/world1/Exploracion1_OrillaIsla.tscn",
	"world1_story1": "res://scenes/world1/Historia1_IslaAnimales.tscn",
	"world1_story2": "res://scenes/world1/Historia2_VocesBosque.tscn",
	"world1_story3": "res://scenes/world1/Historia3_GuardianesMonte.tscn",
	"world1_story4": "res://scenes/world1/Historia4_AguaCielo.tscn",
	"world1_story5": "res://scenes/world1/Historia5_FiestaIsla.tscn",
	"world1_cine2": "res://scenes/world1/Cine2_CasaMayaVacia.tscn",
	"world2_story1": "res://scenes/world2/Historia6_ObjetosALaMedida.tscn",
	"world3_story1": "res://scenes/world3/Historia7_HambreAldea.tscn",
	"world4_story1": "res://scenes/world4/Historia8_PortalDespierta.tscn",
	"world5_story1": "res://scenes/world5/Historia9_Despedida.tscn",
	"world5_cine1": "res://scenes/world5/Cine3_RegresoACasa.tscn",
	"world2_level1": "res://scenes/world2/Level2_ConstruyendoPalabras.tscn",
	"world3_level1": "res://scenes/world3/Level3_HechizosAdjetivos.tscn",
	"world4_level1": "res://scenes/world4/Level4_YoQuiero.tscn",
	"world4_mission1": "res://scenes/world4/Mision_EncargosAldea.tscn",
	"world5_level1": "res://scenes/world5/Level5_PortalDeRegreso.tscn",
}

const LEVEL_ORDER: Array[Dictionary] = [
	{"world": 1, "level": 1, "scene_key": "world1_level1", "name": "Los Caminos Blancos", "map_label": "Caminos", "story_key": "world1_cine1"},
	{"world": 1, "level": 2, "scene_key": "world1_level2", "name": "Los Animales del Bosque", "map_label": "Bosque", "story_key": "world1_story2"},
	{"world": 1, "level": 3, "scene_key": "world1_level3", "name": "Los Guardianes del Monte", "map_label": "Monte", "story_key": "world1_story3"},
	{"world": 1, "level": 4, "scene_key": "world1_level4", "name": "Agua y Cielo", "map_label": "Agua y cielo", "story_key": "world1_story4"},
	{"world": 2, "level": 1, "scene_key": "world2_level1", "name": "La Casa Maya", "map_label": "Los muebles", "story_key": "world1_story5"},
	{"world": 3, "level": 1, "scene_key": "world3_level1", "name": "Hechizos de Adjetivos", "map_label": "A la medida", "story_key": "world2_story1"},
	{"world": 4, "level": 1, "scene_key": "world4_level1", "name": "Yo Quiero", "map_label": "Peticiones", "story_key": "world3_story1"},
	{"world": 5, "level": 1, "scene_key": "world5_level1", "name": "El Portal de Regreso", "map_label": "Regreso a casa", "story_key": "world4_story1"},
]

const FUTURE_VOCABULARY: Array[String] = ["T'uut'"]

const VOCABULARY_ALIASES: Dictionary = {
	"Míis": "Miis", "Káax": "Kaax", "Aak": "Áak", "Aak'": "Áak", "Áak'": "Áak",
	"K'uum": "K'úum", "Ja'as": "ja'as", "T'uut": "T'uut'",
	# IDs históricos del prototipo; migran páginas, no validan esas traducciones.
	"chan": "k'áanche'", "ch'áak": "k'áan", "pak'al": "ich", "jach'": "chich",
}
