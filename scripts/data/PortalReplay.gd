extends RefCounted
class_name PortalReplay

## Reutiliza palabras y combinaciones ya presentes en el contenido revisable.
const OBJECTS = preload("res://data/exercises/world2.tres")
const QUALITIES = preload("res://data/exercises/world3.tres")
const REQUESTS = preload("res://data/exercises/world4.tres")
const ANIMALS: Array[String] = ["Peek'", "Miis", "Kaax", "Áak"]

static func pool(category: int, base: ExerciseEntry, taught: Array[String] = []) -> Array[ExerciseEntry]:
	var result: Array[ExerciseEntry] = []
	var words: Array[String] = ANIMALS.duplicate()
	if category == 1:
		words.clear()
		for entry: Variant in OBJECTS.objects:
			words.append(entry.maya)
	var entries: Array = QUALITIES.challenges if category == 2 else REQUESTS.challenges
	if category >= 2 and not taught.is_empty():
		entries = []
		for id: String in taught:
			if not CombinationCatalog.allowed(id):
				continue
			var entry := ExerciseEntry.new()
			CombinationCatalog.apply_entry(entry, id, category == 3)
			entry.animal = ANIMALS[entries.size() % ANIMALS.size()]
			entries.append(entry)
	var count := words.size() if category < 2 else entries.size()
	for index: int in range(count):
		var task := base.duplicate() as ExerciseEntry
		if category < 2:
			var word := words[index]
			var vocabulary: Dictionary = GameContent.VOCABULARY[word]
			task.noun = word
			task.adjective = ""
			task.learn = word
			task.correct = str(vocabulary.estructura) if category == 0 else word
			task.prompt = "Ayuda a %s a presentarse." % word if category == 0 else "Crea un objeto para la aldea."
			task.clue = str(vocabulary.traduccion) if category == 0 else str(vocabulary.spanish)
		else:
			var entry: ExerciseEntry = entries[index]
			task.noun = entry.noun if category == 2 else entry.food
			task.adjective = entry.adjective if category == 2 else entry.modifier
			task.learn = ""
			task.correct = entry.phrase
			task.prompt = "Ayuda a %s con su hechizo." % entry.animal
			task.clue = entry.translation
		result.append(task)
	# Cuatro respuestas distintas y válidas, incluida siempre la correcta.
	for index: int in range(result.size()):
		var options: Array[String] = [result[index].correct]
		for offset: int in range(1, result.size()):
			var candidate := result[(index + offset) % result.size()].correct
			if candidate not in options and options.size() < 4:
				options.append(candidate)
		result[index].options = options
	return result

static func prepare(base: Array[ExerciseEntry], state: Dictionary, seed_value: int, taught: Dictionary = {}) -> Dictionary:
	var variants := {}
	var session: Array[ExerciseEntry] = []
	var stored: Variant = state.get("portal_variants", {})
	var previous_values: Variant = ReplayVariation.previous(state, "portal_variants", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool_keys := {}
	for category: String in ["2", "3"]:
		var stored_pool: Variant = state.get("portal_pool_keys", {})
		var keys: Variant = stored_pool.get(category, []) if stored_pool is Dictionary else []
		if not state.has("challenge") and (keys is not Array or keys.is_empty()):
			keys = taught.get(category, [])
		if keys is Array and keys.size() >= 4:
			var valid: Array[String] = []
			for id: Variant in keys:
				if id is String and CombinationCatalog.allowed(id) and id not in valid:
					valid.append(id)
			if valid.size() >= 4:
				pool_keys[category] = valid
	for category: int in range(base.size()):
		var chosen := base[category].duplicate() as ExerciseEntry
		if category < 4:
			var taught_keys: Array[String] = []
			taught_keys.assign(pool_keys.get(str(category), []))
			var alternatives := pool(category, base[category], taught_keys)
			var key := str(category)
			var raw: Variant = stored.get(key) if stored is Dictionary else null
			var valid: bool = (raw is int or raw is float) and raw == int(raw) and int(raw) >= 0 and int(raw) < alternatives.size()
			if valid or not state.has("challenge"):
				var previous_index := int(previous_values.get(key, -1)) if previous_values is Dictionary else -1
				var index := int(raw) if valid else ReplayVariation.pick(alternatives.size(), rng, previous_index)
				chosen = alternatives[index]
				variants[key] = index
		session.append(chosen)
	var order := ReplayVariation.order(4, seed_value + 523, ReplayVariation.previous(state, "order", []).slice(0, 4))
	if state.has("challenge") and not state.has("order"):
		order.assign([0, 1, 2, 3])
	for index: int in range(4, base.size()):
		order.append(index)
	order = ExerciseProgress.order_or(state.get("order"), base.size(), order)
	# Las últimas expresiones conservan saludo, agradecimiento y despedida.
	for index: int in range(4, order.size()):
		if order[index] != index:
			order.assign(range(base.size()))
			break
	var arranged: Array[ExerciseEntry] = []
	for index: int in order:
		arranged.append(session[index])
	return {"challenges": arranged, "variants": variants, "order": order, "pool_keys": pool_keys}

static func meaning(phrase: String) -> Array[String]:
	for entry: Array in CombinationCatalog.ROWS:
		var option := ExerciseEntry.new()
		CombinationCatalog.apply_entry(option, CombinationCatalog.key(entry[0], entry[1]))
		var spell := option.phrase
		CombinationCatalog.apply_entry(option, CombinationCatalog.key(entry[0], entry[1]), true)
		if phrase == spell or phrase == option.phrase:
			return [entry[0], entry[1]]
	for entry: Variant in QUALITIES.challenges:
		if entry.phrase == phrase:
			return [entry.noun, entry.adjective]
	for entry: Variant in REQUESTS.challenges:
		if entry.phrase == phrase:
			return [entry.food, entry.modifier]
	for word: String in GameContent.VOCABULARY:
		if phrase == word or phrase == GameContent.VOCABULARY[word].estructura:
			return [word, ""]
	return [phrase, ""]
