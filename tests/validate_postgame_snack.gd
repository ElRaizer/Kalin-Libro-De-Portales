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
	repository = RefusingRepository.new("user://postgame_snack.json")
	manager.use_save_repository(repository)
	manager.reset_save()
	var prepared: GameSession = GardenFixture.complete_corner()
	for level: Dictionary in GameContent.LEVEL_ORDER:
		prepared.complete_level(level.world, level.level)
	check(manager.session.restore(prepared.snapshot()), "Escenario de posjuego aislado")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	root.get_node("AccessibilityManager").reduced_motion = true
	home.change_district("shore")
	check(home._snack_button.visible, "La orilla ofrece la merienda")
	check(home.snack_profile.configuration_issues().is_empty(), "Contenido de autor completo")
	home._snack_button.pressed.emit()
	var panel: Node = home._snack_panel
	panel._guests.Kay.button_pressed = true
	panel._guests["Ch'íich'"].button_pressed = true
	panel._decoration.select(1)
	for index: int in range(panel._food.item_count):
		if panel._food.get_item_metadata(index) == "K'úum|":
			panel._food.select(index)
	await _capture(home, panel, "01_eleccion")
	var before: Dictionary = manager.session.snapshot()
	panel.start_preparation()
	check(
		manager.session.snack_project.preparation.counting.targets == [2, 10],
		"Cantidades ligadas a los invitados"
	)
	panel.workbench.edit("dot")
	panel.workbench.submit()
	check(panel.workbench.activity.session.mistakes == 1, "Conserva error real del numeral")
	var draft: Dictionary = manager.session.snack_project.duplicate(true)
	repository.refuse = true
	var errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	panel.workbench.edit("dot")
	Engine.print_error_messages = errors
	check(
		manager.session.snack_project == draft and panel.workbench.activity.session.units == 1,
		"Fallo al guardar conserva tablilla anterior"
	)
	repository.refuse = false
	await _book(home, panel._book, panel)
	panel.close_panel()
	home = await _reload()
	panel = home._snack_panel
	home.open_snack_project()
	check(
		(
			panel.workbench.activity.session.units == 1
			and panel.workbench.activity.session.mistakes == 1
		),
		"Reanuda borrador y error"
	)
	check(panel.workbench.activity.supports[0] == 1, "Reanuda el apoyo sin inventar recuerdo")
	panel.workbench.use_help()
	panel.workbench.submit()
	check(
		panel.workbench.activity.session.waiting and panel.workbench.provision.quantity == 2,
		"La bandeja muestra la cantidad confirmada"
	)
	await _capture(home, panel, "02_raciones")
	panel.workbench.submit()
	panel.workbench.use_help()
	panel.workbench.use_help()
	panel.workbench.submit()
	check(panel.workbench.provision.quantity == 10, "Diez bocados para dos invitados")
	panel.workbench.submit()
	check(
		not manager.session.snack_project.complete and panel._confirm.visible,
		"La preparación no confirma la reunión sola"
	)
	repository.refuse = true
	Engine.print_error_messages = false
	panel.confirm_project()
	Engine.print_error_messages = errors
	check(not manager.session.snack_project.complete, "Fallo de confirmación conserva preparación")
	repository.refuse = false
	root.get_node("AccessibilityManager").reduced_motion = false
	panel.confirm_project()
	await create_timer(1.2).timeout
	check(manager.session.snack_project.complete, "Proyecto confirmado")
	check(
		panel.gathering.actors.size() == 2 and panel.gathering.motions.size() == 2,
		"Actuaciones independientes para dos invitados"
	)
	var fish: Node = panel.gathering.motions[0]
	var bird: Node = panel.gathering.motions[1]
	check(fish.animal == "Kay" and fish.pond.visible, "Kay permanece en su hábitat")
	check(
		fish.pond.get_rect().has_point(fish.pond.to_local(fish.actor.global_position)),
		"Kay se mantiene dentro del agua"
	)
	check(
		bird.animal == "Ch'íich'" and bird._rig != null and bird._vessel.visible,
		"El ave usa su pose y cuenco"
	)
	check(fish._portion != bird._portion, "No comparte la comida animada entre actores")
	await _capture(home, panel, "03_reunion")
	await _contact_sequence(home, panel)
	root.get_node("AccessibilityManager").reduced_motion = true
	var completed: Dictionary = manager.session.snapshot()
	panel.confirm_project()
	check(
		manager.session.snack_project == completed.snack_project,
		"Repetir la reunión es gratuito y no renueva resultados"
	)
	check(
		manager.session.garden == before.garden and manager.session.economy == before.economy,
		"Comida temporal separada de muebles y diseños"
	)
	check(
		(
			manager.session.magic_points == int(before.magic_points)
			and manager.session.learning_progress == before.learning_progress
		),
		"Cantidades y reunión no acreditan palabras"
	)
	var moment: Dictionary = SnackState.memory(manager.session.snack_project)
	check(
		moment.decoration == "flowers" and moment.guests.size() == 2,
		"Recuerdo de la reunión elegida"
	)
	panel.close_panel()
	home = await _reload()
	home.open_snack_project()
	check(home._snack_panel.gathering.actors.size() == 2, "Reanuda reunión estable")
	await _capture(home, home._snack_panel, "05_reanudado")
	home._snack_panel.close_panel()
	home = await _practice(home)
	current_scene = null
	home.queue_free()
	await process_frame
	await process_frame
	finish("PG5: merienda, contactos, práctica elegible y continuidad")


