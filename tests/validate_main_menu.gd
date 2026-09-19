extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var manager: Node = root.get_node("GameManager")
	var original_completed: Array[String] = manager.completed_levels.duplicate()
	var empty_progress: Array[String] = []
	manager.completed_levels = empty_progress

	var packed_menu := load("res://scenes/MainMenu.tscn") as PackedScene
	if packed_menu == null:
		failures.append("No se pudo cargar el menú principal")
		_finish(manager, original_completed)
		return

	var menu := packed_menu.instantiate()
	root.add_child(menu)
	await process_frame

	var grid := menu.get_node_or_null("UI/LevelsGrid") as GridContainer
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

	if buttons.size() != manager.LEVEL_ORDER.size():
		failures.append("La cantidad de botones no coincide con LEVEL_ORDER")
	else:
		for index: int in range(buttons.size()):
			var expected_name: String = manager.LEVEL_ORDER[index].name
			if expected_name not in buttons[index].text:
				failures.append("El botón %d no respeta el orden oficial" % (index + 1))
			if buttons[index].pressed.get_connections().is_empty():
				failures.append("El botón %d no tiene navegación conectada" % (index + 1))

		if buttons[0].disabled:
			failures.append("El primer nivel debe estar disponible en una partida nueva")
		for index: int in range(1, buttons.size()):
			if not buttons[index].disabled:
				failures.append("El nivel %d debe iniciar bloqueado" % (index + 1))

		var first_level_completed: Array[String] = ["w1_l1"]
		manager.completed_levels = first_level_completed
		menu._refresh_ui()
		if buttons[0].disabled or buttons[1].disabled:
			failures.append("Un nivel completado y el siguiente deben poder abrirse")
		if not buttons[2].disabled:
			failures.append("Los niveles posteriores deben seguir bloqueados")

	menu.queue_free()
	await process_frame
	_finish(manager, original_completed)

func _finish(manager: Node, original_completed: Array[String]) -> void:
	manager.completed_levels = original_completed
	if failures.is_empty():
		print("Validación del menú principal: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
