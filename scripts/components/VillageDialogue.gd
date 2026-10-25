extends Node
class_name VillageDialogue

## El encargo elige su texto una vez por visita; sólo los saludos rotan al terminar.
const CATALOG = preload("res://data/dialogue/VillageDialogueCatalog.gd")
static var TARGETS: Dictionary = CombinationCatalog.targets()
var seed_value := 1
var greeting_visits: Dictionary = {}

static func task_key(task: VillageTask) -> String:
	return task.item + "|" + task.quality

static func personalize(task: VillageTask, animal: String, seed: int, context: String) -> void:
	var key := task_key(task)
	var bank: Array = CATALOG.ANIMALS.get(animal, {}).get("tasks", {}).get(key, [])
	task.requester = animal
	if bank.size() >= 3:
		var variant := posmod(hash("%d:%s:%s:%s" % [seed, context, animal, key]), 2)
		task.request = bank[variant]
		task.success = bank[2]
	else:
		# Contenido futuro: nunca heredar rasgos del dueño anterior del encargo.
		var description: String = TARGETS.get(key, GameContent.VOCABULARY.get(task.item, {}).get("spanish", task.item))
		if key not in TARGETS and not task.quality.is_empty():
			description += " · " + str(GameContent.VOCABULARY.get(task.quality, {}).get("spanish", task.quality))
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
			greeting_visits[animal] = int(fmod(float(value), CATALOG.ANIMALS[animal].greetings.size()))

func prepare(spot: ExplorationSpot) -> void:
	if not _can_greet(spot):
		return
	var bank: Array = CATALOG.ANIMALS[spot.speaker].greetings
	var order := ReplayVariation.order(bank.size(), posmod(hash("%d:%s" % [seed_value, spot.speaker]), 2000000000) + 1)
	var cursor := int(greeting_visits.get(spot.speaker, 0)) % bank.size()
	spot.lines.assign([bank[order[cursor]]])
	var success := str(spot.get_meta("village_success", ""))
	if not success.is_empty():
		spot.lines.append(success)

func finish(spot: ExplorationSpot) -> void:
	if _can_greet(spot):
		var count: int = CATALOG.ANIMALS[spot.speaker].greetings.size()
		greeting_visits[spot.speaker] = (int(greeting_visits.get(spot.speaker, 0)) + 1) % count

func _can_greet(spot: ExplorationSpot) -> bool:
	return (spot.has_meta("village_neighbour") or not str(spot.get_meta("village_success", "")).is_empty()) and spot.speaker in CATALOG.ANIMALS
