extends Control
class_name MissionProgress

## Progreso de la tarea actual, independiente de las palabras del libro.
var completed := 0
var total := 1
var caption := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_progress(value: int, count: int, title: String) -> void:
	completed = value
	total = maxi(1, count)
	caption = title
	queue_redraw()

func _draw() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("173f3a")
	background.set_corner_radius_all(12)
	draw_style_box(background, Rect2(Vector2(-12, -7), Vector2(size.x + 12, 68)))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 22), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff6e1"))
	var x := 0.0
	for index: int in range(total):
		var color := Color("ffd050") if index < completed else Color("8ab0a0")
		draw_circle(Vector2(x + 7, 43), 6, color, true, -1, true)
		if index < completed:
			draw_polyline(PackedVector2Array([Vector2(x + 3, 43), Vector2(x + 6, 46), Vector2(x + 11, 40)]), Color("174e48"), 2, true)
		x += 20.0 + (12.0 if (index + 1) % 3 == 0 else 0.0)

