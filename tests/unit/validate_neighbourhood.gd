extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: GameSession = GardenFixture.complete_corner()
	var id: int = session.place_new_garden_object("mayak|chich", Vector2(600, 440), "patio", 0)
	check(id > 0, "Prepara la mesa compartida")
	_check_visits(session, id)
	_check_deliveries(session)
	_check_encounters()
	finish("PG8: experiencias, compatibilidad y encuentros del paseo")


func _check_visits(session: GameSession, id: int) -> void:
	var base: Dictionary = session.snapshot()
	var legacy: Dictionary = base.duplicate(true)
	legacy.erase("village_experiences")
	check(session.restore(legacy), "La ausencia del campo mantiene el formato 9")
	check(not session.confirm_village_guest("Ma'ax"), "Una charla no confirma una visita")
	var story: Dictionary = session.scene_states.world5_cine1
	session.scene_states.erase("world5_cine1")
	check(not session.begin_village_visit("Ma'ax", id, 18), "El reparto ampliado espera el regreso")
	check(session.begin_village_visit("Áak", id, 18), "Se conserva la primera invitación")
	session.end_village_visit()
	session.scene_states["world5_cine1"] = story
	for district: String in VillageNeighbours.DISTRICTS:
		for animal: String in VillageNeighbours.RESIDENTS[district]:
			if animal == "Kay":
				check(not session.begin_village_visit(animal, id, 18), "Kay no usa muebles secos")
				check(
					not session.confirm_village_guest(animal), "No inventa una merienda sin hacer"
				)
				continue
			check(session.begin_village_visit(animal, id, 18), "Invitación compatible: " + animal)
			check(session.confirm_village_guest(animal), "Confirma a quien viene: " + animal)
			check(session.end_village_visit(), "Despedir libera la mesa")
	check(
		session.village_experiences.visits.size() == 11, "Los once vecinos terrestres pueden venir"
	)
	var confirmed: Dictionary = session.snapshot()
	check(base.economy == confirmed.economy, "Ninguna experiencia cambia la economía")
	check(
		base.learning_progress == confirmed.learning_progress,
		"Ninguna experiencia acredita palabras"
	)
	var loaded: Dictionary = JSON.parse_string(JSON.stringify(confirmed))
	check(session.restore(loaded), "Las experiencias se conservan en el guardado real")
	for invalid: Dictionary in [
		{"visits": ["Kay"]},
		{"visits": [true]},
		{"visits": ["Miis", "Miis"]},
		{"visits": ["sin vecino"]},
		{"clearing": ["Ma'ax"]},
		{"deliveries": {"Áak": true}},
	]:
		var broken: Dictionary = confirmed.duplicate(true)
		broken.village_experiences.merge(invalid, true)
		check(not session.restore(broken), "Rechaza la experiencia anidada inválida")
		check(session.snapshot() == confirmed, "Rechazar preserva el progreso")


func _check_deliveries(session: GameSession) -> void:
	var mission: Dictionary = {"residents": ["Báalam", "Ma'ax", "Kaax"], "delivered": [0]}
	check(
		not session.received_village_delivery("Báalam"), "Construir jardín no agradece otro encargo"
	)
	session.scene_states["world3_mission1"] = mission
	check(session.received_village_delivery("Báalam"), "Reconoce al destinatario real")
	check(not session.received_village_delivery("Ma'ax"), "No extiende el crédito a otra casa")
	session.archive_deliveries("world1_level1", mission)
	check(session.village_experiences.deliveries.is_empty(), "Otra escena no archiva encargos")
	session.archive_deliveries("world3_mission1", mission)
	session.scene_states.erase("world3_mission1")
	check(session.received_village_delivery("Báalam"), "Repetir conserva entregas ya vividas")
	check(not session.received_village_delivery("Kaax"), "No reconoce una entrega pendiente")


func _check_encounters() -> void:
	var session: GameSession = GardenFixture.complete_corner()
	session.rest_corner = RestCornerState.empty_state()
	var walk: VillageNeighbourhood = VillageNeighbourhood.new()
	var profile: VillageNeighbourProfile = load("res://data/village/neighbours.tres")
	check(profile.configuration_issues().is_empty(), "Los encuentros de autor son válidos")
	walk.restore({}, session, profile)
	check(walk.encounter().id == "patio_plans", "Selecciona según el proyecto sin iniciar")
	check(walk.opportunity().area == "patio", "La orientación indica dónde está el encuentro")
	check(walk.advance_encounter(), "La conversación avanza una línea por elección")
	var progress: Dictionary = walk.snapshot()
	for attempt: int in range(3):
		walk.restore(progress, session, profile)
		check(walk.snapshot() == progress, "Reiniciar no cambia el encuentro ni su línea")
	check(not walk.advance_encounter(), "Sólo terminar registra el encuentro")
	check(walk.encounter() == null, "Terminar no abre otro encuentro en la misma visita")
	walk.restore(walk.snapshot(), session, profile)
	check(walk.encounter() == null, "Reabrir con la misma situación no acumula novedades")
	check(walk.opportunity().action == "rest", "Conserva acceso al proyecto original")
	session.rest_corner = {"intro": 3, "choice": "mayak", "complete": true, "result": 0}
	walk.restore(walk.snapshot(), session, profile)
	check(
		walk.encounter().id == "shore_baskets", "Los preparativos requieren el descanso confirmado"
	)
	var malformed: Dictionary = {
		"heard": [{}, "not_an_encounter"],
		"encounter": "shore_baskets",
		"encounter_line": INF,
		"talk": {"animal": "Ma'ax", "line": 1.5, "topics": ["opening"]}
	}
	walk.restore(malformed, session, profile)
	check(
		walk.encounter_line == 0 and walk.talk_animal.is_empty(), "Valida la línea y su evidencia"
	)
	session = GardenFixture.complete_snack()
	walk.restore({}, session, profile)
	check(walk.encounter().id == "clearing_sign", "La merienda confirmada habilita la propuesta")
	session.try_expansion("rest")
	session.try_expansion("snack")
	session.select_expansion_guests(["Ma'ax"])
	session.inaugurate_expansion()
	walk.restore({}, session, profile)
	check(walk.encounter().id == "remember_clearing", "El estreno habilita su propio encuentro")
	for entry: PostgameEncounter in profile.encounters:
		var space: VillageSpace = GameContent.VILLAGE_SPACES.space(entry.district)
		check(space.floor_bounds.has_point(entry.location), "Ubicación en suelo: " + entry.id)
