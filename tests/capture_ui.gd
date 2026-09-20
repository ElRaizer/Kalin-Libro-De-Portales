## Utilidad manual de QA visual. Renderiza escenas clave a 1280 × 720 y deja
## capturas en res://.ui-review/. No forma parte de la suite automatizada.
extends SceneTree

const OUTPUT_DIR := "res://.ui-review"

func _initialize() -> void:
	call_deferred("_capture_all")

func _capture_all() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture_scene("res://scenes/world4/Level4_YoQuiero.tscn", "world4.png")
	await _capture_book()
	await _capture_scene("res://scenes/world5/Level5_PortalDeRegreso.tscn", "world5.png")
	await _capture_completion()
	print("Capturas visuales creadas en %s" % OUTPUT_DIR)
	quit(0)

func _capture_scene(path: String, filename: String) -> void:
	var error := change_scene_to_file(path)
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
	var original_words: Dictionary = manager.words_learned.duplicate(true)
	manager.words_learned = {
		"Peek'": manager.VOCABULARY["Peek'"].duplicate(),
		"mayak": manager.VOCABULARY["mayak"].duplicate(),
		"ja'": manager.VOCABULARY["ja'"].duplicate(),
		"Yuum bo'otik": manager.VOCABULARY["Yuum bo'otik"].duplicate(),
	}
	var book := current_scene.get_node("LibroHechizos")
	book.show_book()
	await process_frame
	await RenderingServer.frame_post_draw
	_save_viewport("book.png")
	manager.words_learned = original_words

func _capture_completion() -> void:
	var completion := current_scene.get_node("UI/CompletionOverlay")
	completion.show_completion(
		"¡El Libro está completo!",
		"Kalin recordó sus hechizos, agradeció a sus amigos y abrió el portal.\nCada punto mágico cuenta la historia de lo que aprendiste.",
		"Cerrar la aventura"
	)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	_save_viewport("completion.png")

func _save_viewport(filename: String) -> void:
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	var error := image.save_png(path)
	if error != OK:
		push_error("No se pudo guardar la captura %s" % path)
