extends ProjectTest

var manager: Node
var capture_directory: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	manager.use_save_repository(repository_for("challenge_room"))
	manager.reset_save()
	for word: String in [
		"Áak", "Miis", "mayak", "mejen", "nojoch", "chich", "Bix a beel", "ja'", "ki'", "janal"
	]:
		manager.learn_word(word)
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	var room: Node = home.room
	room.open_room(home.return_button)
	var plan: Dictionary = room.snapshot()
	check(plan.words.size() > 0 and plan.words.size() <= 3, "Crea una tanda breve")
	room.recall.first.text = "borrador"
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	await process_frame
	check(not room.visible and not paused, "Esc guarda el reto y devuelve el paseo")
	check(root.gui_get_focus_owner() == home.return_button, "La salida devuelve el foco")
	home = await _reload_home()
	room = home.room
	room.open_room(home.return_button)
	var restored: Dictionary = room.snapshot()
	check(
		restored.targets == plan.targets and restored.visitors == plan.visitors,
		"Cargar conserva el plan concreto y los interlocutores"
	)
	check(room.recall.first.text == "borrador", "Conserva la respuesta sin confirmar")
	room.close_room()
	manager.mark_learning_support()
	# La ayuda consultada fuera del modal debe acompañar al intento pendiente.
	room.open_room(home.return_button)
	check(room.attempt.content_help, "Consultar fuera de la sala conserva la ayuda")
	room.close_room()
	await _situation(home, ["Miis"], 300, "01_animal")
	await _situation(home, ["Bix a beel"], 301, "02_conversacion")
	await _situation(home, ["janal", "ki'"], 302, "03_pedido")
	await _rest_delivery(home)
	await _recent_partner(home)
	manager.reset_save()
	room.restore({})
	room.open_room(home.return_button)
	check(
		not room._result.visible and room._submit.disabled and room.preview.art == null,
		"Una partida vacía no conserva el resultado visual anterior"
	)
	room.close_room()
	finish(
		"Sala de retos: variedad, peticiones sin solución anticipada, consecuencias y colaboración opcional"
	)


func _situation(home: Node, answers: Array[String], visit: int, name: String) -> void:
	var room: Node = home.room
	manager.session.learning_clock += LearningProgress.RECALL_GAP
	room.restore({"words": [answers[0]], "targets": [answers], "visit": visit})
	room.open_room(home.return_button)
	check(
		room.targets[0] == answers, "El escenario usa exactamente la combinación canónica prevista"
	)
	check(
		room.preview.art == null and room.preview.motion == null,
		"La petición no muestra el objeto ni su uso antes de responder"
	)
	check(
		not room._result.visible and room.visitors[0] not in answers,
		"El interlocutor no adelanta el animal ni el texto esperado"
	)
	for word: String in answers:
		check(not room._request.text.contains(word), "La petición no incluye la solución maya")
	await _capture(name + "_peticion")
	root.size = Vector2i(640, 360)
	home.get_node("ScreenLayout").preview_compact = true
	home.get_node("ScreenLayout").refresh()
	room._hint_button.pressed.emit()
	room._hint_button.pressed.emit()
	check(room.recall.mode == RecallPanel.Mode.BLOCKS, "Conserva los apoyos hasta bloques")
	await _capture(name + "_apoyo_compacto")
	_check_bounds(room)
	var active: Dictionary = room.snapshot()
	room.close_room()
	room.restore(JSON.parse_string(JSON.stringify(active)))
	room.open_room(home.return_button)
	check(
		room.recall.mode == RecallPanel.Mode.BLOCKS and room.attempt.supported,
		"Reanudar conserva piezas y evidencia de apoyo"
	)
	var points: int = manager.session.magic_points
	room.recall.debug_fill(answers)
	room.submit()
	check(
		room.waiting and room._result.visible and not room.recall.visible,
		"La confirmación muestra la consecuencia"
	)
	check(manager.session.magic_points == points, "La aportación con apoyo no inventa puntos")
	check(room._feedback.text.contains("con apoyo"), "Distingue colaboración de recuerdo libre")
	check(not room._outcome.text.is_empty(), "La aportación tiene un cierre ajeno al saldo")
	for word: String in answers:
		check(
			manager.learning_record(word).recalls.is_empty(),
			"El resultado apoyado no registra recuperación independiente"
		)
	await _capture(name + "_resultado_compacto")
	_check_bounds(room)
	var confirmed: Dictionary = room.snapshot()
	room.close_room()
	room.restore(JSON.parse_string(JSON.stringify(confirmed)))
	room.open_room(home.return_button)
	check(
		room.waiting and room._result.visible, "El resultado confirmado se reanuda sin otro acierto"
	)
	check(manager.session.magic_points == points, "Reabrir el resultado no vuelve a pagar")
	room._submit.pressed.emit()
	check(not paused and not room.visible, "El cierre de tanda devuelve el paseo")
	root.size = Vector2i(1280, 720)
	home.get_node("ScreenLayout").preview_compact = false
	home.get_node("ScreenLayout").refresh()


