extends ProjectTest

var manager: Node
var repository: RefusingRepository
var capture_directory: String = ""
var table_id: int = 0
var plate_id: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	repository = RefusingRepository.new("user://garden_personalization.json")
	manager.use_save_repository(repository)
	manager.reset_save()
	var prepared: GameSession = GardenFixture.complete_corner()
	prepared.rest_corner.complete = false
	check(manager.session.restore(prepared.snapshot()), "Fixture aislado válido")
	table_id = manager.session.place_new_garden_object("mayak|chich", Vector2(580, 430), "patio", 1)
	plate_id = manager.session.place_new_garden_object("lak|", Vector2.ZERO, "patio", 0, table_id)
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	check(home.garden_profile.configuration_issues().is_empty(), "Perfil de autor completo")
	root.get_node("AccessibilityManager").reduced_motion = true
	await _identity(home)
	await _compositions(home)
	await _failures(home)
	var expected: Dictionary = manager.session.snapshot()
	home._storage_panel.close_panel()
	home.editor.hide()
	manager.checkpoint(home)
	check(manager.session.restore(repository.load_progress()), "Restaura archivo vigente")
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	home = current_scene
	check(
		manager.session.garden_identity == expected.garden_identity,
		"Conserva nombre y adornos al reabrir"
	)
	check(
		manager.session.garden_compositions == expected.garden_compositions,
		"Conserva ambos acomodos"
	)
	check(
		manager.session.magic_points == int(expected.magic_points),
		"No acredita ni cobra al reanudar"
	)
	check(home._garden_identity._name.text == "Entre hojas y amigos", "Nombre visible reconstruido")
	check(home._garland.visible, "La guirnalda elegida vuelve")
	await _capture(home, null, "05_reanudado")
	home.editor.open_editor("patio")
	var storage: Node = home._storage_panel
	storage.open_storage(home.editor._tabs.get_node("Storage"))
	storage.request_delete(plate_id)
	var before: Dictionary = manager.session.snapshot()
	_escape()
	await process_frame
	check(not storage.visible and not paused, "Esc descarta confirmación y devuelve la pausa")
	check(manager.session.snapshot() == before, "Cerrar no elimina ni gasta")
	check(
		root.gui_get_focus_owner() == home.editor._tabs.get_node("Storage"),
		"Devuelve foco al botón real"
	)
	storage.open_storage(home.editor._tabs.get_node("Storage"))
	storage.queue_free()
	await process_frame
	check(not paused, "Destruir panel libera la pausa")
	current_scene = null
	home.queue_free()
	await process_frame
	await process_frame
	finish("Identidad, almacén, acomodos, deshacer y continuidad de PG4")


func _identity(home: Node) -> void:
	home.editor.open_editor("patio")
	var panel: Node = home._identity_panel
	var origin: Control = home.editor._tabs.get_node("Identity")
	panel.open_identity("patio", origin)
	check(paused and panel.visible, "La identidad pausa la edición")
	check(panel._decorations.sign.disabled, "El proyecto pendiente mantiene los adornos bloqueados")
	panel.name_field.text = "Borrador sin guardar"
	panel.close_panel()
	check(manager.session.garden_identity.is_empty(), "Volver descarta el nombre provisional")
	check(manager.session.confirm_rest_corner(), "Termina el proyecto previo")
	home._on_rest_changed()
	panel.open_identity("patio", origin)
	panel.name_field.text = "Entre hojas y amigos"
	for id: String in GardenIdentity.DECORATIONS:
		check(not panel._decorations[id].disabled, "Adorno obtenido del proyecto")
		panel._decorations[id].button_pressed = true
	var before: Dictionary = manager.session.snapshot()
	repository.refuse = true
	var errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	panel.save_identity()
	Engine.print_error_messages = errors
	check(manager.session.snapshot() == before, "Fallo de escritura conserva identidad anterior")
	repository.refuse = false
	panel.save_identity()
	check(manager.session.garden_identity.patio.name == "Entre hojas y amigos", "Guarda nombre")
	check(
		manager.session.garden_identity.patio.decorations.size() == 3,
		"Guarda tres adornos de autor"
	)
	check(
		manager.session.magic_points == int(before.magic_points), "Personalizar no cobra ni premia"
	)
	await _capture(home, panel, "01_identidad")
	panel.close_panel()
	check(root.gui_get_focus_owner() == origin, "Devuelve el foco a Nombre y adornos")
	home.editor.hide()
	await _capture(home, null, "02_rincon")


