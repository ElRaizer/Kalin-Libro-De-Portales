@tool
## Mundo 2, nivel 1 — La Casa Maya (Objetos del hogar)
## El jugador lanza el hechizo que corresponde al objeto solicitado.
##
## Cada animal necesita un objeto para su casa. El jugador debe elegir el
## sustantivo maya correcto entre varias opciones para conjurarlo:
##   Fase 1 (Aprende):   se muestra la imagen Y la palabra en maya.
##   Fase 2 (Recuerda):  dos peticiones con traducción de transición y después
##                       sólo las palabras mayas en las respuestas.
## Vocabulario centralizado en GameContent.VOCABULARY, mundo 2 nivel 1:
##   mayak (mesa), lak (plato), k'áan (hamaca), k'áanche' (silla), janal (comida)
extends Node2D

@export var content: ExerciseSet
var objects: Array[ExerciseEntry]:
	get:
		return content.objects

# Objeto solicitado, animal que lo pide, y refuerzo gramatical.

var total_rounds: int:
	get:
		return objects.size() * 2
var round_order: Array[int] = []
var recall_order: Array[int] = []
var round_index: int = 0
var current_phase: int = 0
var _completing: bool = false
var _waiting: bool = false
var _mistakes: int = 0
var _choice_buttons: Array[Button] = []
var guide: LearningGuide
@onready var next_button: Button = $UI/NextButton
@onready var request_art: MeaningIllustration = $UI/RequestPanel/RequestArt
@onready var room: Panel = $UI/Room
var room_items: Dictionary = {}
@onready var mission_progress: MissionProgress = $UI/MissionProgress
@onready var mission_break: MissionBreak = $UI/MissionBreak
@onready var choice_preview: MeaningIllustration = $UI/FeedbackPanel/ChoicePreview
var _help_stage: int = 0
var _blocks_seen: Array[int] = []
var _attempt: LearningAttempt = LearningAttempt.new()
var _layout_seed: int = 1
var _saved_scaffold: Dictionary = {}
var _practice_fallback: bool = false
@onready var recall: RecallPanel = $UI/RecallPanel

@onready var animal_spr: TextureRect = $UI/RequestPanel/AnimalSprite
@onready var need_lbl: Label = $UI/RequestPanel/VBox/NeedLbl
@onready var word_lbl: Label = $UI/RequestPanel/VBox/WordLbl
@onready var choices_grid: GridContainer = $UI/ChoicesGrid
@onready var feedback_lbl: Label = $UI/FeedbackPanel/FeedbackLbl
@onready var _feedback_left: float = feedback_lbl.offset_left
@onready var _feedback_color: Color = feedback_lbl.get_theme_color("font_color")
@onready var phase_lbl: Label = $UI/StatusPanel/StatusVBox/PhaseLbl
@onready var progress_lbl: Label = $UI/StatusPanel/StatusVBox/ProgressLbl
@onready var completion: CompletionOverlay = $UI/CompletionOverlay
@onready var magic_lbl: Label = $UI/TopBar/MagicLabel
@onready var libro: CanvasLayer = $LibroHechizos


