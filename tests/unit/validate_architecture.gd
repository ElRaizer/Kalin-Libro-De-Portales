extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_save_boundaries()
	_backup_without_primary()
	_reset_edges()
	_progress_rules()
	_long_practice()
	_resource_identity()
	_exercise_session()
	_grid_without_nodes()
	await _checkpoints()
	await _nested_checkpoints()
	finish("Validación de arquitectura y contratos vigentes")


func _save_boundaries() -> void:
	var repository: SaveRepository = repository_for("architecture")
	var invalid: Array = [null, {}, [], "cinco", -1, 1.5, 1e30]
	for value: Variant in invalid:
		write_json(repository.save_path, {"version": value, "magic_points": 10})
		check(
			repository.load_progress().has("_load_error"),
			"Una versión con tipo o rango inválido no se interpreta como partida ausente"
		)
	for value: Variant in [null, {}, [], "diez"]:
		write_json(
			repository.save_path,
			{
				"version": SaveSchema.CURRENT_VERSION,
				"magic_points": value,
				"completed_levels": ["w1_l1"]
			}
		)
		check(
			repository.load_progress().has("_load_error"),
			"Los puntos inválidos se rechazan antes de restaurar niveles"
		)
	var session: GameSession = GameSession.new()
	session.learn_word("Miis")
	var before: Dictionary = session.snapshot()
	check(
		not session.restore({"version": SaveSchema.CURRENT_VERSION, "magic_points": {}}),
		"La restauración rechaza un contenedor inválido"
	)
	check(session.snapshot() == before, "Una restauración fallida no aplica progreso parcial")
	for version: int in range(SaveSchema.CURRENT_VERSION):
		var retired: Dictionary = before.duplicate(true)
		retired.version = version
		check(
			not session.restore(retired) and session.snapshot() == before,
			"Los formatos retirados no se migran ni modifican la sesión"
		)
		check(
			repository.save_progress(retired) == ERR_INVALID_DATA,
			"No se puede escribir un formato retirado como si fuera el vigente"
		)
	check(
		not session.restore({"version": INF}),
		"La validación rechaza números no finitos sin convertirlos"
	)
	check(
		repository.save_progress(before) == OK and repository.save_progress(before) == OK,
		"Se conserva un respaldo válido"
	)
	write_json(repository.save_path, {"version": SaveSchema.CURRENT_VERSION - 1})
	check(
		repository.load_progress().get("_unsupported_version", false),
		"Un formato retirado tampoco se reemplaza silenciosamente por el respaldo"
	)
	write_json(repository.save_path, {"version": SaveSchema.CURRENT_VERSION, "magic_points": {}})
	check(
		repository.load_progress().get("magic_points") == 10,
		"Un error de esquema también recupera el respaldo"
	)
	write_json(repository.save_path, {"version": SaveSchema.CURRENT_VERSION + 1})
	check(
		repository.load_progress().get("_unsupported_version", false),
		"Una partida futura no se sustituye por un respaldo antiguo"
	)
	var manager: Node = load("res://scripts/autoloads/game_manager.gd").new()
	manager.use_save_repository(repository)
	check(
		manager.load_failed and not manager.save_status_message.is_empty(),
		"La fachada informa el fallo sin borrar el archivo"
	)
	var protected_text: String = FileAccess.get_file_as_string(repository.save_path)
	manager.retry_save()
	check(
		FileAccess.get_file_as_string(repository.save_path) == protected_text,
		"Reintentar no sobrescribe una partida incompatible"
	)
	manager.free()
	repository.delete_progress()


func _progress_rules() -> void:
	var session: GameSession = GameSession.new()
	var first: Dictionary = session.record_learning(["Miis", "mayak"], "recall", "first", false, 0)
	check(first.changed and first.learned.size() == 2, "Una acción registra todas sus palabras")
	check(
		session.magic_points == 20 and session.learning_clock == 1,
		"La acción incrementa puntos y reloj una sola vez"
	)
	var before: Dictionary = session.snapshot()
	var repeated: Dictionary = session.record_learning(
		["Miis", "mayak"], "recall", "first", false, 0
	)
	check(
		not repeated.changed and session.snapshot() == before,
		"Restaurar el mismo resultado no multiplica evidencia ni recompensas"
	)


