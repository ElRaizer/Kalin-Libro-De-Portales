## Regresiones de las capturas de autoría: foco, borrado, capas y contenido del portal.
extends "res://tests/validate_game_expansion.gd"


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_folder = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://playtest_polish.json"))
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	_counting_pieces()
	_portal_clues()
	await _cloze_navigation()
	await _illustration_bounds()
	await _mission_status()
	await _world_composition()
	await _native_word_drop()
	await _skip_permissions()
	await _guide_lifecycle()
	await process_frame
	for failure: String in failures:
		push_error(failure)
	if failures.is_empty():
		print(
			"OK: pulido visual, huecos, borrado por pieza, peticiones completas y saltos de repetición."
		)
	quit(0 if failures.is_empty() else 1)


func _counting_pieces() -> void:
	var session: CountingSession = CountingSession.new()
	session.twenties = 2
	session.units = 14
	for value: int in [13, 12, 11, 10, 5, 0]:
		session.remove_piece()
		_check(
			session.units == value and session.twenties == 2,
			"Borrar retira un grano o una barra del piso inferior"
		)
	session.shell = true
	session.select_floor(MayaNumeral.Floor.TWENTIES)
	session.remove_piece()
	_check(session.twenties == 1 and session.shell, "Borrar arriba conserva la concha de abajo")
	session.select_floor(MayaNumeral.Floor.UNITS)
	session.remove_piece()
	_check(not session.shell and session.twenties == 1, "Borrar abajo retira solamente la concha")
	session.remove_piece()
	_check(
		session.units == 0 and session.active_floor == MayaNumeral.Floor.UNITS,
		"Borrar un piso vacío conserva la selección"
	)


func _portal_clues() -> void:
	var base: ExerciseEntry = ExerciseEntry.new()
	for category: int in [2, 3]:
		for entry: ExerciseEntry in PortalReplay.pool(category, base, CombinationCatalog.stage(4)):
			_check(
				(
					entry.clue.to_lower().begins_with("quiero ")
					== entry.correct.begins_with("In k'a'at ")
				),
				"El portal pide exactamente una descripción o una petición completa"
			)


func _cloze_navigation() -> void:
	var scene: Node = await _scene("world3_level1")
	scene.mission_break.hide()
	var panel: RecallPanel = scene.recall
	panel.configure(["Objeto", "Cómo es"], ["lak", "nojoch"], RecallPanel.Mode.CLOZE)
	await process_frame
	await process_frame
	var fields: Array[LineEdit] = panel._editable_fields()
	var first_count: int = panel._corrections[0].get_child_count()
	for index: int in range(first_count):
		var field: LineEdit = fields[index]
		field.grab_focus()
		field.text = "lak"[index]
		field.text_changed.emit(field.text)
	_check(fields[first_count].has_focus(), "Completar la primera palabra enfoca la siguiente")
	var backspace: InputEventKey = InputEventKey.new()
	backspace.keycode = KEY_BACKSPACE
	backspace.pressed = true
	root.push_input(backspace, true)
	await process_frame
	_check(
		fields[first_count - 1].has_focus() and fields[first_count - 1].text.is_empty(),
		"Borrar desde el hueco vacío vuelve a la palabra anterior y borra su última letra"
	)
	panel.configure(["Nombre"], ["Peek'"])
	panel.first.text = "Peeeek'"
	panel.advance_support()
	for button: Node in panel._corrections[0].get_children():
		if button is Button:
			_check(
				button.get_theme_stylebox("normal") is StyleBoxFlat,
				"Las letras sobrantes usan el tema compartido"
			)
	await _capture("huecos_y_letras_sobrantes")


