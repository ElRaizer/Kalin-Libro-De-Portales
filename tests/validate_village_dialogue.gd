extends "res://tests/validate_game_expansion.gd"


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://village_dialogue_validation.json")
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	_catalog_coverage()
	_greeting_banks()
	await _personalized_scenes()
	await _saved_conversations()
	await _completed_friends()
	await process_frame
	await process_frame
	if failures.is_empty():
		print(
			"OK: 444 pedidos personalizados, 1332 frases de encargo, 60 saludos, rotación y conversaciones guardadas."
		)
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _catalog_coverage() -> void:
	var targets: Dictionary = CombinationCatalog.targets()
	for key: String in [
		"world2_explore1",
		"world3_explore1",
		"world2_mission1",
		"world3_mission1",
		"world4_mission1"
	]:
		var scene: Node = load(GameContent.SCENE_PATHS[key]).instantiate()
		var tasks: Array = []
		if scene.has_method("_prepare_encounters"):
			for encounter: VillageEncounter in scene.encounters:
				tasks.append(encounter.task)
				if encounter.alternate_task:
					tasks.append(encounter.alternate_task)
		else:
			tasks.append_array(scene.tasks)
		for task: VillageTask in tasks:
			targets[VillageDialogue.task_key(task)] = true
		scene.free()
	_check(targets.size() == 37, "Se cubren las 28 combinaciones y nueve pedidos sin cualidad")
	var source: VillageTask = VillageTask.new()
	source.requester = "Áak"
	source.request = "Texto de autor con mi caparazón."
	source.success = "Texto original."
	for animal: String in VillageResidents.HOMES:
		var data: Dictionary = VillageDialogue.CATALOG.ANIMALS[animal]
		_check(
			data.tasks.size() == targets.size(), "Cada animal cubre todos los pedidos: " + animal
		)
		for key: String in targets:
			_check(data.tasks.has(key), "Existe una combinación explícita: %s / %s" % [animal, key])
			if not data.tasks.has(key):
				continue
			var bank: Array = data.tasks[key]
			_check(
				bank.size() == 3 and bank[0] != bank[1],
				"Hay dos peticiones y un agradecimiento por combinación"
			)
			for line: String in bank:
				_check(
					not line.is_empty() and line.length() <= 160,
					"Las frases son breves y completas: " + key
				)
				_check(
					animal == "Áak" or not line.to_lower().contains("caparazón"),
					"Sólo la tortuga habla de su caparazón"
				)
				_check(not line.contains("%s"), "No quedan marcadores de plantilla en el diálogo")
			var parts: PackedStringArray = key.split("|")
			source.item = parts[0]
			source.quality = parts[1]
			var task: VillageTask = source.duplicate() as VillageTask
			var variants: Dictionary = {}
			for seed: int in range(1, 20):
				VillageDialogue.personalize(task, animal, seed, "coverage")
				variants[task.request] = true
				_check(
					task.request in bank.slice(0, 2) and task.success == bank[2],
					"Se usa el banco del animal y pedido exactos"
				)
				_check(
					task.item == source.item and task.quality == source.quality,
					"Personalizar no cambia la respuesta del encargo"
				)
			_check(variants.size() == 2, "Ambas peticiones pueden aparecer en visitas distintas")
	_check(
		source.requester == "Áak" and source.request == "Texto de autor con mi caparazón.",
		"El recurso de autor queda intacto"
	)
	var future: VillageTask = source.duplicate() as VillageTask
	future.item = "ich"
	future.quality = "futuro"
	VillageDialogue.personalize(future, "Miis", 42, "future")
	_check(
		future.request.contains("Fruta") and not future.request.contains("caparazón"),
		"Un pedido futuro sin banco conserva su significado sin heredar anatomía ajena"
	)


func _greeting_banks() -> void:
	for animal: String in VillageResidents.HOMES:
		var dialogue: VillageDialogue = VillageDialogue.new()
		dialogue.restore({}, 100)
		var spot: ExplorationSpot = VillageResidents.SPOT.instantiate() as ExplorationSpot
		spot.set_meta("village_neighbour", true)
		spot.speaker = animal
		var seen: Dictionary = {}
		for index: int in range(5):
			dialogue.prepare(spot)
			var line: String = spot.lines[0]
			_check(not seen.has(line), "El saludo no se repite hasta agotar el banco: " + animal)
			seen[line] = true
			dialogue.prepare(spot)
			_check(spot.lines[0] == line, "Abrir o restaurar no consume otro saludo")
			dialogue.finish(spot)
		_check(seen.size() == 5, "Cada animal tiene cinco saludos propios")
		dialogue.restore({"greeting_visits": {animal: "dato inválido"}}, 100)
		_check(int(dialogue.greeting_visits.get(animal, 0)) == 0, "Se ignoran contadores inválidos")
		spot.free()
		dialogue.free()


