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
signal progress_reset

# ─── Estado global ───────────────────────────────────────────────────────────
var magic_points: int = 0
var words_learned: Dictionary = {}          # { "Peek'" : { spanish, emoji, level, ... } }
var completed_levels: Array[String] = []    # [ "w1_l1", "w1_l2", ... ]

# ─── Vocabulario completo del juego ─────────────────────────────────────────
# Indexado por palabra en maya yucateco
const VOCABULARY: Dictionary = {
	# Mundo 1, nivel 1 — Animales (estructura: In k'aaba'e' ___)
	"Peek'":    { "spanish": "Perro",    "emoji": "🐶", "world": 1, "level": 1,
				  "estructura": "In k'aaba'e' Peek'",    "traduccion": "Me llamo Perro" },
	"Miis":     { "spanish": "Gato",     "emoji": "🐱", "world": 1, "level": 1,
				  "estructura": "In k'aaba'e' Miis",     "traduccion": "Me llamo Gato" },
	"Kaax":     { "spanish": "Gallina",  "emoji": "🐔", "world": 1, "level": 1,
				  "estructura": "In k'aaba'e' Kaax",     "traduccion": "Me llamo Gallina" },
	"Áak":      { "spanish": "Tortuga",  "emoji": "🐢", "world": 1, "level": 4,
				  "estructura": "In k'aaba'e' Áak",      "traduccion": "Me llamo Tortuga" },
	"Kéej":     { "spanish": "Venado",   "emoji": "🦌", "world": 1, "level": 2,
				  "estructura": "In k'aaba'e' Kéej",     "traduccion": "Me llamo Venado" },
	"K'éek'en": { "spanish": "Cerdo",    "emoji": "🐷", "world": 1, "level": 2,
				  "estructura": "In k'aaba'e' K'éek'en", "traduccion": "Me llamo Cerdo" },
	# Mundo 1, nivel 2 — Animales del bosque
	"Ma'ax":    { "spanish": "Mono",     "emoji": "🐒", "world": 1, "level": 2,
				  "estructura": "In k'aaba'e' Ma'ax",    "traduccion": "Me llamo Mono" },
	"T'uut'":   { "spanish": "Loro",     "emoji": "🦜", "world": 1, "level": 1,
				  "estructura": "In k'aaba'e' T'uut'",   "traduccion": "Me llamo Loro" },

	# Mundo 2, nivel 1 — Objetos del hogar (sustantivos)
	"mayak":    { "spanish": "Mesa",     "emoji": "🪑", "world": 2, "level": 1,
				  "estructura": "Ti' yaan jun mayak",    "traduccion": "Hay una mesa" },
	"lak":      { "spanish": "Plato",    "emoji": "🍽️", "world": 2, "level": 1,
				  "estructura": "Ti' yaan jun lak",      "traduccion": "Hay un plato" },
	"ch'áak":   { "spanish": "Cama",     "emoji": "🛏️", "world": 2, "level": 1,
				  "estructura": "Ti' yaan jun ch'áak",   "traduccion": "Hay una cama" },
	"chan":     { "spanish": "Silla",    "emoji": "💺",  "world": 2, "level": 1,
				  "estructura": "Ti' yaan jun chan",     "traduccion": "Hay una silla" },
	"janal":    { "spanish": "Comida",   "emoji": "🍲",  "world": 2, "level": 1,
				  "estructura": "Ti' yaan jun janal",    "traduccion": "Hay comida" },

	# Mundo 3, nivel 1 — Adjetivos
	"mejen":    { "spanish": "Pequeño/a", "emoji": "🔹", "world": 3, "level": 1,
				  "estructura": "In [sust.]e' mejen",    "traduccion": "Mi [cosa] es pequeña" },
	"nojoch":   { "spanish": "Grande",    "emoji": "🔷", "world": 3, "level": 1,
				  "estructura": "In [sust.]e' nojoch",   "traduccion": "Mi [cosa] es grande" },
	"Jats'uts": { "spanish": "Bonito/a",  "emoji": "✨",  "world": 3, "level": 1,
				  "estructura": "In [sust.]e' Jats'uts", "traduccion": "Mi [cosa] es bonita" },
	"ki'":      { "spanish": "Delicioso", "emoji": "😋", "world": 3, "level": 1,
				  "estructura": "In [sust.]e' ki'",      "traduccion": "Mi [cosa] es deliciosa" },
	"jach'":    { "spanish": "Fuerte",    "emoji": "💪", "world": 3, "level": 1,
				  "estructura": "In [sust.]e' jach'",    "traduccion": "Mi [cosa] es fuerte" },

	# Mundo 4, nivel 1 — Alimentos / In k'a'at
	"ja'":      { "spanish": "Agua",     "emoji": "💧", "world": 4, "level": 1,
				  "estructura": "In k'a'at ja'",         "traduccion": "Yo quiero agua" },
	"ja'as":    { "spanish": "Plátano",  "emoji": "🍌", "world": 4, "level": 1,
				  "estructura": "In k'a'at ja'as",       "traduccion": "Yo quiero plátano" },
	"pak'al":   { "spanish": "Fruta",    "emoji": "🍎", "world": 4, "level": 1,
				  "estructura": "In k'a'at pak'al",      "traduccion": "Yo quiero fruta" },
	"K'úum":    { "spanish": "Calabaza", "emoji": "🎃", "world": 4, "level": 1,
				  "estructura": "In k'a'at K'úum",       "traduccion": "Yo quiero calabaza" },

	# Mundo 1, nivel 3 — Guardianes del monte
	"Kuuts":    { "spanish": "Pavo",     "emoji": "🦃", "world": 1, "level": 3,
				  "estructura": "In k'aaba'e' Kuuts",    "traduccion": "Me llamo Pavo" },
	"Báalam":   { "spanish": "Jaguar",   "emoji": "🐆", "world": 1, "level": 3,
				  "estructura": "In k'aaba'e' Báalam",   "traduccion": "Me llamo Jaguar" },
	"T'u'ul":   { "spanish": "Conejo",   "emoji": "🐇", "world": 1, "level": 3,
				  "estructura": "In k'aaba'e' T'u'ul",   "traduccion": "Me llamo Conejo" },

	# Mundo 1, nivel 4 — Agua y cielo
	"Kay":      { "spanish": "Pez",      "emoji": "🐟", "world": 1, "level": 4,
				  "estructura": "In k'aaba'e' Kay",      "traduccion": "Me llamo Pez" },
	"Ch'íich'": { "spanish": "Pájaro",   "emoji": "🐦", "world": 1, "level": 4,
				  "estructura": "In k'aaba'e' Ch'íich'", "traduccion": "Me llamo Pájaro" },
}

