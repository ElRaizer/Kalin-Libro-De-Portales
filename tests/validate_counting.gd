## Mundo 4 · Las piedras que cuentan: numeración maya de dos pisos, números
## sorteados del 1 al 50, guardado, errores que enseñan y recorrido completo.
extends ProjectTest

var manager: Node


func _initialize() -> void:
	await process_frame
	manager = root.get_node("GameManager")
	manager._save_repository = repository_for("counting")
	manager.reset_save()
	_numeral_rules()
	_content_rules()
	_random_targets()
	_session_rules()
	await _wrong_answers_teach()
	await _resume_keeps_progress()
	await _full_level()
	finish("Validación de los números")


## Cada número de 1 a 59 se reparte en veintenas y unidades; un piso nunca
## muestra más de cuatro puntos ni más de tres barras.
func _numeral_rules() -> void:
	for value: int in range(1, MayaNumeral.max_value() + 1):
		var twenties: int = MayaNumeral.twenties_of(value)
		var units: int = MayaNumeral.units_of(value)
		check(
			MayaNumeral.value_of(twenties, units) == value,
			"El numeral de %d vale %d" % [value, value]
		)
		check(MayaNumeral.dots_of(units) <= MayaNumeral.MAX_DOTS, "Nunca más de cuatro puntos")
		check(MayaNumeral.bars_of(units) <= MayaNumeral.MAX_BARS, "Nunca más de tres barras")
	check(MayaNumeral.needs_shell(20) and MayaNumeral.needs_shell(40), "20 y 40 llevan concha")
	check(not MayaNumeral.needs_shell(27), "27 no lleva concha")
	check(MayaNumeral.max_value() >= 50, "La tablilla alcanza para el 50")


## La configuración de autor es válida, llega hasta el 50 y un rango que no
## alcanza para las rondas se reporta.
func _content_rules() -> void:
	var content: CountingSet = load("res://data/exercises/world4_counting.tres") as CountingSet
	check(content != null, "Existe la configuración del tianguis")
	if content == null:
		return
	check(
		content.get_configuration_issues().is_empty(),
		"La configuración está completa: " + "; ".join(content.get_configuration_issues())
	)
	check(content.min_value == 1 and content.max_value == 50, "Se sortea del 1 al 50")
	var broken: CountingSet = CountingSet.new()
	broken.min_value = 10
	broken.max_value = 12
	broken.round_count = 8
	check(
		not broken.get_configuration_issues().is_empty(),
		"Un rango sin números suficientes se reporta en el Inspector"
	)


## Los números salen de la semilla: distintos, dentro del rango y estables al
## reanudar; otra partida sortea otros.
func _random_targets() -> void:
	var content: CountingSet = load("res://data/exercises/world4_counting.tres") as CountingSet
	var session: CountingSession = CountingSession.new()
	session.seed_value = 1234
	var first: Array[int] = session.targets(content)
	check(first.size() == content.round_count, "Hay un número por ronda")
	var unique: Array[int] = []
	for value: int in first:
		check(value >= 1 and value <= 50, "El número %d está entre 1 y 50" % value)
		if value not in unique:
			unique.append(value)
	check(unique.size() == first.size(), "Los números de una partida no se repiten")
	check(first == session.targets(content), "La misma semilla pide los mismos números")
	var differs: bool = false
	for seed_value: int in range(1, 6):
		session.seed_value = seed_value
		differs = differs or session.targets(content) != first
	check(differs, "Otra partida sortea otros números")


## Poner piezas sigue la numeración: cinco puntos forman una barra, veinte
## suben al piso de arriba con la concha abajo y el checkpoint se valida.
func _session_rules() -> void:
	var session: CountingSession = CountingSession.new()
	for step: int in range(4):
		session.add_dot()
	check(session.add_dot() == CountingSession.Placement.MERGED, "El quinto punto es una barra")
	check(session.units == 5, "Una barra vale cinco")
	for step: int in range(3):
		session.add_bar()
	check(
		session.twenties == 1 and session.units == 0 and session.shell,
		"Veinte suben como un punto y abajo queda la concha"
	)
	check(session.is_solved(20), "Un punto arriba y la concha abajo forman el 20")
	session.clear_numeral()
	session.select_floor(MayaNumeral.Floor.TWENTIES)
	session.add_dot()
	check(not session.is_solved(20), "Sin concha el piso de abajo queda sin escribir")
	check(
		session.add_shell() == CountingSession.Placement.SHELL_TAKEN,
		"La concha no va en el piso de arriba"
	)
	session.select_floor(MayaNumeral.Floor.UNITS)
	check(session.add_shell() == CountingSession.Placement.SHELL, "La concha va abajo")
	check(session.is_solved(20), "Con concha se forma el 20")
	session.add_dot()
	check(not session.shell, "Una pieza abajo quita la concha")
	session.select_floor(MayaNumeral.Floor.TWENTIES)
	session.add_dot()
	check(session.add_dot() == CountingSession.Placement.FULL, "Arriba sólo caben las veintenas")
	var content: CountingSet = load("res://data/exercises/world4_counting.tres") as CountingSet
	var restored: CountingSession = CountingSession.new()
	restored.restore(
		{
			"round": 99,
			"waiting": true,
			"layout_seed": 77,
			"twenties": 40,
			"units": -2,
			"shell": "sí",
			"floor": 9,
			"mistakes": INF
		},
		content
	)
	check(restored.round_index == content.round_count, "La ronda se limita al final del nivel")
	restored.restore(
		{
			"round": 0,
			"waiting": true,
			"layout_seed": 77,
			"twenties": 40,
			"units": -2,
			"shell": "sí",
			"floor": 9
		},
		content
	)
	check(
		restored.twenties == MayaNumeral.MAX_TWENTIES and restored.units == 0,
		"Los pisos se limitan"
	)
	check(not restored.shell, "Una concha guardada con otro tipo se descarta")
	check(restored.active_floor == MayaNumeral.Floor.UNITS, "Un piso inválido vuelve abajo")
	check(not restored.waiting, "Una tablilla incorrecta no se da por resuelta al continuar")


