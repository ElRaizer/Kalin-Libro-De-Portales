extends Control
class_name GardenEditor

signal changed
signal closed
signal selection_changed(id: int)
var selected_id: int = 0
var preview: Vector2 = Vector2(640, 440)
var district: String = "patio"
var placing: bool = false
var _orientation: int = 0
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _new_id: int = 0
var _new_before: Dictionary = {}
var _inventory_mode: String = "copies"
var _undo: Dictionary = {}
var _inventory: HBoxContainer
var _tools: HBoxContainer
var _hint: Label
var _preview_art: GardenObject
var _tabs: HBoxContainer
var _shelf: ScrollContainer
var _copy_word: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory = HBoxContainer.new()
	_inventory.add_theme_constant_override("separation", 12)
	var tabs: HBoxContainer = HBoxContainer.new()
	_tabs = tabs
	tabs.add_theme_constant_override("separation", 12)
	tabs.position = Vector2(20, 72)
	add_child(tabs)
	_button(tabs, "Copias gratis", _show_inventory.bind("copies"))
	_button(tabs, "Mis muebles y almacén", _show_inventory.bind("owned"))
	var scroll: ScrollContainer = ScrollContainer.new()
	_shelf = scroll
	scroll.position = Vector2(20, 130)
	scroll.size = Vector2(1240, 66)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	scroll.add_child(_inventory)
	_tools = HBoxContainer.new()
	_tools.add_theme_constant_override("separation", 10)
	_tools.position = Vector2(24, 635)
	add_child(_tools)
	_button(_tools, "Colocar", commit)
	_button(_tools, "Girar", rotate_selected)
	_button(_tools, "Encima de mesa", support_selected)
	_button(_tools, "Guardar", store_selected)
	_button(_tools, "Cancelar", cancel)
	_button(_tools, "Deshacer", undo)
	_button(
		_tools,
		"Terminar",
		func() -> void:
			cancel()
			hide()
			closed.emit()
	)
	_hint = Label.new()
	_hint.position = Vector2(24, 595)
	_hint.size = Vector2(1230, 38)
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color("164b48"))
	add_child(_hint)
	hide()


func open_editor(area: String) -> void:
	district = area
	show()
	refresh()
	_hint.text = "Elige una copia o un mueble. Flechas para mover; Enter para colocar."
	if _inventory.get_child_count() > 0:
		(_inventory.get_child(0) as Button).grab_focus()


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.theme_type_variation = &"KalinSecondaryButton"
	button.custom_minimum_size.y = 48
	if parent == _inventory:
		button.custom_minimum_size = Vector2(150, 54)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func refresh() -> void:
	_hint.text = "Elige una copia o un mueble; no cuesta puntos moverlos."
	_refresh_tools()
	for child: Node in _inventory.get_children():
		_inventory.remove_child(child)
		child.queue_free()
	var session: GameSession = GameManager.session
	var shown: Array[String] = []
	if _inventory_mode == "copies" and not _copy_word.is_empty():
		_button(_inventory, "← Objetos", _choose_copy_word.bind(""))
	for id: String in CombinationCatalog.targets():
		if _inventory_mode != "copies" or (not session.economy.built and id != "mayak|chich"):
			continue
		if MagicEconomy.can_build(session.economy, id, session.words_learned):
			var title: String = str(CombinationCatalog.targets()[id])
			var word: String = id.get_slice("|", 0)
			if _copy_word.is_empty():
				if word not in shown:
					shown.append(word)
					_button(
						_inventory,
						str(VocabularyCatalog.entry(word).spanish),
						_choose_copy_word.bind(word)
					)
			elif word == _copy_word:
				_button(_inventory, "＋ " + title, new_copy.bind(id))
	for object: Dictionary in session.garden.objects:
		if _inventory_mode != "owned":
			continue
		if object.stored or object.district == district:
			_button(
				_inventory,
				(
					("Almacén: " if object.stored else "Mover: ")
					+ str(CombinationCatalog.targets()[object.key])
				),
				select_object.bind(int(object.id))
			)
	changed.emit()


