extends RefCounted
class_name ReplayVariation

## Azar acotado: una elección por intento, persistida por la escena.
static func order(count: int, seed_value: int, previous: Array = [], fixed_first := false) -> Array[int]:
	var result: Array[int] = []
	for index: int in range(count):
		result.append(index)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var first := 1 if fixed_first else 0
	for index: int in range(count - 1, first, -1):
		var other := rng.randi_range(first, index)
		var swap := result[index]
		result[index] = result[other]
		result[other] = swap
	if result == previous and count - first > 1:
		var swap := result[first]
		result[first] = result[first + 1]
		result[first + 1] = swap
	return result

static func pick(count: int, rng: RandomNumberGenerator, previous: int = -1) -> int:
	if count <= 1:
		return 0
	var chosen := rng.randi_range(0, count - 2 if previous >= 0 and previous < count else count - 1)
	return chosen + 1 if previous >= 0 and previous < count and chosen >= previous else chosen

static func previous(state: Dictionary, key: String, fallback: Variant = null) -> Variant:
	var saved: Variant = state.get("previous_variation", {})
	var value: Variant = saved.get(key, fallback) if saved is Dictionary else fallback
	return fallback if fallback != null and typeof(value) != typeof(fallback) else value

static func replay_state(state: Dictionary) -> Dictionary:
	var previous_values := {}
	for key: String in ["guess_targets", "board_variant", "plan", "order", "encounter_plan", "portal_variants", "task_indices", "residents", "combination_plan", "combination_tasks", "combination_animals"]:
		if state.has(key):
			previous_values[key] = state[key]
	return {"previous_variation": previous_values}

static func two_phase(count: int, seed_value: int, fixed_first: bool, previous_plan: Array = []) -> Array[Dictionary]:
	var previous_guided: Array = []
	for item: Variant in previous_plan.slice(0, count):
		previous_guided.append(item.get("challenge", -1) if item is Dictionary else item)
	var guided := order(count, seed_value, previous_guided, fixed_first)
	var recall := order(count, seed_value + 7919, guided)
	if count > 1 and recall[0] == guided.back():
		var swap := recall[0]
		recall[0] = recall[1]
		recall[1] = swap
	var result: Array[Dictionary] = []
	for index: int in guided:
		result.append({"challenge": index, "guided": true})
	for index: int in recall:
		result.append({"challenge": index, "guided": false})
	return result