func _illustration_bounds() -> void:
	var scene: Node = await _scene("world3_level1")
	scene.mission_break.hide()
	var panel: RecallPanel = scene.recall
	for compact: bool in [false, true]:
		var layout: ScreenLayout = scene.get_node("ScreenLayout")
		layout.preview_compact = compact
		layout.refresh()
		for id: String in CombinationCatalog.targets():
			var parts: PackedStringArray = id.split("|")
			panel.show_result(parts[0], parts[1], parts[0] + " · " + parts[1], "Resultado")
			await process_frame
			await process_frame
			var art: MeaningIllustration = panel.get_node("Margin/Content/Result/Art")
			for layer: TextureRect in [
				art.picture, art.world_front, art.world_mat, art.quality_badge
			]:
				if layer.visible:
					_check(
						Rect2(Vector2.ZERO, art.size).grow(0.1).encloses(
							Rect2(layer.position, layer.size)
						),
						"La ilustración cabe en su tarjeta: " + id
					)
		panel.show_result("k'áan", "nojoch", "k'áan · nojoch", "Hamaca grande")
		await process_frame
		var result_art: MeaningIllustration = panel.get_node("Margin/Content/Result/Art")
		var large_size: Vector2 = result_art.picture_rect().size
		panel.show_result("k'áan", "mejen", "k'áan · mejen", "Hamaca pequeña")
		_check(
			result_art.picture_rect().size.x < large_size.x,
			"El ajuste conserva la diferencia de tamaños"
		)
		panel.show_result("k'áan", "nojoch", "k'áan · nojoch", "Hamaca grande")
		await _capture("hamaca_resultado" + ("_compacto" if compact else ""))
		_check(
			QualityCue.texture_for("nojoch") != manager.get_visual_texture("nojoch"),
			"Las cualidades tienen un apoyo neutro en las tarjetas"
		)


func _mission_status() -> void:
	var scene: Node = await _scene(
		"world2_mission1",
		{
			"intro_done": true,
			"layout_seed": 504,
			"mission_met": [0, 1],
			"delivered": [0],
			"active_task": 1
		}
	)
	scene._open_workbench()
	scene._select_task_card(0)
	var preview: MissionTaskPreview = scene.get_node("UI/MissionPanel/TaskPreview")
	_check(
		preview.visible and preview._group != null,
		"El encargo entregado muestra al habitante usando su objeto"
	)
	await _capture("encargo_entregado")
	scene._select_task_card(2)
	_check(
		preview.get_node("Unknown").visible and preview._group == null,
		"El encargo desconocido muestra una interrogación"
	)
	var selected: SelectionButton = scene._task_cards.get_child(2)
	var pressed: SelectionButton = scene._task_cards.get_child(1)
	pressed.button_down.emit()
	_check(
		selected.get_theme_stylebox("pressed") != pressed.get_theme_stylebox("pressed"),
		"La selección dorada y la presión física se distinguen"
	)
	await _capture("encargo_desconocido")
	pressed.button_up.emit()
	_check(
		not scene.has_node("UI/JournalButton") and not scene.has_node("UI/Journal"),
		"Se retira Encargos y lugares junto a su panel"
	)
	scene._select_task_card(1)
	var task: VillageTask = scene.tasks[scene.task_indices[1]]
	scene.recall.debug_fill([task.item, task.quality])
	scene._forge()
	scene._process(0.0)
	_check(
		scene.carried_art.z_index > scene._roaming.walker.z_index,
		"El objeto transportado se dibuja delante de Kalin"
	)
	_check(
		scene.carried_art.position.x > 0, "El objeto queda al costado, fuera de la cara y el cuerpo"
	)
	scene._roaming.walker.step(Vector2.LEFT * 20, 0.0, true)
	scene._process(0.0)
	_check(
		scene.carried_art.get_rect().end.x < 0,
		"Al mirar a la izquierda el objeto permanece fuera de la cara"
	)
	scene._roaming.walker.step(Vector2.RIGHT * 20, 0.0, true)
	scene._process(0.0)
	await _capture("kalin_transportando")
	scene = await _resume("world2_mission1")
	_check(
		not scene.carried.is_empty() and scene.carried_art.visible,
		"Reanudar recupera el objeto transportado"
	)
	var layout: ScreenLayout = scene.get_node("ScreenLayout")
	layout.preview_compact = true
	layout.refresh()
	scene._open_workbench()
	scene._select_task_card(0)
	await _capture("encargo_entregado_compacto")


