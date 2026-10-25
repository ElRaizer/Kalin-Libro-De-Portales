extends CanvasLayer
class_name LearningGuide

## Demostración sobre el juego real. Nunca consume los clics del jugador.
@export var page_scene: PackedScene
@onready var hand: TextureRect = $Hand
enum Gesture { NONE, CLICK, DRAG, HIGHLIGHT }
const FINGER_TIP := Vector2(22, 5)
const CLICK_CYCLE := 1.45
const DRAG_PRESS := 0.4
var gesture_mode: LearningGuide.Gesture = Gesture.NONE
var help_button: Button
var _point_target: Control
var _world_target: Node2D
var _world_point: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _continue_target: Control
var _idle_seconds: float = 0.0
var _idle_delay: float = 4.0
var _hint_target: Control
var _action_target: Control
var _drag_source: Control
var _drag_target: Control
var _drag_space: CanvasItem
var _drag_local_points: Array[Vector2] = []
var _gesture_points: Array[Vector2] = []
var _hand_scale: Vector2 = Vector2.ONE
@onready var _hint_ring: Panel = $HintRing
@onready var _gesture_line: Line2D = $GestureLine
@onready var _click_pulse: Panel = $ClickPulse
@onready var _hand_alpha: float = $Hand.modulate.a
@onready var _ring_alpha: float = $HintRing.modulate.a


static func install(host: Node, bar: Container, help_action: Callable) -> LearningGuide:
	var guide: LearningGuide = host.get_node("LearningGuide") as LearningGuide
	guide.help_button = bar.get_node("HelpButton") as Button
	guide.help_button.pressed.connect(help_action)
	return guide


func _ready() -> void:
	_hand_scale = hand.scale
	hand.pivot_offset = FINGER_TIP
	set_process(false)


## Clic: el dedo permanece sobre el objetivo y pulsa sin recorrer una trayectoria.
func click_at(control: Control) -> void:
	stop()
	_point_target = control
	_start_click()


func click_world(target: Node2D, local_point: Vector2 = Vector2.ZERO) -> void:
	stop()
	_world_target = target
	_world_point = local_point
	_start_click()


## Compatibilidad con las ayudas de botones, personajes y Continuar.
func point_at(control: Control) -> void:
	click_at(control)


func _start_click() -> void:
	gesture_mode = Gesture.CLICK
	hand.show()
	hand.modulate.a = _hand_alpha * 0.95
	set_process(true)
	_process(0)


## Arrastre entre controles: seguir sus transformaciones evita señalar posiciones viejas.
func drag_between(source: Control, destination: Control) -> void:
	stop()
	_drag_source = source
	_drag_target = destination
	_start_drag()


## Arrastre en un tablero, con puntos locales y codos que siguen las casillas.
func drag_path(space: CanvasItem, points: Array[Vector2]) -> void:
	stop()
	if points.size() < 2:
		return
	_drag_space = space
	_drag_local_points = points.duplicate()
	_start_drag()


func _start_drag() -> void:
	gesture_mode = Gesture.DRAG
	hand.show()
	set_process(true)
	_process(0)


static func screen_center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)


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
	gesture_mode = Gesture.HIGHLIGHT
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
		_click_pulse.hide()


func _process(delta: float) -> void:
	if gesture_mode == Gesture.DRAG:
		_process_drag(delta)
		return
	if is_instance_valid(_action_target):
		_idle_seconds += delta
		if _idle_seconds >= _idle_delay:
			var target: Control = _action_target
			highlight(target)
		return
	if is_instance_valid(_hint_target) and is_instance_valid(_hint_ring):
		if not _hint_target.is_visible_in_tree():
			stop()
			return
		_time += delta
		var rect: Rect2 = (
			(
				_hint_target.get_global_transform_with_canvas()
				* Rect2(Vector2.ZERO, _hint_target.size)
			)
			. grow(5)
		)
		_hint_ring.position = rect.position
		_hint_ring.size = rect.size
		_hint_ring.modulate.a = _ring_alpha * (0.6 + 0.4 * sin(_time * 3.0))
		return
	if is_instance_valid(_continue_target):
		if (
			not _continue_target.is_visible_in_tree()
			or (_continue_target is BaseButton and _continue_target.disabled)
		):
			stop()
			return
		_idle_seconds += delta
		if _idle_seconds >= _idle_delay:
			_point_target = _continue_target
			gesture_mode = Gesture.CLICK
			hand.show()
			hand.modulate.a = _hand_alpha * 0.95
	if not is_instance_valid(_point_target) and not is_instance_valid(_world_target):
		if not is_instance_valid(_continue_target):
			stop()
		return
	var point: Vector2
	if is_instance_valid(_world_target):
		if not _world_target.is_visible_in_tree():
			stop()
			return
		point = _world_target.get_global_transform_with_canvas() * _world_point
	else:
		if (
			not _point_target.is_visible_in_tree()
			or (_point_target is BaseButton and _point_target.disabled)
		):
			stop()
			return
		point = screen_center(_point_target)
	if not get_viewport().get_visible_rect().has_point(point):
		hand.hide()
		_click_pulse.hide()
		return
	hand.show()
	_time += delta
	hand.position = point - FINGER_TIP
	var phase: float = fposmod(_time, CLICK_CYCLE)
	var reduced: bool = get_node("/root/AccessibilityManager").reduced_motion
	var press: float = sin(clampf(phase / 0.4, 0.0, 1.0) * PI)
	hand.scale = _hand_scale * (1.0 if reduced else 1.0 - 0.14 * press)
	_click_pulse.position = point - _click_pulse.size * 0.5
	_click_pulse.scale = Vector2.ONE * (1.0 if reduced else 0.7 + phase * 1.3)
	_click_pulse.modulate.a = 0.65 if reduced else maxf(0, 1.0 - phase / 0.6)
	_click_pulse.visible = reduced or phase < 0.6