# ─── Rutas de escenas ────────────────────────────────────────────────────────
const SCENE_PATHS: Dictionary = {
	"intro":           "res://scenes/Intro.tscn",
	"main_menu":       "res://scenes/MainMenu.tscn",
	"world1_level1":   "res://scenes/world1/Level1_CaminosBlancos.tscn",
	"world1_level2":   "res://scenes/world1/Level2_AnimalesBosque.tscn",
	"world1_level3":   "res://scenes/world1/Level3_GuardianesMonte.tscn",
	"world1_level4":   "res://scenes/world1/Level4_AguaYCielo.tscn",
	"world2_level1":   "res://scenes/world2/Level2_ConstruyendoPalabras.tscn",
	"world3_level1":   "res://scenes/world3/Level3_HechizosAdjetivos.tscn",
	"world4_level1":   "res://scenes/world4/Level4_YoQuiero.tscn"
}

## Orden canónico de progreso. Cada mundo representa una mecánica distinta;
## sus niveles son variaciones de esa misma mecánica.
const LEVEL_ORDER: Array[Dictionary] = [
	{ "world": 1, "level": 1, "scene_key": "world1_level1", "name": "Los Caminos Blancos" },
	{ "world": 1, "level": 2, "scene_key": "world1_level2", "name": "Los Animales del Bosque" },
	{ "world": 1, "level": 3, "scene_key": "world1_level3", "name": "Los Guardianes del Monte" },
	{ "world": 1, "level": 4, "scene_key": "world1_level4", "name": "Agua y Cielo" },
	{ "world": 2, "level": 1, "scene_key": "world2_level1", "name": "La Casa Maya" },
	{ "world": 3, "level": 1, "scene_key": "world3_level1", "name": "Hechizos de Adjetivos" },
	{ "world": 4, "level": 1, "scene_key": "world4_level1", "name": "Yo Quiero" },
]

