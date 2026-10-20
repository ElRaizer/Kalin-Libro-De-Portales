## Capturas de los estados de UX. Ejecutar con renderer real, sin --headless.
## godot --path . --script res://tests/capture_ux.gd -- [carpeta absoluta de salida]
extends SceneTree

var output := "res://.ui-review/ux"
var manager: Node

func _initialize() -> void:
	call_deferred("_run")

func _scene(key: String, filename: String) -> void:
	manager.scene_states.erase(key)
	change_scene_to_file(manager.SCENE_PATHS[key])
	await scene_changed
	await create_timer(0.7).timeout
	await _shot(filename)

func _shot(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output.path_join(filename + ".png"))
	if error != OK:
		push_error("No se pudo guardar " + filename)

func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	output = ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output)
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new(output.path_join("capture_progress.json"))
	manager.scene_states.clear()
	manager.tutorials_seen.clear()
	manager.completed_levels.clear()
	manager.words_learned.clear()
	manager.resume_scene_key = ""
	manager.magic_points = 0
	await _scene("main_menu", "menu")
	current_scene._on_reset_pressed()
	await create_timer(0.2).timeout
	await _shot("confirmacion")
	current_scene.reset_confirmation.hide()
	await _scene("intro", "intro")
	current_scene._finish_typewriter()
	await _shot("intro")
	if OS.get_cmdline_user_args().has("--quick"):
		print("Capturas de menú e introducción: " + output)
		quit()
		return
	await _scene("world1_level1", "tutorial_caminos")
	var board: GridBoard = current_scene.grid_board
	board._handle_press(board.words[0].start_cell)
	for column: int in range(1, board.words[0].destination_cell.x + 1):
		board._try_cell(Vector2i(column, 1))
	await create_timer(1.4).timeout
	await _shot("camino_recuperado")
	current_scene._close_dialogue()
	await _shot("caminos")
	var quiz := RecallCheck.new()
	current_scene.add_child(quiz)
	quiz.start(["Peek'", "Miis", "Kaax"])
	await _shot("repaso_animales")
	quiz.queue_free()
	await process_frame
	await _scene("world1_level3", "memoria_lista")
	current_scene._toggle_preview()
	await _shot("memoria_pistas")
	await _scene("world2_level1", "casa")
	current_scene._on_choice_pressed(current_scene._current_object().maya)
	await create_timer(0.6).timeout
	await _shot("casa_objeto")
	await _scene("world3_level1", "adjetivos")
	var challenge: ExerciseEntry = current_scene._current_challenge()
	current_scene._select_noun(challenge.noun)
	current_scene._select_adjective(challenge.adjective)
	current_scene._on_cast_pressed()
	await create_timer(0.6).timeout
	await _shot("objeto_a_medida")
	await _scene("world4_level1", "peticiones")
	current_scene._select_food("ja'")
	await _shot("agua_lista")
	current_scene._on_serve_pressed()
	await create_timer(0.4).timeout
	await _shot("entrega")
	current_scene.round_index = current_scene.CHALLENGES.size()
	current_scene._show_round()
	await _shot("peticion_recuerdo")
	await _scene("world5_level1", "portal")
	manager.words_learned = manager.VOCABULARY.duplicate(true)
	current_scene.libro.show_book()
	current_scene.libro._spread_index = 7
	current_scene.libro._render_spread()
	await _shot("libro")
	current_scene.libro.hide_book()
	manager.words_learned.clear()
	await _scene("world1_story1", "historia")
	current_scene._next_beat()
	current_scene._next_beat()
	current_scene._complete_text()
	await create_timer(0.7).timeout
	await _shot("conocer")
	await _scene("world1_explore1", "exploracion")
	await _gallery()
	print("Capturas UX: " + output)
	quit()

func _gallery() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	current_scene.add_child(canvas)
	var background := ColorRect.new()
	background.color = Color("f8f2dc")
	background.size = Vector2(1280, 720)
	canvas.add_child(background)
	var title := Label.new()
	title.text = "Kalin · Ilustraciones para aprender jugando"
	title.position = Vector2(32, 15)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("176b67"))
	canvas.add_child(title)
	var words: Array[String] = ["Peek'", "mayak", "lak", "ch'áak", "chan", "janal", "ja'", "ja'as", "pak'al", "K'úum", "mejen", "nojoch", "Jats'uts", "ki'", "jach'", "Bix a beel", "Yuum bo'otik", "Tak ti' uláak' k'iin"]
	for index: int in range(words.size()):
		var art := TextureRect.new()
		art.texture = load(manager.get_book_illustration(words[index]))
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.position = Vector2(25 + (index % 6) * 210, 62 + floori(float(index) / 6.0) * 210)
		art.size = Vector2(180, 155)
		canvas.add_child(art)
		var label := Label.new()
		label.text = words[index]
		label.position = art.position + Vector2(0, 156)
		label.size.x = 180
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("5b4630"))
		canvas.add_child(label)
	await _shot("ilustraciones")
