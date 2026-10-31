## R1–R4 y P2: consecuencias observables y reanudación del último estado.
extends "res://tests/validate_game_expansion.gd"

const ART = preload("res://scenes/ui/shared/meaning_illustration.tscn")


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://revision_outcomes.json"))
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	await _exercise_views()
	await _quality_book_views()
	await _shared_projects()
	await _personal_memory()
	await _action_sequences()
	await _actions_in_context()
	await _meal_furniture()
	await _layout_exit_lifecycle()
	await process_frame
	if failures.is_empty():
		print("OK: destinos contenidos, respuesta única, plaza, acciones, recuerdos y actuaciones.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _exercise_views() -> void:
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(1280, 684), Vector2i(640, 360)]:
		root.size = window_size
		var suffix: String = "%dx%d" % [window_size.x, window_size.y]
		for world: int in [3, 4]:
			var key: String = "world%d_level1" % world
			var scene: Node = await _scene(key, {"layout_seed": 743})
			scene.guide.stop()
			var compact: bool = window_size.x <= 1024
			scene.get_node("ScreenLayout").preview_compact = compact
			scene.get_node("ScreenLayout").refresh()
			await process_frame
			await process_frame
			var slots: Array[Control] = []
			slots.assign(
				(
					[scene.noun_slot, scene.adjective_slot]
					if world == 3
					else [scene.food_slot, scene.modifier_slot]
				)
			)
			for slot: Control in slots:
				if slot.is_visible_in_tree():
					_check(
						scene.spell_panel.get_global_rect().encloses(slot.get_global_rect()),
						"Cada destino cabe en la caja de composición en " + suffix
					)
			_check(not scene.result_art.visible, "La creación no aparece antes de confirmar")
			await _capture("tarjetas_%d_%s" % [world, suffix])
			var selection: ExerciseEntry = scene._current_challenge()
			if world == 3:
				scene._select_noun(selection.noun)
				scene._select_adjective(selection.adjective)
			else:
				scene._select_food(selection.food)
				scene._select_modifier(selection.modifier)
			_check(
				not scene.result_art.visible,
				"Elegir tarjetas no muestra el resultado antes de confirmar"
			)
			scene._show_help()
			await _capture("ayuda_tarjetas_%d_%s" % [world, suffix])
			scene = await _scene(key, PhraseExerciseFixture.recall_state(743))
			scene.mission_break.hide()
			scene.guide.stop()
			scene.get_node("ScreenLayout").preview_compact = compact
			scene.get_node("ScreenLayout").refresh()
			scene.recall.first.text = "mi intento"
			_check(
				scene.recall.get_node_or_null("Margin/Content/Workspace") == null,
				"Escribir conserva una sola representación editable"
			)
			await _capture("escritura_%d_%s" % [world, suffix])
			if world == 3:
				scene.recall.second.text = "mi intento"
				scene._on_cast_pressed()
			else:
				if scene.recall.second_box.visible:
					scene.recall.second.text = "mi intento"
				scene._on_serve_pressed()
			_check(not scene.result_art.visible, "Un error no revela la creación esperada")
			await _capture("error_%d_%s" % [world, suffix])
			var challenge: ExerciseEntry = scene._current_challenge()
			RecallFiller.fill(
				scene.recall,
				(
					[challenge.noun, challenge.adjective]
					if world == 3
					else [challenge.food, challenge.modifier]
				)
			)
			if world == 3:
				scene._on_cast_pressed()
			else:
				scene._on_serve_pressed()
			_check(scene._awaiting_continue, "Confirmar muestra el resultado")
			await _capture("acierto_%d_%s" % [world, suffix])
	root.size = Vector2i(1280, 720)


