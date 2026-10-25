extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_domain_inputs()
	_boolean_inputs()
	_destination()
	_incompatible_files()
	_navigation_failure()
	finish("Transacciones y límites del estado vigente")


func _domain_inputs() -> void:
	var session: GameSession = GameSession.new()
	var before: Dictionary = session.snapshot()
	check(not session.learn_word("desconocida"), "No se aprende una palabra fuera del catálogo")
	check(not session.complete_level(9, 9), "No se completa un nivel inexistente")
	check(session.snapshot() == before, "Las entradas inválidas no crean progreso ni puntos")


func _boolean_inputs() -> void:
	for value: Variant in [[], {}, null, 1, "true", false, true]:
		var attempt: LearningAttempt = LearningAttempt.new()
		attempt.restore({"supported": value})
		var exercise: PhraseExerciseSession = PhraseExerciseSession.new()
		exercise.restore_attempt({"cards": value})
		var enabled: bool = value is bool and value
		check(attempt.supported == enabled, "El intento acepta sólo ayuda de tipo booleano")
		check(exercise.cards == enabled, "La sesión acepta sólo tarjetas de tipo booleano")


func _destination() -> void:
	var word: GridWordData = GridWordData.new()
	word.start_cell = Vector2i(0, 0)
	word.destination_cell = Vector2i(3, 0)
	var grid: GridPathController = GridPathController.new()
	grid.configure(4, 2, [word], [])
	grid.start(0)
	grid.extend(Vector2i(1, 0))
	grid.try_finalize(word.start_cell)
	check(grid.connected.is_empty() and grid.drawing, "Volver al inicio no finaliza un camino")
	grid.extend(Vector2i(2, 0))
	grid.try_finalize(Vector2i(1, 0))
	check(grid.connected.is_empty(), "Una casilla propia tampoco sustituye al destino")
	grid.try_finalize(word.destination_cell)
	check(grid.connected == [0], "La conexión con el destino válido se conserva")


func _incompatible_files() -> void:
	var repository: SaveRepository = repository_for("write_barrier")
	var session: GameSession = GameSession.new()
	session.learn_word("Miis")
	for suffix: String in ["", ".bak"]:
		for version: int in [SaveSchema.CURRENT_VERSION - 1, SaveSchema.CURRENT_VERSION + 1]:
			var path: String = repository.save_path + suffix
			write_json(path, {"version": version, "magic_points": 321})
			var before: String = FileAccess.get_file_as_string(path)
			check(
				repository.save_progress(session.snapshot()) == ERR_INVALID_DATA,
				"El repositorio rechaza sobrescribir otro formato"
			)
			check(
				FileAccess.get_file_as_string(path) == before,
				"El archivo incompatible queda intacto"
			)
			check(
				not FileAccess.file_exists(repository.save_path + ".tmp"),
				"El rechazo ocurre antes de crear temporales"
			)
			repository.delete_progress()
	check(repository.save_progress(session.snapshot()) == OK, "Una partida nueva sigue guardándose")
	check(session.learn_word("Áak"), "Se agrega otra palabra válida antes de actualizar")
	check(
		repository.save_progress(session.snapshot()) == OK,
		"El formato vigente sigue actualizándose"
	)
	check(
		repository.load_progress().magic_points == session.magic_points,
		"La escritura aceptada se puede recuperar"
	)
	repository.delete_progress()


func _navigation_failure() -> void:
	var session: GameSession = GameSession.new()
	var writes: Array[Dictionary] = []
	var navigator: RefusingNavigator = RefusingNavigator.new(
		session, func() -> void: writes.append(session.snapshot())
	)
	root.add_child(navigator)
	var source: CheckpointSource = CheckpointSource.new()
	source.scene_file_path = GameContent.SCENE_PATHS.world3_level1
	root.add_child(source)
	current_scene = source
	session.resume_scene_key = "world3_level1"
	# La apertura fallida es deliberada; el resto de errores del proceso se registra.
	var previous_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var accepted: bool = navigator.go_to_scene("world4_level1")
	Engine.print_error_messages = previous_errors
	check(not accepted, "La navegación devuelve el rechazo del motor")
	check(current_scene == source, "La escena de origen sigue activa")
	check(
		session.resume_scene_key == "world3_level1",
		"Una apertura fallida conserva la escena de continuación"
	)
	check(
		writes.size() == 1 and writes[0].resume_scene_key == "world3_level1",
		"Sólo se persiste el checkpoint de origen"
	)
	check(
		session.scene_states.world3_level1.round == 2,
		"Se conserva el progreso capturado antes del intento"
	)
	session.complete_level(4, 1)
	session.practice_return_key = "world1_level1"
	Engine.print_error_messages = false
	navigator.visit_village()
	Engine.print_error_messages = previous_errors
	check(
		session.practice_return_key == "world1_level1",
		"Una visita rechazada conserva su destino de retorno anterior"
	)
	check(
		writes[-1].practice_return_key == "world1_level1",
		"El retorno anterior también se conserva en disco"
	)
	navigator.result = OK
	check(navigator.go_to_scene("world4_level1"), "La transición aceptada avanza")
	check(
		(
			session.resume_scene_key == "world4_level1"
			and writes[-1].resume_scene_key == "world4_level1"
		),
		"El destino se persiste después de aceptar la transición"
	)
	current_scene = null
	source.free()
	navigator.free()


class RefusingNavigator:
	extends SceneNavigator
	var result: Error = ERR_CANT_OPEN

	func _request_scene(_path: String) -> Error:
		return result


class CheckpointSource:
	extends Node

	func get_checkpoint_state() -> Dictionary:
		return {"round": 2}
