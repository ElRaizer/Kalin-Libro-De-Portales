## Regresiones del testeo exploratorio: ratón, corrección, encargos y repetición.
extends "res://tests/validate_game_expansion.gd"


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_folder = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://festival_feedback.json"))
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	_bridge_rules()
	_local_link()
	await _drag_release()
	_correction_validation()
	await _correction()
	await _continue_click()
	await _mission_cards()
	await _replay_chain()
	await _book_navigation()
	await _depth_and_cues()
	await _bridge_presentation()
	await process_frame
	if failures.is_empty():
		print("OK: correcciones por progreso, foco, encargos, repetición, puentes y orientación.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _bridge_rules() -> void:
	var first: GridWordData = GridWordData.new()
	first.start_cell = Vector2i(0, 2)
	first.destination_cell = Vector2i(4, 2)
	first.maya_word = "Peek'"
	var second: GridWordData = GridWordData.new()
	second.start_cell = Vector2i(2, 0)
	second.destination_cell = Vector2i(2, 4)
	second.maya_word = "Kéej"
	var tile: Texture2D = GradientTexture2D.new()
	_check(
		(
			GridBoardValidator
			. validate(5, 5, tile, null, [], [first, second], [Vector2i(2, 2)])
			. is_empty()
		),
		"El Inspector admite un puente en una celda libre"
	)
	for invalid: Array in [[Vector2i(2, 2), Vector2i(2, 2)], [Vector2i(0, 2)], [Vector2i(5, 5)]]:
		var invalid_cells: Array[Vector2i] = []
		invalid_cells.assign(invalid)
		_check(
			not (
				GridBoardValidator
				. validate(5, 5, tile, null, [], [first, second], invalid_cells)
				. is_empty()
			),
			"El Inspector rechaza puentes repetidos, sobre fichas o fuera del tablero"
		)
	var controller: GridPathController = GridPathController.new()
	controller.configure(5, 5, [first, second], [], [Vector2i(2, 2)])
	controller.start(0)
	controller.extend(Vector2i(1, 2))
	controller.extend(Vector2i(2, 2))
	controller.extend(Vector2i(2, 3))
	_check(controller.paths[0].size() == 2, "No girar ni cambiar de piso en el puente")
	controller.extend(Vector2i(3, 2))
	controller.try_finalize(Vector2i(4, 2))
	controller.start(1)
	controller.extend(Vector2i(2, 1))
	controller.extend(Vector2i(2, 2))
	controller.extend(Vector2i(2, 3))
	controller.try_finalize(Vector2i(2, 4))
	_check(controller.connected.size() == 2, "Los dos pisos admiten caminos independientes")
	controller.clear(0)
	_check(
		(
			controller.grid_state[2][2] == GridPathController.Cell.BRIDGE
			and Vector2i(2, 2) in controller.paths[1]
		),
		"Borrar un piso conserva el otro"
	)
	var orders: Dictionary = {}
	for layout: Dictionary in GridVariantCatalog.DATA.levels["4"].variants:
		orders[str(layout.goals)] = true
		_check(not layout.bridges.is_empty(), "Cada variante del último tablero presenta un puente")
	_check(orders.size() >= 3, "Las casas no conservan un orden fijo por animal")


func _local_link() -> void:
	var word: GridWordData = GridWordData.new()
	word.start_cell = Vector2i.ZERO
	word.destination_cell = Vector2i(4, 4)
	var controller: GridPathController = GridPathController.new()
	controller.configure(5, 5, [word], [Vector2i(1, 0)])
	controller.start(0)
	controller.try_link(Vector2i(1, 1))
	_check(
		controller.paths[0] == [Vector2i(0, 1), Vector2i(1, 1)],
		"El arrastre continúa por dos pasos válidos sin atravesar la roca"
	)
	controller.configure(5, 5, [word], [])
	controller.start(0)
	controller.try_link(Vector2i(1, 1))
	_check(controller.paths[0].is_empty(), "No decidir entre dos caminos equivalentes")
	controller.drawing = false
	controller.try_link(Vector2i(2, 0))
	_check(controller.paths[0].is_empty(), "Soltar el botón termina la tolerancia de trazado")


func _drag_release() -> void:
	var scene: Node = await _scene("world1_level1")
	var board: GridBoard = scene.grid_board
	board._handle_press(board.words[0].start_cell)
	_check(board.drawing, "La ficha inicia el trazado")
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(70, 35)
	root.push_input(release, true)
	await process_frame
	_check(not board.drawing, "Soltar sobre un botón de la GUI termina el arrastre")
	var before: Dictionary = board.get_path_state()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = board.to_global(
		(
			board.cell_to_local_position(board.words[0].start_cell + Vector2i.RIGHT)
			+ Vector2.ONE * board.tile_size * 0.5
		)
	)
	root.push_input(motion, true)
	await process_frame
	_check(board.get_path_state() == before, "Mover el ratón sin pulsar no continúa el camino")


func _correction() -> void:
	var scene: Node = await _scene("world3_level1")
	scene.mission_break.hide()
	var panel: RecallPanel = scene.recall
	panel.configure(["Nombre"], ["Peek'"])
	panel.first.text = "Peck'"
	panel.advance_support()
	await process_frame
	await process_frame
	_check(panel.first.text == "Pe_k'", "El primer error conserva las partes acertadas")
	var correction: SpellingField = panel.first.get_parent().get_node("Correction") as SpellingField
	var input: LineEdit = correction.get_child(2) as LineEdit
	_check(input != null and input.has_focus(), "El hueco obtiene foco sin otro clic")
	input.text = "e"
	input.text_changed.emit("e")
	_check(panel.values()[0] == "Peek'", "La escritura del hueco reconstruye la palabra")
	panel.configure(["Nombre"], ["Peek'"])
	panel.first.text = "Pxxk"
	panel.advance_support()
	correction = panel.first.get_parent().get_node("Correction") as SpellingField
	for child: Node in correction.get_children():
		if child is LineEdit:
			child.text = "e"
			child.text_changed.emit("e")
			break
	panel.advance_support()
	_check(
		panel.mode == RecallPanel.Mode.CLOZE and panel.first.text.begins_with("Pe"),
		"Una corrección válida conserva huecos y añade letras protegidas"
	)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(panel.scaffold_state()))
	var text: String = panel.first.text
	panel.configure(["Nombre"], ["Peek'"], RecallPanel.Mode.CLOZE)
	panel.restore_scaffold(saved)
	panel.first.text = text
	_check(panel.first.text == text, "JSON conserva letras y huecos del intento")
	correction = panel.first.get_parent().get_node("Correction") as SpellingField
	for child: Node in correction.get_children():
		if child is LineEdit:
			child.text = "z"
			child.text_changed.emit("z")
	panel.advance_support()
	_check(
		panel.mode == RecallPanel.Mode.BLOCKS, "Sin nuevas correcciones válidas se pasa a bloques"
	)
	panel.configure(["Nombre"], ["Kéej"])
	panel.first.text = "Kej"
	panel.advance_support()
	await process_frame
	panel.get_node("Margin/Content/Letters/E").pressed.emit()
	_check(
		panel.values()[0] == "Kéej" and root.gui_get_focus_owner() is LineEdit,
		"La tecla de acento inserta y conserva el foco"
	)
	panel.configure(["Nombre"], ["Peek'"])
	panel.first.text = "Peek''"
	panel.advance_support()
	correction = panel.first.get_parent().get_node("Correction") as SpellingField
	for child: Node in correction.get_children():
		if child is Button:
			child.pressed.emit()
			break
	_check(panel.values()[0] == "Peek'", "Una letra sobrante se retira sin perder los aciertos")
	scene = await _scene("world3_level1", PhraseExerciseFixture.recall_state(504))
	scene.mission_break.hide()
	var challenge: ExerciseEntry = scene._current_challenge()
	scene.recall.first.text = challenge.noun.substr(0, 1) + "z" + challenge.noun.substr(2)
	scene.recall.second.text = challenge.adjective
	scene._on_cast_pressed()
	await _capture("correccion_huecos")
	await _compact_capture(scene, "correccion_huecos_compacto")
	# La escena recupera desde disco el modelo de huecos, no sólo su texto agregado.
	var before: Dictionary = scene.recall.scaffold_state()
	scene = await _resume("world3_level1")
	_check(
		scene.recall.scaffold_state().corrections == before.corrections,
		"Reabrir la actividad conserva los aciertos protegidos y los huecos"
	)


