extends RefCounted
class_name VillageVisitPlacement


static func meeting_point(table: Dictionary, garden: Dictionary, space: VillageSpace) -> Vector2:
	if not VillageVisitState.usable_table(table):
		return Vector2.INF
	var extent: Vector2 = GardenLayout.footprint(table.key, int(table.orientation))
	for side: float in [-1.0, 1.0]:
		var point: Vector2 = GardenLayout.point(table) + Vector2(side * (extent.x * 0.5 + 68), 0)
		var clear: bool = true
		for offset: Vector2 in [Vector2.ZERO, Vector2(-24, 0), Vector2(24, 0)]:
			clear = (clear and not VillageGround.blocked(point + offset, garden, "patio", space))
		if clear:
			return point
	return Vector2.INF
