class_name WordDropSlot
extends Label

signal word_dropped(value: String)

@export_enum("noun", "adjective", "food", "modifier") var accepted_kind: String = "noun"
var _base_modulate := Color.WHITE
var _slot_tween: Tween
var _compatible_drag_active: bool = false
var _valid_hover: bool = false
var _border_phase: float = 0.0

const BORDER_SPEED := 72.0
const DOT_SPACING := 14.0
const DOT_RADIUS := 2.6
const NOUN_COLOR := Color("176b67")
const ADJECTIVE_COLOR := Color("704c9f")

func _ready() -> void:
	_initialize()

func _initialize() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size * 0.5
	if not resized.is_connected(_refresh_pivot):
		resized.connect(_refresh_pivot)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var accepted: bool = false
	if data is Dictionary:
		accepted = StringName(data.get("kind", &"")) == StringName(accepted_kind)
	return accepted

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_reset_visual()
	word_dropped.emit(str(data.get("value", "")))

func pop() -> void:
	if _slot_tween and _slot_tween.is_valid():
		_slot_tween.kill()
	scale = Vector2(0.9, 0.9)
	modulate = Color(1.15, 1.12, 0.82, 1.0)
	_slot_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_slot_tween.tween_property(self, "scale", Vector2.ONE, 0.24)
	_slot_tween.tween_property(self, "modulate", _base_modulate, 0.3)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var data: Variant = get_viewport().gui_get_drag_data()
		_compatible_drag_active = data is Dictionary and StringName(data.get("kind", &"")) == StringName(accepted_kind)
		set_process(_compatible_drag_active)
		queue_redraw()
	elif what == NOTIFICATION_DRAG_END:
		_compatible_drag_active = false
		_set_valid_hover(false)
		set_process(false)
		_reset_visual()
		queue_redraw()

func _process(delta: float) -> void:
	if not _compatible_drag_active:
		return
	_border_phase = fmod(_border_phase + BORDER_SPEED * delta, DOT_SPACING)
	# Comprobar la posición en cada frame garantiza que el resaltado desaparezca
	# incluso cuando Godot deja de llamar a _can_drop_data al salir del Control.
	var cursor_inside := get_global_rect().has_point(get_viewport().get_mouse_position())
	_set_valid_hover(cursor_inside)
	queue_redraw()

func _draw() -> void:
	if not _compatible_drag_active:
		return
	var inset := DOT_RADIUS + 1.0
	var border_size := size - Vector2.ONE * inset * 2.0
	if border_size.x <= 0.0 or border_size.y <= 0.0:
		return
	var perimeter := 2.0 * (border_size.x + border_size.y)
	var dot_count := maxi(1, int(perimeter / DOT_SPACING))
	var color := _category_color()
	for index: int in range(dot_count):
		var distance := fmod(float(index) * DOT_SPACING + _border_phase, perimeter)
		var point := _point_on_border(distance, border_size) + Vector2.ONE * inset
		draw_circle(point, DOT_RADIUS, color, true, -1.0, true)

func _point_on_border(distance: float, border_size: Vector2) -> Vector2:
	if distance < border_size.x:
		return Vector2(distance, 0.0)
	distance -= border_size.x
	if distance < border_size.y:
		return Vector2(border_size.x, distance)
	distance -= border_size.y
	if distance < border_size.x:
		return Vector2(border_size.x - distance, border_size.y)
	distance -= border_size.x
	return Vector2(0.0, border_size.y - distance)

func _category_color() -> Color:
	return NOUN_COLOR if accepted_kind == "noun" or accepted_kind == "food" else ADJECTIVE_COLOR

func _set_valid_hover(value: bool) -> void:
	if _valid_hover == value:
		return
	_valid_hover = value
	if value:
		_glow()
	else:
		_reset_visual()

func _refresh_pivot() -> void:
	pivot_offset = size * 0.5

func _glow() -> void:
	if scale.x > 1.03:
		return
	if _slot_tween and _slot_tween.is_valid():
		_slot_tween.kill()
	_slot_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	_slot_tween.tween_property(self, "scale", Vector2(1.055, 1.055), 0.1)
	_slot_tween.tween_property(self, "modulate", Color(1.18, 1.13, 0.72, 1.0), 0.1)

func _reset_visual() -> void:
	if _slot_tween and _slot_tween.is_valid():
		_slot_tween.kill()
	_slot_tween = create_tween().set_parallel(true)
	_slot_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	_slot_tween.tween_property(self, "modulate", _base_modulate, 0.1)
