@tool
## Mundo 5 — El Portal de Regreso
## Recapitulación de las estructuras aprendidas y cierre narrativo.
extends Node2D

@export var content: ExerciseSet
@export var vary_challenges: bool = true
var _session_challenges: Array[ExerciseEntry] = []
var _portal_variants: Dictionary = {}
var _portal_pool_keys: Dictionary = {}
var _challenge_order: Array[int] = []
var challenges: Array[ExerciseEntry]:
	get:
		return content.challenges if _session_challenges.is_empty() else _session_challenges

const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var challenge_index: int = 0
var option_buttons: Array[Button] = []
var _resolving: bool = false
var _awaiting_continue: bool = false
var _mistakes: int = 0
var guide: LearningGuide
var challenge_art: MeaningIllustration
@onready var next_button: Button = $UI/NextButton
@onready var portal_visual: PortalVisual = $PortalVisual
@onready var mission_progress: MissionProgress = $UI/MissionProgress
var _help_stage: int = 0
var _attempt: LearningAttempt = LearningAttempt.new()
var _layout_seed: int = 1
var _saved_scaffold: Dictionary = {}
var _practice_fallback: bool = false
@onready var recall: RecallPanel = $UI/RecallPanel
@onready var feedback_art: MeaningIllustration = $UI/FeedbackPanel/FeedbackArt

