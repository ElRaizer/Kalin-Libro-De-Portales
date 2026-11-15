extends Node2D
class_name KalinWalker

var _upper: Sprite2D
var _left: Sprite2D
var _right: Sprite2D
var _phase: float = 0.0
var _body: Node2D
var _depth_base: Vector2 = Vector2.ONE
var _depth_configured: bool = false
var _carrying: bool = false
const STEP_LENGTH: float = 52.0
const HOP_HEIGHT: float = 12.0
const FRONT: Texture2D = preload("res://Arte/sprites/kalin_walk_upper.svg")
const BACK: Texture2D = preload("res://Arte/sprites/kalin_walk_back.svg")
const CARRY: Texture2D = preload("res://Arte/sprites/kalin_carry_upper.svg")


func _ready() -> void:
	_body = Node2D.new()
	add_child(_body)
	_left = _part(preload("res://Arte/sprites/kalin_walk_left.svg"), Vector2(-10, -10))
	_right = _part(preload("res://Arte/sprites/kalin_walk_right.svg"), Vector2(10, -10))
	_upper = _part(FRONT, Vector2(0, -74))
	queue_redraw()


func _part(texture: Texture2D, offset: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.position = offset
	sprite.scale = Vector2.ONE * 0.5
	_body.add_child(sprite)
	return sprite


func step(velocity: Vector2, delta: float, reduced: bool) -> void:
	if not is_instance_valid(_upper):
		return
	var moving: bool = velocity.length() > 0.1
	if moving:
		_phase += velocity.length() * delta / STEP_LENGTH * PI
		_upper.texture = (
			CARRY if _carrying else (BACK if velocity.y < -absf(velocity.x) * 0.7 else FRONT)
		)
		if absf(velocity.x) > 1:
			_upper.flip_h = velocity.x < 0
	var stride: float = sin(_phase) if moving and not reduced else 0.0
	# El recorte completo salta; el origen del suelo y su sombra permanecen estables.
	_body.position.y = -absf(stride) * HOP_HEIGHT
	_body.rotation = stride * 0.025
	_left.position = Vector2(-10, -10)
	_right.position = Vector2(10, -10)
	z_index = int(position.y)


func set_carrying(enabled: bool) -> void:
	_carrying = enabled
	_upper.texture = CARRY if enabled else FRONT


func carry_anchor() -> Vector2:
	var side: float = -1.0 if _upper.flip_h else 1.0
	return _upper.to_global(Vector2(80 * side, -10))


func _draw() -> void:
	draw_ellipse_shape()


func apply_depth(floor_y: float, floor_range: Vector2) -> void:
	if not _depth_configured:
		_depth_base = scale
		_depth_configured = true
	var depth: float = clampf(inverse_lerp(floor_range.x, floor_range.y, floor_y), 0.0, 1.0)
	scale = _depth_base * lerpf(0.84, 1.08, depth)


func head_position() -> Vector2:
	var top: Vector2 = (
		_upper.position - Vector2(0, _upper.texture.get_height() * _upper.scale.y / 2)
	)
	return _body.to_global(top)


func draw_ellipse_shape() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, 25, Color(0.1, 0.2, 0.12, 0.2))
	draw_set_transform(Vector2.ZERO)
