## Utilidad manual de QA visual. Renderiza escenas clave a 1280 × 720 y deja
## capturas en res://.ui-review/. No forma parte de la suite automatizada.
extends SceneTree

const OUTPUT_DIR := "res://.ui-review"


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	var manager: Node = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		"user://capture_validation_progress.json"
	)
	manager.session.scene_states.clear()
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture_scene(
		"res://scenes/worlds/world1/exploracion1_orilla_isla.tscn", "exploracion.png"
	)
	await _capture_scene("res://scenes/worlds/world4/level4_yo_quiero.tscn", "world4.png")
	await _capture_book()
	await _capture_scene("res://scenes/worlds/world5/level5_portal_de_regreso.tscn", "world5.png")
	await _capture_completion()
	print("Capturas visuales creadas en %s" % OUTPUT_DIR)
	quit(0)


func _capture_scene(path: String, filename: String) -> void:
	var error: Error = change_scene_to_file(path)
	if error != OK:
		push_error("No se pudo abrir %s" % path)
		return
	await scene_changed
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_save_viewport(filename)


func _capture_book() -> void:
	var manager: Node = root.get_node("GameManager")
	var original_words: Dictionary = manager.session.words_learned.duplicate(true)
	manager.session.words_learned = {
		"Peek'": GameContent.VOCABULARY["Peek'"].duplicate(),
		"mayak": GameContent.VOCABULARY["mayak"].duplicate(),
		"ja'": GameContent.VOCABULARY["ja'"].duplicate(),
		"Yuum bo'otik": GameContent.VOCABULARY["Yuum bo'otik"].duplicate(),
	}
	var book: Node = current_scene.get_node("LibroHechizos")
	book.show_book()
	await book.motion.opened
	await process_frame
	await RenderingServer.frame_post_draw
	_save_viewport("book.png")
	manager.session.words_learned = original_words


func _capture_completion() -> void:
	var completion: Node = current_scene.get_node("UI/CompletionOverlay")
	(
		completion
		. show_completion(
			"¡El Libro está completo!",
			"Kalin recordó sus hechizos, agradeció a sus amigos y abrió el portal.\nCada punto mágico cuenta la historia de lo que aprendiste.",
			"Cerrar la aventura"
		)
	)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	_save_viewport("completion.png")


func _save_viewport(filename: String) -> void:
	var image: Image = root.get_texture().get_image()
	var path: String = ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("No se pudo guardar la captura %s" % path)