## Equivocarse no avanza: explica el error y la ayuda señala la pieza que falta.
func _wrong_answers_teach() -> void:
	var level: Node = await _open_level({})
	var target: int = level.current_target()
	check(level.target_label.text == str(target), "La petición muestra el número buscado")
	check(level.hint_label.text.contains("="), "Las primeras rondas explican el reparto")
	if target == 1:
		level._on_bar_pressed()
	else:
		level._on_dot_pressed()
	level._on_action_pressed()
	check(not level._session.waiting, "Un numeral incorrecto no se acepta")
	check(level._session.mistakes == 1, "El error queda registrado")
	check(
		(
			level.feedback_label.text.contains("piezas")
			or level.feedback_label.text.contains("arriba")
		),
		"El aviso explica qué revisar"
	)
	level._on_action_pressed()
	check(level._help_stage > 0, "Tras dos errores se ofrece ayuda")
	CountingSolver.solve_round(level)
	level._on_action_pressed()
	check(level._session.waiting, "El numeral correcto se acepta")
	check(level._session.mistakes == 2, "Acertar no borra los errores de la ronda")
	await _close(level)


## Salir a media ronda y volver conserva el número buscado y la tablilla.
func _resume_keeps_progress() -> void:
	var level: Node = await _open_level({})
	var target: int = level.current_target()
	level.upper_floor.pressed.emit()
	level._on_dot_pressed()
	var state: Dictionary = level.get_checkpoint_state()
	await _close(level)
	var resumed: Node = await _open_level(state)
	check(resumed.current_target() == target, "Al volver se pide el mismo número")
	check(
		resumed._session.twenties == 1 and resumed.upper_numeral.dots == 1,
		"El grano del piso de arriba sigue sobre la tablilla"
	)
	check(resumed.upper_floor.button_pressed, "Sigue elegido el piso de arriba")
	CountingSolver.solve_round(resumed)
	resumed._on_action_pressed()
	var solved_state: Dictionary = resumed.get_checkpoint_state()
	await _close(resumed)
	var again: Node = await _open_level(solved_state)
	check(again._session.waiting, "Una ronda resuelta sigue resuelta al volver")
	check(again.dot_button.disabled, "Las piezas quedan bloqueadas hasta continuar")
	await _close(again)


## Recorrer todo el nivel lo completa y continúa al capítulo del portal.
func _full_level() -> void:
	manager.reset_save()
	var level: Node = await _open_level({})
	CountingSolver.solve_level(level)
	check(manager.is_level_completed(4, 2), "Terminar el tianguis completa el Mundo 4 · Nivel 2")
	check(level.completion.visible, "Se muestra la celebración del nivel")
	level.completion.next_pressed.emit()
	await scene_changed
	await process_frame
	check(
		current_scene.scene_file_path == GameContent.SCENE_PATHS.world4_story1,
		"Después de contar sigue el capítulo del portal"
	)
	var story: Node = load(GameContent.SCENE_PATHS.world4_story2).instantiate()
	check(story.next_scene_key == "world4_level2", "El capítulo del tianguis abre el nivel")
	story.free()


func _open_level(state: Dictionary) -> Node:
	manager.session.scene_states["world4_level2"] = state.duplicate(true)
	change_scene_to_file(GameContent.SCENE_PATHS.world4_level2)
	await scene_changed
	await process_frame
	return current_scene


func _close(level: Node) -> void:
	manager.session.scene_states.erase("world4_level2")
	level.queue_free()
	current_scene = null
	await process_frame
