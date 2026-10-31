extends RefCounted
class_name VillageGround

const FLOOR: Rect2 = Rect2(42, 325, 1190, 260)
const CELL: float = 20.0


static func obstacles_for_garden(garden: Dictionary, district: String) -> Array[Rect2]:
	var obstacles: Array[Rect2] = []
	if district == "shore":
		obstacles.append(Rect2(940, 295, 280, 160))
	for object: Dictionary in garden.objects:
		if object.stored or object.district != district or int(object.support) != 0:
			continue
		var extent: Vector2 = (
			GardenLayout.footprint(object.key, int(object.orientation)) + Vector2(36, 30)
		)
		obstacles.append(Rect2(GardenLayout.point(object) - extent * 0.5, extent))
	return obstacles


static func blocked(location: Vector2, garden: Dictionary, district: String) -> bool:
	return blocked_by_obstacles(location, FLOOR, obstacles_for_garden(garden, district))


static func route(
	start: Vector2, goal: Vector2, garden: Dictionary, district: String
) -> PackedVector2Array:
	return route_with_obstacles(start, goal, FLOOR, obstacles_for_garden(garden, district))


static func blocked_by_obstacles(
	location: Vector2, floor_bounds: Rect2, obstacles: Array[Rect2]
) -> bool:
	if not floor_bounds.has_point(location):
		return true
	for obstacle: Rect2 in obstacles:
		if obstacle.has_point(location):
			return true
	return false


static func route_with_obstacles(
	start: Vector2, goal: Vector2, floor_bounds: Rect2, obstacles: Array[Rect2]
) -> PackedVector2Array:
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(
		Vector2i((floor_bounds.position / CELL).floor()),
		Vector2i((floor_bounds.size / CELL).ceil()) + Vector2i.ONE
	)
	grid.cell_size = Vector2.ONE * CELL
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y: int in range(grid.region.position.y, grid.region.end.y):
		for x: int in range(grid.region.position.x, grid.region.end.x):
			grid.set_point_solid(
				Vector2i(x, y), blocked_by_obstacles(Vector2(x, y) * CELL, floor_bounds, obstacles)
			)
	var source: Vector2i = Vector2i((start / CELL).round())
	var destination: Vector2i = Vector2i((goal / CELL).round())
	if (
		not grid.region.has_point(source)
		or not grid.region.has_point(destination)
		or grid.is_point_solid(destination)
	):
		return PackedVector2Array()
	grid.set_point_solid(source, false)
	return grid.get_point_path(source, destination)
