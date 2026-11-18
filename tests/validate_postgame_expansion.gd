extends ProjectTest

var manager: Node
var repository: RefusingRepository
var capture_directory: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	repository = RefusingRepository.new("user://postgame_expansion.json")
	manager.use_save_repository(repository)
	manager.reset_save()
	var prepared: GameSession = GardenFixture.complete_snack()
	prepared.magic_points = 0
	for level: Dictionary in GameContent.LEVEL_ORDER:
		prepared.complete_level(level.world, level.level)
	check(manager.session.restore(prepared.snapshot()), "Posjuego preparado")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	root.get_node("AccessibilityManager").reduced_motion = true
	home.change_district("shore")
	check(home._expansion_button.visible, "Proyecto en la orilla tras merienda y descanso")
	check(home.expansion_profile.configuration_issues().is_empty(), "Autoría de ampliación válida")
	check(home._map._places.size() == 3, "La ampliación pertenece a la orilla")
	home._expansion_button.pressed.emit()
	var panel: Node = home._expansion_panel
	check(panel.visible and paused, "Modal conserva pausa")
	await _capture(home, panel, "01_propuesta")
	panel._trials.rest.pressed.emit()
	check(manager.session.village_expansion.tried == ["rest"], "Prueba real de descanso")
	check(
		panel.gathering.motions[0].item == home.expansion_profile.rest_word,
		"Muestra asientos en uso"
	)
	panel._guests["Ma'ax"].button_pressed = true
	panel._guests["Áak"].button_pressed = true
	check(manager.session.village_expansion.guests == ["Ma'ax", "Áak"], "Elige los participantes")
	check(panel._confirm.disabled, "No estrena sin probar la otra opción")
	await _book(home, panel)
	await _escape()
	check(not paused and not panel.visible, "Escape devuelve el control a la aldea")
	home = await _reload()
	home.open_expansion_project()
	panel = home._expansion_panel
	check(manager.session.village_expansion.tried == ["rest"], "Carga prueba pendiente")
	check(panel._guests["Áak"].button_pressed, "Carga grupo elegido")
	var before: Dictionary = manager.session.village_expansion.duplicate(true)
	repository.refuse = true
	var errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	panel.try_purpose("snack")
	Engine.print_error_messages = errors
	check(manager.session.village_expansion == before, "Fallo de prueba conserva decisión")
	check(
		panel.gathering.motions[0].item == home.expansion_profile.rest_word,
		"Vista revierte tras fallo"
	)
	repository.refuse = false
	panel._trials.snack.pressed.emit()
	check(not panel._confirm.disabled, "Ambas pruebas y grupo habilitan estreno")
	check(panel.gathering.actors.size() == 2, "Dos actores con apoyos propios")
	check(
		panel.gathering.motions[0]._portion != panel.gathering.motions[1]._portion,
		"Porciones independientes"
	)
	root.get_node("AccessibilityManager").reduced_motion = false
	for motion: Node in panel.gathering.motions:
		motion.set_process(false)
	for moment: float in [0.4, 1.3, 2.8]:
		for motion: Node in panel.gathering.motions:
			motion._pose(0.0)
			motion._apply_action(moment)
		await _capture(home, panel, "02_merienda_%s" % str(moment).replace(".", "_"))
	root.get_node("AccessibilityManager").reduced_motion = true
	var baseline: Dictionary = manager.session.snapshot()
	repository.refuse = true
	Engine.print_error_messages = false
	panel.confirm_project()
	Engine.print_error_messages = errors
	check(not manager.session.village_expansion.complete, "Fallo al inaugurar conserva proyecto")
	check("El claro" not in home._available_spots(), "Guardado fallido no abre terreno")
	repository.refuse = false
	panel.confirm_project()
	check(manager.session.village_expansion.complete, "Estreno confirmado")
	check("El claro" in home._available_spots(), "Interacción física permanente")
	check(
		panel._replay.visible and not panel._confirm.visible, "Reunión posterior sin preparativos"
	)
	await _capture(home, panel, "03_inauguracion")
	var opening: Dictionary = manager.session.village_expansion.opening.duplicate(true)
	panel.replay()
	check(manager.session.village_expansion.opening == opening, "Repetición no confirma otra vez")
	check(manager.session.magic_points == 0, "Estreno y repetición gratuitos")
	check(manager.session.garden == baseline.garden, "Provisión y asientos temporales")
	check(manager.session.learning_progress == baseline.learning_progress, "No acredita palabras")
	await _book(home, panel)
	panel.close_panel()
	await _capture(home, null, "04_claro_merienda")
	home.go_to_place("El claro")
	check(not home._route.is_empty(), "Ruta desde la llegada hasta el claro")
	for step: int in range(200):
		if panel.visible:
			break
		home._process(0.02)
	check(panel.visible and paused, "El letrero abre la reunión al llegar")
	panel.try_purpose("rest")
	check(manager.session.village_expansion.purpose == "rest", "Redecoración inmediata")
	check(manager.session.village_expansion.opening == opening, "Recuerdo inicial intacto")
	repository.refuse = true
	Engine.print_error_messages = false
	panel.try_purpose("snack")
	panel._guests["Ma'ax"].button_pressed = false
	Engine.print_error_messages = errors
	repository.refuse = false
	check(
		manager.session.village_expansion.purpose == "rest",
		"Redecoración fallida conserva uso anterior"
	)
	check(panel._guests["Ma'ax"].button_pressed, "Invitación fallida restaura selección visible")
	manager.retry_save()
	check(manager.save_status_message.is_empty(), "Reintentar confirma el estado conservado")
	await _capture(home, panel, "05_redecoracion")
	panel.close_panel()
	await _capture(home, null, "06_claro_descanso")
	home.open_map()
	check("El claro compartido" in home._map._places[2].text, "Mapa reconoce la extensión")
	await _capture(home, null, "08_mapa")
	home._map._travel("patio")
	check(home.district == "patio" and not paused, "Retorno entre barrios")
	home.change_district("shore")
	check(home._expansion_gathering.actors.size() == 2, "Vuelve sin preparación nueva")
	var table: int = manager.session.place_new_garden_object(
		"mayak|chich", Vector2(400, 237), "shore", 0
	)
	var plate: int = manager.session.place_new_garden_object(
		"lak|", Vector2(400, 237), "shore", 0, table
	)
	check(table != 0 and plate != 0, "Muebles propios en la parcela nueva")
	check(
		manager.session.place_garden_object(table, Vector2(800, 450), "shore", 1),
		"Gira el conjunto en suelo suficiente"
	)
	check(
		manager.session.place_garden_object(table, Vector2(500, 237), "shore", 0),
		"Mueve el conjunto a la ampliación"
	)
	check(
		(
			GardenLayout.point(GardenLayout.object_by_id(manager.session.garden, plate))
			== Vector2(500, 237)
		),
		"Plato sigue su mesa"
	)
	home._refresh_garden()
	home.walker.position = Vector2(500, 237)
	manager.checkpoint(home)
	home = await _reload()
	var shore: VillageSpace = GameContent.VILLAGE_SPACES.space("shore")
	check(
		not VillageGround.blocked(
			home.walker.position, manager.session.garden, "shore", shore, true
		),
		"Reanudar aparta a Kalin de un obstáculo"
	)
	check(
		home._expansion_gathering.motions[0].item == home.expansion_profile.rest_word,
		"Reanuda propósito actual"
	)
	check(manager.session.village_expansion.opening == opening, "Reanuda recuerdo independiente")
	home.open_expansion_project()
	panel = home._expansion_panel
	panel._guests["Ma'ax"].button_pressed = false
	panel._guests.Miis.button_pressed = true
	check(manager.session.village_expansion.guests == ["Áak", "Miis"], "Elige nueva visita")
	panel.replay()
	await _capture(home, panel, "07_nueva_visita")
	panel.close_panel()
	var geometry: VillageSpaces = GameContent.VILLAGE_SPACES.duplicate(true)
	geometry.space("patio").plot = Rect2(300, 350, 600, 150)
	check(
		GameContent.VILLAGE_SPACES.space("patio").plot == Rect2(230, 350, 800, 190),
		"Configuración canónica inmutable"
	)
	current_scene = null
	home.queue_free()
	await process_frame
	await process_frame
	finish("PG6: estreno, rediseño, mapa, recorrido y reanudación")


