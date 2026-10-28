extends RefCounted
class_name WordMatcher


## Comparación pura; omitir acentos se registra como apoyo.
static func match_word(typed: String, expected: String) -> Dictionary:
	var actual: String = " ".join(
		typed.strip_edges().replace("’", "'").replace("·", " ").to_lower().split(" ", false)
	)
	var wanted: String = " ".join(expected.replace("·", " ").to_lower().split(" ", false))
	if actual == wanted:
		return {"correct": true, "supported": false, "word": expected}
	var normalized: String = actual
	var normalized_expected: String = wanted
	for pair: Array in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"]]:
		normalized = normalized.replace(pair[0], pair[1])
		normalized_expected = normalized_expected.replace(pair[0], pair[1])
	return {
		"correct": normalized == normalized_expected,
		"supported": normalized == normalized_expected,
		"word": expected if normalized == normalized_expected else typed
	}