func _practice(home: Node) -> Node:
	var practice: Node = home._practice
	home.change_district("patio")
	practice.open_hub(home.return_button)
	check(practice.available().size() == 3, "Tres familias cuando el contenido está disponible")
	await _capture(home, practice.hub, "06_familias")
	practice.hub.choose("numbers")
	practice.numbers.workbench.edit("dot")
	practice.numbers.workbench.submit()
	var numbers: Dictionary = practice.numbers.workbench.activity.snapshot()
	await _book(home, practice.numbers._book, practice.numbers)
	practice.numbers.close_panel()
	practice.open_hub(home.return_button)
	practice.hub.choose("paths")
	var route: Array[Vector2i] = GridReplayLayouts.cells(
		PathPracticeState.layout(practice.paths.activity.variant).solution[0]
	)
	practice.paths.press_cell(route[1])
	practice.paths.show_hint()
	var paths: Dictionary = practice.paths.activity.snapshot()
	await _capture(home, practice.paths, "07_camino")
	await _book(home, practice.paths._book, practice.paths)
	practice.paths.close_panel()
	manager.checkpoint(home)
	home = await _reload()
	practice = home._practice
	var checkpoint: Dictionary = JSON.parse_string(
		JSON.stringify(manager.saved_scene_state("village_home"))
	)
	practice.restore(checkpoint.practice)
	check(
		practice.numbers.workbench.activity.snapshot() == numbers,
		"Cada familia conserva su tablilla y apoyos"
	)
	check(practice.paths.activity.snapshot() == paths, "Conserva variante y camino parcial")
	var bad: Dictionary = paths.duplicate(true)
	bad.path = [[NAN, 2]]
	practice.paths.restore(bad)
	check(
		practice.paths.activity.snapshot() == paths, "Una restauración inválida conserva el camino"
	)
	practice.next_family = "numbers"
	practice.open_hub(home.return_button)
	practice.hub.choose("mixed")
	var learning: Dictionary = manager.session.learning_progress.duplicate(true)
	var points: int = manager.session.magic_points
	while not practice.numbers.workbench.activity.finished():
		if not practice.numbers.workbench.activity.session.waiting:
			practice.numbers.workbench.use_help()
			practice.numbers.workbench.use_help()
		practice.numbers.workbench.submit()
	practice.numbers.finish_practice()
	check(
		practice.paths.visible and not practice.numbers.visible,
		"Mixto alterna de cantidades a caminos"
	)
	practice.paths.restart()
	for index: int in range(1, route.size()):
		practice.paths._cells[route[index]].pressed.emit()
	check(
		not practice.paths.activity.controller.connected.is_empty(),
		"Completa el camino con las reglas existentes"
	)
	practice.paths.finish_practice()
	check(home.room.visible, "Mixto ofrece después palabras")
	check(
		manager.session.magic_points == points and manager.session.learning_progress == learning,
		"No inventa evidencia lingüística por cantidades ni caminos"
	)
	home.room.recall.first.text = "borrador"
	var words: Dictionary = home.room.snapshot()
	home.close_transient_ui()
	check(not paused and not home.room.visible, "Puede dejar mixto sin hacer todas las actividades")
	home.room.open_room(home.return_button)
	check(home.room.recall.first.text == str(words.answer), "Palabras conserva su propio borrador")
	home.room.close_room()
	return home


func _book(home: Node, button: Button, panel: Node) -> void:
	home._open_activity_book(button)
	await create_timer(0.6).timeout
	check(
		home.get_node("LibroHechizos").visible and panel.visible and paused,
		"El libro se superpone sin cerrar la actividad"
	)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	await create_timer(0.55).timeout
	check(
		not home.get_node("LibroHechizos").visible and panel.visible and paused,
		"Esc cierra sólo el libro y conserva la pausa de la actividad"
	)


func _reload() -> Node:
	check(manager.session.restore(repository.load_progress()), "Carga desde archivo aislado")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	await process_frame
	return current_scene


func _contact_sequence(home: Node, panel: Node) -> void:
	for motion: Node in panel.gathering.motions:
		motion.set_process(false)
	for moment: float in [0.4, 1.3, 1.8, 2.8]:
		for motion: Node in panel.gathering.motions:
			motion._pose(0.0)
			motion._apply_action(moment)
		await _capture(home, panel, "04_contacto_%s" % str(moment).replace(".", "_"))
	var bird: Node = panel.gathering.motions[1]
	bird._apply_action(bird._rig.contact_time())
	check(
		bird._rig.mouth_position().distance_to(bird._vessel.to_global(Vector2(60, 18))) < 1.0,
		"El pico alcanza la abertura real del cuenco"
	)


func _capture(home: Node, panel: Node, name: String) -> void:
	for compact: bool in [false, true]:
		var layout: ScreenLayout = home.get_node("ScreenLayout")
		layout.preview_compact = compact
		layout.refresh()
		await process_frame
		await process_frame
		var outer: Control = panel.controls.get_child(0)
		check(
			outer.get_global_rect().encloses(panel.footer.get_global_rect()),
			"Acciones contenidas en ambos perfiles"
		)
		check(
			outer.get_global_rect().encloses(panel.notice.get_global_rect()),
			"Avisos completos en ambos perfiles"
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
