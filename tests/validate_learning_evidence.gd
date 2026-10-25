## Evidencia pedagógica, entrada libre, migración y misión con entrega real.
## --capture=<carpeta> permite inspeccionar los mismos estados con renderer real.
extends SceneTree

var manager: Node
var failures: Array[String] = []
var capture_folder := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _scene(key: String, fresh: bool = true) -> void:
	if fresh:
		manager.scene_states.erase(key)
	change_scene_to_file(manager.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame

func _capture(name: String) -> void:
	if capture_folder.is_empty():
		return
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_folder.path_join(name + ".png"))

func _close_dialogue(scene: Node) -> void:
	for step: int in range(8):
		if not scene.is_dialogue_open():
			break
		scene.advance_dialogue()

func _click(button: Button) -> void:
	await process_frame
	await process_frame
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = button.get_global_rect().get_center()
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://learning_evidence_validation.json")
	manager.reset_save()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	_model()
	_sources()
	await _recall_inputs()
	await _mission()
	await _intro_keyboard()
	_migration_and_backup()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("OK: descubrimiento, práctica, recuerdo espaciado, entradas libres, guardado y encargos en el mundo.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _model() -> void:
	manager.learn_word("mayak")
	_check(manager.learning_caption("mayak").begins_with("Descubierta"), "Descubrir no debe acreditar práctica ni recuerdo")
	manager.record_learning(["mayak"], "practice", "practice@1", true)
	_check(manager.learning_progress.mayak.recalls.is_empty(), "Copiar un dibujo no acredita recuerdo")
	manager.record_learning(["mayak"], "recall", "house@1")
	_check(manager.learning_progress.mayak.recalls.size() == 1, "Un primer recuerdo debe quedar identificado como primero")
	var clock: int = manager.learning_clock
	for index: int in range(8):
		manager.record_learning(["mayak"], "recall", "house@1")
	_check(manager.learning_clock == clock and manager.learning_progress.mayak.recalls.size() == 1, "Reemitir o restaurar un resultado no crea tiempo ni evidencias")
	manager.record_learning(["lak"], "practice", "between1")
	manager.record_learning(["ja'"], "practice", "between2")
	manager.record_learning(["mayak"], "recall", "village@1")
	_check(manager.learning_progress.mayak.recalls.size() == 2, "Dos contextos separados por otros ejercicios permiten registrar recuerdo")
	manager.record_learning(["ja'"], "recall", "with_book", true)
	_check(manager.learning_progress["ja'"].recalls.is_empty(), "Consultar el libro no debe contar como recuerdo independiente")
	_check(RecallPanel.match_word("K’ÁANCHE’", "k'áanche'").correct, "Aceptar mayúsculas y apóstrofos tipográficos")
	_check(RecallPanel.match_word("k'aanche'", "k'áanche'").supported, "La corrección de acentos debe identificarse como apoyo")
	_check(not RecallPanel.match_word("chan", "k'áanche'").correct, "No aceptar la traducción retirada como respuesta válida")
	_check(not RecallPanel.match_word("kaan", "k'áan").correct, "No ignorar el cierre glotal de la palabra")

func _sources() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/vocabulary_sources.json"))
	for word: String in manager.VOCABULARY:
		_check(manifest.entries.has(word) and str(manifest.entries[word].url).begins_with("https://"), "Cada palabra debe tener su referencia documental: " + word)
	for retired: String in ["chan", "ch'áak", "pak'al", "jach'"]:
		_check(retired not in manager.VOCABULARY, "Las asociaciones retiradas no deben seguir enseñándose")
	_check(manifest.speaker_review_pending and manifest.pronunciation_pending, "El cotejo documental no debe presentarse como validación oral")

func _recall_inputs() -> void:
	await _scene("world3_level1")
	var level := current_scene
	level.round_index = level.challenges.size() + 3
	level._show_round()
	level.mission_break.hide()
	var task: ExerciseEntry = level._current_challenge()
	_check(level.recall.visible and not level.target_art.visible, "El recuerdo del taller debe retirar tarjetas y dibujo de la solución")
	level.recall.first.text = task.noun
	level.recall.second.text = task.adjective
	_check(not level.result_art.visible, "Escribir no debe revelar una ilustración que permita comparar sin recordar")
	await _capture("01_recuerdo_taller")
	level._on_cast_pressed()
	_check(level._awaiting_continue and manager.learning_progress[task.noun].recalls.size() >= 1, "El recuerdo escrito correcto debe avanzar y producir evidencia")
	level.round_index += 1
	level._show_round()
	task = level._current_challenge()
	level.recall.first.text = "may"
	level.libro.show_book()
	level.libro.hide_book()
	await level.libro.motion.closed
	manager.checkpoint(level)
	manager.scene_states.clear()
	manager._load_save()
	await _scene("world3_level1", false)
	level = current_scene
	_check(level._attempt.supported and level.recall.visible and level.recall.first.text == "may", "Reanudar conserva la consulta al libro, el modo y el texto parcial")
	level.recall.practice_requested.emit()
	_check(not level.recall.visible and level.target_art.visible and level._attempt.supported, "Volver a las tarjetas debe ser práctica con apoyo")
	await _scene("world4_level1")
	level = current_scene
	level.round_index = level.challenges.size()
	level._show_round()
	level.mission_break.hide()
	task = level._current_challenge()
	_check(level.recall.visible and not level.visual_clue.visible, "Las peticiones de recuerdo no deben dar dibujos de solución")
	level.recall.first.text = task.food
	level.recall.second.text = task.modifier
	level._on_serve_pressed()
	_check(level._awaiting_continue, "La petición puede resolverse mediante escritura")
	await _scene("world2_level1")
	level = current_scene
	level.round_index = level.objects.size()
	level._show_round()
	level.mission_break.hide()
	_check(level.recall.visible and not level.choices_grid.visible and not level.request_art.visible, "Casa: recuerdo sin opciones ni imágenes de solución")
	level.recall.first.text = level._current_object().maya
	await _click(level.recall.get_node("Margin/Content/Actions/Submit"))
	_check(level._waiting, "Casa: la respuesta escrita resuelve la petición")
	# Cambian las posiciones entre rondas, pero se conservan al reanudar.
	await _scene("world3_level1")
	level = current_scene
	var positions: Array[String] = []
	for index: int in range(4):
		level.round_index = index
		level._show_round()
		var order := ""
		for button: Node in level.noun_grid.get_children():
			order += str(button.word_value) + "/"
		positions.append(order)
	_check(positions.any(func(value: String): return value != positions[0]), "Las tarjetas no deben conservar el mismo orden en todas las rondas")
	manager.checkpoint(level)
	var before := positions[-1]
	await _scene("world3_level1", false)
	var after := ""
	for button: Node in current_scene.noun_grid.get_children():
		after += str(button.word_value) + "/"
	_check(before == after, "Reanudar no debe cambiar las tarjetas del intento")

func _mission() -> void:
	await _scene("world4_mission1")
	var mission: Node = current_scene
	_close_dialogue(mission)
	var bench := mission.get_node("Spots/Workbench") as ExplorationSpot
	var first := mission.get_node("Spots/Recipient0") as ExplorationSpot
	var task: VillageTask = mission.tasks[mission.task_indices[0]]
	mission._place_kalin(first.position.x)
	mission.open_spot(first)
	_close_dialogue(mission)
	_check(0 in mission.met, "La misión exige escuchar el encargo")
	mission._place_kalin(bench.position.x)
	mission.open_spot(bench)
	mission.recall.first.text = "ich" if task.item != "ich" else "mayak"
	mission.recall.second.text = task.quality
	mission._forge()
	_check(mission.carried.is_empty() and mission.delivered.is_empty() and mission.recall.mode == RecallPanel.Mode.CLOZE, "Un encargo escrito incorrectamente ofrece completar antes de crearlo")
	# Un objeto incorrecto procedente de un guardado anterior también debe
	# poder corregirse sin acreditar recuerdo ni permitir entregar a distancia.
	mission.carried = {"item": "ich" if task.item != "ich" else "mayak", "quality": "", "supported": true, "mistakes": 1, "phase": "recall"}
	mission._close_workbench()
	mission._update_carried()
	mission.open_spot(first)
	_check(mission.delivered.is_empty(), "No se puede entregar a distancia")
	mission._place_kalin(first.position.x)
	mission.open_spot(first)
	_close_dialogue(mission)
	_check(mission.carried.supported and mission.delivered.is_empty(), "La entrega equivocada debe enseñar y permitir corregir sin acreditar recuerdo")
	manager.checkpoint(mission)
	manager.scene_states.clear()
	manager._load_save()
	await _scene("world4_mission1", false)
	mission = current_scene
	_close_dialogue(mission)
	_check(not mission.carried.is_empty() and mission.carried.supported, "Continuar conserva lo que Kalin lleva y los errores de entrega")
	for index: int in range(3):
		var recipient := mission.get_node("Spots/Recipient%d" % index) as ExplorationSpot
		bench = mission.get_node("Spots/Workbench")
		task = mission.tasks[mission.task_indices[index]]
		mission.carried.clear()
		mission._place_kalin(recipient.position.x)
		mission.open_spot(recipient)
		_close_dialogue(mission)
		mission._place_kalin(bench.position.x)
		mission.open_spot(bench)
		mission.recall.first.text = task.item
		mission.recall.second.text = task.quality
		if index == 0:
			await _capture("02_taller_aldea")
		mission._forge()
		_check(mission.delivered.size() == index and mission.carried_art.visible, "El hechizo crea un objeto transportable, no una entrega automática")
		mission._place_kalin(recipient.position.x - 80)
		mission.camera.reset_smoothing()
		if index == 0:
			await _capture("03_llevar_encargo")
		mission.open_spot(recipient)
		_close_dialogue(mission)
		_check(index in mission.delivered and mission.carried.is_empty(), "El encargo se completa al entregar el objeto correcto al personaje correcto")
		if index == 0:
			manager.checkpoint(mission)
			await _scene("world4_mission1", false)
			mission = current_scene
			_close_dialogue(mission)
			_check(0 in mission.delivered, "Las entregas y los objetos colocados se conservan al continuar")
	await _capture("04_aldea_resuelta")
	var goal := mission.get_node("Spots/Salida") as ExplorationSpot
	mission._place_kalin(goal.position.x)
	mission.open_spot(goal)
	_close_dialogue(mission)
	await create_timer(0.8).timeout
	_check(current_scene.scene_file_path == manager.SCENE_PATHS.world5_level1, "La misión debe continuar hacia el portal")
	await _capture("05_portal_recuerdo")

func _intro_keyboard() -> void:
	for path: String in ["UI/SkipBtn", "UI/MenuButton"]:
		await _scene("intro")
		await create_timer(0.4).timeout
		current_scene._finish_typewriter()
		current_scene.get_node(path).grab_focus()
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.pressed = true
		root.push_input(event, true)
		await process_frame
		await process_frame
		var expected: String = manager.SCENE_PATHS.world1_explore1 if path.ends_with("SkipBtn") else manager.SCENE_PATHS.main_menu
		_check(current_scene.scene_file_path == expected, "Enter debe activar el botón enfocado en la introducción")
		event = InputEventKey.new()
		event.keycode = KEY_ENTER
		root.push_input(event, true)

func _migration_and_backup() -> void:
	var legacy := {"version": 2, "words_learned": {"chan": {}, "jach'": {}, "pak'al": {}, "ch'áak": {}}, "completed_levels": ["w2_l1"], "magic_points": 100}
	var file := FileAccess.open(manager._save_repository.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	manager._load_save()
	_check(manager.words_learned.has_all(["k'áanche'", "chich", "ich", "k'áan"]) and manager.is_level_completed(2, 1), "Migrar los IDs retirados conserva páginas y niveles")
	_check(manager.learning_progress.is_empty(), "Una partida antigua no debe inventar evidencias de recuerdo")
	manager._save()
	manager._save()
	file = FileAccess.open(manager._save_repository.save_path, FileAccess.WRITE)
	file.store_string("{archivo interrumpido")
	file.close()
	_check(not manager._save_repository.load_progress().has("_load_error"), "Un guardado interrumpido debe recuperar el respaldo")
