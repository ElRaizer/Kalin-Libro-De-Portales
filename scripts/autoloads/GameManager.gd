## GameManager.gd
## Autoload/Singleton — Gestiona el estado global del juego:
##   - Palabras aprendidas en maya
##   - Puntos mágicos
##   - Niveles completados
##   - Guardado y carga de progreso
##   - Navegación entre escenas

extends Node

# ─── Señales ────────────────────────────────────────────────────────────────
signal word_learned(word_data: Dictionary)
signal magic_points_changed(new_total: int)
signal level_completed(world: int, level: int)

# ─── Estado global ───────────────────────────────────────────────────────────
var magic_points: int = 0
var words_learned: Dictionary = {}          # { "Peek'" : { spanish, emoji, level, ... } }
var completed_levels: Array[String] = []    # [ "w1_l1", "w1_l2", ... ]

# ─── Vocabulario completo del juego ─────────────────────────────────────────
# Indexado por palabra en maya yucateco
const VOCABULARY: Dictionary = {
	# Nivel 1 — Animales (estructura: In k'aaba'e' ___)
	"Peek'":    { "spanish": "Perro",    "emoji": "🐶", "world": 1, "level": 1,
	              "estructura": "In k'aaba'e' Peek'",    "traduccion": "Me llamo Perro" },
	"Míis":     { "spanish": "Gato",     "emoji": "🐱", "world": 1, "level": 1,
	              "estructura": "In k'aaba'e' Míis",     "traduccion": "Me llamo Gato" },
	"Káax":     { "spanish": "Gallina",  "emoji": "🐔", "world": 1, "level": 1,
	              "estructura": "In k'aaba'e' Káax",     "traduccion": "Me llamo Gallina" },
	"Aak'":     { "spanish": "Tortuga",  "emoji": "🐢", "world": 1, "level": 7,
	              "estructura": "In k'aaba'e' Aak'",     "traduccion": "Me llamo Tortuga" },
	"Kéej":     { "spanish": "Venado",   "emoji": "🦌", "world": 1, "level": 5,
	              "estructura": "In k'aaba'e' Kéej",     "traduccion": "Me llamo Venado" },
	"K'éek'en": { "spanish": "Cerdo",    "emoji": "🐷", "world": 1, "level": 5,
	              "estructura": "In k'aaba'e' K'éek'en", "traduccion": "Me llamo Cerdo" },
	# Extras nivel 1
	"Ma'ax":    { "spanish": "Mono",     "emoji": "🐒", "world": 1, "level": 5,
	              "estructura": "In k'aaba'e' Ma'ax",    "traduccion": "Me llamo Mono" },
	"T'uut":    { "spanish": "Loro",     "emoji": "🦜", "world": 1, "level": 1,
	              "estructura": "In k'aaba'e' T'uut",    "traduccion": "Me llamo Loro" },

	# Nivel 2 — Objetos del hogar (sustantivos)
	"mayak":    { "spanish": "Mesa",     "emoji": "🪑", "world": 1, "level": 2,
	              "estructura": "mayak",                 "traduccion": "Mesa" },
	"lak":      { "spanish": "Plato",    "emoji": "🍽️", "world": 1, "level": 2,
	              "estructura": "lak",                   "traduccion": "Plato" },
	"ch'áak":   { "spanish": "Cama",     "emoji": "🛏️", "world": 1, "level": 2,
	              "estructura": "ch'áak",                "traduccion": "Cama" },
	"chan":      { "spanish": "Silla",    "emoji": "💺",  "world": 1, "level": 2,
	              "estructura": "chan",                   "traduccion": "Silla" },
	"janal":    { "spanish": "Comida",   "emoji": "🍲",  "world": 1, "level": 2,
	              "estructura": "janal",                  "traduccion": "Comida" },

	# Nivel 3 — Adjetivos
	"mejen":    { "spanish": "Pequeño/a", "emoji": "🔹", "world": 1, "level": 3,
	              "estructura": "In [sust.]e' mejen",    "traduccion": "Mi [cosa] es pequeña" },
	"nojoch":   { "spanish": "Grande",    "emoji": "🔷", "world": 1, "level": 3,
	              "estructura": "In [sust.]e' nojoch",   "traduccion": "Mi [cosa] es grande" },
	"Jats'uts": { "spanish": "Bonito/a",  "emoji": "✨",  "world": 1, "level": 3,
	              "estructura": "In [sust.]e' Jats'uts", "traduccion": "Mi [cosa] es bonita" },
	"ki'":      { "spanish": "Delicioso", "emoji": "😋", "world": 1, "level": 3,
	              "estructura": "In [sust.]e' ki'",      "traduccion": "Mi [cosa] es deliciosa" },
	"jach'":    { "spanish": "Fuerte",    "emoji": "💪", "world": 1, "level": 3,
	              "estructura": "In [sust.]e' jach'",    "traduccion": "Mi [cosa] es fuerte" },

	# Nivel 4 — Alimentos / In k'a'at
	"ja'":      { "spanish": "Agua",     "emoji": "💧", "world": 1, "level": 4,
	              "estructura": "In k'a'at ja'",         "traduccion": "Yo quiero agua" },
	"Ja'as":    { "spanish": "Plátano",  "emoji": "🍌", "world": 1, "level": 4,
	              "estructura": "In k'a'at Ja'as",       "traduccion": "Yo quiero plátano" },
	"pak'al":   { "spanish": "Fruta",    "emoji": "🍎", "world": 1, "level": 4,
	              "estructura": "In k'a'at pak'al",      "traduccion": "Yo quiero fruta" },
	"K'úum":    { "spanish": "Calabaza", "emoji": "🎃", "world": 1, "level": 4,
	              "estructura": "In k'a'at K'úum",       "traduccion": "Yo quiero calabaza" },

	# Nivel 6 — Animales del monte (listos para el próximo nivel)
	"Kuuts":    { "spanish": "Pavo",     "emoji": "🦃", "world": 1, "level": 6,
	              "estructura": "In k'aaba'e' Kuuts",    "traduccion": "Me llamo Pavo" },
	"Báalam":   { "spanish": "Jaguar",   "emoji": "🐆", "world": 1, "level": 6,
	              "estructura": "In k'aaba'e' Báalam",   "traduccion": "Me llamo Jaguar" },
	"T'u'ul":   { "spanish": "Conejo",   "emoji": "🐇", "world": 1, "level": 6,
	              "estructura": "In k'aaba'e' T'u'ul",   "traduccion": "Me llamo Conejo" },

	# Nivel 7 — Agua y Cielo
	"Kay":      { "spanish": "Pez",      "emoji": "🐟", "world": 1, "level": 7,
	              "estructura": "In k'aaba'e' Kay",      "traduccion": "Me llamo Pez" },
	"Ch'íich'": { "spanish": "Pájaro",   "emoji": "🐦", "world": 1, "level": 7,
	              "estructura": "In k'aaba'e' Ch'íich'", "traduccion": "Me llamo Pájaro" },
}