func _world_composition() -> void:
	var scene: Node = await _scene("world2_level1", {"round": 4, "layout_seed": 101})
	for entry: ExerciseEntry in scene.objects:
		scene._place_object(entry.maya, false)
	_check(
		is_equal_approx(
			scene.get_node("UI/FeedbackPanel").get_global_rect().end.x,
			scene.get_node("UI/RequestPanel").get_global_rect().end.x
		),
		"La barra de indicaciones termina en el margen común"
	)
	await _capture("casa_amueblada")
	var layout: ScreenLayout = scene.get_node("ScreenLayout")
	layout.preview_compact = true
	layout.refresh()
	await _capture("casa_amueblada_compacta")
	scene = await _scene("world3_explore2", {"intro_done": true, "x": 1650})
	_check(
		scene.get_node("Foreground").z_index > scene.kalin.z_index,
		"Los maíces delanteros cubren a Kalin"
	)
	await _capture("milpa_capas")
	scene = await _scene(
		"world3_mission1",
		{
			"intro_done": true,
			"mission_met": [0, 1, 2],
			"delivered": [0, 1, 2],
			"gathering_seen": true
		}
	)
	scene._place_kalin(scene.get_node("Spots/Salida").position.x - 110)
	scene.camera.reset_smoothing()
	_check(
		scene.get_node("Spots/Salida").spot_texture != null,
		"La meta de la comida tiene una mesa visible"
	)
	await _capture("meta_comida_compartida")
	scene = await _scene("world3_level1")
	scene.mission_break.hide()
	var slot: WordDropSlot = scene.noun_slot
	_check(
		slot._has_point(Vector2(slot.size.x / 2, -20)),
		"La zona de soltar acepta la ficha sobre el borde"
	)
	_check(
		(
			slot._can_drop_data(Vector2.ZERO, {"kind": &"noun"})
			and not slot._can_drop_data(Vector2.ZERO, {"kind": &"adjective"})
		),
		"La tolerancia mantiene el tipo correcto de bloque"
	)
	await _capture("tarjetas_cualidades")


func _skip_permissions() -> void:
	for key: String in ["intro", "world1_story1", "world3_explore2"]:
		var scene: Node = await _scene(key)
		var button: Button = scene.skip_btn if key == "intro" else scene.skip_button
		_check(not button.visible, "La primera visita conserva la historia: " + key)
		scene = await _scene(key, {"previous_variation": {"complete": true}})
		button = scene.skip_btn if key == "intro" else scene.skip_button
		_check(button.visible, "La repetición permite saltar: " + key)
		manager.checkpoint(scene)
		scene = await _resume(key)
		button = scene.skip_btn if key == "intro" else scene.skip_button
		_check(button.visible, "Reanudar conserva el permiso de repetición: " + key)
	_check(
		not ReplayVariation.can_skip({"replay_run": "cadena"}),
		"Repetir un capítulo previo no permite saltar un capítulo aún desconocido"
	)


func _native_word_drop() -> void:
	var scene: Node = await _scene("world3_level1")
	scene.mission_break.hide()
	if scene.recall.visible:
		scene._practice_with_cards()
	await process_frame
	await process_frame
	scene.guide.stop()
	var source: DraggableWordButton
	for button: DraggableWordButton in scene.noun_buttons.values():
		if button.is_visible_in_tree() and not button.disabled:
			source = button
			break
	var start: Vector2 = source.get_global_rect().get_center()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = start
	motion.global_position = start
	root.push_input(motion, true)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	press.global_position = start
	root.push_input(press, true)
	motion = InputEventMouseMotion.new()
	motion.position = start + Vector2(50, 50)
	motion.global_position = motion.position
	motion.relative = Vector2(50, 50)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	await process_frame
	_check(root.gui_is_dragging(), "La palabra inicia el arrastre nativo")
	var slot: WordDropSlot = scene.noun_slot
	motion.position = slot.get_global_transform() * Vector2(slot.size.x / 2, -20)
	motion.global_position = motion.position
	motion.relative = Vector2(0, 100)
	root.push_input(motion, true)
	await process_frame
	await process_frame
	_check(slot._valid_hover, "La franja ampliada se ilumina antes de soltar")
	press.position = motion.position
	press.global_position = motion.position
	press.pressed = false
	root.push_input(press, true)
	await process_frame
	_check(
		scene.selected_noun == source.word_value,
		"Soltar sobre la franja ampliada coloca la palabra"
	)


func _guide_lifecycle() -> void:
	var scene: Node = await _scene("world5_farewell", {"intro_done": true})
	scene.guide.click_world(scene.kalin)
	scene._show_choices(0)
	_check(
		scene.guide.gesture_mode == LearningGuide.Gesture.NONE,
		"Un menú de respuestas retira la mano del mundo"
	)
	scene.guide.click_at(scene.get_node("UI/FarewellChoices/Close"))
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	scene.guide._input(click)
	_check(not scene.guide.hand.visible, "Seguir una indicación retira su señalamiento")
	scene.guide.click_at(scene.get_node("UI/FarewellChoices/Close"))
	paused = true
	await process_frame
	_check(not scene.guide.hand.visible, "La pausa del libro retira la orientación anterior")
	paused = false
