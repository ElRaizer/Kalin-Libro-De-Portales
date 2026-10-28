extends Node2D
class_name KalinWalker

var _upper: Sprite2D
var _left: Sprite2D
var _right: Sprite2D
var _phase: float = 0.0
var _body: Node2D
const STEP_LENGTH: float = 52.0
const HOP_HEIGHT: float = 12.0
const FRONT: Texture2D = preload("res://Arte/sprites/kalin_walk_upper.svg")
const BACK: Texture2D = preload("res://Arte/sprites/kalin_walk_back.svg")


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
		_upper.texture = BACK if velocity.y < -absf(velocity.x) * 0.7 else FRONT
		if absf(velocity.x) > 1:
			_upper.flip_h = velocity.x < 0
	var stride: float = sin(_phase) if moving and not reduced else 0.0
	# El recorte completo salta; el origen del suelo y su sombra permanecen estables.
	_body.position.y = -absf(stride) * HOP_HEIGHT
	_body.rotation = stride * 0.025
	_left.position = Vector2(-10, -10)
	_right.position = Vector2(10, -10)
	z_index = int(position.y)


func _draw() -> void:
	draw_ellipse_shape()


func draw_ellipse_shape() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, 25, Color(0.1, 0.2, 0.12, 0.2))
	draw_set_transform(Vector2.ZERO)
