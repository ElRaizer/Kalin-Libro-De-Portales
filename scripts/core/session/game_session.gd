extends RefCounted
class_name GameSession

## Dueño del progreso mutable. No conoce SceneTree, nodos, archivos ni UI.
var magic_points: int = 0
var economy: Dictionary = MagicEconomy.empty_state()
var garden: Dictionary = GardenLayout.empty_state()
var words_learned: Dictionary = {}
var completed_levels: Array[String] = []
var resume_scene_key: String = ""
var practice_return_key: String = ""
var scene_states: Dictionary = {}
var tutorials_seen: Array[String] = []
var learning_progress: Dictionary = {}
var learning_clock: int = 0


func snapshot() -> Dictionary:
	return (
		{
			"version": SaveSchema.CURRENT_VERSION,
			"magic_points": magic_points,
			"economy": economy,
			"garden": garden,
			"words_learned": words_learned,
			"completed_levels": completed_levels,
			"resume_scene_key": resume_scene_key,
			"practice_return_key": practice_return_key,
			"scene_states": scene_states,
			"tutorials_seen": tutorials_seen,
			"learning_progress": learning_progress,
			"learning_clock": learning_clock,
		}
		. duplicate(true)
	)


## La validación termina antes de modificar ningún campo; false conserva
## íntegro el progreso anterior. El resultado normalizado tampoco comparte datos.
func restore(data: Dictionary) -> bool:
	var validated: Dictionary = SaveSchema.validate(data)
	if validated.has("_load_error"):
		return false
	var state: Dictionary = SessionCodec.decode(validated)
	magic_points = state.magic_points
	economy = state.economy
	garden = state.garden
	words_learned = state.words_learned
	completed_levels.assign(state.completed_levels)
	resume_scene_key = state.resume_scene_key
	practice_return_key = state.practice_return_key
	scene_states = state.scene_states
	tutorials_seen.assign(state.tutorials_seen)
	learning_progress = state.learning_progress
	learning_clock = state.learning_clock
	return true


func reset() -> void:
	magic_points = 0
	economy = MagicEconomy.empty_state()
	garden = GardenLayout.empty_state()
	words_learned.clear()
	completed_levels.clear()
	resume_scene_key = ""
	practice_return_key = ""
	scene_states.clear()
	tutorials_seen.clear()
	learning_progress.clear()
	learning_clock = 0


func learn_word(key: String) -> bool:
	if key not in GameContent.VOCABULARY or key in words_learned:
		return false
	words_learned[key] = VocabularyCatalog.entry(key)
	return true


func complete_level(world: int, level: int) -> bool:
	var key: String = "w%d_l%d" % [world, level]
	if key in completed_levels:
		return false
	var exists: bool = false
	for entry: Dictionary in GameContent.LEVEL_ORDER:
		if entry.world == world and entry.level == level:
			exists = true
			break
	if not exists:
		return false
	completed_levels.append(key)
	return true


func is_level_completed(world: int, level: int) -> bool:
	return "w%d_l%d" % [world, level] in completed_levels


func next_unlocked_scene() -> String:
	for level: Dictionary in GameContent.LEVEL_ORDER:
		if not is_level_completed(level.world, level.level):
			return level.scene_key
	return "main_menu"


func recovered_word_count() -> int:
	var count: int = 0
	for word: String in words_learned:
		if word in GameContent.VOCABULARY and word not in GameContent.FUTURE_VOCABULARY:
			count += 1
	return count


