## Entrada de animales: todos los capítulos, cinemáticas y estados restaurados.
extends SceneTree

var manager: Node
var failures: Array[String] = []
var checked_beats := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _release(story: Node) -> void:
	current_scene = null
	story.queue_free()
	await process_frame
	await process_frame

func _mount(key: String, fresh: bool = true) -> Node:
	if fresh:
		manager.scene_states.clear()
		manager.words_learned.clear()
		manager.completed_levels.clear()
		manager.resume_scene_key = ""
	var story: Node = load(manager.SCENE_PATHS[key]).instantiate()
	root.add_child(story)
	current_scene = story
	return story

func _ready_input(story: Node) -> void:
	story._complete_text()
	for tween: Tween in story._actor_tweens.values().duplicate():
		if tween.is_valid():
			tween.custom_step(2.0)
	await process_frame

func _assert_locked(story: Node, context: String) -> void:
	for slot: Control in story.actors_root.get_children():
		var button := slot.get_node("Button") as Button
		_check(button.disabled and button.mouse_filter == Control.MOUSE_FILTER_IGNORE and button.focus_mode == Control.FOCUS_NONE, context + ": el animal debe ignorar ratón y teclado")
		_check(button.tooltip_text.is_empty(), context + ": no debe ofrecer saludar")

func _assert_ignored(story: Node, context: String) -> void:
	var met: Array = story._met_words.duplicate()
	var waiting: bool = story._waiting_to_continue
	var bubble_visible: bool = story.word_bubble.visible
	var bubble_text: String = story.bubble_maya.text
	story._on_actor_pressed("")
	story._on_actor_pressed("animal_inexistente")
	for slot: Control in story.actors_root.get_children():
		(slot.get_node("Button") as Button).pressed.emit()
	_check(story._met_words == met and story._waiting_to_continue == waiting, context + ": una pulsación bloqueada no debe cambiar el progreso")
	_check(story.word_bubble.visible == bubble_visible and story.bubble_maya.text == bubble_text, context + ": una pulsación bloqueada no debe abrir ni sustituir un diálogo")

func _run() -> void:
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new("user://story_interaction_validation.json")
	var scenes_checked := 0
	for key: String in manager.SCENE_PATHS:
		if not ("_story" in key or "_cine" in key):
			continue
		scenes_checked += 1
		var story := _mount(key)
		for index: int in range(story.beats.size()):
			var context := "%s, momento %d" % [key, index]
			checked_beats += 1
			story.auto_timer.stop()
			_assert_locked(story, context + ", al presentar la consigna")
			_assert_ignored(story, context + ", al presentar la consigna")
			await _ready_input(story)
			for slot: Control in story.actors_root.get_children():
				var button := slot.get_node("Button") as Button
				if str(button.get_meta("word", "")).is_empty():
					_check(not slot.visible and button.disabled and button.icon == null, context + ": los espacios sin animal deben estar ocultos y vacíos")
			var beat: StoryBeat = story.current_beat()
			if beat.kind in [StoryBeat.Kind.CONOCER, StoryBeat.Kind.ADIVINAR]:
				for button: Button in story.actor_buttons.values():
					_check(not button.disabled and button.mouse_filter == Control.MOUSE_FILTER_STOP and button.focus_mode == Control.FOCUS_ALL, context + ": los animales presentes deben poder responder a la consigna")
				paused = true
				_assert_ignored(story, context + ", en pausa")
				paused = false
				# Aunque un nodo se oculte después de activarse, el manejador lo rechaza.
				var first: Button = story.actor_buttons.values()[0]
				first.get_parent().hide()
				var bubble_before: bool = story.word_bubble.visible
				first.pressed.emit()
				_check(story.word_bubble.visible == bubble_before and not story._waiting_to_continue, context + ": un animal oculto no debe responder")
				first.get_parent().show()
				story._refresh_actor_interaction()
				if beat.kind == StoryBeat.Kind.CONOCER:
					for word: String in beat.actors:
						var button: Button = story.actor_buttons[word]
						button.pressed.emit()
						_check(word in story._met_words and button.disabled, context + ": saludar debe registrar al animal y desactivar su botón")
						var count: int = story._met_words.size()
						button.pressed.emit()
						_check(story._met_words.size() == count, context + ": repetir el clic no debe repetir el saludo")
				else:
					for word: String in beat.actors:
						if word != beat.target_word:
							(story.actor_buttons[word] as Button).pressed.emit()
							_check(not story._waiting_to_continue, context + ": un error debe permitir intentarlo de nuevo")
							break
					(story.actor_buttons[beat.target_word] as Button).pressed.emit()
				_check(story._waiting_to_continue, context + ": completar la interacción debe permitir continuar")
				_assert_locked(story, context + ", resuelto")
				_assert_ignored(story, context + ", resuelto")
			else:
				_assert_locked(story, context)
				_assert_ignored(story, context)
				if beat.kind == StoryBeat.Kind.ELEGIR:
					_check(not story.word_bubble.visible and story.choices_box.visible, context + ": los saludos no deben tapar las respuestas")
					var answer := story.choices_box.get_child(beat.options.find(beat.target_word)) as Button
					answer.pressed.emit()
					_assert_ignored(story, context + ", tras responder la pregunta")
			if index + 1 < story.beats.size():
				story._next_beat()
		# Una señal tardía al salir tampoco debe indexar un momento inexistente.
		story._navigating = true
		story.beat_index = story.beats.size()
		story._refresh_actor_interaction()
		_assert_ignored(story, key + ", saliendo")
		await _release(story)
	await _check_entrance_gate()
	await _check_prompt_and_real_input()
	await _check_resume()
	if failures.is_empty():
		print("Validación de entrada de animales: OK (%d escenas, %d momentos)" % [scenes_checked, checked_beats])
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _check_entrance_gate() -> void:
	var story := _mount("world1_story1")
	while story.current_beat().kind != StoryBeat.Kind.CONOCER:
		story._next_beat()
	story._complete_text()
	_assert_locked(story, "Durante la entrada de los animales")
	_assert_ignored(story, "Durante la entrada de los animales")
	await _ready_input(story)
	_check(not (story.actor_buttons["Peek'"] as Button).disabled, "La interacción debe habilitarse cuando termina la entrada")
	await _release(story)

