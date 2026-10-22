extends RefCounted
class_name LearningProgress

## Evidencia local de uso, separada de las páginas descubiertas. No diagnostica
## dominio: dos recuperaciones separadas y en contextos distintos son un indicio.
const RECALL_GAP := 3

static func empty_record() -> Dictionary:
	return {"practice": 0, "supported": 0, "errors": 0, "recalls": [], "last_recall": -100, "contexts": []}

static func sanitize(value: Variant) -> Dictionary:
	var record := empty_record()
	if value is not Dictionary:
		return record
	for key: String in ["practice", "supported", "errors", "last_recall"]:
		var number: Variant = value.get(key)
		if (number is int or number is float) and is_finite(float(number)):
			record[key] = clampi(int(number), -100 if key == "last_recall" else 0, 1000000)
	for key: String in ["recalls", "contexts"]:
		if value.get(key) is Array:
			for context: Variant in value[key]:
				if context is String and context.length() <= 160 and context not in record[key] and record[key].size() < 128:
					record[key].append(context)
	return record

static func record_result(record: Dictionary, phase: String, context: String, supported: bool, mistakes: int, clock: int) -> void:
	# Restaurar un resultado o repetir el mismo reto no multiplica la evidencia.
	if context in record.contexts:
		return
	record.contexts.append(context)
	record.errors += maxi(mistakes, 0)
	record.practice += 1
	if supported or phase != "recall" or mistakes > 0:
		record.supported += 1
	elif clock - int(record.last_recall) >= RECALL_GAP and context.get_slice("@", 0) not in record.recalls:
		record.recalls.append(context.get_slice("@", 0))
		record.last_recall = clock

static func caption(record: Dictionary) -> String:
	var count: int = record.recalls.size()
	if count >= 2:
		return "Recordada sin ayuda · %d situaciones" % count
	if count == 1:
		return "Primer recuerdo sin ayuda · vuelve a usarla"
	if int(record.practice) > 0:
		return "En práctica · aún con apoyo"
	return "Descubierta · vamos a practicar"
