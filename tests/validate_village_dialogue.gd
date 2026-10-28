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
	_after_help_banks()
	await _personalized_scenes()
	await _saved_conversations()
	await _completed_friends()
	await _conversation_layout()
	await process_frame
	await process_frame
	if failures.is_empty():
		print(
			"OK: encargos personalizados, saludos y comentarios tras ayudar, rotación y conversaciones guardadas."
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
			var bank: Dictionary = data.tasks[key]
			var requests: Array[String] = []
			requests.assign(bank.requests)
			var thanks: Array[String] = []
			thanks.assign(bank.thanks)
			_check(
				requests.size() == 3 and thanks.size() == 2,
				"Hay tres peticiones y dos agradecimientos por combinación"
			)
			var lines: Array[String] = requests.duplicate()
			lines.append_array(thanks)
			var unique: Dictionary = {}
			for line: String in lines:
				_check(not unique.has(line), "Cada variante aporta un texto diferente: " + key)
				unique[line] = true
				_check(
					not line.is_empty() and line.length() <= 160,
					"Las frases son breves y completas: " + key
				)
				_check(
					animal == "Áak" or not line.to_lower().contains("caparazón"),
					"Sólo la tortuga habla de su caparazón"
				)
				_check(not line.contains("%s"), "No quedan marcadores de plantilla en el diálogo")
			_check(
				(
					requests[2].contains(VillageDialogue.TARGETS[key])
					and thanks[1].contains(VillageDialogue.TARGETS[key])
				),
				"Las variantes nuevas conservan explícitos el objeto y la cualidad"
			)
			var parts: PackedStringArray = key.split("|")
			source.item = parts[0]
			source.quality = parts[1]
			var task: VillageTask = source.duplicate() as VillageTask
			var variants: Dictionary = {}
			var outcomes: Dictionary = {}
			var pairs: Dictionary = {}
			for seed: int in range(1, 65):
				VillageDialogue.personalize(task, animal, seed, "coverage")
				variants[task.request] = true
				outcomes[task.success] = true
				pairs[task.request + "|" + task.success] = true
				_check(
					(
						task.request in requests
						and task.success in thanks
						and task.requester == animal
					),
					"Se usa el banco del animal y pedido exactos"
				)
				var request: String = task.request
				var success: String = task.success
				VillageDialogue.personalize(task, animal, seed, "coverage")
				_check(
					task.request == request and task.success == success,
					"Consultar el mismo encargo no cambia la petición ni el agradecimiento"
				)
				_check(
					task.item == source.item and task.quality == source.quality,
					"Personalizar no cambia la respuesta del encargo"
				)
			_check(variants.size() == 3, "Las tres peticiones aparecen en visitas distintas")
			_check(outcomes.size() == 2, "Los dos agradecimientos aparecen en visitas distintas")
			_check(
				pairs.size() == 6, "Las peticiones y agradecimientos se seleccionan por separado"
			)
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
		var bank: Array = VillageDialogue.CATALOG.ANIMALS[animal].greetings
		_check(bank.size() >= 15, "Cada animal conserva sus saludos y suma diez nuevos")
		var seen: Dictionary = {}
		for index: int in range(bank.size()):
			dialogue.prepare(spot)
			_check(spot.lines.size() == 1, "Un vecino no habla de un encargo que no recibió")
			var line: String = spot.lines[0]
			_check(line in bank and line.length() <= 160, "El saludo es propio y breve")
			_check(not seen.has(line), "El saludo no se repite hasta agotar el banco: " + animal)
			seen[line] = true
			dialogue.prepare(spot)
			_check(spot.lines[0] == line, "Abrir o restaurar no consume otro saludo")
			dialogue.finish(spot)
		_check(seen.size() == bank.size(), "Se recorren todos los saludos del habitante")
		var pending: ExplorationSpot = VillageResidents.SPOT.instantiate() as ExplorationSpot
		pending.speaker = animal
		pending.lines.assign(["Necesito una mesa."])
		dialogue.prepare(pending)
		dialogue.finish(pending)
		_check(
			pending.lines == ["Necesito una mesa."],
			"Un encargo pendiente conserva su petición y no muestra comentarios tras ayudar"
		)
		pending.free()
		dialogue.restore({"greeting_visits": {animal: "dato inválido"}}, 100)
		_check(int(dialogue.greeting_visits.get(animal, 0)) == 0, "Se ignoran contadores inválidos")
		spot.free()
		dialogue.free()


func _after_help_banks() -> void:
	for animal: String in VillageResidents.HOMES:
		var data: Dictionary = VillageDialogue.CATALOG.ANIMALS[animal]
		var bank: Array = data.after_help
		_check(bank.size() >= 10, "Cada habitante tiene diez comentarios tras ayudar")
		for line: String in bank:
			_check(
				not line.strip_edges().is_empty() and line.length() <= 160,
				"Los comentarios tras ayudar son breves y completos"
			)
			_check(
				animal == "Áak" or not line.to_lower().contains("caparazón"),
				"Los comentarios conservan la voz y anatomía del habitante"
			)
		var dialogue: VillageDialogue = VillageDialogue.new()
		dialogue.restore({}, 100)
		var spot: ExplorationSpot = VillageResidents.SPOT.instantiate() as ExplorationSpot
		spot.speaker = animal
		spot.set_meta("village_success", "El encargo ya está resuelto.")
		var recent: Array[String] = []
		var greetings: Array[String] = []
		# Cruza tanto el límite de los saludos como el ciclo completo de ambos bancos.
		for index: int in range(data.greetings.size() * bank.size() + 1):
			dialogue.prepare(spot)
			_check(spot.lines.size() == 2, "La conversación mantiene sólo dos globos")
			var line: String = spot.lines[1]
			_check(line in bank, "El comentario pertenece al animal ayudado")
			_check(not recent.has(line), "No se repite un comentario antes de agotar su banco")
			recent.append(line)
			if recent.size() == bank.size():
				recent.pop_front()
			_check(
				not greetings.has(spot.lines[0]),
				"El saludo también mantiene su ciclo independiente"
			)
			greetings.append(spot.lines[0])
			if greetings.size() == data.greetings.size():
				greetings.pop_front()
			var lines: Array[String] = spot.lines.duplicate()
			var snapshot: Dictionary = dialogue.checkpoint_extension()
			var before: Dictionary = snapshot.duplicate(true)
			dialogue.restore(snapshot, 100)
			dialogue.prepare(spot)
			_check(spot.lines == lines, "Restaurar conserva las dos frases sin avanzar el contador")
			dialogue.finish(spot)
			_check(snapshot == before, "La instantánea no cambia al terminar la conversación")
		spot.free()
		dialogue.free()


func _personalized_scenes() -> void:
	var keys: Array = [
		"world2_explore1",
		"world3_explore1",
		"world2_mission1",
		"world3_mission1",
		"world4_mission1"
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
		var thanks: Array[String] = []
		for index: int in range(3):
			var task: VillageTask = (
				scene.encounters[index].task
				if scene.has_method("_prepare_encounters")
				else scene.tasks[scene.task_indices[index]]
			)
			var bank: Dictionary = VillageDialogue.CATALOG.ANIMALS[task.requester].tasks[
				VillageDialogue.task_key(task)
			]
			_check(
				task.request in bank.requests and task.success in bank.thanks,
				"Petición y agradecimiento personalizados también en " + key
			)
			requests.append(task.request)
			thanks.append(task.success)
		if key == "world3_explore1":
			# La revisión editorial inspecciona la traducción consultada explícitamente.
			scene.translated.append(0)
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
				task.request == requests[index] and task.success == thanks[index],
				"Consultar, guardar y reanudar conserva la petición y el agradecimiento"
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
		var magic_points: int = manager.session.magic_points
		var learning: Dictionary = manager.session.learning_progress.duplicate(true)
		_approach_spot(scene, spot)
		scene.open_spot(spot)
		var lines: Array = spot.lines.duplicate()
		_check(
			lines.size() == 2 and not str(lines).contains("caparazón"),
			"Un amigo ya ayudado saluda y conversa con su propia voz"
		)
		var after_help: Array = VillageDialogue.CATALOG.ANIMALS[spot.speaker].after_help
		_check(lines[1] in after_help, "Se muestra un comentario posterior y no otro encargo")
		# Guardar también desde el segundo globo, después de terminar su animación de texto.
		if scene._dialogue.text_tween and scene._dialogue.text_tween.is_valid():
			scene._dialogue.text_tween.kill()
		scene.advance_dialogue()
		scene = await _resume(key)
		_check(
			(
				scene.is_dialogue_open()
				and scene._dialogue.lines == lines
				and scene._dialogue.line_index == 1
			),
			"Se restaura el segundo globo de la conversación con el destinatario ayudado"
		)
		_close_lines(scene)
		spot = scene.get_node(spot_name)
		_approach_spot(scene, spot)
		scene.open_spot(spot)
		_check(
			spot.lines[0] != lines[0] and spot.lines[1] != lines[1],
			"Cambian tanto el saludo como el comentario sin inventar otro pedido"
		)
		_close_lines(scene)
		_check(
			(
				manager.session.magic_points == magic_points
				and manager.session.learning_progress == learning
			),
			"Volver a conversar y reanudar no acredita de nuevo el encargo"
		)


func _conversation_layout() -> void:
	var scene: Node = await _scene("world3_explore1", {"intro_done": true, "layout_seed": 203})
	scene.guide.stop()
	var layout: ScreenLayout = scene.get_node("ScreenLayout") as ScreenLayout
	var label: RichTextLabel = scene.dialogue_text
	for compact: bool in [false, true]:
		root.size = Vector2i(640, 360) if compact else Vector2i(1280, 720)
		layout.preview_compact = compact
		layout.refresh()
		await process_frame
		var longest: String = ""
		var speaker: String = ""
		for animal: String in VillageResidents.HOMES:
			var data: Dictionary = VillageDialogue.CATALOG.ANIMALS[animal]
			var lines: Array[String] = []
			for situation: String in ["greetings", "after_help"]:
				lines.append_array(data[situation])
			for key: String in data.tasks:
				for situation: String in ["requests", "thanks"]:
					lines.append_array(data.tasks[key][situation])
			for line: String in lines:
				label.text = line
				await process_frame
				_check(
					label.get_content_height() <= label.size.y,
					"El texto cabe en %s: %s" % ["compacto" if compact else "escritorio", line]
				)
				if line.length() > longest.length():
					longest = line
					speaker = animal
		var preview_lines: Array[String] = [longest]
		scene._start_dialogue(speaker, preview_lines, false)
		if scene._dialogue.text_tween and scene._dialogue.text_tween.is_valid():
			scene._dialogue.text_tween.kill()
		label.visible_ratio = 1.0
		await _capture("conversacion_compacta" if compact else "conversacion_escritorio")
		_close_lines(scene)
	root.size = Vector2i(1280, 720)
	layout.preview_compact = false
	layout.refresh()


func _saved_conversations() -> void:
	for key: String in ["world2_explore1", "world4_mission1", "world5_farewell"]:
		var scene: Node = await _scene(key, {"intro_done": true, "layout_seed": 303})
		for visit: int in range(2):
			var spot: ExplorationSpot = scene.get_node("Spots/Neighbour0") as ExplorationSpot
			_approach_spot(scene, spot)
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
			_approach_spot(scene, spot)
			scene.open_spot(spot)
			_check(
				spot.lines[0] != line,
				"El siguiente saludo es diferente después de terminar el anterior"
			)
			_close_lines(scene)