func _correction_validation() -> void:
	var model: SpellingCorrection = SpellingCorrection.new()
	model.prepare("Peck'", "Peek'")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(model.snapshot()))
	var restored: SpellingCorrection = SpellingCorrection.new()
	_check(restored.restore(saved, "Peek'"), "La corrección admite un checkpoint JSON válido")
	_check(restored.value() == "Pe_k'", "El checkpoint conserva las posiciones acertadas")
	for wrong: Variant in ["0", -2, 0.5, INF, NAN]:
		var corrupt: Dictionary = saved.duplicate(true)
		corrupt.positions[0] = wrong
		_check(
			not restored.restore(corrupt, "Peek'"), "Rechazar posiciones de corrección inválidas"
		)
	var corrupt: Dictionary = saved.duplicate(true)
	corrupt.letters[0] = "z"
	_check(
		not restored.restore(corrupt, "Peek'"), "Una letra errónea no puede restaurarse protegida"
	)
	_check(restored.value() == "Pe_k'", "Un checkpoint rechazado conserva el modelo anterior")
	model.prepare("Pxxk", "Peek'")
	model.letters[model.positions.find(4)] = "’"
	_check(model.confirm() == 1, "Un apóstrofo tipográfico es una corrección válida en un hueco")
	_check(
		restored.restore(model.snapshot(), "Peek'"),
		"La restauración admite el apóstrofo tipográfico protegido"
	)