## Variantes antiguas que pueden existir en escenas o partidas guardadas.
## Toda palabra aprendida se almacena usando la clave canónica de VOCABULARY.
const VOCABULARY_ALIASES: Dictionary = {
	"Míis": "Miis",
	"Káax": "Kaax",
	"Aak": "Áak",
	"Aak'": "Áak",
	"Áak'": "Áak",
	"K'uum": "K'úum",
	"Ja'as": "ja'as",
	"T'uut": "T'uut'",
}

# ─── Constantes de recompensa ────────────────────────────────────────────────
const MAGIC_PER_WORD:  int = 10
const MAGIC_PER_LEVEL: int = 50
const SAVE_PATH: String = "user://kalin_save.json"
const SAVE_VERSION: int = 1

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_save()

# ─── API pública ─────────────────────────────────────────────────────────────

## Registra una palabra maya como aprendida. Emite word_learned y suma puntos.
## Tolera variantes históricas de acentos y apóstrofos.
func learn_word(maya_word: String) -> void:
	# Buscar la clave real en el vocabulario (tolerante a acentos)
	var key: String = _resolve_vocab_key(maya_word)
	if key == "":
		push_warning("GameManager: palabra desconocida '%s'" % maya_word)
		return
	if key in words_learned:
		return
	words_learned[key] = VOCABULARY[key].duplicate()
	_add_magic(MAGIC_PER_WORD)
	word_learned.emit(words_learned[key])
	_save()

## Indica si una palabra ya fue aprendida, aceptando grafías antiguas.
func has_learned_word(maya_word: String) -> bool:
	var key: String = _resolve_vocab_key(maya_word)
	return key != "" and key in words_learned

## Devuelve los datos de la fuente única de vocabulario.
func get_vocabulary_entry(maya_word: String) -> Dictionary:
	var key: String = _resolve_vocab_key(maya_word)
	if key == "":
		return {}
	return VOCABULARY[key]

## Nombre técnico estable para archivos de audio: usa la grafía canónica pero
## elimina acentos, apóstrofes y espacios (ej.: K'úum -> Kuum.ogg).
func get_audio_filename(maya_word: String) -> String:
	var key: String = _resolve_vocab_key(maya_word)
	var source: String = key if key != "" else maya_word
	return _strip_accents(source).replace("'", "").replace("’", "").replace(" ", "_") + ".ogg"

## Devuelve la clave exacta del VOCABULARY que corresponde a una palabra,
## ignorando diferencias de acentos. Devuelve "" si no existe.
func _resolve_vocab_key(word: String) -> String:
	if word in VOCABULARY:
		return word
	if word in VOCABULARY_ALIASES:
		return VOCABULARY_ALIASES[word]
	var normalized: String = _strip_accents(word).to_lower()
	for k in VOCABULARY.keys():
		if _strip_accents(k).to_lower() == normalized:
			return k
	return ""

## Quita acentos de una cadena (á→a, í→i, etc.) para comparaciones flexibles.
func _strip_accents(s: String) -> String:
	var result: String = s
	var pairs: Dictionary = {
		"á":"a","é":"e","í":"i","ó":"o","ú":"u","ü":"u",
		"Á":"A","É":"E","Í":"I","Ó":"O","Ú":"U","Ü":"U",
		"ñ":"n","Ñ":"N",
	}
	for accented in pairs:
		result = result.replace(accented, pairs[accented])
	return result

## Marca un nivel como completado y suma puntos de bonificación.
func complete_level(world: int, level: int) -> void:
	var key: String = "w%d_l%d" % [world, level]
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
	for level_data: Dictionary in LEVEL_ORDER:
		if not is_level_completed(level_data.world, level_data.level):
			return level_data.scene_key
	return "main_menu"

## Devuelve los datos de presentación asociados con una clave de escena.
func get_level_info(scene_key: String) -> Dictionary:
	for level_data: Dictionary in LEVEL_ORDER:
		if level_data.scene_key == scene_key:
			return level_data
	return {}

func all_levels_completed() -> bool:
	return next_unlocked_scene() == "main_menu"

