@tool
## Mundo 4, nivel 2 — Las piedras que cuentan.
## Kalin aprende los números del uno al cinco en el tianguis de la aldea: los
## conoce en una estela, los forma con cacao y varitas (numeración de puntos y
## barras), llena canastas (-p'éel para cosas), cuenta a sus amigos (-túul para
## animales) y al final los escribe de memoria. Las reglas viven en
## CountingSession; este controlador sólo presenta y conecta la entrada.
extends Node2D

const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")
## Notas pentatónicas (semitonos) para que cada grano suene un poco más agudo.
const COUNT_NOTES: Array[int] = [0, 2, 4, 7, 9, 12, 14]
const PHASE_NAMES: Array[String] = ["Conocer", "Construir", "Tianguis", "¿Cuántos?", "Recuerdo"]
const STALL_BUTTON_SIZE := Vector2(96, 78)
const COUNT_ART_SIZE := Vector2(88, 72)
## Tamaño de cada cosa dentro de la canasta: se apilan sobre su boca.
const BASKET_ART_SIZE := Vector2(62, 50)

@export var content: CountingSet
@export var count_texture_size: Vector2 = COUNT_ART_SIZE

var guide: LearningGuide
var _session: CountingSession = CountingSession.new()
var _help_stage: int = 0
var _navigating: bool = false
var _stall_buttons: Array[Button] = []
var _option_buttons: Array[Button] = []

@onready var header: LevelHeader = $UI/LevelHeader
@onready var phase_label: Label = $UI/RequestPanel/Content/PhaseLabel
@onready var animal_sprite: TextureRect = $UI/RequestPanel/Content/AnimalSprite
@onready var animal_label: Label = $UI/RequestPanel/Content/AnimalLabel
@onready var phrase_label: Label = $UI/RequestPanel/Content/PhraseLabel
@onready var request_label: Label = $UI/RequestPanel/Content/RequestLabel
@onready var stele: Control = $UI/StagePanel/Stele
@onready var stele_numbers: HBoxContainer = $UI/StagePanel/Stele/Numbers
@onready var build: Control = $UI/StagePanel/Build
@onready var tablet_numeral: NumeralView = $UI/StagePanel/Build/Tablet/Numeral
@onready var target_label: Label = $UI/StagePanel/Build/TargetLabel
@onready var dot_button: Button = $UI/StagePanel/Build/Pieces/DotButton
@onready var bar_button: Button = $UI/StagePanel/Build/Pieces/BarButton
@onready var clear_button: Button = $UI/StagePanel/Build/Pieces/ClearButton
@onready var market: Control = $UI/StagePanel/Market
@onready var stall_grid: GridContainer = $UI/StagePanel/Market/Stall
@onready var basket_row: HFlowContainer = $UI/StagePanel/Market/Basket/Goods
@onready var friends: Control = $UI/StagePanel/Friends
@onready var crowd: HBoxContainer = $UI/StagePanel/Friends/Crowd
@onready var options_grid: GridContainer = $UI/StagePanel/Options
@onready var recall_box: Control = $UI/StagePanel/Recall
@onready var picture: HBoxContainer = $UI/StagePanel/Recall/Picture
@onready var recall: RecallPanel = $UI/StagePanel/Recall/RecallPanel
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var _feedback_color: Color = feedback_label.get_theme_color("font_color")
@onready var mission_progress: MissionProgress = $UI/MissionProgress
@onready var action_button: Button = $UI/ActionButton
@onready var completion: CompletionOverlay = $UI/CompletionOverlay
@onready var libro: CanvasLayer = $LibroHechizos


