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
	repository = RefusingRepository.new("user://laboratory.json")
	manager.use_save_repository(repository)
	manager.reset_save()
	for word: String in ["mayak", "chich", "nojoch", "mejen", "k'áan", "lak"]:
		manager.record_learning([word], "practice", "presentation/" + word, true)
	manager.prepare_sharing_corner()
	for level: Dictionary in GameContent.LEVEL_ORDER:
		if int(level.world) < 3:
			manager.session.complete_level(level.world, level.level)
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	root.get_node("AccessibilityManager").reduced_motion = true
	home.change_district("workshop")
	var lab: Node = home.get_node("SpellLaboratory")
	lab.open_lab(home.return_button)
	check(paused and lab.visible, "El laboratorio pausa el paseo")
	check(lab._place.disabled and lab._favorite.disabled, "Mirar no confirma una idea")
	lab.try_favorite("k'áan|")
	check(lab._place.disabled, "Otro mueble conserva la protección del primer rincón")
	lab.try_favorite("mayak|chich")
	var before: Dictionary = manager.session.garden.duplicate(true)
	var points: int = manager.session.magic_points
	lab.toggle_favorite()
	check(manager.session.laboratory_favorites == ["mayak|chich"], "Guarda la idea ensayada")
	lab.compare_result()
	lab.try_favorite("mayak|nojoch")
	check(lab._comparison_id == "mayak|chich", "Cambiar cualidad conserva la referencia")
	check(lab._body.get_node("Stage/Reference").visible, "Dos ilustraciones para comparar")
	check(manager.session.magic_points == points, "Ensayos y favoritos no cobran ni premian")
	check(manager.session.garden == before, "Comparar no fabrica muebles")
	await _capture(lab, "01_comparacion")
	lab.try_favorite("mayak|chich")
	lab.request_placement()
	check(lab._purchase.visible, "La compra requiere confirmación")
	check(
		lab._availability.text.contains("Mesa") and lab._availability.text.contains("Fuerte"),
		"Nombra cada diseño"
	)
	check(manager.session.magic_points == points, "Revisar el precio no cobra")
	await _capture(lab, "02_confirmacion")
	lab.cancel_purchase()
	check(manager.session.magic_points == points, "Volver al ensayo conserva el saldo")
	lab.request_placement()
	await _failed_operations(lab)
	lab.confirm_purchase()
	check(manager.session.magic_points == points - 20, "Confirmar compra dos diseños una sola vez")
	lab.confirm_purchase()
	check(manager.session.magic_points == points - 20, "Doble activación no vuelve a cobrar")
	check(manager.session.garden == before, "Comprar un diseño no crea copias")
	lab.request_placement()
	check(not lab.visible and not paused and home.editor.placing, "Pasa directamente a colocar")
	check(home.editor.district == "workshop", "Coloca en la parcela visitada")
	check(
		root.gui_get_focus_owner() == home.editor._tools.get_child(0),
		"La colocación recibe el foco"
	)
	check(manager.session.garden == before, "La vista previa vive fuera de la sesión")
	manager.checkpoint(home)
	var checkpoint: GameSession = GameSession.new()
	check(checkpoint.restore(repository.load_progress()), "El archivo de la vista previa es válido")
	check(checkpoint.garden == before, "Guardar durante la vista previa no crea muebles")
	home.editor.preview = Vector2.ZERO
	home.editor.commit()
	check(
		home.editor.placing and manager.session.garden == before,
		"La posición inválida conserva la vista previa"
	)
	home.editor.cancel()
	check(manager.session.garden == before, "Cancelar deja intacta la parcela")
	home.editor.hide()
	lab.open_lab(home.return_button)
	lab.try_favorite("mayak|chich")
	lab.request_placement()
	home.editor.preview = Vector2(600, 440)
	home.editor.commit()
	check(
		manager.session.garden.objects.size() == 1 and manager.session.economy.built,
		"Confirma el mueble"
	)
	await _capture_editor(home, "03_colocada")
	home.editor.undo()
	check(manager.session.garden.objects == before.objects, "Deshacer retira sólo la copia")
	check(
		int(manager.session.garden.next_id) > int(before.next_id),
		"Deshacer no reutiliza identidades guardadas"
	)
	check(manager.session.economy.designs.size() == 2, "Deshacer conserva diseños comprados")
	home.editor._tools.get_child(6).pressed.emit()
	check(root.gui_get_focus_owner() == home._action, "Terminar devuelve el foco al paseo")
	lab.open_lab(home.return_button)
	lab.try_favorite("mayak|nojoch")
	manager.session.magic_points = 9
	lab.request_placement()
	check(lab._confirm.disabled, "Saldo insuficiente bloquea confirmar")
	check(
		lab._availability.text.contains("Grande") and not lab._availability.text.contains("Mesa ("),
		"Sólo falta la cualidad"
	)
	lab.cancel_purchase()
	manager.session.magic_points = 10
	lab.request_placement()
	lab.confirm_purchase()
	check(manager.session.magic_points == 0, "Sólo paga la cualidad faltante")
	lab.toggle_favorite()
	lab.profile = lab.profile.duplicate() as LaboratoryProfile
	lab.profile.favorite_limit = 2
	lab.try_favorite("mayak|mejen")
	check(lab._favorite.disabled, "El perfil limita favoritos sin borrar los anteriores")
	lab.try_favorite("mayak|nojoch")
	lab.toggle_favorite()
	check(
		manager.session.laboratory_favorites.size() == 1,
		"Puede retirar favoritos con capacidad llena"
	)
	lab.toggle_favorite()
	var saved_points: int = manager.session.magic_points
	lab.close_lab()
	check(
		not paused and root.gui_get_focus_owner() == home.return_button,
		"Cerrar devuelve pausa y foco"
	)
	var stored: Dictionary = JSON.parse_string(JSON.stringify(repository.load_progress()))
	check(manager.session.restore(stored), "Restaura desde el archivo vigente")
	check(manager.session.laboratory_favorites.size() == 2, "Conserva ambas ideas y su orden")
	check(manager.session.magic_points == saved_points, "Reanudar no cobra ni premia")
	await _capacity_and_lifecycle(home, lab)
	finish("Laboratorio: favoritos, comparación, compra, colocación y continuidad")


