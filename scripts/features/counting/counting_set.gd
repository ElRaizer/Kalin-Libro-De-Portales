@tool
extends Resource
class_name CountingSet

## Contenido de autor del tianguis de los números; se edita en el Inspector.
@export var rounds: Array[CountingRound] = []


func get_configuration_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if rounds.is_empty():
		issues.append("Agrega rondas al tianguis de los números.")
	for index: int in range(rounds.size()):
		var step: CountingRound = rounds[index]
		var label: String = "rounds[%d]" % index
		if step == null:
			issues.append("%s no tiene un recurso asignado." % label)
			continue
		if step.kind == CountingRound.Kind.STELE:
			if step.numbers.is_empty():
				issues.append("%s: la estela necesita números." % label)
			for word: String in step.numbers:
				if VocabularyCatalog.number_value(word) <= 0:
					issues.append("%s: «%s» no es un número del vocabulario." % [label, word])
			continue
		if VocabularyCatalog.number_value(step.number) <= 0:
			issues.append("%s: «%s» no es un número del vocabulario." % [label, step.number])
		if step.kind == CountingRound.Kind.BUILD:
			continue
		for word: String in [step.requester, step.item]:
			if VocabularyCatalog.entry(word).is_empty():
				issues.append("%s: «%s» no está en el vocabulario." % [label, word])
		if step.answer.is_empty():
			issues.append("%s: falta el número con su clasificador." % label)
		elif not step.phrase.is_empty() and step.answer.to_lower() not in step.phrase.to_lower():
			issues.append("%s: la frase debe contener «%s»." % [label, step.answer])
		if (
			step.kind == CountingRound.Kind.MARKET
			and VocabularyCatalog.entry(step.distractor).is_empty()
		):
			issues.append("%s: el puesto necesita otra cosa del vocabulario." % label)
		if step.kind in [CountingRound.Kind.FRIENDS, CountingRound.Kind.RECALL]:
			if step.options.size() < 2 or step.options.size() % 2 != 0:
				issues.append("%s: usa un número par de respuestas." % label)
			if step.answer not in step.options:
				issues.append("%s: la respuesta correcta debe estar entre las opciones." % label)
	return issues
