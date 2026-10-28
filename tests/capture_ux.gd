## Capturas de los estados de UX. Ejecutar con renderer real, sin --headless.
## godot --path . --script res://tests/capture_ux.gd -- [carpeta absoluta de salida]
extends SceneTree

var output: String = "res://.ui-review/ux"
var manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _scene(key: String, filename: String) -> void:
	manager.session.scene_states.erase(key)
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await create_timer(0.7).timeout
	await _shot(filename)


func _shot(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(output.path_join(filename + ".png"))
	if error != OK:
		push_error("No se pudo guardar " + filename)


func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	output = ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output)
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		output.path_join("capture_progress.json")
	)
	manager.session.scene_states.clear()
	manager.session.tutorials_seen.clear()
	manager.session.completed_levels.clear()
	manager.session.words_learned.clear()
	manager.session.resume_scene_key = ""
	manager.session.magic_points = 0
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
	await create_timer(0.15).timeout
	await _shot("camino_saltito")
	while current_scene._arrival_animating:
		await process_frame
	if current_scene._naming_pending:
		current_scene.recall.first.text = board.words[0].maya_word
		current_scene._submit_name()
	await _shot("camino_recuperado")
	current_scene._close_dialogue()
	await _shot("caminos")
	await _scene("world1_level3", "memoria_lista")
	current_scene._toggle_preview()
	await _shot("memoria_pistas")
	await _scene("world2_level1", "casa")
	current_scene._on_choice_pressed(current_scene._current_object().maya)
	await create_timer(0.6).timeout
	await _shot("casa_objeto")
	await create_timer(3.6).timeout
	await _shot("casa_continuar")
	current_scene._advance_round()
	for index: int in range(1, current_scene.total_rounds):
		current_scene._on_choice_pressed(current_scene._current_object().maya)
		current_scene._advance_round()
	await create_timer(0.4).timeout
	await _shot("casa_completada")
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
	await create_timer(3.8).timeout
	await _shot("peticion_continuar")
	current_scene.round_index = 2
	current_scene._show_round()
	current_scene._select_food("ich")
	await _shot("fruta_sin_tamano")
	current_scene._select_modifier("nojoch")
	await _shot("fruta_con_tamano")
	current_scene._select_modifier("")
	await _shot("fruta_tamano_retirado")
	current_scene.round_index = current_scene.challenges.size()
	current_scene._show_round()
	await _shot("peticion_recuerdo")
	await _scene("world5_level1", "portal")
	manager.session.words_learned = GameContent.VOCABULARY.duplicate(true)
	current_scene.libro.show_book()
	await current_scene.libro.motion.opened
	current_scene.libro._spread_index = 7
	current_scene.libro._render_spread()
	await _shot("libro")
	current_scene.libro.hide_book()
	await current_scene.libro.motion.closed
	manager.session.words_learned.clear()
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
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 30
	current_scene.add_child(canvas)
	var background: ColorRect = ColorRect.new()
	background.color = Color("f8f2dc")
	background.size = Vector2(1280, 720)
	canvas.add_child(background)
	var title: Label = Label.new()
	title.text = "Kalin · Ilustraciones para aprender jugando"
	title.position = Vector2(32, 15)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("176b67"))
	canvas.add_child(title)
	var words: Array[String] = [
		"Peek'",
		"mayak",
		"lak",
		"k'áan",
		"k'áanche'",
		"janal",
		"ja'",
		"ja'as",
		"ich",
		"K'úum",
		"mejen",
		"nojoch",
		"Jats'uts",
		"ki'",
		"chich",
		"Bix a beel",
		"Yuum bo'otik",
		"Tak ti' uláak' k'iin"
	]
	for index: int in range(words.size()):
		var art: TextureRect = TextureRect.new()
		art.texture = load(manager.get_book_illustration(words[index]))
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.position = Vector2(25 + (index % 6) * 210, 62 + floori(float(index) / 6.0) * 210)
		art.size = Vector2(180, 155)
		canvas.add_child(art)
		var label: Label = Label.new()
		label.text = words[index]
		label.position = art.position + Vector2(0, 156)
		label.size.x = 180
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color("5b4630"))
		canvas.add_child(label)
	await _shot("ilustraciones")
