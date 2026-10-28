extends ProjectTest

var manager: Node
var capture_directory: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	manager.use_save_repository(repository_for("village_roaming"))
	manager.reset_save()
	for world: int in [2, 3, 4]:
		var tasks: Array[String] = ["mayak|", "k'áanche'|", "janal|"]
		if world == 3:
			tasks.assign(["mayak|chich", "k'áan|mejen", "lak|Jats'uts"])
		elif world == 4:
			tasks.assign(["ja'|", "ja'as|", "ich|nojoch"])
		var key: String = "world%d_mission1" % world
		manager.session.scene_states[key] = {
			"intro_done": true,
			"layout_seed": 349,
			"residents": ["Ma'ax", "Miis", "Kay"],
			"combination_tasks": tasks,
			"mission_met": [0, 1, 2],
			"delivered": [0, 1, 2],
			"gathering_seen": true
		}
		change_scene_to_file(GameContent.SCENE_PATHS[key])
		await scene_changed
		await process_frame
		var scene: Node = current_scene
		await create_timer(0.7).timeout
		scene.guide.stop()
		check(scene.free_roam and scene._roaming != null, "La misión usa suelo en dos ejes")
		check(
			not scene.kalin_sprite.visible, "No superpone el recorte completo al cuerpo articulado"
		)
		scene.set_process(false)
		scene._roaming.target(Vector2(350, 480), scene.navigation_obstacles())
		for frame: int in range(150):
			scene.walk(0, 0.02)
		check(
			scene.kalin.position.distance_to(Vector2(350, 480)) < 8,
			"Camina en ambos ejes hacia un destino"
		)
		var checkpoint: Dictionary = scene.get_checkpoint_state()
		manager.session.scene_states[key] = JSON.parse_string(JSON.stringify(checkpoint))
		change_scene_to_file(GameContent.SCENE_PATHS[key])
		await scene_changed
		await process_frame
		scene = current_scene
		await create_timer(0.7).timeout
		scene.guide.stop()
		check(absf(scene.kalin.position.y - 480) < 8, "Reanudar conserva la profundidad del suelo")
		scene.toggle_journal()
		var before: Vector2 = scene.kalin.position
		scene.walk(1, 0.2)
		check(scene.kalin.position == before, "Consultar lugares detiene el movimiento")
		scene.toggle_journal()
		for index: int in range(3):
			var spot: Node2D = scene.get_node("Spots/Recipient%d" % index)
			scene._place_kalin(spot.position.x - 160)
			scene.camera.reset_smoothing()
			await _capture("mision_%d_grupo_%d" % [world, index])
		root.size = Vector2i(640, 360)
		await process_frame
		await _capture("mision_%d_compacto" % world)
		root.size = Vector2i(1280, 720)
	var floor_bounds: Rect2 = Rect2(120, 420, 2280, 220)
	var obstacles: Array[Rect2] = [Rect2(520, 525, 360, 50)]
	var route: PackedVector2Array = VillageGround.route_with_obstacles(
		Vector2(400, 560), Vector2(980, 560), floor_bounds, obstacles
	)
	check(not route.is_empty(), "Encuentra un paso alrededor del mobiliario")
	for point: Vector2 in route:
		check(
			not VillageGround.blocked_by_obstacles(point, floor_bounds, obstacles),
			"La ruta no atraviesa apoyos"
		)
	finish("Marcha, profundidad, colisiones y continuación de las misiones")


func _capture(name: String) -> void:
	await process_frame
	await process_frame
	if capture_directory.is_empty():
		return
	await RenderingServer.frame_post_draw
	check(
		root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK,
		"Captura de " + name
	)