func _resource_identity() -> void:
	for world: int in [3, 4]:
		var original: ExerciseSet = load("res://data/exercises/world%d.tres" % world)
		var copy: ExerciseSet = original.duplicate(true) as ExerciseSet
		var first: Dictionary = CombinationVariation.exercises(original, {}, 123, world)
		check(not first.is_empty(), "El catálogo original permite variaciones")
		var repaired: Dictionary = CombinationVariation.exercises(
			original, {"combination_plan": ["invalid"]}, 123, world
		)
		check(
			repaired.ids == first.ids,
			"Un plan dañado usa el generador vigente, sin recuperar otro sistema"
		)
		check(
			CombinationVariation.exercises(copy, {}, 123, world).ids == first.ids,
			"Una copia idéntica conserva la política de variación"
		)
		var path: String = "user://moved_exercise_%d.tres" % world
		check(ResourceSaver.save(copy, path) == OK, "El recurso se puede guardar en otra ubicación")
		var moved: ExerciseSet = (
			ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ExerciseSet
		)
		check(
			CombinationVariation.exercises(moved, {}, 123, world).ids == first.ids,
			"Mover el recurso conserva su semántica y su plan"
		)
		copy.challenges[0].phrase = "Frase de autor"
		check(
			CombinationVariation.exercises(copy, {}, 123, world).is_empty(),
			"Una edición de autor no se reemplaza por contenido generado"
		)
		copy.variation_policy = ExerciseSet.VariationPolicy.AUTHORED
		check(
			not copy.allows_combinations(world),
			"La política de autor también se puede elegir explícitamente"
		)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _exercise_session() -> void:
	for seed_value: int in [123, 456]:
		var exercise: PhraseExerciseSession = PhraseExerciseSession.new()
		exercise.restore_attempt({"layout_seed": seed_value})
		exercise.build_plan(6, {})
		check(
			exercise.plan.size() == 12 and exercise.is_guided(),
			"Ambos ejercicios empiezan con seis rondas guiadas"
		)
		exercise.round_index = 6
		exercise.begin_round("test", "Miis", ["Áak", "mejen"])
		check(not exercise.is_guided(), "La segunda vuelta es de recuerdo")
		check(
			(
				exercise.submit(["Aak", "mejen"], ["Áak", "mejen"], true)
				and exercise.attempt.supported
			),
			"La comparación compartida conserva la ayuda por acentos"
		)
		exercise.miss()
		check(exercise.attempt.mistakes == 1, "Un error se cuenta una sola vez")
		exercise.resolve()
		var state: Dictionary = JSON.parse_string(
			JSON.stringify(exercise.snapshot("noun", "adjective", exercise.selected, {}))
		)
		check(
			state.noun == "Áak" and state.adjective == "mejen",
			"El snapshot conserva las claves vigentes de respuestas"
		)
		var restored: PhraseExerciseSession = PhraseExerciseSession.new()
		restored.restore_attempt(state)
		restored.build_plan(6, state)
		check(
			(
				restored.plan == exercise.plan
				and restored.round_index == 6
				and restored.attempt.mistakes == 1
			),
			"JSON conserva plan, ronda e intento"
		)
		check(
			exercise.advance() and exercise.round_index == 7,
			"Continuar avanza exactamente una ronda"
		)


