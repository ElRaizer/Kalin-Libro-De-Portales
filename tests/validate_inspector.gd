## Contrato de autoría: las escenas guardan su UI y respetan el inspector.
extends SceneTree

var failures: Array[String] = []
var manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fresh() -> void:
	manager.session.scene_states.clear()
	manager.session.words_learned.clear()
	manager.session.completed_levels.clear()
	manager.session.tutorials_seen.clear()
	manager.session.resume_scene_key = ""


func _release(node: Node) -> void:
	current_scene = null
	node.queue_free()
	await process_frame
	await process_frame


func _run() -> void:
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		"user://inspector_validation.json"
	)
	_validate_word_changes()
	_validate_resources()
	await _validate_saved_controls()
	await _validate_saved_boards()
	await _validate_reused_choices()
	await _validate_exploration_scale()
	await _validate_edited_challenge()
	await _validate_reused_visuals()
	await _validate_confirmation()
	if failures.is_empty():
		print("Validación del inspector y recursos editables: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _validate_word_changes() -> void:
	var word: GridWordData = GridWordData.new()
	var changes: Array[bool] = []
	var listener: Callable = func(): changes.append(true)
	word.changed.connect(listener)
	word.maya_word = "Miis"
	word.color = Color.RED
	word.start_cell = Vector2i(2, 3)
	_check(changes.size() == 3, "Editar palabra, color o celda debe notificar a la vista previa")
	word.color = Color.RED
	_check(changes.size() == 3, "Un valor idéntico no debe reconstruir innecesariamente el tablero")
	word.changed.disconnect(listener)


func _validate_resources() -> void:
	for key: String in GameContent.SCENE_PATHS:
		var instance: Node = load(GameContent.SCENE_PATHS[key]).instantiate()
		if instance.has_method("get_configuration_issues"):
			_check(
				instance.get_configuration_issues().is_empty(), "Configuración incompleta en " + key
			)
		instance.free()
	for entry: VisualEntry in manager.visual_catalog.entries:
		_check(entry.texture != null, "El catálogo necesita la textura de " + entry.key)
		for expression: String in entry.expressions:
			_check(
				entry.expressions[expression] != null,
				"Expresión sin textura: " + entry.key + "/" + expression
			)
	var content: ExerciseSet = (
		load("res://data/exercises/world3.tres").duplicate(true) as ExerciseSet
	)
	content.challenges[0].noun = "mayak"
	content.challenges[0].adjective = "nojoch"
	content.challenges[0].request = "Una petición editada"
	var path: String = "user://inspector_content_test.tres"
	var error: Error = ResourceSaver.save(content, path)
	_check(error == OK, "El contenido del inspector debe poder guardarse como recurso")
	if error == OK:
		var restored: ExerciseSet = (
			ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ExerciseSet
		)
		_check(
			(
				restored.challenges[0].noun == "mayak"
				and restored.challenges[0].adjective == "nojoch"
				and restored.challenges[0].request == "Una petición editada"
			),
			"Los campos editados deben conservarse al recargar el recurso"
		)
		_check(
			restored.challenges[0].sprite != null,
			"El retrato debe conservar su referencia Texture2D"
		)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	content.challenges.append(null)
	_check(
		not content.get_configuration_issues(3).is_empty(),
		"Una petición sin recurso debe producir una advertencia"
	)


func _validate_saved_controls() -> void:
	var cases: Dictionary = {
		"main_menu":
		[
			"UI/WorldMap",
			"UI/WorldMap/World1",
			"UI/ResetConfirmation",
			"LibroHechizos/BG/Book/Categories"
		],
		"intro": ["UI/ContinueButton", "UI/MenuButton", "UI/SkipBtn"],
		"world1_level1":
		[
			"UI/DialoguePanel/ContinueButton",
			"UI/ArrivalButton",
			"UI/MissionProgress",
			"LearningGuide/Hand"
		],
		"world1_level3": ["UI/PreviewButton"],
		"world1_level4": ["UI/PreviewButton"],
		"world1_explore1": ["UI/ContinueButton", "UI/HelpButton", "UI/MenuButton"],
		"world2_story1": ["Stage/Vignette", "UI/DialogueBox/ContinueButton", "UI/MenuButton"],
		"world2_level1":
		["UI/Room", "UI/NextButton", "UI/RequestPanel/RequestArt", "UI/MissionBreak"],
		"world3_level1":
		[
			"UI/RequestPanel",
			"UI/SpellPanel",
			"UI/ChoicesPanel",
			"UI/FeedbackPanel",
			"UI/CastButton"
		],
		"world4_level1":
		[
			"UI/RequestPanel",
			"UI/SpellPanel",
			"UI/ChoicesPanel",
			"UI/FeedbackPanel",
			"UI/ServeButton"
		],
		"world5_level1":
		["PortalVisual", "Kalin", "UI/OptionsPanel", "UI/FeedbackPanel", "UI/NextButton"],
	}
	for key: String in cases:
		_fresh()
		var instance: Node = load(GameContent.SCENE_PATHS[key]).instantiate()
		var saved: Dictionary = {}
		for path: String in cases[key]:
			var control: Control = instance.get_node_or_null(path) as Control
			_check(control != null, key + " debe guardar " + path + " en su escena")
			if control != null:
				# A designer adjustment must survive initialization, not just match defaults.
				control.position += Vector2(3, 2)
				saved[path] = {"node": control, "position": control.position, "size": control.size}
		root.add_child(instance)
		current_scene = instance
		await process_frame
		await process_frame
		for path: String in saved:
			var expected: Dictionary = saved[path]
			var control: Control = instance.get_node_or_null(path) as Control
			_check(control == expected.node, key + " debe reutilizar el control " + path)
			if path == "LearningGuide/Hand":
				continue  # Su posición sigue el gesto animado, su identidad debe conservarse.
			# Containers own child geometry; test positions on freely authored controls.
			if control.get_parent() is not Container:
				_check(
					control.position.is_equal_approx(expected.position),
					key + " sobrescribe la posición de " + path
				)
				if (
					is_zero_approx(control.anchor_right - control.anchor_left)
					and is_zero_approx(control.anchor_bottom - control.anchor_top)
					and (
						path
						not in [
							"UI/WorldMap",
							"UI/ResetConfirmation",
							"LibroHechizos/BG/Book/Categories"
						]
					)
				):
					_check(
						control.size.is_equal_approx(expected.size),
						key + " sobrescribe el tamaño de " + path
					)
		await _release(instance)
	var pause: Node = root.get_node("PauseMenu")
	_check(
		pause.scene_file_path == "res://scenes/autoloads/pause_menu.tscn",
		"La pausa global debe ser una escena editable"
	)


func _validate_saved_boards() -> void:
	for key: String in ["world1_level1", "world1_level2", "world1_level3", "world1_level4"]:
		_fresh()
		var instance: Node = load(GameContent.SCENE_PATHS[key]).instantiate()
		var board: GridBoard = instance.get_node("GridBoard") as GridBoard
		var preview: Node = board.get_node("Preview")
		var saved: Array[Node] = preview.get_children()
		var first_tile: TextureRect = preview.get_node_or_null("Tile_0_0") as TextureRect
		_check(first_tile != null, key + " debe guardar sus casillas antes de entrar al árbol")
		if first_tile:
			first_tile.position += Vector2(2, 3)
		var edited_position: Vector2 = first_tile.position if first_tile else Vector2.ZERO
		var saved_styles: Array[StyleBoxFlat] = []
		for index: int in range(board.words.size()):
			var destination: Panel = preview.get_node("Destination_%d" % index) as Panel
			var style: StyleBoxFlat = (
				(destination.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
				as StyleBoxFlat
			)
			# Un ajuste directo del Inspector debe sobrevivir al inicio del nivel.
			style.bg_color = Color(0.23 + index * 0.1, 0.48, 0.67)
			style.border_color = Color(0.15, 0.28 + index * 0.1, 0.39)
			destination.add_theme_stylebox_override("panel", style)
			saved_styles.append(style)
		root.add_child(instance)
		current_scene = instance
		await process_frame
		_check(
			preview.get_children() == saved, key + " debe reutilizar todos los nodos del tablero"
		)
		_check(
			first_tile.position == edited_position,
			key + " debe respetar la posición de autor de las casillas"
		)
		_check(
			board.word_nodes[0].get_node("Icon").texture == board.words[0].sprite,
			key + " debe guardar la ilustración de la ficha"
		)
		for index: int in range(board.words.size()):
			var destination: Panel = board.destination_nodes[index]
			_check(
				destination.get_theme_stylebox("panel") == saved_styles[index],
				key + " debe respetar el estilo de casa editado en el Inspector"
			)
		var line: Line2D = board.path_lines[0]
		var tip: Polygon2D = board.path_tips[0]
		board.paths[0].append(board.words[0].start_cell)
		board._refresh_path_line(0)
		board._remove_path_line(0)
		_check(
			(
				board.path_lines[0] == line
				and board.path_tips[0] == tip
				and not line.visible
				and not tip.visible
			),
			key + " debe reutilizar también los trazos al reiniciar un camino"
		)
		await _release(instance)


func _validate_reused_choices() -> void:
	for key: String in ["world2_level1", "world5_level1", "world2_story1"]:
		_fresh()
		var instance: Node = load(GameContent.SCENE_PATHS[key]).instantiate()
		var path: String = (
			"UI/ChoicesGrid"
			if key == "world2_level1"
			else ("UI/OptionsPanel/Content/Options" if key == "world5_level1" else "UI/Choices")
		)
		var container: Node = instance.get_node(path)
		var saved: Array[Node] = container.get_children()
		_check(not saved.is_empty(), key + " debe guardar sus botones de respuesta")
		var saved_actors: Array[Node] = []
		if key == "world2_story1":
			saved_actors = instance.get_node("Stage/Actors").get_children()
		root.add_child(instance)
		current_scene = instance
		await process_frame
		if key == "world2_level1":
			instance._build_choices()
			instance.round_index = instance.objects.size()
			instance.current_phase = 1
			instance._build_choices()
			for button: Button in container.get_children():
				_check(
					button.icon == null,
					"La fase de recuerdo debe limpiar los iconos de los botones reutilizados"
				)
			for button: Button in instance._choice_buttons:
				if str(button.get_meta("word")) == instance._current_object().maya:
					button.pressed.emit()
					break
			_check(
				instance._waiting,
				"Las respuestas de la casa deben leer el contenido de la ronda actual"
			)
		elif key == "world5_level1":
			instance._build_options(instance.challenges[0].options)
			for button: Button in instance.option_buttons:
				if str(button.get_meta("phrase")) == instance.challenges[0].correct:
					button.pressed.emit()
					break
			_check(
				instance._awaiting_continue,
				"Las respuestas reutilizadas del portal deben resolver la pregunta"
			)
		else:
			while instance.current_beat().kind != StoryBeat.Kind.ELEGIR:
				instance._next_beat()
			_check(
				instance.get_node("Stage/Actors").get_children() == saved_actors,
				"Cambiar de momento debe conservar los espacios de actor"
			)
		_check(
			container.get_children() == saved,
			key + " debe reutilizar los botones al cambiar de ronda"
		)
		await _release(instance)


func _validate_exploration_scale() -> void:
	_fresh()
	var instance: Node = load(GameContent.SCENE_PATHS.world1_explore1).instantiate()
	var sprite: Sprite2D = instance.get_node("Kalin/Sprite") as Sprite2D
	sprite.scale = Vector2(0.63, 0.84)
	root.add_child(instance)
	current_scene = instance
	await process_frame
	await process_frame
	_check(
		is_equal_approx(sprite.scale.x, 0.63) and absf(sprite.scale.y - 0.84) < 0.02,
		"Respirar debe respetar la escala de autor de Kalin"
	)
	instance._dialogue.close()
	instance.walk(1.0, 0.03)
	_check(
		sprite.scale.is_equal_approx(Vector2(0.63, 0.84)),
		"Caminar debe respetar la escala de autor de Kalin"
	)
	await _release(instance)


func _validate_edited_challenge() -> void:
	_fresh()
	var instance: Node = load(GameContent.SCENE_PATHS.world3_level1).instantiate()
	instance.content = instance.content.duplicate(true)
	var texture: Texture2D = load("res://Arte/sprites/animal_aak.svg")
	instance.content.challenges[0].sprite = texture
	instance.content.challenges[0].phrase = "Frase de autor"
	root.add_child(instance)
	current_scene = instance
	await process_frame
	_check(
		instance.animal_sprite.texture == texture,
		"La petición debe usar el retrato del recurso editado"
	)
	_check(
		instance._current_challenge().phrase == "Frase de autor",
		"El controlador debe consumir el contenido de su instancia"
	)
	var original: ExerciseSet = load("res://data/exercises/world3.tres")
	_check(
		original.challenges[0].phrase != "Frase de autor",
		"Editar una instancia no debe modificar el recurso de otra prueba"
	)
	var guide: LearningGuide = instance.guide
	var ring: Panel = guide._hint_ring
	var children: int = guide.get_child_count()
	guide.highlight(instance.noun_slot)
	guide.stop()
	guide.highlight(instance.adjective_slot)
	_check(
		guide._hint_ring == ring and guide.get_child_count() == children,
		"La ayuda debe reutilizar el marco guardado"
	)
	await _release(instance)


func _validate_reused_visuals() -> void:
	var vignette: StoryVignette = (
		load("res://scenes/features/story/story_vignette.tscn").instantiate() as StoryVignette
	)
	root.add_child(vignette)
	var children: int = vignette.get_child_count()
	var actor: TextureRect = vignette.actor
	for situation: String in ["camino", "casa", "tamano", "hambre", "portal"]:
		vignette.show_situation(situation)
		vignette.show_situation(situation, true)
		_check(
			vignette.actor == actor and vignette.get_child_count() == children,
			"Cambiar la situación debe reutilizar la composición guardada"
		)
	await _release(vignette)


func _validate_confirmation() -> void:
	_fresh()
	var instance: Node = load(GameContent.SCENE_PATHS.main_menu).instantiate()
	root.add_child(instance)
	current_scene = instance
	manager.session.magic_points = 123
	instance._on_reset_pressed()
	for index: int in range(4):
		var tab: InputEventKey = InputEventKey.new()
		tab.keycode = KEY_TAB
		tab.pressed = true
		root.push_input(tab, true)
		await process_frame
		var focused: Control = root.gui_get_focus_owner()
		_check(
			focused != null and instance.reset_confirmation.is_ancestor_of(focused),
			"El foco de teclado debe permanecer dentro de la confirmación"
		)
	instance.reset_confirmation.cancel_button.pressed.emit()
	_check(
		manager.session.magic_points == 123 and not instance.reset_confirmation.visible,
		"Cancelar el borrado debe conservar la partida"
	)
	instance._on_reset_pressed()
	instance.reset_confirmation.get_node("Panel/Buttons/ConfirmButton").pressed.emit()
	_check(
		manager.session.magic_points == 0 and not instance.reset_confirmation.visible,
		"Confirmar el borrado debe reiniciar y cerrar el diálogo"
	)
	await _release(instance)
