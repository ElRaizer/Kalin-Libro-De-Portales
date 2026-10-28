extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for support: int in [0, 1, 2]:
		_first_cycle(support)
	_support_and_failures()
	_nested_validation()
	_support_outside_room()
	finish("Economía por objetivo y preparación del rincón")


func _first_cycle(support: int) -> void:
	var session: GameSession = GameSession.new()
	session.learn_word("mayak")
	check(session.magic_points == 0, "Descubrir no suma el premio antiguo")
	check(not session.prepare_sharing_corner(), "Fuerte no se exige ni prepara antes de enseñarla")
	session.complete_level(1, 1)
	check(session.magic_points == 0, "Completar nivel no añade otros 50")
	var detail: Dictionary = {}
	for word: String in MagicEconomy.FIRST_DESIGNS:
		detail[word] = {"support_level": support}
	session.record_learning(["mayak", "chich"], "recall", "preparation", false, 8, detail)
	var minimum: int = 2 * [10, 6, 4][support]
	check(session.magic_points == minimum, "Los errores no reducen el premio por apoyo")
	check(session.prepare_sharing_corner(), "La preparación paga antes de comprar")
	check(session.magic_points == minimum + 12, "Preparación fija de doce")
	check(not session.prepare_sharing_corner(), "Preparar dos veces no duplica puntos")
	check(
		not session.purchase_design("lak"), "Compras opcionales no consumen el presupuesto inicial"
	)
	for word: String in MagicEconomy.FIRST_DESIGNS:
		check(session.purchase_design(word), "El presupuesto alcanza con cualquier apoyo")
		check(not session.purchase_design(word), "Un diseño sólo se cobra una vez")
	check(session.confirm_sharing_corner("mayak|chich"), "Primera construcción disponible")
	var restored: GameSession = GameSession.new()
	check(
		restored.restore(JSON.parse_string(JSON.stringify(session.snapshot()))),
		"Continúa desde JSON"
	)
	check(restored.snapshot() == session.snapshot(), "Se conservan saldo, compras y preparación")
	check(not restored.prepare_sharing_corner(), "Cargar no repaga la preparación")
	check(
		MagicEconomy.can_build(restored.economy, "mayak|chich", restored.words_learned),
		"Copias gratuitas"
	)
	restored.record_learning(["Áak"], "practice", "between1", true)
	restored.record_learning(["Miis"], "practice", "between2", true)
	var before: int = restored.magic_points
	restored.record_learning(["mayak", "chich"], "recall", "later_situation")
	check(restored.magic_points == before + 20 - minimum, "Recuperar entrega sólo la diferencia")
	before = restored.magic_points
	restored.record_learning(["mayak", "chich"], "recall", "another_situation")
	check(restored.magic_points == before, "No existe una fuente ilimitada por repetición")


func _support_and_failures() -> void:
	var attempt: LearningAttempt = LearningAttempt.new()
	attempt.begin("two_words")
	attempt.observe("mayak", true, false, "recall")
	attempt.use_word_support("chich", 1)
	attempt.observe("chich", true, false, "reconstruction")
	var restored: LearningAttempt = LearningAttempt.new()
	restored.restore(JSON.parse_string(JSON.stringify(attempt.snapshot())))
	var session: GameSession = GameSession.new()
	session.record_learning(
		["mayak", "chich"], "recall", "two_words", true, 0, restored.evidence(["mayak", "chich"])
	)
	check(session.magic_points == 16, "La pista de cualidad no rebaja el objeto correcto")
	var before: Dictionary = session.snapshot()
	session.record_learning(["mayak", "chich"], "recall", "two_words")
	check(session.snapshot() == before, "Reabrir el resultado no mejora ni repaga")
	session.record_learning(["lak"], "experiment", "lab", true)
	check(session.magic_points == 16, "Ensayar no paga puntos lingüísticos")
	session.record_learning(["chich"], "recall", "same_question_new_seed")
	check(session.magic_points == 16, "Otra semilla inmediata no paga un complemento")


func _nested_validation() -> void:
	var session: GameSession = GameSession.new()
	var before: Dictionary = session.snapshot()
	for invalid: Variant in [null, {}, "10", -1, 5, INF, 4.5]:
		var state: Dictionary = before.duplicate(true)
		state.economy.awards.mayak = invalid
		check(not session.restore(state), "Premios anidados inválidos se rechazan")
		check(session.snapshot() == before, "Fallar una carga conserva la sesión")


func _support_outside_room() -> void:
	var session: GameSession = GameSession.new()
	var attempt: LearningAttempt = LearningAttempt.new()
	attempt.begin("challenge_room/mayak@1")
	session.learn_word("mayak")
	session.scene_states.village_home = {
		"challenge_room":
		{
			"words": ["mayak"],
			"index": 0,
			"visit": 1,
			"waiting": false,
			"attempt": attempt.snapshot()
		}
	}
	check(
		session.mark_pending_challenge_help(),
		"La consulta fuera de la sala marca el intento pendiente"
	)
	var restored: GameSession = GameSession.new()
	check(
		restored.restore(JSON.parse_string(JSON.stringify(session.snapshot()))),
		"La consulta persiste al cambiar de escena y cargar"
	)
	attempt.restore(restored.scene_states.village_home.challenge_room.attempt)
	attempt.observe("mayak", true, false, "recall")
	restored.record_learning(
		["mayak"], "recall", attempt.context, attempt.supported, 0, attempt.evidence(["mayak"])
	)
	check(
		restored.magic_points == 4, "Salir para consultar no convierte la solución en diez puntos"
	)
