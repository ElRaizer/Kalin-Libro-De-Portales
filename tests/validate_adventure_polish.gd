## Interacción real, paseos, borradores, vuelta a la aventura y preferencias.
## Capturas opcionales con renderer real: -- --capture=<carpeta absoluta>
extends SceneTree

var manager: Node
var failures: Array[String] = []
var capture_folder: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _scene(key: String, fresh: bool = true) -> void:
	if fresh:
		manager.session.scene_states.erase(key)
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await create_timer(0.1).timeout


func _click(control: Control) -> void:
	await process_frame
	_check(
		control.is_visible_in_tree(),
		"El control debe estar visible antes de pulsarlo: " + str(control.get_path())
	)
	var point: Vector2 = control.get_global_transform_with_canvas() * (control.size * 0.5)
	_check(
		Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(point),
		"El control debe poder pulsarse dentro de la ventana: " + str(control.name)
	)
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _key(code: int, unicode_value: int = 0) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.unicode = unicode_value
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _type(value: String) -> void:
	for index: int in range(value.length()):
		await _key(value[index].to_upper().unicode_at(0), value.unicode_at(index))


func _close_dialogue(scene: Node) -> void:
	await process_frame
	await process_frame
	for index: int in range(12):
		if not scene.is_dialogue_open():
			break
		await _click(scene.continue_button)


func _capture(name: String) -> void:
	if capture_folder.is_empty():
		return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_folder.path_join(name + ".png"))


