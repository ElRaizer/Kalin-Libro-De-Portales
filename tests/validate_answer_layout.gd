## Comprueba las opciones visibles, las filas y la solución en cada ronda.
## Con --capture guarda ejemplos renderizados en res://.ui-review/symmetry/.
extends SceneTree

var failures: Array[String] = []
var manager: Node
var capture: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _scene(key: String) -> void:
	manager.session.scene_states.clear()
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame


func _settle() -> void:
	await process_frame
	await process_frame


func _visible_buttons(grid: Container) -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in grid.get_children():
		if child is Button and child.visible:
			buttons.append(child)
	return buttons


func _grid(grid: GridContainer, context: String) -> void:
	if not grid.is_visible_in_tree():
		return
	var buttons: Array[Button] = _visible_buttons(grid)
	_check(
		buttons.size() >= 2 and buttons.size() % 2 == 0, context + ": cantidad par de respuestas"
	)
	_check(
		grid.columns % 2 == 0 and buttons.size() % grid.columns == 0,
		context + ": filas completas con columnas pares"
	)
	if buttons.is_empty():
		return
	var first_size: Vector2 = buttons[0].size
	for button: Button in buttons:
		_check(
			(button.size - first_size).abs().x <= 1 and (button.size - first_size).abs().y <= 1,
			context + ": botones del mismo tamaño"
		)
		_check(
			grid.get_global_rect().grow(1).encloses(button.get_global_rect()),
			context + ": botón dentro de la cuadrícula"
		)
		_check(
			Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(button.get_global_rect()),
			context + ": botón dentro de la pantalla"
		)
	for index: int in range(0, buttons.size(), grid.columns):
		for column: int in range(grid.columns):
			_check(
				is_equal_approx(buttons[index].position.y, buttons[index + column].position.y),
				context + ": botones alineados por fila"
			)


func _navigation(grid: GridContainer, context: String) -> void:
	if not grid.is_visible_in_tree():
		return
	for button: Button in _visible_buttons(grid):
		for path: NodePath in [
			button.focus_neighbor_left,
			button.focus_neighbor_right,
			button.focus_neighbor_top,
			button.focus_neighbor_bottom
		]:
			if not path.is_empty():
				var target: Control = button.get_node(path) as Control
				_check(
					target != null and target.is_visible_in_tree(),
					context + ": el teclado no debe apuntar a opciones ocultas"
				)


func _shot(filename: String) -> void:
	if not capture:
		return
	await _settle()
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://.ui-review/symmetry")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(filename + ".png"))


func _run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		"user://answer_layout_validation.json"
	)
	manager.session.scene_states.clear()
	manager.session.tutorials_seen.assign(["objects", "phrases", "requests"])
	await _house()
	await _phrases()
	await _food()
	await _portal()
	await _stories()
	if failures.is_empty():
		print("OK: respuestas pares, filas simétricas y soluciones accesibles en todas las rondas.")
	else:
		for message: String in failures:
			push_error(message)
	quit(0 if failures.is_empty() else 1)


func _house() -> void:
	await _scene("world2_level1")
	var level: Node = current_scene
	for index: int in range(level.total_rounds):
		level.round_index = index
		level._show_round()
		level.mission_break.hide()
		await _settle()
		_grid(level.choices_grid, "Casa %d" % index)
		var correct: String = level._current_object().maya
		var found: bool = false
		for button: Button in _visible_buttons(level.choices_grid):
			found = found or button.get_meta("word") == correct
		_check(found, "Casa: la respuesta correcta siempre debe estar visible")
		if index == 0 or index == 1 or index == level.objects.size() + 2:
			await _shot("casa_%d" % index)
		level._on_choice_pressed(correct)
		_check(level._waiting, "Casa: la respuesta debe resolver la ronda")


func _phrases() -> void:
	await _scene("world3_level1")
	var level: Node = current_scene
	for index: int in range(level.round_plan.size()):
		level.round_index = index
		level._show_round()
		level.mission_break.hide()
		await _settle()
		_grid(level.noun_grid, "Taller objeto %d" % index)
		_grid(level.adjective_grid, "Taller cualidad %d" % index)
		_navigation(level.noun_grid, "Taller objeto")
		_navigation(level.adjective_grid, "Taller cualidad")
		var challenge: ExerciseEntry = level._current_challenge()
		_check(
			(
				level.noun_buttons[challenge.noun].visible
				and level.adjective_buttons[challenge.adjective].visible
			),
			"Taller: solución siempre visible"
		)
		if index == 0 or index == 7 or index == 10:
			await _shot("taller_%d" % index)
		level._select_noun(challenge.noun)
		level._select_adjective(challenge.adjective)
		_check(not level.cast_button.disabled, "Taller: solución habilita Crear")


