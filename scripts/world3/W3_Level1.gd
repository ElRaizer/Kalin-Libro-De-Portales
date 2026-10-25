@tool
## Mundo 3, nivel 1 — Hechizos con adjetivos
## El jugador construye las frases del GDD combinando un sustantivo y un
## adjetivo. La primera vuelta ofrece traducciones; la segunda las retira.
extends Node2D

@export var content: ExerciseSet
@export var vary_combinations := true
var _session_challenges: Array[ExerciseEntry] = []
var _combination_plan: Array[String] = []
var _combination_animals: Array[String] = []
var nouns: Array[ExerciseEntry]:
	get:
		return content.nouns
var adjectives: Array[ExerciseEntry]:
	get:
		return content.adjectives
var challenges: Array[ExerciseEntry]:
	get:
		return content.challenges if _session_challenges.is_empty() else _session_challenges

const PHRASE_BUILDER = preload("res://scripts/components/PhraseBuilderController.gd")


## Peticiones definidas por el GDD. Las frases se guardan completas para no
## intentar inferir las uniones morfológicas desde el código.

const COLOR_INK := Color("3b2415")
const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var round_plan: Array[int] = []
var round_index: int = 0
var selected_noun: String = ""
var selected_adjective: String = ""
var noun_buttons: Dictionary = {}
var adjective_buttons: Dictionary = {}
var _resolving: bool = false
var _awaiting_continue := false
var _mistakes := 0
var guide: LearningGuide
var target_art: MeaningIllustration
@onready var result_art: MeaningIllustration = $UI/FeedbackPanel/ResultArt
@onready var mission_progress: MissionProgress = $UI/MissionProgress
@onready var mission_break: MissionBreak = $UI/MissionBreak
var _help_stage := 0
var _blocks_seen: Array[int] = []
var _attempt := LearningAttempt.new()
var _layout_seed := 1
var _saved_scaffold: Dictionary = {}
var _practice_fallback := false
@onready var recall: RecallPanel = $UI/ChoicesPanel/RecallPanel

