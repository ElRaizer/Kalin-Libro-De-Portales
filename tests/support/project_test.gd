extends SceneTree
class_name ProjectTest

## Soporte mínimo compartido: acumular comprobaciones y fallar el proceso.
var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func finish(label: String) -> void:
	if failures.is_empty():
		print(label + ": OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func repository_for(name: String) -> SaveRepository:
	var repository: SaveRepository = SaveRepository.new("user://validation_" + name + ".json")
	check(repository.delete_progress() == OK, "Se puede aislar el archivo de prueba: " + name)
	return repository


func write_json(path: String, value: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "Se puede escribir el fixture de prueba")
	if file:
		file.store_string(JSON.stringify(value))
		file.close()
