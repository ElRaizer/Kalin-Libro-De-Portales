extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_identity()
	_compositions()
	_protection()
	_schema()
	finish("Identidad, acomodos, copias y protección del jardín")


func _identity() -> void:
	var session: GameSession = GardenFixture.complete_corner()
	check(
		session.set_garden_identity("patio", "La pausa de Kalin", ["sign", "border", "gathering"]),
		"Elige nombre y tres adornos"
	)
	var before: Dictionary = session.snapshot()
	for name_value: String in [" Muy largo ", "a".repeat(33), "Salto\nnuevo", "tab\tname"]:
		check(
			not session.set_garden_identity("patio", name_value, []),
			"Rechaza nombres fuera del contrato"
		)
	check(not session.set_garden_identity("other", "Jardín", []), "No cambia claves semánticas")
	check(not session.set_garden_identity("patio", "Jardín", ["sign", "sign"]), "Adornos únicos")
	check(session.snapshot() == before, "Entradas inválidas conservan la identidad")
	session.rest_corner.complete = false
	session.garden_identity.clear()
	check(
		not session.set_garden_identity("patio", "Jardín", ["sign"]), "El proyecto habilita adornos"
	)
	check(session.set_garden_identity("patio", "Mi jardín", []), "El nombre personal es libre")
	check(session.confirm_rest_corner(), "Confirma el proyecto después de nombrar")
	check(
		"gathering" in session.garden_identity.patio.decorations,
		"Nombrar antes del proyecto conserva su guirnalda"
	)
	session.set_garden_identity("patio", "Mi jardín", [])
	check(not session.confirm_rest_corner(), "No confirma dos veces")
	check(
		session.garden_identity.patio.decorations.is_empty(), "Repetir no impone un adorno retirado"
	)
	check(
		GardenIdentity.entry_for({}, "patio", true).decorations == ["gathering"],
		"Conserva la guirnalda de partidas vigentes"
	)


func _compositions() -> void:
	var session: GameSession = GardenFixture.complete_corner()
	var table: int = session.place_new_garden_object("mayak|chich", Vector2(580, 430), "patio", 1)
	var plate: int = session.place_new_garden_object("lak|", Vector2.ZERO, "patio", 0, table)
	check(table > 0 and plate > 0, "Conjunto con superficie")
	var original: Dictionary = session.garden.duplicate(true)
	check(session.save_garden_composition("patio", 0, 2), "Primer espacio")
	check(session.place_garden_object(table, Vector2(800, 450), "patio", 2), "Mueve el conjunto")
	check(session.save_garden_composition("patio", 1, 2), "Segundo espacio")
	check(session.save_garden_composition("workshop", 0, 2), "Cada parcela tiene sus espacios")
	check(not session.save_garden_composition("patio", 2, 2), "Capacidad acotada")
	check(session.apply_garden_composition("patio", 0).is_empty(), "Restaura conjunto")
	check(session.garden == original, "Conserva exactamente IDs, giros, posiciones y apoyos")
	check(session.apply_garden_composition("patio", 1).is_empty(), "Alterna espacios")
	check(
		int(GardenLayout.object_by_id(session.garden, table).orientation) == 2,
		"Conserva orientación"
	)
	check(
		int(GardenLayout.object_by_id(session.garden, plate).support) == table,
		"Conserva superficie"
	)
	check(
		session.place_garden_object(table, Vector2(600, 440), "workshop", 3),
		"Mueve el conjunto a otro barrio"
	)
	check(
		session.apply_garden_composition("patio", 0).is_empty(),
		"Recupera las mismas copias desde otro barrio"
	)
	check(
		session.garden == original, "El traslado conserva la identidad y la superficie originales"
	)
	var extra: int = session.place_new_garden_object("mayak|chich", Vector2(820, 470), "patio", 0)
	var extra_plate: int = session.place_new_garden_object("lak|", Vector2.ZERO, "patio", 0, extra)
	check(extra > 0 and extra_plate > 0, "Otro conjunto colocado")
	check(session.apply_garden_composition("patio", 0).is_empty(), "Restaura con muebles sobrantes")
	check(
		(
			GardenLayout.object_by_id(session.garden, extra).stored
			and GardenLayout.object_by_id(session.garden, extra_plate).stored
		),
		"Lleva el conjunto sobrante al almacén"
	)
	check(
		int(GardenLayout.object_by_id(session.garden, extra_plate).support) == extra,
		"Conserva el apoyo almacenado"
	)
	check(session.garden.objects.size() == 4, "No fabrica ni borra copias al restaurar")
	check(session.delete_garden_copy(plate).is_empty(), "Elimina sólo el plato")
	var missing: Dictionary = session.snapshot()
	check(not session.apply_garden_composition("patio", 0).is_empty(), "Informa la pieza faltante")
	check(session.snapshot() == missing, "No restaura parcialmente ni fabrica copias")
	var restored: GameSession = GameSession.new()
	check(
		restored.restore(JSON.parse_string(JSON.stringify(missing))),
		"Un acomodo histórico puede tener una pieza eliminada"
	)
	check(
		restored.garden_compositions == session.garden_compositions,
		"Mantiene ambos espacios independientes"
	)
	check(session.replace_garden_layout(original), "Deshacer recupera la copia eliminada")
	check(
		session.apply_garden_composition("patio", 0).is_empty(),
		"Deshacer vuelve a habilitar el acomodo"
	)
	check(session.save_garden_composition("shore", 0, 2), "Acomodo vacío válido")
	check(session.apply_garden_composition("shore", 0).is_empty(), "Restaurar vacío no fabrica")