@onready var spell_panel: Panel = $UI/SpellPanel
@onready var choices_panel: Panel = $UI/ChoicesPanel
@onready var completion: CompletionOverlay = $UI/CompletionOverlay
@onready var animal_sprite: TextureRect = $UI/RequestPanel/Content/AnimalSprite
@onready var animal_name: Label = $UI/RequestPanel/Content/AnimalName
@onready var request_label: Label = $UI/RequestPanel/Content/RequestLabel
@onready var target_badge: Label = $UI/RequestPanel/Content/TargetBadge
@onready var phase_label: Label = $UI/RequestPanel/Content/PhaseLabel
@onready var noun_slot: Label = $UI/SpellPanel/Content/Sentence/NounSlot
@onready var adjective_slot: Label = $UI/SpellPanel/Content/Sentence/AdjectiveSlot
@onready var translation_label: Label = $UI/SpellPanel/Content/TranslationLabel
@onready var noun_grid: GridContainer = $UI/ChoicesPanel/Content/NounGrid
@onready var adjective_grid: GridContainer = $UI/ChoicesPanel/Content/AdjectiveGrid
@onready var cast_button: Button = $UI/CastButton
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var _feedback_left: float = feedback_label.offset_left
@onready var _feedback_color: Color = feedback_label.get_theme_color("font_color")
@onready var progress_label: Label = $UI/StatusPanel/StatusRow/ProgressLabel
@onready var instruction_label: Label = $UI/StatusPanel/StatusRow/InstructionLabel
@onready var magic_label: Label = $UI/TopBar/Bar/MagicLabel
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues := get_configuration_issues()
	if not issues.is_empty():
		push_error("Configuración incompleta: " + "; ".join(issues))
		return
	_setup_drop_slots()
	recall.set_workspace("taller")
	_build_choice_buttons()
	_configure_keyboard_navigation()
	cast_button.pressed.connect(_on_cast_pressed)
	recall.submitted.connect(_on_cast_pressed)
	recall.practice_requested.connect(_practice_with_cards)
	recall.support_used.connect(mark_learning_help)
	recall.answer_changed.connect(_on_scaffold_changed)
	recall.first.text_changed.connect(_on_recall_changed)
	recall.second.text_changed.connect(_on_recall_changed)
	GameManager.magic_points_changed.connect(_on_magic_points_changed)
	_on_magic_points_changed(GameManager.magic_points)
	completion.next_pressed.connect(_on_next_level_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	guide = LearningGuide.install(self, $UI/TopBar/Bar, _show_help)
	target_art = $UI/RequestPanel/Content/TargetArt
	mission_break.continued.connect(func():
		_refresh_step()
		guide.watch_action(noun_slot)
	)
	var state := GameManager.get_scene_state(self)
	_attempt.restore(state.get("attempt"))
	_saved_scaffold = state.get("scaffold", {}) if state.get("scaffold") is Dictionary else {}
	_practice_fallback = bool(state.get("cards", false))
	_layout_seed = int(state.get("layout_seed", randi_range(1, 2000000000)))
	if vary_combinations:
		var session := CombinationVariation.exercises(content, state, _layout_seed, 3)
		if not session.is_empty():
			_session_challenges.assign(session.entries)
			_combination_plan.assign(session.ids)
			_combination_animals.assign(session.animals)
			for entry: ExerciseEntry in _session_challenges:
				entry.sprite = GameManager.get_visual_texture(entry.animal)
	_build_round_plan(state)
	noun_grid.set_meta("layout_seed", _layout_seed)
	adjective_grid.set_meta("layout_seed", _layout_seed)
	_blocks_seen = ExerciseProgress.restore_markers(state.get("blocks"), challenges.size() * 2)
	round_plan = ExerciseProgress.restore_rounds(state.get("plan"), challenges.size(), round_plan)
	round_index = clampi(int(state.get("round", 0)), 0, round_plan.size())
	_show_round()
	if recall.visible and state.has("noun"):
		recall.first.text = str(state.get("noun", ""))
		recall.second.text = str(state.get("adjective", ""))
	if not _resolving:
		var noun := str(state.get("noun", ""))
		var adjective := str(state.get("adjective", ""))
		if noun in noun_buttons:
			_select_noun(noun)
		if adjective in adjective_buttons:
			_select_adjective(adjective)
		if bool(state.get("waiting", false)) and noun == _current_challenge().noun and adjective == _current_challenge().adjective:
			_render_success(false)

func _build_round_plan(state: Dictionary = {}) -> void:
	round_plan.clear()
	for item: Dictionary in ReplayVariation.two_phase(challenges.size(), _layout_seed, true, ReplayVariation.previous(state, "plan", [])):
		round_plan.append(int(item.challenge))

func _build_choice_buttons() -> void:
	noun_buttons = PHRASE_BUILDER.collect_buttons(noun_grid, _select_noun)
	adjective_buttons = PHRASE_BUILDER.collect_buttons(adjective_grid, _select_adjective)

func _configure_keyboard_navigation() -> void:
	PHRASE_BUILDER.configure_navigation(noun_grid, adjective_grid, cast_button)

func _setup_drop_slots() -> void:
	noun_slot.connect("word_dropped", _select_noun)
	adjective_slot.connect("word_dropped", _select_adjective)

func _show_round() -> void:
	guide.stop()
	mission_break.hide()
	if round_index >= round_plan.size():
		_finish_level()
		return
	_resolving = false
	_awaiting_continue = false
	var semantic := ExerciseRecallFlow.context("workshop", _current_challenge().animal, [_current_challenge().noun, _current_challenge().adjective], _is_guided_phase(), _layout_seed)
	var continuing := ExerciseRecallFlow.begin(_attempt, semantic, "world3:%d@%d" % [round_index, _layout_seed])
	_mistakes = _attempt.mistakes
	_practice_fallback = _practice_fallback if continuing else false
	recall.hide()
	ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, false)
	$UI/ChoicesPanel/Content.show()
	_help_stage = 0
	selected_noun = ""
	selected_adjective = ""
	result_art.hide()
	PHRASE_BUILDER.clear_mark(noun_slot)
	PHRASE_BUILDER.clear_mark(adjective_slot)
	feedback_label.text = "Elige el objeto."
	feedback_label.offset_left = _feedback_left
	feedback_label.add_theme_color_override("font_color", _feedback_color)
	var challenge := _current_challenge()
	var guided := _is_guided_phase()
	if guided:
		GameManager.learn_word(challenge.noun)
		GameManager.learn_word(challenge.adjective)
	animal_sprite.texture = challenge.sprite
	animal_name.text = challenge.animal
	phase_label.text = "Práctica con tarjetas" if _practice_fallback else ("Práctica" if guided else "Recuerdo")
	request_label.text = "Ayuda a %s" % challenge.animal
	target_art.show_meaning(challenge.noun, challenge.adjective)
	target_art.visible = guided or _practice_fallback
	target_badge.text = challenge.translation
	instruction_label.text = ""
	translation_label.text = ""
	_update_slots()
	_update_choice_labels()
	PHRASE_BUILDER.show_even_choices(noun_buttons, challenge.noun, round_index)
	PHRASE_BUILDER.show_even_choices(adjective_buttons, challenge.adjective, round_index)
	_configure_keyboard_navigation()
	_set_choices_enabled(true)
	cast_button.text = "Crear ✦"
	_refresh_step()
	if not guided and not _practice_fallback:
		$UI/ChoicesPanel/Content.hide()
		ExerciseRecallFlow.prepare(recall, ["Objeto", "Cómo es"], [challenge.noun, challenge.adjective], _attempt, _saved_scaffold if continuing else {})
		_saved_scaffold = {}
		ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, true)
		feedback_label.text = "Recuerda las dos palabras de la petición."
		cast_button.disabled = false
	mission_progress.update_progress(round_index, round_plan.size(), _phase_caption())
	progress_label.text = "%s %d / %d" % ["Aprende" if guided else "Repasa", round_index % challenges.size() + 1, challenges.size()]
	PHRASE_BUILDER.focus_first_visible(noun_grid)
	if round_index == 0 and "phrases" not in GameManager.tutorials_seen:
		call_deferred("_show_help")
	else:
		guide.watch_action(noun_slot)
	_show_block()
	GameManager.checkpoint(self)

