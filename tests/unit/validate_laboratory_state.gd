extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_favorites()
	_purchases()
	_new_placement()
	finish("Favoritos, compra atómica y colocación del laboratorio")


func _favorites() -> void:
	var session: GameSession = GameSession.new()
	check(not session.set_laboratory_favorite("mayak|chich", true, 6), "No guarda desconocidos")
	for word: String in VocabularyCatalog.learnable_keys():
		session.learn_word(word)
	var ids: Array[String] = []
	for id: String in CombinationCatalog.targets():
		ids.append(id)
	for index: int in range(LaboratoryState.MAX_FAVORITES):
		check(session.set_laboratory_favorite(ids[index], true, 12), "Guarda hasta el límite")
	check(not session.set_laboratory_favorite(ids[12], true, 12), "La capacidad es finita")
	check(not session.set_laboratory_favorite(ids[0], true, 12), "No duplica favoritos")
	var original: Dictionary = session.snapshot()
	for invalid: Variant in [null, {}, "mayak|", [null], [1], ["mayak||"], [ids[0], ids[0]], ids]:
		var data: Dictionary = original.duplicate(true)
		data.laboratory_favorites = invalid
		check(not session.restore(data), "Rechaza favoritos anidados inválidos")
		check(session.snapshot() == original, "La carga fallida conserva toda la sesión")
	var unknown: Dictionary = original.duplicate(true)
	unknown.words_learned.erase("mayak")
	unknown.laboratory_favorites = ["mayak|"]
	check(not session.restore(unknown), "Contrasta favoritos con palabras conocidas")
	var restored: GameSession = GameSession.new()
	check(
		restored.restore(JSON.parse_string(JSON.stringify(original))), "Favoritos vuelven de JSON"
	)
	check(restored.snapshot() == original, "Cargar no añade puntos ni aprendizaje")
	original.laboratory_favorites.clear()
	check(restored.laboratory_favorites.size() == 12, "El snapshot no comparte favoritos")
	check(restored.set_laboratory_favorite(ids[0], false, 2), "Un perfil menor permite retirar")
	check(
		not restored.set_laboratory_favorite(ids[12], true, 2), "Un perfil menor conserva el límite"
	)
	var compatible: Dictionary = restored.snapshot()
	compatible.erase("laboratory_favorites")
	check(restored.restore(compatible), "Formato 9 sin favoritos sigue vigente")
	check(restored.laboratory_favorites.is_empty(), "La ausencia significa lista vacía")
	check(not restored.set_laboratory_favorite(ids[0], true, 13), "No amplía el límite persistido")
	check(restored.set_laboratory_favorite(ids[0], true, 1), "Capacidad editable de una idea")
	restored.reset()
	check(restored.laboratory_favorites.is_empty(), "Reiniciar retira favoritos")


func _purchases() -> void:
	var session: GameSession = GameSession.new()
	session.record_learning(["mayak", "chich", "nojoch"], "practice", "preparation", true)
	session.prepare_sharing_corner()
	var before: Dictionary = session.snapshot()
	check(not session.purchase_combination_designs("mayak|nojoch"), "Protege el primer rincón")
	check(session.snapshot() == before, "Un diseño permitido no se compra parcialmente")
	check(
		session.purchase_combination_designs("mayak|chich"), "Compra explícita del conjunto inicial"
	)
	check(session.magic_points == int(before.magic_points) - 20, "Cobra exactamente dos diseños")
	before = session.snapshot()
	check(
		not session.purchase_combination_designs("mayak|chich"), "Repetir no cobra diseños poseídos"
	)
	check(session.snapshot() == before, "La repetición es inerte")
	session.confirm_sharing_corner("mayak|chich")
	session.magic_points = 9
	before = session.snapshot()
	check(not session.purchase_combination_designs("mayak|nojoch"), "Saldo insuficiente")
	check(session.snapshot() == before, "El fallo conserva saldo y diseños")
	session.magic_points = 10
	check(session.purchase_combination_designs("mayak|nojoch"), "Compra sólo lo que falta")
	check(session.magic_points == 0, "Reutiliza gratis el diseño Mesa")
	check(session.economy.designs.count("mayak") == 1, "No duplica diseños compartidos")
	before = session.snapshot()
	check(not session.purchase_combination_designs("inventado|"), "Rechaza combinaciones ajenas")
	check(session.snapshot() == before, "Una entrada inválida no muta")


func _new_placement() -> void:
	var session: GameSession = GameSession.new()
	session.record_learning(["mayak", "chich"], "practice", "preparation", true)
	session.prepare_sharing_corner()
	session.purchase_combination_designs("mayak|chich")
	var before: Dictionary = session.snapshot()
	check(
		session.place_new_garden_object("mayak|chich", Vector2.ZERO, "patio", 0) == 0,
		"No coloca fuera"
	)
	check(session.snapshot() == before, "El fallo no consume identidad ni deja copia")
	check(
		session.place_new_garden_object("mayak|chich", Vector2(600, 440), "patio", 4) == 0,
		"Giro inválido"
	)
	check(
		session.place_new_garden_object("mayak|chich", Vector2(600, 440), "patio", 1) == 1,
		"Confirma copia"
	)
	check(session.economy.built, "La primera colocación confirma el rincón")
	check(session.garden.objects.size() == 1, "Una sola copia confirmada")
	before = session.snapshot()
	check(
		session.place_new_garden_object("mayak|chich", Vector2(600, 440), "patio", 0) == 0,
		"No superpone"
	)
	check(session.snapshot() == before, "El rechazo conserva el acomodo y progreso")
