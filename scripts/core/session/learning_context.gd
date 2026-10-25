extends RefCounted
class_name LearningContext


static func identify(
	activity: String, requester: String, words: Array, guided: bool, seed_value: int
) -> String:
	return (
		"%s:%s:%s:%s@%d"
		% [activity, requester, "|".join(words), "practice" if guided else "recall", seed_value]
	)


static func begin(attempt: LearningAttempt, semantic: String) -> bool:
	var continuing: bool = attempt.context == semantic
	attempt.begin(semantic)
	return continuing
