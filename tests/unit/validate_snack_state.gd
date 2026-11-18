extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_project(["Kay"])
	_project(["Kay", "Ch'íich'"])
	_paths()
	finish("Merienda, cantidades, recuerdos y caminos de práctica")


func _project(guests: Array[String]) -> void:
	var session: GameSession = GardenFixture.complete_corner()
	session.magic_points = 0
	for index: int in range(GardenLayout.MAX_OBJECTS):
		session.create_garden_object("mayak|chich", "patio")
	var before: Dictionary = session.snapshot()
	check(not session.select_snack(["Kay", "Kay"], "ja'as|", "leaves"), "No duplica invitados")
	check(
		not session.select_snack(["Áak"], "ja'as|", "leaves"),
		"Sólo el reparto con actuación implementada"
	)
	check(not session.select_snack(guests, "future|", "flowers"), "Comida canónica conocida")
	check(session.snapshot() == before, "Entradas inválidas no cambian nada")
	check(session.select_snack(guests, "K'úum|", "flowers"), "Elige grupo y merienda sin comprar")
	check(session.begin_snack_preparation(), "Prepara dos cantidades relacionadas con el grupo")
	check(not session.confirm_snack_project(), "Una elección no es proyecto terminado")
	var activity: CountingActivity = CountingActivity.new()
	activity.setup(SnackState.counting_set(), session.snack_project.preparation)
	check(
		activity.session.targets(activity.content) == SnackState.targets(guests),
		"Raciones e ingredientes dependen de los invitados"
	)
	activity.session.add_dot()
	activity.submit()
	check(session.update_snack_preparation(activity.snapshot()), "Conserva borrador y errores")
	var original: Dictionary = session.snapshot()
	for field: String in ["round", "units", "twenties", "floor", "mistakes", "layout_seed"]:
		for invalid: Variant in [NAN, INF, -1, 0.5, "1", null]:
			var bad: Dictionary = original.duplicate(true)
			bad.snack_project.preparation.counting[field] = invalid
			check(not session.restore(bad), "Valida números anidados antes de convertir")
			check(session.snapshot() == original, "Una carga fallida conserva la sesión")
	for invalid: Variant in [null, [], true, {"guests": []}]:
		var bad: Dictionary = original.duplicate(true)
		bad.snack_project = invalid
		check(not session.restore(bad), "Rechaza estructura de proyecto inválida")
	var counterfeit: Dictionary = original.duplicate(true)
	counterfeit.snack_project.complete = true
	check(not session.restore(counterfeit), "Finalización exige cantidades confirmadas")
	counterfeit = original.duplicate(true)
	counterfeit.snack_project.preparation.counting.round = 2
	check(not session.restore(counterfeit), "Un contador no sustituye resultados reales")
	while not activity.finished():
		if not activity.session.waiting:
			activity.help()
			activity.help()
			activity.submit()
		else:
			activity.submit()
		check(
			session.update_snack_preparation(activity.snapshot()),
			"Actualiza la preparación con apoyo"
		)
	check(session.confirm_snack_project(), "Termina con apoyo")
	check(not session.confirm_snack_project(), "La confirmación es única")
	check(
		(
			session.garden == before.garden
			and session.economy == before.economy
			and session.magic_points == int(before.magic_points)
		),
		"No fabrica, compra ni paga premios"
	)
	check(
		(
			session.learning_progress == before.learning_progress
			and session.learning_clock == int(before.learning_clock)
		),
		"No acredita evidencia lingüística"
	)
	var memory: Dictionary = SnackState.memory(session.snack_project)
	check(
		memory.decoration == "flowers" and memory.food == "K'úum|",
		"El recuerdo conserva elecciones"
	)
	memory.guests.clear()
	check(session.snack_project.guests == guests, "Recuerdo independiente del proyecto")
	var restored: GameSession = GameSession.new()
	check(
		restored.restore(JSON.parse_string(JSON.stringify(session.snapshot()))), "Vuelve desde JSON"
	)
	check(restored.snapshot() == session.snapshot(), "Reanudar no cambia apoyos ni resultados")
	var compatible: Dictionary = restored.snapshot()
	compatible.erase("snack_project")
	check(restored.restore(compatible), "Formato 9 sin merienda sigue vigente")
	check(restored.snack_project == SnackState.empty_state(), "La ausencia es proyecto sin iniciar")
	restored.reset()
	check(
		not restored.select_snack(guests, "K'úum|", "leaves"),
		"Requiere regreso narrativo y palabras conocidas"
	)


func _paths() -> void:
	var known: Dictionary = {"Kay": {}}
	for seed_value: int in range(1, 14):
		var activity: PathPracticeState = PathPracticeState.new()
		check(activity.prepare(known, seed_value), "Prepara una variante revisada")
		var source: Dictionary = PathPracticeState.layout(activity.variant)
		check(
			GridReplayLayouts.has_solution(source, 12, 7),
			"La geometría mantiene el testigo revisado"
		)
		var route: Array[Vector2i] = GridReplayLayouts.cells(source.solution[0])
		activity.press(route[1])
		var saved: Dictionary = activity.snapshot()
		var restored: PathPracticeState = PathPracticeState.new()
		check(
			restored.restore(JSON.parse_string(JSON.stringify(saved)), known),
			"Conserva camino parcial desde JSON"
		)
		check(restored.snapshot() == saved, "Variante, animal y cursor estables")
		var before: Dictionary = restored.snapshot()
		for bad_pair: Variant in [[1.5, 1], [INF, 0], [-1, 2], [12, 0], [0, 7], null]:
			var bad: Dictionary = before.duplicate(true)
			bad.path = [bad_pair]
			check(not restored.restore(bad, known), "Rechaza coordenadas inválidas")
			check(restored.snapshot() == before, "Un camino inválido no sustituye el borrador")
		var false_end: Dictionary = before.duplicate(true)
		false_end.connected = true
		check(not restored.restore(false_end, known), "No acepta una llegada que no ocurrió")
		for index: int in range(2, route.size()):
			restored.press(route[index])
		check(
			not restored.controller.connected.is_empty(),
			"Las reglas existentes confirman la llegada"
		)
		check(
			PathPracticeState.valid_state(restored.snapshot(), known), "Resultado conectado válido"
		)