func _phase_caption() -> String:
	return "El taller · %d / %d · %s" % [round_index + 1, round_plan.size(), ExerciseRecallFlow.caption(recall, _is_guided_phase(), _practice_fallback)]

func _show_block() -> void:
	if round_index > 0 and round_index % 3 == 0 and round_index not in _blocks_seen:
		_blocks_seen.append(round_index)
		guide.stop()
		var recent: ExerciseEntry = challenges[round_plan[round_index - 1]]
		mission_break.show_block("¡Otro objeto a su medida!", "tamano", recent.noun, recent.adjective, recent.animal)
		if round_index == challenges.size():
			mission_break.offer_walk("world3_explore1", "world3_level1")

func _refresh_step() -> void:
	ExercisePresentation.focus_step(noun_grid, adjective_grid, not selected_noun.is_empty())
	$UI/ChoicesPanel/Content/NounHeading.text = "1 · Objeto" + ("  · elegido" if not selected_noun.is_empty() else "")
	$UI/ChoicesPanel/Content/AdjectiveHeading.text = "2 · Cómo es" + ("  · elegido" if not selected_adjective.is_empty() else "")

func _current_challenge() -> ExerciseEntry:
	return challenges[round_plan[round_index]]

func _is_guided_phase() -> bool:
	return round_index < challenges.size()

