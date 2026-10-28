## Las demostraciones representan entradas válidas, sin resolver la actividad.
## Capturas opcionales con renderer real: -- --capture=<carpeta absoluta>
extends SceneTree

var manager: Node
var failures: Array[String] = []
var capture_folder: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _scene(key: String) -> Node:
	manager.session.scene_states.clear()
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame
	return current_scene


func _capture(name: String) -> void:
	if capture_folder.is_empty():
		return
	# Dejar terminar la entrada de escena antes de inspeccionar sus colores.
	await create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_folder.path_join(name + ".png"))


func _click_hint(guide: LearningGuide, point: Vector2, context: String) -> void:
	guide.set_process(false)
	_check(
		guide.gesture_mode == LearningGuide.Gesture.CLICK and guide.hand.visible,
		context + ": muestra un clic"
	)
	for delta: float in [0.0, 0.15, 0.25, 0.7, 0.55]:
		guide._process(delta)
		var fingertip: Vector2 = guide.hand.get_transform() * LearningGuide.FINGER_TIP
		_check(fingertip.distance_to(point) < 1.0, context + ": el dedo pulsa sin desplazarse")
		_check(not guide._gesture_line.visible, context + ": no hay trayectoria de arrastre")


func _control_click(guide: LearningGuide, button: Control, context: String) -> void:
	_click_hint(guide, LearningGuide.screen_center(button), context)


