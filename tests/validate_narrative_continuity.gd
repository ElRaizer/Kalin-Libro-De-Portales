## Recuerdos vividos, despedida expresiva y lectura de cinemáticas a tu ritmo.
extends "res://tests/validate_game_expansion.gd"


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_folder = argument.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://narrative_continuity.json"))
	manager.reset_save()
	var preferences: Node = root.get_node("AccessibilityManager")
	var previous_preferences: Dictionary[String, bool] = {}
	for key: String in preferences.PREFERENCE_KEYS:
		previous_preferences[key] = preferences.get(key)
	_memories_only_from_deliveries()
	await _expressive_farewell()
	await _cinematic_reading()
	await _comfort_layouts()
	for key: String in previous_preferences:
		preferences.set_preference(key, previous_preferences[key])
	if failures.is_empty():
		print("OK: recuerdos de entregas reales, despedida libre, lectura manual y reanudación.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _visits() -> Array[Dictionary]:
	return [
		{
			"delivered": [1],
			"combination_tasks": ["k'áan|", "k'áanche'|", "lak|"],
			"residents": ["Peek'", "Miis", "Kaax"]
		},
		{
			"delivered": [2],
			"combination_tasks": ["k'áan|mejen", "mayak|nojoch", "lak|Jats'uts"],
			"residents": ["Peek'", "Áak", "Kaax"]
		},
		{}
	]


func _memories_only_from_deliveries() -> void:
	var visits: Array[Dictionary] = _visits()
	var cat: Dictionary = VillageMemory.for_animal(visits, "Miis")
	_check(
		cat.get("item") == "k'áanche'", "Miis recuerda su silla entregada, no la hamaca pendiente"
	)
	_check(
		VillageMemory.for_animal(visits, "Peek'").is_empty(),
		"Un pedido sin entregar no se convierte en recuerdo de Peek'"
	)
	_check(
		VillageMemory.for_animal(visits, "Kaax").get("quality") == "Jats'uts",
		"El recuerdo conserva la cualidad realmente entregada a Kaax"
	)
	cat.item = "k'áan"
	_check(
		VillageMemory.for_animal(visits, "Miis").item == "k'áanche'",
		"Editar la imagen de un recuerdo no altera el historial de entregas"
	)
	var invalid: Array[Dictionary] = [
		{"delivered": [0], "combination_tasks": [[]], "residents": ["Miis"]},
		{"delivered": [0], "combination_tasks": ["mayak|nojoch"], "residents": [{}]},
		{"delivered": [2], "combination_tasks": ["lak|"], "residents": ["Miis"]}
	]
	_check(
		VillageMemory.for_animal(invalid, "Miis").is_empty(),
		"Datos anidados inválidos no inventan recuerdos ni interrumpen la despedida"
	)


func _expressive_farewell() -> void:
	var visits: Array[Dictionary] = _visits()
	for index: int in range(visits.size()):
		manager.session.scene_states["world%d_mission1" % (index + 2)] = visits[index]
	var farewell: Node = await _scene("world5_farewell", {"intro_done": true})
	_check(
		(
			farewell._friend_memories[1].contains("Silla")
			and not farewell._friend_memories[1].to_lower().contains("hamaca")
		),
		"La despedida de Miis describe la entrega de esta partida"
	)
	var authored: Node = load(GameContent.SCENE_PATHS.world5_farewell).instantiate()
	_check(
		farewell.gifts[1].translation == authored.gifts[1].translation,
		"El recuerdo no modifica el recurso de autor"
	)
	authored.free()
	_approach_spot(farewell, farewell.get_node("Spots/Friend1"))
	farewell._show_choices(1)
	var different: int = 0
	if farewell._choices[different] == farewell.gifts[1].correct:
		different = 1
	var phrase: String = farewell._choices[different]
	_check(
		(
			(farewell.get_node("UI/FarewellChoices/Options").get_child(different) as Button)
			. text
			. contains(str(VocabularyCatalog.entry(phrase).spanish))
		),
		"La expresión elegida muestra su significado antes de despedirse"
	)
	farewell._choose(different)
	_check(
		farewell._dialogue.lines[1] == farewell.gifts[1].translation,
		"El recuerdo de una entrega conserva también el deseo de buen viaje del amigo"
	)
	_check(
		1 in farewell.collected and not farewell.choices_panel.visible,
		"Una expresión distinta también permite compartir la despedida, sin otro examen"
	)
	var record: Dictionary = manager.learning_record(phrase)
	_check(
		record.practice == 1 and record.recalls.is_empty() and record.errors == 0,
		"La elección cuenta sólo como práctica apoyada, sin errores ni recuerdo acreditado"
	)
	farewell.advance_dialogue()
	if farewell._dialogue.line_index == 0:
		farewell.advance_dialogue()
	var line: int = farewell._dialogue.line_index
	var dialogue_lines: Array[String] = farewell._dialogue.lines.duplicate()
	var before: Dictionary = manager.session.learning_progress.duplicate(true)
	farewell = await _resume("world5_farewell")
	_check(
		farewell.is_dialogue_open() and farewell._dialogue.line_index == line,
		"Reanudar conserva el momento abierto de la despedida"
	)
	_check(
		farewell._dialogue.lines == dialogue_lines,
		"Reanudar conserva el recuerdo vivido y las líneas de la conversación"
	)
	_check(
		manager.session.learning_progress == before,
		"Reanudar no acredita de nuevo la expresión elegida"
	)
	_close_lines(farewell)
	await _capture("despedida_vivida")
	manager.session.scene_states["world2_mission1"] = {}
	farewell = await _scene("world5_farewell", {"intro_done": true})
	_check(
		farewell._friend_memories[1] == farewell.gifts[1].translation,
		"Sin una entrega a Miis se conserva el texto de autor sin inventar un objeto"
	)


func _cinematic_reading() -> void:
	var preferences: Node = root.get_node("AccessibilityManager")
	_check(preferences.manual_cinematics, "Las cinemáticas esperan al lector por defecto")
	preferences.instant_text = true
	var story: Node = await _scene("world1_cine1", {"beat": 1})
	_check(story.auto_timer.is_stopped(), "Un momento automático espera con lectura manual")
	var initial: int = story.beat_index
	story._on_auto_timer_timeout()
	_check(story.beat_index == initial, "Un timeout pendiente no salta una lectura manual")
	preferences.set_preference("manual_cinematics", false)
	_check(not story.auto_timer.is_stopped(), "El avance automático sigue disponible al elegirlo")
	var pause: Node = root.get_node("PauseMenu")
	pause.open_pause()
	var remaining: float = story.auto_timer.time_left
	await create_timer(0.2).timeout
	_check(
		is_equal_approx(story.auto_timer.time_left, remaining),
		"La pausa conserva el tiempo restante de la cinemática"
	)
	var manual_button: CheckButton = pause.get_node("Shade/Panel/ManualCinematics")
	manual_button.button_pressed = true
	_check(story.auto_timer.is_stopped(), "Activar lectura manual en pausa cancela el timer")
	pause.resume_game()
	_check(story.beat_index == initial, "Cerrar opciones conserva el mismo momento narrativo")
	preferences.set_preference("manual_cinematics", false)
	story._complete_text()
	story._on_auto_timer_timeout()
	_check(story.beat_index == initial + 1, "La opción automática avanza al siguiente momento")
	preferences.set_preference("manual_cinematics", true)
	var stored: ConfigFile = ConfigFile.new()
	_check(
		(
			stored.load(preferences.PREFERENCES_PATH) == OK
			and stored.get_value("comfort", "manual_cinematics", false) == true
		),
		"La lectura manual se guarda en preferencias, fuera de la partida"
	)
	initial = story.beat_index
	story = await _resume("world1_cine1")
	_check(
		story.beat_index == initial and story.auto_timer.is_stopped(),
		"Reanudar respeta el momento guardado y la lectura manual"
	)
	_check(not story.skip_button.visible, "Reanudar no habilita saltar una cinemática desconocida")
	story._complete_text()
	story._on_continue_pressed()
	_check(
		story.beat_index == initial + 1, "El botón Continuar sigue avanzando al leer manualmente"
	)


func _comfort_layouts() -> void:
	await _scene("main_menu")
	var pause: Node = root.get_node("PauseMenu")
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = window_size
		pause.open_pause()
		await process_frame
		await process_frame
		var panel: Control = pause.get_node("Shade/Panel")
		for path: String in [
			"ReducedMotion", "ReducedFlashes", "InstantText", "ManualCinematics", "VolumeControls"
		]:
			var control: Control = panel.get_node(path)
			_check(
				panel.get_global_rect().encloses(control.get_global_rect()),
				"Las preferencias caben dentro del panel a %d píxeles" % window_size.x
			)
		await _capture("lectura_manual_%d" % window_size.x)
		pause.resume_game()
	root.size = Vector2i(1280, 720)