func _update_choice_labels() -> void:
	var guided := _is_guided_phase()
	var bridge := not guided and round_index < challenges.size() + 3
	for noun: ExerciseEntry in nouns:
		var button: Button = noun_buttons[noun.maya]
		button.text = "%s\n%s" % [noun.maya, str(noun.spanish).capitalize()] if bridge else noun.maya
		button.icon = GameManager.get_visual_texture(noun.maya) if guided else null
	for adjective: ExerciseEntry in adjectives:
		var button: Button = adjective_buttons[adjective.maya]
		button.text = "%s\n%s" % [adjective.maya, str(adjective.spanish).capitalize()] if bridge else adjective.maya
		button.icon = GameManager.get_visual_texture(adjective.maya) if guided else null

func _select_noun(word: String) -> void:
	if _resolving:
		return
	guide.stop()
	selected_noun = word
	if recall.visible:
		recall.first.text = word
		return
	_refresh_step()
	_update_slots()
	_update_button_states()
	_celebrate_selection(noun_slot)

func _select_adjective(word: String) -> void:
	if _resolving:
		return
	guide.stop()
	selected_adjective = word
	if recall.visible:
		recall.second.text = word
		return
	_refresh_step()
	_update_slots()
	_update_button_states()
	_celebrate_selection(adjective_slot)

func _celebrate_selection(slot: Control) -> void:
	if not selected_noun.is_empty():
		result_art.show()
		result_art.show_meaning(selected_noun, selected_adjective)
		feedback_label.offset_left = maxf(_feedback_left, result_art.position.x + result_art.size.x + 9)
	PHRASE_BUILDER.clear_mark(slot)
	PHRASE_BUILDER.celebrate(slot, feedback_label, "Elige cómo es." if selected_adjective.is_empty() else "¡Crea el objeto!", _feedback_color)
	GameManager.checkpoint(self)
	if round_index == 0 and "phrases" not in GameManager.tutorials_seen:
		_show_help()
	else:
		guide.watch_action(adjective_slot if selected_adjective.is_empty() else cast_button)

func _update_slots() -> void:
	noun_slot.text = "objeto"
	if selected_noun != "":
		noun_slot.text = selected_noun
	adjective_slot.text = selected_adjective if selected_adjective != "" else "cómo es"
	cast_button.disabled = selected_noun == "" or selected_adjective == "" or _resolving

func _update_button_states() -> void:
	PHRASE_BUILDER.set_button_states(noun_buttons, selected_noun, adjective_buttons, selected_adjective)

func _set_choices_enabled(enabled: bool) -> void:
	PHRASE_BUILDER.set_enabled(noun_buttons, adjective_buttons, enabled)
	_update_button_states()
	cast_button.disabled = not enabled or selected_noun == "" or selected_adjective == ""

func _on_cast_pressed() -> void:
	if _awaiting_continue:
		round_index += 1
		_show_round()
		return
	if _resolving:
		return
	var challenge := _current_challenge()
	if recall.visible:
		if not recall.ready_to_submit():
			return
		var answers := recall.values()
		var noun_match := RecallPanel.match_word(answers[0], challenge.noun)
		var adjective_match := RecallPanel.match_word(answers[1], challenge.adjective)
		selected_noun = noun_match.word
		selected_adjective = adjective_match.word
		_attempt.supported = _attempt.supported or noun_match.supported or adjective_match.supported
	if selected_noun != challenge.noun or selected_adjective != challenge.adjective:
		_show_incorrect_feedback(challenge)
		return
	GameManager.learn_word(challenge.noun)
	GameManager.learn_word(challenge.adjective)
	GameManager.record_learning([challenge.noun, challenge.adjective], ExerciseRecallFlow.phase(recall, _is_guided_phase()), _attempt.context, _attempt.supported, _attempt.mistakes)
	GameManager.mark_tutorial_seen("phrases")
	_render_success(true)