# ─── Rutas de escenas ────────────────────────────────────────────────────────
const SCENE_PATHS: Dictionary = {
	"intro":           "res://scenes/Intro.tscn",
	"main_menu":       "res://scenes/MainMenu.tscn",
	"world1_level1":   "res://scenes/world1/Level1_CaminosBlancos.tscn",
	"world1_level2":   "res://scenes/world1/Level2_ConstruyendoPalabras.tscn",
	"world1_level3":   "res://scenes/world1/Level3_HechizosAdjetivos.tscn",
	"world1_level4":   "res://scenes/world1/Level4_YoQuiero.tscn",
	"world1_level5":   "res://scenes/world1/Level5_AnimalesBosque.tscn",
	"world1_level6":   "res://scenes/world1/Level6_GuardianesMonte.tscn",
	"world1_level7":   "res://scenes/world1/Level7_AguaYCielo.tscn",
}

# ─── Constantes de recompensa ────────────────────────────────────────────────
const MAGIC_PER_WORD:  int = 10
const MAGIC_PER_LEVEL: int = 50

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_save()

# ─── API pública ─────────────────────────────────────────────────────────────

## Registra una palabra maya como aprendida. Emite word_learned y suma puntos.
## Tolera variaciones de acentos: "Miis" encuentra "Míis", etc.
func learn_word(maya_word: String) -> void:
	# Buscar la clave real en el vocabulario (tolerante a acentos)
	var key := _resolve_vocab_key(maya_word)
	if key == "":
		push_warning("GameManager: palabra desconocida '%s'" % maya_word)
		return
	if key in words_learned:
		return
	words_learned[key] = VOCABULARY[key].duplicate()
	_add_magic(MAGIC_PER_WORD)
	word_learned.emit(words_learned[key])
	_save()

