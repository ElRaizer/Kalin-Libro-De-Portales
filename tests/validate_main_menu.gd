extends SceneTree

var failures: Array[String] = []
var capture_folder: String = ""


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_folder = argument.trim_prefix("--capture=")
	var manager: Node = root.get_node("GameManager")
	# SceneTree inicia este script junto con los autoloads. Esperar un frame evita
	# que GameManager._ready() cargue la partida después de preparar el escenario.
	await process_frame
	var original_completed: Array[String] = manager.session.completed_levels.duplicate()
	var empty_progress: Array[String] = []
	manager.session.completed_levels = empty_progress

	var packed_menu: PackedScene = load("res://scenes/ui/main_menu/main_menu.tscn") as PackedScene
	if packed_menu == null:
		failures.append("No se pudo cargar el menú principal")
		_finish(manager, original_completed)
		return

	var menu: Node = packed_menu.instantiate()
	root.add_child(menu)
	await process_frame

	var grid: GridContainer = menu.get_node_or_null("UI/LevelsGrid") as GridContainer
	if grid == null:
		failures.append("El menú no contiene la cuadrícula de niveles")
		menu.queue_free()
		await process_frame
		_finish(manager, original_completed)
		return

	var buttons: Array[Button] = []
	for child: Node in grid.get_children():
		if child is Button:
			buttons.append(child as Button)

	if buttons.size() != GameContent.LEVEL_ORDER.size():
		failures.append("La cantidad de botones no coincide con LEVEL_ORDER")
	else:
		for index: int in range(buttons.size()):
			var expected_name: String = GameContent.LEVEL_ORDER[index].name
			if expected_name not in buttons[index].tooltip_text:
				failures.append("El botón %d no respeta el orden oficial" % (index + 1))
			if buttons[index].pressed.get_connections().is_empty():
				failures.append("El botón %d no tiene navegación conectada" % (index + 1))

		if buttons[0].disabled:
			failures.append("El primer nivel debe estar disponible en una partida nueva")
		for index: int in range(1, buttons.size()):
			if not buttons[index].disabled:
				failures.append("El nivel %d debe iniciar bloqueado" % (index + 1))

		var first_level_completed: Array[String] = ["w1_l1"]
		manager.session.completed_levels = first_level_completed
		menu._refresh_ui()
		if buttons[0].disabled or buttons[1].disabled:
			failures.append("Un nivel completado y el siguiente deben poder abrirse")
		if not buttons[2].disabled:
			failures.append("Los niveles posteriores deben seguir bloqueados")
	await _completed_layout(manager, menu)

	manager.session.completed_levels.clear()
	manager.session.words_learned.clear()
	manager.session.resume_scene_key = ""
	manager.load_failed = true
	menu._refresh_ui()
	if not menu.get_node("UI/Center/VBox/ResetBtn").visible:
		failures.append("Una partida rechazada debe permitir reiniciarla desde el menú")
	manager.load_failed = false
	menu.queue_free()
	await process_frame
	_finish(manager, original_completed)


func _completed_layout(manager: Node, menu: Node) -> void:
	manager.session.completed_levels.clear()
	manager.session.resume_scene_key = ""
	for level: Dictionary in GameContent.LEVEL_ORDER:
		manager.session.completed_levels.append("w%d_l%d" % [level.world, level.level])
	menu._refresh_ui()
	var layout: Node = menu.get_node("ScreenLayout")
	for compact: bool in [false, true]:
		root.size = Vector2i(640, 360) if compact else Vector2i(1280, 720)
		layout.preview_compact = compact
		layout.refresh()
		await process_frame
		await process_frame
		var status: Label = menu.next_stop
		var play: Button = menu.play_btn
		var status_bottom: float = status.get_global_rect().end.y
		if play.get_global_rect().position.y - status_bottom < 8.0:
			failures.append("El estado completado necesita espacio sobre Jugar en ambos perfiles")
		if not play.has_focus():
			failures.append("Reordenar el menú conserva el foco en la acción principal")
		if not capture_folder.is_empty():
			await RenderingServer.frame_post_draw
			var path: String = capture_folder.path_join(
				"menu_completo_%s.png" % ("compacto" if compact else "escritorio")
			)
			var result: Error = root.get_texture().get_image().save_png(path)
			if result != OK:
				failures.append("No se pudo guardar la captura del menú completo")
	root.size = Vector2i(1280, 720)
	layout.preview_compact = false
	layout.refresh()
	await process_frame


func _finish(manager: Node, original_completed: Array[String]) -> void:
	manager.session.completed_levels = original_completed
	if failures.is_empty():
		print("Validación del menú principal: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
