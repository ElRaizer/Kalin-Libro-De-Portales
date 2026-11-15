extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var known: Dictionary = {}
	for word: String in ["Miis", "Áak", "mayak", "chich", "Bix a beel", "T'uut'"]:
		known[word] = VocabularyCatalog.entry(word)
	var secure: Dictionary = LearningProgress.empty_record()
	secure.practice = 50
	secure.errors = 800
	secure.recalls = ["house", "village"]
	secure.last_seen = 9
	var needs_practice: Dictionary = LearningProgress.empty_record()
	needs_practice.practice = 2
	needs_practice.supported = 2
	needs_practice.last_seen = 0
	needs_practice.recent = [{"support": 2, "errors": 1}]
	var selected: Array[String] = ChallengePlanner.select_words(
		known, {"Miis": secure, "Áak": needs_practice}, 10
	)
	check(
		selected.size() <= 3 and "T'uut'" not in selected, "Tanda corta sólo de vocabulario activo"
	)
	check(
		"Áak" in selected and "Miis" not in selected,
		"Prioriza ocasiones con apoyo y evita la palabra recién practicada"
	)
	for word: String in selected:
		check(word in known, "La sala no examina contenido sin presentar")
	var phrase: Array[String] = ChallengePlanner.targets("chich", known)
	check(phrase == ["mayak", "chich"], "Cualidad dentro de una combinación canónica conocida")
	check(
		ChallengePlanner.targets("Miis", known) == ["Miis"],
		"Un animal conserva su situación propia"
	)
	check(
		ChallengePlanner.targets("Bix a beel", known) == ["Bix a beel"],
		"Cortesía con identidad completa"
	)
	check(
		not ChallengePlanner.prompt("Bix a beel").contains("Bix a beel"),
		"El contexto no revela la respuesta"
	)
	var limited: Array[String] = ChallengePlanner.select_words({"Miis": known.Miis}, {}, 0)
	check(limited == ["Miis"], "Con pocos candidatos reduce la tanda sin repetir")
	_check_context_identity()
	_check_reward_policy()
	finish("Selección local y contextos de la sala de retos")


func _check_context_identity() -> void:
	var known: Dictionary = {"mayak": {}, "mejen": {}, "nojoch": {}}
	var noun: Array[String] = ChallengePlanner.targets("mayak", known)
	var quality: Array[String] = ChallengePlanner.targets("mejen", known)
	check(noun == quality, "Las dos anclas pueden representar la misma petición")
	var first: String = ChallengePlanner.context(noun, 1)
	var repeated: String = ChallengePlanner.context(quality, 2)
	var changed: String = ChallengePlanner.context(["mayak", "nojoch"], 3)
	var record: Dictionary = LearningProgress.empty_record()
	LearningProgress.record_result(record, "recall", first, false, 0, 3)
	LearningProgress.record_result(record, "recall", repeated, false, 0, 6)
	check(record.recalls.size() == 1, "Cambiar ancla o visita no inventa otra situación")
	LearningProgress.record_result(record, "recall", changed, false, 0, 9)
	check(record.recalls.size() == 2, "Cambiar el contenido sí distingue la situación")
	check(record.contexts.size() == 3, "Cada ocasión conserva su resultado propio")


func _check_reward_policy() -> void:
	var session: GameSession = GameSession.new()
	session.learn_word("Miis")
	var result: Dictionary = session.record_learning(
		["Miis"], "reconstruction", "challenge_room/Miis@1", true, 1, {}, false
	)
	check(result.changed and result.awarded == 0, "Apoyo en la sala conserva práctica sin premio")
	check(session.magic_points == 0, "Un intento apoyado no añade puntos")
	check(session.learning_progress.Miis.reconstruction == 1, "Se registra la reconstrucción")
	result = session.record_learning(["Miis"], "recall", "challenge_room/Miis@2")
	check(result.awarded == 10, "Escritura independiente conserva el premio máximo")
	result = session.record_learning(["Miis"], "recall", "challenge_room/Miis@3")
	check(result.awarded == 0, "Repetir el acierto no vuelve a pagar")
