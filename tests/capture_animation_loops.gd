## Captura fases y fotogramas del mismo bucle que se usa en las historias.
## -- [directorio] [--frames] [--small]
extends SceneTree

var output: String = "res://.ui-review/animation-loops"
var manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(path))


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	output = ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output)
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		output.path_join("capture_progress.json")
	)
	manager.session.scene_states.clear()
	var selected: PackedStringArray = PackedStringArray()
	for arg: String in args:
		if arg.begins_with("--only="):
			selected = arg.get_slice("=", 1).split(",")
	for entry: Array in [
		["world1_story1", "camino"],
		["world1_story5", "casa"],
		["world2_story1", "tamano"],
		["world3_story1", "hambre"],
		["world4_story1", "portal"]
	]:
		if not selected.is_empty() and entry[1] not in selected:
			continue
		change_scene_to_file(GameContent.SCENE_PATHS[entry[0]])
		await scene_changed
		while current_scene.current_beat().kind != StoryBeat.Kind.EXPLORAR:
			current_scene._next_beat()
		current_scene._complete_text()
		current_scene.guide.stop()
		current_scene.auto_timer.stop()
		current_scene._animator._kalin_idle_tween.kill()
		current_scene.vignette.set_process(false)
		for effect: Node in current_scene.effects_root.get_children():
			if effect is CPUParticles2D:
				effect.visible = false
		await create_timer(0.7).timeout
		var home: Vector2 = current_scene._animator._kalin_home
		for phase: float in [0.0, 0.18, 0.47, 0.63, 0.9, 1.0]:
			current_scene.vignette.seek_cycle(phase * 7.2)
			current_scene.kalin.position = home + Vector2(0, -3.0 * (1.0 - cos(phase * TAU * 3)))
			await _shot("%s_%03d.png" % [entry[1], roundi(phase * 100)])
		if args.has("--frames"):
			DirAccess.make_dir_recursive_absolute(output.path_join(entry[1]))
			for frame: int in range(144):
				var phase: float = frame / 144.0
				current_scene.vignette.seek_cycle(phase * 7.2)
				current_scene.kalin.position = (
					home + Vector2(0, -3.0 * (1.0 - cos(phase * TAU * 3)))
				)
				await _shot("%s/%03d.png" % [entry[1], frame])
	# La celebración usa también el mismo ciclo, con el animal y objeto ganados.
	change_scene_to_file(GameContent.SCENE_PATHS.world3_level1)
	await scene_changed
	await process_frame
	current_scene.round_index = 3
	current_scene._show_round()
	current_scene.mission_break.vignette.set_process(false)
	for phase: float in [0.0, 0.47, 1.0]:
		current_scene.mission_break.vignette.seek_cycle(phase * 7.2)
		await _shot("regalo_%03d.png" % roundi(phase * 100))
	print("Capturas de animaciones: " + output)
	quit()
