extends VillagePanel
class_name PathPracticePanel

signal completed
signal book_requested(origin: Control)
var activity: PathPracticeState = PathPracticeState.new()
var _grid: GridContainer
var _cells: Dictionary[Vector2i, Button] = {}
var _finish: Button
var _book: Button
var _help: Button
var _reset: Button


func _build_content() -> void:
	heading.text = "Un camino para venir a la merienda"
	close_button.text = "Salir y guardar"
	add_label(
		body,
		"Desde el animal hasta la estrella: toca casillas vecinas o mueve el foco con flechas y pulsa Enter. Las rocas no dejan pasar."
	)
	var center: CenterContainer = CenterContainer.new()
	body.add_child(center)
	_grid = GridContainer.new()
	_grid.columns = 12
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	center.add_child(_grid)
	for y: int in range(7):
		for x: int in range(12):
			var cell: Vector2i = Vector2i(x, y)
			var button: Button = add_button(_grid, "", press_cell.bind(cell))
			button.custom_minimum_size = Vector2(44, 44)
			button.focus_entered.connect(func() -> void: activity.cursor = cell)
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 34)
			_cells[cell] = button
	for cell: Vector2i in _cells:
		var button: Button = _cells[cell]
		button.focus_neighbor_left = button.get_path_to(
			_cells[Vector2i(maxi(0, cell.x - 1), cell.y)]
		)
		button.focus_neighbor_right = button.get_path_to(
			_cells[Vector2i(mini(11, cell.x + 1), cell.y)]
		)
		button.focus_neighbor_top = button.get_path_to(
			_cells[Vector2i(cell.x, maxi(0, cell.y - 1))]
		)
		button.focus_neighbor_bottom = button.get_path_to(
			_cells[Vector2i(cell.x, mini(6, cell.y + 1))]
		)
	var tools: HBoxContainer = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 12)
	tools.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(tools)
	_help = add_button(tools, "Mostrar apoyo", show_hint)
	_reset = add_button(tools, "Borrar camino", restart)
	_finish = add_button(footer, "Continuar", finish_practice)
	_book = add_button(footer, "Libro", func() -> void: book_requested.emit(_book))


func open_practice(origin: Control) -> void:
	if activity.variant.is_empty():
		activity.prepare(GameManager.learned_words(), randi_range(1, 2000000000))
	if activity.variant.is_empty():
		return
	refresh()
	if open_panel(origin) and activity.controller.connected.is_empty():
		_cells[activity.cursor].grab_focus()
		body.get_parent().call_deferred("ensure_control_visible", _grid)


func restore(state: Dictionary) -> void:
	activity.restore(state, GameManager.learned_words())


func refresh() -> void:
	var controller: GridPathController = activity.controller
	var done: bool = not controller.connected.is_empty()
	var source: Dictionary = PathPracticeState.layout(activity.variant)
	var hint: Array[Vector2i] = []
	if activity.supported:
		hint = GridReplayLayouts.cells(source.solution[0])
	for cell: Vector2i in _cells:
		var button: Button = _cells[cell]
		var blocked: bool = (
			controller.grid_state[cell.y][cell.x] == GridPathController.Cell.OBSTACLE
		)
		button.disabled = blocked or done
		button.text = (
			"×"
			if blocked
			else ("•" if cell in controller.paths[0] else ("○" if cell in hint else ""))
		)
		button.icon = null
		button.tooltip_text = "Roca" if blocked else "Casilla %d, %d" % [cell.x + 1, cell.y + 1]
		if cell == controller.words[0].start_cell:
			button.text = ""
			button.icon = VillageUseArt.ACTORS[activity.animal]
			button.tooltip_text = activity.animal + " · salida"
		elif cell == controller.words[0].destination_cell:
			button.text = "★"
			button.tooltip_text = "Lugar de la merienda"
		elif cell in controller.paths[0]:
			button.tooltip_text += " · camino trazado"
		elif cell in hint:
			button.tooltip_text += " · ruta de apoyo"
		button.accessibility_name = button.tooltip_text
	_finish.visible = done
	_help.disabled = done
	_reset.text = "Volver a trazar" if done else "Borrar camino"
	if done:
		notice.text = activity.animal + " ya puede venir a la merienda."
	elif activity.supported:
		notice.text = "Los círculos marcan la ruta de apoyo."
	else:
		notice.text = "Puedes pedir ayuda y volver a trazar cuando quieras."
	layout_changed.emit()
	refresh_focus()


func press_cell(cell: Vector2i) -> void:
	activity.press(cell)
	refresh()
	changed.emit()
	if not activity.controller.connected.is_empty():
		_finish.grab_focus()
	elif _cells.has(cell) and not _cells[cell].disabled:
		_cells[cell].grab_focus()


func show_hint() -> void:
	activity.supported = true
	refresh()
	changed.emit()


func restart() -> void:
	activity.controller.start(0)
	refresh()
	changed.emit()


func finish_practice() -> void:
	if not visible or activity.controller.connected.is_empty():
		return
	close_panel()
	completed.emit()


func close_panel() -> void:
	if not visible:
		return
	super.close_panel()
	changed.emit()
