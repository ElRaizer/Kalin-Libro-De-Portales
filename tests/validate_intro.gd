extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var error: Error = change_scene_to_file("res://scenes/Intro.tscn")
	if error != OK:
		push_error("No se pudo cargar la introducción para la prueba")
		quit(1)
		return

	await scene_changed
	var intro: Node = current_scene
	intro.set("panel_index", 7)
	intro.set("is_animating", false)
	intro.set("text_revealed", true)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	intro.call("_input", click)

	await scene_changed
	if current_scene == null or current_scene.scene_file_path != GameManager.SCENE_PATHS.world1_level1:
		failures.append("La introducción no abrió el primer nivel después del panel final")

	if failures.is_empty():
		print("Validación de la introducción: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
