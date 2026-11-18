extends RefCounted
class_name GardenIdentity

const MAX_NAME_LENGTH: int = 32
const DISTRICTS: Array[String] = ["patio", "workshop", "shore"]
const DECORATIONS: Array[String] = ["sign", "border", "gathering"]


static func entry_for(state: Dictionary, district: String, project_complete: bool) -> Dictionary:
	if state.has(district):
		return state[district].duplicate(true)
	return {
		"name": "", "decorations": ["gathering"] if project_complete and district == "patio" else []
	}


static func valid_name(value: Variant) -> bool:
	if value is not String or value.length() > MAX_NAME_LENGTH or value != value.strip_edges():
		return false
	for index: int in range(value.length()):
		if value.unicode_at(index) < 32 or value.unicode_at(index) == 127:
			return false
	return true


static func valid_state(value: Variant, project_complete: bool) -> bool:
	if value is not Dictionary or value.size() > DISTRICTS.size():
		return false
	for district: Variant in value:
		if district is not String or district not in DISTRICTS:
			return false
		var entry: Variant = value[district]
		if entry is not Dictionary or not valid_name(entry.get("name")):
			return false
		if entry.get("decorations") is not Array or entry.decorations.size() > DECORATIONS.size():
			return false
		var seen: Array[String] = []
		for decoration: Variant in entry.decorations:
			if decoration is not String or decoration not in DECORATIONS or decoration in seen:
				return false
			seen.append(decoration)
		if not project_complete and not seen.is_empty():
			return false
	return true
