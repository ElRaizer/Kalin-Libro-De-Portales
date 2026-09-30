class_name DraggableWordButton
extends Button

## Botón de palabra que conserva el clic normal y añade arrastre nativo.
## Ambas propiedades son editables desde el inspector.
@export var word_value: String = ""
@export_enum("noun", "adjective", "food", "modifier") var word_kind: String = "noun"

var _hover_tween: Tween
var _mouse_mode_before_drag: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _owns_hidden_cursor: bool = false
var _active_press_style: StyleBoxFlat
var _is_drag_source: bool = false

func _ready() -> void:
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	resized.connect(_refresh_pivot)
	_active_press_style = _create_active_press_style()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled:
		return null
	_is_drag_source = true
	button_pressed = true
	var preview := Label.new()
	preview.text = text
	preview.custom_minimum_size = size
	preview.size = size
	# El origen de la previsualización es el cursor; este desplazamiento hace
	# que la palabra quede agarrada exactamente desde su centro.
	preview.position = -size * 0.5
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	preview.add_theme_color_override("font_color", Color.WHITE)
	var card := StyleBoxFlat.new()
	card.bg_color = Color("d69b2b")
	card.border_color = Color("fff0a8")
	card.set_border_width_all(3)
	card.set_corner_radius_all(12)
	card.shadow_color = Color(0.08, 0.04, 0.01, 0.35)
	card.shadow_size = 8
	preview.add_theme_stylebox_override("normal", card)
	preview.modulate.a = 0.94
	set_drag_preview(preview)
	_mouse_mode_before_drag = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_owns_hidden_cursor = true
	_punch(Vector2(0.92, 0.92), Vector2.ONE)
	return {"kind": StringName(word_kind), "value": word_value, "source": self}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Godot envía esta notificación a todos los controles. Solo el botón que
		# originó el arrastre debe cambiar su estado visual.
		if not _is_drag_source:
			return
		_restore_cursor()
		_clear_active_press_style()
		# Un drop válido ya actualizó la selección del mundo. Conservamos su
		# estado presionado para que tenga el mismo feedback amarillo que el clic.
		# Si se soltó fuera de un destino, revertimos la marca temporal del arrastre.
		if not get_viewport().gui_is_drag_successful():
			button_pressed = false
		_punch(Vector2(1.08, 1.08), Vector2.ONE)
		_is_drag_source = false

func _exit_tree() -> void:
	# Evita dejar el cursor oculto si se cambia de escena durante un arrastre.
	_restore_cursor()

func _restore_cursor() -> void:
	if not _owns_hidden_cursor:
		return
	Input.mouse_mode = _mouse_mode_before_drag
	_owns_hidden_cursor = false

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _on_mouse_entered() -> void:
	if not disabled and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_animate_scale(Vector2(1.045, 1.045), 0.1)

func _on_mouse_exited() -> void:
	_animate_scale(Vector2.ONE, 0.12)

func _on_button_down() -> void:
	# Marrón de la interfaz durante la presión física. Este estado es temporal
	# y se diferencia del dorado persistente que representa una selección.
	add_theme_stylebox_override("pressed", _active_press_style)
	add_theme_color_override("font_pressed_color", Color("fff4d2"))

func _on_button_up() -> void:
	_clear_active_press_style()

func _clear_active_press_style() -> void:
	remove_theme_stylebox_override("pressed")
	remove_theme_color_override("font_pressed_color")

func _create_active_press_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("7a4f1c")
	style.border_color = Color("e7a928")
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	style.shadow_color = Color(0.08, 0.04, 0.01, 0.24)
	style.shadow_size = 3
	return style

func _animate_scale(target: Vector2, duration: float) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target, duration)

func _punch(from_scale: Vector2, target: Vector2) -> void:
	scale = from_scale
	_animate_scale(target, 0.18)