func _personalized_scenes() -> void:
	var keys: Array = [
		"world2_explore1",
		"world3_explore1",
		"world2_mission1",
		"world3_mission1",
		"world4_mission1",
		"village_practice"
	]
	for key: String in keys:
		var state: Dictionary = {
			"intro_done": true, "layout_seed": 203, "residents": ["Miis", "Áak", "Kay"]
		}
		state.combination_tasks = (
			["mayak|", "k'áanche'|", "k'áan|"]
			if key.begins_with("world2")
			else ["mayak|nojoch", "k'áanche'|chich", "k'áan|mejen"]
		)
		if key.contains("explore"):
			state.encounter_plan = [1, 2, 4]
		else:
			state.task_indices = [0, 2, 4]
		var scene: Node = await _scene(key, state)
		var requests: Array[String] = []
		for index: int in range(3):
			var task: VillageTask = (
				scene.encounters[index].task
				if scene.has_method("_prepare_encounters")
				else scene.tasks[scene.task_indices[index]]
			)
			var bank: Array = VillageDialogue.CATALOG.ANIMALS[task.requester].tasks[
				VillageDialogue.task_key(task)
			]
			_check(
				task.request in bank.slice(0, 2) and task.success == bank[2],
				"Petición y agradecimiento personalizados también en " + key
			)
			requests.append(task.request)
		if key == "world3_explore1":
			var spot: ExplorationSpot = scene.get_node("Spots/Visit0") as ExplorationSpot
			scene._place_kalin(spot.position.x - 120)
			scene.camera.reset_smoothing()
			scene.open_spot(spot)
			_check(
				(
					scene.dialogue_text.text.contains("mesa grande")
					and not scene.dialogue_text.text.contains("caparazón")
				),
				"Regresión del gato sin caparazón y con su mesa grande"
			)
			scene.guide.stop()
			if scene._dialogue.text_tween:
				scene._dialogue.text_tween.kill()
			scene.dialogue_text.visible_ratio = 1.0
			await _capture("gato_mesa_grande")
			root.size = Vector2i(640, 360)
			scene.get_node("ScreenLayout").preview_compact = true
			scene.get_node("ScreenLayout").refresh()
			await process_frame
			await _capture("gato_mesa_grande_movil")
			root.size = Vector2i(1280, 720)
			_close_lines(scene)
			if scene._choice_index >= 0:
				scene._close_choices()
		scene = await _resume(key)
		for index: int in range(3):
			var task: VillageTask = (
				scene.encounters[index].task
				if scene.has_method("_prepare_encounters")
				else scene.tasks[scene.task_indices[index]]
			)
			_check(
				task.request == requests[index],
				"Consultar, guardar y reanudar conserva el texto del pedido"
			)


func _completed_friends() -> void:
	for key: String in ["world3_explore1", "world3_mission1"]:
		var state: Dictionary = {
			"intro_done": true, "layout_seed": 203, "residents": ["Miis", "Áak", "Kay"]
		}
		state.combination_tasks = ["mayak|nojoch", "k'áanche'|chich", "k'áan|mejen"]
		var spot_name: String = "Spots/Visit0" if key.contains("explore") else "Spots/Recipient0"
		if key.contains("explore"):
			state.encounter_plan = [1, 2, 4]
			state.solved = [0]
		else:
			state.task_indices = [0, 2, 4]
			state.mission_met = [0]
			state.delivered = [0]
		var scene: Node = await _scene(key, state)
		var spot: ExplorationSpot = scene.get_node(spot_name) as ExplorationSpot
		scene._place_kalin(spot.position.x)
		scene.open_spot(spot)
		var lines: Array = spot.lines.duplicate()
		_check(
			lines.size() == 2 and not str(lines).contains("caparazón"),
			"Un amigo ya ayudado saluda y recuerda su resultado con su propia voz"
		)
		scene = await _resume(key)
		_check(
			scene.is_dialogue_open() and scene._dialogue.lines == lines,
			"También se restaura la conversación con un destinatario ya ayudado"
		)
		_close_lines(scene)
		spot = scene.get_node(spot_name)
		scene._place_kalin(spot.position.x)
		scene.open_spot(spot)
		_check(
			spot.lines[0] != lines[0] and spot.lines[1] == lines[1],
			"El saludo del amigo ayudado cambia sin inventar otro pedido"
		)
		_close_lines(scene)


func _saved_conversations() -> void:
	for key: String in ["world2_explore1", "world4_mission1", "world5_farewell"]:
		var scene: Node = await _scene(key, {"intro_done": true, "layout_seed": 303})
		for visit: int in range(2):
			var spot: ExplorationSpot = scene.get_node("Spots/Neighbour0") as ExplorationSpot
			scene._place_kalin(spot.position.x)
			scene.open_spot(spot)
			var line: String = spot.lines[0]
			var before: Dictionary = scene.get_node("VillageDialogue").greeting_visits.duplicate()
			scene = await _resume(key)
			_check(
				scene.is_dialogue_open() and scene.dialogue_text.text == line,
				"El saludo abierto se restaura, incluso en la segunda visita"
			)
			_check(
				scene.get_node("VillageDialogue").greeting_visits == before,
				"Restaurar no adelanta la rotación"
			)
			_close_lines(scene)
			spot = scene.get_node("Spots/Neighbour0")
			scene._place_kalin(spot.position.x)
			scene.open_spot(spot)
			_check(
				spot.lines[0] != line,
				"El siguiente saludo es diferente después de terminar el anterior"
			)
			_close_lines(scene)
