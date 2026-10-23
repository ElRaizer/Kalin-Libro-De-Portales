extends Node

## Mantiene separado el foco de teclado del puntero. Los botones de Godot
## reciben foco al hacer clic; lo liberamos al usar el ratón para que el borde
## amarillo represente únicamente la navegación por teclado.

var _mouse_focused_control: Control
var _saved_focus_style: StyleBox
@export var empty_focus_style: StyleBoxEmpty
signal preferences_changed
const PREFERENCES_PATH := "user://kalin_preferences.cfg"
var reduced_motion := false
var reduced_flashes := false
var instant_text := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var config := ConfigFile.new()
	if config.load(PREFERENCES_PATH) != OK:
		return
	for key: String in ["reduced_motion", "reduced_flashes", "instant_text"]:
		set(key, config.get_value("comfort", key, false) == true)

func set_preference(key: String, enabled: bool) -> void:
	if key not in ["reduced_motion", "reduced_flashes", "instant_text"]:
		return
	set(key, enabled)
	var config := ConfigFile.new()
	for name: String in ["reduced_motion", "reduced_flashes", "instant_text"]:
		config.set_value("comfort", name, get(name))
	var error := config.save(PREFERENCES_PATH)
	if error != OK:
		push_warning("No se pudieron guardar las preferencias de lectura (error %d)." % error)
	get_tree().call_group("comfort_visuals", "apply_comfort_settings")
	preferences_changed.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		call_deferred(&"_hide_keyboard_visuals")
		return

	if event is InputEventKey and event.pressed and not event.echo and _is_navigation_event(event):
		_show_keyboard_visuals()
		# La navegación de Godot cambia el foco después de `_input`; una segunda
		# actualización muestra el borde en el nuevo control.
		call_deferred(&"_show_keyboard_visuals")

func _is_navigation_event(event: InputEventKey) -> bool:
	return (
		event.is_action_pressed(&"ui_left")
		or event.is_action_pressed(&"ui_right")
		or event.is_action_pressed(&"ui_up")
		or event.is_action_pressed(&"ui_down")
		or event.is_action_pressed(&"ui_focus_next")
		or event.is_action_pressed(&"ui_focus_prev")
		or event.is_action_pressed(&"ui_accept")
	)

func _hide_keyboard_visuals() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused):
		if _mouse_focused_control != focused:
			_restore_focus_style()
			_mouse_focused_control = focused
			_saved_focus_style = focused.get_theme_stylebox(&"focus") if focused.has_theme_stylebox_override(&"focus") else null
		focused.add_theme_stylebox_override(&"focus", empty_focus_style)
	get_tree().call_group(&"keyboard_focus_visual", &"set_keyboard_visual_visible", false)

func _show_keyboard_visuals() -> void:
	_restore_focus_style()
	get_tree().call_group(&"keyboard_focus_visual", &"set_keyboard_visual_visible", true)

func _restore_focus_style() -> void:
	if is_instance_valid(_mouse_focused_control):
		if _saved_focus_style:
			_mouse_focused_control.add_theme_stylebox_override(&"focus", _saved_focus_style)
		else:
			_mouse_focused_control.remove_theme_stylebox_override(&"focus")
	_mouse_focused_control = null
	_saved_focus_style = null
