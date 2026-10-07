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
	_validate_stories()
	_validate_explorations()
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
				if int(level_data.world) == 1 and board.columns != 12:
					failures.append("%s debe usar el tablero ampliado de 12 columnas" % scene_path)
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

## Cada capítulo de historia debe usar vocabulario existente con ilustración,
## plantear preguntas que se puedan responder y continuar hacia una escena real.
func _validate_stories() -> void:
	for level_data: Dictionary in GameManagerScript.LEVEL_ORDER:
		var story_key: String = level_data.get("story_key", "")
		if story_key != "" and not GameManagerScript.SCENE_PATHS.has(story_key):
			failures.append("LEVEL_ORDER usa un capítulo inexistente: %s" % story_key)
	for scene_key: String in GameManagerScript.SCENE_PATHS:
		if not scene_key.contains("_story") and not scene_key.contains("_cine"):
			continue
		var scene_path: String = GameManagerScript.SCENE_PATHS[scene_key]
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			failures.append("No se pudo cargar el capítulo %s" % scene_key)
			continue
		var story: Node = packed_scene.instantiate()
		if story.beats.is_empty():
			failures.append("%s no tiene momentos de historia" % scene_path)
		if not GameManagerScript.SCENE_PATHS.has(story.next_scene_key):
			failures.append("%s continúa hacia una escena inexistente: %s" % [scene_path, story.next_scene_key])
		for beat: StoryBeat in story.beats:
			_validate_story_beat(scene_path, beat)
		if scene_key.contains("_cine"):
			_validate_cinematic(scene_path, story)
		story.free()
	_validate_story_effects_template()
	_validate_story_chain()

## Las cinemáticas avanzan solas, salvo el momento final, que espera al jugador
## para no cambiar de escena sin aviso.
func _validate_cinematic(scene_path: String, story: Node) -> void:
	for index: int in range(story.beats.size()):
		var beat: StoryBeat = story.beats[index]
		if beat.kind != StoryBeat.Kind.DIALOGO:
			failures.append("%s: las cinemáticas solo usan momentos DIALOGO" % scene_path)
		var is_last: bool = index == story.beats.size() - 1
		if beat.auto_advance <= 0.0 and not is_last and beat.speaker == "Narrador":
			failures.append("%s: el momento %d de la cinemática no avanza solo" % [scene_path, index + 1])

## Los efectos disponibles en StoryBeat deben existir como partículas en la plantilla.
func _validate_story_effects_template() -> void:
	var packed := load("res://scenes/components/StoryScene.tscn") as PackedScene
	var template: Node = packed.instantiate()
	var effects_root: Node = template.get_node_or_null("Effects")
	if effects_root == null:
		failures.append("StoryScene no tiene el nodo Effects")
	else:
		for node_name: String in template.CONTINUOUS_EFFECTS.values():
			var particles := effects_root.get_node_or_null(node_name) as CPUParticles2D
			if particles == null:
				failures.append("StoryScene no tiene el efecto %s" % node_name)
			elif particles.texture == null:
				failures.append("El efecto %s no tiene textura" % node_name)
		for node_name: String in ["ConfetiPaginas", "ConfetiChispas"]:
			var burst := effects_root.get_node_or_null(node_name) as CPUParticles2D
			if burst == null or not burst.one_shot:
				failures.append("StoryScene necesita el estallido de una sola vez %s" % node_name)
	for node_path: String in ["Ambient", "BackgroundNext", "AutoTimer", "UI/TitleCard/TitleLabel", "UI/TitleCard/SubtitleLabel", "UI/Flash"]:
		if template.get_node_or_null(node_path) == null:
			failures.append("StoryScene no tiene el nodo %s" % node_path)
	for mood: int in StoryBeat.Mood.values():
		if mood != StoryBeat.Mood.SIN_CAMBIO and not template.AMBIENT_COLORS.has(mood):
			failures.append("StoryScene no define el color del ambiente %d" % mood)
	template.free()

## La historia debe encadenarse sin callejones: intro, cinemáticas y capítulos.
func _validate_story_chain() -> void:
	var expected: Dictionary = {
		"world1_cine1": "world1_explore1",
		"world1_explore1": "world1_story1",
		"world1_story5": "world1_cine2",
		"world1_cine2": "world2_level1",
		"world5_story1": "world5_cine1",
		"world5_cine1": "main_menu",
	}
	for scene_key: String in expected:
		var packed := load(GameManagerScript.SCENE_PATHS[scene_key]) as PackedScene
		var story: Node = packed.instantiate()
		if story.next_scene_key != expected[scene_key]:
			failures.append("%s debe continuar hacia %s, no hacia %s" % [scene_key, expected[scene_key], story.next_scene_key])
		story.free()

## Cada exploración necesita un sendero, objetos con diálogo y dibujo, una sola
## meta al final del camino y continuar hacia una escena real.
func _validate_explorations() -> void:
	var found: int = 0
	for scene_key: String in GameManagerScript.SCENE_PATHS:
		if not scene_key.contains("_explore"):
			continue
		found += 1
		var scene_path: String = GameManagerScript.SCENE_PATHS[scene_key]
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			failures.append("No se pudo cargar la exploración %s" % scene_key)
			continue
		var exploration: Node = packed_scene.instantiate()
		_validate_exploration(scene_path, exploration)
		exploration.free()
	if found == 0:
		failures.append("No hay escenas de exploración registradas en SCENE_PATHS")
	for action: String in ["kalin_izquierda", "kalin_derecha", "kalin_interactuar"]:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			failures.append("Falta la acción de entrada %s en project.godot" % action)

