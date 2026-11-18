extends RefCounted
class_name VillageGround

const CELL: float = 20.0


static func obstacles_for_garden(
	garden: Dictionary, district: String, space: VillageSpace
) -> Array[Rect2]:
	var obstacles: Array[Rect2] = space.obstacles.duplicate()
	for object: Dictionary in garden.objects:
		if object.stored or object.district != district or int(object.support) != 0:
			continue
		var extent: Vector2 = (
			GardenLayout.footprint(object.key, int(object.orientation)) + Vector2(36, 30)
		)
		obstacles.append(Rect2(GardenLayout.point(object) - extent * 0.5, extent))
	return obstacles


static func blocked(
	location: Vector2,
	garden: Dictionary,
	district: String,
	space: VillageSpace,
	expanded: bool = false
) -> bool:
	return blocked_by_obstacles(
		location,
		bounds(space, expanded),
		obstacles_for_garden(garden, district, space),
		space.walk_regions(expanded)
	)


static func bounds(space: VillageSpace, expanded: bool) -> Rect2:
	var result: Rect2 = space.floor_bounds
	for region: Rect2 in space.walk_regions(expanded):
		result = result.merge(region)
	return result


static func route(
	start: Vector2,
	goal: Vector2,
	garden: Dictionary,
	district: String,
	space: VillageSpace,
	expanded: bool = false
) -> PackedVector2Array:
	return route_with_obstacles(
		start,
		goal,
		bounds(space, expanded),
		obstacles_for_garden(garden, district, space),
		space.walk_regions(expanded)
	)


static func safe_arrival(
	preferred: Vector2,
	garden: Dictionary,
	district: String,
	space: VillageSpace,
	expanded: bool = false
) -> Vector2:
	if not blocked(preferred, garden, district, space, expanded):
		return preferred
	var nearest: Vector2 = space.arrival
	var distance: float = INF
	var area: Rect2 = bounds(space, expanded)
	for y: int in range(int(area.position.y), int(area.end.y), int(CELL)):
		for x: int in range(int(area.position.x), int(area.end.x), int(CELL)):
			var candidate: Vector2 = Vector2(x, y)
			if not blocked(candidate, garden, district, space, expanded):
				var current: float = preferred.distance_squared_to(candidate)
				if current < distance:
					nearest = candidate
					distance = current
	return nearest


static func extension_accessible(garden: Dictionary, space: VillageSpace) -> bool:
	var start: Vector2 = safe_arrival(space.arrival, garden, space.id, space, true)
	for anchor: Vector2 in space.guest_anchors + [space.extension_anchor]:
		if blocked(anchor, garden, space.id, space, true):
			return false
		if route(start, anchor, garden, space.id, space, true).is_empty():
			return false
	return true


static func blocked_by_obstacles(
	location: Vector2, floor_bounds: Rect2, obstacles: Array[Rect2], regions: Array[Rect2] = []
) -> bool:
	var inside: bool = regions.is_empty() and floor_bounds.has_point(location)
	for region: Rect2 in regions:
		inside = inside or region.has_point(location)
	if not inside:
		return true
	for obstacle: Rect2 in obstacles:
		if obstacle.has_point(location):
			return true
	return false


static func route_with_obstacles(
	start: Vector2,
	goal: Vector2,
	floor_bounds: Rect2,
	obstacles: Array[Rect2],
	regions: Array[Rect2] = []
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
				Vector2i(x, y),
				blocked_by_obstacles(Vector2(x, y) * CELL, floor_bounds, obstacles, regions)
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
