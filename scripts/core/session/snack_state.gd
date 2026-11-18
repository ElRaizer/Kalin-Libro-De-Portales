extends RefCounted
class_name SnackState

const GUESTS: Array[String] = ["Kay", "Ch'íich'"]
const FOODS: Array[String] = ["ja'as|", "K'úum|", "janal|"]
const DECORATIONS: Array[String] = ["leaves", "flowers"]


static func counting_set() -> CountingSet:
	var content: CountingSet = CountingSet.new()
	content.round_count = 2
	content.min_value = 1
	content.max_value = 10
	content.guided_rounds = 0
	content.requesters.assign(GUESTS)
	return content


static func targets(guests: Array) -> Array[int]:
	return [guests.size(), guests.size() * 5]


static func empty_state() -> Dictionary:
	return {"guests": [], "food": "", "decoration": "leaves", "preparation": {}, "complete": false}


static func valid_state(value: Variant, known: Dictionary, scene_states: Dictionary) -> bool:
	if value is not Dictionary or value.size() != 5:
		return false
	if value.get("guests") is not Array or value.guests.size() > GUESTS.size():
		return false
	var seen: Array[String] = []
	for guest: Variant in value.guests:
		if guest is not String or guest not in GUESTS or guest not in known or guest in seen:
			return false
		seen.append(guest)
	if (
		value.get("food") is not String
		or value.get("decoration") is not String
		or value.decoration not in DECORATIONS
		or value.get("complete") is not bool
	):
		return false
	if (
		not value.food.is_empty()
		and (value.food not in FOODS or not LaboratoryState.known_combination(value.food, known))
	):
		return false
	if value.get("preparation") is not Dictionary:
		return false
	if not RestCornerState.has_homecoming(scene_states):
		return value == empty_state()
	if value.preparation.is_empty():
		return not value.complete
	if seen.is_empty() or value.food.is_empty():
		return false
	if not CountingActivity.valid_state(value.preparation, counting_set()):
		return false
	var expected: Array[int] = targets(seen)
	for index: int in range(expected.size()):
		if int(value.preparation.counting.targets[index]) != expected[index]:
			return false
	return not value.complete or int(value.preparation.counting.round) == 2


static func memory(state: Dictionary) -> Dictionary:
	if not state.complete:
		return {}
	return {
		"guests": state.guests.duplicate(),
		"food": state.food,
		"decoration": state.decoration,
		"quantities": targets(state.guests)
	}
