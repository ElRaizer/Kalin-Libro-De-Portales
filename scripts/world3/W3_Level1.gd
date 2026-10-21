@tool
## Mundo 3, nivel 1 — Hechizos con adjetivos
## El jugador construye las frases del GDD combinando un sustantivo y un
## adjetivo. La primera vuelta ofrece traducciones; la segunda las retira.
extends Node2D

@export var content: ExerciseSet
var nouns: Array[ExerciseEntry]:
	get:
		return content.nouns
var adjectives: Array[ExerciseEntry]:
	get:
		return content.adjectives
var challenges: Array[ExerciseEntry]:
	get:
		return content.challenges

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
	_build_round_plan()
	_build_choice_buttons()
	_configure_keyboard_navigation()
	cast_button.pressed.connect(_on_cast_pressed)
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
	_blocks_seen = ExerciseProgress.restore_markers(state.get("blocks"), challenges.size() * 2)
	round_plan = ExerciseProgress.restore_rounds(state.get("plan"), challenges.size(), round_plan)
	round_index = clampi(int(state.get("round", 0)), 0, round_plan.size())
	_show_round()
	if not _resolving:
		var noun := str(state.get("noun", ""))
		var adjective := str(state.get("adjective", ""))
		if noun in noun_buttons:
			_select_noun(noun)
		if adjective in adjective_buttons:
			_select_adjective(adjective)
		if bool(state.get("waiting", false)) and noun == _current_challenge().noun and adjective == _current_challenge().adjective:
			_render_success(false)

func _build_round_plan() -> void:
	for item: Dictionary in PHRASE_BUILDER.build_two_phase_plan(challenges.size()):
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
	_mistakes = 0
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
	animal_sprite.texture = challenge.sprite
	animal_name.text = challenge.animal
	phase_label.text = "Aprende" if guided else "Recuerda"
	request_label.text = "Ayuda a %s" % challenge.animal
	target_art.show_meaning(challenge.noun, challenge.adjective)
	target_badge.text = challenge.translation if guided else ""
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
	return "El taller · %d / 3 · %s" % [round_index % 3 + 1, "Con ayuda" if _is_guided_phase() else ("Una pista" if round_index < challenges.size() + 3 else "A tu turno")]

func _show_block() -> void:
	if round_index > 0 and round_index % 3 == 0 and round_index not in _blocks_seen:
		_blocks_seen.append(round_index)
		guide.stop()
		var recent: ExerciseEntry = challenges[round_plan[round_index - 1]]
		mission_break.show_block("¡Otro objeto a su medida!", "tamano", recent.noun, recent.adjective, recent.animal)

func _refresh_step() -> void:
	ExercisePresentation.focus_step(noun_grid, adjective_grid, not selected_noun.is_empty())
	$UI/ChoicesPanel/Content/NounHeading.text = "1 · Objeto" + ("  ✓" if not selected_noun.is_empty() else "")
	$UI/ChoicesPanel/Content/AdjectiveHeading.text = "2 · Cómo es" + ("  ✓" if not selected_adjective.is_empty() else "")

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
	_refresh_step()
	_update_slots()
	_update_button_states()
	_celebrate_selection(noun_slot)

func _select_adjective(word: String) -> void:
	if _resolving:
		return
	guide.stop()
	selected_adjective = word
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
		for challenge: ExerciseEntry in challenges:
			if challenge.noun == selected_noun:
				noun_slot.text = _phrase_noun(challenge.phrase)
				break
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
	if selected_noun != challenge.noun or selected_adjective != challenge.adjective:
		_show_incorrect_feedback(challenge)
		return
	AudioManager.play_sfx("acierto")
	AudioManager.play_sfx("hechizo_lanzar")
	GameManager.learn_word(challenge.noun)
	GameManager.learn_word(challenge.adjective)
	GameManager.mark_tutorial_seen("phrases")
	_render_success(true)

