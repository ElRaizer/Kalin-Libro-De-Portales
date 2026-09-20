extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	await _validate_world4_runtime()
	await _validate_world5_runtime()
	await _validate_book_runtime()
	if failures.is_empty():
		print("Validación de aprendizaje y libro: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

func _validate_world4_runtime() -> void:
	var packed := load("res://scenes/world4/Level4_YoQuiero.tscn") as PackedScene
	if packed == null:
		failures.append("No se pudo cargar el Mundo 4")
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	if level.round_plan.size() != level.CHALLENGES.size() * 2:
		failures.append("Mundo 4 no creó sus fases guiada y de recuerdo")
	if level.food_buttons.size() != 5 or level.modifier_buttons.size() != 3:
		failures.append("Mundo 4 no creó todas las opciones de alimento y cualidad")
	var challenge: Dictionary = level._current_challenge()
	level._select_food(challenge.food)
	level._select_modifier(challenge.modifier)
	if level.serve_button.disabled:
		failures.append("Mundo 4 no habilita el hechizo al completar ambos espacios")
	if level.selected_food != challenge.food or level.selected_modifier != challenge.modifier:
		failures.append("Mundo 4 no conserva la selección del jugador")
	level.queue_free()
	await process_frame

func _validate_world5_runtime() -> void:
	var packed := load("res://scenes/world5/Level5_PortalDeRegreso.tscn") as PackedScene
	if packed == null:
		failures.append("No se pudo cargar el Mundo 5")
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	if level.option_buttons.size() != 3:
		failures.append("Mundo 5 debe mostrar tres respuestas por fragmento")
	if int(level.portal_energy.max_value) != level.CHALLENGES.size():
		failures.append("La energía del portal no representa todos los fragmentos")
	var current: Dictionary = level.CHALLENGES[level.challenge_index]
	if current.correct not in current.options:
		failures.append("El primer fragmento del Mundo 5 no puede resolverse")
	level.queue_free()
	await process_frame

func _validate_book_runtime() -> void:
	var manager: Node = root.get_node("GameManager")
	var original_words: Dictionary = manager.words_learned.duplicate(true)
	manager.words_learned = {
		"Peek'": manager.VOCABULARY["Peek'"].duplicate(),
		"mayak": manager.VOCABULARY["mayak"].duplicate(),
		"ja'": manager.VOCABULARY["ja'"].duplicate(),
	}
	var packed := load("res://scenes/ui/LibroHechizos.tscn") as PackedScene
	if packed == null:
		failures.append("No se pudo cargar el Libro de Hechizos")
		manager.words_learned = original_words
		return
	var book := packed.instantiate()
	root.add_child(book)
	await process_frame
	book.show_book()
	if book._entries.size() != 3 or book._spread_count() != 2:
		failures.append("El Libro no distribuye dos entradas por pliego")
	if not book.left_page.get_node("Content/Illustration/ContextSprite").visible:
		failures.append("El Libro no muestra la ilustración contextual disponible")
	if not book.right_page.get_node("Content/Illustration/Placeholder").visible:
		failures.append("El Libro no reserva espacio para ilustraciones futuras")
	book._next_spread()
	if book._spread_index != 1 or not book.next_button.disabled:
		failures.append("La navegación entre páginas del Libro no respeta sus límites")
	book.queue_free()
	manager.words_learned = original_words
	await process_frame
