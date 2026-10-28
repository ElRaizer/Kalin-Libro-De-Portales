extends RefCounted
class_name PhraseExerciseSession

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


func build_plan(count: int, state: Dictionary) -> void:
	plan = ReplayVariation.two_phase(
		count, seed_value, true, ReplayVariation.previous(state, "plan", [])
	)
	plan = ExerciseProgress.restore_plan(state.get("plan"), count, plan)
	blocks_seen = ExerciseProgress.restore_markers(state.get("blocks"), plan.size())
	round_index = clampi(int(state.get("round", 0)), 0, plan.size())


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


func submit(answers: Array, expected: Array[String], writing: bool) -> bool:
	var correct: bool = true
	for index: int in range(expected.size()):
		var answer: String = str(answers[index]) if index < answers.size() else ""
		if writing:
			var match_result: Dictionary = WordMatcher.match_word(answer, expected[index])
			selected[index] = match_result.word
			attempt.supported = attempt.supported or match_result.supported
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
