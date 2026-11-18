extends ProjectTest

var capture_directory: String = ""
var manager: Node
var accessibility: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	accessibility = root.get_node("AccessibilityManager")
	manager.use_save_repository(repository_for("village_visits"))
	manager.reset_save()
	for word: String in ["Áak", "Miis", "mayak", "chich", "lak"]:
		manager.learn_word(word)
	manager.record_learning(["mayak", "chich"], "practice", "setup/table", true)
	manager.record_learning(["lak"], "recall", "setup/plate")
	for level: Dictionary in GameContent.LEVEL_ORDER:
		manager.complete_level(level.world, level.level)
	manager.session.scene_states.world5_cine1 = {"complete": true}
	manager.prepare_sharing_corner()
	manager.purchase_design("mayak")
	manager.purchase_design("chich")
	var id: int = manager.session.create_garden_object("mayak|chich", "patio")
	check(manager.session.place_garden_object(id, Vector2(600, 440), "patio"), "Prepara mesa")
	check(manager.purchase_design("lak"), "Prepara el plato de la mesa")
	var plate: int = manager.session.create_garden_object("lak|", "patio")
	check(
		GardenLayout.put_on_table(manager.session.garden, plate, id), "El plato conserva su apoyo"
	)
	check(manager.session.magic_points == 0, "Las compras preparan saldo cero sin alterarlo")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	var baseline: Dictionary = manager.session.snapshot()
	home.walker.position = Vector2(640, 555)
	home._process(0)
	check(home._action.text == "Invitar a un amigo", "El contexto descubre la invitación")
	home._action.pressed.emit()
	check(paused and home._visit_panel.visible, "El panel de invitados pausa el mundo")
	await _capture("01_elegir_invitado")
	await _compact_capture(home, "02_elegir_compacto")
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	await process_frame
	check(not paused and not home._visit_panel.visible, "Esc cierra primero la invitación")
	check(root.gui_get_focus_owner() == home._action, "Cerrar devuelve el foco al origen")
	home._action.pressed.emit()
	home._visit_panel._guests[0].pressed.emit()
	check(not paused and home._visit.active(), "Elegir inicia la visita sin pago")
	check(not home._resident_views["Áak"].visible, "El vecino no aparece también en su casa")
	await create_timer(0.3).timeout
	await _capture("03_llegada_mirada")
	await create_timer(1).timeout
	await _capture("04_llegada_camino")
	await create_timer(1.5).timeout
	await _capture("05_aak_utiliza_mesa")
	var object_view: GardenObject = _table_view(home, id)
	var table_position: Vector2 = object_view.art.position
	await create_timer(0.2).timeout
	check(object_view.art.position == table_position, "La actuación no desplaza el mueble")
	var remaining: float = float(manager.session.village_visit.remaining)
	paused = true
	await create_timer(0.2).timeout
	check(float(manager.session.village_visit.remaining) == remaining, "Pausar detiene el tiempo")
	paused = false
	home.show_project()
	await process_frame
	remaining = float(manager.session.village_visit.remaining)
	await create_timer(0.2).timeout
	check(
		float(manager.session.village_visit.remaining) == remaining, "El proyecto detiene la visita"
	)
	home._project.hide()
	await process_frame
	manager.checkpoint(home)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(manager.session.snapshot()))
	var saved_remaining: float = float(saved.village_visit.remaining)
	check(manager.session.restore(saved), "Restaura datos independientes")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	home = current_scene
	check(home._visit.active(), "La visita se representa al regresar")
	check(
		absf(float(manager.session.village_visit.remaining) - saved_remaining) < 0.5,
		"Reanudar no reinicia su duración"
	)
	check(
		(
			home._visit.ground_point().distance_to(
				VillageVisitPlacement.meeting_point(
					manager.session.garden.objects[0],
					manager.session.garden,
					GameContent.VILLAGE_SPACES.space("patio")
				)
			)
			< 1
		),
		"Reanudar muestra el uso estable sin repetir la llegada"
	)
	await _capture("06_reanudada")
	accessibility.reduced_motion = true
	await process_frame
	await _compact_capture(home, "07_reanudada_compacto_sin_movimiento")
	accessibility.reduced_motion = false
	manager.session.advance_village_visit(float(manager.session.village_visit.remaining) - 1.5)
	await process_frame
	await _capture("08_despedida")
	await create_timer(1.8).timeout
	check(
		manager.session.village_visit.is_empty() and not home._visit.active(),
		"La visita termina sola"
	)
	check(home._resident_views["Áak"].visible, "El vecino vuelve a su lugar")
	check(home.invite_guest("Miis", id), "Se puede invitar a otro amigo después")
	await create_timer(2.7).timeout
	await _capture("09_miis_utiliza_mesa")
	home.editor.open_editor("patio")
	check(manager.session.village_visit.is_empty(), "Editar despide antes de cambiar el soporte")
	check(home._resident_views["Miis"].visible, "No queda un vecino oculto al editar")
	check(
		not _table_view(home, id).art.has_node("UseMotion"),
		"No quedan actuaciones en objetos anteriores"
	)
	home.editor.hide()
	check(home.invite_guest("Miis", id), "El soporte sigue disponible tras editar")
	manager.session.end_village_visit()
	await process_frame
	await process_frame
	check(manager.session.village_visit.is_empty(), "Se puede despedir antes del tiempo")
	check(not home._visit.active(), "La vista observa el cierre público de sesión")
	check(home._resident_views["Miis"].visible, "El cierre de sesión devuelve el vecino")
	check(manager.session.magic_points == 0, "Las visitas no pagan ni cobran puntos")
	check(manager.session.economy == baseline.economy, "No vuelve a preparar ni comprar diseños")
	check(manager.session.learning_progress == baseline.learning_progress, "No inventa evidencia")
	await _check_orientations(home, id)
	await _check_rejected_access(home)
	finish("Invitaciones, actuación fija, tiempo activo, edición y reanudación de aldea")