@onready var header: Panel = $UI/LevelHeader
@onready var section_label: Label = $UI/ChallengePanel/Content/SectionLabel
@onready var prompt_label: Label = $UI/ChallengePanel/Content/PromptLabel
@onready var clue_label: Label = $UI/ChallengePanel/Content/ClueLabel
@onready var options_box: GridContainer = $UI/OptionsPanel/Content/Options
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var _feedback_left: float = feedback_label.offset_left
@onready var _feedback_color: Color = feedback_label.get_theme_color("font_color")
@onready var progress_label: Label = $UI/PortalStatus/Status/ProgressLabel
@onready var portal_energy: ProgressBar = $UI/PortalStatus/Status/PortalEnergy
@onready var portal_label: Label = $UI/PortalStatus/Status/PortalLabel
@onready var portal_glow: ColorRect = $PortalGlow
@onready var completion: Control = $UI/CompletionOverlay
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
	completion.next_pressed.connect(_on_epilogue_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	portal_energy.max_value = challenges.size()
	portal_energy.value = 0
	guide = LearningGuide.install(self, $UI/LevelHeader/Bar, _show_help)
	for button: Button in options_box.get_children():
		button.pressed.connect(func(): _on_option_pressed(str(button.get_meta("phrase"))))
	challenge_art = $UI/ChallengePanel/Content/ChallengeArt
	next_button.pressed.connect(_advance_challenge)
	recall.submitted.connect(func(): _on_option_pressed(recall.first.text))
	recall.practice_requested.connect(_practice_with_cards)
	recall.support_used.connect(func() -> void: GameManager.checkpoint(self))
	ExerciseRecallFlow.bind_support(recall, _attempt)
	recall.answer_changed.connect(_on_scaffold_changed)
	var state: Dictionary = GameManager.get_scene_state(self)
	_attempt.restore(state.get("attempt"))
	_practice_fallback = state.get("cards", false) == true
	_saved_scaffold = state.get("scaffold", {}) if state.get("scaffold") is Dictionary else {}
	_layout_seed = int(state.get("layout_seed", randi_range(1, 2000000000)))
	if vary_challenges:
		var taught: Dictionary = {}
		for world: int in [3, 4]:
			var previous: Dictionary = GameManager.saved_scene_state("world%d_level1" % world)
			if previous.get("combination_plan") is Array:
				taught[str(world - 1)] = previous.combination_plan
		var session: Dictionary = PortalReplay.prepare(
			content.challenges, state, _layout_seed, taught
		)
		_session_challenges.assign(session.challenges)
		_portal_variants = session.variants
		_portal_pool_keys = session.pool_keys
		_challenge_order.assign(session.order)
	challenge_index = clampi(int(state.get("challenge", 0)), 0, challenges.size())
	portal_energy.value = challenge_index
	portal_visual.energy = challenge_index
	portal_glow.color.a = minf(0.16 + 0.06 * challenge_index, 0.62)
	_show_challenge()
	if recall.visible:
		recall.first.text = str(state.get("recall_text", ""))
	if challenge_index < challenges.size() and bool(state.get("waiting", false)):
		_render_success(false)


func _show_challenge() -> void:
	guide.stop()
	next_button.hide()
	if challenge_index >= challenges.size():
		_finish_world()
		return
	_resolving = false
	_awaiting_continue = false
	var semantic: String = LearningContext.identify(
		"portal",
		challenges[challenge_index].section,
		[challenges[challenge_index].correct],
		challenge_index >= 4,
		_layout_seed
	)
	var continuing: bool = LearningContext.begin(_attempt, semantic)
	_practice_fallback = _practice_fallback if continuing else false
	_mistakes = _attempt.mistakes
	recall.hide()
	options_box.show()
	$UI/OptionsPanel.show()
	$UI/ChallengePanel.size.y = 242
	_help_stage = 0
	feedback_art.hide()
	feedback_label.offset_left = _feedback_left
	var challenge: ExerciseEntry = challenges[challenge_index]
	if not challenge.learn.is_empty() and challenge_index >= 4:
		GameManager.learn_word(challenge.learn)
	section_label.text = "Página %d / %d" % [challenge_index + 1, challenges.size()]
	prompt_label.text = challenge.prompt
	clue_label.text = challenge.clue
	var word: String = "Peek'"
	var quality: String = ""
	match challenge.section:
		"OBJETOS":
			word = "mayak"
		"CUALIDADES":
			word = "mayak"
			quality = "nojoch"
		"PETICIONES":
			word = "ja'"
		"SALUDO", "AGRADECIMIENTO", "DESPEDIDA", "BUEN CAMINO":
			word = challenge.correct
	if not challenge.noun.is_empty():
		word = challenge.noun
		quality = challenge.adjective
	challenge_art.show_meaning(word, quality)
	feedback_label.text = "Elige el hechizo."
	feedback_label.add_theme_color_override("font_color", _feedback_color)
	progress_label.text = "%d / %d páginas" % [challenge_index, challenges.size()]
	portal_label.text = "El portal está despertando"
	_build_options(challenge.options)
	challenge_art.visible = challenge_index >= 4 or _practice_fallback
	if challenge_index < 4 and not _practice_fallback:
		options_box.hide()
		ExerciseRecallFlow.prepare(
			recall, ["Hechizo completo"], [challenge.correct], _attempt, _saved_scaffold
		)
		_saved_scaffold = {}
		$UI/OptionsPanel.hide()
		$UI/ChallengePanel.size.y = 160
		recall.position.y = 266
		feedback_label.text = "Recuerda tu hechizo. Las pistas aparecen si las necesitas."
	guide.watch_action(options_box)
	mission_progress.update_progress(
		challenge_index,
		challenges.size(),
		"El portal · %d / %d" % [challenge_index + 1, challenges.size()]
	)
	GameManager.checkpoint(self)


func _build_options(options: Array) -> void:
	for child: Node in options_box.get_children():
		(child as Button).hide()
	option_buttons.clear()
	var shuffled: Array = options.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_layout_seed, challenge_index])
	for index: int in range(shuffled.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: Variant = shuffled[index]
		shuffled[index] = shuffled[other]
		shuffled[other] = swap
	for index: int in range(shuffled.size()):
		var phrase: String = shuffled[index]
		var button: Button = options_box.get_child(index) as Button
		button.show()
		button.disabled = false
		button.set_meta("phrase", phrase)
		button.text = phrase
		option_buttons.append(button)
	if not option_buttons.is_empty():
		option_buttons[0].grab_focus()


func _on_option_pressed(phrase: String) -> void:
	if _resolving:
		return
	var challenge: ExerciseEntry = challenges[challenge_index]
	guide.stop()
	var spelling_correction: bool = false
	if recall.visible:
		if phrase == recall.first.text and not recall.ready_to_submit():
			return
		var match_result: Dictionary = WordMatcher.match_word(phrase, challenge.correct)
		if match_result.correct:
			phrase = match_result.word
			_attempt.supported = _attempt.supported or match_result.supported
			spelling_correction = match_result.supported
	if phrase != challenge.correct:
		_attempt.miss()
		_mistakes += 1
		feedback_art.show()
		var created: String = phrase
		var quality: String = (
			"mejen"
			if phrase.ends_with(" mejen")
			else ("nojoch" if phrase.ends_with(" nojoch") else "")
		)
		if phrase.contains("mayak"):
			created = "mayak"
		elif phrase.ends_with(" Peek'"):
			created = "Peek'"
		elif phrase.ends_with(" ja'"):
			created = "ja'"
		elif phrase.ends_with(" ja'as"):
			created = "ja'as"
		var meaning_art: Array[String] = PortalReplay.meaning(phrase)
		if meaning_art[0] != phrase or phrase in GameContent.VOCABULARY:
			created = meaning_art[0]
			quality = meaning_art[1]
		feedback_art.show_meaning(created, quality)
		feedback_label.offset_left = maxf(
			_feedback_left, feedback_art.position.x + feedback_art.size.x + 11
		)
		var meaning: Dictionary = VocabularyCatalog.entry(phrase)
		if not meaning.is_empty():
			feedback_label.text = "Esa frase dice: %s" % meaning.traduccion
		elif phrase.begins_with("In k'a'at"):
			feedback_label.text = "Esa frase pide algo. Mira lo que necesita Kalin."
		elif phrase.begins_with("In k'aaba'e'"):
			feedback_label.text = "Esa frase sirve para presentarse."
		elif phrase.begins_with("Ti' yaan"):
			feedback_label.text = "Ese hechizo dice que hay un objeto."
		else:
			feedback_label.text = "Ese hechizo describe un objeto."
		feedback_label.add_theme_color_override("font_color", COLOR_ERROR)
		if recall.visible:
			recall.advance_support()
		elif _mistakes >= 2:
			_help_stage = mini(_mistakes - 2, 2)
			_show_help()
		GameManager.checkpoint(self)
		return
	if str(challenge.learn) != "":
		GameManager.learn_word(challenge.learn)
	var evidence_words: Array[String] = []
	if not challenge.learn.is_empty():
		evidence_words.append(challenge.learn)
	if evidence_words.is_empty():
		for word: String in VocabularyCatalog.learnable_keys():
			if word in challenge.correct.split(" ", false):
				evidence_words.append(word)
	if recall.visible:
		for word: String in evidence_words:
			_attempt.observe(
				word,
				true,
				spelling_correction,
				ExerciseRecallFlow.phase(recall, challenge_index >= 4)
			)
	GameManager.record_learning(
		evidence_words,
		ExerciseRecallFlow.phase(recall, challenge_index >= 4),
		_attempt.context,
		_attempt.supported,
		_attempt.mistakes,
		_attempt.evidence(evidence_words)
	)
	_render_success(true)


func _finish_world() -> void:
	_resolving = true
	_awaiting_continue = false
	guide.stop()
	next_button.hide()
	GameManager.complete_level(5, 1)
	portal_glow.color.a = 0.72
	completion.show_completion(
		"¡El portal está abierto!",
		"Tus palabras ayudaron a toda la aldea.",
		"Preparar mi despedida →"
	)
	GameManager.checkpoint(self)


func _on_menu_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("main_menu")


## "Cerrar la aventura" abre el epílogo con la despedida de los animales.
func _on_epilogue_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("world5_farewell")


func _on_book_pressed() -> void:
	libro.show_book($UI/LevelHeader/Bar/BookButton)


func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))