func _drag_hint(guide: LearningGuide, points: Array[Vector2], context: String) -> void:
	guide.set_process(false)
	_check(
		guide.gesture_mode == LearningGuide.Gesture.DRAG and guide.hand.visible,
		context + ": muestra un arrastre"
	)
	guide._time = 0.0
	guide._process(0.0)
	_check(
		(guide.hand.position + LearningGuide.FINGER_TIP).distance_to(points[0]) < 1.0,
		context + ": empieza en el origen"
	)
	_check(
		guide._gesture_line.visible and not guide._click_pulse.visible,
		context + ": diferencia arrastrar de pulsar"
	)
	var length: float = 0.0
	for index: int in range(1, points.size()):
		length += points[index - 1].distance_to(points[index])
	var seconds: float = clampf(length / 360.0, 0.65, 2.5)
	# Muestrear toda la animación: cada posición permanece sobre un tramo válido.
	for sample: int in range(21):
		guide._time = 0.0
		guide._process(LearningGuide.DRAG_PRESS + seconds * sample / 20.0)
		var fingertip: Vector2 = guide.hand.position + LearningGuide.FINGER_TIP
		var on_segment: bool = false
		for index: int in range(1, points.size()):
			if (
				(
					Geometry2D
					. get_closest_point_to_segment(fingertip, points[index - 1], points[index])
					. distance_to(fingertip)
				)
				< 1.0
			):
				on_segment = true
		_check(on_segment, context + ": sigue la trayectoria sin cortar esquinas")
	_check(
		(guide.hand.position + LearningGuide.FINGER_TIP).distance_to(points.back()) < 1.0,
		context + ": termina en el destino"
	)
	guide._time = 0.0
	guide._process(0.0)


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://tutorial_gestures_validation.json")
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	await _exploration()
	await _boards()
	await _cards_and_buttons()
	await _story()
	if failures.is_empty():
		print("OK: clics quietos, cámara, arrastres válidos, tarjetas, botones y personajes.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _exploration() -> void:
	var scene: Node = await _scene("world1_explore1")
	for index: int in range(4):
		if scene.is_dialogue_open():
			scene.advance_dialogue()
	var conch: ExplorationSpot = scene.get_node("Spots/Concha")
	scene._show_help()
	_check(
		scene.guide._world_target == conch.sprite,
		"La exploración inicial invita a pulsar la concha"
	)
	_click_hint(
		scene.guide,
		conch.sprite.get_global_transform_with_canvas() * conch.sprite.get_rect().get_center(),
		"Concha"
	)
	await _capture("01_clic_concha")
	# La cámara cambia, el objetivo sigue siendo la concha y su dedo la acompaña.
	scene._place_kalin(600)
	scene.camera.reset_smoothing()
	await process_frame
	scene.guide._process(0.0)
	_click_hint(
		scene.guide,
		conch.sprite.get_global_transform_with_canvas() * conch.sprite.get_rect().get_center(),
		"Concha tras mover la cámara"
	)
	for spot: ExplorationSpot in scene.spots:
		spot.examined = true
	scene._show_help()
	_click_hint(
		scene.guide,
		scene.get_global_transform_with_canvas() * scene.guide._world_point,
		"Clic para caminar"
	)
	for world: int in [2, 3]:
		scene = await _scene("world%d_explore1" % world)
		for index: int in range(4):
			if scene.is_dialogue_open():
				scene.advance_dialogue()
		scene._place_kalin(scene._encounter_spot(0).position.x - 100)
		scene._show_choices(0)
		scene.camera.reset_smoothing()
		await process_frame
		scene._show_help()
		var target: Button = scene.guide._point_target as Button
		var target_index: int = target.get_index()
		var spell: ExerciseEntry = scene.encounters[0].choices[scene._choice_order[target_index]]
		_check(
			(
				spell.noun == scene.encounters[0].task.item
				and spell.adjective == scene.encounters[0].task.quality
			),
			"La ayuda del paseo sigue la solución después de barajar"
		)
		_control_click(scene.guide, target, "Hechizo en el paseo %d" % world)
		await _capture("02_clic_paseo%d" % world)
		scene._close_choices()
		_check(not scene.guide.hand.visible, "Salir de las elecciones retira la ayuda")


func _boards() -> void:
	for level: int in range(1, 5):
		var scene: Node = await _scene("world1_level%d" % level)
		if scene.has_method("_toggle_preview"):
			scene._show_help()
			_control_click(scene.guide, scene.preview_button, "Listo en tablero %d" % level)
			scene._toggle_preview()
		var board: GridBoard = scene.grid_board
		var before: Dictionary = board.get_path_state().duplicate(true)
		for index: int in range(board.words.size()):
			var route: Array[Vector2i] = board.get_hint_path(index)
			_check(
				(
					route.size() >= 2
					and route[0] == board.words[index].start_cell
					and route.back() == board.words[index].destination_cell
				),
				"Cada animal tiene una ruta hacia su propia casa"
			)
			for cursor: int in range(1, route.size()):
				var step: Vector2i = route[cursor] - route[cursor - 1]
				_check(
					absi(step.x) + absi(step.y) == 1,
					"La ayuda recorre casillas adyacentes, sin diagonales"
				)
				_check(
					(
						cursor == route.size() - 1
						or (
							board.grid_state[route[cursor].y][route[cursor].x]
							== GridBoard.Cell.EMPTY
						)
					),
					"La ayuda evita rocas, otras fichas y caminos"
				)
			_check(
				board.get_hint_path(index, 2).size() <= 3,
				"Los niveles avanzados sólo demuestran dos pasos"
			)
		scene._show_help()
		var points: Array[Vector2] = scene.guide._gesture_points.duplicate()
		_check(points.size() >= 2, "El tablero presenta un recorrido válido")
		if points.size() >= 2:
			_drag_hint(scene.guide, points, "Tablero %d" % level)
			await _capture("03_arrastre_tablero%d" % level)
		_check(board.get_path_state() == before, "Ver la ayuda no dibuja ni completa caminos")
		# Un trazo parcial se retoma desde su punta, no desde la ficha original.
		var route: Array[Vector2i] = board.get_hint_path(0)
		if route.size() > 2:
			board.active_index = 0
			board._path_controller.extend(route[1])
			var resumed: Array[Vector2i] = board.get_hint_path(0)
			_check(
				not resumed.is_empty() and resumed[0] == route[1],
				"La ayuda retoma el extremo del camino parcial"
			)
			scene._show_help()
			var tip: Vector2 = (
				board.get_global_transform_with_canvas()
				* (board.cell_to_local_position(route[1]) + Vector2.ONE * board.tile_size * 0.5)
			)
			_check(
				(scene.guide.hand.position + LearningGuide.FINGER_TIP).distance_to(tip) < 1.0,
				"El dedo empieza en la punta del trazo parcial"
			)


func _card_drag(
	scene: Node, button: DraggableWordButton, slot: WordDropSlot, context: String
) -> void:
	scene._help_stage = 2
	scene._show_help()
	_check(
		scene.guide._drag_source == button and scene.guide._drag_target == slot,
		context + ": tarjeta y hueco correctos"
	)
	_check(
		slot._can_drop_data(Vector2.ZERO, {"kind": button.word_kind, "value": button.word_value}),
		context + ": el destino acepta el arrastre mostrado"
	)
	_drag_hint(
		scene.guide,
		[LearningGuide.screen_center(button), LearningGuide.screen_center(slot)],
		context
	)


func _cards_and_buttons() -> void:
	var scene: Node = await _scene("world2_level1")
	scene._help_stage = 2
	scene._show_help()
	_control_click(scene.guide, scene.guide._point_target, "Palabra de un mueble")
	(scene.guide._point_target as Button).pressed.emit()
	scene._show_help()
	_control_click(scene.guide, scene.next_button, "Continuar en la casa")
	scene = await _scene("world3_level1")
	var wanted: ExerciseEntry = scene._current_challenge()
	_card_drag(scene, scene.noun_buttons[wanted.noun], scene.noun_slot, "Objeto hacia su hueco")
	await _capture("04_arrastre_objeto")
	scene._select_noun(wanted.noun)
	await create_timer(0.3).timeout
	_card_drag(
		scene,
		scene.adjective_buttons[wanted.adjective],
		scene.adjective_slot,
		"Cualidad hacia su hueco"
	)
	scene._select_adjective(wanted.adjective)
	scene._show_help()
	_control_click(scene.guide, scene.cast_button, "Crear objeto")
	scene = await _scene("world4_level1")
	wanted = scene._current_challenge()
	_card_drag(scene, scene.food_buttons[wanted.food], scene.food_slot, "Alimento hacia su hueco")
	scene._select_food(wanted.food)
	scene._show_help()
	_control_click(scene.guide, scene.serve_button, "Servir agua")
	scene.round_index = 0
	for index: int in range(scene.challenges.size()):
		if scene.challenges[int(scene.round_plan[index].challenge)].modifier != "":
			scene.round_index = index
			break
	scene._show_round()
	scene.mission_break.hide()
	wanted = scene._current_challenge()
	scene._select_food(wanted.food)
	await create_timer(0.3).timeout
	_card_drag(
		scene, scene.modifier_buttons[wanted.modifier], scene.modifier_slot, "Tamaño hacia su hueco"
	)
	await _capture("05_arrastre_tamano")
	scene = await _scene("world5_level1")
	scene._practice_with_cards()
	scene._help_stage = 2
	scene._show_help()
	_control_click(scene.guide, scene.guide._point_target, "Respuesta del portal")
	(scene.guide._point_target as Button).pressed.emit()
	scene._show_help()
	_control_click(scene.guide, scene.next_button, "Continuar en el portal")
	# La ayuda de inactividad también pulsa; se oculta al interactuar.
	scene.guide.watch_continue(scene.next_button, 0.1)
	scene.guide._process(0.2)
	_control_click(scene.guide, scene.next_button, "Continuar tras esperar")
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.relative = Vector2(10, 0)
	scene.guide._input(event)
	_check(
		not scene.guide.hand.visible and not scene.guide._click_pulse.visible,
		"La actividad del jugador retira la pulsación diferida"
	)


func _story() -> void:
	var story: Node = await _scene("world1_story1")
	while story.current_beat().kind != StoryBeat.Kind.CONOCER:
		story._next_beat()
	story._complete_text()
	for tween: Tween in story._actor_tweens.values().duplicate():
		if tween.is_valid():
			tween.custom_step(2.0)
	await process_frame
	story._show_meet_hint()
	var target: Control = story.guide._point_target
	_check(is_instance_valid(target), "Saludar a un personaje ofrece un clic")
	if is_instance_valid(target):
		_control_click(story.guide, target, "Saludar al animal")
		await _capture("06_clic_personaje")
