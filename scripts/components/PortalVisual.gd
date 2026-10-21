extends Control
class_name PortalVisual

@export var active_page_style: StyleBoxFlat
@export var inactive_page_style: StyleBoxFlat
@export var frame_color: Color = Color("7a5228")
@export var ring_color: Color = Color("27867d")
@export var active_color: Color = Color("ffd050")
@export var inactive_color: Color = Color("b99562")

var energy := 0.0:
	set(value):
		energy = value
		queue_redraw()
var transition: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_energy(value: float) -> void:
	if transition and transition.is_valid():
		transition.kill()
	transition = create_tween()
	transition.tween_property(self, "energy", value, 0.6).set_trans(Tween.TRANS_SINE)

func _draw() -> void:
	var center := Vector2(150, 170)
	draw_circle(center, 136, frame_color, false, 14, true)
	draw_circle(center, 118, ring_color, false, 7, true)
	draw_circle(center, 106, Color(0.25, 0.82, 0.76, 0.1 + energy * 0.025), true, -1, true)
	for index: int in range(8):
		var angle := -PI / 2.0 + TAU * index / 8.0
		var at := center + Vector2(cos(angle), sin(angle)) * 136
		var active := energy >= index + 0.8
		draw_circle(at, 18, active_color if active else inactive_color, true, -1, true)
		var page := Rect2(at - Vector2(7, 10), Vector2(14, 20))
		draw_style_box(_page_style(active), page)

func _page_style(active: bool) -> StyleBoxFlat:
	return active_page_style if active else inactive_page_style
