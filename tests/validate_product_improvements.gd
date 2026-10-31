## Evidencia por palabra, orientación, interpretación y actividades de la aldea.
## Con renderer real admite --capture=<carpeta>, igual que las suites de autoría.
extends "res://tests/validate_game_expansion.gd"


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://product_improvements_validation.json"))
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	_model_boundaries()
	await _word_evidence()
	await _reading_requests()
	await _laboratory_and_gathering()
	await _book_detail()
	await process_frame
	if failures.is_empty():
		print(
			"OK: orientación, evidencia por palabra, lectura, laboratorio y celebración persistentes."
		)
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _model_boundaries() -> void:
	var attempt: LearningAttempt = LearningAttempt.new()
	attempt.restore(
		{
			"word_evidence":
			{
				"mayak":
				{"phase": "recall", "supported": "false", "spelling": false, "mistakes": 0},
				"lak": {"phase": "recall", "supported": false, "spelling": false, "mistakes": 0.5}
			}
		}
	)
	_check(
		attempt.word_evidence.is_empty(),
		"No aceptar evidencia anidada de tipos o enteros inválidos"
	)
	var state: VillageMissionState = VillageMissionState.new()
	state.restore({"carried": {}, "drafts": [], "task_support": false}, ["mayak"], [""])
	_check(
		state.carried.is_empty() and state.drafts.is_empty(),
		"Un objeto vacío no causa errores del motor"
	)
	state.restore({"carried": {"item": "mayak", "quality": "", "phase": []}}, ["mayak"], [""])
	_check(state.carried.phase == "recall", "El tipo de fase se comprueba antes de compararlo")
	state.met.append(0)
	var snapshot: Dictionary = state.snapshot()
	snapshot.mission_met.clear()
	_check(state.met == [0], "La instantánea de encargos es independiente")
	var progress: Dictionary = LearningProgress.empty_record()
	var malformed: Dictionary = LearningProgress.sanitize(
		{"recent": [{"support": 0.5, "errors": 0}, {"support": 0, "errors": -1}]}
	)
	_check(malformed.recent.is_empty(), "Los resultados recientes requieren enteros en rango")
	LearningProgress.record_result(progress, "recognition", "read@1", false, 0, 1)
	_check(
		progress.recognition == 1 and progress.recalls.is_empty(),
		"Comprender no acredita escritura"
	)
	LearningProgress.record_result(progress, "experiment", "lab@1", true, 0, 2)
	LearningProgress.record_result(progress, "practice", "copy@1", true, 0, 3)
	_check(
		progress.recognition == 1, "Copiar una palabra mostrada no se presenta como reconocimiento"
	)
	_check(
		progress.experimentation == 1 and progress.writing == 0,
		"Experimentar es práctica diferenciada"
	)


func _word_evidence() -> void:
	var scene: Node = await _scene("world3_level1", PhraseExerciseFixture.recall_state(741))
	scene.mission_break.hide()
	scene._show_help()
	_check(
		scene._attempt.guidance and not scene._attempt.supported,
		"Explicar los controles no revela contenido"
	)
	var challenge: ExerciseEntry = scene._current_challenge()
	scene.recall.first.text = "incorrecto"
	scene.recall.second.text = challenge.adjective
	scene._on_cast_pressed()
	_check(scene.recall.mode == RecallPanel.Mode.CLOZE, "El error conserva el apoyo automático")
	var key: String = challenge.adjective
	scene = await _resume("world3_level1")
	scene.mission_break.hide()
	challenge = scene._current_challenge()
	_check(scene.recall.second.text == key, "La parte correcta y su evidencia sobreviven a JSON")
	scene.recall.first.text = challenge.noun
	scene._on_cast_pressed()
	var noun: Dictionary = manager.learning_record(challenge.noun)
	var adjective: Dictionary = manager.learning_record(challenge.adjective)
	_check(
		noun.reconstruction == 1 and noun.writing == 0,
		"La palabra corregida registra reconstrucción"
	)
	_check(
		adjective.writing == 1 and adjective.guidance == 1,
		"La palabra acertada conserva escritura independiente"
	)
	var before: Dictionary = manager.learning_record(challenge.adjective)
	scene = await _resume("world3_level1")
	_check(
		manager.learning_record(challenge.adjective) == before,
		"Reabrir el resultado no acredita otra vez"
	)
	for world: int in [3, 4]:
		for compact: bool in [false, true]:
			root.size = Vector2i(640, 360) if compact else Vector2i(1280, 720)
			scene = await _scene("world%d_level1" % world, PhraseExerciseFixture.recall_state(743))
			scene.mission_break.hide()
			scene.get_node("ScreenLayout").preview_compact = compact
			scene.get_node("ScreenLayout").refresh()
			await process_frame
			await process_frame
			var card: Control = scene.get_node("UI/ChoicesPanel")
			_check(
				is_equal_approx(card.size.y, 268.0 if scene.recall.second_box.visible else 190.0),
				"La altura de recuerdo procede del perfil y se adapta a una o dos palabras"
			)
			_check(
				card.get_global_rect().encloses(scene.recall.get_global_rect()),
				"La respuesta cabe dentro de su tarjeta"
			)
			_check(
				Rect2(0, 0, 1280, 720).encloses(scene.recall.get_global_rect()),
				"Los campos caben en ambos perfiles"
			)
			await _capture("recuerdo_%d_%s" % [world, "compacto" if compact else "escritorio"])
			scene.recall.advance_support()
			scene.recall.advance_support()
			await process_frame
			var bank: Control = scene.recall.get_node("Margin/Content/Blocks/Bank")
			_check(
				scene.recall.get_global_rect().encloses(bank.get_global_rect()),
				"Los bloques caben en el panel"
			)
			await _capture("bloques_%d_%s" % [world, "compacto" if compact else "escritorio"])
	root.size = Vector2i(1280, 720)


