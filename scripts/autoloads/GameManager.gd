## Autoload responsable únicamente del estado, persistencia y navegación.
extends Node

const CONTENT = preload("res://scripts/data/GameContent.gd")
const SAVE_REPOSITORY = preload("res://scripts/data/SaveRepository.gd")

signal word_learned(word_data: Dictionary)
signal magic_points_changed(new_total: int)
signal level_completed(world: int, level: int)
signal progress_reset

var magic_points: int = 0
var words_learned: Dictionary = {}
var completed_levels: Array[String] = []
var resume_scene_key: String = ""
var scene_states: Dictionary = {}
var tutorials_seen: Array[String] = []

## Alias de compatibilidad para consumidores existentes.
const VOCABULARY: Dictionary = CONTENT.VOCABULARY
const SCENE_PATHS: Dictionary = CONTENT.SCENE_PATHS
const LEVEL_ORDER: Array[Dictionary] = CONTENT.LEVEL_ORDER
const FUTURE_VOCABULARY: Array[String] = CONTENT.FUTURE_VOCABULARY
const BOOK_ILLUSTRATIONS: Dictionary = CONTENT.BOOK_ILLUSTRATIONS
const VOCABULARY_ALIASES: Dictionary = CONTENT.VOCABULARY_ALIASES

const MAGIC_PER_WORD: int = 10
const MAGIC_PER_LEVEL: int = 50
const SAVE_PATH: String = SAVE_REPOSITORY.DEFAULT_PATH
const SAVE_VERSION: int = SAVE_REPOSITORY.CURRENT_VERSION

var _save_repository: RefCounted

func _ready() -> void:
	_save_repository = SAVE_REPOSITORY.new(SAVE_PATH)
	_load_save()
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(quit_game)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _get_save_repository() -> RefCounted:
	if not is_instance_valid(_save_repository):
		_save_repository = SAVE_REPOSITORY.new(SAVE_PATH)
	return _save_repository

func learn_word(maya_word: String) -> void:
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

func has_learned_word(maya_word: String) -> bool:
	var key: String = _resolve_vocab_key(maya_word)
	return key != "" and key in words_learned

func get_vocabulary_entry(maya_word: String) -> Dictionary:
	var key: String = _resolve_vocab_key(maya_word)
	return {} if key == "" else VOCABULARY[key]

func get_learnable_vocabulary_keys() -> Array[String]:
	var keys: Array[String] = []
	for maya_word: String in VOCABULARY:
		if maya_word not in FUTURE_VOCABULARY:
			keys.append(maya_word)
	return keys

func get_learnable_word_count() -> int:
	return get_learnable_vocabulary_keys().size()

func recovered_pages_text() -> String:
	var count := get_recovered_word_count()
	return "%d %s" % [count, "página" if count == 1 else "páginas"]

func get_recovered_word_count() -> int:
	var count := 0
	for word: String in words_learned:
		if word in VOCABULARY and word not in FUTURE_VOCABULARY:
			count += 1
	return count

func get_book_illustration(maya_word: String) -> String:
	var key: String = _resolve_vocab_key(maya_word)
	return str(BOOK_ILLUSTRATIONS.get(key, ""))

func get_audio_filename(maya_word: String) -> String:
	var key: String = _resolve_vocab_key(maya_word)
	var source: String = key if key != "" else maya_word
	return _strip_accents(source).replace("'", "").replace("’", "").replace(" ", "_") + ".ogg"

func _resolve_vocab_key(word: String) -> String:
	if word in VOCABULARY:
		return word
	if word in VOCABULARY_ALIASES:
		return VOCABULARY_ALIASES[word]
	var normalized: String = _strip_accents(word).to_lower()
	for key: String in VOCABULARY:
		if _strip_accents(key).to_lower() == normalized:
			return key
	return ""

func _strip_accents(value: String) -> String:
	var result := value
	var pairs: Dictionary = {
		"á":"a", "é":"e", "í":"i", "ó":"o", "ú":"u", "ü":"u",
		"Á":"A", "É":"E", "Í":"I", "Ó":"O", "Ú":"U", "Ü":"U",
		"ñ":"n", "Ñ":"N",
	}
	for accented: String in pairs:
		result = result.replace(accented, pairs[accented])
	return result

func complete_level(world: int, level: int) -> void:
	var key: String = "w%d_l%d" % [world, level]
	if key not in completed_levels:
		completed_levels.append(key)
		_add_magic(MAGIC_PER_LEVEL)
	level_completed.emit(world, level)
	_save()

func is_level_completed(world: int, level: int) -> bool:
	return ("w%d_l%d" % [world, level]) in completed_levels

func next_unlocked_scene() -> String:
	for level_data: Dictionary in LEVEL_ORDER:
		if not is_level_completed(level_data.world, level_data.level):
			return level_data.scene_key
	return "main_menu"

func get_level_info(scene_key: String) -> Dictionary:
	for level_data: Dictionary in LEVEL_ORDER:
		if level_data.scene_key == scene_key:
			return level_data
	return {}

func all_levels_completed() -> bool:
	return next_unlocked_scene() == "main_menu"

func go_to_scene(key: String) -> void:
	if key not in SCENE_PATHS:
		push_error("GameManager: clave de escena desconocida '%s'" % key)
		return
	checkpoint_current_scene()
	if key != "main_menu":
		resume_scene_key = key
	elif get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SCENE_PATHS.world5_cine1:
		resume_scene_key = ""
	_save()
	var error: Error = get_tree().change_scene_to_file(SCENE_PATHS[key])
	if error != OK:
		push_error("GameManager: no se pudo abrir '%s' (error %d)" % [SCENE_PATHS[key], error])

