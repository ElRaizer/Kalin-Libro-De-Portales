extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	await _validate_story_runtime()
	await _validate_story_choice_runtime()
	await _validate_cinematic_runtime()
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

## Recorre el primer capítulo: conocer a todos los animales habilita el
## avance y en ADIVINAR solo la respuesta correcta lo permite.
func _validate_story_runtime() -> void:
	var packed := load("res://scenes/world1/Historia1_IslaAnimales.tscn") as PackedScene
	if packed == null:
		failures.append("No se pudo cargar el primer capítulo de historia")
		return
	var story := packed.instantiate()
	root.add_child(story)
	await process_frame
	if story.beat_index != 0:
		failures.append("La historia no empezó en su primer momento")
	var checked_meet := false
	var checked_guess := false
	while story.beat_index < story.beats.size() - 1:
		story._next_beat()
		var beat: StoryBeat = story.current_beat()
		if beat.kind == StoryBeat.Kind.CONOCER and not checked_meet:
			checked_meet = true
			if story._waiting_to_continue:
				failures.append("La historia avanza antes de conocer a los animales")
			for word: String in beat.actors:
				(story.actor_buttons[word] as Button).pressed.emit()
			if not story._waiting_to_continue:
				failures.append("Conocer a todos los animales no habilita el avance")
		elif beat.kind == StoryBeat.Kind.ADIVINAR and not checked_guess:
			checked_guess = true
			for word: String in beat.actors:
				if word != beat.target_word:
					(story.actor_buttons[word] as Button).pressed.emit()
					break
			if story._waiting_to_continue:
				failures.append("Una respuesta incorrecta no debe avanzar la historia")
			(story.actor_buttons[beat.target_word] as Button).pressed.emit()
			if not story._waiting_to_continue:
				failures.append("La respuesta correcta no habilita el avance")
	if not checked_meet or not checked_guess:
		failures.append("El primer capítulo debe incluir los momentos CONOCER y ADIVINAR")
	story.queue_free()
	await process_frame

## En ELEGIR, un error revela el significado de la palabra elegida y solo la
## respuesta correcta muestra la frase y permite continuar.
func _validate_story_choice_runtime() -> void:
	var packed := load("res://scenes/world2/Historia6_ObjetosALaMedida.tscn") as PackedScene
	if packed == null:
		failures.append("No se pudo cargar el capítulo 6")
		return
	var story := packed.instantiate()
	root.add_child(story)
	await process_frame
	while story.current_beat().kind != StoryBeat.Kind.ELEGIR:
		story._next_beat()
	await process_frame
	var beat: StoryBeat = story.current_beat()
	var wrong_button: Button = null
	var right_button: Button = null
	for button: Node in story.choices_box.get_children():
		if (button as Button).text.ends_with(beat.target_word):
			right_button = button
		elif wrong_button == null:
			wrong_button = button
	if wrong_button == null or right_button == null:
		failures.append("ELEGIR no creó las opciones del capítulo 6")
	else:
		wrong_button.pressed.emit()
		if story._waiting_to_continue or not wrong_button.text.contains("\n"):
			failures.append("Un error en ELEGIR debe revelar el significado sin avanzar")
		right_button.pressed.emit()
		if not story._waiting_to_continue or story.choices_box.visible:
			failures.append("La respuesta correcta en ELEGIR no muestra la frase ni permite avanzar")
	story.queue_free()
	await process_frame

## La primera cinemática activa lluvia y páginas, muestra su cartel, avanza sola,
## acuesta a Kalin en la orilla y lo levanta al despertar.
func _validate_cinematic_runtime() -> void:
	var packed := load("res://scenes/world1/Cine1_NocheHuracan.tscn") as PackedScene
	if packed == null:
		failures.append("No se pudo cargar la cinemática del huracán")
		return
	var cine := packed.instantiate()
	root.add_child(cine)
	await process_frame
	var rain := cine.get_node("Effects/Lluvia") as CPUParticles2D
	var pages := cine.get_node("Effects/Paginas") as CPUParticles2D
	if not rain.emitting or pages.emitting:
		failures.append("El primer momento del huracán debe tener lluvia y no páginas")
	if cine.kalin.visible:
		failures.append("Kalin no debe verse durante la noche del huracán")
	if cine.title_label.text != "Prólogo" or cine.subtitle_label.text != "La noche del huracán":
		failures.append("La cinemática no muestra su cartel de título")
	if cine.auto_timer.is_stopped():
		failures.append("Un momento con auto_advance debe programar el avance automático")
	cine._complete_text()
	cine._on_auto_timer_timeout()
	if cine.beat_index != 1:
		failures.append("El avance automático no pasó al siguiente momento")
	if not pages.emitting:
		failures.append("El segundo momento del huracán debe activar las páginas")
	while cine.beat_index < 3:
		cine._next_beat()
	if not cine._kalin_sleeping or absf(cine.kalin.rotation + cine.SLEEP_ANGLE) > 0.01:
		failures.append("Kalin debe estar acostado al amanecer")
	if rain.emitting:
		failures.append("La lluvia debe detenerse al amanecer")
	cine._next_beat()
	await create_timer(cine.STAND_UP_SECONDS + 0.2).timeout
	if cine._kalin_sleeping or absf(cine.kalin.rotation) > 0.01:
		failures.append("Kalin no se levantó al despertar")
	cine.queue_free()
	await process_frame

	# Cinemática final: Kalin cruza el portal y desaparece.
	packed = load("res://scenes/world5/Cine3_RegresoACasa.tscn") as PackedScene
	var ending := packed.instantiate()
	root.add_child(ending)
	await process_frame
	ending._next_beat()
	if ending.kalin.z_index != 1:
		failures.append("Kalin debe pasar por delante de los animales al cruzar el portal")
	await create_timer(ending.CROSS_SECONDS + 0.2).timeout
	if ending.kalin.modulate.a > 0.05 or ending.kalin.scale.x > ending.CROSS_SCALE + 0.05:
		failures.append("Kalin no se hizo pequeño ni desapareció dentro del portal")
	ending.queue_free()
	await process_frame

	# Un momento con página recuperada hace saltar a Kalin sin configuración extra.
	var chapter := (load("res://scenes/world1/Historia2_VocesBosque.tscn") as PackedScene).instantiate()
	root.add_child(chapter)
	await process_frame
	var celebrating: StoryBeat = null
	for beat: StoryBeat in chapter.beats:
		if beat.celebrate_page:
			celebrating = beat
	if celebrating == null or chapter._effective_motion(celebrating) != StoryBeat.KalinMotion.SALTA:
		failures.append("Kalin debe saltar de alegría cuando recupera una página")
	chapter.queue_free()
	await process_frame

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
	if not level.completion.next_pressed.is_connected(level._on_epilogue_pressed):
		failures.append("Cerrar la aventura debe abrir el epílogo de la historia")
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