func _show_incorrect_feedback(challenge: ExerciseEntry) -> void:
	_mistakes += 1
	AudioManager.play_sfx("error_suave")
	guide.stop()
	result_art.show()
	result_art.show_meaning(selected_noun, selected_adjective)
	feedback_label.offset_left = maxf(_feedback_left, result_art.position.x + result_art.size.x + 9)
	CharacterReaction.play(animal_sprite, false)
	var noun_ok: bool = selected_noun == str(challenge.noun)
	var adjective_ok: bool = selected_adjective == str(challenge.adjective)
	if not noun_ok and not adjective_ok:
		feedback_label.text = "Mira la imagen. Cambia el objeto y cómo es."
	elif not noun_ok:
		feedback_label.text = "Cómo es: ✓. Elige el objeto que pidió %s." % str(challenge.animal_spanish).to_lower()
	else:
		feedback_label.text = "Objeto: ✓. Cambia cómo es."
	feedback_label.add_theme_color_override("font_color", COLOR_ERROR)
	var original_x := choices_panel.position.x
	var tween := create_tween()
	tween.tween_property(choices_panel, "position:x", original_x - 8.0, 0.05)
	tween.tween_property(choices_panel, "position:x", original_x + 8.0, 0.05)
	tween.tween_property(choices_panel, "position:x", original_x, 0.06)
	_pulse_error_slots(noun_ok, adjective_ok)
	PHRASE_BUILDER.mark_slot(noun_slot, noun_ok)
	PHRASE_BUILDER.mark_slot(adjective_slot, adjective_ok)
	if _mistakes >= 2:
		_help_stage = mini(_mistakes - 2, 2)
		_show_help()

func _pulse_error_slots(noun_ok: bool, adjective_ok: bool) -> void:
	for slot: Control in [noun_slot, adjective_slot]:
		var is_ok := noun_ok if slot == noun_slot else adjective_ok
		if is_ok:
			continue
		slot.pulse_error()

func _phrase_noun(phrase: String) -> String:
	var parts := phrase.split(" ")
	return parts[1] if parts.size() > 1 else selected_noun

func _finish_level() -> void:
	_resolving = true
	_awaiting_continue = false
	guide.stop()
	GameManager.complete_level(3, 1)
	completion.show_completion("¡Objetos a la medida!", "Tus amigos ya tienen lo que necesitan.", "A preparar comida →")
	GameManager.checkpoint(self)

func _on_magic_points_changed(value: int) -> void:
	magic_label.text = GameManager.recovered_pages_text()

func _safe_navigate(key: String) -> void:
	_resolving = true
	GameManager.go_to_scene(key)

func _on_menu_pressed() -> void:
	_safe_navigate("main_menu")

func _on_next_level_pressed() -> void:
	_safe_navigate("world3_story1")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))

func _render_success(animate: bool) -> void:
	_resolving = true
	_awaiting_continue = true
	mission_progress.update_progress(round_index + 1, round_plan.size(), "El taller · %d / 3 · ¡Creado!" % [round_index % 3 + 1])
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
	var challenge := _current_challenge()
	var needs_noun := selected_noun != challenge.noun
	var grid: Control = noun_grid if needs_noun else adjective_grid
	var slot: Control = noun_slot if needs_noun else adjective_slot
	if not selected_noun.is_empty() and not selected_adjective.is_empty() and _mistakes == 0:
		guide.point_at(cast_button)
	elif round_index == 0 and "phrases" not in GameManager.tutorials_seen or _help_stage >= 2:
		var button: Control = noun_buttons[challenge.noun] if needs_noun else adjective_buttons[challenge.adjective]
		guide.demonstrate([button.get_global_rect().get_center(), slot.get_global_rect().get_center()])
	elif _help_stage == 0:
		guide.highlight(slot)
	else:
		guide.highlight(grid)
	_help_stage += 1
	feedback_label.text = "Elige el objeto." if needs_noun else "Elige cómo es."

func get_checkpoint_state() -> Dictionary:
	return {"plan": round_plan, "round": round_index, "noun": selected_noun, "adjective": selected_adjective, "waiting": _awaiting_continue, "blocks": _blocks_seen}

func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del ejercicio."])
	return content.get_configuration_issues(3)

func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()