func _failed_operations(lab: Node) -> void:
	var before: Dictionary = manager.session.snapshot()
	var notifications: Array[int] = []
	var observer: Callable = func(total: int) -> void: notifications.append(total)
	manager.magic_points_changed.connect(observer)
	repository.refuse = true
	var errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	lab.confirm_purchase()
	check(not manager.purchase_design("mayak"), "La compra individual también espera al guardado")
	Engine.print_error_messages = errors
	check(manager.session.snapshot() == before, "Un fallo de guardado revierte toda la compra")
	check(notifications.is_empty(), "No anuncia un saldo que no se confirmó")
	check(lab._purchase.visible, "Permite reintentar la confirmación")
	Engine.print_error_messages = false
	lab.toggle_favorite()
	Engine.print_error_messages = errors
	check(manager.session.snapshot() == before, "Un fallo conserva los favoritos anteriores")
	repository.refuse = false
	manager.magic_points_changed.disconnect(observer)


func _capacity_and_lifecycle(home: Node, lab: Node) -> void:
	for index: int in range(GardenLayout.MAX_OBJECTS):
		manager.session.create_garden_object("mayak|chich", "patio")
	lab.open_lab(home.return_button)
	lab.try_favorite("mayak|chich")
	check(
		lab._place.disabled and lab._availability.text.contains("llenos"),
		"Explica la capacidad global"
	)
	var before: Dictionary = manager.session.garden.duplicate(true)
	lab.request_placement()
	check(lab.visible and manager.session.garden == before, "La capacidad llena no sale ni fabrica")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	await process_frame
	check(not lab.visible and not paused, "Esc devuelve el paseo")
	lab.open_lab(home.return_button)
	root.get_node("AccessibilityManager").reduced_motion = false
	lab.create_spell()
	lab.close_lab()
	await create_timer(0.6).timeout
	check(
		not lab.visible and not lab._casting, "Cerrar durante la magia cancela el trabajo diferido"
	)
	lab.open_lab(home.return_button)
	lab.queue_free()
	await process_frame
	check(not paused, "Destruir el laboratorio devuelve la pausa")


func _capture(lab: Node, name: String) -> void:
	for compact: bool in [false, true]:
		var layout: ScreenLayout = lab.get_node("ScreenLayout")
		layout.preview_compact = compact
		layout.refresh()
		await process_frame
		await process_frame
		var target: Control = (
			lab._purchase if lab._purchase.visible else lab._body.get_node("Stage")
		)
		var browse: ScrollContainer = lab.get_node("Shade/Panel/Content/Browse")
		browse.ensure_control_visible(target)
		await process_frame
		await process_frame
		check(
			browse.get_global_rect().encloses(target.get_global_rect()),
			"El precio y la confirmación se pueden leer completos"
		)
		var panel: Control = lab.get_node("Shade/Panel")
		var actions: Control = lab.get_node("Shade/Panel/Content/Actions")
		check(
			panel.get_global_rect().encloses(actions.get_global_rect()),
			"Acciones contenidas en ambos perfiles"
		)
		if not capture_directory.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(
				capture_directory.path_join(name + ("_compacto" if compact else "") + ".png")
			)
	lab.get_node("ScreenLayout").preview_compact = false
	lab.get_node("ScreenLayout").refresh()


func _capture_editor(home: Node, name: String) -> void:
	await process_frame
	if not capture_directory.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png"))
	check(home.editor.visible, "El jardín queda disponible después de colocar")


class RefusingRepository:
	extends SaveRepository
	var refuse: bool = false

	func save_progress(data: Dictionary) -> Error:
		return ERR_CANT_CREATE if refuse else super.save_progress(data)
