extends RefCounted
class_name ExerciseProgress

## JSON vuelve a leer los números como float. Normalizar antes de usar Array.has.
static func restore_markers(value: Variant, limit: int) -> Array[int]:
	var markers: Array[int] = []
	if value is Array:
		for entry: Variant in value:
			if (entry is int or entry is float) and entry == int(entry):
				var index := int(entry)
				if index >= 0 and index < limit and index not in markers:
					markers.append(index)
	return markers

## Restaurar sólo planes completos y válidos; un guardado antiguo puede no tenerlos.
static func order_or(value: Variant, count: int, fallback: Array[int]) -> Array[int]:
	if value is not Array or value.size() != count:
		return fallback.duplicate()
	var result: Array[int] = []
	for entry: Variant in value:
		if not (entry is float or entry is int) or entry != int(entry):
			return fallback.duplicate()
		var index := int(entry)
		if index < 0 or index >= count or index in result:
			return fallback.duplicate()
		result.append(index)
	return result

static func restore_plan(value: Variant, count: int, fallback: Array[Dictionary]) -> Array[Dictionary]:
	if value is not Array or value.size() != count * 2:
		return fallback
	var result: Array[Dictionary] = []
	for phase: int in range(2):
		var indices: Array[int] = []
		for offset: int in range(count):
			var entry: Variant = value[phase * count + offset]
			if entry is not Dictionary or entry.get("guided") is not bool or entry.get("guided") != (phase == 0):
				return fallback
			var challenge: Variant = entry.get("challenge", -1)
			if not (challenge is float or challenge is int) or challenge != int(challenge):
				return fallback
			var index := int(challenge)
			if index < 0 or index >= count or index in indices:
				return fallback
			indices.append(index)
			result.append({"challenge": index, "guided": phase == 0})
	return result

static func restore_rounds(value: Variant, count: int, fallback: Array[int]) -> Array[int]:
	if value is not Array or value.size() != count * 2:
		return fallback
	var first := order_or(value.slice(0, count), count, fallback.slice(0, count))
	first.append_array(order_or(value.slice(count), count, fallback.slice(count)))
	return first
