extends ProjectTest

var manager: Node
var accessibility: Node
var repository: RefusingRepository
var home: Node
var capture_directory: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	accessibility = root.get_node("AccessibilityManager")
	repository = RefusingRepository.new("user://neighbours_validation.json")
	manager.use_save_repository(repository)
	manager.reset_save()
	accessibility.reduced_motion = true
	await _check_encounters()
	await _check_reunions_and_visits()
	finish("PG8: vecinos, paseo, orientación y regreso libre")


func _scenario() -> GameSession:
	var session: GameSession = GardenFixture.complete_corner()
	for level: Dictionary in GameContent.LEVEL_ORDER:
		session.complete_level(level.world, level.level)
	session.magic_points = 0
	return session


func _check_encounters() -> void:
	var session: GameSession = _scenario()
	session.rest_corner = RestCornerState.empty_state()
	check(manager.session.restore(session.snapshot()), "Posjuego con el primer proyecto pendiente")
	await _enter_home()
	check(home._hint.text.begins_with("Una pausa en el patio"), "La entrada señala una oportunidad")
	check(not home._neighbour_panel.visible and not paused, "Entrar permite pasear libremente")
	await _capture("01_entrada")
	home.open_map()
	check(
		home._map._opportunity.text.contains("Una pausa en el patio"),
		"El mapa reconoce el encuentro"
	)
	await _capture("02_mapa")
	_press(KEY_ESCAPE)
	check(not paused and root.gui_get_focus_owner() == home._map_button, "El mapa se puede ignorar")
	home.editor.open_editor("patio")
	check(
		home.editor.visible and home._neighbourhood.encounter().id == "patio_plans",
		"Decorar no consume el encuentro"
	)
	home.editor.hide()
	home.walker.position = home._neighbourhood.encounter().location
	home._process(0)
	check(home._destination == "Encuentro", "Hay un acceso caminando al encuentro")
	home._action.pressed.emit()
	var panel: Node = home._neighbour_panel
	check(panel.visible and paused, "El letrero abre sólo la conversación")
	check(
		panel._speaker.text == "Áak" and not panel._activity.visible,
		"La primera línea presenta a Áak"
	)
	_press(KEY_TAB)
	check(root.gui_get_focus_owner() == panel.close_button, "Tab recorre las acciones del diálogo")
	panel._next.pressed.emit()
	var second: String = panel._line.text
	check(
		panel._speaker.text == "Miis" and panel._activity.visible,
		"La segunda línea ofrece el proyecto"
	)
	await _capture("03_encuentro")
	_press(KEY_ESCAPE)
	check(not paused and not home._rest_panel.visible, "Se puede salir sin abrir el proyecto")
	check(
		manager.session.rest_corner == RestCornerState.empty_state(),
		"La charla no confirma el descanso"
	)
	_reload_save()
	await _enter_home()
	check(not home._neighbour_panel.visible, "Volver no impone la charla")
	home.open_map()
	home._map._opportunity.pressed.emit()
	panel = home._neighbour_panel
	check(panel.visible and panel._line.text == second, "Reanuda la misma línea desde el archivo")
	panel._activity.pressed.emit()
	check(
		home._rest_panel.visible and paused, "El acceso opcional abre el proyecto correspondiente"
	)
	home._rest_panel.close_panel()
	home.open_map()
	check(
		home._map._opportunity.text.contains("Un lugar para descansar"),
		"Mapa conserva el proyecto pendiente"
	)
	home._map.close_map()
	check(home._neighbourhood.encounter() == null, "No salta a otro encuentro en la misma visita")
	_reload_save()
	await _enter_home()
	check(home._neighbourhood.encounter() == null, "Mantiene el encuentro oído al entrar de nuevo")


