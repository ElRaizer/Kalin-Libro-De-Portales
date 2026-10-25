extends RefCounted
class_name SaveRepository

## Único punto de acceso al archivo de progreso. Mantiene los detalles de JSON
## y FileAccess fuera de GameManager para que puedan probarse por separado.

const CURRENT_VERSION := 5
const DEFAULT_PATH := "user://kalin_save.json"

var save_path: String

func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path

func save_progress(progress: Dictionary) -> Error:
	var serialized := progress.duplicate(true)
	serialized["version"] = CURRENT_VERSION
	var temporary := save_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(serialized, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	# Nunca truncar el archivo válido antes de terminar la escritura nueva.
	if FileAccess.file_exists(save_path) and not _read_progress(save_path).has("_load_error"):
		error = DirAccess.copy_absolute(save_path, save_path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, save_path)

## Devuelve un diccionario vacío si no existe partida o si no puede usarse.
## La clave `_load_error` permite al consumidor distinguir un archivo ausente
## de uno dañado sin acoplarse a JSON ni FileAccess.
func load_progress() -> Dictionary:
	var result := _read_progress(save_path)
	if result.get("_unsupported_version", false):
		return result
	if result.has("_load_error") or result.is_empty():
		var backup := _read_progress(save_path + ".bak")
		if not backup.is_empty() and not backup.has("_load_error"):
			return backup
	return result

func _read_progress(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"_load_error": "No se pudo leer el progreso (error %d)." % FileAccess.get_open_error()}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {"_load_error": "El progreso está dañado (línea %d: %s)." % [json.get_error_line(), json.get_error_message()]}
	if json.data is not Dictionary:
		return {"_load_error": "El progreso no contiene un objeto JSON válido."}
	var data: Dictionary = json.data
	var loaded_version := int(data.get("version", 0))
	if loaded_version > CURRENT_VERSION:
		return {"_load_error": "El progreso usa una versión más reciente (%d)." % loaded_version, "_unsupported_version": true}
	return data

func delete_progress() -> Error:
	for path: String in [save_path, save_path + ".bak", save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			var error := DirAccess.remove_absolute(path)
			if error != OK:
				return error
	return OK

static func sanitize_completed_levels(value: Variant, level_order: Array[Dictionary]) -> Array[String]:
	var sanitized: Array[String] = []
	if value is not Array:
		return sanitized
	var valid_keys: Dictionary = {}
	for level_data: Dictionary in level_order:
		valid_keys["w%d_l%d" % [level_data.world, level_data.level]] = true
	for item: Variant in value:
		var key := str(item)
		if valid_keys.has(key) and key not in sanitized:
			sanitized.append(key)
	return sanitized

static func sanitize_scene_state(value: Dictionary) -> Dictionary:
	var state := value.duplicate(true)
	for key: String in ["panel", "beat", "round", "challenge", "dialogue_word", "line", "x", "active_task", "choosing", "mistakes", "farewell_choice"]:
		if not state.has(key):
			continue
		var number: Variant = state[key]
		if not (number is float or number is int) or not is_finite(float(number)):
			state.erase(key)
		elif key != "x":
			state[key] = int(clampf(float(number), -1 if key in ["dialogue_word", "active_task", "choosing", "farewell_choice"] else 0, 10000))
	for key: String in ["waiting", "complete", "dialogue_open", "resolved", "intro_done", "cards", "naming_pending", "workbench_open", "assembly_open"]:
		if state.has(key) and state[key] is not bool:
			state.erase(key)
	for key: String in ["noun", "adjective", "food", "modifier", "active", "return_scene"]:
		if state.has(key) and state[key] is not String:
			state.erase(key)
	for key: String in ["known", "met", "examined", "order", "recall_order", "plan", "named", "mission_met", "delivered", "task_indices", "solved", "encounter_plan", "gifts", "pages", "residents", "combination_plan", "combination_tasks", "combination_animals"]:
		if state.has(key) and state[key] is not Array:
			state.erase(key)
	for key: String in ["attempt", "carried", "task_support", "task_mistakes", "drafts", "previous_variation", "guess_targets", "portal_variants", "scaffold", "greeting_visits", "portal_pool_keys"]:
		if state.has(key) and state[key] is not Dictionary:
			state.erase(key)
	if state.has("layout_seed"):
		var seed_value: Variant = state.layout_seed
		if not (seed_value is float or seed_value is int) or not is_finite(float(seed_value)):
			state.erase("layout_seed")
		else:
			state.layout_seed = clampi(int(seed_value), 1, 2000000000)
	return state
