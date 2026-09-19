extends SceneTree

const GameManagerScript = preload("res://scripts/autoloads/GameManager.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_validate_level_order()
	_validate_vocabulary()
	if failures.is_empty():
		print("Validación del proyecto: OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_level_order() -> void:
	var seen_progress: Dictionary = {}
	var seen_scenes: Dictionary = {}
	for level_data: Dictionary in GameManagerScript.LEVEL_ORDER:
		var progress_key: String = "w%d_l%d" % [level_data.world, level_data.level]
		var scene_key: String = level_data.scene_key
		if seen_progress.has(progress_key):
			failures.append("Identificador de progreso duplicado: %s" % progress_key)
		seen_progress[progress_key] = true
		if seen_scenes.has(scene_key):
			failures.append("Clave de escena duplicada: %s" % scene_key)
		seen_scenes[scene_key] = true
		if not GameManagerScript.SCENE_PATHS.has(scene_key):
			failures.append("LEVEL_ORDER usa una clave inexistente: %s" % scene_key)
			continue
		var scene_path: String = GameManagerScript.SCENE_PATHS[scene_key]
		if not ResourceLoader.exists(scene_path):
			failures.append("No existe la escena: %s" % scene_path)
			continue
		var packed_scene: PackedScene = load(scene_path) as PackedScene
		if packed_scene == null:
			failures.append("No se pudo cargar la escena: %s" % scene_path)
			continue
		var instance: Node = packed_scene.instantiate()
		if instance == null:
			failures.append("No se pudo instanciar la escena: %s" % scene_path)
		else:
			instance.free()

func _validate_vocabulary() -> void:
	var manager: Node = GameManagerScript.new()
	var valid_stages: Dictionary = {}
	var audio_names: Dictionary = {}
	for level_data: Dictionary in GameManagerScript.LEVEL_ORDER:
		valid_stages["w%d_l%d" % [level_data.world, level_data.level]] = true
	for maya_word: String in GameManagerScript.VOCABULARY:
		var entry: Dictionary = GameManagerScript.VOCABULARY[maya_word]
		var stage_key: String = "w%d_l%d" % [entry.world, entry.level]
		if not valid_stages.has(stage_key):
			failures.append("%s apunta a una etapa inexistente: %s" % [maya_word, stage_key])
		var audio_name: String = manager.get_audio_filename(maya_word)
		if audio_names.has(audio_name):
			failures.append("Nombre de audio duplicado: %s" % audio_name)
		audio_names[audio_name] = maya_word
	var aliases: Dictionary = {
		"Míis": "Miis",
		"Káax": "Kaax",
		"Aak'": "Áak",
		"K'uum": "K'úum",
		"Ja'as": "ja'as",
	}
	for old_word: String in aliases:
		var canonical_word: String = aliases[old_word]
		if manager.get_vocabulary_entry(old_word) != GameManagerScript.VOCABULARY[canonical_word]:
			failures.append("No se migra la variante %s a %s" % [old_word, canonical_word])
	if manager.get_audio_filename("K'úum") != "Kuum.ogg":
		failures.append("El nombre de audio de K'úum debe ser Kuum.ogg")
	manager.free()
