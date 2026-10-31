extends RefCounted
class_name ChallengePlanner


## La prioridad usa ocasiones, apoyo reciente y separación; nunca diagnostica conocimiento.
static func select_words(known: Dictionary, progress: Dictionary, clock: int) -> Array[String]:
	var priority: Array[String] = []
	for word: String in VocabularyCatalog.learnable_keys():
		if word in known:
			priority.append(word)
	priority.sort_custom(
		func(a: String, b: String) -> bool:
			var left: float = _priority(LearningProgress.sanitize(progress.get(a)), clock)
			var right: float = _priority(LearningProgress.sanitize(progress.get(b)), clock)
			return left > right if left != right else a < b
	)
	var result: Array[String] = []
	for word: String in priority:
		var record: Dictionary = LearningProgress.sanitize(progress.get(word))
		if clock - int(record.last_seen) < LearningProgress.RECALL_GAP:
			continue
		result.append(word)
		if result.size() == 2:
			break
	# Una consolidación entre candidatos restantes, favoreciendo los menos recientes.
	var consolidation: String = ""
	var oldest: int = 1000001
	for word: String in priority:
		if word in result:
			continue
		var record: Dictionary = LearningProgress.sanitize(progress.get(word))
		if (
			clock - int(record.last_seen) >= LearningProgress.RECALL_GAP
			and int(record.last_seen) < oldest
		):
			oldest = int(record.last_seen)
			consolidation = word
	if not consolidation.is_empty():
		result.append(consolidation)
	if result.is_empty() and not priority.is_empty():
		# Si no hubo separación, la vista ofrece ensayo guiado, sin simular recuperación.
		result.append(priority[0])
	return result


static func _priority(record: Dictionary, clock: int) -> float:
	var recent: Array = record.recent
	var difficulty: float = 0.0
	for result: Dictionary in recent:
		difficulty += float(result.support) + minf(float(result.errors), 2.0)
	return (
		(6.0 if record.recalls.is_empty() else 0.0)
		+ difficulty / maxf(1.0, recent.size())
		+ minf(float(clock - int(record.last_seen)), 30.0) * 0.1
		- minf(float(record.practice), 10.0) * 0.1
	)


static func prompt(word: String) -> String:
	var entry: Dictionary = VocabularyCatalog.entry(word)
	if int(entry.world) == 1:
		return (
			"Un visitante busca a su amigo. ¿Cómo se llama en maya este animal: %s?" % entry.spanish
		)
	if int(entry.world) == 5:
		return "Kalin va a conversar. ¿Qué expresión maya usarías para decir «%s»?" % entry.spanish
	if int(entry.world) == 3:
		return "En el taller, describe cómo debe ser el objeto: %s." % entry.spanish
	return "Prepara un pedido para la aldea. ¿Cómo se dice %s en maya?" % entry.spanish


static func targets(word: String, known: Dictionary) -> Array[String]:
	if word not in MagicEconomy.design_words():
		return [word]
	for id: String in CombinationCatalog.targets():
		var parts: PackedStringArray = id.split("|", false)
		if parts.size() != 2 or word not in parts:
			continue
		if parts[0] in known and parts[1] in known:
			var result: Array[String] = []
			result.assign(parts)
			return result
	return [word]


static func situation(word: String, answers: Array[String]) -> String:
	if answers.size() == 2:
		var id: String = CombinationCatalog.key(answers[0], answers[1])
		return (
			"Prepara %s para un rincón de la aldea. Escribe el objeto y cómo es."
			% CombinationCatalog.targets()[id]
		)
	return prompt(word)
