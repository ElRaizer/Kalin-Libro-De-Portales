extends Node
class_name VillageDialogue

## El encargo conserva su texto; los saludos y comentarios rotan al terminar de hablar.
const CATALOG = preload("res://scripts/features/village/data/village_dialogue_catalog.gd")
static var TARGETS: Dictionary = CombinationCatalog.targets()
var seed_value: int = 1
var greeting_visits: Dictionary = {}


static func task_key(task: VillageTask) -> String:
	return task.item + "|" + task.quality


static func personalize(task: VillageTask, animal: String, seed: int, context: String) -> void:
	var key: String = task_key(task)
	var bank: Dictionary = CATALOG.ANIMALS.get(animal, {}).get("tasks", {}).get(key, {})
	task.requester = animal
	task.purpose = CATALOG.ANIMALS.get(animal, {}).get("purpose", "Prepararemos juntos la plaza.")
	if not bank.is_empty():
		var requests: Array[String] = []
		requests.assign(bank.requests)
		var thanks: Array[String] = []
		thanks.assign(bank.thanks)
		var identity: String = "%d:%s:%s:%s" % [seed, context, animal, key]
		task.request = requests[posmod(hash(identity + ":request"), requests.size())]
		task.success = thanks[posmod(hash(identity + ":thanks"), thanks.size())]
	else:
		# Contenido futuro: nunca heredar rasgos del dueño anterior del encargo.
		var description: String = TARGETS.get(
			key, GameContent.VOCABULARY.get(task.item, {}).get("spanish", task.item)
		)
		if key not in TARGETS and not task.quality.is_empty():
			description += (
				" · "
				+ str(GameContent.VOCABULARY.get(task.quality, {}).get("spanish", task.quality))
			)
		task.request = "Necesito: %s. ¿Puedes ayudarme?" % description
		task.success = "¡Gracias, Kalin! Recibí mi encargo: %s." % description


func restore(saved: Dictionary, seed: int) -> void:
	seed_value = seed
	greeting_visits.clear()
	var stored: Variant = saved.get("greeting_visits", {})
	if stored is not Dictionary:
		return
	for animal: String in CATALOG.ANIMALS:
		var value: Variant = stored.get(animal, 0)
		if (value is int or value is float) and is_finite(float(value)) and value >= 0:
			greeting_visits[animal] = int(fmod(float(value), _conversation_cycle(animal)))


func prepare(spot: ExplorationSpot) -> void:
	if not _can_greet(spot):
		return
	var success: String = str(spot.get_meta("village_success", ""))
	spot.lines.assign(lines_for(spot.speaker, not success.is_empty()))


func lines_for(animal: String, after_help: bool = false) -> Array[String]:
	var lines: Array[String] = []
	if animal not in CATALOG.ANIMALS:
		return lines
	lines.append(_conversation_line(animal, "greetings", CATALOG.ANIMALS[animal].greetings))
	if after_help:
		lines.append(_conversation_line(animal, "after_help", CATALOG.ANIMALS[animal].after_help))
	return lines


func finish_animal(animal: String) -> void:
	if animal in CATALOG.ANIMALS:
		greeting_visits[animal] = (
			(int(greeting_visits.get(animal, 0)) + 1) % _conversation_cycle(animal)
		)


func _conversation_line(animal: String, situation: String, bank: Array) -> String:
	var order: Array[int] = ReplayVariation.order(
		bank.size(), posmod(hash("%d:%s:%s" % [seed_value, animal, situation]), 2000000000) + 1
	)
	var cursor: int = int(greeting_visits.get(animal, 0)) % bank.size()
	return bank[order[cursor]]


func _conversation_cycle(animal: String) -> int:
	# Un múltiplo de ambos bancos evita cortar la rotación del más corto al reiniciar.
	var data: Dictionary = CATALOG.ANIMALS[animal]
	return data.greetings.size() * data.after_help.size()


func finish(spot: ExplorationSpot) -> void:
	if _can_greet(spot):
		finish_animal(spot.speaker)


func _can_greet(spot: ExplorationSpot) -> bool:
	return (
		(
			spot.has_meta("village_neighbour")
			or not str(spot.get_meta("village_success", "")).is_empty()
		)
		and spot.speaker in CATALOG.ANIMALS
	)


func checkpoint_extension() -> Dictionary:
	return {"greeting_visits": greeting_visits.duplicate()}
