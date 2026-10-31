extends RefCounted
class_name SceneStateSchema

## Contratos de checkpoints por familia. El repositorio no conoce estas claves.
const NUMBERS := [
	"panel",
	"beat",
	"round",
	"challenge",
	"dialogue_word",
	"line",
	"x",
	"y",
	"active_task",
	"choosing",
	"mistakes",
	"farewell_choice",
	"bars",
	"dots"
]
const FLAGS := [
	"waiting",
	"complete",
	"dialogue_open",
	"resolved",
	"intro_done",
	"cards",
	"naming_pending",
	"workbench_open",
	"memory_open",
	"gathering_seen"
]
const TEXT := [
	"noun",
	"adjective",
	"food",
	"modifier",
	"active",
	"return_scene",
	"recall_text",
	"board_variant",
	"district"
]
const LISTS := [
	"known",
	"met",
	"examined",
	"order",
	"recall_order",
	"plan",
	"blocks",
	"named",
	"mission_met",
	"delivered",
	"task_indices",
	"solved",
	"encounter_plan",
	"gifts",
	"residents",
	"combination_plan",
	"combination_tasks",
	"combination_animals",
	"translated",
	"helped",
	"basket"
]
const OBJECTS := [
	"attempt",
	"carried",
	"task_support",
	"task_mistakes",
	"drafts",
	"previous_variation",
	"guess_targets",
	"portal_variants",
	"scaffold",
	"greeting_visits",
	"portal_pool_keys",
	"board",
	"memory",
	"challenge_room",
	"walk_target"
]
const REPLAY_KEYS := [
	"guess_targets",
	"board_variant",
	"plan",
	"order",
	"encounter_plan",
	"portal_variants",
	"task_indices",
	"residents",
	"combination_plan",
	"combination_tasks",
	"combination_animals"
]


static func sanitize(value: Dictionary) -> Dictionary:
	var state: Dictionary = value.duplicate(true)
	for key: String in NUMBERS:
		if not state.has(key):
			continue
		if not SaveSchema.is_number(state[key]):
			state.erase(key)
		elif key not in ["x", "y"]:
			state[key] = int(
				clampf(
					float(state[key]),
					(
						-1
						if key in ["dialogue_word", "active_task", "choosing", "farewell_choice"]
						else 0
					),
					10000
				)
			)
	for key: String in FLAGS:
		if state.has(key) and state[key] is not bool:
			state.erase(key)
	for key: String in TEXT:
		if state.has(key) and state[key] is not String:
			state.erase(key)
	for key: String in LISTS:
		if state.has(key) and state[key] is not Array:
			state.erase(key)
	for key: String in OBJECTS:
		if state.has(key) and state[key] is not Dictionary:
			state.erase(key)
	if state.has("layout_seed"):
		if SaveSchema.is_number(state.layout_seed):
			state.layout_seed = int(clampf(float(state.layout_seed), 1, 2000000000))
		else:
			state.erase("layout_seed")
	# Los componentes validan sus índices y contenido; aquí se protegen los
	# tipos compartidos que consumen antes de inicializarse.
	if state.has("attempt"):
		var attempt: LearningAttempt = LearningAttempt.new()
		attempt.restore(state.attempt)
		state.attempt = attempt.snapshot()
	if state.has("scaffold"):
		state.scaffold = _scaffold(state.scaffold)
	if state.has("drafts"):
		for draft: Variant in state.drafts.values():
			if draft is Dictionary and draft.get("scaffold") is Dictionary:
				draft.scaffold = _scaffold(draft.scaffold)
	if state.has("carried"):
		var carried: Dictionary = state.carried
		if carried.has("mistakes"):
			var mistakes: Variant = carried.mistakes
			carried.mistakes = (
				int(clampf(float(mistakes), 0, 1000)) if SaveSchema.is_number(mistakes) else 0
			)
		if carried.has("supported") and carried.supported is not bool:
			carried.supported = true
	return state


static func _scaffold(scaffold: Dictionary) -> Dictionary:
	if scaffold.has("mode"):
		if SaveSchema.is_number(scaffold.mode):
			scaffold.mode = int(clampf(float(scaffold.mode), 0, 2))
		else:
			scaffold.erase("mode")
	for key: String in ["slots", "history"]:
		if scaffold.has(key) and scaffold[key] is not Array:
			scaffold.erase(key)
	return scaffold


static func replay_state(value: Dictionary) -> Dictionary:
	var previous: Dictionary = {}
	var state: Dictionary = sanitize(value)
	for key: String in REPLAY_KEYS:
		if state.has(key):
			previous[key] = state[key]
	return {"previous_variation": previous}.duplicate(true)
