## Regresiones de interacción, ritmo, pausa y continuación. Usa un guardado aislado.
extends SceneTree

var failures: Array[String] = []
var manager: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _scene(key: String, fresh: bool = true) -> void:
	if fresh:
		manager.scene_states.erase(key)
	change_scene_to_file(manager.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame

func _resume() -> void:
	if current_scene.has_method("_on_menu_pressed"):
		current_scene._on_menu_pressed()
	else:
		manager.go_to_scene("main_menu")
	await scene_changed
	await process_frame
	# Leer JSON de nuevo comprueba también las conversiones de tipos tras cerrar el juego.
	manager.scene_states.clear()
	manager.resume_scene_key = ""
	manager._load_save()
	manager.continue_adventure()
	await scene_changed
	await process_frame
	await process_frame

func _run() -> void:
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new("user://ux_validation_progress.json")
	manager.scene_states.clear()
	manager.completed_levels.clear()
	manager.words_learned.clear()
	manager.tutorials_seen.clear()
	manager.resume_scene_key = ""
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/MainMenu.tscn", "El arranque debe ofrecer Jugar o Continuar")
	await _menu()
	await _paths()
	await _objects()
	await _phrases()
	await _requests()
	await _portal()
	await _story()
	await _exploration()
	await _memory()
	await _menu_destination()
	_validate_migration()
	await _scene("main_menu")
	if failures.is_empty():
		print("Validación UX: OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _menu() -> void:
	await _scene("main_menu")
	_check(current_scene.world_buttons.size() == 5, "El mapa debe presentar cinco lugares")
	manager.magic_points = 123
	current_scene._on_reset_pressed()
	_check(manager.magic_points == 123, "Abrir ajustes no debe borrar la partida")
	_check(current_scene.reset_confirmation.visible, "El borrado necesita confirmación visible")
	current_scene.reset_confirmation.hide()
	_check(manager.magic_points == 123, "Cancelar debe conservar el progreso")
	manager.magic_points = 0

func _paths() -> void:
	await _scene("world1_level1")
	var level: Node = current_scene
	var board: GridBoard = level.grid_board
	var source := board.get_word_node(0)
	var animal := source.get_child(0) as TextureRect
	_check(animal.size.x <= source.size.x and animal.size.y <= source.size.y, "El animal debe caber en la zona que recibe el clic")
	_check(not board.get_word_node(1).visible, "El tutorial debe empezar con un solo animal")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = animal.get_global_rect().position + animal.size * Vector2(0.5, 0.8)
	board._unhandled_input(click)
	_check(board.drawing and board.active_index == 0, "Pulsar el cuerpo del animal debe iniciar el camino")
	for column: int in range(1, board.words[0].destination_cell.x + 1):
		board._try_cell(Vector2i(column, 1))
	await create_timer(0.15).timeout
	var walker := level.get_node("UI/ArrivingAnimal") as TextureRect
	var start := board.cell_to_local_position(board.words[0].start_cell)
	_check(level._arrival_animating and not level.dialogue.visible, "La palabra debe esperar a que el animal llegue a su casa")
	_check(walker.position.x > start.x and walker.position.y < start.y and absf(walker.rotation) > 0.001, "El animal debe avanzar con elevación y balanceo, como Kalin")
	level.libro.show_book()
	var paused_position := walker.position
	await create_timer(0.2).timeout
	_check(walker.position.is_equal_approx(paused_position), "El libro debe pausar también el salto del animal")
	level.libro.hide_book()
	await create_timer(1.0).timeout
	_check(level._arrival_animating, "La llegada no debe recorrer todo el camino en sólo un segundo")
	await _wait_for_arrival(level)
	_check(level._dialogue_open and level.dialogue.visible, "El animal debe llegar y dejar visible la palabra recuperada")
	_check(board.get_word_node(1).visible, "Después del primer acierto deben aparecer los demás animales")
	await _resume()
	await _wait_for_arrival(current_scene)
	level = current_scene
	board = level.grid_board
	_check(level._dialogue_open and level.dialogue.visible, "Continuar debe recuperar también la palabra pendiente de leer")
	level.libro.show_book()
	_check(paused and not level.can_process(), "Consultar el libro debe pausar el ejercicio")
	level.libro.hide_book()
	_check(not paused, "Cerrar el libro debe reanudar el ejercicio")
	level._close_dialogue()
	board._handle_press(board.words[1].start_cell)
	board._try_cell(board.words[1].start_cell + Vector2i.RIGHT)
	board._stop_drawing()
	await _resume()
	_check(current_scene.scene_file_path == manager.SCENE_PATHS.world1_level1, "Continuar debe volver al tablero, sin repetir el prólogo")
	_check(current_scene.grid_board.connected.size() == 1, "Se debe conservar el animal conectado")
	_check(current_scene.grid_board.paths[1].size() == 1, "Se debe conservar el camino parcial")

func _wait_for_arrival(level: Node) -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while level._arrival_animating and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not level._arrival_animating, "El animal debe terminar su recorrido y aterrizar")
	_check(level.get_node_or_null("UI/ArrivingAnimal") == null, "La llegada debe retirar el animal animado al mostrar el de la casa")

func _objects() -> void:
	await _scene("world2_level1")
	var word: String = current_scene._current_object().maya
	current_scene._on_choice_pressed(word)
	_check(word in current_scene.room_items, "El objeto recuperado debe aparecer en la casa")
	await create_timer(1.6).timeout
	_check(current_scene.round_index == 0 and current_scene.next_button.visible, "El mensaje de aprendizaje debe esperar al jugador")
	await _continue_hint(current_scene.next_button)
	await _resume()
	_check(current_scene._waiting and word in current_scene.room_items, "Continuar debe restaurar el mueble y el acierto pendiente")
	current_scene._advance_round()
	_check(current_scene.round_index == 1, "La flecha debe avanzar exactamente una ronda")
	_check(not current_scene.guide.hand.visible and current_scene.guide._continue_target == null, "Cambiar de ronda debe quitar el aviso pendiente")
	for index: int in range(current_scene.round_index, current_scene.TOTAL_ROUNDS):
		current_scene._on_choice_pressed(current_scene._current_object().maya)
		current_scene._advance_round()
	_check(current_scene.completion.visible and current_scene.completion.get_index() > current_scene.room.get_index(), "El cierre debe quedar por encima de la casa y recibir los clics")
	_check(not current_scene.guide.hand.visible, "El aviso no debe cubrir la pantalla de nivel completado")
	await process_frame
	var panel: Control = current_scene.completion.panel
	var center := panel.get_global_rect().get_center()
	var hover := InputEventMouseMotion.new()
	hover.position = center
	hover.global_position = center
	root.push_input(hover, true)
	await process_frame
	var hovered := root.gui_get_hovered_control()
	_check(hovered != null and current_scene.completion.is_ancestor_of(hovered), "La casa no debe interceptar la interacción del panel final (control: %s)" % (hovered.get_path() if hovered else "ninguno"))

func _continue_hint(button: Button) -> void:
	var guide: LearningGuide = current_scene.guide
	_check(guide._continue_target == button and not guide.hand.visible, "La mano debe esperar antes de señalar Continuar")
	var movement := InputEventMouseMotion.new()
	movement.relative = Vector2(30, 0)
	guide._input(movement)
	await create_timer(2.0).timeout
	_check(not guide.hand.visible, "La ayuda no debe aparecer antes de cuatro segundos")
	guide._input(movement)
	current_scene.libro.show_book()
	var elapsed := guide._idle_seconds
	await create_timer(0.25).timeout
	_check(is_equal_approx(guide._idle_seconds, elapsed), "El tiempo de ayuda debe pausarse al consultar el libro")
	current_scene.libro.hide_book()
	await create_timer(2.1).timeout
	_check(not guide.hand.visible, "La interacción debe reiniciar la espera de ayuda")
	await create_timer(2.1).timeout
	_check(guide.hand.visible and guide._point_target == button, "Tras cuatro segundos de inactividad la mano debe señalar Continuar")
	guide._input(movement)
	_check(not guide.hand.visible, "Volver a interactuar debe retirar la mano")

func _phrases() -> void:
	await _scene("world3_level1")
	var challenge: ExerciseEntry = current_scene._current_challenge()
	current_scene._select_noun(challenge.noun)
	current_scene._select_adjective(challenge.adjective)
	current_scene._on_cast_pressed()
	await create_timer(1.6).timeout
	_check(current_scene.round_index == 0 and current_scene._awaiting_continue, "El Mundo 3 debe conservar el acierto hasta Continuar")
	_check(current_scene.result_art.visible, "El hechizo debe mostrar el objeto a la medida")
	_check(current_scene.guide._continue_target == current_scene.cast_button, "El taller debe ofrecer la ayuda diferida de Continuar")
	var plan: Array = current_scene.round_plan.duplicate()
	await _resume()
	_check(current_scene.round_plan == plan and current_scene._awaiting_continue, "Se debe restaurar el plan y el acierto de adjetivos")
	current_scene._on_cast_pressed()
	_check(current_scene.round_index == 1, "Continuar adjetivos debe avanzar una ronda")
	current_scene.round_index = current_scene.CHALLENGES.size()
	current_scene._show_round()
	for button: Button in current_scene.noun_buttons.values():
		_check(button.icon == null, "El repaso debe practicar palabras, sin duplicar la pista con iconos en las respuestas")

func _requests() -> void:
	manager.scene_states.world4_level1 = {"round": {}, "plan": ["inválido"], "food": [], "waiting": []}
	await _scene("world4_level1", false)
	_check(current_scene.round_index == 0, "Un checkpoint con tipos incorrectos debe volver a un estado jugable")
	_check(current_scene._current_challenge().food == "ja'", "La primera petición debe enseñar un caso sencillo sin tamaño")
	current_scene._select_food("ja'")
	_check(current_scene.modifier_slot.text.is_empty() and not current_scene.modifier_slot.visible, "Una frase sin tamaño debe contener solamente palabras mayas")
	_check(not current_scene.serve_button.disabled and current_scene.selected_modifier == "", "Agua debe poder servirse sin elegir Sin tamaño")
	current_scene._on_serve_pressed()
	await create_timer(1.3).timeout
	_check(current_scene.round_index == 0 and current_scene._awaiting_continue, "La petición acertada debe esperar al jugador")
	_check(not current_scene.modifier_slot.visible and current_scene.modifier_slot.text.is_empty(), "El acierto sin tamaño no debe añadir un símbolo a la frase")
	_check(current_scene.guide._continue_target == current_scene.serve_button, "Servir debe activar la ayuda diferida de Continuar")
	await _resume()
	_check(current_scene._awaiting_continue, "Se debe restaurar la petición entregada")
	current_scene._on_serve_pressed()
	_check(current_scene.round_index == 1, "Continuar una petición debe avanzar una ronda")
	var challenge: ExerciseEntry = current_scene._current_challenge()
	_check(current_scene.modifier_slot.visible and current_scene.modifier_slot.text.is_empty(), "Una petición con tamaño necesita un espacio vacío donde colocar su palabra")
	current_scene._select_food(challenge.food)
	current_scene._on_serve_pressed()
	_check(not current_scene._awaiting_continue, "Una petición con tamaño no debe aceptar un tamaño ausente")
	current_scene._select_modifier(challenge.modifier)
	_check(current_scene.modifier_slot.text == challenge.modifier, "El tamaño elegido debe aparecer en maya")
	current_scene._on_serve_pressed()
	_check(current_scene._awaiting_continue, "La petición completa debe poder entregarse")
	current_scene.round_index = current_scene.CHALLENGES.size()
	current_scene._show_round()
	for button: Button in current_scene.food_buttons.values():
		_check(button.icon == null, "Los alimentos del repaso no deben regalar la respuesta por coincidencia de dibujos")
	current_scene.libro.show_book()
	_check(paused, "El libro debe pausar también las peticiones")
	current_scene.libro.hide_book()

func _portal() -> void:
	await _scene("world5_level1")
	current_scene._on_option_pressed(current_scene.CHALLENGES[0].correct)
	await create_timer(1.3).timeout
	_check(current_scene.challenge_index == 0 and current_scene.next_button.visible, "La página del portal debe esperar a Continuar")
	_check(current_scene.guide._continue_target == current_scene.next_button, "El portal debe ofrecer la ayuda diferida de Continuar")
	await _resume()
	_check(current_scene._awaiting_continue and current_scene.portal_energy.value == 1, "Se debe restaurar la página recuperada del portal")

func _story() -> void:
	await _scene("world1_story1")
	current_scene._next_beat()
	current_scene._next_beat()
	current_scene._meet_actor("Peek'")
	await _resume()
	_check(current_scene.beat_index == 2 and "Peek'" in current_scene._met_words, "La historia debe recordar el momento y los animales saludados")
	await create_timer(0.7).timeout
	var target: Control = current_scene.actor_buttons["Miis"]
	_check(absf(current_scene.guide.hand.position.x - target.get_global_rect().get_center().x + 22) < 1, "La mano debe seguir al siguiente animal durante su entrada")

func _exploration() -> void:
	await _scene("world1_explore1")
	while current_scene.is_dialogue_open():
		current_scene.advance_dialogue()
	var spot: ExplorationSpot = current_scene.spots[0]
	current_scene._place_kalin(spot.position.x)
	current_scene.open_spot(spot)
	while current_scene.is_dialogue_open():
		current_scene.advance_dialogue()
	var name: String = str(spot.name)
	await _resume()
	var found := false
	for restored: ExplorationSpot in current_scene.spots:
		if str(restored.name) == name:
			found = restored.examined
	_check(found and current_scene._intro_done, "La exploración debe recordar descubrimientos y no repetir el diálogo inicial")

func _memory() -> void:
	await _scene("world1_level3")
	await create_timer(4.3).timeout
	_check(current_scene.previewing and current_scene.grid_board.obstacle_clues_visible, "Las rocas no deben desaparecer antes de que el jugador esté listo")
	current_scene._toggle_preview()
	_check(not current_scene.grid_board.obstacle_clues_visible, "Listo debe iniciar el reto de memoria")
	current_scene._toggle_preview()
	_check(current_scene.grid_board.obstacle_clues_visible, "Debe ser posible volver a consultar las rocas")

func _validate_migration() -> void:
	var legacy_path := "user://ux_legacy_v1.json"
	var file := FileAccess.open(legacy_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "magic_points": 100, "completed_levels": ["w1_l1"], "words_learned": {"mejen": {}, "nojoch": {}, "ki'": {}}}))
	file.close()
	var old_manager: Node = load("res://scripts/autoloads/GameManager.gd").new()
	old_manager._save_repository = load("res://scripts/data/SaveRepository.gd").new(legacy_path)
	old_manager._load_save()
	_check(old_manager.is_level_completed(1, 1), "La migración debe conservar niveles completados")
	_check(not old_manager.is_level_completed(3, 1), "Aprender tres palabras no debe marcar como terminado un mundo pendiente")
	old_manager.free()

func _menu_destination() -> void:
	manager.completed_levels.clear()
	manager.scene_states.clear()
	for index: int in range(5):
		var info: Dictionary = manager.LEVEL_ORDER[index]
		manager.completed_levels.append("w%d_l%d" % [info.world, info.level])
	manager.resume_scene_key = "world1_level1"
	await _scene("main_menu")
	current_scene._on_level_pressed(5)
	await scene_changed
	await process_frame
	_check(current_scene.scene_file_path == manager.SCENE_PATHS.world2_story1, "Elegir un nivel pendiente debe abrir ese destino aunque se estuviera repitiendo otro")
