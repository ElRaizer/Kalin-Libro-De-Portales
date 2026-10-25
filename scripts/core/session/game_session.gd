extends RefCounted
class_name GameSession

## Dueño del progreso mutable. No conoce SceneTree, nodos, archivos ni UI.
const MAGIC_PER_WORD := 10
const MAGIC_PER_LEVEL := 50
var magic_points: int = 0
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
	magic_points += MAGIC_PER_WORD
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
	magic_points += MAGIC_PER_LEVEL
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
	words: Array, phase: String, context: String, supported: bool = false, mistakes: int = 0
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
	learning_clock += 1
	for word: String in words:
		var key: String = VocabularyCatalog.resolve(word)
		if key.is_empty():
			continue
		if learn_word(key):
			learned.append(key)
		var record: Dictionary = LearningProgress.sanitize(learning_progress.get(key))
		LearningProgress.record_result(record, phase, context, supported, mistakes, learning_clock)
		learning_progress[key] = record
	return {"changed": true, "learned": learned}
