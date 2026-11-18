extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: GameSession = _prepared_session()
	check(not session.has_finished_adventure(), "Las palabras y diseños no abren el posjuego")
	for level: Dictionary in GameContent.LEVEL_ORDER:
		session.complete_level(level.world, level.level)
	check(not session.has_finished_adventure(), "Completar niveles no sustituye el regreso a casa")
	check(not session.advance_rest_intro(), "No adelanta la invitación antes del cierre")
	check(not session.choose_rest_corner("mayak"), "No elige un proyecto sin invitación")
	for invalid: Variant in [1, "true", {}, []]:
		session.scene_states.world5_cine1 = {"complete": invalid}
		check(not session.has_finished_adventure(), "El cierre exige una bandera booleana real")
	session.scene_states.world5_cine1 = {"complete": true}
	check(session.has_finished_adventure(), "El cierre vivido habilita proyectos")
	for iteration: int in range(2):
		session.scene_states.world5_cine1 = SceneStateSchema.replay_state(
			session.scene_states.world5_cine1
		)
		check(session.has_finished_adventure(), "Repetir no retira el acceso al posjuego")
	for word: String in RestCornerState.WORDS:
		_check_choice(word)
	_check_invalid_loads()
	_check_saturated_economy()
	_check_profile()
	finish("Rincón de descanso: cierre real, elecciones, resultado único y cargas atómicas")


func _prepared_session() -> GameSession:
	var session: GameSession = GameSession.new()
	for word: String in ["Áak", "Miis", "mayak", "k'áanche'", "k'áan", "chich"]:
		session.learn_word(word)
	session.record_learning(["mayak", "chich"], "practice", "supported", true)
	session.prepare_sharing_corner()
	session.purchase_design("mayak")
	session.purchase_design("chich")
	check(session.magic_points == 0, "Prepara saldo cero mediante las compras vigentes")
	return session


func _check_choice(word: String) -> void:
	var session: GameSession = _prepared_session()
	session.scene_states.world5_cine1 = {"complete": true}
	var before: Dictionary = session.snapshot()
	for step: int in range(RestCornerState.INTRO_STEPS):
		check(session.advance_rest_intro(), "La invitación avanza manualmente")
	check(not session.advance_rest_intro(), "No sobrepasa los momentos de introducción")
	check(not session.confirm_rest_corner(), "No confirma sin elegir")
	check(not session.choose_rest_corner("lak"), "No sustituye una alternativa por otro objeto")
	check(session.choose_rest_corner(word), "Las tres soluciones permiten colaborar")
	var restored: GameSession = GameSession.new()
	check(
		restored.restore(JSON.parse_string(JSON.stringify(session.snapshot()))), "Retoma una prueba"
	)
	check(
		restored.rest_corner.choice == word and not restored.rest_corner.complete,
		"Elegir no confirma"
	)
	check(restored.confirm_rest_corner(), "Confirma sin compra adicional ni escritura perfecta")
	check(not restored.confirm_rest_corner(), "No vuelve a confirmar ni premiar")
	check(not restored.choose_rest_corner("mayak"), "La elección vivida conserva su identidad")
	for step: int in range(RestCornerState.RESULT_STEPS):
		check(restored.advance_rest_result(), "Las reacciones avanzan con una acción propia")
	check(not restored.advance_rest_result(), "El resultado tiene un cierre finito")
	var completed: Dictionary = restored.snapshot()
	check(
		session.restore(JSON.parse_string(JSON.stringify(completed))),
		"Reanuda un proyecto completo"
	)
	completed.rest_corner.choice = ""
	check(session.rest_corner.choice == word, "El recuerdo no comparte el dato recibido")
	check(session.magic_points == before.magic_points, "Colaborar no paga puntos lingüísticos")
	check(session.garden == before.garden, "La prueba temporal no fabrica ni consume muebles")
	check(session.economy == before.economy, "No compra diseños ni repite preparación")
	check(
		session.learning_progress == before.learning_progress, "No inventa recuerdo independiente"
	)


func _check_invalid_loads() -> void:
	var session: GameSession = _prepared_session()
	session.scene_states.world5_cine1 = {"complete": true}
	for step: int in range(RestCornerState.INTRO_STEPS):
		session.advance_rest_intro()
	session.choose_rest_corner("k'áan")
	var before: Dictionary = session.snapshot()
	for field: String in ["intro", "result"]:
		for invalid: Variant in [null, "1", true, INF, -1, 0.5, 5]:
			var state: Dictionary = before.duplicate(true)
			state.rest_corner[field] = invalid
			check(not session.restore(state), "Valida tipo, finitud y rango de cada etapa")
			check(session.snapshot() == before, "Una carga fallida conserva la sesión anterior")
	for invalid: Variant in [
		null, [], {}, {"intro": 3}, {"intro": 0, "choice": "", "complete": true, "result": 0}
	]:
		var state: Dictionary = before.duplicate(true)
		state.rest_corner = invalid
		check(not session.restore(state), "Rechaza objetos incompletos o terminaciones ficticias")
	var broken: Dictionary = before.duplicate(true)
	broken.rest_corner.result = 1
	check(
		not session.restore(broken), "No muestra una reacción confirmada sin terminar el proyecto"
	)
	broken = before.duplicate(true)
	broken.words_learned.erase("k'áan")
	check(not session.restore(broken), "No restaura una alternativa desconocida")
	broken = before.duplicate(true)
	broken.scene_states.clear()
	check(not session.restore(broken), "Contrasta el avance con el cierre real de la historia")
	check(session.snapshot() == before, "Las referencias inválidas no destruyen la partida")
	broken = before.duplicate(true)
	broken.erase("rest_corner")
	check(session.restore(broken), "Un guardado vigente sin el campo opcional sigue siendo válido")
	check(
		session.rest_corner == RestCornerState.empty_state(),
		"La ausencia significa proyecto sin iniciar"
	)


func _check_profile() -> void:
	var profile: RestCornerProfile = (
		load("res://data/village/rest_corner.tres") as RestCornerProfile
	)
	check(profile.configuration_issues().is_empty(), "El recurso de autor cubre las alternativas")
	var customized: RestCornerProfile = profile.duplicate(true) as RestCornerProfile
	customized.options[0].description = "Un rincón personalizado en el Inspector."
	check(
		customized.option_for("mayak").description != profile.option_for("mayak").description,
		"Conserva las personalizaciones sin mutar el recurso canónico"
	)


func _check_saturated_economy() -> void:
	var session: GameSession = _prepared_session()
	session.scene_states.world5_cine1 = {"complete": true}
	for occasion: int in range(2):
		for word: String in session.words_learned:
			session.record_learning([word], "recall", "later/%s@%d" % [word, occasion])
	for word: String in session.words_learned:
		check(int(session.economy.awards[word]) == 10, "Prepara palabras con máximo acreditado")
	var before: Dictionary = session.snapshot()
	for step: int in range(RestCornerState.INTRO_STEPS):
		session.advance_rest_intro()
	check(
		session.choose_rest_corner("k'áan") and session.confirm_rest_corner(),
		"Los máximos no bloquean la colaboración"
	)
	check(session.magic_points == before.magic_points, "El proyecto no exige otra fuente de puntos")
	check(
		session.economy == before.economy and session.learning_progress == before.learning_progress,
		"No modifica premios ni evidencia al confirmar"
	)