func _check_orientations(home: Node, id: int) -> void:
	manager.session.garden.objects[0].orientation = 1
	home._refresh_garden()
	check(home.invite_guest("Áak", id), "Invita junto a una mesa girada")
	await create_timer(2.7).timeout
	await _capture("10_mesa_girada")
	home.dismiss_visit()
	check(manager.purchase_design("lak") == false, "Las invitaciones no crean saldo para compras")
	home.change_district("workshop")
	await create_timer(0.6).timeout
	check(not home.invite_guest("Áak", id), "No invita a un vecino ausente desde otro barrio")


func _check_rejected_access(home: Node) -> void:
	home.change_district("patio")
	await create_timer(0.6).timeout
	var id: int = int(manager.session.garden.objects[0].id)
	check(home.invite_guest("Áak", id), "Prepara salida de barrio con visita")
	home.change_district("shore")
	await create_timer(0.6).timeout
	check(manager.session.village_visit.is_empty(), "La salida aceptada termina la visita")


func _table_view(home: Node, id: int) -> GardenObject:
	for child: Node in home._furniture.get_children():
		if child is GardenObject and child.object_id == id:
			return child
	return null


func _compact_capture(home: Node, name: String) -> void:
	root.size = Vector2i(640, 360)
	home.get_node("ScreenLayout").preview_compact = true
	home.get_node("ScreenLayout").refresh()
	home.get_node("ScreenLayout").register_controls(home._visit_panel.controls)
	await _capture(name)
	root.size = Vector2i(1280, 720)
	home.get_node("ScreenLayout").preview_compact = false
	home.get_node("ScreenLayout").refresh()
	home.get_node("ScreenLayout").register_controls(home._visit_panel.controls)


func _capture(name: String) -> void:
	await process_frame
	await process_frame
	if capture_directory.is_empty():
		return
	await RenderingServer.frame_post_draw
	check(
		root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK,
		"Captura de " + name
	)