func _show_inventory(mode: String) -> void:
	cancel()
	_inventory_mode = mode
	_copy_word = ""
	refresh()


func _choose_copy_word(word: String) -> void:
	_copy_word = word
	refresh()


func new_copy(id: String) -> void:
	cancel()
	_new_before = GameManager.session.garden.duplicate(true)
	selected_id = GameManager.session.create_garden_object(id, district)
	_new_id = selected_id
	if selected_id != 0:
		select_object(selected_id)
	else:
		_hint.text = "El almacén está lleno. Reutiliza uno de tus muebles."


func select_object(id: int) -> void:
	if _new_id != 0 and id != _new_id:
		cancel()
	selected_id = id
	var object: Dictionary = GardenLayout.object_by_id(GameManager.session.garden, id)
	if object.is_empty():
		return
	preview = GardenLayout.point(object)
	_orientation = int(object.orientation)
	placing = true
	if is_instance_valid(_preview_art):
		_preview_art.queue_free()
	_preview_art = GardenObject.new()
	add_child(_preview_art)
	var table: Dictionary = GardenLayout.object_by_id(
		GameManager.session.garden, int(object.support)
	)
	_preview_art.configure(object, true, int(table.get("orientation", 0)))
	for child: Dictionary in GameManager.session.garden.objects:
		if int(child.support) == id:
			var supported: GardenObject = GardenObject.new()
			_preview_art.add_child(supported)
			supported.configure(child, false, _orientation)
			supported.position = Vector2.ZERO
			supported.z_index = 1
	_hint.text = "Toca suelo libre. Esc cancela; guardar conserva el mueble."
	_update_preview()
	_refresh_tools()
	selection_changed.emit(id)


func _refresh_tools() -> void:
	_tabs.visible = not placing
	_shelf.visible = not placing
	var object: Dictionary = GardenLayout.object_by_id(GameManager.session.garden, selected_id)
	var word: String = str(object.get("key", "")).get_slice("|", 0)
	_tools.get_child(0).visible = placing
	_tools.get_child(1).visible = placing and word in ["k'áanche'", "mayak"]
	_tools.get_child(2).visible = placing and word == "lak"
	_tools.get_child(3).visible = (
		placing and selected_id > 0 and not object.is_empty() and not object.stored
	)
	_tools.get_child(4).visible = placing
	_tools.get_child(5).visible = not placing and not _undo.is_empty()
	_tools.get_child(6).visible = not placing


func _input(event: InputEvent) -> void:
	# La colocación recibe las flechas antes de que el foco de un botón las use para navegar.
	if visible and placing and not get_tree().paused and event is InputEventKey and event.pressed:
		if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_ESCAPE]:
			_handle_key(event)
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if event is InputEventMouseMotion and _dragging:
		preview = get_global_mouse_position() + _drag_offset
		_update_preview()
		get_viewport().set_input_as_handled()
		return
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and not event.pressed
	):
		if _dragging:
			_dragging = false
			commit()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var location: Vector2 = get_global_mouse_position()
		if placing and GardenLayout.PLOT.has_point(location):
			preview = location
			_dragging = true
			_drag_offset = Vector2.ZERO
			_update_preview()
		elif location.y > 160 and location.y < 570:
			var objects: Array = GameManager.session.garden.objects.duplicate()
			objects.reverse()
			for object: Dictionary in objects:
				if (
					not object.stored
					and object.district == district
					and (
						Rect2(GardenLayout.point(object) - Vector2(80, 120), Vector2(160, 140))
						. has_point(location)
					)
				):
					select_object(int(object.id))
					_dragging = true
					_drag_offset = preview - location
					break
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed:
		_handle_key(event)


