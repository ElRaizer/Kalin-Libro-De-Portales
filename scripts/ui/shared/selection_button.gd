extends Button
class_name SelectionButton

## Distingue la presión física del dorado que conserva una selección.
@export var active_press_style: StyleBoxFlat = preload("res://themes/active_press.tres")
var _active_press_style: StyleBoxFlat
var _press_override_active: bool = false
var _saved_pressed_style: StyleBox
var _saved_hover_pressed_style: StyleBox
var _saved_pressed_color: Color
var _had_pressed_color: bool = false


func _ready() -> void:
	_active_press_style = active_press_style
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_down() -> void:
	# Marrón de la interfaz durante la presión física. Este estado es temporal
	# y se diferencia del dorado persistente que representa una selección.
	if not _press_override_active:
		_saved_pressed_style = (
			get_theme_stylebox("pressed") if has_theme_stylebox_override("pressed") else null
		)
		_saved_hover_pressed_style = (
			get_theme_stylebox("hover_pressed")
			if has_theme_stylebox_override("hover_pressed")
			else null
		)
		_had_pressed_color = has_theme_color_override("font_pressed_color")
		_saved_pressed_color = get_theme_color("font_pressed_color")
		_press_override_active = true
	add_theme_stylebox_override("pressed", _active_press_style)
	add_theme_stylebox_override("hover_pressed", _active_press_style)
	add_theme_color_override("font_pressed_color", Color("fff4d2"))


func _on_button_up() -> void:
	_clear_active_press_style()


func _clear_active_press_style() -> void:
	if not _press_override_active:
		return
	if _saved_pressed_style:
		add_theme_stylebox_override("pressed", _saved_pressed_style)
	else:
		remove_theme_stylebox_override("pressed")
	if _saved_hover_pressed_style:
		add_theme_stylebox_override("hover_pressed", _saved_hover_pressed_style)
	else:
		remove_theme_stylebox_override("hover_pressed")
	if _had_pressed_color:
		add_theme_color_override("font_pressed_color", _saved_pressed_color)
	else:
		remove_theme_color_override("font_pressed_color")
	_press_override_active = false
