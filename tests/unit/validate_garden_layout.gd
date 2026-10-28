extends ProjectTest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var garden: Dictionary = GardenLayout.empty_state()
	var table: int = GardenLayout.add_object(garden, "mayak|chich", "patio")
	var plate: int = GardenLayout.add_object(garden, "lak|", "patio")
	check(GardenLayout.move_object(garden, table, Vector2(600, 440), "patio"), "Coloca la mesa")
	check(GardenLayout.put_on_table(garden, plate, table), "Plato con apoyo real")
	check(not GardenLayout.put_on_table(garden, table, plate), "No admite apoyos circulares")
	check(
		GardenLayout.move_object(garden, table, Vector2(800, 450), "workshop"), "Mueve el conjunto"
	)
	check(
		GardenLayout.point(GardenLayout.object_by_id(garden, plate)) == Vector2(800, 450),
		"El plato acompaña la mesa"
	)
	check(GardenLayout.store_object(garden, table), "Guarda la mesa")
	check(GardenLayout.object_by_id(garden, plate).stored, "Conserva su plato en almacén")
	check(
		GardenLayout.valid_state(JSON.parse_string(JSON.stringify(garden))),
		"El conjunto vuelve de JSON"
	)
	check(
		GardenLayout.move_object(garden, table, Vector2(600, 440), "patio"), "Recupera el conjunto"
	)
	check(not GardenLayout.object_by_id(garden, plate).stored, "Recupera también el plato")
	var before: Dictionary = garden.duplicate(true)
	check(
		not GardenLayout.move_object(garden, table, Vector2(600, 580), "patio"),
		"No invade el sendero"
	)
	check(garden == before, "Un rechazo conserva todas las posiciones")
	check(GardenLayout.store_object(garden, plate), "Retira el plato por separado")
	check(GardenLayout.object_by_id(garden, plate).support == 0, "Retirarlo rompe sólo su apoyo")
	var chair: int = GardenLayout.add_object(garden, "k'áanche'|", "patio")
	check(
		not GardenLayout.move_object(garden, chair, Vector2(600, 440), "patio"),
		"No superpone apoyos en el suelo"
	)
	var invalid: Dictionary = garden.duplicate(true)
	invalid.objects[0].x = INF
	check(not GardenLayout.valid_state(invalid), "Rechaza posiciones no finitas")
	finish("Parcela, superficies y almacén")