func _check_reunions_and_visits() -> void:
	var session: GameSession = _scenario()
	var table: int = session.place_new_garden_object("mayak|chich", Vector2(600, 440), "patio", 1)
	_prepare_snack(session)
	session.try_expansion("rest")
	session.try_expansion("snack")
	session.select_expansion_guests(["Áak", "Miis"])
	check(session.inaugurate_expansion(), "Estreno con sus propios participantes")
	session.scene_states["world3_mission1"] = {
		"residents": ["Kaax", "Kuuts", "Báalam"], "delivered": [0]
	}
	check(manager.session.restore(session.snapshot()), "Aldea preparada para el regreso libre")
	await _enter_home()
	check(
		home._neighbourhood.encounter().id == "remember_clearing",
		"Propone una actividad tras completar proyectos"
	)
	home.walker.position = Vector2(640, 555)
	home._process(0)
	check(home._destination == "visit:" + str(table), "El patio conserva acceso a la mesa")
	home._action.pressed.emit()
	var offered: int = 0
	for button: Button in home._visit_panel._guests:
		if button.is_visible_in_tree() and not button.disabled:
			offered += 1
	check(offered == 11, "El panel ofrece los tres grupos terrestres")
	await _capture("04_invitaciones")
	home._visit_panel.close_panel()

	repository.refuse = true
	var errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var failed: bool = home.invite_guest("Ma'ax", table)
	Engine.print_error_messages = errors
	check(
		not failed and not home._visit.active(),
		"La escritura rechazada revierte representación e invitación"
	)
	check(
		not manager.session.hosted_village_guest("Ma'ax"), "Una invitación fallida no deja recuerdo"
	)
	repository.refuse = false
	accessibility.reduced_motion = false
	check(home.invite_guest("Ma'ax", table), "El invitado del taller llega por el sendero")
	var arrival: Vector2 = home._visit.ground_point()
	await create_timer(2.75).timeout
	check(
		arrival.x < 160 and home._visit.ground_point().distance_to(arrival) > 200,
		"Recorre la ruta antes de apoyar los pies junto a la mesa"
	)
	home.dismiss_visit()
	accessibility.reduced_motion = true

	for district: String in VillageNeighbours.DISTRICTS:
		for animal: String in VillageNeighbours.RESIDENTS[district]:
			if animal in ["Kay", "Ma'ax"]:
				continue
			check(home.invite_guest(animal, table), "Entra y ocupa un lateral real: " + animal)
			check(
				home._visit.active() and home._visit.ground_point().is_finite(),
				"Actuación compatible"
			)
			if animal == "Ch'íich'":
				await _capture("05_visita_desde_la_orilla")
			home.dismiss_visit()
	check(not home.invite_guest("Kay", table), "La mesa no invita a Kay")
	check(manager.session.village_experiences.visits.size() == 11, "Se guardan experiencias únicas")

	# Leer con el vecino del taller prueba la entrega y la visita como hechos independientes.
	home.change_district("workshop")
	home.walker.position = home._talk_points["Kaax"]
	home._process(0)
	check(home._destination == "talk:Kaax", "Se acerca a Kaax")
	home._action.pressed.emit()
	var panel: Node = home._neighbour_panel
	check(panel.visible and panel._speaker.text == "Kaax", "El saludo conserva su dueño")
	var initial_topics: Array[String] = home._neighbourhood.talk_topics.duplicate()
	check(initial_topics == ["mission", "visit"], "Muestra sólo sus experiencias confirmadas")
	panel._next.pressed.emit()
	var delivery_line: String = panel._line.text
	check(
		delivery_line == home._dialogue.lines_for("Kaax", true)[1],
		"Un encargo real usa el banco editable de agradecimientos"
	)
	_press(KEY_ESCAPE)
	_reload_save()
	await _enter_home()
	home.walker.position = home._talk_points["Kaax"]
	home._process(0)
	home._action.pressed.emit()
	panel = home._neighbour_panel
	check(panel._line.text == delivery_line, "El saludo y su avance sobreviven a la recarga")
	panel._next.pressed.emit()
	check(
		panel._line.text == home.neighbour_profile.visit_memories["Kaax"],
		"Reconoce la visita concreta"
	)
	await _capture("06_conversacion_reanudada")
	panel._next.pressed.emit()
	check(not paused, "Terminar devuelve al paseo")
	check(
		not manager.session.received_village_delivery("Kuuts"),
		"No atribuye el encargo a otro vecino"
	)

	check(
		home._neighbourhood.encounter().id == "remember_clearing",
		"Cambiar de barrio no cambia el encuentro"
	)
	home.open_map()
	home._map._opportunity.pressed.emit()
	check(
		home.district == "shore" and home._neighbour_panel.visible,
		"La oportunidad viaja y abre su destino"
	)
	home._neighbour_panel.close_panel()
	home._snack_button.pressed.emit()
	check(
		home._snack_panel._kay.visible, "Kay puede participar tras una merienda que no lo incluyó"
	)
	var preparation: Dictionary = manager.session.snack_project.duplicate(true)
	home._snack_panel._kay.pressed.emit()
	check(
		manager.session.hosted_village_guest("Kay"),
		"La merienda repetida sí confirma la visita de Kay"
	)
	check(
		manager.session.snack_project == preparation,
		"Conserva la preparación y los primeros invitados"
	)
	check(home._snack_panel.gathering.motions[0].pond.visible, "Kay conserva el agua")
	await _capture("07_kay_estanque")
	home._snack_panel._photo.pressed.emit()
	check(home._album._draft.guests == ["Kay"], "El álbum recibe el grupo que realmente apareció")
	home._album.close_panel()

	var opening: Dictionary = manager.session.village_expansion.opening.duplicate(true)
	home._expansion_button.pressed.emit()
	home._expansion_panel._guests["Miis"].button_pressed = false
	home._expansion_panel._guests["Ma'ax"].button_pressed = true
	check(
		"opening" not in home._neighbourhood.topics_for("Ma'ax"),
		"Cambiar invitados no cambia el estreno"
	)
	check(
		"clearing" not in home._neighbourhood.topics_for("Ma'ax"),
		"Seleccionar no confirma una reunión"
	)
	home._expansion_panel._replay.pressed.emit()
	check(
		"clearing" in home._neighbourhood.topics_for("Ma'ax"),
		"Reconoce la reunión posterior vivida"
	)
	check(manager.session.village_expansion.opening == opening, "Conserva el estreno")
	home._expansion_panel.close_panel()
	check(
		manager.session.magic_points == 0 and manager.session.learning_progress.is_empty(),
		"Convivir no suma puntos ni evidencia"
	)
	home.return_button.pressed.emit()
	await scene_changed
	manager.visit_home()
	await scene_changed
	await process_frame
	home = current_scene
	check(
		(
			manager.session.hosted_village_guest("Kay")
			and home._neighbourhood.encounter().id == "remember_clearing"
		),
		"Despedirse y volver conserva las oportunidades y experiencias"
	)

	home.open_map()
	home._map._opportunity.pressed.emit()
	home._neighbour_panel._next.pressed.emit()
	home._neighbour_panel._next.pressed.emit()
	_reload_save()
	await _enter_home()
	check(
		home._neighbourhood.encounter().id == "workshop_visit",
		"La invitación real habilita el encuentro del taller"
	)
	home.open_map()
	home._map._opportunity.pressed.emit()
	check(
		home.district == "workshop" and home._neighbour_panel._line.text.contains("me invitó"),
		"El anfitrión trae al taller la experiencia del patio"
	)
	await _capture("08_idea_en_el_taller")
	home._neighbour_panel.close_panel()


