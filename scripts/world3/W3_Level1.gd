## Mundo 3, nivel 1 — Hechizos con adjetivos
## El jugador construye las frases del GDD combinando un sustantivo y un
## adjetivo. La primera vuelta ofrece traducciones; la segunda las retira.
extends Node2D

const UI_EFFECTS = preload("res://scripts/components/UIEffects.gd")
const PHRASE_BUILDER = preload("res://scripts/components/PhraseBuilderController.gd")
const EXERCISE_ENTRY = preload("res://scripts/data/ExerciseEntry.gd")

const RAW_NOUNS: Array[Dictionary] = [
	{ "maya": "mayak",  "spanish": "mesa",   "emoji": "🪑" },
	{ "maya": "lak",    "spanish": "plato",  "emoji": "🍽️" },
	{ "maya": "ch'áak", "spanish": "cama",   "emoji": "🛏️" },
	{ "maya": "chan",   "spanish": "silla",  "emoji": "💺" },
	{ "maya": "janal",  "spanish": "comida", "emoji": "🍲" },
]
static var NOUNS: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_NOUNS)

const RAW_ADJECTIVES: Array[Dictionary] = [
	{ "maya": "mejen",    "spanish": "pequeña" },
	{ "maya": "nojoch",   "spanish": "grande" },
	{ "maya": "Jats'uts", "spanish": "bonita" },
	{ "maya": "ki'",      "spanish": "deliciosa" },
	{ "maya": "jach'",    "spanish": "fuerte" },
]
static var ADJECTIVES: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_ADJECTIVES)

## Peticiones definidas por el GDD. Las frases se guardan completas para no
## intentar inferir las uniones morfológicas desde el código.
const RAW_CHALLENGES: Array[Dictionary] = [
	{ "animal": "Peek'", "animal_spanish": "Perro", "sprite": "res://Arte/sprites/animal_peek.svg", "noun": "chan", "adjective": "jach'", "phrase": "In chan'e' jach'", "translation": "Mi silla es fuerte." },
	{ "animal": "Miis", "animal_spanish": "Gato", "sprite": "res://Arte/sprites/animal_miis.svg", "noun": "ch'áak", "adjective": "mejen", "phrase": "In ch'áake' mejen", "translation": "Mi cama es pequeña." },
	{ "animal": "Kaax", "animal_spanish": "Gallina", "sprite": "res://Arte/sprites/animal_kaax.svg", "noun": "lak", "adjective": "Jats'uts", "phrase": "In lake' Jats'uts", "translation": "Mi plato es bonito." },
	{ "animal": "Áak", "animal_spanish": "Tortuga", "sprite": "res://Arte/sprites/animal_aak.svg", "noun": "mayak", "adjective": "nojoch", "phrase": "In mayake' nojoch", "translation": "Mi mesa es grande." },
	{ "animal": "K'éek'en", "animal_spanish": "Cerdo", "sprite": "res://Arte/sprites/animal_keek_en.svg", "noun": "janal", "adjective": "ki'", "phrase": "In janale' ki'", "translation": "Mi comida es deliciosa." },
	{ "animal": "Kéej", "animal_spanish": "Venado", "sprite": "res://Arte/sprites/animal_keej.svg", "noun": "chan", "adjective": "Jats'uts", "phrase": "In chan'e' Jats'uts", "translation": "Mi silla es bonita." },
]
static var CHALLENGES: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_CHALLENGES)

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
var result_art: MeaningIllustration

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
@onready var cast_button: Button = $UI/ChoicesPanel/Content/CastButton
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var progress_label: Label = $UI/StatusPanel/StatusRow/ProgressLabel
@onready var instruction_label: Label = $UI/StatusPanel/StatusRow/InstructionLabel
@onready var magic_label: Label = $UI/TopBar/Bar/MagicLabel
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
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
	result_art = MeaningIllustration.new()
	result_art.position = Vector2(14, 100)
	result_art.size = Vector2(145, 94)
	spell_panel.add_child(result_art)
	var state := GameManager.get_scene_state(self)
	round_plan = ExerciseProgress.restore_rounds(state.get("plan"), CHALLENGES.size(), round_plan)
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
	for item: Dictionary in PHRASE_BUILDER.build_two_phase_plan(CHALLENGES.size()):
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
	if round_index >= round_plan.size():
		_finish_level()
		return
	_resolving = false
	_awaiting_continue = false
	_mistakes = 0
	selected_noun = ""
	selected_adjective = ""
	result_art.hide()
	PHRASE_BUILDER.clear_mark(noun_slot)
	PHRASE_BUILDER.clear_mark(adjective_slot)
	feedback_label.text = "1 Objeto   →   2 Cómo es   →   3 Crear"
	feedback_label.add_theme_color_override("font_color", COLOR_INK)
	var challenge := _current_challenge()
	var guided := _is_guided_phase()
	animal_sprite.texture = load(challenge.sprite)
	animal_name.text = "%s · %s" % [challenge.animal_spanish, challenge.animal]
	phase_label.text = "Aprende" if guided else "Recuerda"
	request_label.text = "Ayuda a %s" % challenge.animal
	target_art.show_meaning(challenge.noun, challenge.adjective)
	target_badge.text = challenge.translation if guided else ""
	instruction_label.text = "Elige o arrastra."
	translation_label.text = ""
	_update_slots()
	_update_choice_labels()
	_set_choices_enabled(true)
	cast_button.text = "Crear ✦"
	progress_label.text = "%s %d / %d" % ["Aprende" if guided else "Repasa", round_index % CHALLENGES.size() + 1, CHALLENGES.size()]
	if not noun_buttons.is_empty():
		(noun_buttons.values()[0] as Button).grab_focus()
	if round_index == 0 and "phrases" not in GameManager.tutorials_seen:
		call_deferred("_show_help")
	GameManager.checkpoint(self)

