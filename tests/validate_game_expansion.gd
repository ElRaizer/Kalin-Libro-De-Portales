## Regresiones del recorrido ampliado, escritura apoyada, contrato de guardado y móvil horizontal.
## Con renderer real: -- --capture=<carpeta absoluta>
extends "res://tests/validate_adventure.gd"

var capture_folder: String = ""


func _scene(key: String, state: Dictionary = {}) -> Node:
	manager.session.scene_states[key] = state.duplicate(true)
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame
	return current_scene


func _resume(key: String) -> Node:
	manager.checkpoint(current_scene)
	manager.session.scene_states.clear()
	manager._load_save()
	return await _scene(key, manager.session.scene_states.get(key, {}))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _capture(name: String) -> void:
	if capture_folder.is_empty():
		return
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_folder.path_join(name + ".png"))


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://expansion_validation.json")
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	await _semantic_evidence()
	await _scaffolds()
	await _deliveries()
	await _farewell()
	await _motion()
	await _screens()
	await _keyboard_dock()
	_save_version()
	await process_frame
	await process_frame
	if failures.is_empty():
		print(
			"OK: evidencia semántica, bloques, escritura, encargos, despedida, movimiento y móvil horizontal."
		)
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _semantic_evidence() -> void:
	var house: Node = await _scene(
		"world2_level1", {"round": 8, "recall_order": [1, 2, 3, 0, 4], "layout_seed": 101}
	)
	house.mission_break.hide()
	house._on_choice_pressed("mayak")
	manager.record_learning(["lak"], "practice", "intermediate:one")
	manager.record_learning(["ja'"], "practice", "intermediate:two")
	house = await _scene(
		"world2_level1", {"round": 9, "recall_order": [1, 2, 3, 4, 0], "layout_seed": 202}
	)
	house._on_choice_pressed("mayak")
	_check(
		manager.session.learning_progress.mayak.recalls.size() == 1,
		"Barajar una petición de casa no debe acreditar dos situaciones"
	)
	_check(
		manager.session.learning_progress.mayak.writing == 2,
		"Sí pueden registrarse dos escrituras sin confundirlas con contextos distintos"
	)
	var attempt: LearningAttempt = LearningAttempt.new()
	attempt.restore(
		{"context": "workshop:Miis:k'áan|mejen:recall@45", "supported": true, "mistakes": 2}
	)
	LearningContext.begin(attempt, "workshop:Miis:k'áan|mejen:recall@45")
	_check(
		attempt.supported and attempt.mistakes == 2, "Reanudar un intento conserva apoyos y errores"
	)


func _scaffolds() -> void:
	var workshop: Node = await _scene("world3_level1", {"round": 7, "layout_seed": 51})
	workshop.mission_break.hide()
	var panel: RecallPanel = workshop.recall
	_check(
		panel.mode == RecallPanel.Mode.WRITE and not workshop._attempt.supported,
		"El recuerdo comienza sin apoyos"
	)
	panel.advance_support()
	panel.advance_support()
	_check(
		not workshop.spell_panel.visible and workshop.choices_panel.position.y < 100,
		"La escritura ocupa un único panel sin huecos duplicados"
	)
	var first_index: int = _next_fragment(panel, panel.first, panel.expected[0])
	var payload: Dictionary = {"kind": "recall_fragment", "panel": panel, "index": first_index}
	var slot: Button = panel._slot_rows[0].get_child(0) as Button
	_check(slot._can_drop_data(Vector2.ZERO, payload), "La casilla acepta arrastre de sus bloques")
	_check(
		not slot._can_drop_data(
			Vector2.ZERO, {"kind": "recall_fragment", "panel": null, "index": first_index}
		),
		"Rechazar bloques de otro panel"
	)
	slot._drop_data(Vector2.ZERO, payload)
	var draft: String = panel.first.text
	workshop = await _resume("world3_level1")
	panel = workshop.recall
	_check(
		(
			panel.mode == RecallPanel.Mode.BLOCKS
			and panel.first.text == draft
			and panel._used.size() == 1
		),
		"JSON restaura modo, fragmento y banco usado"
	)
	for field_index: int in range(panel.expected.size()):
		var field: LineEdit = panel.first if field_index == 0 else panel.second
		for step: int in range(20):
			if WordMatcher.match_word(field.text, panel.expected[field_index]).correct:
				break
			var next: int = _next_fragment(panel, field, panel.expected[field_index])
			if next < 0:
				break
			panel.place_fragment(next, field)
	await _capture("01_bloques_taller")
	var task: ExerciseEntry = workshop._current_challenge()
	workshop._on_cast_pressed()
	_check(workshop._awaiting_continue, "Unir los fragmentos correctos resuelve el hechizo")
	_check(
		(
			manager.session.learning_progress[task.adjective].reconstruction >= 1
			and manager.session.learning_progress[task.adjective].recalls.is_empty()
		),
		"Los bloques registran reconstrucción, nunca recuerdo libre"
	)
	var house: Node = await _scene("world2_level1", {"round": 5, "layout_seed": 55})
	house.mission_break.hide()
	_check(
		house.recall.mode == RecallPanel.Mode.WRITE and house.recall.first.text.is_empty(),
		"La casa empieza pidiendo escritura sin ayuda"
	)
	house.recall.first.text = "incorrecto"
	house.recall.submitted.emit()
	_check(
		house.recall.mode == RecallPanel.Mode.CLOZE and house._attempt.supported,
		"El fallo activa una pista sin borrar la evidencia de apoyo"
	)
	await _capture("02_casa_escritura")