func _protection() -> void:
	var session: GameSession = GardenFixture.complete_corner()
	var table: int = session.place_new_garden_object("mayak|chich", Vector2(580, 430), "patio", 0)
	session.save_garden_composition("patio", 0, 2)
	var plate: int = session.place_new_garden_object("lak|", Vector2.ZERO, "patio", 0, table)
	var before: Dictionary = session.snapshot()
	check(not session.delete_garden_copy(table).is_empty(), "No elimina soporte con plato")
	check(
		not session.apply_garden_composition("patio", 0).is_empty(),
		"No descarta un plato ajeno al acomodo"
	)
	check(session.snapshot() == before, "Los rechazos conservan el conjunto")
	GardenLayout.store_object(session.garden, plate)
	check(session.begin_village_visit("Áak", table, 18.0), "Visita activa")
	session.place_garden_object(table, Vector2(800, 450), "patio")
	GardenLayout.put_on_table(session.garden, plate, table)
	session.begin_village_visit("Áak", table, 18.0)
	before = session.snapshot()
	check(not session.delete_garden_copy(table).is_empty(), "Protege referencia del invitado")
	check(not session.delete_garden_copy(plate).is_empty(), "Protege también el plato del invitado")
	check(
		not session.apply_garden_composition("patio", 0).is_empty(),
		"No mueve el apoyo del invitado"
	)
	check(session.snapshot() == before, "El rechazo conserva invitado y tiempo")
	session.end_village_visit()
	GardenLayout.store_object(session.garden, plate)
	check(session.apply_garden_composition("patio", 0).is_empty(), "Puede restaurar tras despedir")
	before = session.garden.duplicate(true)
	session.delete_garden_copy(plate)
	check(session.replace_garden_layout(before), "Deshacer conserva identidad")
	var occupied: Dictionary = session.garden.duplicate(true)
	var duplicate: Dictionary = GardenLayout.object_by_id(occupied, plate).duplicate(true)
	duplicate.id = int(occupied.next_id)
	occupied.next_id += 1
	duplicate.support = table
	duplicate.stored = false
	duplicate.x = GardenLayout.object_by_id(occupied, table).x
	duplicate.y = GardenLayout.object_by_id(occupied, table).y
	occupied.objects.append(duplicate)
	var existing: Dictionary = GardenLayout.object_by_id(occupied, plate)
	existing.support = table
	existing.stored = false
	existing.x = duplicate.x
	existing.y = duplicate.y
	check(
		not GardenLayout.valid_state(occupied, GameContent.VILLAGE_SPACES),
		"Una superficie no admite dos platos"
	)
	var references: Dictionary = session.garden_compositions.duplicate(true)
	for index: int in range(GardenLayout.MAX_OBJECTS - session.garden.objects.size()):
		session.create_garden_object("mayak|chich", "workshop")
	check(session.create_garden_object("mayak|chich", "patio") == 0, "Límite global con almacén")
	var removable: int = int(session.garden.objects.back().id)
	check(session.delete_garden_copy(removable).is_empty(), "Eliminar libera capacidad")
	check(session.create_garden_object("mayak|chich", "patio") > removable, "No reutiliza IDs")
	check(session.garden_compositions == references, "Eliminar no borra composiciones históricas")


