## El atajo responde por la lógica real sin adelantar rondas ni acreditar recuerdo.
extends "res://tests/validate_game_expansion.gd"

var debug_tool: Node

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://debug_answer_validation.json")
	manager.reset_save()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	debug_tool = root.get_node("DebugAnswer")
	_check(OS.is_debug_build(), "Esta suite necesita el binario de depuración de Godot")
	await _exercises()
	await _names()
	await _missions()
	await _stories()
	await _farewell_answers()
	await _scene("main_menu")
	_check(not debug_tool.can_answer(), "El menú no ofrece respuestas")
	_check(not debug_tool.toolbar.visible, "El botón se oculta fuera de una actividad")
	for word: String in manager.learning_progress:
		var evidence := LearningProgress.sanitize(manager.learning_progress[word])
		_check(evidence.recalls.is_empty() and evidence.writing == 0, "Debug no acredita recuerdo ni escritura independiente: " + word)
	await process_frame
	await process_frame
	if failures.is_empty():
		print("OK: respuestas debug, F4, pausa, modos, nombres, historias, encargos y despedida sin falso recuerdo.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _exercises() -> void:
	for key: String in ["world2_level1", "world3_level1", "world4_level1"]:
		var exercise := await _scene(key)
		var count: int = exercise.objects.size() if key == "world2_level1" else exercise.challenges.size()
		for round_number: int in [0, count, count + 1, count + 3]:
			exercise = await _scene(key, {"round": round_number, "layout_seed": 420})
			exercise.mission_break.hide()
			var mode: int = exercise.recall.mode
			if key == "world3_level1" and round_number == count + 1:
				await _capture("debug_responder_bloques")
			_check(debug_tool.can_answer(), "Debe ofrecer respuesta en " + key)
			# También bloquea la entrada detrás del libro, que posee la pausa.
			var was_supported: bool = exercise._attempt.supported
			paused = true
			debug_tool.answer_current()
			_check(not debug_tool.can_answer() and exercise._attempt.supported == was_supported, "La pausa no permite responder " + key)
			_check(exercise.round_index == round_number, "Pausar conserva la ronda")
			paused = false
			var keypress := InputEventKey.new()
			keypress.keycode = KEY_F4
			keypress.pressed = true
			Input.parse_input_event(keypress)
			await process_frame
			var waiting: bool = exercise._waiting if key == "world2_level1" else exercise._awaiting_continue
			_check(waiting and exercise._attempt.supported, "F4 responde correctamente y marca ayuda en " + key)
			_check(exercise.recall.mode == mode, "Debug conserva la modalidad del ejercicio")
			debug_tool.answer_current()
			_check(exercise.round_index == round_number, "Dos pulsaciones no deben saltar la revisión del resultado")
			_check(not debug_tool.can_answer(), "Debug espera al Continuar normal")
	var portal := await _scene("world5_level1")
	for index: int in [0, 4]:
		portal = await _scene("world5_level1", {"challenge": index, "layout_seed": 420})
		var point: Vector2 = debug_tool.answer_button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		root.push_input(motion, true)
		for down: bool in [true, false]:
			var click := InputEventMouseButton.new()
			click.position = point
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = down
			root.push_input(click, true)
		await process_frame
		_check(portal._awaiting_continue and portal._attempt.supported, "El botón resuelve escritura y tarjetas del portal")

func _names() -> void:
	var level := await _scene("world1_level2")
	_check(not debug_tool.can_answer(), "El atajo no salta el trazado del camino")
	level._show_word_dialogue(level.grid_board.words[0], 0)
	_check(not debug_tool.can_answer(), "El atajo espera la llegada del animal")
	level.arrival_tween.custom_step(60.0)
	await process_frame
	_check(level._naming_pending and debug_tool.can_answer(), "El nombre del animal permite respuesta automática")
	debug_tool.answer_current()
	_check(not level._naming_pending and 0 in level._named_words and level._attempt.supported, "El nombre pasa por su validación y marca ayuda")

func _missions() -> void:
	for key: String in ["world2_mission1", "world3_mission1", "world4_mission1"]:
		var mission := await _scene(key)
		_close_lines(mission)
		_check(not debug_tool.can_answer(), "Caminar por la aldea no ofrece respuesta")
		for index: int in range(2):
			var friend: ExplorationSpot = mission.get_node("Spots/Recipient%d" % index)
			mission._place_kalin(friend.position.x)
			mission.open_spot(friend)
			_close_lines(mission)
			mission._open_workbench()
			if index == 1:
				mission._show_cards()
			debug_tool.answer_current()
			var task: VillageTask = mission.tasks[mission.task_indices[index]]
			_check(not mission.mission_panel.visible and mission.carried.get("item") == task.item and mission.carried.get("quality") == task.quality, "Debug crea el encargo exacto en " + key)
			_check(mission.carried.get("supported", false), "El encargo automático lleva marca de ayuda")
			mission._place_kalin(friend.position.x)
			mission.open_spot(friend)
			_close_lines(mission)
			_check(index in mission.delivered, "El encargo automático puede entregarse normalmente")

func _stories() -> void:
	var checked: Array[int] = []
	for key: String in ["world1_story1", "world1_story2", "world4_story1"]:
		var story := await _scene(key)
		for index: int in range(story.beats.size()):
			story.auto_timer.stop()
			story._complete_text()
			for tween: Tween in story._actor_tweens.values().duplicate():
				if tween.is_valid():
					tween.custom_step(2.0)
			await process_frame
			var kind: int = story.current_beat().kind
			if kind in [StoryBeat.Kind.CONOCER, StoryBeat.Kind.ADIVINAR, StoryBeat.Kind.ELEGIR]:
				for answer: int in range(4):
					if not debug_tool.can_answer():
						break
					debug_tool.answer_current()
				_check(story._waiting_to_continue, "Debug resuelve la interacción narrativa %s:%d" % [key, index])
				if kind not in checked:
					checked.append(kind)
			else:
				_check(not debug_tool.can_answer(), "El atajo no salta las líneas de historia")
			if index + 1 < story.beats.size():
				story._next_beat()
	_check(checked.size() == 3, "La prueba cubre conocer, adivinar y elegir")

func _farewell_answers() -> void:
	var farewell := await _scene("world5_farewell")
	_close_lines(farewell)
	for index: int in range(3):
		farewell._show_choices(index)
		debug_tool.answer_current()
		_check(index in farewell.collected, "Debug encuentra la cortesía correcta aunque se barajen opciones")
		_close_lines(farewell)
	farewell.assembly.show()
	for count: int in range(3):
		debug_tool.answer_current()
		_check(farewell.placed.size() == count + 1, "Cada pulsación coloca un recuerdo en su hueco")
	_check(not debug_tool.can_answer(), "Tras colocar las páginas se espera la despedida normal")
