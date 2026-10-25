extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
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


func _finish(manager: Node, original_completed: Array[String]) -> void:
	manager.session.completed_levels = original_completed
	if failures.is_empty():
		print("Validación del menú principal: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
