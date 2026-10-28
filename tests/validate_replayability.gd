## Variaciones reproducibles, restauración y resolución real de los 48 tableros.
extends SceneTree

var manager: Node
var failures: Array[String] = []
var capture_folder: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _scene(key: String, state: Dictionary = {}) -> Node:
	manager.session.scene_states[key] = state.duplicate(true)
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame
	return current_scene


func _resume(key: String) -> Node:
	manager.checkpoint(current_scene)
	manager.session.scene_states.clear()
	manager._load_save()
	return await _scene(key, manager.session.scene_states[key])


func _capture(name: String) -> void:
	if capture_folder.is_empty():
		return
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_folder.path_join(name + ".png"))


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://replayability_validation.json")
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	_plans()
	await _boards()
	await _questions()
	await _exercises()
	await _walks()
	await _portal()
	await _replay_action()
	if failures.is_empty():
		print(
			"OK: 48 tableros resueltos, dificultad acotada, preguntas variables, planes, alternativas, guardado y repetición."
		)
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _plans() -> void:
	var seen: Dictionary = {}
	for seed_value: int in range(1, 65):
		var plan: Array[Dictionary] = ReplayVariation.two_phase(6, seed_value, true)
		_check(plan[0].challenge == 0 and plan[0].guided, "El primer ejemplo conserva su sencillez")
		_check(
			ExerciseProgress.restore_plan(plan, 6, []).size() == 12,
			"Cada fase cubre todas las preguntas exactamente una vez"
		)
		_check(
			plan[5].challenge != plan[6].challenge,
			"El recuerdo no repite inmediatamente el último ejemplo"
		)
		var next: Array[Dictionary] = ReplayVariation.two_phase(6, seed_value, true, plan)
		_check(next.slice(0, 6) != plan.slice(0, 6), "Repetir cambia el orden posterior al ejemplo")
		seen[str(plan)] = true
	_check(seen.size() > 20, "Desde la primera partida hay órdenes diferentes")