func _prepare_snack(session: GameSession) -> void:
	session.select_snack(["Ch'íich'"], "K'úum|", "flowers")
	session.begin_snack_preparation()
	var activity: CountingActivity = CountingActivity.new()
	activity.setup(SnackState.counting_set(), session.snack_project.preparation)
	for index: int in range(2):
		activity.help()
		activity.help()
		activity.submit()
		activity.submit()
	session.update_snack_preparation(activity.snapshot())
	check(session.confirm_snack_project(), "Prepara una merienda confirmada sólo con el ave")


func _enter_home() -> void:
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	home = current_scene


func _reload_save() -> void:
	var saved: Dictionary = repository.load_progress()
	check(manager.session.restore(saved), "Carga el archivo aislado")


func _press(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.pressed = true
	event.keycode = key
	root.push_input(event)


func _capture(label: String) -> void:
	var layout: ScreenLayout = home.get_node("ScreenLayout")
	for compact: bool in [false, true]:
		layout.preview_compact = compact
		if not capture_directory.is_empty():
			root.size = Vector2i(960, 540) if compact else Vector2i(1280, 720)
		layout.refresh()
		await process_frame
		await process_frame
		for panel: Node in [home._neighbour_panel, home._visit_panel, home._snack_panel]:
			if panel.visible:
				var frame: Control = panel.controls.get_child(0)
				check(
					frame.get_global_rect().encloses(panel.footer.get_global_rect()),
					"Acciones accesibles"
				)
		if not capture_directory.is_empty():
			await RenderingServer.frame_post_draw
			var suffix: String = "_compacto" if compact else ""
			check(
				(
					root.get_texture().get_image().save_png(
						capture_directory.path_join(label + suffix + ".png")
					)
					== OK
				),
				"Captura " + label + suffix
			)
	layout.preview_compact = false
	layout.refresh()
	if not capture_directory.is_empty():
		root.size = Vector2i(1280, 720)


class RefusingRepository:
	extends SaveRepository
	var refuse: bool = false

	func save_progress(data: Dictionary) -> Error:
		return ERR_CANT_CREATE if refuse else super.save_progress(data)