func _show_incorrect_feedback(challenge: ExerciseEntry) -> void:
	_attempt.miss()
	_mistakes += 1
	guide.stop()
	result_art.show()
	result_art.show_meaning(selected_noun, selected_adjective)
	feedback_label.offset_left = maxf(_feedback_left, result_art.position.x + result_art.size.x + 9)
	CharacterReaction.play(animal_sprite, false)
	var noun_ok: bool = selected_noun == str(challenge.noun)
	var adjective_ok: bool = selected_adjective == str(challenge.adjective)
	if not noun_ok and not adjective_ok:
		feedback_label.text = "Revisa la petición. Cambia el objeto y cómo es."
	elif not noun_ok:
		feedback_label.text = "Cómo es: ✓. Elige el objeto que pidió %s." % str(challenge.animal_spanish).to_lower()
	else:
		feedback_label.text = "Objeto: ✓. Cambia cómo es."
	feedback_label.add_theme_color_override("font_color", COLOR_ERROR)
	UIEffects.shake(self, choices_panel, 8.0)
	_pulse_error_slots(noun_ok, adjective_ok)
	PHRASE_BUILDER.mark_slot(noun_slot, noun_ok)
	PHRASE_BUILDER.mark_slot(adjective_slot, adjective_ok)
	if recall.visible:
		recall.advance_support()
	elif _mistakes >= 2:
		_help_stage = mini(_mistakes - 2, 2)
		_show_help()
	GameManager.checkpoint(self)

func _pulse_error_slots(noun_ok: bool, adjective_ok: bool) -> void:
	for slot: Control in [noun_slot, adjective_slot]:
		var is_ok := noun_ok if slot == noun_slot else adjective_ok
		if is_ok:
			continue
		slot.pulse_error()

func _phrase_noun(phrase: String) -> String:
	return phrase.get_slice(" · ", 0)

func _finish_level() -> void:
	_resolving = true
	_awaiting_continue = false
	guide.stop()
	GameManager.complete_level(3, 1)
	completion.show_completion("¡Objetos a la medida!", "Tus palabras cambian los objetos. Sal a probarlas con tus amigos.", "Pasear por la aldea →")
	GameManager.checkpoint(self)

func _on_magic_points_changed(value: int) -> void:
	magic_label.text = GameManager.recovered_pages_text()

func _safe_navigate(key: String) -> void:
	_resolving = true
	GameManager.go_to_scene(key)

func _on_menu_pressed() -> void:
	_safe_navigate("main_menu")

func _on_next_level_pressed() -> void:
	GameManager.start_walk("world3_explore1", "world3_mission1")

func _on_book_pressed() -> void:
	libro.show_book($UI/TopBar/Bar/BookButton)

func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))

func _render_success(animate: bool) -> void:
	_resolving = true
	_awaiting_continue = true
	var result := _current_challenge()
	ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, true)
	$UI/ChoicesPanel/Content.hide()
	recall.show_result(result.noun, result.adjective, result.phrase, result.translation)
	mission_progress.update_progress(round_index + 1, round_plan.size(), "El taller · %d / %d · ¡Creado!" % [round_index + 1, round_plan.size()])
	guide.stop()
	_set_choices_enabled(false)
	var challenge := _current_challenge()
	noun_slot.text = _phrase_noun(challenge.phrase)
	adjective_slot.text = challenge.adjective
	PHRASE_BUILDER.mark_slot(noun_slot, true)
	PHRASE_BUILDER.mark_slot(adjective_slot, true)
	translation_label.text = "%s\n%s" % [challenge.phrase, challenge.translation]
	translation_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	feedback_label.text = "✓ ¡Ya está a su medida!"
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	result_art.show()
	feedback_label.offset_left = maxf(_feedback_left, result_art.position.x + result_art.size.x + 9)
	result_art.show_meaning(challenge.noun, challenge.adjective)
	cast_button.text = "Continuar →"
	cast_button.disabled = false
	cast_button.grab_focus()
	guide.watch_continue(cast_button)
	if animate:
		result_art.celebrate()
		CharacterReaction.play(animal_sprite)
		guide.page_to_book(result_art.global_position, $UI/TopBar/Bar/BookButton.get_global_rect().get_center())
	GameManager.checkpoint(self)

