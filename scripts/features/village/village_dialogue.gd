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
	var bank: Array = CATALOG.ANIMALS[spot.speaker].greetings
	spot.lines.assign([_conversation_line(spot.speaker, "greetings", bank)])
	var success: String = str(spot.get_meta("village_success", ""))
	if not success.is_empty():
		var after_help: Array = CATALOG.ANIMALS[spot.speaker].after_help
		spot.lines.append(_conversation_line(spot.speaker, "after_help", after_help))


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
		var count: int = _conversation_cycle(spot.speaker)
		greeting_visits[spot.speaker] = (int(greeting_visits.get(spot.speaker, 0)) + 1) % count


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
