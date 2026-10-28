## Mundo 4 · Las piedras que cuentan: numeración de puntos y barras, contenido de
## autor, guardado, recorrido completo, errores que enseñan y la sección Números
## del Libro de Hechizos.
extends ProjectTest

const NUMBERS: Array[String] = ["jun", "ka'a", "óox", "kan", "jo'o"]

var manager: Node


func _initialize() -> void:
	await process_frame
	manager = root.get_node("GameManager")
	manager._save_repository = repository_for("counting")
	manager.reset_save()
	_numeral_rules()
	_vocabulary_and_content()
	_session_rules()
	await _wrong_answers_teach()
	await _resume_keeps_progress()
	await _full_level()
	await _book_numbers()
	finish("Validación de los números")


## Un punto vale 1, una barra vale 5 y cinco puntos se reúnen en una barra.
func _numeral_rules() -> void:
	for value: int in range(1, MayaNumeral.max_value() + 1):
		var bars: int = MayaNumeral.bars_of(value)
		var dots: int = MayaNumeral.dots_of(value)
		check(dots <= MayaNumeral.MAX_DOTS, "Un numeral nunca muestra más de cuatro puntos")
		check(
			MayaNumeral.value_of(bars, dots) == value, "El numeral de %d vale %d" % [value, value]
		)
	check(MayaNumeral.add_dot(0, 4) == Vector2i(1, 0), "El quinto punto se vuelve una barra")
	check(MayaNumeral.add_dot(1, 2) == Vector2i(1, 3), "Un punto suma uno")
	check(
		MayaNumeral.add_bar(MayaNumeral.MAX_BARS, 0) == Vector2i(MayaNumeral.MAX_BARS, 0),
		"Las barras tienen un límite"
	)


## Los números están en el vocabulario canónico, con valor, sección propia del
## libro, ilustración de puntos y barras, y el contenido de autor es válido.
func _vocabulary_and_content() -> void:
	for index: int in range(NUMBERS.size()):
		var word: String = NUMBERS[index]
		check(VocabularyCatalog.number_value(word) == index + 1, "«%s» vale %d" % [word, index + 1])
		check(VocabularyCatalog.book_category(word) == 6, "«%s» va en la sección Números" % word)
		check(
			not VocabularyCatalog.entry(word).has("emoji"),
			"Los números se ilustran con puntos y barras, sin emoji: " + word
		)
		check(
			manager.get_visual_texture(word) != null,
			"«%s» tiene su ilustración de puntos y barras" % word
		)
		check(word in VocabularyCatalog.learnable_keys(), "«%s» se puede aprender" % word)
	var content: CountingSet = load("res://data/exercises/world4_counting.tres") as CountingSet
	check(content != null, "Existe el contenido del tianguis")
	if content == null:
		return
	check(
		content.get_configuration_issues().is_empty(),
		"El contenido del tianguis está completo: " + "; ".join(content.get_configuration_issues())
	)
	var kinds: Array[int] = []
	var taught: Array[String] = []
	for step: CountingRound in content.rounds:
		if step.kind not in kinds:
			kinds.append(step.kind)
		for word: String in step.numbers + [step.number]:
			if not word.is_empty() and word not in taught:
				taught.append(word)
	check(kinds.size() == CountingRound.Kind.size(), "El nivel recorre las cinco fases")
	for word: String in NUMBERS:
		check(word in taught, "El nivel enseña «%s»" % word)
	var counts_things: bool = false
	var counts_animals: bool = false
	for step: CountingRound in content.rounds:
		counts_things = counts_things or step.answer.ends_with("p'éel")
		counts_animals = counts_animals or step.answer.ends_with("túul")
	check(counts_things and counts_animals, "Se practican -p'éel (cosas) y -túul (animales)")


## La canasta detecta faltantes, sobrantes y cosas que no se pidieron, y el
## checkpoint descarta datos inválidos.
func _session_rules() -> void:
	var market: CountingRound = CountingRound.new()
	market.kind = CountingRound.Kind.MARKET
	market.number = "óox"
	market.item = "ja'as"
	market.distractor = "K'úum"
	var session: CountingSession = CountingSession.new()
	var goods: Array[String] = session.stall(market)
	check(goods == session.stall(market), "El puesto es estable con la misma semilla")
	var wanted: Array[int] = []
	var other: int = -1
	for index: int in range(goods.size()):
		if goods[index] == market.item:
			wanted.append(index)
		elif other < 0:
			other = index
	session.toggle_basket(wanted[0])
	check(session.basket_result(market) == "few", "Con un plátano faltan dos")
	session.toggle_basket(wanted[1])
	session.toggle_basket(wanted[2])
	check(session.basket_result(market) == "ok", "Tres plátanos resuelven el pedido")
	session.toggle_basket(wanted[3])
	check(session.basket_result(market) == "many", "Cuatro plátanos son demasiados")
	session.toggle_basket(wanted[3])
	session.toggle_basket(other)
	check(session.basket_result(market) == "other", "Una calabaza no se pidió")
	var restored: CountingSession = CountingSession.new()
	restored.restore(
		{
			"round": 0,
			"waiting": true,
			"basket": [1, 1, -3, 99, "x", INF],
			"bars": 40,
			"dots": -2,
			"layout_seed": 77
		},
		[market]
	)
	check(restored.basket == [1], "El checkpoint descarta índices repetidos o fuera del puesto")
	check(
		restored.bars == MayaNumeral.MAX_BARS and restored.dots == 0, "Barras y puntos se limitan"
	)
	check(not restored.waiting, "Una canasta incompleta no se da por resuelta al continuar")