func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues: PackedStringArray = get_configuration_issues()
	if not issues.is_empty():
		push_error("Configuración incompleta: " + "; ".join(issues))
		return
	var state: Dictionary = GameManager.get_scene_state(self)
	_attempt.restore(state.get("attempt"))
	_saved_scaffold = state.get("scaffold", {}) if state.get("scaffold") is Dictionary else {}
	_practice_fallback = bool(state.get("cards", false))
	_layout_seed = int(state.get("layout_seed", randi_range(1, 2000000000)))
	round_order = ReplayVariation.order(
		objects.size(), _layout_seed, ReplayVariation.previous(state, "order", [])
	)
	_blocks_seen = ExerciseProgress.restore_markers(state.get("blocks"), total_rounds)
	round_order = ExerciseProgress.order_or(state.get("order"), objects.size(), round_order)
	recall_order = ReplayVariation.order(objects.size(), _layout_seed + 7919, round_order)
	recall_order = ExerciseProgress.order_or(
		state.get("recall_order"), objects.size(), recall_order
	)
	round_index = clampi(int(state.get("round", 0)), 0, total_rounds)
	completion.next_pressed.connect(_on_next_level_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	GameManager.magic_points_changed.connect(_on_magic_points_changed)
	_on_magic_points_changed(GameManager.session.magic_points)
	guide = LearningGuide.install(self, $UI/TopBar, _show_help)
	for button: Button in choices_grid.get_children():
		button.pressed.connect(func(): _on_choice_pressed(str(button.get_meta("word"))))
	next_button.pressed.connect(_advance_round)
	recall.submitted.connect(func(): _on_choice_pressed(recall.first.text))
	recall.practice_requested.connect(_practice_with_cards)
	recall.support_used.connect(func() -> void: GameManager.checkpoint(self))
	ExerciseRecallFlow.bind_support(recall, _attempt)
	recall.answer_changed.connect(_on_scaffold_changed)
	mission_break.continued.connect(func(): guide.watch_action(choices_grid))
	_restore_room()
	if round_index >= total_rounds:
		_on_level_complete()
	else:
		_show_round()
		if recall.visible and state.has("recall_text"):
			recall.first.text = str(state.recall_text)
		if bool(state.get("waiting", false)):
			_render_success(false)


func _place_object(word: String, animate: bool) -> void:
	if word in room_items:
		if animate:
			(room_items[word] as MeaningIllustration).celebrate()
		return
	var art: MeaningIllustration = (
		room.get_node("Items").get_node(NodePath(word)) as MeaningIllustration
	)
	art.show()
	art.show_meaning(word)
	room_items[word] = art
	if animate:
		art.celebrate()


func _restore_room() -> void:
	for index: int in range(mini(round_index, objects.size())):
		_place_object(objects[round_order[index]].maya, false)


func _current_object() -> ExerciseEntry:
	var order: Array[int] = round_order if round_index < objects.size() else recall_order
	return objects[order[round_index % order.size()]]


func _show_round() -> void:
	guide.stop()
	mission_break.hide()
	choice_preview.hide()
	feedback_lbl.offset_left = _feedback_left
	_waiting = false
	$UI/FeedbackPanel.show()
	var semantic: String = LearningContext.identify(
		"house",
		_current_object().animal,
		[_current_object().maya],
		round_index < objects.size(),
		_layout_seed
	)
	var continuing: bool = LearningContext.begin(_attempt, semantic)
	_mistakes = _attempt.mistakes
	_practice_fallback = _practice_fallback if continuing else false
	recall.hide()
	_help_stage = 0
	next_button.hide()
	feedback_lbl.text = "Elige el hechizo para ayudar."
	feedback_lbl.add_theme_color_override("font_color", _feedback_color)
	var obj: ExerciseEntry = _current_object()
	var vocab: Dictionary = VocabularyCatalog.entry(obj.maya)
	current_phase = 0 if round_index < objects.size() else 1
	if current_phase == 0:
		GameManager.learn_word(obj.maya)
	animal_spr.texture = obj.sprite
	need_lbl.text = obj.request if current_phase == 0 else "En maya: %s" % vocab.spanish.to_lower()
	word_lbl.text = "%s · %s" % [obj.maya, vocab.spanish] if current_phase == 0 else ""
	request_art.show_meaning(obj.maya)
	request_art.visible = current_phase == 0 or _practice_fallback
	phase_lbl.text = (
		"%s · %d / %d"
		% [
			"Aprende" if current_phase == 0 else "Recuerda",
			round_index % objects.size() + 1,
			objects.size()
		]
	)
	progress_lbl.text = (
		"%d / %d muebles recuperados" % [mini(round_index, objects.size()), objects.size()]
	)
	mission_progress.update_progress(
		round_index,
		total_rounds,
		(
			"La casa · %d / %d · %s"
			% [
				round_index % objects.size() + 1,
				objects.size(),
				ExerciseRecallFlow.caption(recall, current_phase == 0, _practice_fallback)
			]
		)
	)
	_build_choices()
	choices_grid.visible = current_phase == 0 or _practice_fallback
	if current_phase == 1 and not _practice_fallback:
		ExerciseRecallFlow.prepare(
			recall, ["Objeto"], [obj.maya], _attempt, _saved_scaffold if continuing else {}
		)
		_saved_scaffold = {}
		$UI/FeedbackPanel.hide()
	mission_progress.update_progress(
		round_index,
		total_rounds,
		(
			"La casa · %d / %d · %s"
			% [
				round_index + 1,
				total_rounds,
				ExerciseRecallFlow.caption(recall, current_phase == 0, _practice_fallback)
			]
		)
	)
	if round_index == 0 and "objects" not in GameManager.session.tutorials_seen:
		call_deferred("_show_help")
	else:
		guide.watch_action(choices_grid)
	if round_index == objects.size() and round_index not in _blocks_seen:
		_blocks_seen.append(round_index)
		mission_break.show_block("¡La casa está amueblada! Ahora prueba tus palabras.", "casa")
		mission_break.offer_walk("world2_explore1", "world2_level1")
	GameManager.checkpoint(self)


func _build_choices() -> void:
	for child: Node in choices_grid.get_children():
		(child as Button).hide()
	_choice_buttons.clear()
	var pool: Array[ExerciseEntry] = objects.duplicate()
	pool.erase(_current_object())
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_layout_seed, round_index])
	pool.sort_custom(func(a: ExerciseEntry, b: ExerciseEntry): return a.maya < b.maya)
	for index: int in range(pool.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: ExerciseEntry = pool[index]
		pool[index] = pool[other]
		pool[other] = swap
	# Dos opciones al empezar y cuatro después, siempre en filas completas de dos.
	var count: int = mini(2 if current_phase == 0 and round_index == 0 else 4, objects.size())
	count -= count % 2
	pool = pool.slice(0, count - 1)
	pool.append(_current_object())
	var correct_position: int = rng.randi_range(0, pool.size() - 1)
	var correct_item: ExerciseEntry = pool.pop_back() as ExerciseEntry
	pool.insert(correct_position, correct_item)
	for index: int in range(pool.size()):
		var obj: ExerciseEntry = pool[index]
		var button: Button = choices_grid.get_child(index) as Button
		button.show()
		button.disabled = false
		button.set_meta("word", obj.maya)
		button.text = obj.maya
		if current_phase == 1 and _practice_fallback:
			button.text += "\n" + str(VocabularyCatalog.entry(obj.maya).spanish)
		button.icon = GameManager.get_visual_texture(obj.maya) if current_phase == 0 else null
		_choice_buttons.append(button)
	_choice_buttons[0].grab_focus()


func _on_choice_pressed(word: String) -> void:
	if _completing or _waiting:
		return
	if recall.visible and word == recall.first.text and not recall.ready_to_submit():
		return
	guide.stop()
	if current_phase == 1 and not _practice_fallback:
		var match_result: Dictionary = WordMatcher.match_word(word, _current_object().maya)
		_attempt.observe(
			_current_object().maya,
			match_result.correct,
			match_result.supported,
			ExerciseRecallFlow.phase(recall, false)
		)
		if match_result.correct:
			word = match_result.word
			_attempt.supported = _attempt.supported or match_result.supported
	if word == _current_object().maya:
		GameManager.learn_word(word)
		GameManager.record_learning(
			[word],
			ExerciseRecallFlow.phase(recall, current_phase == 0),
			_attempt.context,
			_attempt.supported,
			_attempt.mistakes,
			_attempt.evidence([word])
		)
		GameManager.mark_tutorial_seen("objects")
		_render_success(true)
	else:
		_attempt.miss()
		_mistakes += 1
		choice_preview.show()
		choice_preview.show_meaning(word)
		feedback_lbl.offset_left = maxf(
			_feedback_left, choice_preview.position.x + choice_preview.size.x + 11
		)
		CharacterReaction.play(animal_spr, false)
		var meaning: Dictionary = VocabularyCatalog.entry(word)
		feedback_lbl.text = (
			"%s significa %s. Revisa la petición." % [word, meaning.spanish]
			if not meaning.is_empty()
			else "Revisa tu palabra o usa tarjetas."
		)
		feedback_lbl.add_theme_color_override("font_color", Color("b56a1f"))
		if recall.visible:
			recall.advance_support()
			recall.caption.show()
		if _mistakes >= 2 and not recall.visible:
			_help_stage = mini(_mistakes - 2, 2)
			_show_help()
		GameManager.checkpoint(self)


func _render_success(animate: bool) -> void:
	_waiting = true
	$UI/FeedbackPanel.show()
	var result_obj: ExerciseEntry = _current_object()
	var result_vocab: Dictionary = VocabularyCatalog.entry(result_obj.maya)
	recall.show_result(result_obj.maya, "", result_vocab.estructura, result_vocab.traduccion)
	choices_grid.hide()
	mission_progress.update_progress(
		round_index + 1,
		total_rounds,
		"La casa · %d / %d · ¡Creado!" % [round_index + 1, total_rounds]
	)
	$UI/FeedbackPanel.hide()
	choice_preview.hide()
	feedback_lbl.offset_left = _feedback_left
	guide.stop()
	for button: Button in _choice_buttons:
		button.disabled = true
	var obj: ExerciseEntry = _current_object()
	var vocab: Dictionary = VocabularyCatalog.entry(obj.maya)
	feedback_lbl.text = "✓ %s\n%s" % [vocab.estructura, vocab.traduccion]
	feedback_lbl.add_theme_color_override("font_color", Color("2e8b57"))
	_place_object(obj.maya, animate)
	progress_lbl.text = "%d / %d muebles recuperados" % [room_items.size(), objects.size()]
	next_button.show()
	next_button.grab_focus()
	guide.watch_continue(next_button)
	if animate:
		CharacterReaction.play(animal_spr)
		guide.page_to_book(
			request_art.global_position, $UI/TopBar/BookBtn.get_global_rect().get_center()
		)
	GameManager.checkpoint(self)


func _advance_round() -> void:
	if not _waiting:
		return
	round_index += 1
	if round_index >= total_rounds:
		_on_level_complete()
	else:
		_show_round()


func _show_help() -> void:
	if mission_break.visible:
		guide.point_at(mission_break.continue_button)
		return
	if _waiting:
		guide.point_at(next_button)
		return
	if recall.visible:
		_attempt.guidance = true
		GameManager.checkpoint(self)
		recall.explain_support()
		guide.highlight(recall)
		return
	mark_learning_help()
	if (
		not (round_index == 0 and "objects" not in GameManager.session.tutorials_seen)
		and _help_stage < 2
	):
		guide.highlight(request_art if _help_stage == 0 else choices_grid)
		_help_stage += 1
		feedback_lbl.text = "Busca la palabra del objeto."
		return
	for button: Button in _choice_buttons:
		if button.text.get_slice("\n", 0) == _current_object().maya:
			guide.point_at(button)
			feedback_lbl.text = "Toca una palabra. El objeto aparecerá en la casa."
			return


func _on_level_complete() -> void:
	_completing = true
	guide.stop()
	next_button.hide()
	GameManager.complete_level(2, 1)
	completion.show_completion(
		"¡La casa está lista!",
		"Recuperaste los muebles de tus amigos. Sal a ver cómo los utilizan.",
		"Pasear por la aldea →"
	)
	GameManager.checkpoint(self)


func _on_magic_points_changed(value: int) -> void:
	magic_lbl.text = GameManager.recovered_pages_text()


func _on_menu_pressed() -> void:
	GameManager.go_to_scene("main_menu")


func _on_next_level_pressed() -> void:
	GameManager.go_to_scene("world2_mission1")


func _on_book_pressed() -> void:
	libro.show_book($UI/TopBar/BookBtn)


func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))