func _grid_without_nodes() -> void:
	var word: GridWordData = GridWordData.new()
	word.maya_word = "Miis"
	word.start_cell = Vector2i(0, 1)
	word.destination_cell = Vector2i(3, 1)
	var grid: GridPathController = GridPathController.new()
	grid.configure(4, 3, [word], [Vector2i(1, 1)])
	var path: Array[Vector2i] = grid.hint_path(0)
	check(
		(
			path.front() == word.start_cell
			and path.back() == word.destination_cell
			and Vector2i(1, 1) not in path
		),
		"Las reglas buscan una ruta sin montar una escena"
	)
	grid.start(0)
	grid.extend(Vector2i(1, 1))
	check(grid.paths[0].is_empty(), "Una roca no se transforma en camino")
	for cell: Vector2i in path.slice(1, path.size() - 1):
		grid.extend(cell)
	grid.try_finalize(word.destination_cell)
	check(
		0 in grid.connected and not grid.drawing, "Las reglas completan una ruta sin presentación"
	)
	grid.reset_connected(0)
	check(
		grid.connected.is_empty() and grid.paths[0].is_empty(),
		"Reiniciar libera las celdas del camino"
	)


func _checkpoints() -> void:
	var story: Node = load("res://scenes/worlds/world1/historia1_isla_animales.tscn").instantiate()
	var snapshot: Dictionary = story.get_checkpoint_state()
	story._known_words.append("Miis")
	check(snapshot.known.is_empty(), "El snapshot de historia no cambia con su escena")
	story.free()
	var session: GameSession = GameSession.new()
	var navigator: SceneNavigator = SceneNavigator.new(session, func(): pass)
	root.add_child(navigator)
	var node: CheckpointNode = CheckpointNode.new()
	node.scene_file_path = GameContent.SCENE_PATHS.world1_level1
	navigator.checkpoint(node)
	node.items.append("Miis")
	check(
		session.scene_states.world1_level1.items.is_empty(),
		"El coordinador captura una copia profunda del checkpoint"
	)
	var returned: Dictionary = navigator.get_scene_state(node)
	returned.items.append("Kaax")
	check(
		session.scene_states.world1_level1.items.is_empty(),
		"La lectura tampoco devuelve el contenedor vivo"
	)
	node.free()
	navigator.queue_free()
	await process_frame


func _backup_without_primary() -> void:
	var repository: SaveRepository = repository_for("only_backup")
	check(repository.load_progress().is_empty(), "Sin archivos todavía no hay partida")
	write_json(repository.save_path + ".bak", {"version": SaveSchema.CURRENT_VERSION + 1})
	check(
		repository.load_progress().get("_unsupported_version", false),
		"Un respaldo incompatible sin archivo principal no se interpreta como partida nueva"
	)
	write_json(
		repository.save_path + ".bak", {"version": SaveSchema.CURRENT_VERSION, "magic_points": {}}
	)
	check(
		repository.load_progress().has("_load_error"),
		"El único respaldo dañado debe informar el error"
	)
	repository.delete_progress()


func _reset_edges() -> void:
	var manager: Node = load("res://scripts/autoloads/game_manager.gd").new()
	var unavailable: UnavailableRepository = UnavailableRepository.new(
		"user://reset_unavailable.json"
	)
	manager.use_save_repository(unavailable)
	manager.session.learn_word("Miis")
	var before: Dictionary = manager.session.snapshot()
	var signals: Dictionary = {"reset": 0, "points": 0}
	manager.progress_reset.connect(func() -> void: signals.reset += 1)
	manager.magic_points_changed.connect(func(_points: int) -> void: signals.points += 1)
	manager.reset_save()
	check(manager.session.snapshot() == before, "Si falla el borrado, se conserva el progreso vivo")
	check(
		signals.reset == 0 and signals.points == 0,
		"Un reinicio fallido no notifica a las vistas que se ha borrado la partida"
	)
	check(not manager.save_status_message.is_empty(), "El fallo de reinicio se muestra al usuario")
	manager.free()

	var repository: SaveRepository = repository_for("successful_reset")
	manager = load("res://scripts/autoloads/game_manager.gd").new()
	manager.use_save_repository(repository)
	manager.session.learn_word("Miis")
	manager.load_failed = true
	manager.save_status_message = "Partida ilegible"
	var observed: Dictionary = {}
	manager.progress_reset.connect(
		func() -> void:
			observed.failed = manager.load_failed
			observed.message = manager.save_status_message
			observed.words = manager.session.words_learned.duplicate(true)
	)
	manager.reset_save()
	check(
		not observed.failed and observed.message.is_empty() and observed.words.is_empty(),
		"Las vistas reciben el reinicio con todo el estado actualizado"
	)
	manager.free()
	repository.delete_progress()


