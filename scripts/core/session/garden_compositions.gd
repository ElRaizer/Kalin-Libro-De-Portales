extends RefCounted
class_name GardenCompositions

const MAX_SLOTS: int = 2


static func capture(garden: Dictionary, district: String) -> Dictionary:
	var objects: Array[Dictionary] = []
	for object: Dictionary in garden.objects:
		if object.district == district and not object.stored:
			objects.append(object.duplicate(true))
	return {"objects": objects}


static func valid_state(
	value: Variant, known: Dictionary, next_id: int, spaces: VillageSpaces, expanded: bool = false
) -> bool:
	if value is not Dictionary or value.size() > GardenIdentity.DISTRICTS.size():
		return false
	var identities: Dictionary[int, String] = {}
	for district: Variant in value:
		if district is not String or district not in GardenIdentity.DISTRICTS:
			return false
		var slots: Variant = value[district]
		if slots is not Array or slots.size() > MAX_SLOTS:
			return false
		for slot: Variant in slots:
			if slot is not Dictionary:
				return false
			if slot.is_empty():
				continue
			if slot.get("objects") is not Array or slot.objects.size() > GardenLayout.MAX_OBJECTS:
				return false
			var synthetic: Dictionary = {"next_id": 1, "objects": slot.objects}
			for object: Variant in slot.objects:
				if object is not Dictionary or not SaveSchema.is_number(object.get("id")):
					return false
				if float(object.id) < 1 or float(object.id) >= next_id:
					return false
				synthetic.next_id = maxi(int(synthetic.next_id), int(object.id) + 1)
				if object.get("district") is not String or object.district != district:
					return false
				if object.get("stored") is not bool or object.stored:
					return false
				if (
					object.get("key") is not String
					or not LaboratoryState.known_combination(object.key, known)
				):
					return false
				var id: int = int(object.id)
				if identities.has(id) and identities[id] != object.key:
					return false
				identities[id] = object.key
			if not GardenLayout.valid_state(synthetic, spaces, expanded):
				return false
	return true


static func apply(
	garden: Dictionary,
	district: String,
	composition: Dictionary,
	spaces: VillageSpaces,
	expanded: bool = false
) -> Dictionary:
	var candidate: Dictionary = garden.duplicate(true)
	var ids: Array[int] = []
	for reference: Dictionary in composition.objects:
		var id: int = int(reference.id)
		var current: Dictionary = GardenLayout.object_by_id(candidate, id)
		if current.is_empty() or current.key != reference.key:
			return {
				"error":
				(
					"Falta la copia #%d: %s. Conservamos tu jardín."
					% [id, CombinationCatalog.targets()[reference.key]]
				)
			}
		ids.append(id)
	for object: Dictionary in candidate.objects:
		if int(object.support) in ids and int(object.id) not in ids:
			return {
				"error":
				"Una mesa tiene otro plato apoyado. Guarda primero ese plato; conservamos tu jardín."
			}
		if object.district == district and int(object.id) not in ids:
			object.stored = true
	for reference: Dictionary in composition.objects:
		GardenLayout.object_by_id(candidate, int(reference.id)).merge(reference, true)
	if not GardenLayout.valid_state(candidate, spaces, expanded):
		return {"error": "El acomodo no cabe con los apoyos actuales. Conservamos tu jardín."}
	return {"garden": candidate}