## Devuelve la clave exacta del VOCABULARY que corresponde a una palabra,
## ignorando diferencias de acentos. Devuelve "" si no existe.
func _resolve_vocab_key(word: String) -> String:
	if word in VOCABULARY:
		return word
	var normalized := _strip_accents(word).to_lower()
	for k in VOCABULARY.keys():
		if _strip_accents(k).to_lower() == normalized:
			return k
	return ""

## Quita acentos de una cadena (á→a, í→i, etc.) para comparaciones flexibles.
func _strip_accents(s: String) -> String:
	var result := s
	var pairs := {
		"á":"a","é":"e","í":"i","ó":"o","ú":"u","ü":"u",
		"Á":"A","É":"E","Í":"I","Ó":"O","Ú":"U","Ü":"U",
		"ñ":"n","Ñ":"N",
	}
	for accented in pairs:
		result = result.replace(accented, pairs[accented])
	return result

## Marca un nivel como completado y suma puntos de bonificación.
func complete_level(world: int, level: int) -> void:
	var key := "w%d_l%d" % [world, level]
	if key not in completed_levels:
		completed_levels.append(key)
		_add_magic(MAGIC_PER_LEVEL)
	level_completed.emit(world, level)
	_save()

## Devuelve true si el nivel ya fue completado.
func is_level_completed(world: int, level: int) -> bool:
	return ("w%d_l%d" % [world, level]) in completed_levels

## Regresa el siguiente nivel sin completar (para botón "Continuar").
func next_unlocked_scene() -> String:
	for lvl in range(1, 8):
		if not is_level_completed(1, lvl):
			return "world1_level%d" % lvl
	return "main_menu"

## Cambia a una escena por clave.
func go_to_scene(key: String) -> void:
	if key in SCENE_PATHS:
		get_tree().change_scene_to_file(SCENE_PATHS[key])
	else:
		push_error("GameManager: clave de escena desconocida '%s'" % key)

## Cambia al nivel indicado.
func go_to_level(world: int, level: int) -> void:
	go_to_scene("world%d_level%d" % [world, level])

## Borra el progreso guardado.
func reset_save() -> void:
	magic_points = 0
	words_learned = {}
	completed_levels = []
	magic_points_changed.emit(0)
	if FileAccess.file_exists("user://kalin_save.json"):
		DirAccess.open("user://").remove("kalin_save.json")

# ─── Internos ────────────────────────────────────────────────────────────────

func _add_magic(amount: int) -> void:
	magic_points += amount
	magic_points_changed.emit(magic_points)

func _save() -> void:
	var data := {
		"magic_points": magic_points,
		"words_learned": words_learned,
		"completed_levels": completed_levels,
	}
	var f := FileAccess.open("user://kalin_save.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func _load_save() -> void:
	if not FileAccess.file_exists("user://kalin_save.json"):
		return
	var f := FileAccess.open("user://kalin_save.json", FileAccess.READ)
	if not f:
		return
	var result = JSON.parse_string(f.get_as_text())
	f.close()
	if result is Dictionary:
		# JSON devuelve números como float y arrays/dicts SIN tipo,
		# así que convertimos explícitamente para respetar los tipos declarados.
		magic_points = int(result.get("magic_points", 0))

		# completed_levels es Array[String]: usamos assign() para convertir
		# el Array genérico que entrega JSON en un Array tipado sin crashear.
		completed_levels.assign(result.get("completed_levels", []))

		# words_learned: reconstruimos para asegurar que "level"/"world" sean int.
		words_learned = {}
		var loaded_words = result.get("words_learned", {})
		if loaded_words is Dictionary:
			for key in loaded_words:
				var entry = loaded_words[key]
				if entry is Dictionary:
					if entry.has("level"): entry["level"] = int(entry["level"])
					if entry.has("world"): entry["world"] = int(entry["world"])
					words_learned[key] = entry

	magic_points_changed.emit(magic_points)