func _compositions(home: Node) -> void:
	home.editor.open_editor("patio")
	var panel: Node = home._storage_panel
	panel.open_storage(home.editor._tabs.get_node("Storage"))
	check(panel._capacity.text.contains("2 de 80"), "Explica capacidad global")
	panel.request_save(0)
	panel.cancel_action()
	check(manager.session.garden_compositions.is_empty(), "Cancelar no guarda acomodo")
	panel.request_save(0)
	panel.confirm_action()
	var original: Dictionary = manager.session.garden.duplicate(true)
	check(manager.session.garden_compositions.patio[0].objects.size() == 2, "Guarda mesa y plato")
	panel.close_panel()
	home.editor.select_object(table_id)
	home.editor.rotate_selected()
	home.editor.preview = Vector2(800, 450)
	home.editor.commit()
	panel.open_storage(home.editor._tabs.get_node("Storage"))
	panel.request_save(1)
	panel.confirm_action()
	check(manager.session.garden_compositions.patio.size() == 2, "Dos espacios por parcela")
	panel.restore_composition(0)
	check(manager.session.garden == original, "Restaura orientación y plato en la misma mesa")
	panel.request_delete(table_id)
	panel.confirm_action()
	check(
		manager.session.garden == original and panel.notice.text.contains("plato"),
		"Protege soporte con plato"
	)
	panel.cancel_action()
	panel.request_delete(plate_id)
	panel.confirm_action()
	check(manager.session.garden.objects.size() == 1, "Eliminar libera capacidad real")
	check(panel._capacity.text.contains("1 de 80"), "Actualiza el límite visible")
	var missing: Dictionary = manager.session.garden.duplicate(true)
	panel.restore_composition(0)
	check(
		manager.session.garden == missing and panel.notice.text.contains("Falta la copia"),
		"Faltante informado sin cambios parciales"
	)
	await _capture(home, panel, "03_pieza_faltante")
	panel.undo_edit()
	check(manager.session.garden == original, "Deshacer recupera exactamente la copia")
	panel.restore_composition(1)
	check(
		int(GardenLayout.object_by_id(manager.session.garden, table_id).orientation) == 2,
		"Recupera el otro giro"
	)
	await _capture(home, panel, "04_acomodos")


func _failures(home: Node) -> void:
	var panel: Node = home._storage_panel
	var before: Dictionary = manager.session.snapshot()
	repository.refuse = true
	var errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	panel.restore_composition(0)
	Engine.print_error_messages = errors
	check(manager.session.snapshot() == before, "Fallo al restaurar conserva jardín")
	panel.request_save(0)
	Engine.print_error_messages = false
	panel.confirm_action()
	Engine.print_error_messages = errors
	check(manager.session.snapshot() == before, "Fallo al sustituir conserva ambos espacios")
	panel.cancel_action()
	panel.request_delete(plate_id)
	Engine.print_error_messages = false
	panel.confirm_action()
	Engine.print_error_messages = errors
	check(manager.session.snapshot() == before, "Fallo al eliminar conserva copia y capacidad")
	repository.refuse = false
	panel.confirm_action()
	var deleted: Dictionary = manager.session.snapshot()
	repository.refuse = true
	Engine.print_error_messages = false
	panel.undo_edit()
	Engine.print_error_messages = errors
	check(
		manager.session.snapshot() == deleted and home.editor.has_undo(),
		"Fallo al deshacer conserva estado y reintento"
	)
	repository.refuse = false
	panel.undo_edit()
	check(manager.session.garden == before.garden, "Deshacer después del fallo recupera la copia")


func _escape() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)


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
