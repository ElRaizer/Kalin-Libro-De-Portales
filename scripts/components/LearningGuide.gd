extends CanvasLayer
class_name LearningGuide

## Demostración sobre el juego real. Nunca consume los clics del jugador.
@export var page_scene: PackedScene
@onready var hand: TextureRect = $Hand
var gesture: Tween
var help_button: Button
var _point_target: Control
var _time := 0.0
var _continue_target: Control
var _idle_seconds := 0.0
var _idle_delay := 4.0
var _hint_target: Control
@onready var _hint_ring: Panel = $HintRing
@onready var _gesture_line: Line2D = $GestureLine
var _action_target: Control
@onready var _hand_alpha: float = $Hand.modulate.a
@onready var _ring_alpha: float = $HintRing.modulate.a

static func install(host: Node, bar: Container, help_action: Callable) -> LearningGuide:
	var guide := host.get_node("LearningGuide") as LearningGuide
	guide.help_button = bar.get_node("HelpButton") as Button
	guide.help_button.pressed.connect(help_action)
	return guide

func _ready() -> void:
	set_process(false)

func demonstrate(points: Array[Vector2]) -> void:
	stop()
	if points.is_empty():
		return
	hand.visible = true
	# Una línea discontinua acompaña el gesto; nunca modifica la respuesta real.
	if points.size() > 1:
		_gesture_line.points = PackedVector2Array(points)
		_gesture_line.show()
	hand.position = points[0] - Vector2(22, 5)
	gesture = create_tween().set_loops()
	gesture.tween_property(hand, "modulate:a", _hand_alpha, 0.15).from(0.0)
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
	hand.modulate.a = _hand_alpha * 0.95
	set_process(true)
	_process(0)

## El aviso espera al jugador y respeta la pausa del libro.
func watch_continue(control: Control, delay: float = 4.0) -> void:
	stop()
	_continue_target = control
	_idle_delay = delay
	set_process(true)

## Ayuda de operación: rodea un grupo o un hueco, sin señalar la respuesta.
func highlight(control: Control) -> void:
	stop()
	_hint_target = control
	_hint_ring.show()
	set_process(true)
	_process(0)

func watch_action(control: Control, delay: float = 8.0) -> void:
	stop()
	_action_target = control
	_idle_delay = delay
	set_process(true)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_continue_target) and not is_instance_valid(_action_target):
		return
	var interacted: bool = (
		(event is InputEventMouseMotion and event.relative.length() > 2.0)
		or (event is InputEventMouseButton and event.pressed)
		or (event is InputEventKey and event.pressed and not event.echo)
		or (event is InputEventScreenTouch and event.pressed)
		or event is InputEventScreenDrag
	)
	if interacted:
		_idle_seconds = 0.0
		_point_target = null
		hand.hide()

func _process(delta: float) -> void:
	if is_instance_valid(_action_target):
		_idle_seconds += delta
		if _idle_seconds >= _idle_delay:
			var target := _action_target
			highlight(target)
		return
	if is_instance_valid(_hint_target) and is_instance_valid(_hint_ring):
		if not _hint_target.is_visible_in_tree():
			stop()
			return
		_time += delta
		var rect := _hint_target.get_global_rect().grow(5)
		_hint_ring.position = rect.position
		_hint_ring.size = rect.size
		_hint_ring.modulate.a = _ring_alpha * (0.6 + 0.4 * sin(_time * 3.0))
		return
	if is_instance_valid(_continue_target):
		if not _continue_target.is_visible_in_tree() or (_continue_target is BaseButton and _continue_target.disabled):
			stop()
			return
		_idle_seconds += delta
		if _idle_seconds >= _idle_delay:
			_point_target = _continue_target
			hand.show()
			hand.modulate.a = _hand_alpha * 0.95
	if not is_instance_valid(_point_target):
		if not is_instance_valid(_continue_target):
			stop()
		return
	if not _point_target.is_visible_in_tree():
		stop()
		return
	_time += delta
	hand.position = _point_target.get_global_rect().get_center() - Vector2(22, 5) + Vector2(0, sin(_time * 4) * 6)

func stop() -> void:
	_hint_target = null
	_hint_ring.hide()
	_gesture_line.hide()
	_action_target = null
	_point_target = null
	_continue_target = null
	_idle_seconds = 0.0
	set_process(false)
	if gesture and gesture.is_valid():
		gesture.kill()
	if is_instance_valid(hand):
		hand.hide()
	for child: Node in $Effects.get_children():
		child.queue_free()

func page_to_book(origin: Vector2, target: Vector2) -> void:
	var page := page_scene.instantiate() as TextureRect
	page.position = origin - page.size * 0.5
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Effects.add_child(page)
	var tween := page.create_tween()
	tween.tween_property(page, "position", page.position + Vector2(0, -55), 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(page, "position", target - Vector2(20, 15), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(page, "scale", page.scale * 0.4, 0.65)
	tween.parallel().tween_property(page, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.tween_callback(page.queue_free)
