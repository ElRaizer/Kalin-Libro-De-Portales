extends RefCounted
class_name PortalReplay

## Reutiliza palabras y combinaciones ya presentes en el contenido revisable.
const OBJECTS = preload("res://data/exercises/world2.tres")
const QUALITIES = preload("res://data/exercises/world3.tres")
const REQUESTS = preload("res://data/exercises/world4.tres")
const ANIMALS: Array[String] = ["Peek'", "Miis", "Kaax", "Áak"]


static func pool(
	category: int, base: ExerciseEntry, taught: Array[String] = []
) -> Array[ExerciseEntry]:
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
			var entry: ExerciseEntry = ExerciseEntry.new()
			CombinationCatalog.apply_entry(entry, id, category == 3)
			entry.animal = ANIMALS[entries.size() % ANIMALS.size()]
			entries.append(entry)
	var count: int = words.size() if category < 2 else entries.size()
	for index: int in range(count):
		var task: ExerciseEntry = base.duplicate() as ExerciseEntry
		if category < 2:
			var word: String = words[index]
			var vocabulary: Dictionary = GameContent.VOCABULARY[word]
			task.noun = word
			task.adjective = ""
			task.learn = word
			task.correct = str(vocabulary.estructura) if category == 0 else word
			task.prompt = (
				"Ayuda a %s a presentarse." % word
				if category == 0
				else "Crea un objeto para la aldea."
			)
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
			var candidate: String = result[(index + offset) % result.size()].correct
			if candidate not in options and options.size() < 4:
				options.append(candidate)
		result[index].options = options
	return result


static func prepare(
	base: Array[ExerciseEntry], state: Dictionary, seed_value: int, taught: Dictionary = {}
) -> Dictionary:
	var variants: Dictionary = {}
	var session: Array[ExerciseEntry] = []
	var stored: Variant = state.get("portal_variants", {})
	var previous_values: Variant = ReplayVariation.previous(state, "portal_variants", {})
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool_keys: Dictionary = {}
	for category: String in ["2", "3"]:
		var stored_pool: Variant = state.get("portal_pool_keys", {})
		var keys: Variant = stored_pool.get(category, []) if stored_pool is Dictionary else []
		if keys is not Array or keys.is_empty():
			keys = taught.get(category, [])
		if keys is Array and keys.size() >= 4:
			var valid: Array[String] = []
			for id: Variant in keys:
				if id is String and CombinationCatalog.allowed(id) and id not in valid:
					valid.append(id)
			if valid.size() >= 4:
				pool_keys[category] = valid
	for category: int in range(base.size()):
		var chosen: ExerciseEntry = base[category].duplicate() as ExerciseEntry
		if category < 4:
			var taught_keys: Array[String] = []
			taught_keys.assign(pool_keys.get(str(category), []))
			var alternatives: Array[ExerciseEntry] = pool(category, base[category], taught_keys)
			var key: String = str(category)
			var raw: Variant = stored.get(key) if stored is Dictionary else null
			var restored_index: int = _index(raw, alternatives.size())
			var previous_index: int = (
				_index(previous_values.get(key), alternatives.size())
				if previous_values is Dictionary
				else -1
			)
			var index: int = (
				restored_index
				if restored_index >= 0
				else ReplayVariation.pick(alternatives.size(), rng, previous_index)
			)
			chosen = alternatives[index]
			variants[key] = index
		session.append(chosen)
	var order: Array[int] = ReplayVariation.order(
		4, seed_value + 523, ReplayVariation.previous(state, "order", []).slice(0, 4)
	)
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


static func _index(value: Variant, count: int) -> int:
	if not SaveSchema.is_number(value):
		return -1
	var number: float = float(value)
	if number < 0 or number >= count or number != floor(number):
		return -1
	return int(number)


static func meaning(phrase: String) -> Array[String]:
	for entry: Array in CombinationCatalog.ROWS:
		var option: ExerciseEntry = ExerciseEntry.new()
		CombinationCatalog.apply_entry(option, CombinationCatalog.key(entry[0], entry[1]))
		var spell: String = option.phrase
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
