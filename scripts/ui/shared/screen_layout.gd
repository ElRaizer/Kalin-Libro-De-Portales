extends Node
class_name ScreenLayout

@export var profile: ScreenLayoutProfile
@export var compact_width: int = 1024
@export var preview_compact: bool = false
var compact: bool = false
var _captured: bool = false
var _rectangles: Dictionary = {}
var _fonts: Dictionary = {}
var _minimums: Dictionary = {}
var _hidden: Dictionary = {}
var _keyboard_panel: Control
var _keyboard_home: Vector2 = Vector2.ZERO
var _keyboard_field: LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size_changed.connect(refresh)
	$Keyboard/Dock/Submit.pressed.connect(_submit_keyboard)
	$Keyboard/Dock/Hide.pressed.connect(_hide_keyboard)
	call_deferred("_capture")


static func is_compact(window: Window, width_limit: int = 1024) -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	return (
		window.size.x <= width_limit
		or OS.has_feature("mobile")
		or DisplayServer.is_touchscreen_available()
	)


func _capture() -> void:
	var host: Node = get_parent()
	if profile != null:
		for path: NodePath in profile.rectangles:
			var control: Control = host.get_node_or_null(path) as Control
			if control:
				var authored: Rect2 = Rect2(
					control.position,
					(
						control.preferred_size
						if control is RecallPanel and control.preferred_size != Vector2.ZERO
						else control.size
					)
				)
				_rectangles[control] = control.get_meta("practice_rect", authored)
		for path: NodePath in profile.hidden:
			var control: CanvasItem = host.get_node_or_null(path) as CanvasItem
			if control:
				_hidden[control] = control.visible
	for control: Node in host.find_children("*", "Control", true, false):
		if _inside_book(control):
			continue
		if control is Label or control is Button or control is LineEdit:
			_fonts[control] = {
				"size": control.get_theme_font_size("font_size"),
				"override": control.has_theme_font_size_override("font_size")
			}
		elif control is RichTextLabel:
			_fonts[control] = {
				"size": control.get_theme_font_size("normal_font_size"),
				"override": control.has_theme_font_size_override("normal_font_size")
			}
		if control is Button:
			_minimums[control] = control.custom_minimum_size
	_captured = true
	refresh()


func _inside_book(node: Node) -> bool:
	var ancestor: Node = node.get_parent()
	while ancestor != null and ancestor != get_parent():
		if ancestor.name == &"LibroHechizos":
			return true
		if ancestor.name == &"GridBoard" or ancestor.name == &"Bank":
			return true
		ancestor = ancestor.get_parent()
	return false


func refresh() -> void:
	if not _captured:
		return
	compact = preview_compact or is_compact(get_window(), compact_width)
	var host: Node = get_parent()
	# Las casillas de respuesta se recrean entre rondas. El perfil sólo puede
	# conservar referencias a controles que aún pertenecen a esta escena.
	for cache: Dictionary in [_rectangles, _fonts, _minimums, _hidden]:
		for control: Variant in cache.keys():
			if not is_instance_valid(control) or not host.is_ancestor_of(control):
				cache.erase(control)
	for control: Control in _rectangles:
		var rect: Rect2 = (
			profile.rectangles[host.get_path_to(control)] if compact else _rectangles[control]
		)
		control.position = rect.position
		control.size = rect.size
		if control.has_meta("practice_rect"):
			control.set_meta("practice_rect", rect)
		if control is RecallPanel:
			control.set_meta("layout_size", rect.size)
	for control: CanvasItem in _hidden:
		control.visible = false if compact else _hidden[control]
	for control: Control in _fonts:
		var data: Dictionary = _fonts[control]
		var property: String = "normal_font_size" if control is RichTextLabel else "font_size"
		if compact:
			control.add_theme_font_size_override(
				property, maxi(int(data.size), profile.minimum_body_font if profile != null else 26)
			)
		elif data.override:
			control.add_theme_font_size_override(property, int(data.size))
		else:
			control.remove_theme_font_size_override(property)
	for button: Button in _minimums:
		var original: Vector2 = _minimums[button]
		button.custom_minimum_size = (
			Vector2(original.x, maxf(original.y, 56)) if compact else original
		)
	if compact and profile != null:
		for path: NodePath in profile.font_sizes:
			var control: Control = host.get_node_or_null(path) as Control
			if control:
				control.add_theme_font_size_override("font_size", int(profile.font_sizes[path]))
	for panel: Node in host.find_children("*", "", true, false):
		if panel is RecallPanel:
			panel.apply_compact(compact)
	if host.has_method("apply_screen_layout"):
		host.apply_screen_layout(compact)
	# Aplicar la transformación de fase sobre la base del perfil actual.
	# El controlador del ejercicio solicita la fase y no introduce coordenadas.
	for control: Control in _rectangles:
		if control.has_meta("recall_panel"):
			ExerciseRecallFlow.expand_for_recall(
				control,
				control.get_meta("recall_spell"),
				control.get_meta("recall_panel"),
				bool(control.get_meta("recall_expanded", false))
			)


func _process(_delta: float) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	var height: int = DisplayServer.virtual_keyboard_get_height()
	var focused: LineEdit = get_viewport().gui_get_focus_owner() as LineEdit
	_dock_keyboard(focused, height)


func _dock_keyboard(focused: LineEdit, height: int) -> void:
	if (
		height <= 0
		or focused == null
		or not focused.is_visible_in_tree()
		or not get_parent().is_ancestor_of(focused)
	):
		_restore_keyboard()
		return
	if _keyboard_field != focused:
		_restore_keyboard()
		_keyboard_field = focused
		var parent: Node = focused.get_parent()
		while parent != null and parent != get_parent():
			if parent is RecallPanel:
				_keyboard_panel = parent
				_keyboard_home = _keyboard_panel.position
				break
			parent = parent.get_parent()
	var logical_keyboard: float = float(height) * 720.0 / maxf(get_window().size.y, 1)
	var top: float = 720.0 - logical_keyboard - 80.0
	$Keyboard/Dock.position.y = maxf(76, top)
	$Keyboard/Dock/Submit.text = (
		"Siguiente campo"
		if (
			_keyboard_panel != null
			and (_keyboard_panel as RecallPanel).second_box.visible
			and focused == (_keyboard_panel as RecallPanel).first
		)
		else "Confirmar"
	)
	$Keyboard/Dock.show()
	if _keyboard_panel != null:
		var bottom: float = focused.get_global_rect().end.y
		_keyboard_panel.position.y -= maxf(0, bottom - top + 12)


func _restore_keyboard() -> void:
	$Keyboard/Dock.hide()
	if is_instance_valid(_keyboard_panel):
		_keyboard_panel.position = _keyboard_home
	_keyboard_panel = null
	_keyboard_field = null


func _submit_keyboard() -> void:
	if is_instance_valid(_keyboard_panel):
		var panel: RecallPanel = _keyboard_panel as RecallPanel
		if _keyboard_field == panel.first and panel.second_box.visible:
			panel.second.grab_focus()
			return
		panel.submitted.emit()
	_hide_keyboard()


func _hide_keyboard() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	_restore_keyboard()