func _long_practice() -> void:
	var session: GameSession = GameSession.new()
	for index: int in range(130):
		session.record_learning(["Miis"], "practice", "practice:%d" % index)
	var before: Dictionary = session.snapshot()
	var repeated: Dictionary = session.record_learning(["Miis"], "practice", "practice:129")
	check(
		not repeated.changed and session.snapshot() == before,
		"Superar 128 intentos no permite volver a acreditar el último resultado"
	)
	var restored: GameSession = GameSession.new()
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(before))
	check(restored.restore(decoded), "El historial largo se restaura desde JSON")
	before = restored.snapshot()
	repeated = restored.record_learning(["Miis"], "practice", "practice:129")
	check(
		not repeated.changed and restored.snapshot() == before,
		"La deduplicación del intento actual también se conserva después de cargar"
	)


func _nested_checkpoints() -> void:
	check(
		SceneStateSchema.sanitize({"carried": {}}).carried.is_empty(),
		"Sanear un objeto transportado vacío conserva la ausencia de entrega"
	)
	var state: Dictionary = {
		"intro_done": true,
		"layout_seed": 93,
		"active_task": 0,
		"mission_met": [0],
		"workbench_open": true,
		"carried": {"item": "mayak", "quality": "", "mistakes": {}, "supported": "invalid"},
		"drafts": {"0": {"scaffold": {"mode": {}, "slots": "invalid"}}}
	}
	var sanitized: Dictionary = SceneStateSchema.sanitize(state)
	check(
		sanitized.carried.mistakes == 0 and sanitized.carried.supported,
		"El objeto transportado valida sus campos antes de convertirlos"
	)
	check(
		(
			not sanitized.drafts["0"].scaffold.has("mode")
			and not sanitized.drafts["0"].scaffold.has("slots")
		),
		"Los borradores anidados validan el mismo contrato que el panel de respuestas"
	)
	check(
		state.carried.mistakes is Dictionary and state.drafts["0"].scaffold.mode is Dictionary,
		"Sanear un checkpoint conserva intacto el diccionario de origen"
	)
	var manager: Node = root.get_node("GameManager")
	var repository: SaveRepository = repository_for("nested_checkpoint")
	manager.use_save_repository(repository)
	manager.session.scene_states.world4_mission1 = state
	change_scene_to_file(GameContent.SCENE_PATHS.world4_mission1)
	await scene_changed
	await process_frame
	await process_frame
	check(
		current_scene._dialogue != null and current_scene.carried.get("mistakes") == 0,
		"Una misión con datos anidados dañados completa su inicialización"
	)
	check(
		current_scene.recall.mode == RecallPanel.Mode.WRITE,
		"Un modo de borrador inválido se restaura como escritura"
	)
	var portal: ExerciseSet = load("res://data/exercises/world5.tres")
	var prepared: Dictionary = PortalReplay.prepare(
		portal.challenges,
		{"portal_variants": {"0": []}, "previous_variation": {"portal_variants": {"0": {}}}},
		93
	)
	check(
		prepared.challenges.size() == portal.challenges.size() and prepared.variants.size() == 4,
		"El portal repara índices inválidos sin convertir objetos a enteros"
	)
	change_scene_to_file(GameContent.SCENE_PATHS.main_menu)
	await scene_changed
	repository.delete_progress()


class UnavailableRepository:
	extends SaveRepository

	func delete_progress() -> Error:
		return ERR_CANT_CREATE


class CheckpointNode:
	extends Node
	var items: Array[String] = []

	func get_checkpoint_state() -> Dictionary:
		return {"items": items}
