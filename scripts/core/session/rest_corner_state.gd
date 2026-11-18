extends RefCounted
class_name RestCornerState

const GUESTS: Array[String] = ["Áak", "Miis"]
const WORDS: Array[String] = ["mayak", "k'áanche'", "k'áan"]
const INTRO_STEPS: int = 3
const RESULT_STEPS: int = 2


static func empty_state() -> Dictionary:
	return {"intro": 0, "choice": "", "complete": false, "result": 0}


static func has_homecoming(scene_states: Dictionary) -> bool:
	var story: Variant = scene_states.get("world5_cine1")
	if story is not Dictionary:
		return false
	if story.get("complete") is bool and story.complete:
		return true
	var previous: Variant = story.get("previous_variation")
	return previous is Dictionary and previous.get("complete") is bool and previous.complete


static func valid_state(value: Variant, known: Dictionary, scene_states: Dictionary) -> bool:
	if value is not Dictionary or value.size() != 4:
		return false
	if value.get("choice") is not String or value.get("complete") is not bool:
		return false
	for field: String in ["intro", "result"]:
		var number: Variant = value.get(field)
		var limit: int = INTRO_STEPS if field == "intro" else RESULT_STEPS
		if (
			not SaveSchema.is_number(number)
			or float(number) != floor(float(number))
			or float(number) < 0
			or float(number) > limit
		):
			return false
	if int(value.intro) > 0 and not has_homecoming(scene_states):
		return false
	if not value.choice.is_empty():
		if (
			value.choice not in WORDS
			or value.choice not in known
			or int(value.intro) != INTRO_STEPS
		):
			return false
	if value.complete and value.choice.is_empty():
		return false
	return int(value.result) == 0 or value.complete
