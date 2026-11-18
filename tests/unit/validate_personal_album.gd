extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: GameSession = GardenFixture.complete_snack()
	var legacy: Dictionary = session.snapshot()
	legacy.erase("personal_album")
	check(session.restore(legacy), "El formato vigente anterior sigue siendo compatible")
	check(session.personal_moments().is_empty(), "Ausencia equivale a un álbum vacío")
	var moment: Dictionary = {
		"title": "Merienda",
		"kind": "snack",
		"frame": "close",
		"pose": 2.6,
		"guests": ["Kay", "Ch'íich'"],
		"setting": {"food": "K'úum|", "decoration": "flowers"}
	}
	var candidate: Array[Dictionary] = session.album_with_moment(moment)
	check(candidate.size() == 1 and session.personal_moments().is_empty(), "Prepara sin confirmar")
	session.apply_personal_album(candidate)
	moment.guests.clear()
	candidate[0].setting.decoration = "leaves"
	var copy: Array[Dictionary] = session.personal_moments()
	copy[0].title = "Otro título"
	check(
		(
			session.personal_moments()[0].setting.decoration == "flowers"
			and session.personal_moments()[0].guests == ["Kay", "Ch'íich'"]
			and session.personal_moments()[0].title == "Merienda"
		),
		"Componer, confirmar y consultar usan copias profundas"
	)
	var baseline: Dictionary = session.snapshot()
	for invalid: Dictionary in [
		{"title": " "},
		{"title": "a\nb"},
		{"title": "x".repeat(33)},
		{"kind": "home"},
		{"frame": "custom"},
		{"pose": true},
		{"pose": INF},
		{"pose": NAN},
		{"pose": 7},
		{"guests": ["Miis"]},
		{"guests": ["Kay", "Kay"]},
		{"guests": [4]},
		{"guests": []},
		{"setting": {"food": "K'úum|", "decoration": 1}},
		{"setting": {"food": "mayak|chich", "decoration": "flowers"}},
		{"setting": {"food": "K'úum|", "decoration": "flowers", "extra": []}},
	]:
		var damaged: Dictionary = baseline.duplicate(true)
		damaged.personal_album[0].merge(invalid, true)
		check(not session.restore(damaged), "Rechaza datos anidados inválidos: " + str(invalid))
		check(session.snapshot() == baseline, "Una lectura rechazada no muta la sesión")
	var visit: Dictionary = _visit(session)
	check(PersonalAlbum.valid_moment(visit, session.words_learned), "Valida la copia de la mesa")
	for invalid: Dictionary in [
		{"table": 1.5},
		{"guest_x": 0.0},
		{"guest_y": INF},
		{"identity": {"name": "", "decorations": ["wrong"]}},
		{"objects": [{"id": 1}]},
	]:
		var damaged: Dictionary = visit.duplicate(true)
		damaged.setting.merge(invalid, true)
		check(
			not PersonalAlbum.valid_moment(damaged, session.words_learned),
			"Rechaza visita inválida"
		)
	var overfilled: Dictionary = baseline.duplicate(true)
	for index: int in range(PersonalAlbum.LIMIT):
		overfilled.personal_album.append(visit)
	check(not session.restore(overfilled), "La capacidad se valida al cargar")
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(baseline))
	check(session.restore(decoded), "Todos los campos caben en el JSON vigente")
	finish("PG7: contrato del álbum personal")


func _visit(session: GameSession) -> Dictionary:
	var id: int = session.place_new_garden_object("mayak|chich", Vector2(600, 440), "patio", 1)
	var table: Dictionary = GardenLayout.object_by_id(session.garden, id)
	var anchor: Vector2 = VillageVisitPlacement.meeting_point(
		table, session.garden, GameContent.VILLAGE_SPACES.space("patio")
	)
	return {
		"title": "En mi patio",
		"kind": "visit",
		"frame": "wide",
		"pose": 4,
		"guests": ["Áak"],
		"setting":
		{
			"table": id,
			"guest_x": anchor.x,
			"guest_y": anchor.y,
			"objects": GardenCompositions.capture(session.garden, "patio").objects,
			"identity": {"name": "", "decorations": ["gathering"]}
		}
	}
