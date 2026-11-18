extends Node2D
class_name VillageVisitPresentation

signal ended

var session: GameSession
var actor: Sprite2D
var motion: VillageUseMotion
var suspended: bool = false
var _route: PackedVector2Array = PackedVector2Array()
var _arrival_elapsed: float = 0.0
var _entering: bool = false
var _table: GardenObject
const ARRIVAL_SECONDS: float = 2.5
const DEPARTURE_SECONDS: float = 2.0


func present(table: GardenObject, home: Vector2, scale_at_home: Vector2, entering: bool) -> bool:
	clear()
	var visit: Dictionary = session.village_visit
	var object: Dictionary = GardenLayout.object_by_id(session.garden, int(visit.object_id))
	var destination: Vector2 = VillageVisitPlacement.meeting_point(
		object, session.garden, GameContent.VILLAGE_SPACES.space("patio")
	)
	if not destination.is_finite():
		return false
	_route = VillageGround.route(
		home, destination, session.garden, "patio", GameContent.VILLAGE_SPACES.space("patio")
	)
	if _route.is_empty():
		return false
	_route.insert(0, home)
	_route.append(destination)
	_table = table
	z_index = table.z_index + 2
	actor = Sprite2D.new()
	actor.texture = VillageUseArt.ACTORS[visit.animal]
	actor.scale = scale_at_home
	add_child(actor)
	motion = VillageUseMotion.attach(
		actor, table.art, "mayak", visit.animal, to_global(destination)
	)
	# Esta vista muestrea la actuación; sólo la sesión conserva el reloj de la visita.
	motion.set_process(false)
	_entering = entering
	_arrival_elapsed = 0
	_sample(0)
	return true


func clear() -> void:
	if is_instance_valid(motion):
		motion.get_parent().remove_child(motion)
		motion.queue_free()
	motion = null
	if is_instance_valid(actor):
		remove_child(actor)
		actor.queue_free()
	actor = null
	_table = null
	_route.clear()


func active() -> bool:
	return is_instance_valid(actor) and not session.village_visit.is_empty()


func ground_point() -> Vector2:
	if not active():
		return Vector2.INF
	return actor.position + _foot_offset()


func _process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	if session.village_visit.is_empty():
		clear()
		ended.emit()
		return
	if suspended:
		return
	if not is_instance_valid(_table) or session.advance_village_visit(delta):
		session.end_village_visit()
		clear()
		ended.emit()
		return
	_arrival_elapsed += delta
	_sample(_arrival_elapsed)


func _sample(elapsed: float) -> void:
	var remaining: float = float(session.village_visit.remaining)
	var reduced: bool = AccessibilityManager.reduced_motion
	motion.sample_action(0.2 if _entering and elapsed < 0.5 else 4.0)
	var progress: float = 1.0
	if _entering and elapsed < ARRIVAL_SECONDS and not reduced:
		progress = smoothstep(0.5, ARRIVAL_SECONDS, elapsed)
	elif remaining < DEPARTURE_SECONDS:
		progress = 0.0 if reduced else smoothstep(0.0, DEPARTURE_SECONDS, remaining)
	actor.position = _route_point(progress) - _foot_offset()
	z_index = int(ground_point().y) + 2
	if progress > 0 and progress < 1 and not reduced:
		actor.rotation = sin(elapsed * 8) * 0.025


func _foot_offset() -> Vector2:
	return (
		(
			(actor.get_rect().position + actor.texture.get_size() * Vector2(0.5, motion.foot_y))
			* actor.scale
		)
		. rotated(actor.rotation)
	)


func _route_point(progress: float) -> Vector2:
	var length: float = 0.0
	for index: int in range(1, _route.size()):
		length += _route[index - 1].distance_to(_route[index])
	var distance: float = length * progress
	for index: int in range(1, _route.size()):
		var segment: float = _route[index - 1].distance_to(_route[index])
		if distance <= segment:
			return _route[index - 1].lerp(_route[index], distance / maxf(segment, 0.001))
		distance -= segment
	return _route[-1]
