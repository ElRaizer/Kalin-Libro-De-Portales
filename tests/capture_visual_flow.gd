## Capturas del flujo final. Acepta una carpeta de salida después de --.
extends "res://tests/capture_ux.gd"

func _run() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	output = ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output)
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new(output.path_join("capture_progress.json"))
	manager.scene_states.clear()
	manager.completed_levels.clear()
	manager.words_learned.clear()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	manager.resume_scene_key = ""
	await _scene("main_menu", "01_mapa")
	await _scene("intro", "02_intro")
	current_scene._finish_typewriter()
	await _shot("02_intro")
	if OS.get_cmdline_user_args().has("--quick"):
		await _scene("world3_level1", "06_taller")
		manager.words_learned = manager.VOCABULARY.duplicate(true)
		current_scene.libro._new_word = ""
		current_scene.libro.show_book()
		await current_scene.libro.motion.opened
		current_scene.libro._select_category(3)
		while current_scene.libro._turning:
			await process_frame
		await _shot("21_libro")
		current_scene.libro.hide_book()
		await current_scene.libro.motion.closed
		quit()
		return
	await _scene("world1_level1", "03_camino")
	await _scene("world1_level2", "04_casas_palabras")
	await _scene("world2_level1", "05_casa")
	await _scene("world3_level1", "06_taller")
	current_scene._show_help()
	await _shot("07_pista")
	current_scene._select_noun("mayak")
	current_scene._select_adjective("mejen")
	current_scene._on_cast_pressed()
	await create_timer(0.5).timeout
	await _shot("08_error_comparacion")
	var challenge: ExerciseEntry = current_scene._current_challenge()
	current_scene._select_noun(challenge.noun)
	current_scene._select_adjective(challenge.adjective)
	current_scene._on_cast_pressed()
	await create_timer(0.5).timeout
	await _shot("09_objeto_creado")
	current_scene.round_index = 3
	current_scene._show_round()
	await create_timer(0.9).timeout
	await _shot("10_bloque")
	current_scene.mission_break._continue()
	current_scene.round_index = 7
	current_scene._show_round()
	await _shot("11_apoyo_intermedio")
	current_scene.round_index = 10
	current_scene._show_round()
	await _shot("12_recuerdo")
	await _scene("world4_level1", "13_comida")
	current_scene.round_index = 1
	current_scene._show_round()
	current_scene._select_food("ja'as")
	await _shot("14_tamano")
	await _scene("world5_level1", "15_portal")
	for index: int in range(4):
		current_scene._on_option_pressed(current_scene.challenges[index].correct)
		current_scene._advance_challenge()
	await create_timer(0.7).timeout
	await _shot("16_portal_energia")
	for entry: Array in [["world1_story1", "17_camino_roto"], ["world2_story1", "18_mesa_pequena"], ["world3_story1", "19_hambre"], ["world4_story1", "20_portal_historia"]]:
		await _scene(entry[0], "temporal")
		while current_scene.current_beat().kind != StoryBeat.Kind.EXPLORAR:
			current_scene._next_beat()
		current_scene._complete_text()
		await create_timer(0.9).timeout
		await _shot(entry[1])
	await _scene("main_menu", "temporal")
	manager.words_learned = manager.VOCABULARY.duplicate(true)
	current_scene.libro._new_word = ""
	current_scene.libro.show_book()
	await current_scene.libro.motion.opened
	current_scene.libro._select_category(3)
	while current_scene.libro._turning:
		await process_frame
	await _shot("21_libro")
	current_scene.libro.hide_book()
	await current_scene.libro.motion.closed
	await _scene("world3_level1", "temporal")
	root.get_node("PauseMenu").open_pause()
	await _shot("22_pausa")
	root.get_node("PauseMenu").resume_game()
	print("Capturas de la revisión visual: " + output)
	quit()
