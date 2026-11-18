extends RefCounted
class_name VillageNeighbours

const DISTRICTS: Array[String] = ["patio", "workshop", "shore"]
const NAMES: Array[String] = ["El patio", "El taller", "La orilla"]
const RESIDENTS: Dictionary[String, Array] = {
	"patio": ["Áak", "Miis", "Peek'", "K'éek'en"],
	"workshop": ["Ma'ax", "Báalam", "Kuuts", "Kaax"],
	"shore": ["Kay", "Ch'íich'", "Kéej", "T'u'ul"]
}


static func district_for(animal: String) -> String:
	for district: String in DISTRICTS:
		if animal in RESIDENTS[district]:
			return district
	return ""


static func table_guest(animal: String, postgame: bool) -> bool:
	return (
		animal in RestCornerState.GUESTS
		or (postgame and animal != "Kay" and not district_for(animal).is_empty())
	)


static func empty_experiences() -> Dictionary:
	return {"visits": [], "deliveries": [], "clearing": []}


static func valid_experiences(
	value: Variant, known: Dictionary, homecoming: bool, snack: bool, opening: bool
) -> bool:
	if value is not Dictionary or value.size() != 3:
		return false
	if not _valid_known_list(value.get("visits"), known):
		return false
	if not _valid_known_list(value.get("deliveries"), known):
		return false
	if not _valid_known_list(value.get("clearing"), known):
		return false
	for guest: String in value.visits:
		if not (table_guest(guest, homecoming) or (guest == "Kay" and snack)):
			return false
	if not opening and not value.clearing.is_empty():
		return false
	for guest: String in value.clearing:
		if guest not in VillageExpansion.GUESTS:
			return false
	return true


static func _valid_known_list(value: Variant, known: Dictionary) -> bool:
	if value is not Array or value.size() > 12:
		return false
	var seen: Array[String] = []
	for guest: Variant in value:
		if guest is not String or guest not in known or guest in seen:
			return false
		if district_for(guest).is_empty():
			return false
		seen.append(guest)
	return true


const MISSIONS: Array[String] = ["world2_mission1", "world3_mission1", "world4_mission1"]


static func delivered_residents(state: Dictionary) -> Array[String]:
	var residents: Variant = state.get("residents")
	var result: Array[String] = []
	if residents is not Array or residents.size() != 3:
		return result
	for slot: int in ExerciseProgress.restore_markers(state.get("delivered"), residents.size()):
		var word: Variant = residents[slot]
		if word is String and not district_for(word).is_empty() and word not in result:
			result.append(word)
	return result