func _handle_key(event: InputEventKey) -> void:
	var delta: Vector2 = Vector2.ZERO
	match event.keycode:
		KEY_LEFT:
			delta.x = -12
		KEY_RIGHT:
			delta.x = 12
		KEY_UP:
			delta.y = -12
		KEY_DOWN:
			delta.y = 12
		KEY_ENTER:
			commit()
		KEY_ESCAPE:
			if placing:
				cancel()
			else:
				hide()
				closed.emit()
	if placing and delta != Vector2.ZERO:
		preview += delta
		_update_preview()
	if delta != Vector2.ZERO or event.keycode in [KEY_ENTER, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()


func _update_preview() -> void:
	if not is_instance_valid(_preview_art):
		return
	_preview_art.position = preview
	var valid: bool = GardenLayout.valid_position(
		GameManager.session.garden, selected_id, preview, district, _orientation
	)
	_preview_art.modulate = Color(1, 1, 1, 0.8) if valid else Color(1, 0.5, 0.4, 0.8)
	_hint.text = (
		"Enter o Colocar para confirmar."
		if valid
		else "Falta espacio: deja libres el sendero y los otros muebles."
	)


func remember() -> void:
	_undo = GameManager.session.garden.duplicate(true)


func commit() -> void:
	if not placing:
		return
	var before: Dictionary = (
		_new_before.duplicate(true)
		if selected_id == _new_id
		else GameManager.session.garden.duplicate(true)
	)
	if not GameManager.session.place_garden_object(selected_id, preview, district, _orientation):
		_hint.text = "Busca un espacio libre dentro del jardín."
		return
	_undo = before
	_new_id = 0
	_new_before.clear()
	cancel()
	refresh()


func rotate_selected() -> void:
	var object: Dictionary = GardenLayout.object_by_id(GameManager.session.garden, selected_id)
	if object.is_empty() or object.key.get_slice("|", 0) not in ["k'áanche'", "mayak"]:
		_hint.text = "Las sillas y mesas tienen vistas de giro."
		return
	_orientation = (_orientation + 1) % 4
	var drawing: Dictionary = object.duplicate(true)
	drawing.orientation = _orientation
	_preview_art.configure(drawing, true)
	for child: Node in _preview_art.get_children():
		if child is GardenObject:
			var supported: Dictionary = GardenLayout.object_by_id(
				GameManager.session.garden, child.object_id
			)
			child.configure(supported, false, _orientation)
			child.position = Vector2.ZERO
			child.z_index = 1
	_update_preview()


func support_selected() -> void:
	var tables: Array = GameManager.session.garden.objects.duplicate()
	tables.sort_custom(_nearer_table)
	for table: Dictionary in tables:
		if table.district != district:
			continue
		var before: Dictionary = GameManager.session.garden.duplicate(true)
		if GardenLayout.put_on_table(GameManager.session.garden, selected_id, int(table.id)):
			_undo = _new_before.duplicate(true) if _new_id != 0 else before
			_new_id = 0
			_new_before.clear()
			cancel()
			refresh()
			return
	_hint.text = "Elige un plato y coloca primero una mesa con superficie libre."


func _nearer_table(a: Dictionary, b: Dictionary) -> bool:
	return GardenLayout.point(a).distance_to(preview) < GardenLayout.point(b).distance_to(preview)


func store_selected() -> void:
	remember()
	if GardenLayout.store_object(GameManager.session.garden, selected_id):
		cancel()
		refresh()


func cancel() -> void:
	placing = false
	_dragging = false
	if _new_id != 0 and not _new_before.is_empty():
		GameManager.session.garden = _new_before.duplicate(true)
		_new_id = 0
		_new_before.clear()
		selected_id = 0
	if is_instance_valid(_preview_art):
		_preview_art.queue_free()
	_preview_art = null
	_refresh_tools()
	selection_changed.emit(0)


func undo() -> void:
	if _undo.is_empty():
		return
	cancel()
	GameManager.session.garden = _undo.duplicate(true)
	_undo.clear()
	refresh()
