## Apoyos por error, piezas reordenables, persistencia y consecuencias visibles.
extends "res://tests/validate_game_expansion.gd"

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://blocks_validation.json")
	manager.reset_save()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	await _automatic_support()
	await _mission_support()
	await _pieces()
	await _walk_requests()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("OK: escritura primero, apoyos automáticos, casillas iguales, intercambios, banco, guardado, resultados y capas.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _automatic_support() -> void:
	for key: String in ["world2_level1", "world3_level1", "world4_level1", "world5_level1"]:
		var scene := await _scene(key)
		var round_number: int = scene.objects.size() if key == "world2_level1" else (0 if key == "world5_level1" else scene.challenges.size())
		var state := {"challenge" if key == "world5_level1" else "round": round_number, "layout_seed": 735}
		scene = await _scene(key, state)
		if key != "world5_level1":
			scene.mission_break.hide()
		var panel: RecallPanel = scene.recall
		_check(panel.mode == RecallPanel.Mode.WRITE and not scene._attempt.supported, "Primero se pide recuerdo sin apoyo: " + key)
		_check(not panel.get_node("Margin/Content/Modes").visible and not panel.get_node("Margin/Content/Actions/Practice").visible, "El jugador no elige modalidad")
		panel.submitted.emit()
		_check(scene._attempt.mistakes == 0 and panel.mode == RecallPanel.Mode.WRITE, "Un campo vacío no cuenta como fallo")
		panel.first.text = "incorrecto"
		if panel.second_box.visible:
			panel.second.text = panel.expected[1]
		panel.submitted.emit()
		_check(panel.mode == RecallPanel.Mode.CLOZE and scene._attempt.supported and scene._attempt.mistakes == 1, "El primer fallo pasa a completar: " + key)
		if panel.second_box.visible:
			_check(panel.second.text == panel.expected[1], "Una segunda parte correcta permanece resuelta")
		panel.first.text = "incorrecto"
		panel.submitted.emit()
		_check(panel.mode == RecallPanel.Mode.BLOCKS and scene._attempt.mistakes == 2, "El segundo fallo pasa a bloques: " + key)
		_check(not panel.first.visible and not panel.second.visible, "Los bloques no parecen un campo de escritura")
		panel.submitted.emit()
		_check(scene._attempt.mistakes == 2, "No se penalizan casillas todavía vacías")
		scene = await _resume(key)
		panel = scene.recall
		_check(panel.mode == RecallPanel.Mode.BLOCKS and scene._attempt.mistakes == 2, "El apoyo alcanzado se conserva desde JSON: " + key)
		panel.debug_fill(panel.expected)
		panel.submitted.emit()
		_check(panel._showing_result and panel.get_node("Margin/Content/Result").visible, "El acierto ocupa la zona de trabajo con imagen y frase: " + key)
		await _capture("resultado_" + key)
		scene = await _resume(key)
		_check(scene.recall._showing_result, "El resultado se conserva al reanudar: " + key)
		state.layout_seed = 736
		scene = await _scene(key, state)
		if key != "world5_level1":
			scene.mission_break.hide()
		panel = scene.recall
		var before := _writing_count()
		panel.first.text = panel.expected[0]
		if panel.second_box.visible:
			panel.second.text = panel.expected[1]
		panel.submitted.emit()
		_check(panel._showing_result and not scene._attempt.supported and _writing_count() > before, "Acertar a la primera registra escritura independiente: " + key)

func _writing_count() -> int:
	var count := 0
	for word: String in manager.learning_progress:
		count += int(manager.learning_progress[word].writing)
	return count

func _mission_support() -> void:
	for key: String in ["world2_mission1", "world3_mission1", "world4_mission1"]:
		var mission := await _scene(key, {"intro_done": true})
		var friend := mission.get_node("Spots/Recipient0") as ExplorationSpot
		mission._place_kalin(friend.position.x)
		mission.open_spot(friend)
		_close_lines(mission)
		mission._open_workbench()
		for expected_mode: int in [RecallPanel.Mode.CLOZE, RecallPanel.Mode.BLOCKS]:
			mission.recall.first.text = "incorrecto"
			if mission.recall.second_box.visible:
				mission.recall.second.text = "incorrecto"
			mission._forge()
			_check(mission.recall.mode == expected_mode and mission.carried.is_empty(), "El encargo ofrece apoyo automático antes de crear un objeto equivocado")
		mission = await _resume(key)
		await process_frame
		_check(mission.mission_panel.visible and mission.recall.mode == RecallPanel.Mode.BLOCKS, "Reabrir el taller conserva los apoyos del encargo")
		mission.recall.debug_fill(mission.recall.expected)
		mission._forge()
		_check(not mission.carried.is_empty() and mission.carried.supported and mission.carried.mistakes == 2, "El encargo apoyado conserva sus errores tras reanudar y puede transportarse")

func _pieces() -> void:
	var scene := await _scene("world3_level1", {"round": 7, "layout_seed": 88})
	scene.mission_break.hide()
	var panel: RecallPanel = scene.recall
	panel.advance_support()
	panel.advance_support()
	await process_frame
	var bank := panel.get_node("Margin/Content/Blocks/Bank") as HFlowContainer
	var extent: Vector2 = bank.get_child(0).custom_minimum_size
	for child: Button in bank.get_children():
		_check(child.custom_minimum_size == extent, "Todas las piezas del banco tienen el mismo tamaño")
	for row: HFlowContainer in panel._slot_rows:
		for slot: Button in row.get_children():
			_check(slot.custom_minimum_size == extent, "Las casillas comparten tamaño con las piezas")
	_check(not panel.has_node("Margin/Content/BankTitle"), "El banco no necesita una barra adicional")
	var preview := bank.get_child(0).create_drag_preview() as Control
	var preview_piece := preview.get_child(0) as Button
	_check(preview_piece.get_rect().get_center().is_equal_approx(Vector2.ZERO), "La pieza arrastrada queda centrada en el cursor")
	preview.free()
	panel.move_fragment(0, 0, 0)
	var ghost := bank.get_child(0) as Button
	_check(ghost.visible and ghost.modulate.a < 0.5 and not ghost.disabled, "La pieza colocada deja una referencia atenuada y pulsable en el banco")
	_check(ghost._get_drag_data(Vector2.ZERO) == null, "La referencia atenuada no permite duplicar una pieza")
	ghost.pressed.emit()
	_check(0 not in panel._used and ghost.modulate.a == 1.0, "Tocar la referencia devuelve la pieza y recupera su opacidad")
	panel.move_fragment(0, 0, 0)
	panel.move_fragment(1, 0, 1)
	panel.move_fragment(0, 0, 1)
	_check(panel._slots[0][0] == 1 and panel._slots[0][1] == 0, "Arrastrar una pieza sobre otra intercambia posiciones")
	panel.move_fragment(2, 0, 0)
	_check(panel._slots[0][0] == 2 and 1 not in panel._used, "Reemplazar desde el banco devuelve la otra pieza al banco")
	panel.move_fragment(0, 1, 0)
	_check(panel._slots[1][0] == 0 and panel._slots[0][1] == -1, "También se puede mover entre palabras")
	var payload := {"kind": "recall_fragment", "panel": panel, "index": 0}
	_check(bank._can_drop_data(Vector2.ZERO, payload), "El banco acepta devolver una pieza colocada")
	bank._drop_data(Vector2.ZERO, payload)
	_check(0 not in panel._used and bank.get_child(0).visible, "Devolver recupera el bloque en el banco")
	_check(not bank._can_drop_data(Vector2.ZERO, {"kind": "recall_fragment", "panel": null, "index": 0}), "Rechaza piezas de otra actividad")
	panel._undo_fragment()
	_check(panel._slots[1][0] == 0, "Deshacer recupera la disposición anterior")
	panel._slot_pressed(1, 0)
	panel._slot_pressed(0, 1)
	_check(panel._slots[0][1] == 0, "Toques y teclado permiten mover sin arrastrar")
	var saved_slots := panel._slots.duplicate(true)
	scene = await _resume("world3_level1")
	panel = scene.recall
	_check(panel._slots == saved_slots, "Guardar conserva huecos, orden y piezas entre palabras")
	await _capture("bloques_casillas")
	for physical_size: Vector2i in [Vector2i(1920, 1080), Vector2i(960, 540), Vector2i(640, 360)]:
		root.size = physical_size
		scene.get_node("ScreenLayout").preview_compact = physical_size.x < 1024
		scene.get_node("ScreenLayout").refresh()
		await process_frame
		_check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "Los bloques caben completos en móvil horizontal")
		for button_in_panel: Node in panel.find_children("*", "Button", true, false):
			var control := button_in_panel as Button
			if control.is_visible_in_tree():
				_check(Rect2(0, 0, 1280, 720).encloses(control.get_global_rect()), "Las casillas y el banco quedan dentro de pantalla")
		await _capture("bloques_%d" % physical_size.x)
	root.size = Vector2i(1280, 720)
	scene.get_node("ScreenLayout").preview_compact = false
	scene.get_node("ScreenLayout").refresh()
	await process_frame
	# Un drag real crea una vista previa con fondo y conserva el bloque hasta soltarlo.
	var button := panel.get_node("Margin/Content/Blocks/Bank").get_child(1) as Button
	var start := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	# Usa la entrada del viewport, igual que el jugador.
	motion.position = start
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	motion = InputEventMouseMotion.new()
	motion.position = start + Vector2(50, -55)
	motion.relative = Vector2(50, -55)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	await process_frame
	_check(root.gui_is_dragging(), "El bloque inicia arrastre nativo")
	await _capture("bloque_arrastrado")
	press.position = motion.position
	press.pressed = false
	root.push_input(press, true)
	await process_frame
	panel.debug_fill(panel.expected)
	scene._on_cast_pressed()
	for physical_size: Vector2i in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = physical_size
		scene.get_node("ScreenLayout").preview_compact = physical_size.x < 1024
		scene.get_node("ScreenLayout").refresh()
		await process_frame
		await _capture("resultado_taller_%d" % physical_size.x)
	root.size = Vector2i(1280, 720)