func _book(home: Node, panel: Node) -> void:
	panel._book.grab_focus()
	panel._book.pressed.emit()
	await process_frame
	await process_frame
	check(home.get_node("LibroHechizos").visible and panel.visible, "Libro sobre proyecto")
	check(
		panel.controls.process_mode == Node.PROCESS_MODE_DISABLED, "Libro detiene actuación e input"
	)
	await _escape()
	await create_timer(0.6).timeout
	check(panel.visible and paused, "Cierra sólo el libro y conserva el proyecto")
	check(root.gui_get_focus_owner() == panel._book, "Devuelve foco al libro del proyecto")


func _escape() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _reload() -> Node:
	check(manager.session.restore(repository.load_progress()), "Carga archivo aislado")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	await process_frame
	return current_scene


func _capture(home: Node, panel: Node, name: String) -> void:
	for compact: bool in [false, true]:
		var layout: ScreenLayout = home.get_node("ScreenLayout")
		layout.preview_compact = compact
		layout.refresh()
		await process_frame
		await process_frame
		if panel != null:
			var outer: Control = panel.controls.get_child(0)
			check(
				outer.get_global_rect().encloses(panel.footer.get_global_rect()),
				"Acciones completas en ambos perfiles"
			)
			check(
				outer.get_global_rect().encloses(panel.notice.get_global_rect()),
				"Avisos contenidos"
			)
		if not capture_directory.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(
				capture_directory.path_join(name + ("_compacto" if compact else "") + ".png")
			)
	home.get_node("ScreenLayout").preview_compact = false
	home.get_node("ScreenLayout").refresh()


class RefusingRepository:
	extends SaveRepository
	var refuse: bool = false

	func save_progress(data: Dictionary) -> Error:
		return ERR_CANT_CREATE if refuse else super.save_progress(data)