func _show_help() -> void:
	if mission_break.visible:
		guide.point_at(mission_break.continue_button)
		return
	if _awaiting_continue:
		guide.point_at(cast_button)
		return
	if _resolving:
		return
	mark_learning_help()
	if recall.visible:
		recall.explain_support()
		guide.highlight(recall)
		return
	var challenge := _current_challenge()
	var needs_noun := selected_noun != challenge.noun
	var grid: Control = noun_grid if needs_noun else adjective_grid
	var slot: Control = noun_slot if needs_noun else adjective_slot
	if not selected_noun.is_empty() and not selected_adjective.is_empty() and _mistakes == 0:
		guide.point_at(cast_button)
	elif round_index == 0 and "phrases" not in GameManager.tutorials_seen or _help_stage >= 2:
		var button: Control = noun_buttons[challenge.noun] if needs_noun else adjective_buttons[challenge.adjective]
		guide.drag_between(button, slot)
	elif _help_stage == 0:
		guide.highlight(slot)
	else:
		guide.highlight(grid)
	_help_stage += 1
	feedback_label.text = "Elige el objeto." if needs_noun else "Elige cómo es."

func get_checkpoint_state() -> Dictionary:
	var state := {"plan": round_plan, "round": round_index, "noun": recall.first.text if recall.visible and not recall._showing_result else selected_noun, "adjective": recall.second.text if recall.visible and not recall._showing_result else selected_adjective, "waiting": _awaiting_continue, "blocks": _blocks_seen, "attempt": _attempt.snapshot(), "layout_seed": _layout_seed, "cards": _practice_fallback, "scaffold": recall.scaffold_state()}
	if not _combination_plan.is_empty():
		state.merge({"combination_plan": _combination_plan.duplicate(), "combination_animals": _combination_animals.duplicate()})
	return state

func mark_learning_help() -> void:
	if not _resolving:
		_attempt.supported = true
		GameManager.checkpoint(self)

func _practice_with_cards() -> void:
	mark_learning_help()
	_practice_fallback = true
	ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, false)
	recall.hide()
	$UI/ChoicesPanel/Content.show()
	target_art.show()
	_update_choice_labels()
	_refresh_step()
	phase_label.text = "Práctica con tarjetas"
	mission_progress.update_progress(round_index, round_plan.size(), _phase_caption())
	feedback_label.text = "Practiquemos con las tarjetas."
	PHRASE_BUILDER.focus_first_visible(noun_grid)
	GameManager.checkpoint(self)

func _on_recall_changed(_text: String) -> void:
	if recall.visible and not _resolving:
		cast_button.disabled = false

func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del ejercicio."])
	return content.get_configuration_issues(3)

func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()


func _on_scaffold_changed() -> void:
	if recall.visible and not recall._setting_up:
		phase_label.text = ExerciseRecallFlow.caption(recall, false, false)
		mission_progress.update_progress(round_index, round_plan.size(), _phase_caption())
		GameManager.schedule_checkpoint(self)

func debug_can_answer() -> bool:
	return OS.is_debug_build() and not _resolving and not _awaiting_continue and not mission_break.visible

func debug_answer() -> void:
	if not debug_can_answer():
		return
	mark_learning_help()
	var challenge := _current_challenge()
	if recall.visible:
		recall.debug_fill([challenge.noun, challenge.adjective])
	else:
		_select_noun(challenge.noun)
		_select_adjective(challenge.adjective)
	_on_cast_pressed()
