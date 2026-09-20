extends SceneTree

const GameManagerScript = preload("res://scripts/autoloads/GameManager.gd")
const WindowManagerScript = preload("res://scripts/autoloads/WindowManager.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_validate_display_configuration()
	_validate_level_order()
	_validate_scene_registry()
	_validate_vocabulary()
	_validate_save_sanitization()
	_validate_theme()
	_validate_world3()
	_validate_world4()
	_validate_world5()
	_validate_book_catalog()
	await _validate_world1_instruction_layout()
	await _validate_world3_runtime()
	if failures.is_empty():
		print("Validación del proyecto: OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _validate_display_configuration() -> void:
	if ProjectSettings.get_setting("display/window/size/viewport_width") != 1280:
		failures.append("El ancho de diseño debe ser 1280")
	if ProjectSettings.get_setting("display/window/size/viewport_height") != 720:
		failures.append("El alto de diseño debe ser 720")
	if ProjectSettings.get_setting("display/window/stretch/mode") != "canvas_items":
		failures.append("El modo de escalado debe ser canvas_items")
	if ProjectSettings.get_setting("display/window/stretch/aspect") != "keep":
		failures.append("El escalado debe conservar la relación de aspecto")
	if not ProjectSettings.get_setting("display/window/size/resizable"):
		failures.append("La ventana debe poder redimensionarse")
	if WindowManagerScript.MIN_WINDOW_SIZE != Vector2i(960, 540):
		failures.append("El tamaño mínimo de ventana debe ser 960 × 540")
	if WindowManagerScript.MAX_WINDOW_SIZE != Vector2i(1920, 1080):
		failures.append("El tamaño máximo de ventana debe ser 1920 × 1080")

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
			var board: GridBoard = instance.find_child("GridBoard", true, false) as GridBoard
			if board != null:
				for issue: String in board.get_configuration_issues():
					failures.append("%s: %s" % [scene_path, issue])
			instance.free()

func _validate_scene_registry() -> void:
	var seen_paths: Dictionary = {}
	for scene_key: String in GameManagerScript.SCENE_PATHS:
		var scene_path: String = GameManagerScript.SCENE_PATHS[scene_key]
		if seen_paths.has(scene_path):
			failures.append("Ruta de escena duplicada: %s" % scene_path)
		seen_paths[scene_path] = true
		if not ResourceLoader.exists(scene_path, "PackedScene"):
			failures.append("La escena registrada no existe: %s (%s)" % [scene_path, scene_key])
			continue
		var packed_scene: PackedScene = load(scene_path) as PackedScene
		if packed_scene == null:
			failures.append("La escena registrada no se puede cargar: %s" % scene_path)
			continue
		var instance: Node = packed_scene.instantiate()
		if instance == null:
			failures.append("La escena registrada no se puede instanciar: %s" % scene_path)
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

func _validate_save_sanitization() -> void:
	var manager: Node = GameManagerScript.new()
	var sanitized: Array[String] = manager._sanitize_completed_levels(
		["w1_l1", "w1_l1", "etapa_inexistente", 42]
	)
	if sanitized != ["w1_l1"]:
		failures.append("El guardado no descarta niveles inválidos o duplicados")
	if not manager._sanitize_completed_levels("dato_invalido").is_empty():
		failures.append("El guardado acepta una lista de niveles con tipo inválido")
	manager.free()

func _validate_theme() -> void:
	var theme := load("res://themes/kalin_theme.tres") as Theme
	if theme == null:
		failures.append("No se pudo cargar el tema visual compartido")
		return
	var panel_variations: Array[StringName] = [
		&"KalinDialoguePanel", &"KalinCreamPanel", &"KalinDarkStatusPanel",
		&"KalinTopBarPanel", &"KalinRequestPanel", &"KalinSpellPanel",
		&"KalinChoicesPanel", &"KalinFeedbackPanel", &"KalinCompletionPanel",
		&"KalinBookCard",
	]
	for variation: StringName in panel_variations:
		if not theme.has_stylebox(&"panel", variation):
			failures.append("Falta la variación visual %s" % variation)
	for variation: StringName in [&"KalinPrimaryButton", &"KalinSecondaryButton", &"KalinNounButton", &"KalinAdjectiveButton", &"KalinAudioButton"]:
		if not theme.has_stylebox(&"normal", variation):
			failures.append("Falta la variación de botón %s" % variation)
	for variation: StringName in [&"KalinNounSlot", &"KalinAdjectiveSlot"]:
		if not theme.has_stylebox(&"normal", variation):
			failures.append("Falta la variación de espacio de frase %s" % variation)

func _validate_world1_instruction_layout() -> void:
	var level_paths: Array[String] = [
		"res://scenes/world1/Level1_CaminosBlancos.tscn",
		"res://scenes/world1/Level2_AnimalesBosque.tscn",
		"res://scenes/world1/Level3_GuardianesMonte.tscn",
		"res://scenes/world1/Level4_AguaYCielo.tscn",
	]
	for level_path: String in level_paths:
		var packed_scene := load(level_path) as PackedScene
		if packed_scene == null:
			failures.append("No se pudo comprobar la instrucción de %s" % level_path)
			continue
		var level := packed_scene.instantiate()
		root.add_child(level)
		await process_frame
		var instruction := level.get_node_or_null("UI/InstrPanel/InstrLbl") as Label
		if instruction == null:
			failures.append("Falta el texto de instrucciones en %s" % level_path)
		elif instruction.text.contains("\n") or instruction.get_line_count() != 1:
			failures.append("La instrucción debe mostrarse en una sola línea en %s" % level_path)
		level.queue_free()
		await process_frame

func _validate_world3() -> void:
	var world3_script: Script = load("res://scripts/world3/W3_Level1.gd") as Script
	if world3_script == null:
		failures.append("No se pudo cargar el script del Mundo 3")
		return
	if world3_script.CHALLENGES.size() != 6:
		failures.append("El Mundo 3 debe contener las seis peticiones definidas por el GDD")
	if world3_script.ADJECTIVES.size() != 5:
		failures.append("El Mundo 3 debe enseñar los cinco adjetivos definidos por el GDD")
	var combinations: Dictionary = {}
	var used_adjectives: Dictionary = {}
	for challenge: Dictionary in world3_script.CHALLENGES:
		for required_field: String in ["animal", "sprite", "noun", "adjective", "phrase", "translation"]:
			if str(challenge.get(required_field, "")).is_empty():
				failures.append("Petición del Mundo 3 sin campo obligatorio: %s" % required_field)
		var noun: String = challenge.get("noun", "")
		var adjective: String = challenge.get("adjective", "")
		if not GameManagerScript.VOCABULARY.has(noun):
			failures.append("Sustantivo desconocido en Mundo 3: %s" % noun)
		if not GameManagerScript.VOCABULARY.has(adjective):
			failures.append("Adjetivo desconocido en Mundo 3: %s" % adjective)
		elif GameManagerScript.VOCABULARY[adjective].world != 3:
			failures.append("El adjetivo %s no pertenece al Mundo 3" % adjective)
		var combination := "%s|%s" % [noun, adjective]
		if combinations.has(combination):
			failures.append("Combinación duplicada en Mundo 3: %s" % combination)
		combinations[combination] = true
		used_adjectives[adjective] = true
		if not ResourceLoader.exists(challenge.sprite):
			failures.append("Sprite inexistente en Mundo 3: %s" % challenge.sprite)
	for adjective: Dictionary in world3_script.ADJECTIVES:
		if not used_adjectives.has(adjective.maya):
			failures.append("El adjetivo %s no se practica en ninguna petición" % adjective.maya)

func _validate_world4() -> void:
	var world4_script := load("res://scripts/world4/W4_Level1.gd") as Script
	if world4_script == null:
		failures.append("No se pudo cargar el script del Mundo 4")
		return
	if world4_script.CHALLENGES.size() != 6:
		failures.append("El Mundo 4 debe contener las seis peticiones del GDD")
	if world4_script.FOODS.size() != 5:
		failures.append("El Mundo 4 debe ofrecer los cinco alimentos de sus peticiones")
	if world4_script.MODIFIERS.size() != 3:
		failures.append("El Mundo 4 debe permitir elegir sin cualidad, mejen o nojoch")
	for challenge: Dictionary in world4_script.CHALLENGES:
		for field: String in ["animal", "sprite", "food", "modifier", "phrase", "translation"]:
			if not challenge.has(field):
				failures.append("Petición del Mundo 4 sin campo obligatorio: %s" % field)
		if not GameManagerScript.VOCABULARY.has(challenge.food):
			failures.append("Alimento desconocido en Mundo 4: %s" % challenge.food)
		if challenge.modifier != "" and not GameManagerScript.VOCABULARY.has(challenge.modifier):
			failures.append("Cualidad desconocida en Mundo 4: %s" % challenge.modifier)
		if not ResourceLoader.exists(challenge.sprite):
			failures.append("Sprite inexistente en Mundo 4: %s" % challenge.sprite)

func _validate_world5() -> void:
	var world5_script := load("res://scripts/world5/W5_Level1.gd") as Script
	if world5_script == null:
		failures.append("No se pudo cargar el script del Mundo 5")
		return
	if world5_script.CHALLENGES.size() != 8:
		failures.append("El Mundo 5 debe recuperar ocho fragmentos del portal")
	for challenge: Dictionary in world5_script.CHALLENGES:
		for field: String in ["section", "prompt", "clue", "correct", "options", "learn"]:
			if not challenge.has(field):
				failures.append("Fragmento del Mundo 5 sin campo obligatorio: %s" % field)
		if challenge.correct not in challenge.options:
			failures.append("La respuesta correcta del Mundo 5 no aparece entre sus opciones")
		if challenge.learn != "" and not GameManagerScript.VOCABULARY.has(challenge.learn):
			failures.append("Frase nueva del Mundo 5 ausente del vocabulario: %s" % challenge.learn)

func _validate_book_catalog() -> void:
	var manager := GameManagerScript.new()
	var learnable := manager.get_learnable_vocabulary_keys()
	for future_word: String in GameManagerScript.FUTURE_VOCABULARY:
		if future_word in learnable:
			failures.append("El vocabulario futuro no debe contar para completar el libro: %s" % future_word)
	if learnable.size() != GameManagerScript.VOCABULARY.size() - GameManagerScript.FUTURE_VOCABULARY.size():
		failures.append("La cuenta de entradas recuperables del libro es inconsistente")
	manager.free()

func _validate_world3_runtime() -> void:
	var packed_scene := load("res://scenes/world3/Level3_HechizosAdjetivos.tscn") as PackedScene
	if packed_scene == null:
		failures.append("No se pudo preparar la prueba interactiva del Mundo 3")
		return
	var level := packed_scene.instantiate()
	root.add_child(level)
	await process_frame
	var noun_grid := level.get_node_or_null("UI/ChoicesPanel/Content/NounGrid") as GridContainer
	var adjective_grid := level.get_node_or_null("UI/ChoicesPanel/Content/AdjectiveGrid") as GridContainer
	var cast_button := level.get_node_or_null("UI/ChoicesPanel/Content/CastButton") as Button
	if noun_grid == null or noun_grid.get_child_count() != 5:
		failures.append("La interfaz del Mundo 3 no creó las cinco opciones de sustantivo")
	if adjective_grid == null or adjective_grid.get_child_count() != 5:
		failures.append("La interfaz del Mundo 3 no creó las cinco opciones de adjetivo")
	if cast_button == null or not cast_button.disabled:
		failures.append("El hechizo debe permanecer bloqueado hasta elegir ambas palabras")
	if level.noun_buttons.has("chan") and level.adjective_buttons.has("jach'"):
		(level.noun_buttons["chan"] as Button).pressed.emit()
		(level.adjective_buttons["jach'"] as Button).pressed.emit()
		if level.selected_noun != "chan" or level.selected_adjective != "jach'":
			failures.append("Los botones del Mundo 3 no actualizan la frase seleccionada")
		if cast_button.disabled:
			failures.append("El botón de hechizo no se habilita al completar los dos espacios")
	else:
		failures.append("Faltan las opciones necesarias para la primera petición del Mundo 3")
	level.queue_free()
	await process_frame
