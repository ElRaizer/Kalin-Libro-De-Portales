extends RefCounted
class_name SaveSchema

## Valida el contenedor antes de restaurar una sesión o aceptar un respaldo.
const CURRENT_VERSION: int = 9
const MAX_POINTS := 1000000000


static func is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func validate(data: Dictionary) -> Dictionary:
	for key: String in ["version", "magic_points", "learning_clock"]:
		if not data.has(key):
			continue
		var value: Variant = data[key]
		if (
			not is_number(value)
			or float(value) < 0
			or float(value) > MAX_POINTS
			or float(value) != floor(float(value))
		):
			return {"_load_error": "El campo '%s' no contiene un entero válido." % key}
	var version: int = int(data.get("version", 0))
	if version != CURRENT_VERSION:
		return {
			"_load_error":
			(
				"La partida usa otro formato (%d). Reinicia la partida para usar esta versión."
				% version
			),
			"_unsupported_version": true
		}
	for key: String in ["words_learned", "scene_states", "learning_progress"]:
		if data.has(key) and data[key] is not Dictionary:
			return {"_load_error": "El campo '%s' no contiene un objeto válido." % key}
	for key: String in ["completed_levels", "tutorials_seen"]:
		if data.has(key) and data[key] is not Array:
			return {"_load_error": "El campo '%s' no contiene una lista válida." % key}
	for key: String in ["resume_scene_key", "practice_return_key"]:
		if data.has(key) and data[key] is not String:
			return {"_load_error": "El campo '%s' no contiene texto válido." % key}
	if data.has("economy") and not MagicEconomy.valid_state(data.economy):
		return {"_load_error": "La economía contiene objetivos o compras inválidos."}
	if not RestCornerState.valid_state(
		data.get("rest_corner", RestCornerState.empty_state()),
		data.get("words_learned", {}),
		data.get("scene_states", {})
	):
		return {"_load_error": "El rincón de descanso contiene elecciones o etapas inválidas."}
	var economy: Dictionary = data.get("economy", MagicEconomy.empty_state())
	var known: Dictionary = data.get("words_learned", {})
	if not LaboratoryState.valid_favorites(data.get("laboratory_favorites", []), known):
		return {"_load_error": "Los favoritos contienen combinaciones desconocidas o inválidas."}
	if not PersonalAlbum.valid_state(data.get("personal_album", []), known):
		return {"_load_error": "El álbum contiene un recuerdo personal inválido."}
	var rest: Dictionary = data.get("rest_corner", RestCornerState.empty_state())
	if not SnackState.valid_state(
		data.get("snack_project", SnackState.empty_state()), known, data.get("scene_states", {})
	):
		return {"_load_error": "La merienda contiene invitados, cantidades o resultados inválidos."}
	var snack: Dictionary = data.get("snack_project", SnackState.empty_state())
	var homecoming: bool = RestCornerState.has_homecoming(data.get("scene_states", {}))
	var expansion: Variant = data.get("village_expansion", VillageExpansion.empty_state())
	if not VillageExpansion.valid_state(expansion, known, rest.complete and snack.complete):
		return {
			"_load_error": "La ampliación contiene pruebas, invitados o inauguración inválidos."
		}
	if not VillageNeighbours.valid_experiences(
		data.get("village_experiences", VillageNeighbours.empty_experiences()),
		known,
		homecoming,
		snack.complete,
		expansion.complete
	):
		return {"_load_error": "Las experiencias de aldea contienen habitantes inválidos."}
	if (
		data.has("garden")
		and not GardenLayout.valid_state(
			data.garden, GameContent.VILLAGE_SPACES, expansion.complete
		)
	):
		return {"_load_error": "La parcela contiene muebles o apoyos inválidos."}
	if not VillageVisitState.valid_state(
		data.get("village_visit", {}),
		data.get("garden", GardenLayout.empty_state()),
		known,
		homecoming
	):
		return {"_load_error": "La visita contiene un invitado, mueble o tiempo inválido."}
	if (
		expansion.complete
		and not VillageGround.extension_accessible(
			data.get("garden", GardenLayout.empty_state()),
			GameContent.VILLAGE_SPACES.space("shore")
		)
	):
		return {"_load_error": "La ampliación no conserva una entrada segura para sus invitados."}
	if not GardenIdentity.valid_state(data.get("garden_identity", {}), rest.complete):
		return {"_load_error": "El nombre o los adornos del rincón no son válidos."}
	var garden: Dictionary = data.get("garden", GardenLayout.empty_state())
	if not GardenCompositions.valid_state(
		data.get("garden_compositions", {}),
		known,
		int(garden.next_id),
		GameContent.VILLAGE_SPACES,
		expansion.complete
	):
		return {
			"_load_error": "Los acomodos guardados contienen posiciones o referencias inválidas."
		}
	for field: String in ["awards", "designs"]:
		for word: String in economy[field]:
			if word not in known:
				return {
					"_load_error": "Un objetivo o diseño no corresponde a palabras presentadas."
				}
	if data.has("garden"):
		for object: Dictionary in data.garden.objects:
			if not MagicEconomy.can_build(economy, object.key, known):
				return {"_load_error": "La parcela contiene un diseño sin abrir."}
	return data.duplicate(true)


static func completed_levels(value: Variant, level_order: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	if value is not Array:
		return result
	var valid: Array[String] = []
	for level: Dictionary in level_order:
		valid.append("w%d_l%d" % [level.world, level.level])
	for item: Variant in value:
		if item is String and item in valid and item not in result:
			result.append(item)
	return result
