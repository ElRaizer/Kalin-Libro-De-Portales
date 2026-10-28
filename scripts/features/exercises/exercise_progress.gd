extends RefCounted
class_name ExerciseProgress


## JSON vuelve a leer los números como float. Normalizar antes de usar Array.has.
static func restore_markers(value: Variant, limit: int) -> Array[int]:
	var markers: Array[int] = []
	if value is Array:
		for entry: Variant in value:
			if (entry is int or entry is float) and entry == int(entry):
				var index: int = int(entry)
				if index >= 0 and index < limit and index not in markers:
					markers.append(index)
	return markers


## Restaurar sólo planes completos y válidos; reparar datos incompletos o dañados.
static func order_or(value: Variant, count: int, fallback: Array[int]) -> Array[int]:
	if value is not Array or value.size() != count:
		return fallback.duplicate()
	var result: Array[int] = []
	for entry: Variant in value:
		if not (entry is float or entry is int) or entry != int(entry):
			return fallback.duplicate()
		var index: int = int(entry)
		if index < 0 or index >= count or index in result:
			return fallback.duplicate()
		result.append(index)
	return result


static func restore_plan(
	value: Variant,
	count: int,
	fallback: Array[Dictionary],
	require_presentation: bool = true,
	presented: Array[bool] = []
) -> Array[Dictionary]:
	if value is not Array or value.size() < count or value.size() > count * 2:
		return fallback.duplicate(true)
	var result: Array[Dictionary] = []
	var guided: Array[int] = []
	var recalled: Array[int] = []
	for entry: Variant in value:
		if entry is not Dictionary or entry.get("guided") is not bool:
			return fallback.duplicate(true)
		var challenge: Variant = entry.get("challenge")
		if (
			not SaveSchema.is_number(challenge)
			or challenge < 0
			or challenge >= count
			or float(challenge) != floor(float(challenge))
		):
			return fallback.duplicate(true)
		var index: int = int(challenge)
		if entry.guided:
			if index in guided or index in recalled:
				return fallback.duplicate(true)
			guided.append(index)
		else:
			var needs_presentation: bool = (
				require_presentation or (index < presented.size() and not presented[index])
			)
			if (needs_presentation and index not in guided) or index in recalled:
				return fallback.duplicate(true)
			recalled.append(index)
		result.append({"challenge": index, "guided": entry.guided})
	if (require_presentation and guided.size() != count) or recalled.size() != count:
		return fallback.duplicate(true)
	return result
