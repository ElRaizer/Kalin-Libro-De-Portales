extends Control
class_name MissionProgress

@export var background_style: StyleBoxFlat
@export var caption_color: Color = Color("fff6e1")
@export var complete_color: Color = Color("ffd050")
@export var pending_color: Color = Color("8ab0a0")
@export var check_color: Color = Color("174e48")
@export_range(10, 48) var caption_font_size: int = 20

## Progreso de la tarea actual, independiente de las palabras del libro.
var completed: int = 0
var total: int = 1
var caption: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_progress(value: int, count: int, title: String) -> void:
	completed = value
	total = maxi(1, count)
	caption = title
	queue_redraw()


func _draw() -> void:
	draw_style_box(background_style, Rect2(Vector2(-12, -7), Vector2(size.x + 12, 68)))
	var font: Font = get_theme_font("font", "Label")
	draw_string(
		font,
		Vector2(0, 22),
		caption,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		caption_font_size,
		caption_color
	)
	var x: float = 0.0
	for index: int in range(total):
		var color: Color = complete_color if index < completed else pending_color
		draw_circle(Vector2(x + 7, 43), 6, color, true, -1, true)
		if index < completed:
			draw_polyline(
				PackedVector2Array([Vector2(x + 3, 43), Vector2(x + 6, 46), Vector2(x + 11, 40)]),
				check_color,
				2,
				true
			)
		x += 20.0 + (12.0 if (index + 1) % 3 == 0 else 0.0)