func _quality_book_views() -> void:
	if capture_folder.is_empty():
		return
	for word: String in ["mejen", "nojoch", "chich"]:
		manager.learn_word(word)
	var home: Node = await _scene("village_home")
	var book: Node = home.get_node("LibroHechizos")
	for compact: bool in [false, true]:
		root.size = Vector2i(640, 360) if compact else Vector2i(1280, 720)
		book.show_book(home.return_button)
		await create_timer(0.65).timeout
		book._select_category(3)
		await create_timer(0.65).timeout
		while not book.previous_button.disabled:
			book.previous_button.pressed.emit()
			await create_timer(0.65).timeout
		for page: int in range(book._spread_count()):
			await _capture(
				"libro_cualidades_%s_%d" % ["compacto" if compact else "escritorio", page]
			)
			if not book.next_button.disabled:
				book.next_button.pressed.emit()
				await create_timer(0.65).timeout
		book.hide_book()
		await create_timer(0.65).timeout
	root.size = Vector2i(1280, 720)


func _shared_projects() -> void:
	for world: int in [2, 3, 4]:
		var key: String = "world%d_mission1" % world
		var scene: Node = await _scene(key, {"intro_done": true, "layout_seed": 349})
		_close_lines(scene)
		scene.guide.stop()
		_check(
			(
				(
					scene.get_node("Spots/Recipient1").position.x
					- scene.get_node("Spots/Recipient0").position.x
				)
				>= 400
			),
			"Los grupos disponen de espacio para sus objetos y sus habitantes"
		)
		await _capture("plaza_%d_inicio" % world)
		for index: int in [2, 0, 1]:
			if index == 2:
				scene.toggle_journal()
				(scene.get_node("UI/Direct").get_child(index) as Button).grab_focus()
				await _press_key(KEY_ENTER)
				_check(
					scene.is_dialogue_open() and scene.active_task == index,
					"El acceso directo por teclado abre al amigo elegido"
				)
			else:
				scene.visit_task(index)
			_close_lines(scene)
			scene.visit_workbench()
			var task: VillageTask = scene.tasks[scene.task_indices[index]]
			RecallFiller.fill(scene.recall, [task.item, task.quality])
			scene._forge()
			if index == 2:
				scene = await _resume(key)
				_check(
					index not in scene.delivered and not scene.carried.is_empty(),
					"Reanudar tras crear no inventa una entrega pendiente"
				)
			var before: int = manager.learning_record(task.item).use
			scene.visit_task(index)
			_close_lines(scene)
			_check(
				index in scene.delivered and scene.carried.is_empty(),
				"Entregar coloca el aporte funcional sin decisiones de ubicación adicionales"
			)
			if scene.gathering.visible:
				await _capture("celebracion_%d" % world)
				scene.gathering.close_gathering()
			scene = await _resume(key)
			_check(
				manager.learning_record(task.item).use == before + 1,
				"La entrega registra un uso; restaurar no lo acredita otra vez"
			)
			scene.guide.stop()
			await _capture("plaza_%d_aporte_%d" % [world, scene.delivered.size()])
		_check(scene.delivered == [2, 0, 1], "Los tres aportes admiten un orden elegido")
		root.size = Vector2i(640, 360)
		await process_frame
		await _capture("plaza_%d_compacto" % world)
		root.size = Vector2i(1280, 720)
	var walk: Node = await _scene("world3_explore1", {"intro_done": true, "layout_seed": 349})
	_close_lines(walk)
	walk._show_choices(0)
	var task: VillageTask = walk.encounters[0].task
	_check(walk._request_text(0).contains(task.purpose), "La petición conserva una voz y un motivo")
	_check(
		not walk._request_text(0).contains(task.request),
		"El contexto no copia la traducción del objetivo"
	)
	await _capture("peticion_con_motivo")
	root.size = Vector2i(640, 360)
	await process_frame
	await _capture("peticion_con_motivo_compacto")
	_check(
		not walk.get_node("UI/ObjectivePanel").visible,
		"La petición abierta tiene una sola representación y no desborda el pie"
	)
	root.size = Vector2i(1280, 720)
	walk._translate_request()
	_check(0 in walk.translated, "Traducir sigue registrado como apoyo de contenido")
	await _capture("peticion_traducida")


