extends RefCounted
class_name PhraseExerciseFixture


## Las pruebas eligen una modalidad, sin asumir una posición fija en el plan.
static func round_for(plan: Array[Dictionary], guided: bool, offset: int = 0) -> int:
	for index: int in range(plan.size()):
		if plan[index].guided == guided:
			if offset == 0:
				return index
			offset -= 1
	return -1


static func recall_state(seed_value: int, count: int = 6, offset: int = 0) -> Dictionary:
	var exercise: PhraseExerciseSession = PhraseExerciseSession.new()
	exercise.restore_attempt({"layout_seed": seed_value})
	exercise.build_plan(count, {})
	return {
		"layout_seed": seed_value,
		"plan": exercise.plan.duplicate(true),
		"round": round_for(exercise.plan, false, offset)
	}


static func episode_state(seed_value: int, round_index: int, count: int = 6) -> Dictionary:
	var exercise: PhraseExerciseSession = PhraseExerciseSession.new()
	exercise.restore_attempt({"layout_seed": seed_value})
	exercise.build_plan(count, {})
	return {"layout_seed": seed_value, "plan": exercise.plan.duplicate(true), "round": round_index}
