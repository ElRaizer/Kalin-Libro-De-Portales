## Flujos de usuario de la revisión visual: ayuda gradual, corrección, pausa,
## cambios de bloque, pestañas y recuperación de capítulos anteriores.
extends SceneTree

var manager: Node
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _scene(key: String) -> void:
	change_scene_to_file(manager.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame

func _escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)
	var book := current_scene.get_node_or_null("LibroHechizos")
	if book and book.motion.closing:
		await book.motion.closed
	await process_frame

func _run() -> void:
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new("user://visual_flow_validation.json")
	manager.scene_states.clear()
	manager.words_learned.clear()
	manager.completed_levels.clear()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	await _scene("world3_level1")
	var level: Node = current_scene
	level._show_help()
	_check(level.guide._hint_target == level.noun_slot and not level.guide.hand.visible, "La primera pista debe mostrar dónde colocar, sin dar la respuesta")
	level._show_help()
	_check(level.guide._hint_target == level.noun_grid, "La segunda pista debe señalar el grupo de opciones")
	level._show_help()
	_check(level.guide.hand.visible, "La tercera pista debe demostrar el gesto")
	(level.noun_buttons["mayak"] as Button).pressed.emit()
	(level.adjective_buttons["mejen"] as Button).pressed.emit()
	level.cast_button.pressed.emit()
	_check(not level._awaiting_continue and level.result_art.word == "mayak" and level.result_art.quality == "mejen", "El error debe mostrar lo creado y dejar corregirlo")
	var wanted: ExerciseEntry = level._current_challenge()
	(level.noun_buttons[wanted.noun] as Button).pressed.emit()
	(level.adjective_buttons[wanted.adjective] as Button).pressed.emit()
	level.cast_button.pressed.emit()
	_check(level._awaiting_continue, "Corregir las dos tarjetas debe permitir continuar")
	_check(level.cast_button.position.is_equal_approx(Vector2(1024, 646)), "La acción principal debe conservar su ubicación")
	_check(level.cast_button.theme != null and level.cast_button.size.y >= 58, "La acción reubicada debe conservar estilo y tamaño")
	# El libro se abre sobre el resultado y vuelve al mismo estado, con el mismo foco.
	level.libro.show_book()
	_check(paused and level.libro.visible, "El libro debe pausar el ejercicio")
	await _escape()
	_check(not paused and not level.libro.visible and level._awaiting_continue, "Esc debe cerrar el libro conservando el resultado")
	await _escape()
	var pause: Node = root.get_node("PauseMenu")
	_check(paused and pause.shade.visible, "Esc debe abrir la pausa")
	var index: int = level.round_index
	await create_timer(0.1).timeout
	_check(level.round_index == index, "La pausa debe conservar la ronda")
	await _escape()
	_check(not paused and not pause.shade.visible, "Esc debe reanudar la misma escena")
	level.cast_button.pressed.emit()
	for round_number: int in range(1, 3):
		wanted = level._current_challenge()
		level._select_noun(wanted.noun)
		level._select_adjective(wanted.adjective)
		level.cast_button.pressed.emit()
		level.cast_button.pressed.emit()
	_check(level.round_index == 3 and level.mission_break.visible, "Tres peticiones deben cerrar un bloque con una escena")
	level.mission_break.continue_button.pressed.emit()
	_check(not level.mission_break.visible and level.round_index == 3, "Seguir un bloque no debe saltarse una petición")
	# Restaurar JSON real conserva también los bloques ya vistos.
	manager.checkpoint(level)
	manager.scene_states.clear()
	manager._load_save()
	await _scene("world3_level1")
	_check(current_scene.round_index == 3 and not current_scene.mission_break.visible, "Continuar no debe repetir una celebración ya vista")
	await _scene("world4_level1")
	level = current_scene
	_check(not level.modifier_grid.visible and not level.modifier_slot.visible, "Agua no debe pedir una decisión de tamaño")
	(level.food_buttons["ja'"] as Button).pressed.emit()
	level.serve_button.pressed.emit()
	_check(level._awaiting_continue, "Agua se sirve directamente")
	level.serve_button.pressed.emit()
	# Elegir una petición con tamaño, independientemente del orden del intento.
	for request_index: int in range(level.challenges.size()):
		if not level.challenges[int(level.round_plan[request_index].challenge)].modifier.is_empty():
			level.round_index = request_index
			level._show_round()
			level.mission_break.hide()
			break
	_check(level.modifier_grid.visible and level.modifier_slot.visible, "Las peticiones con tamaño deben mostrar sus opciones y su espacio")
	_check((level.modifier_buttons[""] as Button).visible, "Sin cualidad debe conservar su lugar para mantener cuatro opciones, sin ser un paso obligatorio")
	for key: String in ["world1_level1", "world1_level2", "world1_level3", "world1_level4"]:
		await _scene(key)
		var board: GridBoard = current_scene.grid_board
		for phase: int in range(3):
			if phase > 0 and current_scene.has_method("_toggle_preview"):
				current_scene.preview_button.pressed.emit()
			for word_index: int in range(board.words.size()):
				var destination: Panel = board.destination_nodes[word_index]
				var style := destination.get_theme_stylebox("panel") as StyleBoxFlat
				var color: Color = board.words[word_index].color if key == "world1_level1" else Color("b99562")
				_check(style.bg_color.is_equal_approx(color.lightened(0.55)), key + " debe usar color de aprendizaje al inicio y casas neutras en recuerdo")
				_check(style.border_color.is_equal_approx(color.darkened(0.15)), key + " debe mantener el borde neutro al consultar pistas")
				var label := destination.get_node("Label") as Label
				var expected_text: String = "?" if key == "world1_level4" and phase == 1 else (board.words[word_index].get_destination_text() if key == "world1_level1" else board.words[word_index].spanish_word)
				_check(label.text == expected_text, key + " debe conservar el funcionamiento de las pistas de destino")
	await _scene("world2_story1")
	level = current_scene
	while level.current_beat().kind != StoryBeat.Kind.EXPLORAR:
		level._next_beat()
	_check(level._waiting_to_continue and level.vignette.visible, "La situación debe animarse sola y dejar continuar al jugador")
	_check(level.vignette.find_children("*", "Button", true, false).is_empty(), "La animación no debe mostrar botones para reproducirla")
	var saved_beat: int = level.beat_index
	await _escape()
	_check(level.beat_index == saved_beat and pause.shade.visible, "Esc no debe saltar capítulos")
	await _escape()
	manager.scene_states.world2_story1 = {"beat": 7, "resolved": false}
	await _scene("world2_story1")
	_check(current_scene.current_beat().target_word == "nojoch", "Un guardado anterior debe recuperar el mismo momento narrativo")
	await _scene("main_menu")
	manager.words_learned = manager.VOCABULARY.duplicate(true)
	var book: Node = current_scene.libro
	book.show_book()
	await book.motion.opened
	(book.category_buttons[4] as Button).pressed.emit()
	while book._turning:
		await process_frame
	_check("ja'" in book._entries and "janal" in book._entries and "Peek'" not in book._entries, "Comida debe encontrar todos los alimentos sin mezclar animales")
	(book.category_buttons[1] as Button).pressed.emit()
	while book._turning:
		await process_frame
	_check("Peek'" in book._entries and "ja'" not in book._entries and book._spread_index == 0, "Cambiar de pestaña debe abrir su primera página")
	book.hide_book()
	await book.motion.closed
	manager.reset_save()
	manager.learn_word("ja'")
	book.show_book()
	_check(book._category == 4 and "ja'" in book._visible_words, "Después de reiniciar, una palabra nueva debe abrir de nuevo su página")
	book.hide_book()
	await book.motion.closed
	if failures.is_empty():
		print("Validación de narrativa y UX visual: OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