func _boards() -> void:
	for level: int in range(1, 5):
		var source: Dictionary = GridVariantCatalog.DATA.levels[str(level)]
		var key: String = "world1_level%d" % level
		var fingerprints: Dictionary = {}
		for layout: Dictionary in source.variants:
			_check(
				GridReplayLayouts.has_solution(layout, 12, 7),
				"El testigo une las tres parejas sin cruzarlas: " + str(layout.id)
			)
			var scene: Node = await _scene(key, {"layout_seed": 541, "board_variant": layout.id})
			var board: GridBoard = scene.grid_board
			_check(scene._board_variant == layout.id, "La escena aplica la variante elegida")
			var geometry: Array = [board.obstacles]
			for word: GridWordData in board.words:
				geometry.append([word.start_cell, word.destination_cell])
			fingerprints[str(geometry)] = true
			if level > 2:
				scene._toggle_preview()
			if str(layout.id).ends_with("01") or str(layout.id).ends_with("02"):
				await _capture("tablero_" + str(layout.id))
			var total_steps: int = 0
			var total_turns: int = 0
			for index: int in range(3):
				var route: Array[Vector2i] = GridReplayLayouts.cells(layout.solution[index])
				var steps: int = route.size() - 1
				var turns: int = 0
				for cursor: int in range(2, route.size()):
					if route[cursor] - route[cursor - 1] != route[cursor - 1] - route[cursor - 2]:
						turns += 1
				total_steps += steps
				total_turns += turns
				_check(
					(
						steps == int(layout.metrics.lengths[index])
						and turns == int(layout.metrics.turns[index])
					),
					"Los indicadores describen la ruta real"
				)
				if level > 1:
					_check(
						(
							steps <= int(source.baseline_metrics.lengths.max()) + 2
							and turns <= int(source.baseline_metrics.turns.max()) + 2
						),
						"Ninguna ruta excede el máximo original en más de dos pasos o giros"
					)
				_check(
					(board.word_nodes[index] as Control).position.is_equal_approx(
						board.cell_to_local_position(route[0]) + Vector2(2, 2)
					),
					"La ficha visible coincide con su celda jugable"
				)
				_check(
					(board.destination_nodes[index] as Control).position.is_equal_approx(
						board.cell_to_local_position(route.back()) + Vector2(2, 2)
					),
					"La casa visible coincide con su destino"
				)
				# Recorrer el controlador real: valida que las rutas sirvan en el juego.
				board._handle_press(route[0])
				for cell: Vector2i in route.slice(1):
					board._try_cell(cell)
				_check(
					index in board.connected,
					"La ruta del catálogo se puede completar: " + str(layout.id)
				)
				if scene.arrival_tween and scene.arrival_tween.is_valid():
					scene.arrival_tween.custom_step(1000.0)
				if scene._naming_pending:
					scene.recall.first.text = board.words[index].maya_word
					scene._submit_name()
				scene._close_dialogue()
				await process_frame
			_check(
				board.is_completed() and scene.completion_overlay.visible,
				"Las tres rutas completan el nivel: " + str(layout.id)
			)
			if level == 1:
				_check(
					(
						int(layout.metrics.lengths[0]) == 4
						and int(layout.metrics.turns[0]) == 0
						and total_steps <= 29
					),
					"La primera demostración sigue siendo corta y recta"
				)
			else:
				var baseline_steps: int = 0
				var baseline_turns: int = 0
				for number: int in source.baseline_metrics.lengths:
					baseline_steps += number
				for number: int in source.baseline_metrics.turns:
					baseline_turns += number
				_check(
					(
						board.obstacles.size() == source.base.obstacles.size()
						and absi(total_steps - baseline_steps) <= 4
						and absi(total_turns - baseline_turns) <= 4
					),
					"Se conserva densidad y una dificultad de recorrido comparable"
				)
		_check(fingerprints.size() == 12, "Los doce tableros son distintos en el nivel %d" % level)
		# Guardar y reabrir un trazo parcial conserva la geometría y sus casillas.
		var scene: Node = await _scene(key, {"layout_seed": 1234})
		if level > 2:
			scene._toggle_preview()
		var board: GridBoard = scene.grid_board
		var route: Array[Vector2i] = board.get_hint_path(0)
		board._handle_press(route[0])
		board._try_cell(route[1])
		board.cancel_drawing()
		var before: Dictionary = scene.get_checkpoint_state()
		scene = await _resume(key)
		_check(
			(
				scene._board_variant == before.board_variant
				and scene.grid_board.get_path_state() == before.board
			),
			"JSON conserva variante y camino parcial"
		)
		var next_state: Dictionary = ReplayVariation.replay_state(before)
		next_state.layout_seed = 1234
		scene = await _scene(key, next_state)
		_check(
			scene._board_variant != before.board_variant and scene.grid_board.connected.is_empty(),
			"Repetir el tablero elige otro y empieza sin trazos"
		)
		var damaged: Dictionary = before.duplicate(true)
		damaged.board_variant = "invalid_variant"
		damaged.board = {}
		scene = await _scene(key, damaged)
		_check(
			not scene._board_variant.is_empty(),
			"Una variante dañada se reemplaza por geometría válida"
		)