func _process_drag(delta: float) -> void:
	_gesture_points.clear()
	if is_instance_valid(_drag_source) and is_instance_valid(_drag_target):
		if (
			not _drag_source.is_visible_in_tree()
			or not _drag_target.is_visible_in_tree()
			or (_drag_source is BaseButton and _drag_source.disabled)
		):
			stop()
			return
		_gesture_points.assign([screen_center(_drag_source), screen_center(_drag_target)])
	elif is_instance_valid(_drag_space):
		if not _drag_space.is_visible_in_tree():
			stop()
			return
		for point: Vector2 in _drag_local_points:
			_gesture_points.append(_drag_space.get_global_transform_with_canvas() * point)
	else:
		stop()
		return
	_gesture_line.points = PackedVector2Array(_gesture_points)
	_gesture_line.show()
	var length: float = 0.0
	for index: int in range(1, _gesture_points.size()):
		length += _gesture_points[index - 1].distance_to(_gesture_points[index])
	var seconds: float = clampf(length / 360.0, 0.65, 2.5)
	_time += delta
	var phase: float = fposmod(_time, DRAG_PRESS + seconds + 0.8)
	var ratio: float = clampf((phase - DRAG_PRESS) / seconds, 0.0, 1.0)
	var remaining: float = ratio * length
	var point: Vector2 = _gesture_points.back()
	for index: int in range(1, _gesture_points.size()):
		var distance: float = _gesture_points[index - 1].distance_to(_gesture_points[index])
		if remaining <= distance:
			point = _gesture_points[index - 1].lerp(
				_gesture_points[index], remaining / maxf(distance, 0.001)
			)
			break
		remaining -= distance
	hand.position = point - FINGER_TIP
	var reduced: bool = get_node("/root/AccessibilityManager").reduced_motion
	hand.scale = _hand_scale * (0.9 if not reduced and phase < DRAG_PRESS + seconds else 1.0)
	hand.modulate.a = _hand_alpha * clampf((DRAG_PRESS + seconds + 0.6 - phase) / 0.2, 0.0, 1.0)


func stop() -> void:
	gesture_mode = Gesture.NONE
	_world_target = null
	_drag_source = null
	_drag_target = null
	_drag_space = null
	_drag_local_points.clear()
	_gesture_points.clear()
	_time = 0.0
	_click_pulse.hide()
	hand.scale = _hand_scale
	_hint_target = null
	_hint_ring.hide()
	_gesture_line.hide()
	_action_target = null
	_point_target = null
	_continue_target = null
	_idle_seconds = 0.0
	set_process(false)
	if is_instance_valid(hand):
		hand.hide()
	for child: Node in $Effects.get_children():
		child.queue_free()


func page_to_book(origin: Vector2, target: Vector2) -> void:
	var page: TextureRect = page_scene.instantiate() as TextureRect
	page.position = origin - page.size * 0.5
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Effects.add_child(page)
	var tween: Tween = page.create_tween()
	tween.tween_property(page, "position", page.position + Vector2(0, -55), 0.3).set_trans(
		Tween.TRANS_SINE
	)
	(
		tween
		. tween_property(page, "position", target - Vector2(20, 15), 0.65)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN_OUT)
	)
	tween.parallel().tween_property(page, "scale", page.scale * 0.4, 0.65)
	tween.parallel().tween_property(page, "modulate:a", 0.0, 0.3).set_delay(0.35)
	tween.tween_callback(page.queue_free)
