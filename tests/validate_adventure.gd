## Completa las ocho escenas jugables y comprueba sus salidas narrativas.
extends SceneTree

var manager: Node
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		"user://adventure_validation.json"
	)
	manager.session.scene_states.clear()
	manager.session.completed_levels.clear()
	manager.session.words_learned.clear()
	manager.session.tutorials_seen.clear()
	manager.session.resume_scene_key = ""
	for info: Dictionary in GameContent.LEVEL_ORDER:
		change_scene_to_file(GameContent.SCENE_PATHS[info.scene_key])
		await scene_changed
		await process_frame
		if int(info.world) == 1:
			await _complete_paths()
		elif int(info.world) == 2:
			for attempt: int in range(current_scene.total_rounds):
				current_scene._on_choice_pressed(current_scene._current_object().maya)
				current_scene._advance_round()
		elif int(info.world) == 3:
			for attempt: int in range(current_scene.round_plan.size()):
				var challenge: ExerciseEntry = current_scene._current_challenge()
				current_scene._select_noun(challenge.noun)
				current_scene._select_adjective(challenge.adjective)
				current_scene._on_cast_pressed()
				current_scene._on_cast_pressed()
		elif int(info.world) == 4:
			for attempt: int in range(current_scene.round_plan.size()):
				var challenge: ExerciseEntry = current_scene._current_challenge()
				current_scene._select_food(challenge.food)
				current_scene._select_modifier(challenge.modifier)
				current_scene._on_serve_pressed()
				current_scene._on_serve_pressed()
		else:
			for attempt: int in range(current_scene.challenges.size()):
				current_scene._on_option_pressed(
					current_scene.challenges[current_scene.challenge_index].correct
				)
				current_scene._advance_challenge()
		if not manager.is_level_completed(info.world, info.level):
			failures.append("No se completó " + info.scene_key)
			break
		var completion: CompletionOverlay = (
			current_scene.completion_overlay if int(info.world) == 1 else current_scene.completion
		)
		if not completion.visible:
			failures.append("No se mostró la celebración de " + info.scene_key)
		completion.next_pressed.emit()
		await scene_changed
		await process_frame
		var expected: String = "world%d_story1" % int(info.world)
		if int(info.world) == 1:
			expected = "world1_story%d" % (int(info.level) + 1)
		elif int(info.world) in [2, 3]:
			expected = "world%d_mission1" % int(info.world)
		elif int(info.world) == 5:
			expected = "world5_farewell"
		if current_scene.scene_file_path != GameContent.SCENE_PATHS[expected]:
			failures.append("La salida de %s no abrió %s" % [info.scene_key, expected])
		if int(info.world) in [2, 3]:
			await _complete_delivery()
			current_scene._go_to_next_scene()
			await scene_changed
			await process_frame
			if (
				current_scene.scene_file_path
				!= GameContent.SCENE_PATHS["world%d_story1" % int(info.world)]
			):
				failures.append("Los encargos no volvieron a la historia correspondiente")
		if int(info.world) == 5:
			await _complete_farewell()
			current_scene._go_to_next_scene()
			await scene_changed
			await process_frame
			current_scene._finish_story()
			await scene_changed
			await process_frame
			if current_scene.scene_file_path != GameContent.SCENE_PATHS.world5_cine1:
				failures.append("El epílogo no abrió el regreso a casa")
			current_scene._finish_story()
			await scene_changed
			await process_frame
			if (
				current_scene.scene_file_path != GameContent.SCENE_PATHS.main_menu
				or manager.session.resume_scene_key != ""
			):
				failures.append("El final no cerró la aventura correctamente en el menú")
	if not manager.all_levels_completed():
		failures.append("El recorrido no registró los ocho niveles")
	await process_frame
	if failures.is_empty():
		print("Validación de aventura completa: OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _complete_paths() -> void:
	var level: Node = current_scene
	var board: GridBoard = level.grid_board
	if int(level.level_number) in [3, 4]:
		level._toggle_preview()
	var routes: Dictionary = _find_routes(board)
	if routes.is_empty():
		failures.append("El tablero no tiene tres rutas sin cruces: " + level.scene_file_path)
		return
	for index: int in range(board.words.size()):
		board._handle_press(board.words[index].start_cell)
		for cell: Vector2i in routes[index]:
			board._try_cell(cell)
		var arrival_deadline: int = Time.get_ticks_msec() + 30000
		while level._arrival_animating and Time.get_ticks_msec() < arrival_deadline:
			await process_frame
		if level._arrival_animating:
			failures.append("La llegada del animal no terminó")
			return
		if level._naming_pending:
			level.recall.first.text = board.words[index].maya_word
			level._submit_name()
		level._close_dialogue()
	if not level.completion_overlay.visible:
		failures.append("Los caminos y la recuperación de nombres deben completar el nivel")
	var key: String = manager.scene_key_for(level)
	manager.session.scene_states[key] = level.get_checkpoint_state()
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame
	if not current_scene.completion_overlay.visible:
		failures.append("El tablero completado conserva su estado al reabrirlo")


func _find_routes(board: GridBoard) -> Dictionary:
	var orders: Array = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]
	for bias: int in range(4):
		for order: Array in orders:
			var blocked: Dictionary = {}
			for cell: Vector2i in board.obstacles:
				blocked[cell] = true
			var routes: Dictionary = {}
			for index: int in order:
				var occupied: Dictionary = blocked.duplicate()
				for other: int in range(board.words.size()):
					if other != index:
						occupied[board.words[other].start_cell] = true
						occupied[board.words[other].destination_cell] = true
				var route: Array[Vector2i] = _bfs(
					board,
					board.words[index].start_cell,
					board.words[index].destination_cell,
					occupied,
					directions
				)
				if route.is_empty():
					break
				routes[index] = route
				for cell: Vector2i in route:
					blocked[cell] = true
			if routes.size() == board.words.size():
				return routes
		directions.append(directions.pop_front())
	return {}