func _check_resume() -> void:
	var story := _mount("world1_story1")
	while story.current_beat().kind != StoryBeat.Kind.CONOCER:
		story._next_beat()
	await _ready_input(story)
	(story.actor_buttons["Peek'"] as Button).pressed.emit()
	manager.checkpoint(story)
	await _release(story)
	story = _mount("world1_story1", false)
	await _ready_input(story)
	_check((story.actor_buttons["Peek'"] as Button).disabled and not (story.actor_buttons["Miis"] as Button).disabled, "Continuar debe conservar el saludo ya realizado y habilitar los pendientes")
	(story.actor_buttons["Miis"] as Button).pressed.emit()
	(story.actor_buttons["Kaax"] as Button).pressed.emit()
	manager.checkpoint(story)
	await _release(story)
	story = _mount("world1_story1", false)
	await _ready_input(story)
	_check(story._waiting_to_continue and not story.continue_button.disabled, "Restaurar una presentación resuelta debe permitir seguir")
	_assert_locked(story, "Presentación restaurada y resuelta")
	_assert_ignored(story, "Presentación restaurada y resuelta")
	await _release(story)
	for key: String in ["world1_story1", "world5_story1"]:
		story = _mount(key)
		var expected_kind := StoryBeat.Kind.ADIVINAR if key == "world1_story1" else StoryBeat.Kind.ELEGIR
		while story.current_beat().kind != expected_kind:
			story._next_beat()
		await _ready_input(story)
		var beat: StoryBeat = story.current_beat()
		if expected_kind == StoryBeat.Kind.ADIVINAR:
			(story.actor_buttons[beat.target_word] as Button).pressed.emit()
		else:
			(story.choices_box.get_child(beat.options.find(beat.target_word)) as Button).pressed.emit()
		manager.checkpoint(story)
		await _release(story)
		story = _mount(key, false)
		await _ready_input(story)
		_check(story._waiting_to_continue and not story.continue_button.disabled, key + ": una respuesta restaurada debe permitir continuar")
		_assert_locked(story, key + ", respuesta restaurada")
		_assert_ignored(story, key + ", respuesta restaurada")
		await _release(story)

func _check_prompt_and_real_input() -> void:
	var story := _mount("world1_story1")
	while story.current_beat().kind != StoryBeat.Kind.CONOCER:
		story._next_beat()
	for tween: Tween in story._actor_tweens.values().duplicate():
		if tween.is_valid():
			tween.custom_step(2.0)
	_assert_locked(story, "Mientras se escribe la consigna con los animales presentes")
	_assert_ignored(story, "Mientras se escribe la consigna con los animales presentes")
	story._text_tween.custom_step(100.0)
	await process_frame
	var dog: Button = story.actor_buttons["Peek'"]
	_check(not dog.disabled, "Terminar de escribir debe activar los animales sin exigir otro clic")
	var point := dog.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = point
		root.push_input(click, true)
	await process_frame
	_check("Peek'" in story._met_words, "Un clic real en un animal habilitado debe saludarlo")
	(story.actor_buttons["Miis"] as Button).grab_focus()
	for pressed: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_SPACE
		key.pressed = pressed
		root.push_input(key, true)
	await process_frame
	_check("Miis" in story._met_words, "El teclado debe permitir saludar a un animal habilitado")
	await _release(story)