func _next_fragment(panel: RecallPanel, field: LineEdit, wanted: String) -> int:
	for index: int in range(panel._fragments.size()):
		if (
			index not in panel._used
			and wanted.substr(field.text.length()).begins_with(panel._fragments[index])
		):
			return index
	return -1


func _deliveries() -> void:
	for world: int in [2, 3]:
		var mission: Node = await _scene("world%d_mission1" % world)
		_close_lines(mission)
		var friend: ExplorationSpot = mission.get_node("Spots/Recipient0") as ExplorationSpot
		mission._place_kalin(friend.position.x)
		mission.open_spot(friend)
		_close_lines(mission)
		mission._open_workbench()
		_check(
			mission.recall.mode == RecallPanel.Mode.WRITE,
			"Los encargos empiezan por escribir sin ayuda"
		)
		await _capture("03_taller_mundo%d" % world)
		mission._close_workbench()
		# El recorrido completo usa los controladores y comprueba uso persistente.
		await _complete_delivery()
		_check(mission.delivered.size() == 3, "Tres encargos resueltos en el mundo %d" % world)
		_check(
			mission.get_node("Delivered/Item0/UseMotion") is VillageUseMotion,
			"La entrega muestra una acción de uso persistente"
		)
		mission = await _resume("world%d_mission1" % world)
		_check(mission.delivered.size() == 3, "Las entregas sobreviven al reinicio desde JSON")
		mission._place_kalin(mission.get_node("Spots/Recipient2").position.x - 145)
		await _capture("04_aldea_mundo%d" % world)
	var damaged_draft: Node = await _scene(
		"world4_mission1",
		{
			"intro_done": true,
			"task_indices": [0, 2, 4],
			"combination_tasks": ["mayak|nojoch", "ja'|", "ich|mejen"],
			"residents": ["Miis", "Peek'", "Kaax"],
			"active_task": 1,
			"mission_met": [1],
			"workbench_open": true,
			"drafts": {"1": {"item": "ja'", "quality": "nojoch", "cards": true}}
		}
	)
	await process_frame
	_check(
		damaged_draft._draft_quality.is_empty() and damaged_draft.recall.second.text.is_empty(),
		"Un borrador inválido no conserva una cualidad imposible de retirar en un campo oculto"
	)


func _farewell() -> void:
	var farewell: Node = await _scene("world5_farewell")
	_close_lines(farewell)
	farewell._place_kalin(3500)
	farewell.open_spot(farewell.get_node("Spots/Salida"))
	_check(not farewell.assembly.visible, "El portal espera a que Kalin comparta los recuerdos")
	_close_lines(farewell)
	await _complete_farewell()
	_check(
		farewell.collected.size() == 3 and farewell.placed.size() == 3,
		"La despedida se completa caminando y reuniendo las páginas"
	)
	await _capture("05_portal_recuerdos")
	farewell.placed.erase(2)
	farewell._restore_pages()
	farewell = await _resume("world5_farewell")
	_check(
		farewell.assembly.visible and farewell.placed.size() == 2,
		"Continuar conserva el portal abierto con sus páginas parciales"
	)
	farewell._place_page("home", 2)
	_check(farewell.placed.size() == 2, "Una página en un destino incorrecto no activa el portal")
	farewell._select_page("friends")
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	farewell._slot_input(event, 2)
	_check(
		farewell.placed.size() == 3 and farewell.get_node("UI/Assembly/Continue").visible,
		"El clic alternativo al arrastre también completa el portal"
	)
	var ending: Node = load(GameContent.SCENE_PATHS.world5_story1).instantiate()
	_check(
		ending.beats.all(func(beat: StoryBeat): return beat.kind == StoryBeat.Kind.DIALOGO),
		"La despedida narrativa deja de repetir cuestionarios"
	)
	ending.free()


