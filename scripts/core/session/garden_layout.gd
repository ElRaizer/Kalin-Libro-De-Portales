extends RefCounted
class_name GardenLayout

const MAX_OBJECTS: int = 80


static func empty_state() -> Dictionary:
	return {"next_id": 1, "objects": []}


static func object_by_id(state: Dictionary, id: int) -> Dictionary:
	for object: Dictionary in state.objects:
		if int(object.id) == id:
			return object
	return {}


static func point(object: Dictionary) -> Vector2:
	return Vector2(float(object.x), float(object.y))


static func footprint(key: String, orientation: int = 0) -> Vector2:
	var word: String = key.get_slice("|", 0)
	if word == "mayak" and orientation % 2 == 1:
		return Vector2(100, 64)
	return Vector2(160, 44) if word in ["mayak", "k'áan"] else Vector2(72, 32)


static func valid_position(
	state: Dictionary,
	id: int,
	location: Vector2,
	district: String,
	space: VillageSpace,
	expanded: bool,
	orientation: int = -1
) -> bool:
	var object: Dictionary = object_by_id(state, id)
	if space == null or object.is_empty() or not location.is_finite():
		return false
	var extent: Vector2 = footprint(
		object.key, int(object.orientation) if orientation < 0 else orientation
	)
	var bounds: Rect2 = Rect2(location - extent * 0.5, extent)
	for obstacle: Rect2 in space.obstacles:
		if bounds.intersects(obstacle):
			return false
	var enclosed: bool = false
	for plot: Rect2 in space.plots(expanded):
		enclosed = enclosed or plot.encloses(bounds)
	if not enclosed:
		return false
	if expanded and space.extension_plot.has_point(location):
		for anchor: Vector2 in space.guest_anchors + [space.extension_anchor]:
			if bounds.intersects(Rect2(anchor - space.use_clearance * 0.5, space.use_clearance)):
				return false
	for other: Dictionary in state.objects:
		if (
			int(other.id) == id
			or other.stored
			or other.district != district
			or int(other.support) != 0
		):
			continue
		var other_extent: Vector2 = footprint(other.key, int(other.orientation))
		if Rect2(point(other) - other_extent * 0.5, other_extent).intersects(
			Rect2(location - extent * 0.5, extent)
		):
			return false
	return true


static func add_object(state: Dictionary, key: String, district: String) -> int:
	if (
		not CombinationCatalog.allowed(key)
		or state.objects.size() >= MAX_OBJECTS
		or int(state.next_id) >= 1000000
	):
		return 0
	var id: int = int(state.next_id)
	state.next_id = id + 1
	state.objects.append(
		{
			"id": id,
			"key": key,
			"district": district,
			"x": 640.0,
			"y": 440.0,
			"orientation": 0,
			"support": 0,
			"stored": true
		}
	)
	return id


static func move_object(
	state: Dictionary,
	id: int,
	location: Vector2,
	district: String,
	space: VillageSpace,
	expanded: bool
) -> bool:
	if (
		district not in ["patio", "workshop", "shore"]
		or not valid_position(state, id, location, district, space, expanded)
	):
		return false
	var object: Dictionary = object_by_id(state, id)
	var delta: Vector2 = location - point(object)
	object.x = location.x
	object.y = location.y
	object.district = district
	object.stored = false
	object.support = 0
	for child: Dictionary in state.objects:
		if int(child.support) == id:
			child.x = float(child.x) + delta.x
			child.y = float(child.y) + delta.y
			child.district = district
			child.stored = false
	return true


static func put_on_table(state: Dictionary, id: int, table_id: int) -> bool:
	var object: Dictionary = object_by_id(state, id)
	var table: Dictionary = object_by_id(state, table_id)
	if object.is_empty() or table.is_empty() or id == table_id or table.stored:
		return false
	if object.key.get_slice("|", 0) != "lak" or table.key.get_slice("|", 0) != "mayak":
		return false
	for child: Dictionary in state.objects:
		if int(child.support) == table_id and int(child.id) != id:
			return false
	object.support = table_id
	object.district = table.district
	object.x = table.x
	object.y = table.y
	object.stored = false
	return true


static func store_object(state: Dictionary, id: int) -> bool:
	var object: Dictionary = object_by_id(state, id)
	if object.is_empty():
		return false
	object.stored = true
	object.support = 0
	for child: Dictionary in state.objects:
		if int(child.support) == id:
			child.stored = true
	return true


static func valid_state(value: Variant, spaces: VillageSpaces, expanded: bool = false) -> bool:
	if value is not Dictionary or value.get("objects") is not Array:
		return false
	if not _integer(value.get("next_id"), 1, 1000000) or value.objects.size() > MAX_OBJECTS:
		return false
	var ids: Array[int] = []
	for object: Variant in value.objects:
		if object is not Dictionary:
			return false
		if not _integer(object.get("id"), 1, int(value.next_id) - 1) or int(object.id) in ids:
			return false
		if object.get("key") is not String or not CombinationCatalog.allowed(object.key):
			return false
		if (
			object.get("district") is not String
			or object.district not in ["patio", "workshop", "shore"]
		):
			return false
		if (
			not _integer(object.get("orientation"), 0, 3)
			or not _integer(object.get("support"), 0, 1000000)
		):
			return false
		if (
			object.get("stored") is not bool
			or not SaveSchema.is_number(object.get("x"))
			or not SaveSchema.is_number(object.get("y"))
		):
			return false
		var inside: bool = false
		for plot: Rect2 in spaces.space(object.district).plots(expanded):
			inside = inside or plot.has_point(point(object))
		if not inside:
			return false
		ids.append(int(object.id))
	var occupied_surfaces: Array[int] = []
	for object: Dictionary in value.objects:
		if int(object.support) == 0:
			if (
				not object.stored
				and not valid_position(
					value,
					int(object.id),
					point(object),
					object.district,
					spaces.space(object.district),
					expanded
				)
			):
				return false
			continue
		var table: Dictionary = object_by_id(value, int(object.support))
		if int(object.support) in occupied_surfaces:
			return false
		occupied_surfaces.append(int(object.support))
		if (
			table.is_empty()
			or int(table.support) != 0
			or table.key.get_slice("|", 0) != "mayak"
			or object.key.get_slice("|", 0) != "lak"
		):
			return false
		if (
			object.district != table.district
			or object.stored != table.stored
			or point(object) != point(table)
		):
			return false
	return true


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (
		SaveSchema.is_number(value)
		and float(value) == floor(float(value))
		and float(value) >= minimum
		and float(value) <= maximum
	)
