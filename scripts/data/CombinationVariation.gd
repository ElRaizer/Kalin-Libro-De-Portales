extends RefCounted
class_name CombinationVariation

## Selección acotada por capítulo, conservada como claves semánticas en JSON.
static func restore_keys(value: Variant, count: int, pool: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if value is not Array or value.size() != count:
		return result
	for id: Variant in value:
		if id is not String or id not in pool:
			return []
		result.append(id)
	return result

static func legacy(saved: Dictionary) -> bool:
	return not saved.has("combination_plan") and not saved.has("combination_tasks") and (saved.has("round") or saved.has("plan") or saved.has("task_indices") or saved.has("encounter_plan") or saved.has("solved"))

static func exercises(content: ExerciseSet, saved: Dictionary, seed_value: int, world: int) -> Dictionary:
	if content.resource_path != "res://data/exercises/world%d.tres" % world:
		return {} # Un recurso editado o sustituido conserva íntegro el contenido de autor.
	var pool: Array[String] = []
	for id: String in CombinationCatalog.stage(world):
		var parts := id.split("|")
		var words := content.nouns if world == 3 else content.foods
		var qualities := content.adjectives if world == 3 else content.modifiers
		if _contains(words, parts[0]) and _contains(qualities, parts[1]):
			pool.append(id)
	var ids := restore_keys(saved.get("combination_plan"), content.challenges.size(), pool)
	if ids.is_empty() and (legacy(saved) or saved.has("combination_plan")):
		return {}
	if ids.is_empty():
		if content.challenges.size() != 6:
			return {}
		if world == 3:
			ids.append("k'áanche'|chich")
			for quality: String in ["mejen", "Jats'uts", "nojoch", "ki'"]:
				var candidates: Array[String] = []
				for id: String in pool:
					if id.ends_with("|" + quality) and id not in ids:
						candidates.append(id)
				if candidates.is_empty():
					return {}
				ids.append(candidates[ReplayVariation.order(candidates.size(), seed_value + ids.size() * 137)[0]])
			var extras := pool.filter(func(id: String): return id not in ids and not id.ends_with("|"))
			ids.append(extras[ReplayVariation.order(extras.size(), seed_value + 991)[0]])
		else:
			ids.append("ja'|")
			var solids := ReplayVariation.order(3, seed_value + 173)
			for index: int in range(3):
				ids.append(CombinationCatalog.key(CombinationCatalog.SOLIDS[solids[index]], ["mejen", "Jats'uts", "nojoch"][index]))
			ids.append("janal|ki'")
			var extras := pool.filter(func(id: String): return id.get_slice("|", 0) in CombinationCatalog.SOLIDS and id not in ids and not id.ends_with("|"))
			ids.append(extras[ReplayVariation.order(extras.size(), seed_value + 991)[0]])
		for id: String in ids:
			if id not in pool:
				return {}
		var previous: Array = ReplayVariation.previous(saved, "combination_plan", [])
		if ids == previous:
			if world == 4:
				for id: String in pool:
					if id.get_slice("|", 0) in CombinationCatalog.SOLIDS and id not in ids and not id.ends_with("|"):
						ids[5] = id
						break
			else:
				for id: String in pool:
					if id not in ids and not id.ends_with("|"):
						ids[5] = id
						break
	var animals := restore_keys(saved.get("combination_animals"), ids.size(), _animals())
	if animals.is_empty():
		var all_animals := _animals()
		for index: int in ReplayVariation.order(all_animals.size(), seed_value + 2707):
			animals.append(all_animals[index])
		animals.resize(ids.size())
	var entries: Array[ExerciseEntry] = []
	for index: int in range(ids.size()):
		var entry := content.challenges[index].duplicate() as ExerciseEntry
		CombinationCatalog.apply_entry(entry, ids[index], world == 4)
		entry.animal = animals[index]
		entry.animal_spanish = GameContent.VOCABULARY[animals[index]].spanish
		entries.append(entry)
	return {"ids": ids, "animals": animals, "entries": entries}

static func needs(pool: Array[String], saved: Dictionary, count: int, seed_value: int, progress: Dictionary = {}) -> Array[String]:
	var stored := restore_keys(saved.get("combination_tasks"), count, pool)
	if not stored.is_empty() or legacy(saved) or saved.has("combination_tasks"):
		return stored
	var result: Array[String] = []
	var used: Array[String] = []
	var previous: Array = ReplayVariation.previous(saved, "combination_tasks", [])
	var order := ReplayVariation.order(pool.size(), seed_value)
	for position: int in range(count):
		var chosen := ""
		var best := 1000000
		for index: int in order:
			var id := pool[index]
			if id.get_slice("|", 0) in used:
				continue
			var score := 0
			for word: String in id.split("|", false):
				score += LearningProgress.sanitize(progress.get(word)).recalls.size()
			if id in previous:
				score += 1000
			if score < best:
				best = score
				chosen = id
		if chosen.is_empty():
			return []
		result.append(chosen)
		used.append(chosen.get_slice("|", 0))
	return result

static func choices(id: String, pool: Array[String], seed_value: int) -> Array[ExerciseEntry]:
	var ids: Array[String] = [id]
	for index: int in ReplayVariation.order(pool.size(), seed_value):
		var candidate := pool[index]
		if candidate != id and candidate.get_slice("|", 0) == id.get_slice("|", 0):
			ids.append(candidate)
			break
	for index: int in ReplayVariation.order(pool.size(), seed_value + 67):
		if pool[index] not in ids and ids.size() < 3:
			ids.append(pool[index])
	var result: Array[ExerciseEntry] = []
	for candidate: String in ids:
		var entry := ExerciseEntry.new()
		CombinationCatalog.apply_entry(entry, candidate)
		result.append(entry)
	return result

static func _contains(entries: Array[ExerciseEntry], word: String) -> bool:
	return entries.any(func(entry: ExerciseEntry): return entry.maya == word)

static func _animals() -> Array[String]:
	var result: Array[String] = []
	for word: String in GameContent.VOCABULARY:
		if int(GameContent.VOCABULARY[word].world) == 1 and word not in GameContent.FUTURE_VOCABULARY:
			result.append(word)
	return result
