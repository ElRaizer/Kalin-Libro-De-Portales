extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_domain_inputs()
	_boolean_inputs()
	_destination()
	_incompatible_files()
	_navigation_failure()
	_quit_failure()
	await _scene_navigation_recovery()
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
	navigator.visit_home()
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


func _quit_failure() -> void:
	var manager: QuitObserver = QuitObserver.new()
	root.add_child(manager)
	var repository: RefusingWriteRepository = RefusingWriteRepository.new(
		"user://quit_failure.json"
	)
	repository.delete_progress()
	manager.use_save_repository(repository)
	var notice: CanvasLayer = load("res://scenes/ui/shared/save_notice.tscn").instantiate()
	manager.add_child(notice)
	manager.session.learn_word("Miis")
	manager.retry_save()
	var saved: String = FileAccess.get_file_as_string(repository.save_path)
	manager.session.learn_word("Áak")
	var before: Dictionary = manager.session.snapshot()
	repository.refuse = true
	var previous_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	manager.quit_game()
	Engine.print_error_messages = previous_errors
	check(manager.quit_requests == 0, "No se cierra el juego cuando falla el guardado final")
	check(manager.session.snapshot() == before, "El cierre rechazado conserva el avance en memoria")
	check(not manager.save_status_message.is_empty(), "El cierre rechazado informa cómo reintentar")
	check(
		notice.get_node("Panel").visible,
		"El aviso de guardado sigue visible tras rechazar el cierre"
	)
	check(
		FileAccess.get_file_as_string(repository.save_path) == saved,
		"El cierre rechazado conserva la última partida válida"
	)
	repository.refuse = false
	manager.retry_save()
	check(manager.save_status_message.is_empty(), "Reintentar permite guardar y retirar el aviso")
	check(not notice.get_node("Panel").visible, "El aviso se retira tras guardar correctamente")
	manager.quit_game()
	check(manager.quit_requests == 1, "El cierre se solicita sólo después de guardar con éxito")
	var restored: GameSession = GameSession.new()
	check(restored.restore(repository.load_progress()), "La última partida se restaura")
	check(restored.snapshot() == before, "El cierre aceptado conserva también el avance reciente")
	manager.free()
	repository.delete_progress()


func _scene_navigation_recovery() -> void:
	var manager: Node = root.get_node("GameManager")
	var previous_navigator: SceneNavigator = manager._scene_navigator
	var navigator: RefusingNavigator = RefusingNavigator.new(manager.session, manager._save)
	root.add_child(navigator)
	manager._scene_navigator = navigator
	change_scene_to_file(GameContent.SCENE_PATHS.world1_story1)
	await scene_changed
	await process_frame
	var story: Node = current_scene
	story._complete_text()
	story.interaction.resolved = true
	story._narrative_ready = true
	story.beat_index = story.beats.size()
	var previous_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	story._finish_story()
	Engine.print_error_messages = previous_errors
	check(current_scene == story and not story._navigating, "La historia fallida recupera entrada")
	check(not story.continue_button.disabled, "Continuar permite reintentar la salida narrativa")
	check(story.hint_label.visible, "La historia muestra el fallo de apertura")
	check(story.beat_index < story.beats.size(), "El momento permanece dentro del capítulo")
	paused = true
	Engine.print_error_messages = false
	story._on_menu_pressed()
	Engine.print_error_messages = previous_errors
	check(not story._navigating, "Un menú rechazado tampoco bloquea la historia")
	check(paused, "La recuperación de navegación respeta la pausa existente")
	paused = false
	change_scene_to_file(GameContent.SCENE_PATHS.world1_level1)
	await scene_changed
	await process_frame
	var paths: Node = current_scene
	for enabled: bool in [true, false]:
		paths.grid_board.set_interaction_enabled(enabled)
		Engine.print_error_messages = false
		paths._safe_navigate("main_menu")
		Engine.print_error_messages = previous_errors
		check(
			paths.grid_board.input_enabled == enabled,
			"El tablero recupera su estado de entrada anterior al rechazo"
		)
	change_scene_to_file(GameContent.SCENE_PATHS.world3_level1)
	await scene_changed
	await process_frame
	var adjective: Node = current_scene
	for resolving: bool in [true, false]:
		adjective._resolving = resolving
		Engine.print_error_messages = false
		adjective._safe_navigate("main_menu")
		Engine.print_error_messages = previous_errors
		check(
			adjective._resolving == resolving,
			"El taller conserva el estado de respuesta anterior al rechazo"
		)
	change_scene_to_file(GameContent.SCENE_PATHS.world1_explore1)
	await scene_changed
	await process_frame
	var exploration: Node = current_scene
	Engine.print_error_messages = false
	exploration._finish()
	await create_timer(exploration.FADE_SECONDS + 0.1).timeout
	Engine.print_error_messages = previous_errors
	check(
		current_scene == exploration and not exploration._navigating,
		"La exploración recupera entrada tras rechazar el destino"
	)
	check(is_zero_approx(exploration.fade.modulate.a), "El fallo retira el fundido opaco")
	check(exploration.skip_button.visible, "La exploración ofrece reintentar su salida")
	check(
		exploration.objective_label.text.contains("No se pudo"),
		"La exploración explica que la apertura ha fallado"
	)
	navigator.result = OK
	exploration.skip_button.pressed.emit()
	await create_timer(exploration.FADE_SECONDS + 0.1).timeout
	check(exploration._navigating, "La salida recuperada permite volver a solicitar el destino")
	check(
		manager.session.resume_scene_key == exploration.next_scene_key,
		"Sólo el reintento aceptado confirma el destino de continuación"
	)
	manager._scene_navigator = previous_navigator
	navigator.free()
	current_scene = null
	exploration.free()


class QuitObserver:
	extends "res://scripts/autoloads/game_manager.gd"
	var quit_requests: int = 0

	func _request_quit() -> void:
		quit_requests += 1


class RefusingWriteRepository:
	extends SaveRepository
	var refuse: bool = false

	func save_progress(data: Dictionary) -> Error:
		return ERR_CANT_CREATE if refuse else super.save_progress(data)


class RefusingNavigator:
	extends SceneNavigator
	var result: Error = ERR_CANT_OPEN

	func _request_scene(_path: String) -> Error:
		return result


class CheckpointSource:
	extends Node

	func get_checkpoint_state() -> Dictionary:
		return {"round": 2}
