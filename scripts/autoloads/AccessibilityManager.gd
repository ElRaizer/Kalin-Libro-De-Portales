extends Node

## Mantiene separado el foco de teclado del puntero. Los botones de Godot
## reciben foco al hacer clic; lo liberamos al usar el ratón para que el borde
## amarillo represente únicamente la navegación por teclado.

var _mouse_focused_control: Control
var _empty_focus_style := StyleBoxEmpty.new()

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
		if is_instance_valid(_mouse_focused_control) and _mouse_focused_control != focused:
			_mouse_focused_control.remove_theme_stylebox_override(&"focus")
		_mouse_focused_control = focused
		focused.add_theme_stylebox_override(&"focus", _empty_focus_style)
	get_tree().call_group(&"keyboard_focus_visual", &"set_keyboard_visual_visible", false)

func _show_keyboard_visuals() -> void:
	if is_instance_valid(_mouse_focused_control):
		_mouse_focused_control.remove_theme_stylebox_override(&"focus")
	_mouse_focused_control = null
	var focused := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused):
		focused.remove_theme_stylebox_override(&"focus")
	get_tree().call_group(&"keyboard_focus_visual", &"set_keyboard_visual_visible", true)