func _render_success(animate: bool) -> void:
	feedback_art.hide()
	feedback_label.offset_left = _feedback_left
	_resolving = true
	_awaiting_continue = true
	var challenge: ExerciseEntry = challenges[challenge_index]
	var meaning: Array[String] = PortalReplay.meaning(challenge.correct)
	recall.show_result(meaning[0], meaning[1], challenge.correct, challenge.prompt)
	$UI/OptionsPanel.hide()
	$UI/ChallengePanel.size.y = 160
	recall.position.y = 266
	guide.stop()
	for button: Button in option_buttons:
		button.disabled = true
		if button.text == challenges[challenge_index].correct:
			button.text = "✓ " + button.text
	feedback_label.text = "✓ %s" % challenges[challenge_index].correct
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	portal_energy.value = challenge_index + 1
	portal_visual.set_energy(challenge_index + 1)
	mission_progress.update_progress(
		challenge_index + 1,
		challenges.size(),
		"El portal · %d / %d" % [challenge_index + 1, challenges.size()]
	)
	progress_label.text = "%d / %d páginas" % [challenge_index + 1, challenges.size()]
	create_tween().tween_property(
		portal_glow, "color:a", minf(0.16 + 0.06 * (challenge_index + 1), 0.62), 0.5
	)
	next_button.show()
	next_button.grab_focus()
	guide.watch_continue(next_button)
	if animate:
		challenge_art.celebrate()
		guide.page_to_book(
			challenge_art.global_position,
			$UI/LevelHeader/Bar/BookButton.get_global_rect().get_center()
		)
	GameManager.checkpoint(self)


