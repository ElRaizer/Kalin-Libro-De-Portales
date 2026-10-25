extends RefCounted
class_name SaveRepository

## Único punto de acceso al archivo de progreso. Mantiene los detalles de JSON
## y FileAccess fuera de GameManager para que puedan probarse por separado.

const CURRENT_VERSION := SaveSchema.CURRENT_VERSION
const DEFAULT_PATH := "user://kalin_save.json"

var save_path: String


func _init(path: String = DEFAULT_PATH) -> void:
	save_path = path


func save_progress(progress: Dictionary) -> Error:
	var serialized: Dictionary = SaveSchema.validate(progress)
	if serialized.has("_load_error"):
		return ERR_INVALID_DATA
	var previous: Dictionary = _read_progress(save_path)
	var existing: Dictionary = (
		_read_progress(save_path + ".bak") if previous.is_empty() else previous
	)
	if existing.get("_unsupported_version", false):
		return ERR_INVALID_DATA
	var temporary: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(serialized, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		return error
	# Nunca truncar el archivo válido antes de terminar la escritura nueva.
	if FileAccess.file_exists(save_path) and not previous.has("_load_error"):
		error = DirAccess.copy_absolute(save_path, save_path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, save_path)


## Devuelve un diccionario vacío si no existe partida o si no puede usarse.
## La clave `_load_error` permite al consumidor distinguir un archivo ausente
## de uno dañado sin acoplarse a JSON ni FileAccess.
func load_progress() -> Dictionary:
	var result: Dictionary = _read_progress(save_path)
	if result.get("_unsupported_version", false):
		return result
	if result.has("_load_error") or result.is_empty():
		var backup: Dictionary = _read_progress(save_path + ".bak")
		# Si es el único archivo, su error también debe llegar al consumidor.
		if not backup.is_empty() and (result.is_empty() or not backup.has("_load_error")):
			return backup
	return result


func _read_progress(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"_load_error": "No se pudo leer el progreso (error %d)." % FileAccess.get_open_error()
		}
	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {
			"_load_error":
			(
				"El progreso está dañado (línea %d: %s)."
				% [json.get_error_line(), json.get_error_message()]
			)
		}
	if json.data is not Dictionary:
		return {"_load_error": "El progreso no contiene un objeto JSON válido."}
	return SaveSchema.validate(json.data)


func delete_progress() -> Error:
	# Conservar el archivo principal si falla la eliminación de un auxiliar.
	for path: String in [save_path + ".tmp", save_path + ".bak", save_path]:
		if FileAccess.file_exists(path):
			var error: Error = DirAccess.remove_absolute(path)
			if error != OK:
				return error
	return OK