func _bfs(
	board: GridBoard,
	start: Vector2i,
	target: Vector2i,
	blocked: Dictionary,
	directions: Array[Vector2i]
) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var parents: Dictionary = {start: start}
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell == target:
			var route: Array[Vector2i] = []
			while cell != start:
				route.push_front(cell)
				cell = parents[cell]
			return route
		for direction: Vector2i in directions:
			var next: Vector2i = cell + direction
			if board.is_valid_cell(next) and next not in blocked and next not in parents:
				parents[next] = cell
				queue.append(next)
	return []


func _close_lines(scene: Node) -> void:
	for index: int in range(10):
		if not scene.is_dialogue_open():
			break
		scene.advance_dialogue()


func _complete_delivery() -> void:
	var mission: Node = current_scene
	_close_lines(mission)
	for index: int in range(3):
		var friend: ExplorationSpot = mission.get_node("Spots/Recipient%d" % index)
		mission._place_kalin(friend.position.x)
		mission.open_spot(friend)
		_close_lines(mission)
		var bench: ExplorationSpot = mission.get_node("Spots/Workbench")
		mission._place_kalin(bench.position.x)
		mission.open_spot(bench)
		var task: VillageTask = mission.tasks[mission.task_indices[index]]
		mission.recall.first.text = task.item
		mission.recall.second.text = task.quality
		mission._forge()
		mission._place_kalin(friend.position.x)
		mission.open_spot(friend)
		_close_lines(mission)
	if mission.delivered.size() != 3:
		failures.append("Los tres encargos deben poder crearse y entregarse")


func _complete_farewell() -> void:
	var farewell: Node = current_scene
	_close_lines(farewell)
	for index: int in range(3):
		var friend: ExplorationSpot = farewell.get_node("Spots/Friend%d" % index)
		farewell._place_kalin(friend.position.x)
		farewell.open_spot(friend)
		_close_lines(farewell)
		farewell._choose(farewell._choices.find(farewell.gifts[index].correct))
		_close_lines(farewell)
	var portal: ExplorationSpot = farewell.get_node("Spots/Salida")
	farewell._place_kalin(portal.position.x)
	farewell.open_spot(portal)
	farewell.memory_choice.choose(0)
	if farewell.memory.is_empty():
		failures.append("El cierre permite elegir un recuerdo personal tras la despedida")