func _rest_delivery(home: Node) -> void:
	manager.session.scene_states.world5_cine1 = {"complete": true}
	for _step: int in range(RestCornerState.INTRO_STEPS):
		manager.session.advance_rest_intro()
	manager.session.choose_rest_corner("mayak")
	var room: Node = home.room
	manager.session.learning_clock += LearningProgress.RECALL_GAP
	room.restore({"words": ["mayak"], "targets": [["mayak", "chich"]], "visit": 310})
	room.open_room(home.return_button)
	room._hint_button.pressed.emit()
	room.recall.debug_fill(["mayak", "chich"])
	var before: Dictionary = manager.session.snapshot()
	room.submit()
	check(
		room._delivery.visible and not manager.session.rest_corner.complete,
		"Una aportación compatible ofrece colaborar sin confirmar por el jugador"
	)
	await _capture("04_llevar_al_rincon")
	room._delivery.pressed.emit()
	check(
		manager.session.rest_corner.complete and home._rest_panel.visible,
		"Llevar abre las reacciones del proyecto y su guirnalda"
	)
	check(
		manager.session.garden == before.garden and manager.session.economy == before.economy,
		"Colaborar no fabrica muebles ni cambia premios"
	)
	check(
		manager.learning_record("mayak").recalls.is_empty(),
		"La colaboración con apoyo no se convierte en recuerdo libre"
	)
	await _capture("05_resultado_en_rincon")
	home._rest_panel.close_panel()
	check(
		root.gui_get_focus_owner() == home._action,
		"Cerrar el proyecto devuelve el foco al paseo desde la sala"
	)
	room.open_room(home.return_button)
	check(not room._delivery.visible, "El proyecto terminado no se entrega otra vez")
	room.close_room()
	# Con el premio ya saturado, la escena sigue teniendo su cierre sin otro pago.
	manager.record_learning(["Miis"], "recall", "elsewhere/Miis@1")
	manager.session.learning_clock += LearningProgress.RECALL_GAP
	room.restore({"words": ["Miis"], "targets": [["Miis"]], "visit": 311})
	room.open_room(home.return_button)
	var points: int = manager.session.magic_points
	room.recall.debug_fill(["Miis"])
	room.submit()
	check(
		room.waiting and room._result.visible and manager.session.magic_points == points,
		"Con máximo saturado conserva consecuencia sin pagar de nuevo"
	)
	await _capture("06_encuentro_sin_premio_extra")
	room.close_room()
	manager.session.learning_clock += LearningProgress.RECALL_GAP
	room.restore({"words": ["Áak"], "targets": [["Áak"]], "visit": 312})
	room.open_room(home.return_button)
	points = manager.session.magic_points
	room.recall.first.text = "Aak"
	room.submit()
	check(
		room.waiting and room._feedback.text.contains("con apoyo"),
		"La corrección de grafía también se presenta como apoyo"
	)
	check(
		manager.session.magic_points == points,
		"La grafía corregida no paga como escritura independiente"
	)
	room.close_room()


func _recent_partner(home: Node) -> void:
	var room: Node = home.room
	var anchor: Dictionary = manager.learning_record("mayak")
	anchor.last_seen = manager.session.learning_clock - LearningProgress.RECALL_GAP
	manager.session.learning_progress.mayak = anchor
	var partner: Dictionary = manager.learning_record("chich")
	partner.last_seen = manager.session.learning_clock
	manager.session.learning_progress.chich = partner
	room.restore({"words": ["mayak"], "targets": [["mayak", "chich"]], "visit": 320})
	room.open_room(home.return_button)
	check(
		room._feedback.text.contains("Ensaya"),
		"La recencia de la segunda palabra también convierte la pareja en ensayo"
	)
	var before: int = manager.session.magic_points
	room.recall.debug_fill(["mayak", "chich"])
	room.submit()
	check(
		room.waiting and manager.session.magic_points == before,
		"El ensayo de pareja no paga como recuperación separada"
	)
	check(
		manager.learning_record("mayak").recalls.is_empty(),
		"El ancla antigua no simula otra separación al acompañar una palabra reciente"
	)
	room.close_room()


func _reload_home() -> Node:
	manager.checkpoint(current_scene)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(manager.session.snapshot()))
	check(manager.session.restore(snapshot), "Carga JSON de la tanda pendiente")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	return current_scene


func _check_bounds(room: Node) -> void:
	for button: Node in room.controls.find_children("*", "Button", true, false):
		if button is Button and button.is_visible_in_tree():
			check(button.get_global_rect().end.y <= 720, "Las acciones caben en altura compacta")
			check(button.get_global_rect().end.x <= 1280, "Los controles caben en ancho compacto")


func _capture(name: String) -> void:
	await process_frame
	await process_frame
	if capture_directory.is_empty():
		return
	await RenderingServer.frame_post_draw
	check(
		root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK,
		"Captura de " + name
	)