func _current_challenge() -> ExerciseEntry:
	return CHALLENGES[round_plan[round_index]]

func _is_guided_phase() -> bool:
	return round_index < CHALLENGES.size()

func _challenge_prompt(challenge: ExerciseEntry) -> String:
	var noun := _noun_data(challenge.noun)
	var adjective := _adjective_data(challenge.adjective)
	return "%s %s" % [str(noun.spanish).capitalize(), adjective.spanish]

func _update_choice_labels() -> void:
	var guided := _is_guided_phase()
	for noun: ExerciseEntry in NOUNS:
		var button: Button = noun_buttons[noun.maya]
		button.text = "%s\n%s" % [noun.maya, str(noun.spanish).capitalize()] if guided else noun.maya
		button.icon = load(GameManager.get_book_illustration(noun.maya)) if guided else null
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 28)
	for adjective: ExerciseEntry in ADJECTIVES:
		var button: Button = adjective_buttons[adjective.maya]
		button.text = "%s\n%s" % [adjective.maya, str(adjective.spanish).capitalize()] if guided else adjective.maya
		button.icon = load(GameManager.get_book_illustration(adjective.maya)) if guided else null
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 28)

func _select_noun(word: String) -> void:
	if _resolving:
		return
	selected_noun = word
	_update_slots()
	_update_button_states()
	_celebrate_selection(noun_slot)

func _select_adjective(word: String) -> void:
	if _resolving:
		return
	selected_adjective = word
	_update_slots()
	_update_button_states()
	_celebrate_selection(adjective_slot)

func _celebrate_selection(slot: Control) -> void:
	PHRASE_BUILDER.clear_mark(slot)
	PHRASE_BUILDER.celebrate(slot, feedback_label, "Colocado", COLOR_INK)
	GameManager.checkpoint(self)
	if round_index == 0 and "phrases" not in GameManager.tutorials_seen:
		_show_help()

func _update_slots() -> void:
	noun_slot.text = "objeto"
	if selected_noun != "":
		for challenge: ExerciseEntry in CHALLENGES:
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
	GameManager.learn_word(challenge.noun)
	GameManager.learn_word(challenge.adjective)
	GameManager.mark_tutorial_seen("phrases")
	_render_success(true)

func _show_incorrect_feedback(challenge: ExerciseEntry) -> void:
	_mistakes += 1
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
		_show_help()

func _pulse_error_slots(noun_ok: bool, adjective_ok: bool) -> void:
	for slot: Control in [noun_slot, adjective_slot]:
		var is_ok := noun_ok if slot == noun_slot else adjective_ok
		if is_ok:
			continue
		var tween := create_tween()
		tween.tween_property(slot, "modulate", Color(1.25, 0.55, 0.55, 1.0), 0.08)
		tween.tween_property(slot, "modulate", Color.WHITE, 0.2)

func _phrase_noun(phrase: String) -> String:
	var parts := phrase.split(" ")
	return parts[1] if parts.size() > 1 else selected_noun

func _noun_data(word: String) -> ExerciseEntry:
	for noun: ExerciseEntry in NOUNS:
		if noun.maya == word:
			return noun
	return null

func _adjective_data(word: String) -> ExerciseEntry:
	for adjective: ExerciseEntry in ADJECTIVES:
		if adjective.maya == word:
			return adjective
	return null

func _noun_emoji(word: String) -> String:
	var data := _noun_data(word)
	return data.emoji if data != null and data.emoji != "" else "✨"

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
	result_art.show_meaning(challenge.noun, challenge.adjective)
	cast_button.text = "Continuar →"
	cast_button.disabled = false
	cast_button.grab_focus()
	guide.watch_continue(cast_button)
	if animate:
		result_art.celebrate()
		guide.page_to_book(result_art.global_position, $UI/TopBar/Bar/BookButton.get_global_rect().get_center())
	GameManager.checkpoint(self)

func _show_help() -> void:
	if _awaiting_continue:
		guide.point_at(cast_button)
	elif not _resolving:
		var challenge := _current_challenge()
		if selected_noun != challenge.noun:
			guide.demonstrate([(noun_buttons[challenge.noun] as Control).get_global_rect().get_center(), noun_slot.get_global_rect().get_center()])
			feedback_label.text = "1 Elige o arrastra el objeto."
		elif selected_adjective != challenge.adjective:
			guide.demonstrate([(adjective_buttons[challenge.adjective] as Control).get_global_rect().get_center(), adjective_slot.get_global_rect().get_center()])
			feedback_label.text = "2 Elige cómo es."
		else:
			guide.point_at(cast_button)
			feedback_label.text = "3 ¡Crea el objeto!"

func get_checkpoint_state() -> Dictionary:
	return {"plan": round_plan, "round": round_index, "noun": selected_noun, "adjective": selected_adjective, "waiting": _awaiting_continue}
