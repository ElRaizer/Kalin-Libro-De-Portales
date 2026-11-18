extends SceneTree


func _initialize() -> void:
	var base: String = ProjectSettings.globalize_path("res://.godot/").replace("\\", "/")
	var target: String = OS.get_user_data_dir().replace("\\", "/")
	if not target.to_lower().begins_with(base.to_lower() + "kalin-validation-"):
		push_error("El escenario de demostración requiere el perfil aislado de validate.ps1.")
		quit(1)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var session: GameSession
	if args == PackedStringArray(["--demo=regreso"]):
		session = PostgameFixture.at_ending()
	elif args == PackedStringArray(["--demo=reanudacion"]):
		session = PostgameFixture.resumed()
	else:
		push_error("Escenario de demostración desconocido.")
		quit(1)
		return
	var repository: SaveRepository = SaveRepository.new()
	if not repository.load_progress().is_empty():
		push_error("El perfil de demostración debe comenzar vacío.")
		quit(1)
		return
	var error: Error = repository.save_progress(session.snapshot())
	if error != OK:
		push_error("No se pudo preparar la demostración (error %d)." % error)
		quit(1)
		return
	quit(0)