func _continue_click() -> void:
	var scene: Node = await _scene("world1_level1")
	scene._dialogue_open = true
	scene._arrival_animating = false
	scene._naming_pending = false
	scene.dialogue.show()
	await process_frame
	await _click_button(scene.continue_button)
	_check(not scene._dialogue_open, "Continuar atiende un clic real dentro del botón")


func _click_button(button: Button) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event, true)
	await process_frame


func _mission_cards() -> void:
	var scene: Node = await _scene(
		"world3_mission1",
		{
			"intro_done": true,
			"layout_seed": 504,
			"mission_met": [0, 1],
			"delivered": [0],
			"active_task": 1
		}
	)
	var spot: ExplorationSpot = scene.get_node("Spots/Recipient0") as ExplorationSpot
	_approach_spot(scene, spot)
	scene.open_spot(spot)
	_close_lines(scene)
	_check(
		scene.active_task == 1 and scene.interaction_prompt(spot) == "Hablar",
		"Saludar a un amigo atendido conserva el encargo pendiente"
	)
	scene._open_workbench()
	scene.recall.first.text = "borrador"
	scene._select_task_card(2)
	_check(not scene.forge_button.visible, "Un encargo desconocido no permite crear")
	scene._select_task_card(1)
	_check(
		scene.recall.first.text == "borrador", "Las tarjetas conservan el borrador de cada encargo"
	)
	await _capture("mesa_tarjetas")
	await _compact_capture(scene, "mesa_tarjetas_compacto")
	var task: VillageTask = scene.tasks[scene.task_indices[1]]
	scene.recall.first.text = "zzzzzzzz"
	scene.recall.second.text = task.quality
	scene._forge()
	_check(
		scene._workbench_attempt.word_evidence[task.item].support_level == 1,
		"Los huecos registran su apoyo en el intento activo del encargo"
	)
	var scaffold: Dictionary = scene.recall.scaffold_state()
	scene.met.append(2)
	scene._select_task_card(2)
	scene._select_task_card(1)
	_check(
		scene.recall.scaffold_state().corrections == scaffold.corrections,
		"Cambiar de encargo conserva sus huecos y partes protegidas"
	)
	scene.recall.first.text = "zzzzzzzz"
	scene._forge()
	_check(
		scene._workbench_attempt.word_evidence[task.item].support_level == 2,
		"Los bloques registran su apoyo tras regresar al encargo"
	)
	scene.carried = {"item": task.item, "quality": task.quality}
	scene._open_workbench()
	_check(scene.forge_button.disabled, "Un objeto transportado no se sustituye al crear otro")
	scene.debug_answer()
	_check(not scene.carried.is_empty(), "La creación bloqueada conserva el objeto transportado")
	scene._close_workbench()


func _replay_chain() -> void:
	manager.session.scene_states.world1_story3 = {"beat": 4}
	manager.session.scene_states.world1_level3 = {"complete": true}
	manager.session.learn_word("Peek'")
	manager.replay_scene("world1_level2")
	await scene_changed
	await process_frame
	var run: String = manager.session.scene_states.world1_level2.replay_run
	manager.go_to_scene("world1_story3")
	await scene_changed
	await process_frame
	_check(
		current_scene.beat_index == 0, "Repetir también vuelve a presentar la historia intermedia"
	)
	manager.go_to_scene("world1_level3")
	await scene_changed
	await process_frame
	_check(
		not current_scene._completing and current_scene.grid_board.connected.is_empty(),
		"El siguiente nivel empieza un intento nuevo"
	)
	_check(
		(
			manager.session.scene_states.world1_level3.replay_run == run
			and "Peek'" in manager.learned_words()
		),
		"La repetición conserva sus decisiones y el aprendizaje general"
	)