## Cambia a una escena por clave.
func go_to_scene(key: String) -> void:
	if key not in SCENE_PATHS:
		push_error("GameManager: clave de escena desconocida '%s'" % key)
		return
	var error: Error = get_tree().change_scene_to_file(SCENE_PATHS[key])
	if error != OK:
		push_error("GameManager: no se pudo abrir '%s' (error %d)" % [SCENE_PATHS[key], error])

## Cambia al nivel indicado.
func go_to_level(world: int, level: int) -> void:
	go_to_scene("world%d_level%d" % [world, level])

## Borra el progreso guardado.
func reset_save() -> void:
	magic_points = 0
	words_learned = {}
	completed_levels = []
	magic_points_changed.emit(0)
	progress_reset.emit()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var user_directory: DirAccess = DirAccess.open("user://")
	if user_directory == null:
		push_warning("GameManager: no se pudo abrir user:// para borrar el progreso")
		return
	var error: Error = user_directory.remove(SAVE_PATH.get_file())
	if error != OK:
		push_warning("GameManager: no se pudo borrar el progreso (error %d)" % error)

# ─── Internos ────────────────────────────────────────────────────────────────

func _add_magic(amount: int) -> void:
	magic_points += amount
	magic_points_changed.emit(magic_points)

func _save() -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"magic_points": magic_points,
		"words_learned": words_learned,
		"completed_levels": completed_levels,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameManager: no se pudo abrir el archivo de progreso (error %d)" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		push_warning("GameManager: no se pudo guardar el progreso completo (error %d)" % error)

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("GameManager: no se pudo leer el progreso (error %d)" % FileAccess.get_open_error())
		return
	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		push_warning(
			"GameManager: el progreso está dañado (línea %d: %s)" % [
				json.get_error_line(), json.get_error_message()
			]
		)
		return
	var result: Variant = json.data
	if result is Dictionary:
		var loaded_version: int = int(result.get("version", 0))
		if loaded_version > SAVE_VERSION:
			push_warning(
				"GameManager: el progreso usa una versión más reciente (%d)" % loaded_version
			)
			return
		# JSON devuelve números como float y arrays/dicts SIN tipo,
		# así que convertimos explícitamente para respetar los tipos declarados.
		magic_points = maxi(int(result.get("magic_points", 0)), 0)

		# completed_levels es Array[String]: usamos assign() para convertir
		# el Array genérico que entrega JSON en un Array tipado sin crashear.
		completed_levels = _sanitize_completed_levels(result.get("completed_levels", []))

		# Reconstruir y migrar claves antiguas a la grafía canónica. Los datos de
		# VOCABULARY reemplazan copias antiguas para evitar contenido duplicado.
		words_learned = {}
		var loaded_words: Variant = result.get("words_learned", {})
		if loaded_words is Dictionary:
			for old_key in loaded_words:
				var canonical_key: String = _resolve_vocab_key(old_key)
				if canonical_key != "":
					words_learned[canonical_key] = VOCABULARY[canonical_key].duplicate()

		# Versiones anteriores guardaban los mundos 3 y 4 con identificadores del
		# Mundo 1. Si todo su vocabulario estaba aprendido, recuperar el progreso.
		_migrate_completed_stage_from_words(3, 1, ["mejen", "nojoch", "ki'"])
		_migrate_completed_stage_from_words(4, 1, ["ja'", "ja'as", "pak'al", "K'úum"])

	magic_points_changed.emit(magic_points)

func _sanitize_completed_levels(value: Variant) -> Array[String]:
	var sanitized: Array[String] = []
	if value is not Array:
		return sanitized
	var valid_keys: Dictionary = {}
	for level_data: Dictionary in LEVEL_ORDER:
		valid_keys["w%d_l%d" % [level_data.world, level_data.level]] = true
	for item: Variant in value:
		var key: String = str(item)
		if valid_keys.has(key) and key not in sanitized:
			sanitized.append(key)
	return sanitized

func _migrate_completed_stage_from_words(world: int, level: int, required_words: Array[String]) -> void:
	var progress_key: String = "w%d_l%d" % [world, level]
	if progress_key in completed_levels:
		return
	for maya_word in required_words:
		if not has_learned_word(maya_word):
			return
	completed_levels.append(progress_key)