func _validate_exploration(scene_path: String, exploration: Node) -> void:
	if not GameManagerScript.SCENE_PATHS.has(exploration.next_scene_key):
		failures.append("%s continúa hacia una escena inexistente: %s" % [scene_path, exploration.next_scene_key])
	for node_path: String in ["Cielo", "Terreno", "Animales", "Kalin/Sprite", "Kalin/Camera", "Kalin/Magia", "UI/PromptButton", "UI/Flecha", "UI/DialogueBox/DialogueText", "UI/Fade"]:
		if exploration.get_node_or_null(node_path) == null:
			failures.append("%s no tiene el nodo %s" % [scene_path, node_path])
	var sendero := exploration.get_node_or_null("Sendero") as Path2D
	if sendero == null or sendero.curve == null or sendero.curve.point_count < 2:
		failures.append("%s necesita un Path2D «Sendero» con al menos dos puntos" % scene_path)
		return
	var start_x: float = sendero.to_global(sendero.curve.get_point_position(0)).x
	var end_x: float = sendero.to_global(sendero.curve.get_point_position(sendero.curve.point_count - 1)).x
	var goals: int = 0
	var goal_x: float = -INF
	var last_spot_x: float = -INF
	for child: Node in exploration.get_node("Spots").get_children():
		var spot := child as ExplorationSpot
		if spot == null:
			failures.append("%s: %s no es un ExplorationSpot" % [scene_path, child.name])
			continue
		if spot.lines.is_empty():
			failures.append("%s: %s no tiene diálogo" % [scene_path, spot.name])
		for line: String in spot.lines:
			if line.strip_edges() == "":
				failures.append("%s: %s tiene una línea vacía" % [scene_path, spot.name])
		if spot.position.x < start_x or spot.position.x > end_x:
			failures.append("%s: %s está fuera del sendero" % [scene_path, spot.name])
		if spot.blocks_path and spot.reaction != ExplorationSpot.Reaction.APARTAR:
			failures.append("%s: el obstáculo %s debe apartarse al examinarlo" % [scene_path, spot.name])
		if spot.is_goal:
			goals += 1
			goal_x = spot.position.x
			if spot.blocks_path:
				failures.append("%s: la meta no puede bloquear el camino" % scene_path)
			continue
		last_spot_x = maxf(last_spot_x, spot.position.x)
		if (spot.get_node("Sprite") as Sprite2D).texture == null:
			failures.append("%s: %s no tiene dibujo" % [scene_path, spot.name])
	if goals != 1:
		failures.append("%s debe tener exactamente una meta (tiene %d)" % [scene_path, goals])
	elif last_spot_x > goal_x:
		failures.append("%s: la meta debe ser el último punto del sendero" % scene_path)

func _validate_story_beat(scene_path: String, beat: StoryBeat) -> void:
	if beat.effects < 0 or beat.effects > 31:
		failures.append("%s usa efectos fuera de rango: %d" % [scene_path, beat.effects])
	if beat.auto_advance < 0.0:
		failures.append("%s tiene un avance automático negativo" % scene_path)
	if beat.subtitle != "" and beat.title == "":
		failures.append("%s tiene subtítulo pero no título" % scene_path)
	if beat.background != null and not ResourceLoader.exists(beat.background.resource_path):
		failures.append("%s usa un fondo que no existe: %s" % [scene_path, beat.background.resource_path])
	if beat.actors.size() > 4:
		failures.append("%s muestra más de cuatro animales a la vez" % scene_path)
	for word: String in beat.actors:
		if not GameManagerScript.VOCABULARY.has(word):
			failures.append("%s usa un animal fuera del vocabulario: %s" % [scene_path, word])
			continue
		var illustration: String = GameManagerScript.BOOK_ILLUSTRATIONS.get(word, "")
		if illustration == "" or not ResourceLoader.exists(illustration):
			failures.append("%s usa a %s, que no tiene ilustración" % [scene_path, word])
	if beat.kind == StoryBeat.Kind.CONOCER and beat.actors.is_empty():
		failures.append("%s pide conocer animales, pero no hay ninguno en escena" % scene_path)
	if beat.kind == StoryBeat.Kind.ADIVINAR:
		if beat.target_word not in beat.actors:
			failures.append("%s pregunta por %s, que no está en escena" % [scene_path, beat.target_word])
		if beat.speaker == beat.target_word:
			failures.append("%s: quien pregunta no debe ser la respuesta (%s)" % [scene_path, beat.target_word])
	if beat.kind == StoryBeat.Kind.ELEGIR:
		if beat.options.size() < 2 or beat.target_word not in beat.options:
			failures.append("%s: ELEGIR necesita varias opciones que incluyan %s" % [scene_path, beat.target_word])
		for word: String in beat.options:
			if not GameManagerScript.VOCABULARY.has(word):
				failures.append("%s ofrece una palabra fuera del vocabulario: %s" % [scene_path, word])
		# Las estructuras con marcadores como [sust.] necesitan la frase completa.
		var target_entry: Dictionary = GameManagerScript.VOCABULARY.get(beat.target_word, {})
		if str(target_entry.get("estructura", "")).contains("[") and beat.reveal_phrase.is_empty():
			failures.append("%s: %s necesita reveal_phrase con la frase completa" % [scene_path, beat.target_word])