func _approach(scene: Node, spot: ExplorationSpot) -> void:
	scene._place_kalin(spot.position.x - 145)
	scene.camera.reset_smoothing()
	await process_frame
	await process_frame
	await _key(KEY_E)


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://adventure_polish_validation.json")
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	for index: int in range(1, 5):
		await _scene("world1_level%d" % index)
		_check(
			not current_scene.recall.is_visible_in_tree(),
			"Un tablero nuevo empieza sin el panel de respuesta"
		)
		_check(
			current_scene.grid_board.connected.is_empty(),
			"El panel no se oculta por haber completado el tablero"
		)
		if index == 1:
			await _capture("01_tablero_corregido")
	await _walks()
	await _drafts()
	await _fallbacks()
	await _landscape_edges()
	await _practice_and_comfort()
	for key: String in ["reduced_motion", "reduced_flashes", "instant_text"]:
		root.get_node("AccessibilityManager").set_preference(key, false)
	if failures.is_empty():
		print("OK: paseos interactivos, consecuencias, borradores, visitas, ayudas y preferencias.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _walks() -> void:
	for world: int in [2, 3]:
		var key: String = "world%d_explore1" % world
		await _scene(key)
		var walk: Node = current_scene
		for encounter: VillageEncounter in walk.encounters:
			_check(
				encounter.get_configuration_issues().is_empty(),
				"Los encuentros tienen personajes, palabras y soluciones válidos"
			)
		await _close_dialogue(walk)
		walk.walk(1.0, 0.05)
		var first_pose: Texture2D = walk.kalin_sprite.texture
		walk.walk(1.0, 0.2)
		_check(
			(
				walk.kalin_sprite.texture == first_pose
				and walk.kalin_sprite.position.y < walk._kalin_base_position.y
			),
			"Kalin conserva su dibujo y camina con saltitos"
		)
		walk.walk(0.0, 0.0)
		_check(
			walk.kalin_sprite.texture == first_pose,
			"Detenerse conserva la identidad visual del personaje"
		)
		for index: int in range(walk.encounters.size()):
			var spot: ExplorationSpot = walk._encounter_spot(index)
			await _approach(walk, spot)
			await _close_dialogue(walk)
			_check(
				walk._choice_index == index, "Conversar abre los hechizos del personaje correcto"
			)
			walk.camera.reset_smoothing()
			await process_frame
			await process_frame
			var correct_button: int = -1
			for button_index: int in range(3):
				var spell: ExerciseEntry = walk.encounters[index].choices[
					walk._choice_order[button_index]
				]
				var task: VillageTask = walk.encounters[index].task
				if spell.noun == task.item and spell.adjective == task.quality:
					correct_button = button_index
			_check(correct_button >= 0, "Cada encuentro ofrece una solución")
			if index == 0:
				await _capture("02_paseo_%d_hechizos" % world)
				await _click(walk.choices_root.get_child((correct_button + 1) % 3))
				_check(
					walk.solved.is_empty() and walk._mistakes == 1,
					"Un hechizo diferente permite volver a elegir sin resolver el encuentro"
				)
			await _click(walk.choices_root.get_child(correct_button))
			_check(
				index in walk.solved and walk.get_node("Results").get_child(index).visible,
				"La elección coloca un objeto permanente junto a su destinatario"
			)
			await _close_dialogue(walk)
			for word: String in walk.encounters[index].task.words():
				_check(
					manager.session.learning_progress[word].recalls.is_empty(),
					"Los dibujos del paseo no acreditan recuerdo independiente"
				)
		await _capture("03_paseo_%d_resuelto" % world)
		await _scene(key, false)
		walk = current_scene
		_check(walk.solved.size() == 3, "Los tres cambios del mundo sobreviven al checkpoint")
		await _approach(walk, walk.get_node("Spots/Salida"))
		await _close_dialogue(walk)
		await create_timer(0.7).timeout
		_check(
			current_scene.scene_file_path == GameContent.SCENE_PATHS["world%d_story1" % world],
			"El paseo conduce a su capítulo"
		)
	# Un descanso debe volver al intento guardado, no reiniciar ni crear un bucle.
	await _scene("world3_level1")
	current_scene.round_index = 6
	current_scene._show_round()
	await _click(current_scene.mission_break.get_node("WalkButton"))
	await create_timer(0.1).timeout
	_check(
		(
			current_scene.scene_file_path == GameContent.SCENE_PATHS.world3_explore1
			and current_scene.next_scene_key == "world3_level1"
		),
		"El descanso conoce su punto de regreso"
	)
	current_scene._go_to_next_scene()
	await scene_changed
	await process_frame
	_check(
		current_scene.round_index == 6 and not current_scene.mission_break.visible,
		"Volver del descanso conserva la petición y no repite la interrupción"
	)
	current_scene._on_next_level_pressed()
	await scene_changed
	await process_frame
	_check(
		current_scene.next_scene_key == "world3_mission1",
		"La salida final pasa a los encargos y no vuelve al nivel completado"
	)


func _drafts() -> void:
	# Este caso necesita dos campos; otras visitas pueden pedir tres objetos sin cualidad.
	manager.session.scene_states["world4_mission1"] = {
		"layout_seed": 173, "combination_tasks": ["mayak|nojoch", "k'áan|mejen", "janal|ki'"]
	}
	await _scene("world4_mission1", false)
	var mission: Node = current_scene
	await _close_dialogue(mission)
	var target_index: int = 0
	for index: int in range(3):
		if not mission.tasks[mission.task_indices[index]].quality.is_empty():
			target_index = index
			break
	await _approach(mission, mission.get_node("Spots/Recipient%d" % target_index))
	await _close_dialogue(mission)
	await _approach(mission, mission.get_node("Spots/Workbench"))
	_check(mission.mission_panel.visible, "Acercarse e interactuar abre el taller")
	await _click(mission.recall.first)
	await _type("may")
	await _click(mission.recall.second)
	await _type("no")
	await _key(KEY_ESCAPE)
	_check(
		not mission.mission_panel.visible and not paused,
		"Esc cierra primero el taller, sin abrir la pausa"
	)
	await _key(KEY_E)
	_check(mission.recall.values() == ["may", "no"], "Cerrar y abrir conserva el texto parcial")
	manager.checkpoint(mission)
	manager._load_save()
	await _scene("world4_mission1", false)
	mission = current_scene
	_check(
		mission.mission_panel.visible and mission.recall.values() == ["may", "no"],
		"Continuar restaura el taller abierto y su borrador"
	)
	await _capture("04_borrador_conservado")
	_check(
		not mission.recall.get_node("Margin/Content/Actions/Practice").visible,
		"El jugador no puede saltar manualmente a las tarjetas"
	)
	await _click(mission.forge_button)
	_check(
		mission.recall.mode == RecallPanel.Mode.CLOZE,
		"El primer error del borrador ofrece completar"
	)
	await _click(mission.recall.first)
	await _type("incorrecto")
	await _click(mission.forge_button)
	_check(mission.recall.mode == RecallPanel.Mode.BLOCKS, "El segundo error ofrece las piezas")
	await _click(mission.recall.get_node("Margin/Content/Blocks/Bank").get_child(0))
	var recipe: Array = mission.recall._slots.duplicate(true)
	await _key(KEY_ESCAPE)
	await _key(KEY_E)
	_check(
		mission.recall.mode == RecallPanel.Mode.BLOCKS and mission.recall._slots == recipe,
		"El apoyo automático y la disposición de piezas sobreviven al cierre"
	)


func _fallbacks() -> void:
	for world: int in [3, 4]:
		await _scene("world%d_level1" % world)
		current_scene.round_index = current_scene.challenges.size()
		current_scene._show_round()
		if current_scene.mission_break.visible:
			await _click(current_scene.mission_break.continue_button)
		var submit: Button = current_scene.cast_button if world == 3 else current_scene.serve_button
		for mode_value: int in [RecallPanel.Mode.CLOZE, RecallPanel.Mode.BLOCKS]:
			await _click(current_scene.recall.first)
			await _type("incorrecto")
			if current_scene.recall.second_box.visible:
				await _click(current_scene.recall.second)
				await _type("incorrecto")
			await _click(submit)
			_check(
				(
					current_scene.recall.visible
					and current_scene.recall.mode == mode_value
					and current_scene._attempt.supported
				),
				"La entrada real activa el siguiente apoyo automático"
			)
		_check(
			(
				"bloques" in current_scene.mission_progress.caption
				and "sin pistas" not in current_scene.mission_progress.caption
			),
			"El progreso muestra el apoyo que está utilizando el jugador"
		)
	await _scene("world3_level1")
	current_scene.round_index = 7
	current_scene._show_round()
	if not capture_folder.is_empty():
		root.size = Vector2i(960, 540)
		await _capture("05_recuerdo_960")
		root.size = Vector2i(1280, 720)


func _practice_and_comfort() -> void:
	manager.session.completed_levels.assign(
		["w1_l1", "w1_l2", "w1_l3", "w1_l4", "w2_l1", "w3_l1", "w4_l1"]
	)
	manager.session.resume_scene_key = "world5_level1"
	await _scene("main_menu")
	await _capture("06_mapa")
	await _click(current_scene.get_node("UI/VisitButton"))
	await create_timer(0.1).timeout
	_check(
		(
			current_scene.scene_file_path == GameContent.SCENE_PATHS.village_practice
			and current_scene.free_practice
		),
		"El mapa ofrece una visita independiente"
	)
	await _close_dialogue(current_scene)
	await _click(current_scene.skip_button)
	await create_timer(0.7).timeout
	_check(
		(
			current_scene.scene_file_path == GameContent.SCENE_PATHS.main_menu
			and manager.session.resume_scene_key == "world5_level1"
		),
		"Volver de la visita recupera el destino de la aventura principal"
	)
	await _click(current_scene.get_node("UI/ComfortButton"))
	_check(paused, "Las opciones detienen el juego")
	await _click(root.get_node("PauseMenu/Shade/Panel/ReducedMotion"))
	await _click(root.get_node("PauseMenu/Shade/Panel/ReducedFlashes"))
	await _click(root.get_node("PauseMenu/Shade/Panel/InstantText"))
	var preferences: Node = root.get_node("AccessibilityManager")
	_check(
		preferences.reduced_motion and preferences.reduced_flashes and preferences.instant_text,
		"Los tres controles cambian las preferencias"
	)
	var stored: ConfigFile = ConfigFile.new()
	_check(
		(
			stored.load(preferences.PREFERENCES_PATH) == OK
			and stored.get_value("comfort", "instant_text", false)
		),
		"Las preferencias se guardan fuera de la partida"
	)
	await _capture("07_a_tu_ritmo")
	await _key(KEY_ESCAPE)
	_check(not paused, "Esc cierra las opciones también desde el mapa")
	await _scene("world1_story1")
	_check(
		current_scene.dialogue_text.visible_ratio == 1.0,
		"El texto completo se aplica a la historia"
	)
	current_scene._animator.flash_screen()
	_check(current_scene.flash_rect.modulate.a == 0.0, "La preferencia evita el destello blanco")
	await _scene("world3_level1")
	current_scene.libro.show_book()
	await current_scene.libro.motion.opened
	_check(
		paused and not current_scene.libro.motion.cover.visible,
		"El libro reducido se abre sin vuelo y mantiene la pausa"
	)
	current_scene.libro.hide_book()
	await current_scene.libro.motion.closed
	_check(not paused, "Cerrar el libro reducido devuelve el control")


func _landscape_edges() -> void:
	for key: String in [
		"world1_explore1",
		"world2_explore1",
		"world3_explore1",
		"world4_mission1",
		"village_practice"
	]:
		await _scene(key)
		var scene: Node = current_scene
		await _close_dialogue(scene)
		var terrain: Sprite2D = scene.get_node("Terreno") as Sprite2D
		var bounds: Rect2 = terrain.get_global_transform() * terrain.get_rect()
		_check(
			scene.camera.limit_right <= floori(bounds.end.x),
			"La cámara termina dentro del SVG: " + key
		)
		for end: float in [scene._min_x, scene._max_x]:
			scene._place_kalin(end)
			scene.camera.reset_smoothing()
			await process_frame
			await process_frame
			var center: Vector2 = scene.camera.get_screen_center_position()
			var half_width: float = scene.get_viewport_rect().size.x / scene.camera.zoom.x * 0.5
			_check(
				(
					center.x - half_width >= bounds.position.x - 1
					and center.x + half_width <= bounds.end.x + 1
				),
				"El paisaje cubre la ventana en ambos extremos: " + key
			)
		if key == "world4_mission1":
			_check(
				terrain.texture.resource_path.ends_with("bg_aldea_habitada_portal.svg"),
				"El paseo final utiliza su propio claro del portal"
			)
			_check(
				scene.get_node("Spots/Salida").spot_texture.resource_path.ends_with(
					"portal_aldea.svg"
				),
				"La salida final es un portal visible, no una casa"
			)
			await _capture("09_portal_extremo")
		elif key == "world2_explore1":
			_check(
				bounds.size.x >= 5120, "La aldea conserva margen de paisaje más allá del sendero"
			)
			await _capture("08_aldea_extremo")
		elif key == "village_practice":
			_check(
				(
					terrain.texture.resource_path.ends_with("bg_aldea_habitada.svg")
					and scene.get_node("Spots/Salida").spot_texture.resource_path.ends_with(
						"ui_casa.svg"
					)
				),
				"La visita de práctica conserva la aldea y su salida al mapa"
			)
