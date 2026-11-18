extends RefCounted
class_name SessionCodec


## Decodifica y sanea únicamente el formato vigente antes de aplicar la sesión.
static func decode(data: Dictionary) -> Dictionary:
	var state: Dictionary = {
		"magic_points": int(data.get("magic_points", 0)),
		"economy": data.get("economy", MagicEconomy.empty_state()).duplicate(true),
		"garden": data.get("garden", GardenLayout.empty_state()).duplicate(true),
		"laboratory_favorites": data.get("laboratory_favorites", []).duplicate(),
		"garden_identity": data.get("garden_identity", {}).duplicate(true),
		"garden_compositions": data.get("garden_compositions", {}).duplicate(true),
		"snack_project": data.get("snack_project", SnackState.empty_state()).duplicate(true),
		"village_expansion":
		data.get("village_expansion", VillageExpansion.empty_state()).duplicate(true),
		"village_visit": data.get("village_visit", {}).duplicate(true),
		"village_experiences":
		data.get("village_experiences", VillageNeighbours.empty_experiences()).duplicate(true),
		"personal_album": data.get("personal_album", []).duplicate(true),
		"rest_corner": data.get("rest_corner", RestCornerState.empty_state()).duplicate(true),
		"completed_levels":
		SaveSchema.completed_levels(data.get("completed_levels", []), GameContent.LEVEL_ORDER),
		"resume_scene_key": _scene(data.get("resume_scene_key", ""), ["main_menu"]),
		"practice_return_key":
		_scene(data.get("practice_return_key", ""), ["main_menu", "village_home"]),
		"scene_states": {},
		"tutorials_seen": [],
		"words_learned": {},
		"learning_progress": {},
		"learning_clock": mini(int(data.get("learning_clock", 0)), 1000000),
	}
	var loaded_states: Dictionary = data.get("scene_states", {})
	if not state.snack_project.preparation.is_empty():
		var preparation: CountingActivity = CountingActivity.new()
		preparation.setup(SnackState.counting_set(), state.snack_project.preparation)
		state.snack_project.preparation = preparation.snapshot()
	state.rest_corner.intro = int(state.rest_corner.intro)
	state.rest_corner.result = int(state.rest_corner.result)
	if not state.village_visit.is_empty():
		state.village_visit.object_id = int(state.village_visit.object_id)
		state.village_visit.remaining = float(state.village_visit.remaining)
	for word: String in state.economy.awards:
		state.economy.awards[word] = int(state.economy.awards[word])
	for moment: Dictionary in state.personal_album:
		if moment.kind != "visit":
			continue
		moment.setting.table = int(moment.setting.table)
		for object: Dictionary in moment.setting.objects:
			for field: String in ["id", "orientation", "support"]:
				object[field] = int(object[field])
	state.garden.next_id = int(state.garden.next_id)
	for object: Dictionary in state.garden.objects:
		for field: String in ["id", "orientation", "support"]:
			object[field] = int(object[field])
	for district: String in state.garden_compositions:
		for slot: Dictionary in state.garden_compositions[district]:
			for object: Dictionary in slot.get("objects", []):
				for field: String in ["id", "orientation", "support"]:
					object[field] = int(object[field])
	for key: String in loaded_states:
		if key in GameContent.SCENE_PATHS and loaded_states[key] is Dictionary:
			state.scene_states[key] = SceneStateSchema.sanitize(loaded_states[key])
	for tutorial: Variant in data.get("tutorials_seen", []):
		if tutorial is String and tutorial not in state.tutorials_seen:
			state.tutorials_seen.append(tutorial)
	var words: Dictionary = data.get("words_learned", {})
	for key: String in words:
		if key in GameContent.VOCABULARY:
			state.words_learned[key] = VocabularyCatalog.entry(key)
	var evidence: Dictionary = data.get("learning_progress", {})
	for word: String in evidence:
		if word in GameContent.VOCABULARY and word in state.words_learned:
			var record: Dictionary = LearningProgress.sanitize(evidence[word])
			state.learning_progress[word] = record
	return state


static func _scene(value: String, excluded: Array[String]) -> String:
	return value if value in GameContent.SCENE_PATHS and value not in excluded else ""