func go_to_level(world: int, level: int) -> void:
	go_to_scene("world%d_level%d" % [world, level])

func reset_save() -> void:
	magic_points = 0
	words_learned = {}
	completed_levels = []
	resume_scene_key = ""
	scene_states.clear()
	tutorials_seen.clear()
	magic_points_changed.emit(0)
	progress_reset.emit()
	var error: Error = _get_save_repository().delete_progress()
	if error != OK:
		push_warning("GameManager: no se pudo borrar el progreso (error %d)" % error)

func _add_magic(amount: int) -> void:
	magic_points += amount
	magic_points_changed.emit(magic_points)

func _save() -> void:
	var data: Dictionary = {"version": SAVE_VERSION, "magic_points": magic_points, "words_learned": words_learned, "completed_levels": completed_levels, "resume_scene_key": resume_scene_key, "scene_states": scene_states, "tutorials_seen": tutorials_seen}
	var error: Error = _get_save_repository().save_progress(data)
	if error != OK:
		push_warning("GameManager: no se pudo guardar el progreso (error %d)" % error)

func _load_save() -> void:
	var result: Dictionary = _get_save_repository().load_progress()
	if result.has("_load_error"):
		push_warning("GameManager: %s" % result._load_error)
		return
	if result.is_empty():
		return
	magic_points = maxi(int(result.get("magic_points", 0)), 0)
	completed_levels = SAVE_REPOSITORY.sanitize_completed_levels(result.get("completed_levels", []), LEVEL_ORDER)
	resume_scene_key = str(result.get("resume_scene_key", ""))
	if resume_scene_key not in SCENE_PATHS or resume_scene_key == "main_menu":
		resume_scene_key = ""
	scene_states.clear()
	var loaded_states: Variant = result.get("scene_states", {})
	if loaded_states is Dictionary:
		for scene_key: String in loaded_states:
			if scene_key in SCENE_PATHS and loaded_states[scene_key] is Dictionary:
				scene_states[scene_key] = loaded_states[scene_key].duplicate(true)
	tutorials_seen.clear()
	var loaded_tutorials: Variant = result.get("tutorials_seen", [])
	if loaded_tutorials is Array:
		for tutorial: Variant in loaded_tutorials:
			if tutorial is String and tutorial not in tutorials_seen:
				tutorials_seen.append(tutorial)
	words_learned = {}
	var loaded_words: Variant = result.get("words_learned", {})
	if loaded_words is Dictionary:
		for old_key: String in loaded_words:
			var canonical_key := _resolve_vocab_key(old_key)
			if canonical_key != "":
				words_learned[canonical_key] = VOCABULARY[canonical_key].duplicate()
	# Sólo los guardados anteriores al sistema de niveles necesitan esta inferencia.
	if int(result.get("version", 0)) == 0:
		_migrate_completed_stage_from_words(3, 1, ["mejen", "nojoch", "ki'"])
		_migrate_completed_stage_from_words(4, 1, ["ja'", "ja'as", "pak'al", "K'úum"])
	magic_points_changed.emit(magic_points)

func _sanitize_completed_levels(value: Variant) -> Array[String]:
	return SAVE_REPOSITORY.sanitize_completed_levels(value, LEVEL_ORDER)

func _migrate_completed_stage_from_words(world: int, level: int, required_words: Array[String]) -> void:
	var progress_key := "w%d_l%d" % [world, level]
	if progress_key in completed_levels:
		return
	for maya_word: String in required_words:
		if not has_learned_word(maya_word):
			return
	completed_levels.append(progress_key)

func scene_key_for(node: Node) -> String:
	return str(SCENE_PATHS.find_key(node.scene_file_path)) if node.scene_file_path in SCENE_PATHS.values() else ""

func checkpoint(node: Node) -> void:
	var key := scene_key_for(node)
	if key.is_empty() or not node.has_method("get_checkpoint_state"):
		return
	scene_states[key] = node.get_checkpoint_state()
	if node == get_tree().current_scene and key != "main_menu":
		resume_scene_key = key
	_save()

func checkpoint_current_scene() -> void:
	if is_instance_valid(get_tree().current_scene):
		checkpoint(get_tree().current_scene)

func get_scene_state(node: Node) -> Dictionary:
	var state: Variant = scene_states.get(scene_key_for(node), {})
	return SAVE_REPOSITORY.sanitize_scene_state(state) if state is Dictionary else {}

func continue_adventure() -> void:
	if not resume_scene_key.is_empty():
		go_to_scene(resume_scene_key)
		return
	var next := next_unlocked_scene()
	if next == "main_menu":
		replay_scene(LEVEL_ORDER[0].scene_key)
	elif completed_levels.is_empty() and words_learned.is_empty():
		go_to_scene("intro")
	else:
		go_to_scene(str(get_level_info(next).get("story_key", next)))

func replay_scene(key: String) -> void:
	# Navegar antes de borrar evita que el checkpoint de salida restaure el estado viejo.
	go_to_scene(key)
	scene_states.erase(key)
	_save()

func mark_tutorial_seen(key: String) -> void:
	if key not in tutorials_seen:
		tutorials_seen.append(key)
		_save()

func quit_game() -> void:
	checkpoint_current_scene()
	_save()
	get_tree().quit()