func _advance_challenge() -> void:
	if not _awaiting_continue:
		return
	challenge_index += 1
	_show_challenge()


func _show_help() -> void:
	if _awaiting_continue:
		guide.point_at(next_button)
	elif not _resolving:
		if recall.visible:
			_attempt.guidance = true
			GameManager.checkpoint(self)
			recall.explain_support()
			guide.highlight(recall)
			return
		mark_learning_help()
		if _help_stage < 2:
			guide.highlight(challenge_art if _help_stage == 0 else options_box)
			_help_stage += 1
			return
		for button: Button in option_buttons:
			if button.text == challenges[challenge_index].correct:
				guide.point_at(button)
				return


func get_checkpoint_state() -> Dictionary:
	var state: Dictionary = {
		"challenge": challenge_index,
		"waiting": _awaiting_continue,
		"attempt": _attempt.snapshot(),
		"layout_seed": _layout_seed,
		"recall_text": recall.first.text,
		"scaffold": recall.scaffold_state(),
		"cards": _practice_fallback,
		"order": _challenge_order.duplicate(),
		"portal_variants": _portal_variants.duplicate()
	}
	if not _portal_pool_keys.is_empty():
		state.portal_pool_keys = _portal_pool_keys.duplicate(true)
	return state.duplicate(true)


func mark_learning_help() -> void:
	if not _resolving:
		_attempt.use_content_help()
		GameManager.checkpoint(self)


func _practice_with_cards() -> void:
	_practice_fallback = true
	$UI/OptionsPanel.show()
	$UI/ChallengePanel.size.y = 242
	mark_learning_help()
	recall.hide()
	options_box.show()
	challenge_art.show()
	feedback_label.text = "Practiquemos. El portal seguirá esperando."


func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del ejercicio."])
	var issues: PackedStringArray = content.get_configuration_issues(5)
	var slots: int = get_node("UI/OptionsPanel/Content/Options").get_child_count()
	for challenge: ExerciseEntry in challenges:
		if challenge != null and challenge.options.size() > slots:
			issues.append(
				"Añade botones en UI/OptionsPanel/Content/Options para todas las respuestas."
			)
			break
	return issues


func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()


func _on_scaffold_changed() -> void:
	if recall.visible and not recall.is_preparing():
		GameManager.schedule_checkpoint(self)


func debug_can_answer() -> bool:
	return (
		OS.is_debug_build()
		and not _resolving
		and not _awaiting_continue
		and challenge_index < challenges.size()
	)


func debug_answer() -> void:
	if not debug_can_answer():
		return
	mark_learning_help()
	var answer: String = challenges[challenge_index].correct
	if recall.visible:
		recall.debug_fill([answer])
	_on_option_pressed(answer)
