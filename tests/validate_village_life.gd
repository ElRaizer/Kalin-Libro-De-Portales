## Composición sin pistas, ajuste físico del mobiliario y habitantes persistentes.
extends "res://tests/validate_game_expansion.gd"

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://village_life_validation.json")
	manager.reset_save()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	await _workspace()
	await _physical_objects()
	await _residents()
	await _home_gallery()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("OK: composición sin respuestas, mobiliario ajustado, 12 habitantes, casas propias y persistencia.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _workspace() -> void:
	for key: String in ["world3_level1", "world4_level1"]:
		var scene := await _scene(key)
		var count: int = scene.challenges.size()
		scene = await _scene(key, {"round": count, "layout_seed": 166})
		scene.mission_break.hide()
		var panel: RecallPanel = scene.recall
		var workspace := panel.get_node("Margin/Content/Workspace") as Control
		_check(workspace.visible and not scene._attempt.supported, "El espacio de composición aparece sin acreditar apoyo")
		_check(workspace.get_node("First").text == "…", "El espacio vacío no muestra la palabra esperada")
		panel.first.text = "ensayo"
		panel.first.text_changed.emit("ensayo")
		_check(workspace.get_node("First").text == "ensayo" and not scene._attempt.supported, "La mesa sólo refleja lo escrito, sin validar ni dar pistas")
		workspace.get_node("First").pressed.emit()
		_check(panel.first.has_focus(), "La tablilla permite volver a editar su palabra")
		scene = await _resume(key)
		panel = scene.recall
		workspace = panel.get_node("Margin/Content/Workspace")
		_check(workspace.get_node("First").text == "ensayo", "El borrador vuelve a la mesa al reanudar")
		for physical_size: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(640, 360)]:
			root.size = physical_size
			scene.get_node("ScreenLayout").preview_compact = physical_size.x <= 1024
			scene.get_node("ScreenLayout").refresh()
			await process_frame
			await process_frame
			_check(Rect2(0, 0, 1280, 720).encloses(panel.get_global_rect()), "La mesa y los campos caben en pantalla")
			await _capture("mesa_%s_%d" % [key, physical_size.x])
		panel.advance_support()
		panel.advance_support()
		_check(not workspace.visible, "El modo de bloques conserva su espacio propio")
	root.size = Vector2i(1280, 720)

func _physical_objects() -> void:
	var scene := await _scene("world3_mission1", {"intro_done": true})
	var spot := scene.get_node("Spots/Recipient0") as ExplorationSpot
	var result := scene.get_node("Delivered/Item0") as MeaningIllustration
	result.show()
	for word: String in VillageResidents.HOMES:
		if word in GameContent.FUTURE_VOCABULARY:
			continue
		spot.sprite.texture = manager.get_visual_texture(word)
		spot.speaker = word
		for quality: String in ["mejen", "nojoch"]:
			result.show_meaning("k'áan", quality)
			VillageUseMotion.attach(spot.sprite, result, "k'áan")
			var motion := result.get_node("UseMotion") as VillageUseMotion
			motion._pose(0)
			_check(not result.reference.visible and not result.quality_badge.visible, "Un objeto físico no conserva la copia de comparación")
			var bounds: Rect2 = spot.sprite.get_global_transform() * spot.sprite.get_rect()
			var furniture: Rect2 = result.get_global_transform() * result.picture_rect()
			if word == "Kay":
				_check(motion.pond.visible and not bounds.intersects(furniture), "Kay recibe el mueble para sus visitas junto al agua")
			else:
				_check(furniture.grow(2).encloses(bounds), "El ocupante cabe en la hamaca %s: %s" % [quality, word])
			result.celebrate()
			_check(result.scale == Vector2.ONE, "La celebración no separa al animal del mueble")
	var saved := {"intro_done": true, "task_indices": [0, 2, 4], "mission_met": [0, 1, 2], "delivered": [0, 1, 2], "residents": ["Báalam", "Miis", "Kay"], "layout_seed": 89}
	scene = await _scene("world3_mission1", saved)
	scene._place_kalin(scene.get_node("Spots/Recipient1").position.x - 170)
	scene.camera.reset_smoothing()
	await _capture("hamaca_pequena_ajustada")