func _personal_memory() -> void:
	var farewell: Node = await _scene("world5_farewell", {"intro_done": true, "layout_seed": 349})
	var invalid_visits: Array[Dictionary] = [
		{"delivered": [0], "combination_tasks": ["mayak|"], "residents": ["inexistente"]}, {}, {}
	]
	for option: Dictionary in VillageMemory.options(invalid_visits, farewell.gifts):
		_check(not option.is_empty(), "Una visita inválida conserva la cortesía vivida como opción")
	await _complete_farewell()
	var learning: Dictionary = manager.session.learning_progress.duplicate(true)
	for index: int in [0, 2]:
		if index == 2:
			farewell = await _scene("world5_farewell", manager.saved_scene_state("world5_farewell"))
			farewell._open_memory_choice()
		farewell.memory_choice.choose(index)
		var memory: Dictionary = farewell.memory.duplicate(true)
		_check(not memory.is_empty(), "La preferencia tiene una imagen de algo vivido")
		farewell = await _resume("world5_farewell")
		_check(
			farewell.memory == memory and farewell.memory_choice.visible,
			"JSON conserva selección e imagen antes de cruzar"
		)
		await _capture("portal_recuerdo_%d" % index)
		for window_size: Vector2i in [Vector2i(1280, 684), Vector2i(640, 360)]:
			root.size = window_size
			await process_frame
			await _capture("portal_recuerdo_%d_%dx%d" % [index, window_size.x, window_size.y])
		root.size = Vector2i(1280, 720)
		manager.checkpoint(farewell)
		var home: Node = await _scene("world5_cine1", {"beat": 4})
		home.auto_timer.stop()
		home._complete_text()
		await create_timer(0.8).timeout
		await process_frame
		_check(
			home.get_node("HomecomingMemory/UI/MemoryMoment").visible,
			"El recuerdo elegido aparece al regresar a casa"
		)
		await _capture("casa_recuerdo_%d" % index)
		root.size = Vector2i(640, 360)
		await process_frame
		await _capture("casa_recuerdo_%d_compacto" % index)
		root.size = Vector2i(1280, 720)
	_check(
		manager.session.learning_progress == learning,
		"La preferencia y su reanudación no generan evidencia educativa"
	)
	farewell = await _scene("world5_farewell", manager.saved_scene_state("world5_farewell"))
	farewell.memory_choice.get_node("Panel/Confirm").pressed.emit()
	await scene_changed
	_check(
		current_scene.scene_file_path == GameContent.SCENE_PATHS.world5_story1,
		"Confirmar el recuerdo permite cruzar hacia la despedida narrativa"
	)
	_check(
		VillageMemory.normalize({"kind": [], "animal": "Miis"}).is_empty(),
		"Un recuerdo de tipos inválidos no se representa"
	)


