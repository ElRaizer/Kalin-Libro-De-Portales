extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: GameSession = _prepared_session()
	var id: int = int(session.garden.objects[0].id)
	var before: Dictionary = session.snapshot()
	check(not session.begin_village_visit("Kay", id, 18), "La primera entrega limita sus invitados")
	check(not session.begin_village_visit("Áak", id + 1, 18), "No invita a un mueble inexistente")
	check(not session.begin_village_visit("Áak", id, INF), "No admite duración no finita")
	check(session.snapshot() == before, "Una invitación inválida no cambia la partida")
	check(session.begin_village_visit("Áak", id, 18), "Invitar es gratuito con saldo cero")
	check(not session.begin_village_visit("Miis", id, 18), "Una sola visita a la vez")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(session.snapshot()))
	var restored: GameSession = GameSession.new()
	check(restored.restore(snapshot), "La visita vuelve de JSON")
	check(restored.village_visit == session.village_visit, "Se conservan invitado, mesa y tiempo")
	snapshot.village_visit.remaining = 1
	check(float(restored.village_visit.remaining) == 18, "La carga no comparte la copia recibida")
	var unchanged: Dictionary = restored.snapshot()
	for invalid: Variant in [null, [], {}, "18", true, -1, 0, INF, 121]:
		var state: Dictionary = unchanged.duplicate(true)
		state.village_visit.remaining = invalid
		check(not restored.restore(state), "Rechaza tiempo anidado inválido")
		check(restored.snapshot() == unchanged, "Fallar conserva la visita anterior")
	for invalid: Variant in ["1", true, 1.5, INF, 0]:
		var state: Dictionary = unchanged.duplicate(true)
		state.village_visit.object_id = invalid
		check(not restored.restore(state), "Rechaza identidad de soporte inválida")
	var broken: Dictionary = unchanged.duplicate(true)
	broken.garden.objects[0].stored = true
	check(not restored.restore(broken), "No restaura una visita a una mesa almacenada")
	check(restored.snapshot() == unchanged, "Una referencia rota no sustituye la sesión")
	check(not restored.advance_village_visit(INF), "Un paso inválido no consume tiempo")
	check(not restored.advance_village_visit(5), "La visita sigue tras cinco segundos activos")
	check(float(restored.village_visit.remaining) == 13, "El tiempo pertenece a la sesión")
	check(restored.advance_village_visit(20), "La visita termina sola")
	check(restored.village_visit.is_empty(), "No queda un resultado por cobrar")
	check(restored.magic_points == 0, "La visita no genera puntos")
	check(restored.learning_progress == before.learning_progress, "No añade evidencia educativa")
	check(not restored.end_village_visit(), "Terminar de nuevo es inocuo")
	check(restored.begin_village_visit("Miis", id, 18), "Se puede invitar otra vez")
	check(
		not restored.place_garden_object(id, Vector2(600, 900), "patio"),
		"Un movimiento inválido conserva su mesa"
	)
	check(not restored.village_visit.is_empty(), "El movimiento rechazado conserva la visita")
	check(restored.place_garden_object(id, Vector2(700, 440), "patio", 1), "Mueve y gira la mesa")
	check(restored.village_visit.is_empty(), "Editar su soporte termina la visita")
	var without_visit: Dictionary = before.duplicate(true)
	without_visit.erase("village_visit")
	check(restored.restore(without_visit), "El campo opcional ausente significa sin visita")
	_check_story_scenarios(restored)
	_check_saturated_economy()
	_check_placement(session.garden)
	finish("Estado de visitas, referencias, tiempo activo y escenarios de posjuego")


func _prepared_session() -> GameSession:
	var session: GameSession = GameSession.new()
	session.learn_word("Áak")
	session.learn_word("Miis")
	session.record_learning(["mayak", "chich"], "practice", "setup", true)
	session.prepare_sharing_corner()
	session.purchase_design("mayak")
	session.purchase_design("chich")
	var id: int = session.create_garden_object("mayak|chich", "patio")
	check(session.place_garden_object(id, Vector2(600, 440), "patio"), "Rincón inicial preparado")
	check(session.magic_points == 0, "La preparación apoyada y las compras dejan saldo cero")
	return session


func _check_story_scenarios(session: GameSession) -> void:
	check(session.scene_states.is_empty(), "El rincón es posible antes del cierre narrativo")
	for level: Dictionary in GameContent.LEVEL_ORDER:
		session.complete_level(level.world, level.level)
	check(
		not session.scene_states.has("world5_cine1"),
		"Completar niveles no inventa el cierre narrativo"
	)
	session.scene_states.world5_cine1 = {"complete": true}
	var replay: Dictionary = SceneStateSchema.replay_state(session.scene_states.world5_cine1)
	check(replay.previous_variation.complete, "Repetir conserva que el cierre ya fue vivido")
	session.scene_states.world5_cine1 = replay
	var copy: GameSession = GameSession.new()
	check(
		copy.restore(JSON.parse_string(JSON.stringify(session.snapshot()))),
		"Escenario de repetición reanudable"
	)
	check(
		copy.scene_states.world5_cine1.previous_variation.complete, "Conserva cierre previo en JSON"
	)


func _check_placement(garden: Dictionary) -> void:
	var table: Dictionary = garden.objects[0]
	var point: Vector2 = VillageVisitPlacement.meeting_point(
		table, garden, GameContent.VILLAGE_SPACES.space("patio")
	)
	check(point.is_finite(), "Hay acceso libre a la mesa")
	for side: float in [-1.0, 1.0]:
		var id: int = GardenLayout.add_object(garden, "k'áanche'|", "patio")
		check(
			GardenLayout.move_object(
				garden,
				id,
				Vector2(600 + side * 148, 440),
				"patio",
				GameContent.VILLAGE_SPACES.space("patio"),
				false
			),
			"Prepara vecino de la mesa"
		)
	check(
		not (
			VillageVisitPlacement
			. meeting_point(table, garden, GameContent.VILLAGE_SPACES.space("patio"))
			. is_finite()
		),
		"No coloca al invitado dentro de otro mueble"
	)


func _check_saturated_economy() -> void:
	var session: GameSession = _prepared_session()
	for occasion: int in range(2):
		for word: String in ["Áak", "Miis", "mayak", "chich"]:
			session.record_learning([word], "recall", "later/%s@%d" % [word, occasion])
	for word: String in session.words_learned:
		check(int(session.economy.awards[word]) == 10, "Prepara máximos acreditados")
	var before: Dictionary = session.snapshot()
	check(
		session.begin_village_visit("Áak", int(session.garden.objects[0].id), 18),
		"La economía saturada no bloquea visitas"
	)
	session.advance_village_visit(20)
	check(session.snapshot() == before, "Repetir la visita no cambia máximos ni resultados")