func get_checkpoint_state() -> Dictionary:
	return (
		{
			"order": round_order,
			"recall_order": recall_order,
			"round": round_index,
			"waiting": _waiting,
			"blocks": _blocks_seen,
			"attempt": _attempt.snapshot(),
			"layout_seed": _layout_seed,
			"cards": _practice_fallback,
			"recall_text": recall.first.text,
			"scaffold": recall.scaffold_state()
		}
		. duplicate(true)
	)


func mark_learning_help() -> void:
	if not _waiting and not _completing:
		_attempt.use_content_help()
		GameManager.checkpoint(self)


func _practice_with_cards() -> void:
	mark_learning_help()
	_practice_fallback = true
	$UI/FeedbackPanel.show()
	recall.hide()
	choices_grid.show()
	request_art.show()
	_build_choices()
	feedback_lbl.text = "Practiquemos. Después podrás recordarla en otra situación."


func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del ejercicio."])
	var issues: PackedStringArray = content.get_configuration_issues(2)
	if get_node("UI/ChoicesGrid").get_child_count() < objects.size():
		issues.append("Añade un botón en UI/ChoicesGrid por cada objeto del contenido.")
	for obj: ExerciseEntry in objects:
		if obj != null and not get_node("UI/Room/Items").has_node(NodePath(obj.maya)):
			issues.append("Falta el mueble '%s' en UI/Room/Items." % obj.maya)
	return issues


func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()


func _on_scaffold_changed() -> void:
	if recall.visible and not recall.is_preparing():
		phase_lbl.text = ExerciseRecallFlow.caption(recall, false, false)
		mission_progress.update_progress(
			round_index,
			total_rounds,
			"La casa · %d / %d · %s" % [round_index + 1, total_rounds, phase_lbl.text]
		)
		GameManager.schedule_checkpoint(self)


func debug_can_answer() -> bool:
	return OS.is_debug_build() and not _completing and not _waiting and not mission_break.visible


func debug_answer() -> void:
	if not debug_can_answer():
		return
	mark_learning_help()
	var word: String = _current_object().maya
	if recall.visible:
		recall.debug_fill([word])
	_on_choice_pressed(word)