func _schema() -> void:
	var session: GameSession = GardenFixture.complete_corner()
	session.set_garden_identity("patio", "Árbol y descanso", ["sign"])
	var table: int = session.place_new_garden_object("mayak|chich", Vector2(580, 430), "patio", 0)
	session.save_garden_composition("patio", 0, 2)
	var original: Dictionary = session.snapshot()
	var restored: GameSession = GameSession.new()
	check(
		restored.restore(JSON.parse_string(JSON.stringify(original))), "Regreso completo desde JSON"
	)
	check(restored.snapshot() == original, "No cambia puntos, diseños ni resultados al cargar")
	for value: Variant in [
		[],
		{"patio": {"name": 8, "decorations": []}},
		{"patio": {"name": "Jardín", "decorations": [true]}},
		{"patio": {"name": "Jardín", "decorations": ["future"]}}
	]:
		var invalid: Dictionary = original.duplicate(true)
		invalid.garden_identity = value
		check(not restored.restore(invalid), "Rechaza identidad anidada inválida desde JSON")
		check(restored.snapshot() == original, "Una identidad inválida conserva toda la sesión")
	for value: Variant in [
		null, [], {"other": []}, {"patio": [1]}, {"patio": [{}, {}, {}]}, {"patio": {}}
	]:
		var invalid: Dictionary = original.duplicate(true)
		invalid.garden_compositions = value
		check(not restored.restore(invalid), "Valida tipos y capacidad anidados")
		check(restored.snapshot() == original, "Carga fallida conserva sesión")
	for field: String in ["id", "orientation", "x", "support", "stored", "key"]:
		var invalid: Dictionary = original.duplicate(true)
		invalid.garden_compositions.patio[0].objects[0][field] = null
		check(not restored.restore(invalid), "Rechaza datos incompletos por pieza")
	for value: Variant in [NAN, INF, -1, 0.5, 1000000]:
		var invalid: Dictionary = original.duplicate(true)
		invalid.garden_compositions.patio[0].objects[0].id = value
		check(not restored.restore(invalid), "Rechaza IDs no finitos, fraccionarios o futuros")
	var malformed: Dictionary = {
		"x": NAN, "orientation": 1.5, "support": INF, "stored": 0, "key": "future|"
	}
	for field: String in malformed:
		var invalid: Dictionary = original.duplicate(true)
		invalid.garden_compositions.patio[0].objects[0][field] = malformed[field]
		check(not restored.restore(invalid), "Valida números y tipos de cada colocación guardada")
		check(restored.snapshot() == original, "La restauración inválida no aplica datos parciales")
	var independent: Dictionary = restored.snapshot()
	independent.garden_identity.patio.name = "Otra cosa"
	independent.garden_compositions.patio[0].objects[0].id = table + 50
	check(restored.snapshot() == original, "Snapshots independientes")
	var compatible: Dictionary = original.duplicate(true)
	compatible.erase("garden_identity")
	compatible.erase("garden_compositions")
	check(restored.restore(compatible), "Formato vigente sin campos nuevos")
	check(
		restored.garden_identity.is_empty() and restored.garden_compositions.is_empty(),
		"Ausencia usa valores vacíos"
	)
	restored.reset()
	check(
		restored.garden_identity.is_empty() and restored.garden_compositions.is_empty(),
		"Reiniciar retira personalización"
	)
