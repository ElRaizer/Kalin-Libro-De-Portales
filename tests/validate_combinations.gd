extends "res://tests/validate_game_expansion.gd"

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://combination_validation.json")
	manager.reset_save()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	_catalog()
	_plans()
	await _runtime()
	await _portal_recap()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("OK: 28 combinaciones válidas, 37 pedidos, 1392 textos, planes variables, práctica previa, opciones y guardado compatible.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _catalog() -> void:
	_check(CombinationCatalog.ROWS.size() == 28 and CombinationCatalog.targets().size() == 37, "Lista cerrada de 28 combinaciones y nueve peticiones simples")
	for id: String in ["lak|chich", "k'áanche'|ki'", "janal|nojoch", "ja'|mejen", "ja'|ki'", "ich|chich"]:
		_check(not CombinationCatalog.allowed(id), "Excluir combinaciones absurdas o contextuales: " + id)
	for animal: String in VillageResidents.HOMES:
		var data: Dictionary = VillageDialogue.CATALOG.ANIMALS[animal]
		_check(data.tasks.size() == 37, "Cada animal tiene textos para los 37 pedidos")
		for id: String in CombinationCatalog.targets():
			_check(data.tasks.has(id) and data.tasks[id].size() == 3, "Dos peticiones y un agradecimiento por combinación")
			if data.tasks.has(id):
				for line: String in data.tasks[id]:
					_check(line.length() <= 160 and (animal == "Áak" or not line.contains("caparazón")), "Texto breve y coherente con la especie")

func _plans() -> void:
	var seen := {}
	for world: int in [3, 4]:
		var content: ExerciseSet = load("res://data/exercises/world%d.tres" % world)
		var fingerprints := {}
		for seed_value: int in range(1, 129):
			var session := CombinationVariation.exercises(content, {}, seed_value, world)
			_check(not session.is_empty(), "El nivel admite combinaciones sin cambiar su número de rondas")
			if session.is_empty():
				continue
			fingerprints[str(session.ids)] = true
			var nouns := {}
			var qualities := {}
			var ids := {}
			for entry: ExerciseEntry in session.entries:
				var id := CombinationCatalog.key(entry.noun, entry.adjective)
				_check(CombinationCatalog.allowed(id) and not ids.has(id), "Las seis peticiones son válidas y distintas")
				ids[id] = true
				nouns[entry.noun] = true
				qualities[entry.adjective] = true
				if not entry.adjective.is_empty():
					seen[id] = true
			_check(qualities.size() == 5, "Se cubren todas las cualidades del capítulo sin alargarlo")
			if world == 4:
				_check(nouns.size() == 5, "Todos los alimentos aparecen en la práctica antes del recuerdo")
			var next := CombinationVariation.exercises(content, {"previous_variation": {"combination_plan": session.ids}}, seed_value, world)
			_check(next.ids != session.ids, "Repetir cambia alguna combinación incluso con la misma semilla")
		_check(fingerprints.size() > 30, "Las partidas reciben una variedad amplia de peticiones")
		_check(CombinationVariation.exercises(content, {"round": 7}, 16, world).is_empty(), "Un ejercicio antiguo conserva su contenido original")
	_check(seen.size() == 28, "Las 28 combinaciones pueden aparecer en los ejercicios")
	var village_seen := {}
	for seed_value: int in range(1, 257):
		var ids := CombinationVariation.needs(CombinationCatalog.stage(4), {}, 3, seed_value)
		var nouns := {}
		for id: String in ids:
			_check(not nouns.has(id.get_slice("|", 0)), "Una visita no repite el objeto entre sus tres destinatarios")
			nouns[id.get_slice("|", 0)] = true
			village_seen[id] = true
	_check(village_seen.size() == 37, "Los 37 pedidos tienen oportunidad de aparecer en visitas nuevas")

func _runtime() -> void:
	for world: int in [3, 4]:
		var key := "world%d_level1" % world
		var scene := await _scene(key, {"layout_seed": 251})
		var state: Dictionary = scene.get_checkpoint_state()
		_check(state.combination_plan.size() == 6 and scene.round_plan.size() == 12, "Seis peticiones, práctica y recuerdo")
		scene = await _resume(key)
		_check(scene.get_checkpoint_state().combination_plan == state.combination_plan and scene.get_checkpoint_state().combination_animals == state.combination_animals, "JSON conserva combinaciones y animales")
		for round_value: int in [0, 2, 6, 8]:
			scene.round_index = round_value
			scene._show_round()
			scene.mission_break.hide()
			var task: ExerciseEntry = scene._current_challenge()
			if world == 4 and round_value < 6:
				_check(scene.modifier_buttons[task.modifier].visible, "La cualidad correcta siempre queda disponible")
				_check(scene.modifier_buttons[""].visible, "Sin cualidad siempre permite retirar una elección")
				scene._select_food(task.food)
				scene._select_modifier(task.modifier)
				_check(scene.modifier_grid.get_children().filter(func(button: Button): return button.visible).size() == 4, "Cuatro opciones equilibradas, incluyendo la cualidad correcta")
			await _capture("combinaciones_mundo%d_ronda%d" % [world, round_value])
			if world == 4 and round_value == 2:
				root.size = Vector2i(640, 360)
				var layout := scene.get_node("ScreenLayout") as ScreenLayout
				layout.preview_compact = true
				layout.refresh()
				await process_frame
				await process_frame
				for button: Control in scene.modifier_grid.get_children():
					if button.is_visible_in_tree():
						_check(Rect2(0, 0, 1280, 720).encloses(button.get_global_rect()), "Las cualidades variables caben en móvil horizontal")
						_check(scene.choices_panel.get_global_rect().encloses(button.get_global_rect()), "Las cualidades no quedan debajo del panel de resultado en móvil")
				await _capture("combinaciones_mundo4_movil")
				root.size = Vector2i(1280, 720)
				layout.preview_compact = false
				layout.refresh()
		var legacy := await _scene(key, {"round": 7, "layout_seed": 251})
		_check(legacy.challenges[1].phrase == legacy.content.challenges[1].phrase, "No se reemplaza una respuesta pendiente de una partida anterior")
	for key: String in ["world2_explore1", "world3_explore1", "world2_mission1", "world3_mission1", "world4_mission1", "village_practice"]:
		var scene := await _scene(key, {"intro_done": true, "layout_seed": 817})
		var state: Dictionary = scene.get_checkpoint_state()
		_check(state.combination_tasks.size() == 3, "La visita guarda sus tres necesidades")
		scene = await _resume(key)
		_check(scene.get_checkpoint_state().combination_tasks == state.combination_tasks, "Las peticiones no cambian al reanudar")
		if scene.has_method("_prepare_encounters"):
			for encounter: VillageEncounter in scene.encounters:
				_check(encounter.get_configuration_issues().is_empty(), "El paseo siempre ofrece la solución del encargo nuevo")
		else:
			await _complete_delivery()
			_check(scene.delivered.size() == 3, "Los tres encargos variables se pueden crear, llevar y entregar")

func _portal_recap() -> void:
	for world: int in [3, 4]:
		var scene := await _scene("world%d_level1" % world, {"layout_seed": 251})
		manager.checkpoint(scene)
	var portal := await _scene("world5_level1", {"layout_seed": 871})
	var state: Dictionary = portal.get_checkpoint_state()
	_check(state.has("portal_pool_keys"), "El portal conserva el banco de combinaciones ya practicadas")
	for category: String in ["2", "3"]:
		var learned: Array = manager.scene_states["world%d_level1" % (int(category) + 1)].combination_plan
		for id: String in state.portal_pool_keys[category]:
			_check(id in learned, "El portal no exige una combinación nueva sin práctica previa")
	portal = await _resume("world5_level1")
	_check(portal._portal_pool_keys == state.portal_pool_keys, "El banco del portal no cambia al continuar")