func _action_sequences() -> void:
	await _scene("main_menu")
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	var motions: Array[VillageUseMotion] = []
	for item: String in ["ja'as", "ja'"]:
		for child: Node in layer.get_children():
			layer.remove_child(child)
			child.queue_free()
		motions.clear()
		var background: ColorRect = ColorRect.new()
		background.color = Color("f7efdc")
		background.size = Vector2(1280, 720)
		layer.add_child(background)
		var index: int = 0
		for animal: String in VillageResidents.HOMES:
			var group: Node2D = Node2D.new()
			group.position = Vector2(160 + (index % 4) * 320, 205 + floori(index / 4.0) * 230)
			layer.add_child(group)
			var actor: Sprite2D = Sprite2D.new()
			actor.texture = VillageUseArt.ACTORS[animal]
			actor.position = Vector2(0, -60)
			group.add_child(actor)
			var art: MeaningIllustration = ART.instantiate() as MeaningIllustration
			art.size = Vector2(160, 120)
			art.position = Vector2(-80, -115)
			group.add_child(art)
			art.show_meaning(item, "ki'" if item == "ja'as" else "")
			var motion: VillageUseMotion = VillageUseMotion.attach(actor, art, item, animal)
			motion.set_process(false)
			motions.append(motion)
			var name_label: Label = Label.new()
			name_label.text = animal
			name_label.position = Vector2(-110, 8)
			name_label.add_theme_color_override("font_color", Color("214f45"))
			name_label.add_theme_font_size_override("font_size", 22)
			group.add_child(name_label)
			index += 1
		var feet_at_rest: Dictionary = {}
		for instant: float in [0.2, 0.8, 1.1, 1.7, 2.3, 3.5]:
			for motion: VillageUseMotion in motions:
				motion.sample_action(instant)
				_check(motion.actor.texture != null, "Cada animal tiene una actuación configurada")
				if motion.animal != "Kay":
					var feet: Vector2 = motion._rig.to_global(Vector2(60, 110))
					if instant == 0.2:
						feet_at_rest[motion.animal] = feet
					_check(
						feet.distance_to(feet_at_rest[motion.animal]) < 1,
						"Inclinarse conserva los pies apoyados"
					)

				if motion.animal == "Kay":
					_check(
						motion.pond.visible and is_zero_approx(motion.actor.rotation),
						"Kay conserva su orilla durante la actuación"
					)
			await _capture("secuencia_%s_%.1f" % ["beber" if item == "ja'" else "comer", instant])
		await _geometry_contacts(motions, item)
		await _capture_species_details(motions, item)
		var sample: VillageUseMotion = motions[0]
		sample.set_process(true)
		sample.receive()
		paused = true
		var time_before: float = sample._action_time
		await create_timer(0.05, true).timeout
		_check(sample._action_time == time_before, "La pausa detiene la actuación")
		paused = false
		root.get_node("AccessibilityManager").reduced_motion = true
		await process_frame
		await process_frame
		var stable: Vector2 = sample._portion.global_position
		await process_frame
		await process_frame
		_check(
			sample._portion.global_position.distance_to(stable) < 0.1,
			"Movimiento reducido conserva el alimento servido estable"
		)
		root.get_node("AccessibilityManager").reduced_motion = false
	layer.queue_free()
	await process_frame


func _geometry_contacts(motions: Array[VillageUseMotion], item: String) -> void:
	for motion: VillageUseMotion in motions:
		if motion.animal == "Kay":
			continue
		var feet: Sprite2D = motion._rig.get_child(0) as Sprite2D
		var used_feet: Rect2i = feet.texture.get_image().get_used_rect()
		var support: Vector2 = Vector2(used_feet.get_center().x, used_feet.end.y)
		var initial_support: Vector2 = Vector2.ZERO
		for clock: float in [0.0, 1.0, 2.0, 3.0]:
			motion.elapsed = clock
			motion._process(0.0)
			var point: Vector2 = feet.to_global(support)
			if clock == 0:
				initial_support = point
			_check(
				point.distance_to(initial_support) < 0.1,
				"Los pies dibujados permanecen plantados en reproducción continua"
			)
		motion.sample_action(0.2)
		var rest: Vector2 = _drawn_food_center(motion)
		motion.sample_action(motion._rig.contact_time())
		await process_frame
		if item != "ja'":
			if motion.art.quality_badge.visible:
				_check(
					(
						motion.art.quality_badge.get_global_rect().get_center().distance_to(
							_drawn_food_center(motion)
						)
						< 80 * motion.actor.global_scale.x
					),
					"El aroma permanece junto al alimento servido o sostenido"
				)
			if motion.animal == "Ma'ax":
				var hand: Line2D = motion._rig.hand
				var used: Rect2i = motion._portion.texture.get_image().get_used_rect()
				var bottom: Vector2 = motion._portion.to_global(
					(
						Vector2(used.get_center().x, used.end.y)
						- motion._portion.texture.get_size() * 0.5
					)
				)
				_check(
					hand.to_global(hand.points[-1]).distance_to(bottom) < 1,
					"La porción de Ma’ax viaja en la mano dibujada"
				)
			else:
				_check(
					rest.distance_to(_drawn_food_center(motion)) < 1,
					"El alimento permanece servido mientras el animal se acerca"
				)
		elif motion.animal in ["Kaax", "Kuuts", "Ch'íich'"]:
			var tip: Vector2 = _raster_beak_tip(motion._rig)
			# El borde dibujado de agua.svg es una elipse (120,34), radios (47,14).
			# Se verifica la abertura, no que dos centros calculados por la actuación coincidan.
			var aperture: Vector2 = (
				(motion._vessel.to_local(tip) - Vector2(120, 34)) / Vector2(47, 14)
			)
			_check(
				aperture.length_squared() <= 1.0,
				"El pico rasterizado toca el borde real del vaso: " + motion.animal
			)
			print("Contacto con abertura dibujada ", motion.animal, ": ", aperture.length_squared())