func _food() -> void:
	await _scene("world4_level1")
	var level: Node = current_scene
	for index: int in range(level.round_plan.size()):
		level.round_index = index
		level._show_round()
		level.mission_break.hide()
		await _settle()
		_grid(level.food_grid, "Comida %d" % index)
		_grid(level.modifier_grid, "Cualidad %d" % index)
		_navigation(level.food_grid, "Comida")
		var challenge: ExerciseEntry = level._current_challenge()
		_check(level.food_buttons[challenge.food].visible, "Comida: alimento correcto visible")
		level._select_food(challenge.food)
		if not challenge.modifier.is_empty():
			# Al elegir un distractor y quitarlo, la fila debe conservar sus cuatro botones.
			level._select_modifier("ki'")
			await _settle()
			_grid(level.modifier_grid, "Cualidad con distractor")
			level._select_modifier("")
			await _settle()
			_grid(level.modifier_grid, "Cualidad sin selección")
			level._select_modifier(challenge.modifier)
		await _settle()
		_grid(level.modifier_grid, "Cualidad seleccionada")
		_check(not level.serve_button.disabled, "Comida: solución habilita Servir")
		if index == 0 or index == 1 or index == 8:
			await _shot("comida_%d" % index)


func _portal() -> void:
	await _scene("world5_level1")
	var level: Node = current_scene
	for index: int in range(level.challenges.size()):
		level.challenge_index = index
		level._show_challenge()
		await _settle()
		_grid(level.options_box, "Portal %d" % index)
		_check(level.option_buttons.size() == 4, "Portal: cuatro opciones por reto")
		var correct: String = level.challenges[index].correct
		var found: bool = false
		for button: Button in _visible_buttons(level.options_box):
			found = found or button.get_meta("phrase") == correct
		_check(found, "Portal: respuesta correcta visible")
		if index == 0 or index == 7:
			await _shot("portal_%d" % index)
		level._on_option_pressed(correct)
		_check(level._awaiting_continue, "Portal: respuesta correcta permite continuar")


func _stories() -> void:
	for key: String in GameContent.SCENE_PATHS:
		if "story" not in key:
			continue
		await _scene(key)
		var story: Node = current_scene
		for index: int in range(story.beats.size()):
			var beat: StoryBeat = story.beats[index]
			if (
				beat.kind
				not in [StoryBeat.Kind.ELEGIR, StoryBeat.Kind.ADIVINAR, StoryBeat.Kind.CONOCER]
			):
				continue
			story.beat_index = index
			story._show_beat(beat)
			story._complete_text()
			await _settle()
			if beat.kind in [StoryBeat.Kind.ADIVINAR, StoryBeat.Kind.CONOCER]:
				for tween: Tween in story.interaction._actor_tweens.values().duplicate():
					if tween.is_valid():
						tween.custom_step(2.0)
				await _settle()
				_check(
					story.interaction.actor_buttons.size() % 2 == 0,
					key + ": cantidad par de respuestas con animales"
				)
				for button: Button in story.interaction.actor_buttons.values():
					_check(
						button.is_visible_in_tree() and not button.disabled,
						key + ": animales disponibles para responder"
					)
				await _shot("%s_animales_%d" % [key, index])
				if beat.kind == StoryBeat.Kind.ADIVINAR:
					(story.interaction.actor_buttons[beat.target_word] as Button).pressed.emit()
				else:
					for button: Button in story.interaction.actor_buttons.values():
						button.pressed.emit()
				_check(story.can_continue(), key + ": interacción con animales permite continuar")
				continue
			_grid(story.choices_box, key)
			_check(
				beat.options.size() == 4 and beat.options.has(beat.target_word),
				key + ": cuatro opciones con respuesta correcta"
			)
			for word: String in beat.options:
				_check(beat.options.count(word) == 1, key + ": distractores únicos")
			await _shot("%s_%d" % [key, index])
			for option: Button in _visible_buttons(story.choices_box):
				if str(option.get_meta("word")) != beat.target_word:
					option.pressed.emit()
					await create_timer(0.2).timeout
					await _settle()
					_grid(story.choices_box, key + " tras equivocarse")
				_check(
					option.get_global_rect().end.y <= story.actors_root.global_position.y - 8,
					key + ": respuestas sin tapar los animales"
				)
			var answer: Button = story.interaction.choice_for_word(beat.target_word) as Button
			answer.pressed.emit()
			_check(story.can_continue(), key + ": respuesta correcta permite continuar")
