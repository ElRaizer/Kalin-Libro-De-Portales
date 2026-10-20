extends CanvasLayer
class_name LearningGuide

## Demostración sobre el juego real. Nunca consume los clics del jugador.
const HAND = preload("res://Arte/ilustraciones/ui_mano.svg")
const PAGE = preload("res://Arte/exploracion/prop_pagina.svg")
var hand: TextureRect
var gesture: Tween
var help_button: Button
var _point_target: Control
var _time := 0.0

static func install(host: Node, bar: Container, help_action: Callable) -> LearningGuide:
	var guide := LearningGuide.new()
	host.add_child(guide)
	guide.help_button = Button.new()
	guide.help_button.name = "HelpButton"
	guide.help_button.text = "? Ayuda"
	guide.help_button.custom_minimum_size = Vector2(106, 40)
	guide.help_button.theme_type_variation = &"KalinSecondaryButton"
	guide.help_button.tooltip_text = "Ver cómo se juega"
	guide.help_button.pressed.connect(help_action)
	bar.add_child(guide.help_button)
	bar.move_child(guide.help_button, maxi(1, bar.get_child_count() - 2))
	return guide

func _ready() -> void:
	layer = 6
	hand = TextureRect.new()
	hand.texture = HAND
	hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hand.size = Vector2(49, 58)
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand.visible = false
	add_child(hand)
	set_process(false)

func demonstrate(points: Array[Vector2]) -> void:
	stop()
	if points.is_empty():
		return
	hand.visible = true
	hand.position = points[0] - Vector2(22, 5)
	gesture = create_tween().set_loops()
	gesture.tween_property(hand, "modulate:a", 1.0, 0.15).from(0.0)
	gesture.tween_interval(0.35)
	for index: int in range(1, points.size()):
		gesture.tween_property(hand, "position", points[index] - Vector2(22, 5), 0.65).set_trans(Tween.TRANS_SINE)
	gesture.tween_interval(0.6)
	gesture.tween_property(hand, "modulate:a", 0.0, 0.2)
	gesture.tween_property(hand, "position", points[0] - Vector2(22, 5), 0.01)

func point_at(control: Control) -> void:
	stop()
	_point_target = control
	hand.show()
	hand.modulate.a = 0.95
	set_process(true)
	_process(0)

func _process(delta: float) -> void:
	if not is_instance_valid(_point_target) or not _point_target.is_visible_in_tree():
		stop()
		return
	_time += delta
	hand.position = _point_target.get_global_rect().get_center() - Vector2(22, 5) + Vector2(0, sin(_time * 4) * 6)

func stop() -> void:
	_point_target = null
	set_process(false)
	if gesture and gesture.is_valid():
		gesture.kill()
	if is_instance_valid(hand):
		hand.hide()
	for child: Node in get_children():
		if child != hand:
			child.queue_free()

func page_to_book(origin: Vector2, target: Vector2) -> void:
	var page := TextureRect.new()
	page.texture = PAGE
	page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page.size = Vector2(78, 60)
	page.position = origin - page.size * 0.5
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	var tween := page.create_tween()
	tween.tween_property(page, "position", page.position + Vector2(0, -55), 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(page, "position", target - Vector2(20, 15), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(page, "scale", Vector2(0.4, 0.4), 0.65)
	tween.parallel().tween_property(page, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.tween_callback(page.queue_free)
