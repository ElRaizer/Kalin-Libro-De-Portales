## La tarjeta posterior al nombre conserva sus zonas en escritorio y compacto.
extends SceneTree

var failures: Array[String] = []
var manager: Node
var capture_folder: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _settle() -> void:
	await process_frame
	await process_frame


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_folder = argument.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://grid_dialogue_layout.json"))
	for level_number: int in range(1, 5):
		await _level(level_number)
	if failures.is_empty():
		print("OK: tarjetas de los doce animales, escritura, foco y perfiles sin superposiciones.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _level(level_number: int) -> void:
	manager.session.reset()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	var level: Node = load(GameContent.SCENE_PATHS["world1_level%d" % level_number]).instantiate()
	level.vary_board = false
	root.add_child(level)
	current_scene = level
	await _settle()
	var layout: ScreenLayout = level.get_node("ScreenLayout") as ScreenLayout
	for mode: int in range(3):
		layout.preview_compact = mode == 1
		layout.refresh()
		await _settle()
		for index: int in range(level.grid_board.words.size()):
			var word: GridWordData = level.grid_board.words[index]
			# Recorre llegada, escritura y confirmación también al volver de compacto.
			level._named_words.clear()
			level._on_word_connected(word, index)
			level.arrival_tween.custom_step(60.0)
			await _settle()
			_check(level.recall.visible, "La llegada debe solicitar el nombre de " + word.maya_word)
			level.recall.first.text = word.maya_word
			level._submit_name()
			await _settle()
			var context: String = "Nivel %d, perfil %d, %s" % [level_number, mode, word.maya_word]
			_validate_card(level, context)
			if level_number == 3 and index == 0 and not capture_folder.is_empty():
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(
					capture_folder.path_join("guardianes_%d.png" % mode)
				)
			level.continue_button.pressed.emit()
			_check(not level.dialogue.visible, context + ": Continuar debe cerrar la tarjeta")
	current_scene = null
	level.queue_free()
	await _settle()


func _validate_card(level: Node, context: String) -> void:
	_check(level.dialogue.visible and not level.recall.visible, context + ": tarjeta tras escribir")
	_check(level.continue_button.has_focus(), context + ": foco en Continuar")
	var card: Rect2 = level.dialogue.get_global_rect()
	_check(Rect2(0, 0, 1280, 720).encloses(card), context + ": tarjeta dentro de la pantalla")
	var controls: Array[Control] = [
		level.dlg_icon, level.dlg_phrase, level.dlg_hint, level.continue_button
	]
	for index: int in range(controls.size()):
		var control: Control = controls[index]
		_check(
			card.grow(-8).encloses(control.get_global_rect()),
			context + ": " + control.name + " dentro de la tarjeta"
		)
		for other_index: int in range(index + 1, controls.size()):
			_check(
				not control.get_global_rect().intersects(controls[other_index].get_global_rect()),
				context + ": " + control.name + " separado de " + controls[other_index].name
			)
		if control is Label:
			_check(
				control.size.y >= control.get_minimum_size().y,
				context + ": texto completo en " + control.name
			)