func _motion() -> void:
	var preferences: Node = root.get_node("AccessibilityManager")
	preferences.reduced_motion = true
	var story: Node = await _scene("world1_story1")
	while story.current_beat().kind != StoryBeat.Kind.CONOCER:
		story._next_beat()
	story._complete_text()
	await create_timer(0.7).timeout
	var actor: Button = story.actor_buttons.values()[0]
	story._hop(actor)
	(story._actor_tweens[actor] as Tween).custom_step(0.12)
	_check(
		actor.position.is_equal_approx(actor.get_meta("home_position")),
		"Reducir movimiento retira el salto de los animales de historia"
	)
	var level: Node = await _scene("world1_level1")
	var walker: TextureRect = TextureRect.new()
	level.add_child(walker)
	level._animate_arrival_step(0.5, walker, Vector2.ZERO, Vector2(72, 0), 1.0)
	_check(
		is_zero_approx(walker.position.y) and is_zero_approx(walker.rotation),
		"Reducir movimiento retira el rebote en las llegadas"
	)
	preferences.reduced_motion = false
	level._animate_arrival_step(0.5, walker, Vector2.ZERO, Vector2(72, 0), 1.0)
	_check(
		walker.position.y < -8 and not is_zero_approx(walker.rotation),
		"El estilo original de saltitos sigue disponible"
	)


func _screens() -> void:
	for physical_size: Vector2i in [
		Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360)
	]:
		root.size = physical_size
		for key: String in [
			"main_menu",
			"world2_level1",
			"world3_level1",
			"world4_level1",
			"world5_level1",
			"world2_mission1",
			"world3_mission1",
			"world4_mission1",
			"world5_farewell"
		]:
			var scene: Node = await _scene(key)
			var layout: ScreenLayout = scene.get_node("ScreenLayout") as ScreenLayout
			layout.preview_compact = physical_size.x <= 1024
			layout.refresh()
			if key.ends_with("mission1"):
				_close_lines(scene)
				var index: int = 0
				for candidate: int in range(3):
					if (
						scene.tasks[scene.task_indices[candidate]].request.length()
						> scene.tasks[scene.task_indices[index]].request.length()
					):
						index = candidate
				scene.active_task = index
				scene.met.append(index)
				scene._open_workbench()
			if key == "world5_farewell":
				await _complete_farewell()
			if key == "world2_level1":
				scene.round_index = 5
				scene._show_round()
				scene.mission_break.hide()
			if key in ["world3_level1", "world4_level1"]:
				scene.round_index = 7
				scene._show_round()
				scene.mission_break.hide()
				scene.recall.apply_compact(layout.compact)
			await process_frame
			await process_frame
			for node: Node in scene.get_node("UI").find_children("*", "", true, false):
				if node is RecallPanel and node.is_visible_in_tree():
					_check(
						Rect2(0, 0, 1280, 720).encloses(node.get_global_rect()),
						(
							"%s a %s: el panel de respuesta debe quedar completo dentro de pantalla"
							% [key, physical_size]
						)
					)
			for node: Node in scene.get_node("UI").find_children("*", "Button", true, false):
				var button: Button = node as Button
				if button.is_visible_in_tree():
					_check(
						Rect2(0, 0, 1280, 720).grow(2).encloses(button.get_global_rect()),
						(
							"%s a %s: botón fuera de pantalla: %s"
							% [key, physical_size, button.get_path()]
						)
					)
			await _capture("06_%s_%d" % [key, physical_size.x])
			if key == "main_menu":
				manager.session.words_learned = GameContent.VOCABULARY.duplicate(true)
				scene.libro.show_book()
				await scene.libro.motion.opened
				await _capture("07_libro_%d" % physical_size.x)
				scene.libro.hide_book()
				await scene.libro.motion.closed
	root.size = Vector2i(1280, 720)


func _save_version() -> void:
	var before: Dictionary = manager.session.snapshot()
	var file: FileAccess = FileAccess.open(manager._save_repository.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveSchema.CURRENT_VERSION - 1}))
	file.close()
	manager._load_save()
	_check(
		manager.load_failed and manager.session.snapshot() == before,
		"Un formato retirado se rechaza sin modificar la sesión ni sobrescribir la partida"
	)
	manager.reset_save()


func _keyboard_dock() -> void:
	var scene: Node = await _scene("world3_level1", {"round": 9, "layout_seed": 70})
	scene.mission_break.hide()
	await process_frame
	var layout: ScreenLayout = scene.get_node("ScreenLayout") as ScreenLayout
	var pause_layout: ScreenLayout = root.get_node("PauseMenu/ScreenLayout") as ScreenLayout
	var panel: RecallPanel = scene.recall
	panel.first.grab_focus()
	var original: Vector2 = panel.position
	layout._dock_keyboard(panel.first, 360)
	pause_layout._dock_keyboard(panel.first, 360)
	_check(
		(
			layout.get_node("Keyboard/Dock").visible
			and not pause_layout.get_node("Keyboard/Dock").visible
		),
		"Sólo la escena dueña del campo presenta el teclado"
	)
	_check(panel.position.y <= original.y, "El campo se mantiene por encima del teclado")
	layout.get_node("Keyboard/Dock/Submit").pressed.emit()
	_check(
		root.gui_get_focus_owner() == panel.second and scene._attempt.mistakes == 0,
		"Siguiente campo evita enviar una frase incompleta"
	)
	layout._hide_keyboard()
	_check(
		panel.position.is_equal_approx(original),
		"Cerrar el teclado restaura la distribución del campo"
	)
