extends HFlowContainer
class_name SpellingField

signal changed
signal submitted
signal focused
signal navigation_requested
signal advance_requested(field: LineEdit)
signal backspace_requested(field: LineEdit)
var correction: SpellingCorrection = SpellingCorrection.new()
var _active: LineEdit
var _style_source: LineEdit
var _compact: bool = false


func configure_style(source: LineEdit) -> void:
	_style_source = source


func apply_compact(enabled: bool) -> void:
	_compact = enabled
	for child: Control in get_children():
		child.custom_minimum_size.y = 56 if enabled else 48


func render() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	add_theme_constant_override("h_separation", 3)
	add_theme_constant_override("v_separation", 6)
	for index: int in range(correction.positions.size()):
		if correction.positions[index] < 0:
			if correction.letters[index].is_empty():
				continue
			var remove: Button = Button.new()
			remove.theme_type_variation = &"KalinSecondaryButton"
			remove.text = correction.letters[index] + " ×"
			remove.tooltip_text = "Quitar esta letra sobrante"
			remove.custom_minimum_size = Vector2(46, 56 if _compact else 48)
			remove.pressed.connect(_remove.bind(index))
			add_child(remove)
		elif correction.locked[index]:
			var label: Label = Label.new()
			label.text = correction.letters[index]
			label.custom_minimum_size.y = 56 if _compact else 48
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 26)
			if is_instance_valid(_style_source):
				label.add_theme_color_override(
					"font_color", _style_source.get_theme_color("font_color")
				)
			add_child(label)
		else:
			var field: LineEdit = LineEdit.new()
			field.custom_minimum_size = Vector2(46, 56 if _compact else 48)
			field.max_length = 1
			field.add_theme_constant_override("minimum_character_width", 1)
			field.alignment = HORIZONTAL_ALIGNMENT_CENTER
			field.placeholder_text = "_"
			field.text = correction.letters[index]
			field.add_theme_font_size_override("font_size", 26)
			if is_instance_valid(_style_source):
				for style: String in ["normal", "focus", "read_only"]:
					field.add_theme_stylebox_override(
						style, _style_source.get_theme_stylebox(style)
					)
				for color: String in ["font_color", "font_placeholder_color", "caret_color"]:
					field.add_theme_color_override(color, _style_source.get_theme_color(color))
			field.text_changed.connect(_edited.bind(index))
			field.gui_input.connect(_edit_input.bind(field))
			field.text_submitted.connect(func(_text: String) -> void: submitted.emit())
			field.focus_entered.connect(
				func() -> void:
					_active = field
					focused.emit()
			)
			add_child(field)


func _edited(text: String, index: int) -> void:
	correction.letters[index] = text
	changed.emit()
	if not text.is_empty() and is_instance_valid(_active):
		advance_requested.emit(_active)


func _edit_input(event: InputEvent, field: LineEdit) -> void:
	if event.is_action_pressed("ui_text_backspace") and field.text.is_empty():
		field.accept_event()
		backspace_requested.emit(field)


func _remove(index: int) -> void:
	correction.letters[index] = ""
	changed.emit()
	render()
	navigation_requested.emit()


func focus_pending() -> bool:
	if not is_inside_tree() or not is_visible_in_tree() or is_queued_for_deletion():
		return false
	for child: Node in get_children():
		if (
			child is LineEdit
			and child.text.is_empty()
			and child.is_inside_tree()
			and not child.is_queued_for_deletion()
		):
			(child as LineEdit).grab_focus()
			return true
	for child: Node in get_children():
		if child is Button and child.is_inside_tree() and not child.is_queued_for_deletion():
			(child as Button).grab_focus()
			return true
	return false


func insert_symbol(letter: String) -> void:
	if not is_instance_valid(_active) or not is_ancestor_of(_active):
		focus_pending()
	if is_instance_valid(_active) and is_ancestor_of(_active):
		_active.text = letter
		_active.grab_focus()
		_active.text_changed.emit(letter)