func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues: PackedStringArray = get_configuration_issues()
	if not issues.is_empty():
		push_error("Configuración incompleta: " + "; ".join(issues))
		return
	header.menu_pressed.connect(_on_menu_pressed)
	header.book_pressed.connect(_on_book_pressed)
	completion.next_pressed.connect(_on_next_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	action_button.pressed.connect(_on_action_pressed)
	dot_button.pressed.connect(_on_dot_pressed)
	bar_button.pressed.connect(_on_bar_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	for index: int in range(stele_numbers.get_child_count()):
		var button: Button = stele_numbers.get_child(index) as Button
		button.pressed.connect(_on_stele_number_pressed.bind(index))
	for index: int in range(options_grid.get_child_count()):
		var option: Button = options_grid.get_child(index) as Button
		option.pressed.connect(_on_option_pressed.bind(option))
		_option_buttons.append(option)
	recall.submitted.connect(_on_action_pressed)
	recall.practice_requested.connect(_practice_with_cards)
	recall.support_used.connect(mark_learning_help)
	recall.answer_changed.connect(_on_recall_changed)
	guide = LearningGuide.install(self, $UI/LevelHeader/Bar, _show_help)
	var state: Dictionary = GameManager.get_scene_state(self)
	if not state.has("layout_seed"):
		state.layout_seed = randi_range(1, 2000000000)
	_session.restore(state, content.rounds)
	_show_round(true)


func _round() -> CountingRound:
	return content.rounds[_session.round_index]


# ─── Rondas ──────────────────────────────────────────────────────────────────
func _show_round(restoring: bool = false) -> void:
	guide.stop()
	_help_stage = 0
	if _session.is_finished(content.rounds.size()):
		_finish_level()
		return
	var current: CountingRound = _round()
	var continuing: bool = _session.begin(current)
	for panel: Control in [stele, build, market, friends, recall_box, options_grid]:
		panel.hide()
	phase_label.text = PHASE_NAMES[current.kind]
	animal_label.text = current.requester
	animal_sprite.texture = GameManager.get_visual_texture(current.requester)
	request_label.text = current.request
	request_label.visible = current.guided and not current.request.is_empty()
	phrase_label.text = current.phrase
	# En «¿Cuántos?» y en el recuerdo la frase es la respuesta: se muestra al acertar.
	phrase_label.visible = (
		not current.phrase.is_empty()
		and current.kind not in [CountingRound.Kind.FRIENDS, CountingRound.Kind.RECALL]
	)
	_set_feedback(_instruction(current), _feedback_color)
	match current.kind:
		CountingRound.Kind.STELE:
			_show_stele(current)
		CountingRound.Kind.BUILD:
			_show_build(current)
		CountingRound.Kind.MARKET:
			_show_market(current)
		CountingRound.Kind.FRIENDS:
			_show_friends(current)
		CountingRound.Kind.RECALL:
			_show_recall(current, continuing and restoring)
	_update_progress()
	if _session.waiting:
		_render_success(current, false)
	elif _session.round_index == 0 and "numbers" not in GameManager.session.tutorials_seen:
		call_deferred("_show_help")
	GameManager.checkpoint(self)


func _instruction(current: CountingRound) -> String:
	match current.kind:
		CountingRound.Kind.STELE:
			return "Toca cada número de la estela."
		CountingRound.Kind.BUILD:
			return "Pon granos (1) y varitas (5) hasta formar el número."
		CountingRound.Kind.MARKET:
			return "Pon en la canasta lo que te pidieron."
		CountingRound.Kind.FRIENDS:
			return "Cuenta a los amigos y elige la respuesta."
	return "Escribe cuántos hay y qué son."


func _show_stele(current: CountingRound) -> void:
	stele.show()
	for index: int in range(stele_numbers.get_child_count()):
		var button: Button = stele_numbers.get_child(index) as Button
		var exists: bool = index < current.numbers.size()
		button.visible = exists
		if exists:
			var word: String = current.numbers[index]
			button.icon = GameManager.get_visual_texture(word)
			button.text = word if word in _session.met else "?"
			button.tooltip_text = "Toca para aprender este número"
	action_button.text = "Continuar →"
	action_button.disabled = true
	(stele_numbers.get_child(0) as Button).grab_focus()


func _show_build(current: CountingRound) -> void:
	build.show()
	target_label.text = (
		"%s · %s" % [current.number, VocabularyCatalog.entry(current.number).spanish]
		if current.guided
		else current.number
	)
	tablet_numeral.set_pieces(_session.bars, _session.dots)
	bar_button.disabled = false
	dot_button.disabled = false
	clear_button.disabled = false
	action_button.text = "Comprobar ✦"
	action_button.disabled = false
	phrase_label.text = current.number
	phrase_label.visible = true
	dot_button.grab_focus()


func _show_market(current: CountingRound) -> void:
	market.show()
	for button: Button in _stall_buttons:
		button.queue_free()
	_stall_buttons.clear()
	var goods: Array[String] = _session.stall(current)
	for index: int in range(goods.size()):
		var button: Button = Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = STALL_BUTTON_SIZE
		button.icon = GameManager.get_visual_texture(goods[index])
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.theme_type_variation = &"KalinNounButton"
		button.tooltip_text = goods[index]
		button.set_meta("good", goods[index])
		button.set_pressed_no_signal(index in _session.basket)
		button.toggled.connect(_on_stall_toggled.bind(index))
		stall_grid.add_child(button)
		_stall_buttons.append(button)
	_refresh_basket()
	action_button.text = "Entregar ✦"
	action_button.disabled = false
	_stall_buttons[0].grab_focus()


func _show_friends(current: CountingRound) -> void:
	friends.show()
	_fill_counted(crowd, current.item, VocabularyCatalog.number_value(current.number))
	_show_options(current, options_grid)
	action_button.text = "Continuar →"
	action_button.disabled = true


func _show_recall(current: CountingRound, continuing: bool) -> void:
	recall_box.show()
	_fill_counted(picture, current.item, VocabularyCatalog.number_value(current.number))
	if _session.cards:
		_practice_with_cards()
		return
	var saved: Dictionary = GameManager.get_scene_state(self).get("scaffold", {})
	ExerciseRecallFlow.prepare(
		recall,
		["¿Cuántos?", "¿Qué son?"],
		[current.answer, current.item],
		_session.attempt,
		saved if continuing and saved is Dictionary else {}
	)
	recall.first.text = _session.answer
	recall.second.text = _session.item
	action_button.text = "Comprobar ✦"
	action_button.disabled = false


func _show_options(current: CountingRound, grid: GridContainer) -> void:
	var options: Array[String] = _session.shuffled_options(current)
	for index: int in range(_option_buttons.size()):
		var button: Button = _option_buttons[index]
		button.visible = index < options.size()
		if button.visible:
			button.text = options[index]
			button.set_meta("answer", options[index])
			button.disabled = false
	grid.show()
	_option_buttons[0].grab_focus()


## Muestra N dibujos de lo que se cuenta, para que el niño cuente.
func _fill_counted(row: HBoxContainer, word: String, count: int) -> void:
	for child: Node in row.get_children():
		child.queue_free()
	for index: int in range(count):
		var art: TextureRect = TextureRect.new()
		art.texture = GameManager.get_visual_texture(word)
		art.custom_minimum_size = count_texture_size
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(art)


# ─── Entrada ─────────────────────────────────────────────────────────────────
func _on_stele_number_pressed(index: int) -> void:
	var current: CountingRound = _round()
	if current.kind != CountingRound.Kind.STELE or index >= current.numbers.size():
		return
	guide.stop()
	var word: String = current.numbers[index]
	var button: Button = stele_numbers.get_child(index) as Button
	if _session.meet(current, word):
		AudioManager.play_sfx("palabra_anotada")
		GameManager.learn_word(word)
	else:
		AudioManager.play_sfx("animal_tocar")
	button.text = word
	CharacterReaction.play(button)
	var entry: Dictionary = VocabularyCatalog.entry(word)
	_set_feedback(
		"%s · %s  (%d)" % [word, entry.spanish, VocabularyCatalog.number_value(word)],
		_feedback_color
	)
	if _session.is_solved(current):
		_resolve(current)
	else:
		GameManager.checkpoint(self)


func _on_dot_pressed() -> void:
	if _session.waiting:
		return
	guide.stop()
	var merged: bool = _session.add_dot()
	tablet_numeral.set_pieces(_session.bars, _session.dots)
	if merged:
		AudioManager.play_sfx("chispas_magia")
		_set_feedback("¡Cinco granos se juntan en una varita!", _feedback_color)
	else:
		var note: int = COUNT_NOTES[clampi(_session.numeral_value() - 1, 0, COUNT_NOTES.size() - 1)]
		AudioManager.play_sfx("camino_trazo", pow(2.0, note / 12.0))
	GameManager.checkpoint(self)


func _on_bar_pressed() -> void:
	if _session.waiting:
		return
	guide.stop()
	_session.add_bar()
	tablet_numeral.set_pieces(_session.bars, _session.dots)
	AudioManager.play_sfx("palabra_soltar")
	GameManager.checkpoint(self)


func _on_clear_pressed() -> void:
	if _session.waiting:
		return
	_session.clear_numeral()
	tablet_numeral.set_pieces(0, 0)
	AudioManager.play_sfx("camino_borrar")
	GameManager.checkpoint(self)


func _on_stall_toggled(_pressed: bool, index: int) -> void:
	if _session.waiting:
		_stall_buttons[index].set_pressed_no_signal(index in _session.basket)
		return
	guide.stop()
	var added: bool = _session.toggle_basket(index)
	AudioManager.play_sfx("palabra_soltar" if added else "palabra_regresar")
	_refresh_basket()
	GameManager.checkpoint(self)


func _refresh_basket() -> void:
	for child: Node in basket_row.get_children():
		child.queue_free()
	for index: int in _session.basket:
		var art: TextureRect = TextureRect.new()
		art.texture = _stall_buttons[index].icon
		art.custom_minimum_size = BASKET_ART_SIZE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		basket_row.add_child(art)


func _on_option_pressed(button: Button) -> void:
	var current: CountingRound = _round()
	if (
		_session.waiting
		or current.kind not in [CountingRound.Kind.FRIENDS, CountingRound.Kind.RECALL]
	):
		return
	guide.stop()
	_session.answer = str(button.get_meta("answer", ""))
	if _session.is_solved(current):
		_resolve(current)
		return
	_session.miss()
	AudioManager.play_sfx("error_suave")
	button.disabled = true
	CharacterReaction.play(animal_sprite, false)
	_set_feedback(_choice_hint(current, _session.answer), COLOR_ERROR)
	_after_mistake()


func _choice_hint(current: CountingRound, chosen: String) -> String:
	var counts_things: bool = chosen.ends_with("p'éel")
	var counts_animals: bool = current.answer.ends_with("túul")
	if counts_things and counts_animals:
		return "Para contar animales se usa -túul, no -p'éel."
	if chosen.ends_with("túul") and not counts_animals:
		return "Para contar cosas se usa -p'éel, no -túul."
	return "Cuenta otra vez, uno por uno."


func _on_action_pressed() -> void:
	if _navigating:
		return
	var current: CountingRound = (
		_round() if not _session.is_finished(content.rounds.size()) else null
	)
	if current == null:
		return
	if _session.waiting:
		_session.next_round()
		_show_round()
		return
	match current.kind:
		CountingRound.Kind.BUILD:
			_check_build(current)
		CountingRound.Kind.MARKET:
			_check_market(current)
		CountingRound.Kind.RECALL:
			_check_recall(current)


func _check_build(current: CountingRound) -> void:
	if _session.is_solved(current):
		_resolve(current)
		return
	_session.miss()
	AudioManager.play_sfx("error_suave")
	var built: int = _session.numeral_value()
	var wanted: int = VocabularyCatalog.number_value(current.number)
	_set_feedback(
		(
			"Tu numeral vale %d. %s vale %d: %s."
			% [built, current.number, wanted, "agrega piezas" if built < wanted else "quita piezas"]
		),
		COLOR_ERROR
	)
	_after_mistake()


func _check_market(current: CountingRound) -> void:
	var result: String = _session.basket_result(current)
	if result == "ok":
		_resolve(current)
		return
	_session.miss()
	AudioManager.play_sfx("error_suave")
	CharacterReaction.play(animal_sprite, false)
	var messages: Dictionary = {
		"other": "En la canasta hay algo que no te pidieron.",
		"few": "Faltan algunos. Cuenta otra vez.",
		"many": "Sobran algunos. Saca los que no pidieron."
	}
	_set_feedback(messages[result], COLOR_ERROR)
	_after_mistake()


func _check_recall(current: CountingRound) -> void:
	if not recall.ready_to_submit():
		return
	var answers: Array[String] = recall.values()
	_session.answer = answers[0]
	_session.item = answers[1]
	var result: Dictionary = _session.check_written(current, answers[0], answers[1])
	if result.correct:
		if result.supported:
			_session.attempt.supported = true
		_session.answer = current.answer
		_session.item = current.item
		_resolve(current)
		return
	_session.miss()
	AudioManager.play_sfx("error_suave")
	_set_feedback(
		(
			"Revisa el número y su terminación."
			if not result.get("number_ok", false)
			else "El número está bien. Revisa qué son."
		),
		COLOR_ERROR
	)
	recall.advance_support()
	GameManager.checkpoint(self)


func _after_mistake() -> void:
	if _session.attempt.mistakes >= 2:
		_help_stage = 2
		_show_help()
	GameManager.checkpoint(self)


# ─── Acierto ─────────────────────────────────────────────────────────────────
func _resolve(current: CountingRound) -> void:
	AudioManager.play_sfx("acierto")
	if current.kind == CountingRound.Kind.STELE:
		GameManager.mark_tutorial_seen("numbers")
	else:
		var phase: String = (
			"practice"
			if current.guided or current.kind != CountingRound.Kind.RECALL or _session.cards
			else ExerciseRecallFlow.phase(recall, false)
		)
		GameManager.record_learning(
			[current.number],
			phase,
			_session.attempt.context,
			_session.attempt.supported,
			_session.attempt.mistakes
		)
	_render_success(current, true)


func _render_success(current: CountingRound, animate: bool) -> void:
	_session.waiting = true
	guide.stop()
	var entry: Dictionary = VocabularyCatalog.entry(current.number)
	var text: String = (
		"Ya conoces los números del 1 al %d." % current.numbers.size()
		if current.kind == CountingRound.Kind.STELE
		else (
			"%s · %s" % [current.phrase, current.translation]
			if not current.phrase.is_empty()
			else "%s · %s" % [current.number, entry.get("spanish", "")]
		)
	)
	_set_feedback("✓ " + text, COLOR_SUCCESS)
	if current.kind == CountingRound.Kind.FRIENDS:
		phrase_label.text = current.phrase
		phrase_label.visible = not current.phrase.is_empty()
	for button: Button in _stall_buttons:
		button.disabled = true
	for button: Button in _option_buttons:
		button.disabled = true
	dot_button.disabled = true
	bar_button.disabled = true
	clear_button.disabled = true
	if current.kind == CountingRound.Kind.RECALL and recall.visible:
		recall.show_result(current.item, "", current.phrase, current.translation)
	action_button.text = "Continuar →"
	action_button.disabled = false
	action_button.grab_focus()
	mission_progress.update_progress(
		_session.round_index + 1,
		content.rounds.size(),
		"El tianguis · %d / %d · ¡Listo!" % [_session.round_index + 1, content.rounds.size()]
	)
	if animate:
		CharacterReaction.play(animal_sprite)
		guide.watch_continue(action_button)
	GameManager.checkpoint(self)


func _finish_level() -> void:
	guide.stop()
	for panel: Control in [stele, build, market, friends, recall_box, options_grid]:
		panel.hide()
	action_button.disabled = true
	GameManager.complete_level(4, 2)
	completion.show_completion(
		"¡Ya sabes contar!", "Contaste en maya del uno al cinco.", "Al portal →"
	)
	GameManager.checkpoint(self)


# ─── Apoyos ──────────────────────────────────────────────────────────────────
func _practice_with_cards() -> void:
	mark_learning_help()
	_session.cards = true
	recall.hide()
	_show_options(_round(), options_grid)
	action_button.text = "Continuar →"
	action_button.disabled = true
	_set_feedback("Elige cuántos hay.", _feedback_color)
	GameManager.checkpoint(self)


func _on_recall_changed() -> void:
	if recall.visible and not recall.is_preparing() and not _session.waiting:
		_session.answer = recall.first.text
		_session.item = recall.second.text
		GameManager.schedule_checkpoint(self)


func _show_help() -> void:
	if _session.is_finished(content.rounds.size()) or _navigating:
		return
	if _session.waiting:
		guide.point_at(action_button)
		return
	mark_learning_help()
	var current: CountingRound = _round()
	match current.kind:
		CountingRound.Kind.STELE:
			for index: int in range(current.numbers.size()):
				if current.numbers[index] not in _session.met:
					guide.click_at(stele_numbers.get_child(index) as Control)
					return
		CountingRound.Kind.BUILD:
			var wanted: int = VocabularyCatalog.number_value(current.number)
			var built: int = _session.numeral_value()
			if built > wanted:
				guide.click_at(clear_button)
			elif _session.bars < MayaNumeral.bars_of(wanted):
				guide.click_at(bar_button)
			elif built < wanted:
				guide.click_at(dot_button)
			else:
				guide.point_at(action_button)
		CountingRound.Kind.MARKET:
			for index: int in range(_stall_buttons.size()):
				var good: String = str(_stall_buttons[index].get_meta("good", ""))
				var wrong_in: bool = good != current.item and index in _session.basket
				var missing: bool = good == current.item and index not in _session.basket
				if wrong_in or (missing and _session.basket_result(current) == "few"):
					guide.click_at(_stall_buttons[index])
					return
			guide.point_at(action_button)
		CountingRound.Kind.FRIENDS:
			if _help_stage >= 2:
				for button: Button in _option_buttons:
					if button.visible and button.get_meta("answer", "") == current.answer:
						guide.click_at(button)
						return
			guide.highlight(crowd)
		CountingRound.Kind.RECALL:
			if recall.visible:
				recall.explain_support()
				guide.highlight(recall)
			else:
				guide.highlight(options_grid)
	_help_stage += 1


func mark_learning_help() -> void:
	if not _session.waiting:
		_session.attempt.supported = true


func _set_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)


func _update_progress() -> void:
	mission_progress.update_progress(
		_session.round_index,
		content.rounds.size(),
		(
			"El tianguis · %d / %d · %s"
			% [_session.round_index + 1, content.rounds.size(), PHASE_NAMES[_round().kind]]
		)
	)


# ─── Navegación ──────────────────────────────────────────────────────────────
func _on_menu_pressed() -> void:
	_navigating = true
	GameManager.go_to_scene("main_menu")


func _on_next_pressed() -> void:
	_navigating = true
	GameManager.go_to_scene("world4_story1")


func _on_book_pressed() -> void:
	libro.show_book($UI/LevelHeader/Bar/BookButton)


func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))


func get_checkpoint_state() -> Dictionary:
	var state: Dictionary = _session.snapshot()
	if recall.visible and not recall.is_showing_result():
		state.scaffold = recall.scaffold_state()
	return state.duplicate(true)


func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del tianguis."])
	return content.get_configuration_issues()


func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()
