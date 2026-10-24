extends RefCounted
class_name PortalReplay

## Reutiliza palabras y combinaciones ya presentes en el contenido revisable.
const OBJECTS = preload("res://data/exercises/world2.tres")
const QUALITIES = preload("res://data/exercises/world3.tres")
const REQUESTS = preload("res://data/exercises/world4.tres")
const ANIMALS: Array[String] = ["Peek'", "Miis", "Kaax", "Áak"]

static func pool(category: int, base: ExerciseEntry) -> Array[ExerciseEntry]:
	var result: Array[ExerciseEntry] = []
	var words: Array[String] = ANIMALS.duplicate()
	if category == 1:
		words.clear()
		for entry: Variant in OBJECTS.objects:
			words.append(entry.maya)
	var entries: Array = QUALITIES.challenges if category == 2 else REQUESTS.challenges
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

static func prepare(base: Array[ExerciseEntry], state: Dictionary, seed_value: int) -> Dictionary:
	var variants := {}
	var session: Array[ExerciseEntry] = []
	var stored: Variant = state.get("portal_variants", {})
	var previous_values: Variant = ReplayVariation.previous(state, "portal_variants", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for category: int in range(base.size()):
		var chosen := base[category].duplicate() as ExerciseEntry
		if category < 4:
			var alternatives := pool(category, base[category])
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
	return {"challenges": arranged, "variants": variants, "order": order}

static func meaning(phrase: String) -> Array[String]:
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
