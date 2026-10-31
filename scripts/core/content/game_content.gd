extends RefCounted
class_name GameContent

## Catálogo estático del juego. No contiene estado de la partida ni lógica de
## navegación: funciona como fuente única para vocabulario, escenas y arte.

const VOCABULARY: Dictionary = {
	"Peek'":
	{
		"spanish": "Perro",
		"emoji": "🐶",
		"world": 1,
		"level": 1,
		"estructura": "In k'aaba'e' Peek'",
		"traduccion": "Me llamo Perro"
	},
	"Miis":
	{
		"spanish": "Gato",
		"emoji": "🐱",
		"world": 1,
		"level": 1,
		"estructura": "In k'aaba'e' Miis",
		"traduccion": "Me llamo Gato"
	},
	"Kaax":
	{
		"spanish": "Gallina",
		"emoji": "🐔",
		"world": 1,
		"level": 1,
		"estructura": "In k'aaba'e' Kaax",
		"traduccion": "Me llamo Gallina"
	},
	"Áak":
	{
		"spanish": "Tortuga",
		"emoji": "🐢",
		"world": 1,
		"level": 4,
		"estructura": "In k'aaba'e' Áak",
		"traduccion": "Me llamo Tortuga"
	},
	"Kéej":
	{
		"spanish": "Venado",
		"emoji": "🦌",
		"world": 1,
		"level": 2,
		"estructura": "In k'aaba'e' Kéej",
		"traduccion": "Me llamo Venado"
	},
	"K'éek'en":
	{
		"spanish": "Cerdo",
		"emoji": "🐷",
		"world": 1,
		"level": 2,
		"estructura": "In k'aaba'e' K'éek'en",
		"traduccion": "Me llamo Cerdo"
	},
	"Ma'ax":
	{
		"spanish": "Mono",
		"emoji": "🐒",
		"world": 1,
		"level": 2,
		"estructura": "In k'aaba'e' Ma'ax",
		"traduccion": "Me llamo Mono"
	},
	"T'uut'":
	{
		"spanish": "Loro",
		"emoji": "🦜",
		"world": 1,
		"level": 1,
		"estructura": "In k'aaba'e' T'uut'",
		"traduccion": "Me llamo Loro"
	},
	"mayak":
	{
		"spanish": "Mesa",
		"emoji": "🪑",
		"world": 2,
		"level": 1,
		"estructura": "mayak",
		"traduccion": "Mesa"
	},
	"lak":
	{
		"spanish": "Plato",
		"emoji": "🍽️",
		"world": 2,
		"level": 1,
		"estructura": "lak",
		"traduccion": "Plato"
	},
	"k'áan":
	{
		"spanish": "Hamaca",
		"emoji": "🛏️",
		"world": 2,
		"level": 1,
		"estructura": "k'áan",
		"traduccion": "Hamaca"
	},
	"k'áanche'":
	{
		"spanish": "Silla",
		"emoji": "💺",
		"world": 2,
		"level": 1,
		"estructura": "k'áanche'",
		"traduccion": "Silla"
	},
	"janal":
	{
		"spanish": "Comida",
		"emoji": "🍲",
		"world": 2,
		"level": 1,
		"estructura": "janal",
		"traduccion": "Comida"
	},
	"mejen":
	{
		"spanish": "Pequeño/a",
		"emoji": "🔹",
		"world": 3,
		"level": 1,
		"estructura": "k'áan · mejen",
		"traduccion": "Hamaca pequeña"
	},
	"nojoch":
	{
		"spanish": "Grande",
		"emoji": "🔷",
		"world": 3,
		"level": 1,
		"estructura": "mayak · nojoch",
		"traduccion": "Mesa grande"
	},
	"Jats'uts":
	{
		"spanish": "Bonito/a",
		"emoji": "✨",
		"world": 3,
		"level": 1,
		"estructura": "lak · Jats'uts",
		"traduccion": "Plato bonito"
	},
	"ki'":
	{
		"spanish": "Delicioso",
		"emoji": "😋",
		"world": 3,
		"level": 1,
		"estructura": "janal · ki'",
		"traduccion": "Comida deliciosa"
	},
	"chich":
	{
		"spanish": "Fuerte",
		"emoji": "💪",
		"world": 3,
		"level": 1,
		"estructura": "k'áanche' · chich",
		"traduccion": "Silla fuerte"
	},
	"ja'":
	{
		"spanish": "Agua",
		"emoji": "💧",
		"world": 4,
		"level": 1,
		"estructura": "In k'a'at ja'",
		"traduccion": "Yo quiero agua"
	},
	"ja'as":
	{
		"spanish": "Plátano",
		"emoji": "🍌",
		"world": 4,
		"level": 1,
		"estructura": "In k'a'at ja'as",
		"traduccion": "Yo quiero plátano"
	},
	"ich":
	{
		"spanish": "Fruta",
		"emoji": "🍎",
		"world": 4,
		"level": 1,
		"estructura": "In k'a'at ich",
		"traduccion": "Yo quiero fruta"
	},
	"K'úum":
	{
		"spanish": "Calabaza",
		"emoji": "🎃",
		"world": 4,
		"level": 1,
		"estructura": "In k'a'at K'úum",
		"traduccion": "Yo quiero calabaza"
	},
	"jun":
	{
		"spanish": "Uno",
		"world": 4,
		"level": 2,
		"value": 1,
		"book_category": 6,
		"estructura": "Juntúul Peek'",
		"traduccion": "Un perro"
	},
	"ka'a":
	{
		"spanish": "Dos",
		"world": 4,
		"level": 2,
		"value": 2,
		"book_category": 6,
		"estructura": "Ka'ap'éel lak",
		"traduccion": "Dos platos"
	},
	"óox":
	{
		"spanish": "Tres",
		"world": 4,
		"level": 2,
		"value": 3,
		"book_category": 6,
		"estructura": "Óoxp'éel ja'as",
		"traduccion": "Tres plátanos"
	},
	"kan":
	{
		"spanish": "Cuatro",
		"world": 4,
		"level": 2,
		"value": 4,
		"book_category": 6,
		"estructura": "Kantúul Miis",
		"traduccion": "Cuatro gatos"
	},
	"jo'o":
	{
		"spanish": "Cinco",
		"world": 4,
		"level": 2,
		"value": 5,
		"book_category": 6,
		"estructura": "Jo'op'éel K'úum",
		"traduccion": "Cinco calabazas"
	},
	"Bix a beel":
	{
		"spanish": "Buenos días",
		"emoji": "☀️",
		"world": 5,
		"level": 1,
		"estructura": "Bix a beel",
		"traduccion": "Buenos días"
	},
	"Yuum bo'otik":
	{
		"spanish": "Muchas gracias",
		"emoji": "🙏",
		"world": 5,
		"level": 1,
		"estructura": "Yuum bo'otik",
		"traduccion": "Muchas gracias"
	},
	"Ka xi'ik tech jats'uts":
	{
		"spanish": "Que te vaya bien",
		"emoji": "🌿",
		"world": 5,
		"level": 1,
		"estructura": "Ka xi'ik tech jats'uts",
		"traduccion": "Que te vaya bien"
	},
	"Tak ti' uláak' k'iin":
	{
		"spanish": "Adiós, nos vemos",
		"emoji": "👋",
		"world": 5,
		"level": 1,
		"estructura": "Tak ti' uláak' k'iin",
		"traduccion": "Adiós, nos vemos"
	},
	"Kuuts":
	{
		"spanish": "Pavo",
		"emoji": "🦃",
		"world": 1,
		"level": 3,
		"estructura": "In k'aaba'e' Kuuts",
		"traduccion": "Me llamo Pavo"
	},
	"Báalam":
	{
		"spanish": "Jaguar",
		"emoji": "🐆",
		"world": 1,
		"level": 3,
		"estructura": "In k'aaba'e' Báalam",
		"traduccion": "Me llamo Jaguar"
	},
	"T'u'ul":
	{
		"spanish": "Conejo",
		"emoji": "🐇",
		"world": 1,
		"level": 3,
		"estructura": "In k'aaba'e' T'u'ul",
		"traduccion": "Me llamo Conejo"
	},
	"Kay":
	{
		"spanish": "Pez",
		"emoji": "🐟",
		"world": 1,
		"level": 4,
		"estructura": "In k'aaba'e' Kay",
		"traduccion": "Me llamo Pez"
	},
	"Ch'íich'":
	{
		"spanish": "Pájaro",
		"emoji": "🐦",
		"world": 1,
		"level": 4,
		"estructura": "In k'aaba'e' Ch'íich'",
		"traduccion": "Me llamo Pájaro"
	},
}

