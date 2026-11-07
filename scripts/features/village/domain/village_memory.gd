extends RefCounted
class_name VillageMemory

## Una preferencia personal sobre algo vivido. No produce evidencia de aprendizaje.
const KEYS: Array[String] = ["home", "party", "meal"]
const TITLES: Array[String] = ["Nuestro rincón", "Preparar la fiesta", "Compartir la comida"]
const FAREWELL_TITLES: Array[String] = ["Dar las gracias", "Desear buen viaje", "Hasta otro día"]


static func options(visits: Array[Dictionary], gifts: Array[ExerciseEntry]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in range(3):
		var memory: Dictionary = {
			"kind": KEYS[index],
			"title": FAREWELL_TITLES[index],
			"animal": gifts[index].animal,
			"item": "",
			"quality": ""
		}
		var fallback: Dictionary = memory.duplicate(true)
		var delivered: Array[Dictionary] = (
			delivered_moments(visits[index], index) if index < visits.size() else []
		)
		if not delivered.is_empty():
			memory = delivered[0]
		var normalized: Dictionary = normalize(memory)
		result.append(normalize(fallback) if normalized.is_empty() else normalized)
	return result


## Sólo las entregas confirmadas pueden convertirse en recuerdos de un habitante.
static func for_animal(visits: Array[Dictionary], animal: String) -> Dictionary:
	for index: int in range(mini(visits.size(), KEYS.size()) - 1, -1, -1):
		for moment: Dictionary in delivered_moments(visits[index], index):
			if moment.animal == animal:
				return moment
	return {}


static func delivered_moments(visit: Dictionary, chapter: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if chapter not in range(KEYS.size()):
		return result
	var combinations: Variant = visit.get("combination_tasks")
	var residents: Variant = visit.get("residents")
	if combinations is not Array or residents is not Array:
		return result
	for task: int in ExerciseProgress.restore_markers(visit.get("delivered"), 3):
		if task >= combinations.size() or task >= residents.size():
			continue
		if combinations[task] is not String or residents[task] is not String:
			continue
		var parts: PackedStringArray = combinations[task].split("|")
		if parts.size() != 2 or not CombinationCatalog.allowed(combinations[task]):
			continue
		var moment: Dictionary = normalize(
			{
				"kind": KEYS[chapter],
				"title": TITLES[chapter],
				"animal": residents[task],
				"item": parts[0],
				"quality": parts[1]
			}
		)
		if not moment.is_empty():
			result.append(moment)
	return result


static func normalize(value: Variant) -> Dictionary:
	if value is not Dictionary:
		return {}
	for key: String in ["kind", "title", "animal", "item", "quality"]:
		if value.get(key) is not String:
			return {}
	if value.kind not in KEYS:
		return {}
	var index: int = KEYS.find(value.kind)
	if value.title not in [TITLES[index], FAREWELL_TITLES[index]]:
		return {}
	var animal: Dictionary = VocabularyCatalog.entry(value.animal)
	if animal.is_empty() or int(animal.get("world", 0)) != 1:
		return {}
	if (
		not value.item.is_empty()
		and not CombinationCatalog.allowed(value.item + "|" + value.quality)
	):
		return {}
	if value.item.is_empty() and not value.quality.is_empty():
		return {}
	return {
		"kind": value.kind,
		"title": value.title,
		"animal": value.animal,
		"item": value.item,
		"quality": value.quality
	}


static func from_checkpoint(state: Dictionary) -> Dictionary:
	if ExerciseProgress.restore_markers(state.get("gifts"), 3).size() != 3:
		return {}
	return normalize(state.get("memory"))