func _drawn_food_center(motion: VillageUseMotion) -> Vector2:
	if motion._portion.texture == null:
		return Vector2.ZERO
	var used: Rect2i = motion._portion.texture.get_image().get_used_rect()
	return motion._portion.to_global(
		Vector2(used.get_center()) - motion._portion.texture.get_size() * 0.5
	)


func _raster_beak_tip(rig: SpeciesActionRig) -> Vector2:
	# Se inspecciona el pigmento del SVG rasterizado, independientemente de MOUTHS.
	var picture: Sprite2D = rig.head_picture
	var raster: Image = picture.texture.get_image()
	var left: int = raster.get_width()
	var tip: Vector2 = Vector2.ZERO
	for y: int in range(raster.get_height()):
		for x: int in range(raster.get_width()):
			var color: Color = raster.get_pixel(x, y)
			if (
				color.a > 0.1
				and color.r > 0.8
				and color.g > 0.5
				and color.g < 0.75
				and color.b < 0.25
				and x < left
			):
				left = x
				tip = Vector2(x + 0.5, y + 0.5)
	_check(left < raster.get_width(), "El dibujo contiene un pico identificable")
	return picture.to_global(tip)


func _capture_species_details(motions: Array[VillageUseMotion], item: String) -> void:
	if capture_folder.is_empty():
		return
	var positions: Array[Vector2] = []
	for motion: VillageUseMotion in motions:
		positions.append((motion.actor.get_parent() as Node2D).position)
	for page: int in range(3):
		for phase: String in ["mirada", "acercamiento", "contacto", "regreso"]:
			for index: int in range(motions.size()):
				var motion: VillageUseMotion = motions[index]
				var group: Node2D = motion.actor.get_parent() as Node2D
				group.visible = floori(index / 4.0) == page
				group.position = Vector2(
					320 + (index % 2) * 640, 285 + floori((index % 4) / 2.0) * 330
				)
				group.scale = Vector2.ONE * 1.65
				var moment: float = motion._rig.contact_time()
				var time: float = {
					"mirada": 0.2,
					"acercamiento": moment * 0.7,
					"contacto": moment,
					"regreso": moment + 1.6
				}[phase]
				motion.sample_action(time)
			await _capture(
				"detalle_%s_%d_%s" % ["beber" if item == "ja'" else "comer", page, phase]
			)
	for index: int in range(motions.size()):
		var group: Node2D = motions[index].actor.get_parent() as Node2D
		group.visible = true
		group.scale = Vector2.ONE
		group.position = positions[index]