func record_learning(
	words: Array,
	phase: String,
	context: String,
	supported: bool = false,
	mistakes: int = 0,
	evidence: Dictionary = {}
) -> Dictionary:
	var fresh: bool = false
	for word: String in words:
		var key: String = VocabularyCatalog.resolve(word)
		if (
			not key.is_empty()
			and context not in LearningProgress.sanitize(learning_progress.get(key)).contexts
		):
			fresh = true
	if not fresh:
		return {"changed": false, "learned": []}
	var learned: Array[String] = []
	var awarded: int = 0
	learning_clock += 1
	for word: String in words:
		var key: String = VocabularyCatalog.resolve(word)
		if key.is_empty():
			continue
		if learn_word(key):
			learned.append(key)
		var record: Dictionary = LearningProgress.sanitize(learning_progress.get(key))
		var detail: Dictionary = evidence.get(word, {})
		if context not in record.contexts and key in VocabularyCatalog.learnable_keys():
			var word_phase: String = str(detail.get("phase", phase))
			var amount: int = MagicEconomy.reward(word_phase, supported, detail)
			var previous: int = int(economy.awards.get(key, 0))
			var difference: int = maxi(0, amount - previous)
			if (
				previous > 0
				and learning_clock - int(record.last_seen) < LearningProgress.RECALL_GAP
			):
				difference = 0
			if difference > 0:
				economy.awards[key] = amount
				magic_points += difference
				awarded += difference
		LearningProgress.record_result(
			record, phase, context, supported, mistakes, learning_clock, evidence.get(word, {})
		)
		learning_progress[key] = record
	return {"changed": true, "learned": learned, "awarded": awarded}


func prepare_sharing_corner() -> bool:
	if MagicEconomy.FIRST_PROJECT in economy.preparations:
		return false
	for word: String in MagicEconomy.FIRST_DESIGNS:
		if word not in words_learned or int(economy.awards.get(word, 0)) < 4:
			return false
	economy.preparations.append(MagicEconomy.FIRST_PROJECT)
	magic_points += MagicEconomy.PREPARATION_POINTS
	return true


func purchase_design(word: String) -> bool:
	if not MagicEconomy.can_purchase(economy, word, words_learned, magic_points):
		return false
	magic_points -= MagicEconomy.DESIGN_PRICE
	economy.designs.append(word)
	return true


func confirm_sharing_corner(id: String) -> bool:
	if economy.built or id != "mayak|chich":
		return false
	if not MagicEconomy.can_build(economy, id, words_learned):
		return false
	economy.built = true
	return true


func create_garden_object(id: String, district: String) -> int:
	if not MagicEconomy.can_build(economy, id, words_learned):
		return 0
	return GardenLayout.add_object(garden, id, district)


func place_garden_object(
	id: int, location: Vector2, district: String, orientation: int = -1
) -> bool:
	var object: Dictionary = GardenLayout.object_by_id(garden, id)
	if object.is_empty() or orientation < -1 or orientation > 3:
		return false
	var previous_orientation: int = int(object.orientation)
	if orientation >= 0:
		object.orientation = orientation
	if not GardenLayout.move_object(garden, id, location, district):
		object.orientation = previous_orientation
		return false
	confirm_sharing_corner(str(GardenLayout.object_by_id(garden, id).key))
	return true


func unlocked_village_world() -> int:
	var world: int = 1
	for level: Dictionary in GameContent.LEVEL_ORDER:
		world = maxi(world, int(level.world))
		if not is_level_completed(level.world, level.level):
			break
	return world


## Consultar contenido fuera de la sala también pertenece al intento pendiente.
func mark_pending_challenge_help() -> bool:
	var saved: Variant = scene_states.get("village_home", {})
	if saved is not Dictionary or saved.get("challenge_room") is not Dictionary:
		return false
	var room: Dictionary = saved.challenge_room
	var index: Variant = room.get("index")
	if room.get("words") is not Array or not SaveSchema.is_number(index):
		return false
	if float(index) != floor(float(index)) or float(index) < 0 or float(index) >= room.words.size():
		return false
	if room.get("waiting") is bool and room.waiting:
		return false
	var attempt: LearningAttempt = LearningAttempt.new()
	attempt.restore(room.get("attempt"))
	if attempt.context.is_empty() or attempt.content_help:
		return false
	attempt.use_content_help()
	room.attempt = attempt.snapshot()
	return true
