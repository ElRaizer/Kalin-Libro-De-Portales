extends ProjectTest

var manager: Node
var accessibility: Node
var capture_directory: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	accessibility = root.get_node("AccessibilityManager")
	manager.use_save_repository(repository_for("rest_corner"))
	manager.reset_save()
	for word: String in ["Áak", "Miis", "mayak", "k'áanche'", "k'áan", "chich"]:
		manager.learn_word(word)
	manager.record_learning(["mayak", "chich"], "practice", "supported", true)
	manager.prepare_sharing_corner()
	manager.purchase_design("mayak")
	manager.purchase_design("chich")
	for level: Dictionary in GameContent.LEVEL_ORDER:
		manager.complete_level(level.world, level.level)
	check(manager.session.magic_points == 0, "Prueba con saldo cero real")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	check(not home._rest_button.visible, "No inaugura el posjuego sólo por completar niveles")
	home.open_rest_project()
	check(not paused and not home._rest_panel.visible, "Conserva las visitas previas al final")
	manager.session.scene_states.world5_cine1 = {"complete": true}
	manager.go_to_scene("main_menu")
	await scene_changed
	await process_frame
	var menu: Node = current_scene
	check(menu.get_node("UI/VisitButton").text == "Volver a mi aldea", "El menú invita a volver")
	check(
		root.gui_get_focus_owner() == menu.get_node("UI/VisitButton"),
		"El regreso tiene foco al terminar"
	)
	await _capture("01_menu_regreso")
	menu.get_node("UI/VisitButton").pressed.emit()
	await scene_changed
	await process_frame
	home = current_scene
	check(
		home._rest_button.visible and not home._rest_panel.visible,
		"La invitación es elegible, sin ventana automática"
	)
	var baseline: Dictionary = manager.session.snapshot()
	home._rest_button.pressed.emit()
	check(paused and home._rest_panel.visible, "Leer la invitación pausa el paseo")
	check(int(manager.session.rest_corner.intro) == 0, "Abrir no salta el primer momento")
	await _capture("02_invitacion")
	home._rest_panel._primary.pressed.emit()
	await _escape()
	check(not paused and int(manager.session.rest_corner.intro) == 1, "Esc guarda el momento leído")
	check(root.gui_get_focus_owner() == home._rest_button, "La salida devuelve el foco al botón")
	home = await _reload_home()
	check(not home._rest_panel.visible, "Reanudar no impone otra ventana")
	home.open_rest_project()
	check(
		home._rest_panel._message.text == home.rest_profile.invitation,
		"Continúa la línea pendiente"
	)
	home._rest_panel._primary.pressed.emit()
	home._rest_panel._primary.pressed.emit()
	check(
		home._rest_panel._primary.disabled, "La elección requiere decidir, no adivina por defecto"
	)
	check(
		root.gui_get_focus_owner() in home._rest_panel._option_buttons,
		"El foco permite elegir por teclado"
	)
	await _capture("03_alternativas")
	await _compact_capture(home, "04_alternativas_compacto")
	for index: int in range(home.rest_profile.options.size()):
		check(
			(
				home._rest_panel._option_buttons[index].icon
				== manager.get_visual_texture(home.rest_profile.options[index].word)
			),
			"Las alternativas muestran la ilustración completa del libro, sin capas parciales"
		)
		home._rest_panel._option_buttons[index].pressed.emit()
		await create_timer(0.85).timeout
		check(home._rest_panel.preview.motion != null, "La elección representa el uso de su objeto")
		await _capture("05_prueba_%d" % index)
		_check_bounds(home._rest_panel)
	check(manager.session.garden == baseline.garden, "Probar no crea muebles permanentes")
	check(manager.session.economy == baseline.economy, "Probar no compra ni vuelve a preparar")
	home._rest_panel.close_panel()
	home = await _reload_home()
	home.open_rest_project()
	check(manager.session.rest_corner.choice == "k'áan", "Conserva la hamaca elegida sin confirmar")
	check(not manager.session.rest_corner.complete, "Cerrar una prueba no termina el proyecto")
	check(home._rest_panel.preview.motion._receiving == 1.0, "Reanudar muestra el uso estable")
	accessibility.reduced_motion = true
	await _compact_capture(home, "06_hamaca_reanudada_compacto")
	accessibility.reduced_motion = false
	home._rest_panel._primary.pressed.emit()
	check(
		manager.session.rest_corner.complete and home._garland.visible,
		"Confirmar obtiene la guirnalda"
	)
	check(int(manager.session.rest_corner.result) == 0, "La reacción aún requiere lectura")
	await _capture("07_resultado_aak")
	home._rest_panel.close_panel()
	home = await _reload_home()
	check(home._garland.visible, "La guirnalda permanece al regresar")
	home.open_rest_project()
	check(int(manager.session.rest_corner.result) == 0, "No da por leído el resultado al cargar")
	check(
		home._rest_panel._message.text == home.rest_profile.option_for("k'áan").aak_reaction,
		"Retoma la reacción de la elección vivida"
	)
	home._rest_panel._primary.pressed.emit()
	await _capture("08_resultado_miis")
	home._rest_panel._primary.pressed.emit()
	await _capture("09_rincon_terminado")
	var complete: Dictionary = manager.session.rest_corner.duplicate(true)
	home._rest_panel._primary.pressed.emit()
	check(manager.session.rest_corner == complete, "Disfrutar otra vez no confirma de nuevo")
	check(
		manager.session.magic_points == baseline.magic_points, "Colaborar no exige ni entrega saldo"
	)
	check(
		manager.session.learning_progress == baseline.learning_progress, "No añade evidencia falsa"
	)
	check(manager.session.economy == baseline.economy, "El resultado no compra diseños")
	home._rest_panel.close_panel()
	await _capture("10_guirnalda_en_patio")
	home.editor.open_editor("patio")
	home.editor.new_copy("mayak|chich")
	home.editor.preview = Vector2(600, 440)
	home.editor.commit()
	var table_id: int = int(manager.session.garden.objects[0].id)
	check(GardenLayout.store_object(manager.session.garden, table_id), "Retira un mueble propio")
	home.editor.hide()
	home._refresh_garden()
	check(
		manager.session.rest_corner == complete and home._garland.visible,
		"Retirar muebles no borra el proyecto vivido"
	)
	home.open_rest_project()
	home._rest_panel._designs.pressed.emit()
	check(
		not paused and home._project.visible, "Diseños sigue siendo una actividad opcional separada"
	)
	home._project.hide()
	manager.go_to_scene("main_menu")
	await scene_changed
	await process_frame
	check(
		current_scene.get_node("UI/VisitHint").text.begins_with("Nuestro rincón"),
		"El menú reconoce el proyecto terminado"
	)
	await _capture("11_menu_rincon")
	finish(
		"Posjuego: invitación manual, tres soluciones, pruebas gratuitas y guirnalda persistente"
	)


func _reload_home() -> Node:
	manager.checkpoint(current_scene)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(manager.session.snapshot()))
	check(manager.session.restore(snapshot), "Carga el estado del proyecto desde JSON")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	return current_scene


func _escape() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	await process_frame
	await process_frame


func _check_bounds(panel: Node) -> void:
	for button: Node in panel.controls.find_children("*", "Button", true, false):
		if button is Button and button.is_visible_in_tree():
			check(button.get_global_rect().end.y <= 720, "Las acciones caben en la pantalla")
			check(button.get_global_rect().end.x <= 1280, "Las alternativas no desbordan")


func _compact_capture(home: Node, name: String) -> void:
	root.size = Vector2i(640, 360)
	home.get_node("ScreenLayout").preview_compact = true
	home.get_node("ScreenLayout").refresh()
	home.get_node("ScreenLayout").register_controls(home._rest_panel.controls)
	await _capture(name)
	_check_bounds(home._rest_panel)
	root.size = Vector2i(1280, 720)
	home.get_node("ScreenLayout").preview_compact = false
	home.get_node("ScreenLayout").refresh()


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
