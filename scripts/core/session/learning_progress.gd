extends RefCounted
class_name LearningProgress

## Evidencia local de uso, separada de las páginas descubiertas. No diagnostica
## dominio: dos recuperaciones separadas y en contextos distintos son un indicio.
const RECALL_GAP := 3
const MAX_HISTORY: int = 128


static func empty_record() -> Dictionary:
	return {
		"practice": 0,
		"supported": 0,
		"errors": 0,
		"writing": 0,
		"reconstruction": 0,
		"recognition": 0,
		"guidance": 0,
		"spelling": 0,
		"use": 0,
		"experimentation": 0,
		"recalls": [],
		"last_recall": -100,
		"last_seen": -100,
		"recent": [],
		"contexts": []
	}


static func sanitize(value: Variant) -> Dictionary:
	var record: Dictionary = empty_record()
	if value is not Dictionary:
		return record
	for key: String in [
		"practice",
		"supported",
		"errors",
		"last_recall",
		"last_seen",
		"writing",
		"reconstruction",
		"recognition",
		"guidance",
		"spelling",
		"use",
		"experimentation"
	]:
		var number: Variant = value.get(key)
		if (
			(number is int or number is float)
			and is_finite(float(number))
			and float(number) == floor(float(number))
		):
			record[key] = clampi(
				int(number), -100 if key in ["last_recall", "last_seen"] else 0, 1000000
			)
	if value.get("recent") is Array:
		for result: Variant in value.recent.slice(-8):
			if (
				result is Dictionary
				and SaveSchema.is_number(result.get("support"))
				and SaveSchema.is_number(result.get("errors"))
				and float(result.support) == floor(float(result.support))
				and float(result.errors) == floor(float(result.errors))
				and float(result.support) >= 0
				and float(result.support) <= 2
				and float(result.errors) >= 0
				and float(result.errors) <= 1000
			):
				record.recent.append(
					{
						"support": clampi(int(result.support), 0, 2),
						"errors": clampi(int(result.errors), 0, 1000)
					}
				)
	for key: String in ["recalls", "contexts"]:
		if value.get(key) is Array:
			var entries: Array = value[key]
			for offset: int in range(entries.size()):
				var index: int = entries.size() - offset - 1 if key == "contexts" else offset
				var context: Variant = entries[index]
				if context is String and context.length() <= 160 and context not in record[key]:
					record[key].append(context)
				if record[key].size() == MAX_HISTORY:
					break
			if key == "contexts":
				record[key].reverse()
	return record


static func record_result(
	record: Dictionary,
	phase: String,
	context: String,
	supported: bool,
	mistakes: int,
	clock: int,
	evidence: Dictionary = {}
) -> void:
	# Restaurar un resultado o repetir el mismo reto no multiplica la evidencia.
	if context in record.contexts:
		return
	if (
		evidence.get("phase") is String
		and evidence.phase in ["recall", "practice", "reconstruction", "recognition"]
	):
		phase = evidence.phase
	if evidence.get("supported") is bool:
		supported = evidence.supported
	if evidence.get("mistakes") is int:
		mistakes = evidence.mistakes
	if evidence.get("guidance") is bool and evidence.guidance:
		record.guidance += 1
	if evidence.get("spelling") is bool and evidence.spelling:
		record.spelling += 1
	if context.begins_with("delivery/") or (evidence.get("use") is bool and evidence.use):
		record.use += 1
	if phase == "experiment":
		record.experimentation += 1
	record.contexts.append(context)
	if record.contexts.size() > MAX_HISTORY:
		record.contexts.pop_front()
	record.errors += maxi(mistakes, 0)
	record.last_seen = clock
	record.recent.append(
		{"support": 2 if supported or phase != "recall" else 0, "errors": maxi(mistakes, 0)}
	)
	if record.recent.size() > 8:
		record.recent.pop_front()
	record.practice += 1
	if phase == "recognition":
		record.recognition += 1
	elif phase == "reconstruction":
		record.reconstruction += 1
	elif phase == "recall" and not supported and mistakes == 0:
		record.writing += 1
	if supported or phase != "recall" or mistakes > 0:
		record.supported += 1
	elif (
		clock - int(record.last_recall) >= RECALL_GAP
		and context.get_slice("@", 0) not in record.recalls
	):
		record.recalls.append(context.get_slice("@", 0))
		record.last_recall = clock


static func caption(record: Dictionary) -> String:
	var count: int = record.recalls.size()
	if count >= 2:
		return "Recordada sin ayuda · %d situaciones" % count
	if count == 1:
		return "Primer recuerdo sin ayuda · vuelve a usarla"
	if int(record.practice) > 0:
		return "En práctica · sigue usándola"
	return "Descubierta · vamos a practicar"


static func detail(record: Dictionary) -> String:
	return (
		(
			"Reconocer: %d · Reconstruir: %d\nEscribir sin ayuda: %d · Usos: %d\n"
			+ "Orientación de controles: %d · Correcciones de grafía: %d\n"
			+ "Con apoyo: %d · Errores: %d · Experimentos: %d\nEvidencia del juego; no certifica dominio."
		)
		% [
			record.recognition,
			record.reconstruction,
			record.writing,
			record.use,
			record.guidance,
			record.spelling,
			record.supported,
			record.errors,
			record.experimentation
		]
	)
