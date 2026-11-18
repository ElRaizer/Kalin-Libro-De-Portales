extends RefCounted
class_name LaboratoryState

## Límite del contrato persistido; cada perfil puede ofrecer una capacidad menor.
const MAX_FAVORITES: int = 12


static func known_combination(id: String, known: Dictionary) -> bool:
	if not CombinationCatalog.allowed(id):
		return false
	for word: String in id.split("|", false):
		if word not in known:
			return false
	return true


static func valid_favorites(value: Variant, known: Dictionary) -> bool:
	if value is not Array or value.size() > MAX_FAVORITES:
		return false
	var seen: Array[String] = []
	for id: Variant in value:
		if id is not String or id in seen or not known_combination(id, known):
			return false
		seen.append(id)
	return true
