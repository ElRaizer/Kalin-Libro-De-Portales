extends RefCounted
class_name LearningAttempt

## La ayuda y los errores pertenecen al intento entero, incluso tras continuar
## desde un guardado. Seleccionar otra tarjeta no limpia esta evidencia.
var context: String = ""
var supported: bool = false
var mistakes: int = 0
var guidance: bool = false
var content_help: bool = false
var word_evidence: Dictionary = {}


func restore(value: Variant) -> void:
	if value is not Dictionary:
		return
	guidance = value.get("guidance") is bool and value.guidance
	content_help = value.get("content_help") is bool and value.content_help
	word_evidence.clear()
	if value.get("word_evidence") is Dictionary:
		for word: Variant in value.word_evidence:
			var entry: Variant = value.word_evidence[word]
			if word is not String or word.length() > 100 or entry is not Dictionary:
				continue
			if entry.get("supported") is not bool or entry.get("spelling") is not bool:
				continue
			var errors: Variant = entry.get("mistakes", 0)
			if not ((errors is int or errors is float) and is_finite(float(errors))):
				continue
			if float(errors) != floor(float(errors)):
				continue
			var phase: Variant = entry.get("phase")
			if phase is not String or phase not in ["practice", "recall", "reconstruction"]:
				continue
			word_evidence[word] = {
				"supported": entry.get("supported") is bool and entry.supported,
				"mistakes": clampi(int(errors), 0, 1000),
				"spelling": entry.get("spelling") is bool and entry.spelling,
				"phase": phase,
				"support_level": _support_level(entry.get("support_level", 0))
			}
	context = str(value.get("context", "")).left(160)
	supported = value.get("supported") is bool and value.supported
	var number: Variant = value.get("mistakes", 0)
	mistakes = (
		clampi(int(number), 0, 1000)
		if (
			(number is int or number is float)
			and is_finite(float(number))
			and float(number) == floor(float(number))
		)
		else 0
	)


func begin(next_context: String) -> void:
	if context == next_context:
		return
	context = next_context
	supported = false
	mistakes = 0
	guidance = false
	content_help = false
	word_evidence.clear()


func snapshot() -> Dictionary:
	return {
		"context": context,
		"supported": supported,
		"mistakes": mistakes,
		"guidance": guidance,
		"content_help": content_help,
		"word_evidence": word_evidence.duplicate(true)
	}


func use_content_help() -> void:
	supported = true
	content_help = true
	for word: String in word_evidence:
		word_evidence[word].support_level = 2


static func _support_level(value: Variant) -> int:
	return (
		int(value)
		if (
			SaveSchema.is_number(value)
			and float(value) == floor(float(value))
			and int(value) in [0, 1, 2]
		)
		else 2
	)


func use_word_support(word: String, level: int) -> void:
	var entry: Dictionary = word_evidence.get(
		word,
		{
			"supported": true,
			"mistakes": 0,
			"spelling": false,
			"phase": "reconstruction",
			"support_level": 0
		}
	)
	entry.support_level = maxi(int(entry.support_level), clampi(level, 0, 2))
	entry.supported = true
	word_evidence[word] = entry
	supported = true


## Una palabra ya correcta se conserva al ofrecer pistas sobre la otra.
func observe(word: String, correct: bool, spelling: bool, phase: String) -> void:
	if word.is_empty():
		return
	var entry: Dictionary = word_evidence.get(
		word,
		{
			"supported": phase != "recall" or content_help or mistakes > 0,
			"mistakes": mistakes,
			"spelling": false,
			"phase": phase,
			"support_level": 2 if content_help or phase == "practice" else 0
		}
	)
	if not correct:
		entry.mistakes += 1
		entry.supported = true
	if spelling:
		entry.spelling = true
		entry.supported = true
		entry.support_level = maxi(int(entry.support_level), 1)
	if phase != "recall" and entry.supported:
		entry.phase = phase
	word_evidence[word] = entry


func evidence(words: Array) -> Dictionary:
	var result: Dictionary = {}
	for word: String in words:
		var entry: Dictionary = word_evidence.get(word, {}).duplicate(true)
		entry.guidance = guidance
		if content_help:
			entry.supported = true
			entry.support_level = 2
		result[word] = entry
	return result


func miss() -> void:
	mistakes += 1
	supported = true
