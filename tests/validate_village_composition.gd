## Atlas de los 444 casos de animal y pedido; capturar sin --headless.
extends "res://tests/validate_game_expansion.gd"

const ART = preload("res://scenes/components/MeaningIllustration.tscn")
var _atlas_only := false

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
		_atlas_only = _atlas_only or arg == "--atlas-only"
	manager = root.get_node("GameManager")
	manager._save_repository = SaveRepository.new("user://village_composition_validation.json")
	manager.reset_save()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	await _atlas()
	if not _atlas_only:
		await _world_scenes()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("OK: atlas de 444 composiciones de animales y encargos.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _atlas() -> void:
	var scene := await _scene("main_menu")
	scene.hide()
	root.size = Vector2i(1280, 720)
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	var page := Node2D.new()
	layer.add_child(page)
	var target_index := 0
	for key: String in VillageDialogue.TARGETS:
		for child: Node in page.get_children():
			page.remove_child(child)
			child.queue_free()
		var background := ColorRect.new()
		background.color = Color("f7efdc")
		background.size = Vector2(1280, 720)
		page.add_child(background)
		var heading := Label.new()
		heading.text = "Resultado: " + str(VillageDialogue.TARGETS[key])
		heading.position = Vector2(24, 5)
		heading.add_theme_color_override("font_color", Color("214f45"))
		heading.add_theme_font_size_override("font_size", 23)
		page.add_child(heading)
		var index := 0
		for animal: String in VillageResidents.HOMES:
			var host := Node2D.new()
			host.position = Vector2((index % 4) * 320, 40 + floori(index / 4.0) * 224)
			host.position += Vector2(24, 22)
			host.scale = Vector2(0.82, 0.82)
			page.add_child(host)
			var floor_line := ColorRect.new()
			floor_line.color = Color("cbd7ae")
			floor_line.position = Vector2(18, 184)
			floor_line.size = Vector2(284, 5)
			host.add_child(floor_line)
			var spot := VillageResidents.SPOT.instantiate() as ExplorationSpot
			spot.speaker = animal
			spot.lines.assign([animal])
			spot.spot_texture = manager.get_visual_expression(animal, "reaccion_feliz")
			spot.sprite_offset = Vector2(0, -61)
			spot.sprite_scale = Vector2.ONE
			spot.position = Vector2(160, 186)
			host.add_child(spot)
			spot.mark_examined()
			spot.get_node("Brillo").emitting = false
			var results := Node2D.new()
			results.z_index = 1
			host.add_child(results)
			var art := ART.instantiate() as MeaningIllustration
			art.size = Vector2(180, 130)
			art.position = spot.position + Vector2(-90, -125)
			results.add_child(art)
			var parts := key.split("|")
			art.show_meaning(parts[0], parts[1])
			VillageUseMotion.attach(spot.sprite, art, parts[0])
			var motion := art.get_node("UseMotion") as VillageUseMotion
			motion.set_process(false)
			motion._pose(0)
			if not _atlas_only:
				_check_composition(spot, art, motion)
			var name_label := Label.new()
			name_label.text = animal
			name_label.position = Vector2(16, 194)
			name_label.add_theme_color_override("font_color", Color("214f45"))
			name_label.add_theme_font_size_override("font_size", 19)
			host.add_child(name_label)
			index += 1
		await _capture("%02d_%s" % [target_index, key.get_slice("|", 0).replace("'", "").replace("á", "a")])
		target_index += 1
	layer.queue_free()

func _z(node: CanvasItem) -> int:
	var value := node.z_index
	var parent := node.get_parent() as CanvasItem
	return value + _z(parent) if parent and node.z_as_relative else value

func _check_composition(spot: ExplorationSpot, art: MeaningIllustration, motion: VillageUseMotion) -> void:
	var before := art.picture_rect()
	for wave: float in [-1.0, 0.0, 1.0]:
		motion._pose(wave)
		_check(art.picture_rect() == before and art.scale == Vector2.ONE, "El objeto conserva su tamaño durante la animación")
		_check(spot.sprite.position.is_finite() and art.position.is_finite(), "La composición conserva coordenadas válidas")
		var body := spot.sprite.get_global_transform() * spot.sprite.get_rect()
		var furniture := art.get_global_transform() * art.picture_rect()
		if art.word == "k'áanche'":
			_check(_z(spot.sprite) > _z(art.picture), "El animal queda delante del respaldo y las patas de la silla")
		if art.word == "k'áan" and spot.speaker != "Kay":
			_check(_z(art.picture) < _z(spot.sprite) and _z(spot.sprite) < _z(art.world_front), "El ocupante queda entre los postes y el tejido de la hamaca")
			_check(furniture.grow(3).encloses(body), "Cada animal cabe en la hamaca durante todo el balanceo")
		if art.word in ["mayak", "lak", "janal", "ja'", "ja'as", "ich", "K'úum"] or spot.speaker == "Kay":
			var face := Rect2(spot.sprite.get_rect().position + spot.sprite.texture.get_size() * Vector2(0.22, 0.10), spot.sprite.texture.get_size() * Vector2(0.6, 0.45))
			var face_world := spot.sprite.get_global_transform() * face
			_check(not face_world.intersects(furniture), "El objeto no tapa la cara del animal")
		if spot.speaker == "Kay":
			_check(motion.pond.visible and is_zero_approx(spot.sprite.rotation), "Kay permanece junto al agua sin adoptar una pose terrestre")
		if art.word in ["lak", "janal", "ja'", "ja'as", "ich", "K'úum"]:
			_check(art.world_mat.visible, "Los platos, alimentos y agua tienen un apoyo visible")
		_check(not art.reference.visible, "No quedan copias de comparación en el escenario")
	if art.quality == "Jats'uts":
		_check(art.picture.texture == VillageUseArt.object_texture(art.word, art.quality), "La versión bonita conserva sus adornos")
	if art.quality == "ki'":
		_check(art.quality_badge.visible, "La comida deliciosa conserva su aroma")
	motion._pose(0)

func _world_scenes() -> void:
	for key: String in ["world2_explore1", "world3_explore1", "world2_mission1", "world3_mission1", "world4_mission1", "village_practice"]:
		var state := {"intro_done": true, "layout_seed": 89, "residents": ["Miis", "Áak", "Kay"]}
		var walk := key.contains("explore")
		if walk:
			state.encounter_plan = [1, 2, 4]
			state.solved = [0, 1, 2]
		else:
			state.task_indices = [1, 2, 4]
			state.delivered = [0, 1, 2]
			state.mission_met = [0, 1, 2]
		var scene := await _scene(key, state)
		await create_timer(0.65).timeout
		var spot_path := "Spots/Visit0" if walk else "Spots/Recipient0"
		var spot := scene.get_node(spot_path) as ExplorationSpot
		var art_path := "Results/Item0" if walk else "Delivered/Item0"
		var art := scene.get_node(art_path) as MeaningIllustration
		var motion := art.get_node("UseMotion") as VillageUseMotion
		_check(_z(scene.kalin) > _z(art.world_front) and _z(scene.kalin) > _z(spot.sprite), "Kalin pasa delante del conjunto en " + key)
		if not walk:
			_check(not scene.get_node("UI/CarriedLabel").visible, "La instrucción de transporte no tapa los resultados cuando no se lleva un objeto")
		scene._place_kalin(spot.position.x - 190)
		scene.camera.reset_smoothing()
		scene.guide.stop()
		await _capture("aldea_" + key)
		var pose := spot.sprite.position
		scene = await _resume(key)
		spot = scene.get_node(spot_path)
		art = scene.get_node(art_path)
		motion = art.get_node("UseMotion")
		motion._pose(0)
		_check(spot.sprite.position.distance_to(pose) < 3, "Reanudar conserva la composición de " + key)
		if key == "world3_mission1":
			for physical_size: Vector2i in [Vector2i(1920, 1080), Vector2i(640, 360)]:
				root.size = physical_size
				scene.get_node("ScreenLayout").preview_compact = physical_size.x < 1024
				scene.get_node("ScreenLayout").refresh()
				await process_frame
				await _capture("silla_en_aldea_%d" % physical_size.x)
			root.size = Vector2i(1280, 720)