func _actions_in_context() -> void:
	var scene: Node = await _scene(
		"world4_mission1",
		{
			"intro_done": true,
			"layout_seed": 349,
			"residents": ["Ma'ax", "Kaax", "Kay"],
			"task_indices": [0, 2, 4],
			"combination_tasks": ["ja'as|", "janal|", "ja'|"],
			"mission_met": [0, 1, 2],
			"delivered": [0, 1, 2],
			"gathering_seen": true
		}
	)
	scene.guide.stop()
	var motions: Array[VillageUseMotion] = []
	for index: int in range(3):
		var motion: VillageUseMotion = scene.get_node("Delivered/Item%d/UseMotion" % index)
		motion.set_process(false)
		motions.append(motion)
	for window_size: Vector2i in [Vector2i(1280, 684), Vector2i(640, 360)]:
		root.size = window_size
		await process_frame
		for instant: float in [0.2, 0.8, 1.1, 1.7, 2.3, 3.5]:
			for motion: VillageUseMotion in motions:
				motion.sample_action(instant)
			await _capture("accion_en_plaza_%dx%d_%.1f" % [window_size.x, window_size.y, instant])
	root.size = Vector2i(1280, 720)


func _press_key(code: Key) -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.pressed = down
		root.push_input(event, true)
		await process_frame


func _layout_exit_lifecycle() -> void:
	var host: Node2D = Node2D.new()
	root.add_child(host)
	var layout: ScreenLayout = (
		preload("res://scenes/ui/shared/screen_layout.tscn").instantiate() as ScreenLayout
	)
	host.add_child(layout)
	host.remove_child(layout)
	layout._capture()
	await process_frame
	_check(
		not layout._captured,
		"Un perfil retirado descarta la captura diferida sin consultar una ventana destruida"
	)
	layout.refresh()
	layout.free()
	host.queue_free()
	# Cargar después de los autoloads: el ejecutor inicia primero este SceneTree.
	var interaction: Node = load("res://scripts/features/story/story_interaction.gd").new()
	root.add_child(interaction)
	interaction.call_deferred("refresh")
	root.remove_child(interaction)
	interaction.refresh()
	interaction.set_text_revealing(false)
	await process_frame
	_check(
		not interaction._actor_input_allowed(),
		"Una interacción retirada descarta su foco diferido y bloquea la entrada"
	)
	interaction.free()


func _meal_furniture() -> void:
	var scene: Node = await _scene(
		"world4_mission1",
		{
			"intro_done": true,
			"layout_seed": 349,
			"residents": ["Ma'ax", "Kay", "Kaax"],
			"task_indices": [0, 2, 4],
			"combination_tasks": ["k'áanche'|chich", "mayak|nojoch", "k'áan|mejen"],
			"mission_met": [0, 1, 2],
			"delivered": [0, 1, 2],
			"gathering_seen": true
		}
	)
	scene.guide.stop()
	for index: int in range(3):
		var art: MeaningIllustration = scene.get_node("Delivered/Item%d" % index)
		var picture: Rect2 = art.picture_rect()
		var support: float = 150.0 / 180.0 if art.word == "k'áan" else 160.0 / 180.0
		var feet: Vector2 = (
			art.get_global_transform() * (picture.position + picture.size * Vector2(0.5, support))
		)
		_check(
			absf(feet.y - scene.get_node("Spots/Recipient%d" % index).position.y) < 2.0,
			"Los muebles de la merienda conservan sus apoyos en el suelo"
		)
	await _capture("mesa_con_mobiliario")
	root.size = Vector2i(640, 360)
	await process_frame
	await _capture("mesa_con_mobiliario_compacto")
	root.size = Vector2i(1280, 720)
	var pending: Dictionary = scene.get_checkpoint_state()
	pending.delivered.erase(0)
	pending.carried = {
		"item": "k'áanche'",
		"quality": "chich",
		"supported": false,
		"mistakes": 0,
		"phase": "recall",
		"attempt": {}
	}
	scene = await _scene("world4_mission1", pending)
	_close_lines(scene)
	scene.visit_task(0)
	_close_lines(scene)
	_check(
		0 in scene.delivered and scene.carried.is_empty(),
		"Un mueble se coloca también en la merienda"
	)
	await _capture("mueble_entregado_en_mesa")