func _questions() -> void:
	for chapter: int in range(1, 6):
		var key: String = "world1_story%d" % chapter
		var targets: Dictionary = {}
		for seed_value: int in range(1, 9):
			var scene: Node = await _scene(key, {"layout_seed": seed_value})
			for index: int in range(scene.beats.size()):
				var beat: StoryBeat = scene.beats[index]
				if beat.kind != StoryBeat.Kind.ADIVINAR:
					continue
				targets[beat.target_word] = true
				_check(
					(
						beat.target_word in beat.actors
						and (
							beat.text
							== beat.question_template.replace("{animal}", beat.target_word)
						)
					),
					"La pregunta nombra exactamente la respuesta disponible"
				)
			var state: Dictionary = scene.get_checkpoint_state()
			scene = await _resume(key)
			_check(
				scene._guess_targets == state.guess_targets,
				"Continuar conserva las preguntas del capítulo"
			)
			var repeat_state: Dictionary = ReplayVariation.replay_state(state)
			repeat_state.layout_seed = seed_value
			scene = await _scene(key, repeat_state)
			for index: String in state.guess_targets:
				_check(
					scene._guess_targets[index] != state.guess_targets[index],
					"Repetir no pregunta de nuevo por el mismo animal"
				)
		_check(targets.size() >= 2, "El capítulo puede preguntar por distintos animales")
	var story: Node = await _scene("world1_story2", {"layout_seed": 114})
	while story.current_beat().kind != StoryBeat.Kind.ADIVINAR:
		story._next_beat()
	story._complete_text()
	for tween: Tween in story._actor_tweens.values().duplicate():
		if tween.is_valid():
			tween.custom_step(2.0)
	await process_frame
	story._on_actor_pressed(story.current_beat().target_word)
	_check(story._waiting_to_continue, "La respuesta variable resuelve la interacción real")
	await _capture("animal_variable")


func _exercises() -> void:
	for world: int in [2, 3, 4]:
		var key: String = "world%d_level1" % world
		var scene: Node = await _scene(key, {"layout_seed": 948})
		var state: Dictionary = scene.get_checkpoint_state()
		if world == 2:
			_check(
				scene.round_order != scene.recall_order,
				"Los muebles no se repasan en el orden de presentación"
			)
		scene = await _resume(key)
		_check(
			(
				scene.get_checkpoint_state().get("plan", scene.get_checkpoint_state().get("order"))
				== state.get("plan", state.get("order"))
			),
			"Continuar conserva el plan del ejercicio"
		)
		var repeated: Dictionary = ReplayVariation.replay_state(state)
		repeated.layout_seed = 948
		scene = await _scene(key, repeated)
		_check(
			(
				scene.get_checkpoint_state().get("plan", scene.get_checkpoint_state().get("order"))
				!= state.get("plan", state.get("order"))
			),
			"Repetir cambia el orden de las rondas"
		)


func _walks() -> void:
	for world: int in [2, 3]:
		var key: String = "world%d_explore1" % world
		var plans: Dictionary = {}
		for seed_value: int in range(1, 9):
			var walk: Node = await _scene(key, {"layout_seed": seed_value})
			plans[str(walk._encounter_plan)] = true
			var items: Array[String] = []
			for encounter: VillageEncounter in walk.encounters:
				_check(
					encounter.get_configuration_issues().is_empty(),
					"Cada necesidad y alternativa tiene una solución ofrecida"
				)
				_check(
					encounter.task.item not in items,
					"Los tres amigos no repiten el mismo objeto en un paseo"
				)
				items.append(encounter.task.item)
			var state: Dictionary = walk.get_checkpoint_state()
			walk = await _resume(key)
			_check(
				walk._encounter_plan == state.encounter_plan,
				"El paseo conserva personajes, necesidades y orden al continuar"
			)
		_check(
			plans.size() >= 4, "Los paseos ofrecen situaciones distintas desde la primera visita"
		)
		var previous_plan: Array = current_scene._encounter_plan.duplicate()
		for seed_value: int in range(1, 33):
			var probe: Node = load(GameContent.SCENE_PATHS[key]).instantiate()
			probe._layout_seed = seed_value
			probe._prepare_encounters({"previous_variation": {"encounter_plan": previous_plan}})
			_check(
				probe._encounter_plan != previous_plan,
				"La reparación de objetos distintos también evita repetir el plan anterior"
			)
			probe.free()
		current_scene.solved.assign([0, 1, 2])
		manager.start_walk(key, "world%d_story1" % world)
		await scene_changed
		await process_frame
		_check(
			current_scene.solved.is_empty() and current_scene._encounter_plan != previous_plan,
			"Volver a un paseo completado ofrece nuevas necesidades"
		)
		# Un checkpoint dañado puede repetir un objeto. Sólo cambia peticiones
		# que todavía no se han escuchado; la primera conserva su resultado.
		var repeated_plan: Array[int] = []
		repeated_plan.assign([0, 3, 4] if world == 2 else [1, 3, 4])
		var resumed: Node = await _scene(
			key,
			{
				"encounter_plan": repeated_plan,
				"solved": [1],
				"choosing": 0,
				"intro_done": true,
				"layout_seed": 9
			}
		)
		_check(
			(
				resumed._encounter_plan[0] == repeated_plan[0]
				and resumed._encounter_plan[1] == repeated_plan[1]
			),
			"Reparar duplicados conserva una petición abierta y otra resuelta"
		)
		var repaired: Array[String] = []
		for encounter: VillageEncounter in resumed.encounters:
			_check(
				encounter.task.item not in repaired,
				"La reparación elimina duplicados entre peticiones nuevas"
			)
			repaired.append(encounter.task.item)
	for world: int in [2, 3, 4]:
		for seed_value: int in range(1, 9):
			var mission: Node = await _scene(
				"world%d_mission1" % world, {"layout_seed": seed_value}
			)
			var items: Array[String] = []
			for index: int in mission.task_indices:
				_check(
					mission.tasks[index].item not in items,
					"Los encargos también evitan repetir objetos"
				)
				items.append(mission.tasks[index].item)


