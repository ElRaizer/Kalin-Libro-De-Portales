extends RefCounted
class_name ExplorationRoaming

## Entrada, marcha y destino de un suelo con profundidad. La escena aporta sus obstáculos.
var walker: KalinWalker
var body: Node2D
var destination: Vector2 = Vector2.ZERO
var route: PackedVector2Array = PackedVector2Array()
var bounds: Rect2
var speed: float = 300.0


func configure(target: Node2D, original: Sprite2D, floor_bounds: Rect2, walk_speed: float) -> void:
	body = target
	bounds = floor_bounds
	speed = walk_speed
	walker = KalinWalker.new()
	walker.scale = original.scale * 2.0
	body.add_child(walker)
	original.hide()
	body.z_index = int(body.position.y)


func target(location: Vector2, obstacles: Array[Rect2]) -> void:
	destination = Vector2(
		clampf(location.x, bounds.position.x + 1, bounds.end.x - 11),
		clampf(location.y, bounds.position.y + 1, bounds.end.y - 11)
	)
	route = VillageGround.route_with_obstacles(body.position, destination, bounds, obstacles)


func step(
	horizontal: float, delta: float, enabled: bool, reduced: bool, obstacles: Array[Rect2]
) -> bool:
	if not enabled:
		walker.step(Vector2.ZERO, delta, reduced)
		return false
	var vertical: float = (
		float(Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S))
		- float(Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W))
	)
	var direction: Vector2 = Vector2(horizontal, vertical)
	if direction != Vector2.ZERO:
		route.clear()
	elif not route.is_empty():
		if body.position.distance_to(route[0]) < 6:
			route.remove_at(0)
			if route.is_empty():
				walker.step(Vector2.ZERO, delta, reduced)
				return true
		if not route.is_empty():
			direction = body.position.direction_to(route[0])
	var velocity: Vector2 = direction.normalized() * speed
	var next: Vector2 = body.position + velocity * delta
	if VillageGround.blocked_by_obstacles(next, bounds, obstacles):
		velocity = Vector2.ZERO
	else:
		body.position = next
	body.z_index = int(body.position.y)
	walker.step(velocity, delta, reduced)
	return false


func snapshot() -> Dictionary:
	return {"x": destination.x, "y": destination.y} if not route.is_empty() else {}


func restore(state: Dictionary, obstacles: Array[Rect2]) -> void:
	if SaveSchema.is_number(state.get("x")) and SaveSchema.is_number(state.get("y")):
		target(Vector2(float(state.x), float(state.y)), obstacles)


func ensure_safe(obstacles: Array[Rect2]) -> void:
	if not VillageGround.blocked_by_obstacles(body.position, bounds, obstacles):
		return
	for offset: Vector2 in [Vector2(0, 60), Vector2(0, -60), Vector2(-140, 0), Vector2(140, 0)]:
		var location: Vector2 = body.position + offset
		if not VillageGround.blocked_by_obstacles(location, bounds, obstacles):
			body.position = location
			body.z_index = int(location.y)
			if not route.is_empty():
				target(destination, obstacles)
			return
	body.position = bounds.position + Vector2(10, bounds.size.y - 10)
	body.z_index = int(body.position.y)


func face(x: float) -> void:
	walker.step(Vector2(x - body.position.x, 0), 0, true)
