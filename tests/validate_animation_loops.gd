## Continuidad visual, reproducción autónoma y pausa de las escenas en bucle.
extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _snapshot(node: Node) -> Array[Dictionary]:
	var state: Array[Dictionary] = []
	for child: Node in node.get_children():
		if child is Control:
			var control := child as Control
			state.append({"position": control.position, "scale": control.scale, "rotation": control.rotation, "alpha": control.modulate.a, "visible": control.visible, "texture": control.texture if control is TextureRect else null})
		state.append_array(_snapshot(child))
	return state

func _same_frame(a: Array[Dictionary], b: Array[Dictionary], tolerance: float) -> bool:
	if a.size() != b.size():
		return false
	for index: int in range(a.size()):
		if a[index].alpha <= 0.001 and b[index].alpha <= 0.001:
			continue # Un efecto puede envolver su posición sólo mientras es invisible.
		if a[index].position.distance_to(b[index].position) > tolerance or a[index].scale.distance_to(b[index].scale) > tolerance:
			return false
		if absf(a[index].rotation - b[index].rotation) > tolerance or absf(a[index].alpha - b[index].alpha) > tolerance:
			return false
		if a[index].visible != b[index].visible or a[index].texture != b[index].texture:
			return false
	return true

func _run() -> void:
	var manager: Node = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new("user://loop_validation.json")
	manager.scene_states.clear()
	var loop := load("res://scenes/components/StoryVignette.tscn").instantiate() as StoryVignette
	root.add_child(loop)
	await process_frame
	for situation: String in ["camino", "casa", "tamano", "hambre", "portal"]:
		for solved: bool in [false, true]:
			loop.show_situation(situation, solved)
			loop.seek_cycle(0)
			var start := _snapshot(loop)
			loop.seek_cycle(loop.cycle_seconds)
			_check(_same_frame(start, _snapshot(loop), 0.0001), "%s: el final debe coincidir con el inicio (resuelto=%s)" % [situation, solved])
			loop.seek_cycle(0.0001)
			var right := _snapshot(loop)
			loop.seek_cycle(loop.cycle_seconds - 0.0001)
			_check(_same_frame(right, _snapshot(loop), 0.08), "%s: no debe haber un salto entre los fotogramas a ambos lados del corte" % situation)
			_check(loop.find_children("*", "BaseButton", true, false).is_empty(), "El bucle no debe contener botones de reproducción")
	loop.show_situation("tamano")
	loop.seek_cycle(loop.cycle_seconds * 0.47)
	_check(loop._footprints[0].size == Vector2(24, 24) and loop._pages[0].size == Vector2(54, 42), "Los SVG de apoyo deben respetar el tamaño del efecto, no su tamaño nativo")
	_check(loop.actor.position.x > loop.actor_home.x + 180 and loop.actor.texture.resource_path.ends_with("aak_duda.svg"), "Áak debe intentar caber y cambiar de expresión")
	loop.seek_cycle(loop.cycle_seconds * 0.63)
	_check(loop._thought.modulate.a > 0.8, "Áak debe imaginar una mesa mayor")
	loop.show_situation("hambre")
	loop.seek_cycle(loop.cycle_seconds * 0.47)
	_check(loop._hunger.modulate.a > 0.7 and loop.actor.texture.resource_path.ends_with("peek_hambre.svg"), "El hambre debe verse en la barriga y en la expresión")
	loop.show_reward("lak", "Jats'uts", "Kaax")
	loop.seek_cycle(0)
	var reward_start := _snapshot(loop)
	loop.seek_cycle(loop.cycle_seconds)
	_check(_same_frame(reward_start, _snapshot(loop), 0.0001), "La celebración también debe cerrar su ciclo")
	var clock: float = loop.elapsed
	await create_timer(0.06).timeout
	_check(loop.elapsed > clock, "La animación debe avanzar por sí sola")
	paused = true
	clock = loop.elapsed
	await create_timer(0.06).timeout
	_check(is_equal_approx(loop.elapsed, clock), "La pausa debe congelar el ciclo")
	paused = false
	loop.hide()
	clock = loop.elapsed
	await create_timer(0.06).timeout
	_check(is_equal_approx(loop.elapsed, clock), "Las celebraciones ocultas no deben seguir animándose")
	loop.queue_free()
	await process_frame
	change_scene_to_file(manager.SCENE_PATHS.world2_story1)
	await scene_changed
	while current_scene.current_beat().kind != StoryBeat.Kind.EXPLORAR:
		current_scene._next_beat()
	_check(current_scene._waiting_to_continue and not current_scene.continue_button.disabled, "La escena debe permitir continuar sin tocar la animación")
	current_scene.vignette.seek_cycle(3.4)
	_check(current_scene.kalin.texture.resource_path.contains("kalin_pensando"), "Kalin debe acompañar el problema con su expresión")
	manager.checkpoint(current_scene)
	var moment: int = current_scene.beat_index
	change_scene_to_file(manager.SCENE_PATHS.world2_story1)
	await scene_changed
	_check(current_scene.beat_index == moment and current_scene._waiting_to_continue, "Un checkpoint visual debe seguir siendo navegable sin el botón antiguo")
	if failures.is_empty():
		print("Validación de animaciones continuas: OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
