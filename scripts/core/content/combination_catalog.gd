extends RefCounted
class_name CombinationCatalog

## Lista cerrada: sólo las 28 combinaciones directas acordadas. Sin inferir sinónimos.
const ROWS = CombinationData.ROWS
const BASICS = CombinationData.BASICS
const FURNITURE: Array[String] = ["mayak", "k'áanche'", "k'áan", "lak", "janal"]
const SOLIDS: Array[String] = ["ja'as", "ich", "K'úum"]


static func key(word: String, quality: String = "") -> String:
	return word + "|" + quality


static func row(id: String) -> Array:
	for entry: Array in ROWS:
		if key(entry[0], entry[1]) == id:
			return entry
	return []


static func allowed(id: String, allow_basic: bool = true) -> bool:
	var parts: PackedStringArray = id.split("|")
	return (
		parts.size() == 2
		and ((allow_basic and parts[1].is_empty() and parts[0] in BASICS) or not row(id).is_empty())
	)


static func targets() -> Dictionary:
	var result: Dictionary = {}
	for word: String in BASICS:
		result[key(word)] = BASICS[word]
	for entry: Array in ROWS:
		result[key(entry[0], entry[1])] = entry[3]
	return result


static func stage(world: int, basics_only: bool = false) -> Array[String]:
	var result: Array[String] = []
	for id: String in targets():
		var parts: PackedStringArray = id.split("|")
		if (
			(world < 4 and parts[0] not in FURNITURE)
			or ((world == 2 or basics_only) and not parts[1].is_empty())
		):
			continue
		result.append(id)
	return result


static func apply_entry(entry: ExerciseEntry, id: String, food: bool = false) -> void:
	var parts: PackedStringArray = id.split("|")
	var description: Array = row(id)
	entry.noun = parts[0]
	entry.adjective = parts[1]
	entry.food = parts[0]
	entry.modifier = parts[1]
	entry.translation = (
		str(description[2])
		if not description.is_empty()
		else str(GameContent.VOCABULARY[parts[0]].spanish)
	)
	entry.phrase = (
		"In k'a'at " + parts[0] + (" " + parts[1] if not parts[1].is_empty() else "")
		if food
		else parts[0] + (" · " + parts[1] if not parts[1].is_empty() else "")
	)


static func apply_task(task: VillageTask, id: String) -> void:
	var parts: PackedStringArray = id.split("|")
	task.item = parts[0]
	task.quality = parts[1]
