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
	finish("Selección local y contextos de la sala de retos")