const SCENE_PATHS: Dictionary = {
	"village_home": "res://scenes/features/village/village_home.tscn",
	"intro": "res://scenes/ui/main_menu/intro.tscn",
	"main_menu": "res://scenes/ui/main_menu/main_menu.tscn",
	"world1_level1": "res://scenes/worlds/world1/level1_caminos_blancos.tscn",
	"world1_level2": "res://scenes/worlds/world1/level2_animales_bosque.tscn",
	"world1_level3": "res://scenes/worlds/world1/level3_guardianes_monte.tscn",
	"world1_level4": "res://scenes/worlds/world1/level4_agua_y_cielo.tscn",
	"world1_cine1": "res://scenes/worlds/world1/cine1_noche_huracan.tscn",
	"world1_explore1": "res://scenes/worlds/world1/exploracion1_orilla_isla.tscn",
	"world1_story1": "res://scenes/worlds/world1/historia1_isla_animales.tscn",
	"world1_story2": "res://scenes/worlds/world1/historia2_voces_bosque.tscn",
	"world1_story3": "res://scenes/worlds/world1/historia3_guardianes_monte.tscn",
	"world1_story4": "res://scenes/worlds/world1/historia4_agua_cielo.tscn",
	"world1_story5": "res://scenes/worlds/world1/historia5_fiesta_isla.tscn",
	"world1_explore2": "res://scenes/worlds/world1/exploracion2_camino_casa_maya.tscn",
	"world1_cine2": "res://scenes/worlds/world1/cine2_casa_maya_vacia.tscn",
	"world2_story1": "res://scenes/worlds/world2/historia6_objetos_a_la_medida.tscn",
	"world3_story1": "res://scenes/worlds/world3/historia7_hambre_aldea.tscn",
	"world3_explore2": "res://scenes/worlds/world3/exploracion3_la_milpa.tscn",
	"world4_story1": "res://scenes/worlds/world4/historia8_portal_despierta.tscn",
	"world5_story1": "res://scenes/worlds/world5/historia9_despedida.tscn",
	"world5_cine1": "res://scenes/worlds/world5/cine3_regreso_a_casa.tscn",
	"world2_level1": "res://scenes/worlds/world2/level2_construyendo_palabras.tscn",
	"world2_mission1": "res://scenes/worlds/world2/mision_rincones_de_la_casa.tscn",
	"world3_mission1": "res://scenes/worlds/world3/mision_preparar_la_fiesta.tscn",
	"world2_explore1": "res://scenes/worlds/world2/paseo_la_casa_viva.tscn",
	"world3_level1": "res://scenes/worlds/world3/level3_hechizos_adjetivos.tscn",
	"world3_explore1": "res://scenes/worlds/world3/paseo_aldea_a_la_medida.tscn",
	"world4_level1": "res://scenes/worlds/world4/level4_yo_quiero.tscn",
	"world4_story2": "res://scenes/worlds/world4/historia_tianguis.tscn",
	"world4_level2": "res://scenes/worlds/world4/level4_piedras_que_cuentan.tscn",
	"world4_mission1": "res://scenes/worlds/world4/mision_encargos_aldea.tscn",
	"world4_explore1": "res://scenes/worlds/world4/exploracion4_camino_portal.tscn",
	"world5_farewell": "res://scenes/worlds/world5/despedida_los_recuerdos.tscn",
	"world5_level1": "res://scenes/worlds/world5/level5_portal_de_regreso.tscn",
}

