extends ProjectTest

const NARRATIVE: Dictionary = {
	"kind": "home", "title": "Nuestro rincón", "animal": "Áak", "item": "mayak", "quality": "chich"
}

var manager: Node
var accessibility: Node
var repository: RefusingRepository
var capture_directory: String = ""
var home: Node
var album: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	accessibility = root.get_node("AccessibilityManager")
	repository = RefusingRepository.new("user://personal_album_validation.json")
	manager.use_save_repository(repository)
	manager.reset_save()
	var session: GameSession = GardenFixture.complete_snack()
	for level: Dictionary in GameContent.LEVEL_ORDER:
		session.complete_level(level.world, level.level)
	session.scene_states["world5_farewell"] = {"gifts": [0, 1, 2], "memory": NARRATIVE}
	session.magic_points = 0
	var table: int = session.place_new_garden_object("mayak|chich", Vector2(600, 440), "patio", 1)
	var plate: int = session.place_new_garden_object("lak|", Vector2.ZERO, "patio", 0, table)
	check(table > 0 and plate > 0, "Prepara una mesa girada y su plato")
	check(
		session.set_garden_identity("patio", "Mi patio", ["sign", "gathering"]), "Prepara adornos"
	)
	session.try_expansion("rest")
	session.try_expansion("snack")
	session.select_expansion_guests(["Miis", "Áak"])
	check(session.inaugurate_expansion(), "Prepara la reunión del claro")
	var initial: Dictionary = session.snapshot()
	var validated: Dictionary = SaveSchema.validate(initial)
	check(
		manager.session.restore(initial),
		str(validated.get("_load_error", "Restaura el escenario de posjuego"))
	)
	if validated.has("_load_error"):
		finish("PG7: escenario inválido")
		return
	await _enter_home()
	home._album_button.pressed.emit()
	check(album.visible and paused and not album._stage_slot.visible, "Álbum vacío y modal")
	_press(KEY_ESCAPE)
	check(not paused and root.gui_get_focus_owner() == home._album_button, "Esc devuelve el foco")
	home.walker.position = Vector2(640, 555)
	home._process(0)
	home._action.pressed.emit()
	home._visit_panel._guests[0].pressed.emit()
	check(home._visit.active(), "La invitación real crea la fuente")
	if not home._visit.active():
		finish("PG7: no inició la visita")
		return
	await process_frame
	home._action.pressed.emit()
	check(home._visit_panel._photo.is_visible_in_tree(), "Ofrece componer desde la mesa")
	home._visit_panel._photo.pressed.emit()
	check(album.visible and paused and album._draft.kind == "visit", "Abre la cámara de la visita")
	check(root.gui_get_focus_owner() == album._title, "Foco inicial en el título")
	var remaining: float = float(manager.session.village_visit.remaining)
	album._title.text = "Tarde con Áak"
	album._frame.select(1)
	album._frame.item_selected.emit(1)
	album._pose.select(0)
	album._pose.item_selected.emit(0)
	await _capture("01_visita_composicion")
	check(
		float(manager.session.village_visit.remaining) == remaining,
		"Componer pausa el reloj de la visita"
	)
	album._clean_button.pressed.emit()
	check(not album.controls.visible and album._clean_screen.visible, "Oculta todos los controles")
	await _capture("02_visita_limpia")
	_press(KEY_ESCAPE)
	check(
		album.controls.visible and paused and root.gui_get_focus_owner() == album._clean_button,
		"Esc restaura los controles y conserva pausa y foco"
	)
	var before: Dictionary = manager.session.snapshot()
	album._save_button.pressed.emit()
	var after: Dictionary = manager.session.snapshot()
	var moment: Dictionary = manager.session.personal_moments()[0]
	after.personal_album = []
	check(after == before, "Guardar sólo cambia el álbum")
	check(
		(
			moment.title == "Tarde con Áak"
			and moment.frame == "close"
			and is_equal_approx(moment.pose, 0.2)
			and moment.guests == ["Áak"]
		),
		"Guarda título, cámara, pose e invitado"
	)
	check(moment.setting.identity.name == "Mi patio", "Conserva la identidad y adornos al invitar")
	check(moment.setting.objects[0].orientation == 1, "Guarda el giro de la mesa")
	check(moment.setting.objects[1].support == table, "Guarda la superficie del plato")
	var image_before: PackedByteArray = await _rendered_photo()
	album.close_panel()
	home.dismiss_visit()
	home._album_button.pressed.emit()
	check(
		album._recent_button.is_visible_in_tree(), "Después de la despedida ofrece la última foto"
	)
	album.close_panel()
	check(manager.delete_garden_copy(plate).is_empty(), "Elimina el plato original")
	check(manager.delete_garden_copy(table).is_empty(), "Elimina la mesa original")
	var no_decorations: Array[String] = []
	check(
		manager.set_garden_identity("patio", "Otro rincón", no_decorations),
		"Cambia nombre y adornos"
	)
	var loaded: Dictionary = repository.load_progress()
	check(manager.session.restore(loaded), "Reabre la partida desde el JSON del repositorio")
	await _enter_home()
	home._album_button.pressed.emit()
	var restored: Dictionary = manager.session.personal_moments()[0]
	check(restored == moment, "La foto conserva la composición al reanudar sin el jardín original")
	var image_after: PackedByteArray = await _rendered_photo()
	if not capture_directory.is_empty():
		check(
			not image_before.is_empty() and image_before == image_after,
			"La imagen restaurada permanece idéntica"
		)
	check(
		VillageMemory.from_checkpoint(manager.saved_scene_state("world5_farewell")) == NARRATIVE,
		"Conserva el recuerdo narrativo al reanudar"
	)
	await _capture("03_album_reanudado")
	album.close_panel()

	home.open_rest_project()
	home._rest_panel._photo.pressed.emit()
	check(album._draft.kind == "rest", "El descanso confirmado ofrece componer")
	_press(KEY_TAB)
	check(root.gui_get_focus_owner() == album._guest_buttons[0], "Tab recorre los controles")
	check(album._replace_button.visible, "Permite sustituir antes de llenar el álbum")
	await _capture("08_descanso")
	album.close_panel()
	accessibility.reduced_motion = true
	home.change_district("shore")
	home._snack_button.pressed.emit()
	home._snack_panel._photo.pressed.emit()
	check(album._draft.kind == "snack", "La merienda confirmada ofrece componer")
	check(not album._preview_motion.visible, "Respeta la preferencia de movimiento reducido")
	await _capture("04_merienda_grupo")
	album._guest_buttons[1].button_pressed = false
	album._guest_buttons[0].button_pressed = false
	check(
		album._guest_buttons[0].button_pressed and album._draft.guests == ["Kay"],
		"Permite seleccionar invitados presentes y conserva al menos uno"
	)
	album._save_button.pressed.emit()
	var snack_photo: Dictionary = manager.session.personal_moments()[1]
	check(
		snack_photo.setting.decoration == "flowers" and snack_photo.guests == ["Kay"],
		"Guarda la foto de la merienda"
	)
	album.close_panel()
	home._expansion_button.pressed.emit()
	home._expansion_panel._photo.pressed.emit()
	check(album._draft.kind == "expansion", "El claro inaugurado ofrece componer")
	accessibility.reduced_motion = false
	album._update_controls()
	album._preview_motion.button_pressed = true
	await create_timer(0.2).timeout
	album._preview_motion.button_pressed = false
	var frozen: float = album._camera.current_pose()
	await create_timer(0.2).timeout
	check(frozen != 4.0 and album._camera.current_pose() == frozen, "Pausa un instante exacto")
	await _capture("05_claro_pose")
	album._save_button.pressed.emit()
	check(
		manager.session.personal_moments()[2].pose == frozen,
		"El álbum recupera el instante pausado"
	)
	album.close_panel()

	_check_capacity(moment)
	await _capture("06_album_lleno")
	await _check_transactions()
	manager.reset_save()
	check(manager.session.personal_moments().is_empty(), "Reiniciar vacía el álbum")
	finish("PG7: composición, capturas y álbum personal")


