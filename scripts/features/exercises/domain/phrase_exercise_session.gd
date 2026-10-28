extends RefCounted
class_name PhraseExerciseSession

const EPISODE_SIZE: int = 3

## Ciclo compartido de ejercicios de dos palabras. No conoce controles,
## escenas, GameManager ni archivos. Las vistas presentan sus transiciones.
var plan: Array[Dictionary] = []
var round_index: int = 0
var seed_value: int = 1
var resolving: bool = false
var awaiting_continue: bool = false
var cards: bool = false
var blocks_seen: Array[int] = []
var attempt: LearningAttempt = LearningAttempt.new()
var saved_scaffold: Dictionary = {}
var selected: Array[String] = ["", ""]


func restore_attempt(state: Dictionary) -> void:
	attempt.restore(state.get("attempt"))
	saved_scaffold = (
		state.get("scaffold", {}).duplicate(true) if state.get("scaffold") is Dictionary else {}
	)
	cards = state.get("cards") is bool and state.cards
	seed_value = int(state.get("layout_seed", randi_range(1, 2000000000)))


func build_plan(count: int, state: Dictionary, presented: Array[bool] = []) -> void:
	plan = _episode_plan(count, ReplayVariation.previous(state, "plan", []), presented)
	plan = ExerciseProgress.restore_plan(
		state.get("plan"), count, plan, presented.is_empty(), presented
	)
	blocks_seen = ExerciseProgress.restore_markers(state.get("blocks"), plan.size())
	round_index = clampi(int(state.get("round", 0)), 0, plan.size())


func _episode_plan(count: int, previous: Array, presented: Array[bool]) -> Array[Dictionary]:
	var previous_guided: Array[int] = []
	for entry: Dictionary in ExerciseProgress.restore_plan(previous, count, []):
		if entry.guided:
			previous_guided.append(int(entry.challenge))
	var guided: Array[int] = ReplayVariation.order(count, seed_value, previous_guided, true)
	var result: Array[Dictionary] = []
	for start: int in range(0, count, EPISODE_SIZE):
		var group: Array[int] = guided.slice(start, mini(start + EPISODE_SIZE, count))
		var recall: Array[int] = ReplayVariation.order(group.size(), seed_value + start + 7919)
		# Evitar que el cambio de modalidad pida copiar el último ejemplo visto.
		if group.size() > 1 and recall[0] == group.size() - 1:
			var swap: int = recall[0]
			recall[0] = recall[1]
			recall[1] = swap
		for index: int in group:
			if index >= presented.size() or not presented[index]:
				result.append({"challenge": index, "guided": true})
		for index: int in recall:
			result.append({"challenge": group[index], "guided": false})
	return result


func is_phase_start() -> bool:
	return round_index > 0 and plan[round_index - 1].guided != is_guided()


func episode_number() -> int:
	var number: int = 1
	for index: int in range(1, round_index + 1):
		if plan[index].guided and not plan[index - 1].guided:
			number += 1
	return number


func phase_position() -> int:
	var start: int = round_index
	while start > 0 and plan[start - 1].guided == is_guided():
		start -= 1
	return round_index - start + 1


func phase_size() -> int:
	var end: int = round_index + 1
	while end < plan.size() and plan[end].guided == is_guided():
		end += 1
	return phase_position() + end - round_index - 1


func challenge_index() -> int:
	return int(plan[round_index].challenge)


func is_guided() -> bool:
	return bool(plan[round_index].guided)


func begin_round(activity: String, requester: String, words: Array) -> bool:
	resolving = false
	awaiting_continue = false
	var semantic: String = LearningContext.identify(
		activity, requester, words, is_guided(), seed_value
	)
	var continuing: bool = LearningContext.begin(attempt, semantic)
	cards = cards if continuing else false
	selected.assign(["", ""])
	return continuing


func advance() -> bool:
	if not awaiting_continue:
		return false
	round_index += 1
	return true


func submit(
	answers: Array, expected: Array[String], writing: bool, phase: String = "recall"
) -> bool:
	var correct: bool = true
	for index: int in range(expected.size()):
		var answer: String = str(answers[index]) if index < answers.size() else ""
		if writing:
			var match_result: Dictionary = WordMatcher.match_word(answer, expected[index])
			selected[index] = match_result.word
			attempt.supported = attempt.supported or match_result.supported
			attempt.observe(expected[index], match_result.correct, match_result.supported, phase)
		else:
			selected[index] = answer
		correct = correct and selected[index] == expected[index]
	return correct


func miss() -> void:
	attempt.miss()


func resolve() -> void:
	resolving = true
	awaiting_continue = true


func finish() -> void:
	resolving = true
	awaiting_continue = false


func snapshot(
	first_key: String, second_key: String, answers: Array, scaffold: Dictionary
) -> Dictionary:
	return (
		{
			"plan": plan,
			"round": round_index,
			first_key: answers[0],
			second_key: answers[1],
			"waiting": awaiting_continue,
			"blocks": blocks_seen,
			"attempt": attempt.snapshot(),
			"layout_seed": seed_value,
			"cards": cards,
			"scaffold": scaffold,
		}
		. duplicate(true)
	)