func _walk_requests() -> void:
	var walk := await _scene("world2_explore1", {"intro_done": true, "layout_seed": 18})
	walk._place_kalin(walk._encounter_spot(0).position.x - 140)
	walk.camera.reset_smoothing()
	walk._show_choices(0)
	_check(walk.get_node("UI/ChoiceRequest").visible and walk.get_node("UI/ChoiceRequest/Request").text.contains(walk.encounters[0].task.request), "La petición completa permanece junto a las opciones")
	walk._show_notice("Otra indicación temporal")
	_check(walk.get_node("UI/ChoiceRequest/Request").text.contains(walk.encounters[0].task.request), "Los avisos no sustituyen la petición persistente")
	await _capture("peticion_visible")
	walk.debug_answer()
	_close_lines(walk)
	_check(0 in walk.solved and not walk.get_node("UI/ChoiceRequest").visible, "El resultado cierra la petición y permite volver a caminar")
	var art := walk.get_node("Results/Item0") as MeaningIllustration
	var spot: ExplorationSpot = walk._encounter_spot(0)
	_check(walk.kalin.z_index > art.z_index + (art.get_parent() as CanvasItem).z_index and walk.kalin.z_index > spot.z_index, "Kalin pasa delante del animal y del objeto juntos")
	walk._place_kalin(spot.position.x)
	await _capture("capas_aldea")
	# Comprueba también la hamaca específica del informe, desde ambos lados.
	for index: int in range(walk.encounters.size()):
		if walk.encounters[index].task.item == "k'áan":
			walk._show_choices(index)
			walk.debug_answer()
			_close_lines(walk)
			walk._place_kalin(walk._encounter_spot(index).position.x)
			walk.camera.reset_smoothing()
			await _capture("capas_hamaca")
