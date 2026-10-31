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
		var visit: Dictionary = visits[index]
		var fallback: Dictionary = memory.duplicate(true)
		var delivered: Array[int] = ExerciseProgress.restore_markers(visit.get("delivered"), 3)
		var combinations: Variant = visit.get("combination_tasks")
		var residents: Variant = visit.get("residents")
		if not delivered.is_empty() and combinations is Array and residents is Array:
			var task: int = delivered[0]
			if task < combinations.size() and task < residents.size():
				if combinations[task] is String and residents[task] is String:
					var parts: PackedStringArray = combinations[task].split("|")
					if parts.size() == 2 and CombinationCatalog.allowed(combinations[task]):
						memory.animal = residents[task]
						memory.item = parts[0]
						memory.quality = parts[1]
						memory.title = TITLES[index]
		var normalized: Dictionary = normalize(memory)
		result.append(normalize(fallback) if normalized.is_empty() else normalized)
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