const LEVEL_ORDER: Array[Dictionary] = [
	{
		"world": 1,
		"level": 1,
		"scene_key": "world1_level1",
		"name": "Los Caminos Blancos",
		"map_label": "Caminos",
		"story_key": "world1_cine1"
	},
	{
		"world": 1,
		"level": 2,
		"scene_key": "world1_level2",
		"name": "Los Animales del Bosque",
		"map_label": "Bosque",
		"story_key": "world1_story2"
	},
	{
		"world": 1,
		"level": 3,
		"scene_key": "world1_level3",
		"name": "Los Guardianes del Monte",
		"map_label": "Monte",
		"story_key": "world1_story3"
	},
	{
		"world": 1,
		"level": 4,
		"scene_key": "world1_level4",
		"name": "Agua y Cielo",
		"map_label": "Agua y cielo",
		"story_key": "world1_story4"
	},
	{
		"world": 2,
		"level": 1,
		"scene_key": "world2_level1",
		"name": "La Casa Maya",
		"map_label": "Los muebles",
		"story_key": "world1_story5"
	},
	{
		"world": 3,
		"level": 1,
		"scene_key": "world3_level1",
		"name": "Hechizos de Adjetivos",
		"map_label": "A la medida",
		"story_key": "world2_story1"
	},
	{
		"world": 4,
		"level": 1,
		"scene_key": "world4_level1",
		"name": "Yo Quiero",
		"map_label": "Peticiones",
		"story_key": "world3_story1"
	},
	{
		"world": 4,
		"level": 2,
		"scene_key": "world4_level2",
		"name": "Las Piedras que Cuentan",
		"map_label": "Números",
		"story_key": "world4_story2"
	},
	{
		"world": 5,
		"level": 1,
		"scene_key": "world5_level1",
		"name": "El Portal de Regreso",
		"map_label": "Regreso a casa",
		"story_key": "world4_story1"
	},
]

const FUTURE_VOCABULARY: Array[String] = ["T'uut'"]
