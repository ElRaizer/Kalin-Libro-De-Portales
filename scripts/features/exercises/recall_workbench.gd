extends Control

## Representa lo escrito, sin conocer respuestas, aciertos ni vocabulario esperado.
var panel: RecallPanel
var kind: String = ""


func _ready() -> void:
	$First.pressed.connect(func(): panel.first.grab_focus())
	$Second.pressed.connect(func(): panel.second.grab_focus())
	resized.connect(queue_redraw)


func refresh() -> void:
	if panel == null:
		return
	$First.text = panel.first.text if not panel.first.text.is_empty() else "…"
	$Second.text = panel.second.text if not panel.second.text.is_empty() else "…"
	$Second.visible = panel.second_box.visible
	$First.anchor_left = 0.06 if $Second.visible else 0.23
	$First.anchor_right = 0.47 if $Second.visible else 0.77
	$Prefix.text = "In k'a'at" if kind == "comida" else "Tu hechizo"
	$First.tooltip_text = (
		"Volver a editar el alimento" if kind == "comida" else "Volver a editar el objeto"
	)
	$Second.tooltip_text = "Volver a editar cómo es"
	queue_redraw()


func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var edge: Rect2 = Rect2(8, size.y - 52, size.x - 16, 26)
	draw_style_box(_wood(), edge)
	for fraction: float in [0.14, 0.86]:
		draw_line(
			Vector2(size.x * fraction, size.y - 30),
			Vector2(size.x * fraction, size.y - 6),
			Color("88613b"),
			12,
			true
		)
	var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.43)
	draw_arc(center, minf(75, size.y * 0.42), PI * 1.05, TAU * 0.98, 40, Color("d9c799"), 2, true)
	for index: int in range(5):
		var angle: float = PI * 1.13 + index * 0.53
		var point: Vector2 = center + Vector2(cos(angle), sin(angle)) * minf(77, size.y * 0.43)
		draw_circle(point, 3, Color("c5ad70"))


func _wood() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("c7975b")
	style.border_color = Color("a17645")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style