func _book_navigation() -> void:
	for word: String in VocabularyCatalog.learnable_keys():
		manager.session.learn_word(word)
	var scene: Node = await _scene("world3_level1")
	scene.libro.show_book(scene.get_node("UI/TopBar/Bar/BookButton"))
	await scene.libro.motion.opened
	var book: CanvasLayer = scene.libro
	_check(
		book.next_button.icon != null and book.next_button.text.is_empty(),
		"La navegación del libro usa sellos ilustrados"
	)
	_check(
		not book.left_page.has_node("Content/PracticeButton"),
		"El detalle educativo permanece fuera de la página infantil"
	)
	_check(
		book.left_page.get_node("Content/AudioButton").text.is_empty(),
		"La pronunciación usa una acción circular sin texto"
	)
	await _capture("libro_sellos")
	await _compact_capture(scene, "libro_sellos_compacto")
	book.hide_book()
	await book.motion.closed


func _depth_and_cues() -> void:
	var scene: Node = await _scene("village_home")
	var walker: KalinWalker = scene.walker
	walker.position.y = 380
	scene._process(0.0)
	var rear: float = walker.scale.y
	walker.position.y = 580
	scene._process(0.0)
	_check(walker.scale.y > rear, "Kalin aumenta suavemente hacia el primer plano")
	var cue: KeyboardCue = scene._keyboard_cue
	scene.set_process(false)
	for vertical: bool in [false, true]:
		cue.update_cue(Vector2(500, 400), true, false, false, vertical, 3.2)
		await process_frame
		await process_frame
		_check(cue.visible, "La inmovilidad presenta y dibuja las teclas de movimiento")
	await _capture("orientacion_teclado")
	cue.update_cue(Vector2(500, 400), true, false, true, true, 3.2)
	await process_frame
	await process_frame
	_check(cue.visible, "La orientación de interacción dibuja la tecla E")
	await _capture("interaccion_tecla_e")
	cue.update_cue(Vector2(500, 400), true, true, false, true, 1.0)
	_check(not cue.visible, "Moverse retira la orientación")
	scene.set_process(true)
	_check(
		walker.head_position().y < walker.global_position.y, "La orientación sigue la cabeza real"
	)


func _bridge_presentation() -> void:
	var scene: Node = await _scene("world1_level4", {"layout_seed": 5401})
	scene._toggle_preview()
	var board: GridBoard = scene.grid_board
	var chosen: Dictionary = {}
	for layout: Dictionary in GridVariantCatalog.DATA.levels["4"].variants:
		if layout.id == scene._board_variant:
			chosen = layout
	for index: int in range(3):
		var route: Array[Vector2i] = GridReplayLayouts.cells(chosen.solution[index])
		board._handle_press(route[0])
		for offset: int in range(1, route.size() - 1):
			board._extend_path(route[offset])
		board.cancel_drawing()
	await _capture("puente_dos_pisos")
	await _compact_capture(scene, "puente_dos_pisos_compacto")
	scene = await _resume("world1_level4")
	board = scene.grid_board
	for index: int in range(3):
		_check(
			board.paths[index].size() == chosen.solution[index].size() - 2,
			"Reanudar conserva ambos pisos y todos los caminos parciales"
		)


func _compact_capture(scene: Node, title: String) -> void:
	var layout: ScreenLayout = scene.get_node("ScreenLayout") as ScreenLayout
	root.size = Vector2i(640, 360)
	layout.preview_compact = true
	layout.refresh()
	await process_frame
	for control: Node in scene.find_children("*", "Control", true, false):
		if control is SpellingField and control.is_visible_in_tree():
			for field: Control in control.get_children():
				_check(
					Rect2(0, 0, 1280, 720).encloses(field.get_global_rect()),
					"Los huecos caben en el perfil compacto"
				)
	await _capture(title)
	root.size = Vector2i(1280, 720)
	layout.preview_compact = false
	layout.refresh()
	await process_frame