func _residents() -> void:
	var seen := {}
	var originals: Array[String] = ["Miis", "Peek'", "Kaax"]
	_check(VillageResidents.select({"encounter_plan": [0, 2, 4]}, 91, originals) == originals, "Un paseo anterior conserva los dueños de sus peticiones")
	_check(VillageResidents.select({"task_indices": [0, 2, 4]}, 91, originals) == originals, "Una misión anterior conserva los destinatarios conocidos")
	for seed_value: int in range(1, 65):
		var cast := VillageResidents.select({}, seed_value, originals)
		_check(cast.size() == 3 and cast[0] != cast[1] and cast[1] != cast[2] and cast[0] != cast[2], "No se repiten vecinos en una visita")
		for word: String in cast:
			seen[word] = true
	_check(seen.size() == 12 and "T'uut'" not in seen, "Los doce animales presentados pueden recibir encargos; el vocabulario futuro espera su capítulo")
	for key: String in ["world2_explore1", "world3_explore1", "world2_mission1", "world3_mission1", "world4_mission1", "village_practice"]:
		var scene := await _scene(key, {"intro_done": true, "layout_seed": 203})
		var cast: Array = scene.get_checkpoint_state().residents.duplicate()
		_check(scene.get_node("VillageHomes").get_child_count() == 6, "Hay tres casas de destinatarios y tres vecinos adicionales")
		_check(scene.get_node("Spots/Neighbour0") is ExplorationSpot, "Los vecinos del camino permiten conversar")
		for index: int in range(3):
			_check(scene.get_node("VillageHomes").get_child(index).get_meta("resident") == cast[index], "La casa corresponde al animal que la habita")
		scene = await _resume(key)
		_check(scene.get_checkpoint_state().residents == cast, "El reparto no cambia al reanudar")
		var neighbour := scene.get_node("Spots/Neighbour0") as ExplorationSpot
		scene._place_kalin(neighbour.position.x)
		scene.open_spot(neighbour)
		manager.checkpoint(scene)
		scene = await _resume(key)
		_check(scene.is_dialogue_open() and scene._active_spot.name == &"Neighbour0", "Una conversación con un vecino se restaura desde JSON")
		_close_lines(scene)
		scene._place_kalin(scene.get_node("Spots/Neighbour1").position.x - 130)
		scene.camera.reset_smoothing()
		await _capture("aldea_" + key)

func _home_gallery() -> void:
	if capture_folder.is_empty():
		return
	await _scene("main_menu")
	var gallery := CanvasLayer.new()
	root.add_child(gallery)
	var background := ColorRect.new()
	background.color = Color("f4ecd4")
	background.size = Vector2(1280, 720)
	gallery.add_child(background)
	var index := 0
	for word: String in VillageResidents.HOMES:
		if word in GameContent.FUTURE_VOCABULARY:
			continue
		var x := 12 + (index % 5) * 252
		var y := 8 + floori(index / 5.0) * 230
		var art := Sprite2D.new()
		art.texture = VillageResidents.HOMES[word]
		art.centered = false
		art.position = Vector2(x + 15, y)
		art.scale = Vector2(0.58, 0.58)
		gallery.add_child(art)
		var name_label := Label.new()
		name_label.text = word
		name_label.position = Vector2(x + 40, y + 204)
		name_label.add_theme_color_override("font_color", Color("324e40"))
		name_label.add_theme_font_size_override("font_size", 20)
		gallery.add_child(name_label)
		index += 1
	await _capture("casas_de_los_animales")
	gallery.queue_free()