func _enter_home() -> void:
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	home = current_scene
	album = home._album


func _check_capacity(moment: Dictionary) -> void:
	for index: int in range(3, PersonalAlbum.LIMIT):
		var another: Dictionary = moment.duplicate(true)
		another.title = "Foto %d" % (index + 1)
		check(manager.save_personal_moment(another), "Añade hasta el límite")
	check(not manager.save_personal_moment(moment), "La foto trece requiere sustituir")
	home._album_button.pressed.emit()
	check(album._summary.text == "12 de 12 recuerdos", "Galería completa y seleccionable")


func _check_transactions() -> void:
	var full: Array[Dictionary] = manager.session.personal_moments()
	album.close_panel()
	home._snack_button.pressed.emit()
	home._snack_panel._photo.pressed.emit()
	album._title.text = "Otra merienda"
	album._save_button.pressed.emit()
	check(
		album._replacement.item_count == full.size() and album._save_button.disabled,
		"Sustituir exige elegir una foto y confirmar"
	)
	await _capture("07_sustitucion")
	album._replacement.select(0)
	album._replacement.item_selected.emit(0)
	var previous_file: String = FileAccess.get_file_as_string(repository.save_path)
	repository.refuse = true
	var errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	album._save_button.pressed.emit()
	Engine.print_error_messages = errors
	check(manager.session.personal_moments() == full, "Falla la sustitución sin tocar el álbum")
	check(
		FileAccess.get_file_as_string(repository.save_path) == previous_file,
		"Falla sin cambiar el archivo"
	)
	check(album._replacing and album._title.text == "Otra merienda", "Permite reintentar")
	repository.refuse = false
	album._save_button.pressed.emit()
	var replaced: Array[Dictionary] = manager.session.personal_moments()
	check(
		replaced[0].title == "Otra merienda" and replaced.slice(1) == full.slice(1),
		"Sustituye sólo el recuerdo elegido"
	)
	album._delete_button.pressed.emit()
	check(
		album._delete_pending and manager.session.personal_moments() == replaced,
		"Pide confirmación"
	)
	_press(KEY_ESCAPE)
	check(
		not album._delete_pending and paused, "Esc cancela el borrado y conserva el álbum abierto"
	)
	album._delete_button.pressed.emit()
	repository.refuse = true
	Engine.print_error_messages = false
	album._delete_button.pressed.emit()
	Engine.print_error_messages = errors
	check(manager.session.personal_moments() == replaced, "Falla el borrado sin tocar el álbum")
	repository.refuse = false
	album._delete_button.pressed.emit()
	check(manager.session.personal_moments() == full.slice(1), "Borra solamente el elegido")
	album.close_panel()


