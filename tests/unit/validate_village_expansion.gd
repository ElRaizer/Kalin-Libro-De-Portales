extends ProjectTest


func _initialize() -> void:
	var spaces: VillageSpaces = GameContent.VILLAGE_SPACES
	check(spaces.configuration_issues().is_empty(), "Geometría de autor válida")
	var shore: VillageSpace = spaces.space("shore")
	var edited: VillageSpaces = spaces.duplicate(true)
	edited.space("patio").plot = Rect2(300, 350, 600, 150)
	var sample: Dictionary = GardenLayout.empty_state()
	var sample_id: int = GardenLayout.add_object(sample, "mayak|chich", "patio")
	check(
		not GardenLayout.move_object(
			sample, sample_id, Vector2(320, 440), "patio", edited.space("patio"), false
		),
		"La colocación utiliza la parcela de autor"
	)
	check(
		GardenLayout.move_object(
			sample, sample_id, Vector2(320, 440), "patio", spaces.space("patio"), false
		),
		"El recurso canónico permanece intacto"
	)
	edited.space("shore").extension_entry.position.x = NAN
	check(not edited.configuration_issues().is_empty(), "Autoría rechaza entrada no finita")
	var session: GameSession = GardenFixture.complete_snack()
	session.magic_points = 0
	var baseline: Dictionary = session.snapshot()
	check(not session.inaugurate_expansion(), "No inaugura sin decisiones")
	check(session.try_expansion("rest"), "Prueba descanso")
	var draft: Dictionary = session.snapshot()
	check(not session.try_expansion("unknown"), "Rechaza un propósito desconocido")
	check(session.snapshot() == draft, "Error no altera borrador")
	check(not session.select_expansion_guests(["Kay"]), "Kay conserva su estanque")
	check(not session.select_expansion_guests(["Ma'ax", "Ma'ax"]), "No duplica invitados")
	check(not session.select_expansion_guests(["Ma'ax", "Áak", "Miis"]), "Grupo acotado")
	check(session.select_expansion_guests(["Ma'ax", "Miis"]), "Elige estreno")
	check(not session.inaugurate_expansion(), "Hay que probar ambas opciones")
	var partial: GameSession = GameSession.new()
	check(
		partial.restore(JSON.parse_string(JSON.stringify(session.snapshot()))),
		"Reanuda prueba y grupo"
	)
	check(partial.village_expansion == session.village_expansion, "Borrador independiente")
	check(session.try_expansion("snack"), "Prueba merienda")
	check(session.try_expansion("rest"), "Elección inicial explícita")
	check(
		not session.place_new_garden_object("mayak|chich", Vector2(400, 237), "shore", 0),
		"El terreno permanece cerrado antes de inaugurar"
	)
	var obstacle: int = session.place_new_garden_object(
		"mayak|chich", Vector2(400, 372), "shore", 0
	)
	check(obstacle > 0, "Conserva muebles previos a la ampliación")
	check(not session.inaugurate_expansion(), "No inaugura una entrada bloqueada")
	GardenLayout.store_object(session.garden, obstacle)
	for index: int in range(GardenLayout.MAX_OBJECTS - 1):
		GardenLayout.add_object(session.garden, "mayak|chich", "shore")
	check(session.inaugurate_expansion(), "Inaugura con saldo cero y almacén lleno")
	var memory: Dictionary = VillageExpansion.memory(session.village_expansion)
	check(not session.inaugurate_expansion(), "Una única inauguración")
	check(session.try_expansion("snack"), "Redecora sin repetir preparativos")
	check(session.select_expansion_guests(["Áak"]), "Nueva visita libre")
	check(
		VillageExpansion.memory(session.village_expansion) == memory, "Conserva el estreno original"
	)
	memory.guests.clear()
	check(
		not session.village_expansion.opening.guests.is_empty(), "Recuerdo sin referencias mutables"
	)
	check(
		session.magic_points == 0 and session.economy == baseline.economy, "Sin cobros ni premios"
	)
	check(
		session.learning_progress == baseline.learning_progress,
		"Sin evidencia lingüística inventada"
	)
	var table: int = obstacle
	check(
		session.place_garden_object(table, Vector2(400, 237), "shore"), "Decora la parcela ampliada"
	)
	var before: Dictionary = session.garden.duplicate(true)
	check(
		not session.place_garden_object(table, shore.extension_anchor, "shore"),
		"Reserva el uso común"
	)
	check(session.garden == before, "Movimiento fallido conserva posición y orientación")
	check(
		not session.place_garden_object(table, Vector2(400, 372), "shore"),
		"Protege la única entrada"
	)
	check(session.save_garden_composition("shore", 0, 2), "Guarda acomodo con ampliación")
	check(session.apply_garden_composition("shore", 0).is_empty(), "Restaura el conjunto válido")
	check(VillageGround.extension_accessible(session.garden, shore), "Entrada y anclas alcanzables")
	for anchor: Vector2 in shore.guest_anchors + [shore.extension_anchor]:
		var route: PackedVector2Array = VillageGround.route(
			shore.arrival, anchor, session.garden, "shore", shore, true
		)
		check(not route.is_empty(), "Ruta hasta cada ancla")
		for point: Vector2 in route:
			check(
				not VillageGround.blocked(point, session.garden, "shore", shore, true),
				"Ruta fuera de obstáculos"
			)
	var safe: Vector2 = VillageGround.safe_arrival(
		Vector2(400, 237), session.garden, "shore", shore, true
	)
	check(
		not VillageGround.blocked(safe, session.garden, "shore", shore, true),
		"Llegada segura con mobiliario"
	)
	var loaded: GameSession = GameSession.new()
	check(
		loaded.restore(JSON.parse_string(JSON.stringify(session.snapshot()))),
		"JSON de ampliación y acomodo"
	)
	check(loaded.snapshot() == session.snapshot(), "Carga exacta sin repetir resultados")
	for invalid: Variant in [null, [], false, {"complete": true}]:
		var data: Dictionary = session.snapshot()
		data.village_expansion = invalid
		check(not loaded.restore(data), "Rechaza frontera inválida")
	var stable: Dictionary = loaded.snapshot()
	for field: String in ["tried", "purpose", "guests", "opening", "complete"]:
		var data: Dictionary = session.snapshot()
		data.village_expansion[field] = 1.5
		check(not loaded.restore(data), "Valida tipo anidado " + field)
		check(loaded.snapshot() == stable, "Carga fallida conserva sesión")
	var counterfeit: Dictionary = session.snapshot()
	counterfeit.village_expansion.tried = ["rest"]
	check(not loaded.restore(counterfeit), "Rechaza inauguración sin ambas pruebas")
	counterfeit = session.snapshot()
	counterfeit.village_expansion.opening.guests = ["unknown"]
	check(not loaded.restore(counterfeit), "Valida invitados del recuerdo")
	var absent: Dictionary = baseline.duplicate(true)
	absent.erase("village_expansion")
	check(loaded.restore(absent), "Campo opcional compatible en formato vigente")
	check(loaded.village_expansion == VillageExpansion.empty_state(), "Ausencia no abre terreno")
	loaded.reset()
	check(loaded.village_expansion == VillageExpansion.empty_state(), "Reinicio completo")
	var early: GameSession = GardenFixture.complete_corner()
	check(not early.try_expansion("rest"), "Se ofrece tras completar los proyectos anteriores")
	finish("PG6: decisiones, ampliación, rutas, memoria y carga")