func _portal() -> void:
	var base: ExerciseSet = load("res://data/exercises/world5.tres")
	for category: int in range(4):
		for task: ExerciseEntry in PortalReplay.pool(category, base.challenges[category]):
			_check(
				task.options.size() == 4 and task.correct in task.options and task.clue != "",
				"Cada variante del portal tiene pista y cuatro opciones válidas"
			)
	var scene: Node = await _scene("world5_level1", {"layout_seed": 42})
	var state: Dictionary = scene.get_checkpoint_state()
	var answers: Array[String] = []
	for index: int in range(scene.challenges.size()):
		scene.challenge_index = index
		scene._show_challenge()
		var task: ExerciseEntry = scene.challenges[index]
		answers.append(task.correct)
		if index < 4:
			_check(
				scene.recall.visible and scene.challenge_art.word == task.noun,
				"El portal mantiene el recuerdo sin pistas y la ilustración correspondiente"
			)
			if not capture_folder.is_empty():
				scene._practice_with_cards()
				await _capture("portal_" + task.section.to_lower())
		scene._on_option_pressed(task.correct)
		_check(scene._awaiting_continue, "La respuesta generada resuelve su página del portal")
	await _capture("portal_variable")
	# Una página pendiente se restaura desde el archivo, incluidas sus opciones.
	scene = await _scene("world5_level1", state)
	scene = await _resume("world5_level1")
	_check(
		(
			scene.challenges[0].correct == answers[0]
			and scene._portal_variants == state.portal_variants
		),
		"JSON conserva las variantes del portal"
	)
	var repeated: Dictionary = ReplayVariation.replay_state(state)
	repeated.layout_seed = 42
	scene = await _scene("world5_level1", repeated)
	_check(
		scene._challenge_order != state.order,
		"El portal cambia el orden de sus primeras cuatro páginas"
	)
	for key: String in state.portal_variants:
		_check(
			scene._portal_variants[key] != state.portal_variants[key],
			"El portal elige otra pregunta de cada categoría al repetir"
		)


func _replay_action() -> void:
	var scene: Node = await _scene("world1_level2", {"layout_seed": 99})
	var previous: String = scene._board_variant
	manager.replay_scene("world1_level2")
	await scene_changed
	await process_frame
	_check(
		current_scene._board_variant != previous,
		"El botón Repetir conserva la referencia anterior y cambia de tablero"
	)
