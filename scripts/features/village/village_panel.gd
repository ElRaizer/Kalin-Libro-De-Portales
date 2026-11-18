extends CanvasLayer
class_name VillagePanel

signal changed
signal layout_changed

var controls: Control
var body: VBoxContainer
var content: VBoxContainer
var footer: HBoxContainer
var notice: Label
var heading: Label
var close_button: Button
var blocking_layer: CanvasLayer
var _origin: WeakRef
var _was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 13
	var shade: ColorRect = ColorRect.new()
	controls = shade
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.04, 0.13, 0.13, 0.87)
	shade.theme = preload("res://themes/kalin_theme.tres")
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	var bounds: Rect2 = _panel_bounds()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.theme_type_variation = &"KalinCreamPanel"
	shade.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	heading = add_label(content, "")
	heading.add_theme_font_size_override("font_size", 30)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	content.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	notice = add_label(content, "")
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	content.add_child(footer)
	close_button = add_button(footer, "Volver al jardín", close_panel)
	_build_content()
	hide()


func _panel_bounds() -> Rect2:
	return Rect2(60, 24, 1160, 672)


func _build_content() -> void:
	pass


func add_label(parent: Control, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = &"KalinActivityLabel"
	parent.add_child(label)
	return label


func add_button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = &"KalinSecondaryButton"
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func open_panel(origin: Control) -> bool:
	if visible or get_tree().paused:
		return false
	_origin = weakref(origin) if is_instance_valid(origin) else null
	_was_paused = get_tree().paused
	get_tree().paused = true
	show()
	layout_changed.emit()
	refresh_focus()
	close_button.grab_focus()
	return true


func refresh_focus() -> void:
	var focusable: Array[Control] = []
	for control: Node in controls.find_children("*", "Control", true, false):
		if not control.is_visible_in_tree():
			continue
		if control is Button and not control.disabled:
			focusable.append(control)
		elif control is LineEdit and control.editable:
			focusable.append(control)
	for index: int in range(focusable.size()):
		focusable[index].focus_next = focusable[index].get_path_to(
			focusable[(index + 1) % focusable.size()]
		)
		focusable[index].focus_previous = focusable[index].get_path_to(
			focusable[posmod(index - 1, focusable.size())]
		)


func close_panel() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = _was_paused
	var origin: Control = _origin.get_ref() as Control if _origin != null else null
	if is_instance_valid(origin) and origin.is_visible_in_tree():
		origin.grab_focus()
	_origin = null


func _input(event: InputEvent) -> void:
	if is_instance_valid(blocking_layer) and blocking_layer.visible:
		return
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible:
		controls.process_mode = (
			Node.PROCESS_MODE_DISABLED
			if is_instance_valid(blocking_layer) and blocking_layer.visible
			else Node.PROCESS_MODE_ALWAYS
		)


func _exit_tree() -> void:
	if visible:
		get_tree().paused = _was_paused
