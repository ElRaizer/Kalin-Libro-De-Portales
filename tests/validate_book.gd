## Regresión de navegación, pausa, foco y apertura/cierre interrumpibles.
## Con --capture=<carpeta> guarda los estados de las mismas animaciones.
extends SceneTree

var manager: Node
var failures: Array[String] = []
var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _scene(key: String) -> void:
	change_scene_to_file(manager.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame

func _settle(book: Node) -> void:
	for frame: int in range(240):
		if not book.motion.busy and not book._turning:
			return
		await process_frame
	_check(false, "La transición del libro debe finalizar")

func _capture(name: String) -> void:
	if output.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	await process_frame

func _run() -> void:
	manager = root.get_node("GameManager")
	manager._save_repository = load("res://scripts/data/SaveRepository.gd").new("user://book_validation.json")
	manager.scene_states.clear()
	manager.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	manager.words_learned = manager.VOCABULARY.duplicate(true)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			output = argument.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(output)
	await _scene("world3_level1")
	var level: Node = current_scene
	var book: Node = level.libro
	var source: Button = level.get_node("UI/TopBar/Bar/BookButton")
	level.cast_button.grab_focus()
	book._new_word = "chich"
	source.pressed.emit()
	_check(paused and book.visible and book.motion.busy, "El libro debe pausar desde el inicio del viaje")
	_check(book._source_rect == source.get_global_rect(), "El viaje debe partir del botón de esta pantalla")
	_check(book.motion.cover.position.is_equal_approx(source.get_global_rect().get_center() - book.motion.cover.pivot_offset), "La cubierta debe comenzar sobre el botón")
	await create_timer(0.13).timeout
	await _capture("01_viaje")
	await create_timer(0.14).timeout
	await _capture("02_cubierta")
	await create_timer(0.10).timeout
	await _capture("03_apertura")
	await _settle(book)
	_check(book.motion.book.scale.is_equal_approx(Vector2.ONE) and not book.motion.cover.visible, "El texto debe terminar a escala completa sin cubierta superpuesta")
	await create_timer(0.8).timeout
	_check(book.left_page.self_modulate.is_equal_approx(Color.WHITE) and book.right_page.self_modulate.is_equal_approx(Color.WHITE), "El brillo de descubrimiento debe terminar sin bucle")
	await _capture("04_abierto")
	var start: int = book._spread_index
	await _key(KEY_RIGHT)
	await _settle(book)
	_check(book._spread_index == start + 1, "La flecha derecha debe cambiar de páginas aunque un botón tenga el foco")
	await _key(KEY_LEFT)
	await _settle(book)
	_check(book._spread_index == start, "La flecha izquierda debe volver a las páginas anteriores")
	book.next_button.pressed.emit()
	book._next_spread()
	book._previous_spread()
	await _settle(book)
	_check(book._spread_index == start + 1, "Los clics rápidos deben producir un solo cambio de páginas")
	await _capture("05_paginas")
	book._select_category(1)
	await _settle(book)
	_check(book._category == 1 and book._spread_index == 0, "Una categoría debe abrir su primera pareja de páginas")
	book.category_buttons[1].button_pressed = false
	book.category_buttons[1].pressed.emit()
	_check(book.category_buttons[1].button_pressed, "Pulsar la categoría actual debe conservar la pestaña seleccionada")
	book._select_category(0)
	await _settle(book)
	_check(book.page_label.text == "Páginas 1–2 de 30", "La numeración debe contar entradas visibles, no parejas")
	var audio: Button = book.left_page.get_node("Content/AudioButton")
	audio.pressed.emit()
	_check(not audio.disabled and book.audio_notice.visible and not book.audio_player.playing, "Sin grabación el botón debe explicar la ausencia y permanecer silencioso")
	await _capture("06_audio_pendiente")
	book.hide_book()
	book.hide_book()
	_check(paused and book.visible, "El mundo debe seguir pausado hasta terminar el cierre")
	await create_timer(0.2).timeout
	await _capture("07_cierre")
	await _settle(book)
	_check(not paused and not book.visible and level.cast_button.has_focus(), "Cerrar debe reanudar y restaurar el foco anterior")
	_check(book.motion.cover.position.is_equal_approx(source.get_global_rect().get_center() - book.motion.cover.pivot_offset), "La cubierta debe volver al botón de origen")
	book.show_book(source)
	await _key(KEY_ESCAPE)
	await _key(KEY_ESCAPE)
	await _settle(book)
	_check(not paused and not book.visible and not root.get_node("PauseMenu").shade.visible, "Escape durante la apertura debe cerrar una vez sin abrir la pausa")
	paused = true
	book.show_book(source)
	await _settle(book)
	book.hide_book()
	await _settle(book)
	_check(paused, "Cerrar un libro abierto sobre una pausa previa debe conservarla")
	paused = false
	manager.words_learned.clear()
	book.show_book(source)
	await _settle(book)
	_check(book.empty_label.visible and book.previous_button.disabled and book.next_button.disabled, "La sección vacía debe conservar sus límites")
	_check(book._visible_words == ["", ""], "Una sección vacía no debe conservar audio de páginas anteriores")
	book.hide_book()
	await _settle(book)
	manager.words_learned = {"Peek'": manager.VOCABULARY["Peek'"]}
	book._category = 0
	book.show_book(source)
	await _settle(book)
	_check(book.page_label.text == "Página 1 de 1" and book.right_page.get_node("LockedPage").visible, "Una cantidad impar debe terminar con página en blanco y numeración correcta")
	book.hide_book()
	await _settle(book)
	manager.words_learned = manager.VOCABULARY.duplicate(true)
	book.show_book(source)
	await _settle(book)
	for category: int in range(6):
		book._select_category(category)
		await _settle(book)
		for spread: int in range(book._spread_count()):
			book._spread_index = spread
			book._render_spread()
			await process_frame
			for page: Panel in [book.left_page, book.right_page]:
				if not page.get_node("Content").visible:
					continue
				var button := page.get_node("Content/AudioButton") as Button
				_check(button.get_global_rect().end.y <= page.get_global_rect().end.y - 10.0, "El texto y el audio deben caber en la página: " + str(book._visible_words))
		if category == 5:
			await _capture("08_cortesia")
	book.hide_book()
	await _settle(book)
	for entry: Array in [
		["main_menu", "UI/Center/VBox/BookBtn"],
		["world1_level1", "UI/LevelHeader/Bar/BookButton"],
		["world2_level1", "UI/TopBar/BookBtn"],
		["world4_level1", "UI/LevelHeader/Bar/BookButton"],
		["world5_level1", "UI/LevelHeader/Bar/BookButton"],
		["world4_mission1", "UI/BookButton"],
	]:
		await _scene(entry[0])
		book = current_scene.get_node("LibroHechizos")
		source = current_scene.get_node(entry[1])
		source.pressed.emit()
		_check(book._source_button == source, "Cada pantalla debe proporcionar su botón real: " + entry[0])
		await _settle(book)
		book._next_spread()
		book.hide_book()
		await _settle(book)
		_check(not paused and not book.visible, "Cerrar durante el cambio de página debe recuperar el juego: " + entry[0])
	# Salir de la escena durante una transición tampoco puede dejar la pausa activa.
	book.show_book(source)
	await _scene("main_menu")
	_check(not paused, "Cambiar de escena debe liberar la pausa que pertenecía al libro")
	if failures.is_empty():
		print("Validación del libro animado: OK")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