func _reading_requests() -> void:
	var scene: Node = await _scene("world3_explore1", {"intro_done": true, "layout_seed": 84})
	_close_lines(scene)
	scene._show_choices(0)
	var task: VillageTask = scene.encounters[0].task
	_check(
		scene.get_node("UI/ChoiceRequest/Request").text.contains(task.item),
		"La petición usa las fichas conocidas"
	)
	await _capture("interpretar_sin_traduccion")
	scene._translate_request()
	scene = await _resume("world3_explore1")
	_check(scene.translated == [0], "La consulta de traducción persiste")
	_check(
		scene.helped.is_empty(),
		"Reanudar no revela la solución ni registra una ayuda no solicitada"
	)
	var correct: int = -1
	for index: int in range(3):
		var entry: ExerciseEntry = scene.encounters[0].choices[scene._choice_order[index]]
		if (
			entry.noun == scene.encounters[0].task.item
			and entry.adjective == scene.encounters[0].task.quality
		):
			correct = index
	_check(correct >= 0, "La interpretación tiene una respuesta visual válida")
	await _capture("interpretar_peticion")
	scene._choose(correct)
	var record: Dictionary = manager.learning_record(task.item)
	_check(
		record.recognition > 0 and scene.solved == [0],
		"Interpretar resuelve el paseo y registra reconocimiento"
	)


func _laboratory_and_gathering() -> void:
	for word: String in ["mayak", "nojoch", "Miis", "Peek'", "Áak"]:
		manager.learn_word(word)
	var home: Node = await _scene("village_home", {})
	var laboratory: Node = home.get_node("SpellLaboratory")
	var origin: Button = home.return_button
	origin.grab_focus()
	laboratory.open_lab(origin)
	_check(paused and laboratory.visible, "El laboratorio pausa el mundo")
	var selected: String = str(laboratory.qualities.get_item_metadata(0))
	_check(CombinationCatalog.allowed(selected), "El laboratorio sólo usa combinaciones válidas")
	laboratory.create_spell()
	await create_timer(0.7).timeout
	_check(laboratory.result.visible, "La creación termina y revela el resultado")
	var word: String = selected.get_slice("|", 0)
	var record: Dictionary = manager.learning_record(word)
	var count: int = record.experimentation
	laboratory.create_spell()
	await create_timer(0.7).timeout
	_check(
		manager.learning_record(word).experimentation == count,
		"Recrear lo mismo no multiplica la práctica"
	)
	_check(
		manager.saved_scene_state("world3_mission1").get("delivered", []).is_empty(),
		"Experimentar no completa encargos"
	)
	await _capture("laboratorio")
	laboratory.close_lab()
	_check(not paused and origin.has_focus(), "Cerrar recupera pausa y foco")
	var scene: Node = await _scene("world3_mission1", {"intro_done": true, "layout_seed": 87})
	_close_lines(scene)
	scene.active_task = 0
	scene.met.append(0)
	var book: Node = scene.get_node("LibroHechizos")
	book.show_book(scene.get_node("UI/BookButton"))
	await create_timer(0.5).timeout
	book.hide_book()
	await create_timer(0.5).timeout
	scene._open_workbench()
	_check(
		scene._workbench_attempt.content_help,
		"El libro consultado durante un encargo cuenta como apoyo"
	)
	scene._close_workbench()
	var completed: Array[VillageTask] = []
	for index: int in range(3):
		completed.append(scene.tasks[scene.task_indices[index]])
	scene.delivered.assign([0, 1, 2])
	scene._show_gathering()
	_check(
		scene.gathering.visible and not scene._can_walk(),
		"La celebración reúne los encargos y detiene el movimiento"
	)
	await _capture("celebracion")
	scene.gathering.close_gathering()
	scene = await _resume("world3_mission1")
	_check(
		scene.gathering_seen and not scene.gathering.visible,
		"Continuar no repite una celebración cerrada"
	)


func _book_detail() -> void:
	var scene: Node = await _scene("world3_level1")
	scene.libro.show_book(scene.get_node("UI/TopBar/Bar/BookButton"))
	await scene.libro.motion.opened
	var page: Panel = scene.libro.left_page
	page.get_node("Content/PracticeButton").pressed.emit()
	_check(
		page.get_node("Content/DiagramLabel").visible, "El detalle se abre con un botón accesible"
	)
	_check(
		page.get_node("Content/DiagramLabel").text.contains("Orientación"),
		"El libro distingue manejo y contenido"
	)
	await _capture("libro_practica")
	scene.libro.hide_book()
	await scene.libro.motion.closed
	_check(not paused, "El nuevo detalle conserva el cierre del libro")
