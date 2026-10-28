extends HBoxContainer
class_name WordChipSelector

signal item_selected(index: int)
var selected: int = -1
var item_count: int:
	get:
		return _buttons.size()
var _buttons: Array[Button] = []
var _metadata: Array[String] = []


func clear() -> void:
	for button: Button in _buttons:
		remove_child(button)
		button.queue_free()
	_buttons.clear()
	_metadata.clear()
	selected = -1


func add_item(text: String) -> void:
	var button: Button = Button.new()
	button.text = text
	button.toggle_mode = true
	button.theme_type_variation = &"KalinSecondaryButton"
	button.add_theme_font_size_override("font_size", 22)
	button.custom_minimum_size = Vector2(130, 52)
	var index: int = _buttons.size()
	button.pressed.connect(
		func() -> void:
			select(index)
			item_selected.emit(index)
	)
	add_child(button)
	_buttons.append(button)
	_metadata.append("")
	if selected < 0:
		select(0)


func select(index: int) -> void:
	if index < 0 or index >= item_count:
		return
	selected = index
	for position: int in range(item_count):
		_buttons[position].set_pressed_no_signal(position == index)


func set_item_metadata(index: int, value: String) -> void:
	_metadata[index] = value


func get_item_metadata(index: int) -> String:
	return _metadata[index] if index >= 0 and index < item_count else ""


func set_item_icon(index: int, texture: Texture2D) -> void:
	if index >= 0 and index < item_count:
		_buttons[index].icon = texture
		_buttons[index].expand_icon = true
		_buttons[index].custom_minimum_size.x = 240
		_buttons[index].add_theme_constant_override("icon_max_width", 44)


func focus_selected() -> void:
	if selected >= 0:
		_buttons[selected].grab_focus()
