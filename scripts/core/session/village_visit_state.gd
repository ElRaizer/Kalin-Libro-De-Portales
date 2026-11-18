extends RefCounted
class_name VillageVisitState

## Una visita conserva intención y tiempo, nunca actores ni una segunda posición del mueble.
const MAX_SECONDS: float = 120.0


static func valid_state(
	value: Variant, garden: Dictionary, known: Dictionary, postgame: bool = false
) -> bool:
	if value is not Dictionary:
		return false
	if value.is_empty():
		return true
	if value.size() != 3 or value.get("animal") is not String:
		return false
	if not VillageNeighbours.table_guest(value.animal, postgame) or value.animal not in known:
		return false
	var id: Variant = value.get("object_id")
	var remaining: Variant = value.get("remaining")
	if (
		not SaveSchema.is_number(id)
		or float(id) != floor(float(id))
		or float(id) < 1
		or float(id) >= float(garden.next_id)
		or not SaveSchema.is_number(remaining)
		or float(remaining) <= 0
		or float(remaining) > MAX_SECONDS
	):
		return false
	return usable_table(GardenLayout.object_by_id(garden, int(id)))


static func usable_table(object: Dictionary) -> bool:
	return (
		not object.is_empty()
		and not object.stored
		and object.district == "patio"
		and object.key.get_slice("|", 0) == "mayak"
		and int(object.support) == 0
	)
