extends RefCounted
class_name StoryQuestionPlan

## Variación de preguntas sobre copias de autor; independiente de la escena.
var beats: Array[StoryBeat] = []
var targets: Dictionary = {}


static func build(
	source: Array[StoryBeat], seed_value: int, state: Dictionary
) -> StoryQuestionPlan:
	var plan: StoryQuestionPlan = StoryQuestionPlan.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var stored: Variant = state.get("guess_targets", {})
	var previous_targets: Variant = ReplayVariation.previous(state, "guess_targets", {})
	var asked: Array[String] = []
	var session: Array[StoryBeat] = []
	for index: int in range(source.size()):
		var beat: StoryBeat = source[index].duplicate() as StoryBeat
		session.append(beat)
		if beat.kind != StoryBeat.Kind.ADIVINAR or beat.question_template.is_empty():
			continue
		var key: String = str(index)
		var candidates: Array[String] = []
		for word: String in beat.actors:
			if word != beat.speaker and word not in asked:
				candidates.append(word)
		if candidates.is_empty():
			candidates = beat.actors.duplicate()
		var chosen: String = beat.target_word
		if stored is Dictionary and str(stored.get(key, "")) in beat.actors:
			chosen = str(stored[key])
		else:
			var previous_word: String = (
				str(previous_targets.get(key, "")) if previous_targets is Dictionary else ""
			)
			chosen = candidates[ReplayVariation.pick(
				candidates.size(), rng, candidates.find(previous_word)
			)]
		beat.target_word = chosen
		beat.text = beat.question_template.replace("{animal}", chosen)
		plan.targets[key] = chosen
		asked.append(chosen)
	plan.beats = session
	return plan