func _press(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.pressed = true
	root.push_input(event)


func _rendered_photo() -> PackedByteArray:
	if capture_directory.is_empty():
		return []
	await process_frame
	await RenderingServer.frame_post_draw
	return album._camera._viewport.get_texture().get_image().get_data()


func _capture(label: String) -> void:
	var layout: ScreenLayout = home.get_node("ScreenLayout")
	for compact: bool in [false, true]:
		layout.preview_compact = compact
		layout.refresh()
		await process_frame
		await process_frame
		if album.controls.visible:
			var outer: Control = album.controls.get_child(0)
			check(
				outer.get_global_rect().encloses(album.footer.get_global_rect()), "Botones visibles"
			)
			check(outer.get_global_rect().encloses(album.notice.get_global_rect()), "Aviso visible")
			if album._stage_slot.visible:
				var frame: Rect2 = album._camera.get_global_rect()
				check(outer.get_global_rect().encloses(frame), "Foto contenida en ambos perfiles")
				check(frame.size.x > 490 and frame.size.y > 270, "Foto legible en ambos perfiles")
		else:
			check(album._camera.size.x > 1100, "La foto limpia se amplía")
		if not capture_directory.is_empty():
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			var suffix: String = "_compacto" if compact else ""
			check(
				image.save_png(capture_directory.path_join(label + suffix + ".png")) == OK,
				"Captura"
			)
	layout.preview_compact = false
	layout.refresh()


class RefusingRepository:
	extends SaveRepository
	var refuse: bool = false

	func save_progress(data: Dictionary) -> Error:
		return ERR_CANT_CREATE if refuse else super.save_progress(data)
