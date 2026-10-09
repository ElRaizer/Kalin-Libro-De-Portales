extends RefCounted
class_name SaveRepository

## Único punto de acceso al archivo de progreso. Mantiene los detalles de JSON
## y FileAccess fuera de GameManager para que puedan probarse por separado.

const CURRENT_VERSION := 1
const DEFAULT_PATH := "user://kalin_save.json"

var save_path: String

func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path

func save_progress(progress: Dictionary) -> Error:
	var serialized := progress.duplicate(true)
	serialized["version"] = CURRENT_VERSION
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(serialized, "\t"))
	var error := file.get_error()
	file.close()
	return error

## Devuelve un diccionario vacío si no existe partida o si no puede usarse.
## La clave `_load_error` permite al consumidor distinguir un archivo ausente
## de uno dañado sin acoplarse a JSON ni FileAccess.
func load_progress() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
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
		return {"_load_error": "El progreso usa una versión más reciente (%d)." % loaded_version}
	return data

func delete_progress() -> Error:
	if not FileAccess.file_exists(save_path):
		return OK
	var directory := DirAccess.open(save_path.get_base_dir())
	if directory == null:
		return ERR_CANT_OPEN
	return directory.remove(save_path.get_file())

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
