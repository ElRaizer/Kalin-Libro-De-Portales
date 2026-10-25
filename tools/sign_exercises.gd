extends SceneTree

## Herramienta explícita de autoría. El catálogo debe revisarse antes de escribir.
func _initialize() -> void:
	var write: bool = "--write" in OS.get_cmdline_user_args()
	var changed: bool = false
	for world: int in [3, 4]:
		var path: String = "res://data/exercises/world%d.tres" % world
		var content: ExerciseSet = load(path)
		var signature: String = content.content_signature()
		if content.authored_signature == signature:
			print("world%d: firma vigente" % world)
			continue
		changed = true
		if not write:
			print("world%d: contenido modificado; revisar antes de confirmar" % world)
			continue
		# Actualizar sólo la firma evita reserializar el recurso y sus subrecursos.
		var source: String = FileAccess.get_file_as_string(path)
		var pattern: RegEx = RegEx.new()
		pattern.compile('(?m)^authored_signature = "[a-f0-9]*"$')
		if pattern.search(source) == null:
			push_error("Falta authored_signature en " + path)
			quit(1)
			return
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("No se pudo actualizar la firma: " + path)
			quit(1)
			return
		file.store_string(pattern.sub(source, 'authored_signature = "' + signature + '"'))
		file.close()
		print("world%d: firma confirmada" % world)
	quit(1 if changed and not write else 0)
