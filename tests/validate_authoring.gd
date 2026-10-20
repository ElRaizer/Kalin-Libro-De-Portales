## Regresiones del contrato de autoría durante animaciones y cambios de estado.
extends SceneTree

var failures: Array[String] = []
var manager: Node
const TINT := Color(0.65, 0.78, 0.91, 0.72)
const SCALE := Vector2(0.73, 0.86)
const ANGLE := 0.17

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _mount(node: Node) -> void:
	manager.scene_states.clear()
	manager.resume_scene_key = ""
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	root.add_child(node)
	current_scene = node

func _release(node: Node) -> void:
	current_scene = null
	node.queue_free()
	await process_frame
	await process_frame

func _run() -> void:
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new("user://authoring_validation.json")
	manager.scene_states.clear()
	manager.completed_levels.clear()
	manager.words_learned.clear()
	await _buttons_and_slots()
	await _reactions_and_illustrations()
	await _narrative()
	await _vignettes()
	await _exploration()
	await _rounds()
	await _default_feedback_colors()
	await _map_and_focus()
	await _board_and_dialogue()
	await _intro_and_guides()
	_legacy_content()
	if failures.is_empty():
		print("Validación de autoría durante la partida: OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _buttons_and_slots() -> void:
	var button := DraggableWordButton.new()
	button.scale = SCALE
	var style := StyleBoxFlat.new()
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_pressed_color", TINT)
	_mount(button)
	button._on_button_down()
	button._on_button_down()
	button._on_button_up()
	button._clear_active_press_style()
	_check(button.get_theme_stylebox("pressed") == style, "Soltar una palabra debe restaurar el estilo de presión del Inspector")
	_check(button.get_theme_color("font_pressed_color") == TINT, "Soltar una palabra debe restaurar su color de texto")
	button._punch(Vector2(0.9, 0.9), Vector2.ONE)
	button._hover_tween.custom_step(1)
	_check(button.scale.is_equal_approx(SCALE), "El pulso del botón debe conservar su escala de autor")
	button.remove_theme_stylebox_override("pressed")
	button.remove_theme_color_override("font_pressed_color")
	button._on_button_down()
	button._on_button_up()
	_check(not button.has_theme_stylebox_override("pressed") and not button.has_theme_color_override("font_pressed_color"), "Los botones sin ajustes locales deben volver al tema heredado")
	await _release(button)
	var slot := load("res://scenes/components/WordDropSlot.tscn").instantiate() as WordDropSlot
	slot.modulate = TINT
	slot.scale = SCALE
	_mount(slot)
	for effect: String in ["_glow", "_reset_visual", "pop", "pulse_error", "_reset_visual"]:
		slot.call(effect)
		slot._slot_tween.custom_step(1)
		if effect != "_glow":
			_check(slot.scale.is_equal_approx(SCALE) and slot.modulate.is_equal_approx(TINT), "El destino debe recuperar su escala y tinte tras " + effect)
	slot.pop()
	slot._slot_tween.custom_step(0.03)
	slot.pulse_error()
	slot._slot_tween.custom_step(1)
	_check(slot.scale.is_equal_approx(SCALE) and slot.modulate.is_equal_approx(TINT), "Un error que interrumpe el pulso de selección debe recuperar la presentación de autor")
	await _release(slot)

func _reactions_and_illustrations() -> void:
	var actor := TextureRect.new()
	actor.texture = manager.get_visual_texture("Peek'")
	actor.scale = SCALE
	actor.rotation = ANGLE
	actor.pivot_offset = Vector2(13, 27)
	_mount(actor)
	var reaction: Script = load("res://scripts/components/CharacterReaction.gd")
	reaction.play(actor)
	(actor.get_meta("reaction_tween") as Tween).custom_step(0.1)
	reaction.play(actor, false)
	(actor.get_meta("reaction_tween") as Tween).custom_step(3)
	_check(actor.scale.is_equal_approx(SCALE) and is_equal_approx(actor.rotation, ANGLE), "Repetir una reacción debe recuperar la transformación inicial")
	_check(actor.pivot_offset == Vector2(13, 27), "Las reacciones deben respetar el pivote del personaje")
	await _release(actor)
	var art := load("res://scenes/components/MeaningIllustration.tscn").instantiate() as MeaningIllustration
	art.scale = SCALE
	_mount(art)
	art.celebrate()
	art.celebration.custom_step(0.1)
	art.celebrate()
	art.celebration.custom_step(1)
	_check(art.scale.is_equal_approx(SCALE), "Celebrar una ilustración no debe cambiar su tamaño de autor")
	await _release(art)
	var overlay := load("res://scenes/components/CompletionOverlay.tscn").instantiate() as CompletionOverlay
	var panel := overlay.get_node("Shade/Panel") as Panel
	panel.scale = SCALE
	panel.modulate = TINT
	_mount(overlay)
	overlay.show_completion("Prueba", "Prueba")
	overlay._show_tween.custom_step(1)
	_check(panel.scale.is_equal_approx(SCALE) and panel.modulate.is_equal_approx(TINT), "La celebración final debe respetar escala y opacidad del panel")
	await _release(overlay)

func _narrative() -> void:
	var story: Node = load(manager.SCENE_PATHS.world1_story1).instantiate()
	var kalin := story.get_node("Stage/Kalin") as TextureRect
	kalin.scale = SCALE
	kalin.rotation = ANGLE
	kalin.modulate = TINT
	kalin.z_index = 3
	story.position = Vector2(7, 11)
	var choice := story.get_node("UI/Choices").get_child(0) as Button
	choice.theme_type_variation = &"KalinPrimaryButton"
	_mount(story)
	var options: Array[String] = ["nojoch"]
	story._build_choices(options)
	_check(choice.theme_type_variation == &"KalinPrimaryButton", "Las opciones narrativas deben respetar una variante de tema personalizada")
	story._play_kalin_motion(StoryBeat.KalinMotion.QUIETO)
	_check(kalin.scale.is_equal_approx(SCALE) and is_equal_approx(kalin.rotation, ANGLE) and kalin.modulate.is_equal_approx(TINT), "Iniciar un capítulo debe conservar la transformación y tinte de Kalin")
	story._animate_speaker("Kalin")
	story._animator._speaker_tween.custom_step(1)
	_check(kalin.scale.is_equal_approx(SCALE), "Hablar debe recuperar la escala de Kalin")
	story._play_kalin_motion(StoryBeat.KalinMotion.DORMIDO)
	story._play_kalin_motion(StoryBeat.KalinMotion.QUIETO)
	story._animator._kalin_motion_tween.custom_step(1)
	_check(kalin.scale.is_equal_approx(SCALE) and is_equal_approx(kalin.rotation, ANGLE), "Levantarse debe recuperar la transformación del Inspector")
	story._play_kalin_motion(StoryBeat.KalinMotion.CRUZA)
	story._animator._kalin_motion_tween.custom_step(2)
	_check(kalin.scale.is_equal_approx(SCALE * story.CROSS_SCALE), "Cruzar el portal debe reducir la escala de autor proporcionalmente")
	story._play_kalin_motion(StoryBeat.KalinMotion.QUIETO)
	_check(kalin.z_index == 3 and kalin.modulate.is_equal_approx(TINT), "Salir del efecto debe restaurar opacidad y orden de dibujo")
	story._shake_screen()
	story._animator._shake_tween.custom_step(2)
	_check(story.position == Vector2(7, 11), "Sacudir la pantalla debe devolver la escena a su posición original")
	await _release(story)

func _vignettes() -> void:
	var loop := load("res://scenes/components/StoryVignette.tscn").instantiate() as StoryVignette
	for path: String in ["Actor", "Prop", "Reward"]:
		var control := loop.get_node(path) as Control
		control.scale = SCALE
		control.rotation = ANGLE
		control.modulate = TINT
	_mount(loop)
	for situation: String in ["camino", "casa", "tamano", "hambre", "portal"]:
		loop.show_situation(situation)
		loop.seek_cycle(0)
		_check(loop.actor.scale.is_equal_approx(SCALE) and is_equal_approx(loop.actor.rotation, ANGLE), "La viñeta debe conservar la transformación del actor en " + situation)
		_check(loop.prop.scale.is_equal_approx(SCALE) and is_equal_approx(loop.prop.rotation, ANGLE), "La viñeta debe conservar la transformación del objeto en " + situation)
		_check(is_equal_approx(loop.prop.modulate.r, TINT.r), "La viñeta debe conservar el tinte del objeto en " + situation)
		loop.seek_cycle(1.7)
		loop.seek_cycle(0)
		_check(loop.actor.scale.is_equal_approx(SCALE), "El bucle no debe acumular cambios de escala")
	loop.show_reward("lak", "Jats'uts", "Kaax")
	loop.seek_cycle(0)
	_check(loop.prop.scale.is_equal_approx(SCALE) and loop.prop.modulate.is_equal_approx(TINT), "El regalo debe conservar su presentación al reutilizar la viñeta")
	await _release(loop)

func _exploration() -> void:
	var level: Node = load(manager.SCENE_PATHS.world1_explore1).instantiate()
	var sprite := level.get_node("Kalin/Sprite") as Sprite2D
	sprite.position = Vector2(9, -16)
	sprite.rotation = ANGLE
	var objective := level.get_node("UI/ObjectivePanel/Content/ObjectiveLabel") as Label
	objective.add_theme_color_override("font_color", TINT)
	var camera := level.get_node("Kalin/Camera") as Camera2D
	camera.limit_left = -150
	camera.limit_right = 4200
	camera.limit_top = -80
	camera.limit_bottom = 900
	_mount(level)
	_check(sprite.position.is_equal_approx(Vector2(9, -16)) and is_equal_approx(sprite.rotation, ANGLE), "Reposar debe conservar el desplazamiento y giro de Kalin")
	_check(camera.limit_left == -150 and camera.limit_right == 4200 and camera.limit_top == -80 and camera.limit_bottom == 900, "La exploración debe respetar los límites de cámara configurados")
	level._show_notice("Prueba")
	level._restore_objective()
	_check(objective.get_theme_color("font_color") == TINT, "Cerrar un aviso debe recuperar el color del objetivo")
	await _release(level)
	var spot := load("res://scenes/components/ExplorationSpot.tscn").instantiate() as ExplorationSpot
	(spot.get_node("Sprite") as Sprite2D).modulate = TINT
	_mount(spot)
	spot._process(0.2)
	spot.mark_examined()
	_check(spot.sprite.modulate.is_equal_approx(TINT), "Examinar un objeto debe restaurar su tinte original")
	await _release(spot)

func _rounds() -> void:
	for world: int in range(2, 6):
		var key := "world%d_level1" % world
		var level: Node = load(manager.SCENE_PATHS[key]).instantiate()
		if world == 5:
			level.content = level.content.duplicate(true)
			level.content.challenges[0].clue = "Una pista editada sin separadores especiales"
		var label := level.get_node("UI/FeedbackPanel/FeedbackLbl" if world == 2 else "UI/FeedbackPanel/FeedbackLabel") as Label
		label.offset_left = 31
		label.add_theme_color_override("font_color", TINT)
		var grid: Control
		if world in [3, 4]:
			grid = level.get_node("UI/ChoicesPanel/Content/NounGrid" if world == 3 else "UI/ChoicesPanel/Content/FoodGrid")
			grid.modulate = TINT
			for button: Button in grid.get_children():
				button.custom_minimum_size = Vector2(161, 101)
				button.add_theme_constant_override("icon_max_width", 43)
		_mount(level)
		_check(label.offset_left == 31 and label.get_theme_color("font_color") == TINT, key + " debe conservar el margen y color del mensaje inicial")
		if world == 5:
			_check(level.clue_label.text == level.content.challenges[0].clue, "El portal debe mostrar el texto completo de la pista editada")
		if world == 2:
			level._render_success(false)
			level._show_round()
		elif world == 3:
			level._select_noun(level._current_challenge().noun)
			level._show_round()
		elif world == 4:
			level._select_food(level._current_challenge().food)
			level._show_round()
		else:
			level._render_success(false)
			level._show_challenge()
		_check(label.offset_left == 31 and label.get_theme_color("font_color") == TINT, key + " debe recuperar el margen y color al volver a la petición")
		if grid:
			_check(grid.modulate.is_equal_approx(TINT), key + " debe conservar el tinte de las opciones al cambiar el énfasis")
			if world == 3:
				_check((grid.get_child(0) as Button).get_theme_constant("icon_max_width") == 43, "El taller debe respetar el tamaño de icono del Inspector")
			else:
				level.round_index = 1
				level._show_round()
				var button := grid.get_child(0) as Button
				_check(button.custom_minimum_size == Vector2(161, 101) and button.get_theme_constant("icon_max_width") == 43, "Mostrar tamaños debe recuperar las medidas configuradas de las tarjetas")
		await _release(level)

func _map_and_focus() -> void:
	var menu: Node = load(manager.SCENE_PATHS.main_menu).instantiate()
	var first := menu.get_node("UI/WorldMap/World1") as Button
	var marker := menu.get_node("UI/WorldMap/KalinLocation") as TextureRect
	first.modulate = TINT
	marker.position += Vector2(7, 9)
	var offset := marker.position - first.position
	var focus_style := StyleBoxFlat.new()
	first.add_theme_stylebox_override("focus", focus_style)
	_mount(menu)
	menu._select_world(2)
	menu._select_world(1)
	_check(first.modulate.is_equal_approx(TINT), "Cambiar de mundo debe recuperar el tinte configurado del botón")
	_check(marker.position.is_equal_approx(first.position + offset), "El marcador debe conservar el desplazamiento del Inspector")
	first.grab_focus()
	var accessibility: Node = root.get_node("AccessibilityManager")
	accessibility._hide_keyboard_visuals()
	accessibility._hide_keyboard_visuals()
	accessibility._show_keyboard_visuals()
	_check(first.get_theme_stylebox("focus") == focus_style, "Cambiar de ratón a teclado debe restaurar el estilo de foco personalizado")
	accessibility._show_keyboard_visuals()
	_check(first.get_theme_stylebox("focus") == focus_style, "La navegación de teclado no debe borrar estilos que no ocultó")
	await _release(menu)

func _default_feedback_colors() -> void:
	for world: int in range(2, 6):
		var level: Node = load(manager.SCENE_PATHS["world%d_level1" % world]).instantiate()
		_mount(level)
		var label: Label = level.get_node("UI/FeedbackPanel/FeedbackLbl" if world == 2 else "UI/FeedbackPanel/FeedbackLabel")
		_check(label.get_theme_color("font_color").get_luminance() < 0.5, "El mensaje inicial del mundo %d debe ser oscuro sobre el panel claro" % world)
		if world == 2:
			_check(level.word_lbl.get_theme_color("font_color").get_luminance() < 0.5, "La palabra de la casa debe conservar un color legible en su escena")
		await _release(level)

func _board_and_dialogue() -> void:
	var level: Node = load(manager.SCENE_PATHS.world1_level2).instantiate()
	var board := level.get_node("GridBoard") as GridBoard
	var word := board.get_node("Preview/Word_0") as Control
	var tile := board.get_node("Preview/Tile_0_0") as Control
	var obstacle_cell := board.obstacles[0]
	var obstacle := board.get_node("Preview/Tile_%d_%d" % [obstacle_cell.x, obstacle_cell.y]) as Control
	word.modulate = TINT
	tile.modulate = TINT
	obstacle.modulate = TINT
	var dialogue := level.get_node("UI/DialoguePanel/VBox") as Control
	dialogue.offset_left = 123
	dialogue.offset_right = 777
	_mount(level)
	board.focus_first_path(true)
	board.focus_first_path(false)
	board._set_tile_color(Vector2i.ZERO, Color.RED)
	board._reset_tile(Vector2i.ZERO)
	board.set_obstacle_clues_visible(false)
	board.set_obstacle_clues_visible(true)
	_check(word.modulate.is_equal_approx(TINT) and tile.modulate.is_equal_approx(TINT) and obstacle.modulate.is_equal_approx(TINT), "El tablero debe conservar los tintes al quitar foco, caminos y pistas")
	level._show_word_dialogue(board.words[0], 0)
	_check(dialogue.offset_left == 123 and dialogue.offset_right == 777, "Abrir el diálogo de un animal debe respetar sus márgenes de autor")
	await _release(level)

func _intro_and_guides() -> void:
	var intro: Node = load(manager.SCENE_PATHS.intro).instantiate()
	var timer := intro.get_node("TypewriterTimer") as Timer
	timer.wait_time = 0.067
	_mount(intro)
	_check(is_equal_approx(timer.wait_time, 0.067), "La introducción debe usar la velocidad de escritura configurada en el temporizador")
	await _release(intro)
	var guide := load("res://scenes/components/LearningGuide.tscn").instantiate() as LearningGuide
	(guide.get_node("Hand") as Control).modulate = TINT
	_mount(guide)
	guide.point_at(guide.hand)
	_check(is_equal_approx(guide.hand.modulate.a, TINT.a * 0.95), "La ayuda debe respetar la opacidad de su mano")
	await _release(guide)

func _legacy_content() -> void:
	var entry := ExerciseEntry.new()
	entry.color = TINT
	entry.emoji = "Anterior"
	entry.symbol = "Símbolo anterior"
	var path := "user://authoring_legacy_entry.tres"
	_check(ResourceSaver.save(entry, path) == OK, "Los campos antiguos deben poder seguir guardándose")
	var restored := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ExerciseEntry
	_check(restored != null and restored.color == TINT and restored.emoji == entry.emoji and restored.symbol == entry.symbol, "Ocultar campos en desuso no debe perder los datos de recursos antiguos")
	for property: Dictionary in entry.get_property_list():
		if property.name in ["emoji", "symbol", "color"]:
			_check((property.usage & PROPERTY_USAGE_EDITOR) == 0, "El Inspector no debe ofrecer el campo sin efecto: " + str(property.name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
