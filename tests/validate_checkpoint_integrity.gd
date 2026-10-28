extends ProjectTest

var manager: Node
var runs: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(120).timeout.connect(quit.bind(2))
	manager = root.get_node("GameManager")
	manager.use_save_repository(repository_for("checkpoint_integrity"))
	root.get_node("AccessibilityManager").instant_text = true
	root.get_node("AccessibilityManager").reduced_motion = true
	for key: String in GameContent.SCENE_PATHS:
		if key == "main_menu":
			continue
		await _load(key, {"layout_seed": 113})
		if not current_scene.has_method("get_checkpoint_state"):
			continue
		var baseline: Dictionary = JSON.parse_string(
			JSON.stringify(current_scene.get_checkpoint_state())
		)
		var progress: Dictionary = manager.session.snapshot()
		for mode: String in [
			"roundtrip",
			"wrong_types",
			"mixed_arrays",
			"nested",
			"large",
			"negative",
			"completion",
			"array_flags",
			"recursive_arrays"
		]:
			var state: Dictionary = baseline.duplicate(true)
			_mutate(state, mode)
			manager.session.restore(progress)
			print("CASE ", key, " ", mode)
			await _load(key, state, false)
			var snapshot: Dictionary = current_scene.get_checkpoint_state()
			var parsed: Variant = JSON.parse_string(JSON.stringify(snapshot))
			if parsed is not Dictionary:
				failures.append(key + ": snapshot no serializable")
			elif mode == "roundtrip":
				check(
					_canonical_checkpoint(parsed) == _canonical_checkpoint(baseline),
					key + ": reanudar conserva todos los valores del checkpoint"
				)
			if mode == "roundtrip" and manager.session.magic_points != progress.magic_points:
				failures.append(key + ": recargar acredita puntos")
			if (
				current_scene.has_method("_on_level_complete")
				and bool(snapshot.get("complete", false))
			):
				if not current_scene.grid_board.is_completed():
					failures.append(key + ": completion sin tablero terminado (" + mode + ")")
	await _blocks_lifecycle()
	_preferences()
	manager._save_repository.delete_progress()
	finish("Integridad de checkpoints: %d cargas y ciclo de controles" % runs)


func _canonical_checkpoint(state: Dictionary) -> Dictionary:
	var result: Dictionary = state.duplicate(true)
	# Estos mapas dispersos omiten las tareas sin errores o apoyo. Restaurarlos
	# con sus valores por defecto conserva el mismo estado de aprendizaje.
	for field: String in ["task_support", "task_mistakes"]:
		if result.get(field) is Dictionary:
			for index: int in range(3):
				var key: String = str(index)
				if not result[field].has(key):
					if field == "task_support":
						result[field][key] = false
					else:
						result[field][key] = 0
	return JSON.parse_string(JSON.stringify(result))


func _load(key: String, state: Dictionary, clear: bool = true) -> void:
	paused = false
	if clear:
		manager.session.reset()
	manager.session.scene_states[key] = JSON.parse_string(JSON.stringify(state))
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame
	runs += 1


func _mutate(state: Dictionary, mode: String) -> void:
	if mode == "wrong_types":
		for key: String in (
			SceneStateSchema.NUMBERS
			+ SceneStateSchema.FLAGS
			+ SceneStateSchema.TEXT
			+ SceneStateSchema.LISTS
		):
			state[key] = {}
		for key: String in SceneStateSchema.OBJECTS:
			state[key] = []
	elif mode == "mixed_arrays":
		for key: String in SceneStateSchema.LISTS:
			state[key] = [null, {}, [], true, 1.5, -1, 1e30, "invalid"]
	elif mode == "nested":
		state.merge(
			{
				"attempt": {"context": {}, "mistakes": {}, "supported": []},
				"carried":
				{"item": "mayak", "quality": "", "mistakes": {}, "supported": [], "phase": []},
				"task_support": {"0": {}, "1": []},
				"task_mistakes": {"0": {}, "1": []},
				"drafts":
				{
					"0":
					{
						"cards": [],
						"scaffold": {"mode": {}, "slots": [[{}, -1, true]], "history": [{}]}
					}
				},
				"previous_variation": {"portal_variants": {"0": {}}, "plan": [{"challenge": {}}]},
				"guess_targets": {"0": {}},
				"portal_variants": {"0": {}},
				"scaffold": {"mode": 2, "slots": [[{}, -1, true]], "history": [{"slots": [null]}]},
				"greeting_visits": {"Miis": {}},
				"portal_pool_keys": {"2": [{}, "invalid"]},
				"board": {"paths": {"0": [[{}, 0]]}, "connected": [null, {}, -1]}
			},
			true
		)
	elif mode in ["large", "negative"]:
		for key: String in SceneStateSchema.NUMBERS:
			state[key] = 1e30 if mode == "large" else -1e30
	elif mode == "recursive_arrays":
		_array_values(state)
	elif mode == "array_flags":
		for key: String in SceneStateSchema.FLAGS:
			state[key] = []
	elif mode == "completion":
		state.complete = true
		state.waiting = true
		state.resolved = true


func _array_values(value: Variant) -> void:
	if value is Dictionary:
		for key: String in value:
			if value[key] is Dictionary or value[key] is Array:
				_array_values(value[key])
			else:
				value[key] = []
	elif value is Array:
		for index: int in range(value.size()):
			if value[index] is Dictionary or value[index] is Array:
				_array_values(value[index])
			else:
				value[index] = []


func _blocks_lifecycle() -> void:
	await _load("world3_level1", {"layout_seed": 113})
	var count: int = current_scene.challenges.size()
	await _load("world3_level1", PhraseExerciseFixture.recall_state(113, count))
	current_scene.recall.set_mode(RecallPanel.Mode.BLOCKS, false)
	var saved: Dictionary = current_scene.get_checkpoint_state()
	await _load("world3_level1", saved)
	check(
		current_scene.recall.mode == RecallPanel.Mode.BLOCKS,
		"Se restauran los bloques antes de capturar la distribución"
	)
	current_scene.recall.configure(
		["Palabra", "Cualidad"], ["Miis", "nojoch"], RecallPanel.Mode.BLOCKS
	)
	await process_frame
	await process_frame
	var layout: Node = current_scene.get_node("ScreenLayout")
	layout.preview_compact = true
	layout.refresh()
	layout.preview_compact = false
	layout.refresh()
	check(
		current_scene.recall.mode == RecallPanel.Mode.BLOCKS,
		"Cambiar la distribución conserva el nuevo ejercicio"
	)
	var panel: RecallPanel = current_scene.recall
	for payload: Variant in [
		[],
		{},
		{"kind": [], "panel": panel, "index": 0},
		{"kind": "recall_fragment", "panel": [], "index": 0}
	]:
		check(not panel.accepts_fragment(payload), "Un arrastre ajeno o mal formado se rechaza")


func _preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("comfort", "reduced_motion", [])
	config.set_value("comfort", "reduced_flashes", {})
	config.set_value("comfort", "instant_text", true)
	var path: String = "user://kalin_preferences.cfg"
	check(config.save(path) == OK, "Se prepara una configuración con tipos incorrectos")
	var preferences: Node = load("res://scripts/autoloads/accessibility_manager.gd").new()
	root.add_child(preferences)
	check(
		(
			not preferences.reduced_motion
			and not preferences.reduced_flashes
			and preferences.instant_text
		),
		"Las preferencias dañadas no interrumpen el inicio ni afectan campos válidos"
	)
	preferences.free()
	check(DirAccess.remove_absolute(path) == OK, "Se limpia la configuración de prueba")