## Equivocarse no avanza: explica el error y cuenta como intento con fallo.
func _wrong_answers_teach() -> void:
	var level: Node = await _open_level({})
	CountingSolver.solve_round(level)
	level._on_action_pressed()
	var build: CountingRound = level._round()
	check(build.kind == CountingRound.Kind.BUILD, "Después de la estela se construye un número")
	level._on_dot_pressed()
	level._on_action_pressed()
	check(not level._session.waiting, "Un numeral incorrecto no se acepta")
	check(level._session.attempt.mistakes == 1, "El error queda registrado en el intento")
	check(
		level.feedback_label.text.contains("agrega piezas"),
		"El aviso explica qué le falta al numeral"
	)
	for step: int in range(4):
		level._on_dot_pressed()
	check(
		level._session.bars == 1 and level._session.dots == 0,
		"Cinco granos sobre la tablilla se vuelven una varita"
	)
	while level._round().kind != CountingRound.Kind.FRIENDS:
		CountingSolver.solve_round(level)
		level._on_action_pressed()
	var friends: CountingRound = level._round()
	check(not level.phrase_label.visible, "La frase con la respuesta no se muestra antes de contar")
	for button: Button in level._option_buttons:
		var answer: String = str(button.get_meta("answer", ""))
		if button.visible and answer.ends_with("p'éel"):
			level._on_option_pressed(button)
			break
	check(
		level.feedback_label.text.contains("-túul"),
		"Contar animales con -p'éel recuerda que se usa -túul"
	)
	CountingSolver.solve_round(level)
	check(
		level._session.waiting and level.phrase_label.text == friends.phrase,
		"Al acertar se muestra la frase completa"
	)
	await _close(level)


## Salir a media ronda y volver conserva la tablilla y la canasta.
func _resume_keeps_progress() -> void:
	var level: Node = await _open_level({})
	CountingSolver.solve_round(level)
	level._on_action_pressed()
	level._on_bar_pressed()
	var state: Dictionary = level.get_checkpoint_state()
	await _close(level)
	var resumed: Node = await _open_level(state)
	check(resumed._round().kind == CountingRound.Kind.BUILD, "Se continúa en la misma ronda")
	check(
		resumed._session.bars == 1 and resumed.tablet_numeral.bars == 1,
		"La varita puesta sigue sobre la tablilla"
	)
	while resumed._round().kind != CountingRound.Kind.MARKET:
		CountingSolver.solve_round(resumed)
		resumed._on_action_pressed()
	resumed._stall_buttons[0].button_pressed = true
	var market_state: Dictionary = resumed.get_checkpoint_state()
	await _close(resumed)
	var again: Node = await _open_level(market_state)
	check(again._session.basket == [0], "La canasta conserva lo que ya se puso")
	check(again._stall_buttons[0].button_pressed, "El puesto muestra lo que está en la canasta")
	await _close(again)


## Recorrer todo el nivel aprende los cinco números, lo completa y continúa al
## capítulo del portal.
func _full_level() -> void:
	manager.reset_save()
	var level: Node = await _open_level({})
	CountingSolver.solve_level(level)
	check(manager.is_level_completed(4, 2), "Terminar el tianguis completa el Mundo 4 · Nivel 2")
	check(level.completion.visible, "Se muestra la celebración del nivel")
	for word: String in NUMBERS:
		check(manager.has_learned_word(word), "Se aprendió «%s»" % word)
	level.completion.next_pressed.emit()
	await scene_changed
	await process_frame
	check(
		current_scene.scene_file_path == GameContent.SCENE_PATHS.world4_story1,
		"Después de contar sigue el capítulo del portal"
	)
	var story: Node = load(GameContent.SCENE_PATHS.world4_story2).instantiate()
	check(story.next_scene_key == "world4_level2", "El capítulo del tianguis abre el nivel")
	story.free()


## La sección Números del libro muestra sólo los números aprendidos.
func _book_numbers() -> void:
	var level: Node = await _open_level({})
	var book: Node = level.libro
	book.show_book()
	await book.motion.opened
	book._select_category(6)
	check(book._entries == NUMBERS, "La sección Números muestra del uno al cinco en orden")
	book.hide_book()
	await book.motion.closed
	await _close(level)


func _open_level(state: Dictionary) -> Node:
	manager.session.scene_states["world4_level2"] = state.duplicate(true)
	change_scene_to_file(GameContent.SCENE_PATHS.world4_level2)
	await scene_changed
	await process_frame
	return current_scene


func _close(level: Node) -> void:
	manager.session.scene_states.erase("world4_level2")
	level.queue_free()
	current_scene = null
	await process_frame
