extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	var manager: Node = root.get_node("GameManager")
	manager.session.scene_states.clear()
	manager.session.resume_scene_key = ""
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		"user://intro_validation_progress.json"
	)
	var error: Error = change_scene_to_file("res://scenes/ui/main_menu/intro.tscn")
	if error != OK:
		push_error("No se pudo cargar la introducción para la prueba")
		quit(1)
		return

	await scene_changed
	var intro: Node = current_scene
	await create_timer(0.4).timeout
	intro.set("panel_index", intro.panels.size() - 1)
	intro.set("is_animating", false)
	intro.set("text_revealed", true)

	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	intro.call("_input", click)

	await scene_changed
	if (
		current_scene == null
		or current_scene.scene_file_path != GameContent.SCENE_PATHS.world1_cine1
	):
		failures.append(
			"La introducción no abrió la cinemática del huracán después del panel final"
		)

	# La cinemática crea temporizadores al entrar; esperar permite que el árbol
	# procese su limpieza antes de terminar la prueba headless.
	await process_frame
	await process_frame

	if failures.is_empty():
		print("Validación de la introducción: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
