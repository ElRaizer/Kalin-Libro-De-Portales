## Mundo 3, nivel 1 — Hechizos con adjetivos
## El jugador construye las frases del GDD combinando un sustantivo y un
## adjetivo. La primera vuelta ofrece traducciones; la segunda las retira.
extends Node2D

const NOUNS: Array[Dictionary] = [
	{ "maya": "mayak",  "spanish": "mesa",   "emoji": "🪑" },
	{ "maya": "lak",    "spanish": "plato",  "emoji": "🍽️" },
	{ "maya": "ch'áak", "spanish": "cama",   "emoji": "🛏️" },
	{ "maya": "chan",   "spanish": "silla",  "emoji": "💺" },
	{ "maya": "janal",  "spanish": "comida", "emoji": "🍲" },
]

const ADJECTIVES: Array[Dictionary] = [
	{ "maya": "mejen",    "spanish": "pequeña" },
	{ "maya": "nojoch",   "spanish": "grande" },
	{ "maya": "Jats'uts", "spanish": "bonita" },
	{ "maya": "ki'",      "spanish": "deliciosa" },
	{ "maya": "jach'",    "spanish": "fuerte" },
]

## Peticiones definidas por el GDD. Las frases se guardan completas para no
## intentar inferir las uniones morfológicas desde el código.
const CHALLENGES: Array[Dictionary] = [
	{ "animal": "Peek'", "animal_spanish": "Perro", "sprite": "res://Arte/sprites/animal_peek.svg", "noun": "chan", "adjective": "jach'", "phrase": "In chan'e' jach'", "translation": "Mi silla es fuerte." },
	{ "animal": "Miis", "animal_spanish": "Gato", "sprite": "res://Arte/sprites/animal_miis.svg", "noun": "ch'áak", "adjective": "mejen", "phrase": "In ch'áake' mejen", "translation": "Mi cama es pequeña." },
	{ "animal": "Kaax", "animal_spanish": "Gallina", "sprite": "res://Arte/sprites/animal_kaax.svg", "noun": "lak", "adjective": "Jats'uts", "phrase": "In lake' Jats'uts", "translation": "Mi plato es bonito." },
	{ "animal": "Áak", "animal_spanish": "Tortuga", "sprite": "res://Arte/sprites/animal_aak.svg", "noun": "mayak", "adjective": "nojoch", "phrase": "In mayake' nojoch", "translation": "Mi mesa es grande." },
	{ "animal": "K'éek'en", "animal_spanish": "Cerdo", "sprite": "res://Arte/sprites/animal_keek_en.svg", "noun": "janal", "adjective": "ki'", "phrase": "In janale' ki'", "translation": "Mi comida es deliciosa." },
	{ "animal": "Kéej", "animal_spanish": "Venado", "sprite": "res://Arte/sprites/animal_keej.svg", "noun": "chan", "adjective": "Jats'uts", "phrase": "In chan'e' Jats'uts", "translation": "Mi silla es bonita." },
]

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

@onready var spell_panel: Panel = $UI/SpellPanel
@onready var choices_panel: Panel = $UI/ChoicesPanel
@onready var complete_panel: Panel = $UI/CompletePanel
@onready var complete_shade: ColorRect = $UI/CompleteShade
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
@onready var complete_summary: Label = $UI/CompletePanel/Content/SummaryLabel
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	_build_round_plan()
	_build_choice_buttons()
	cast_button.pressed.connect(_on_cast_pressed)
	GameManager.magic_points_changed.connect(_on_magic_points_changed)
	_on_magic_points_changed(GameManager.magic_points)
	complete_panel.visible = false
	complete_shade.visible = false
	_show_round()

func _build_round_plan() -> void:
	for i in range(CHALLENGES.size()):
		round_plan.append(i)
	var challenge_rounds: Array[int] = []
	for i in range(CHALLENGES.size()):
		challenge_rounds.append(i)
	challenge_rounds.shuffle()
	round_plan.append_array(challenge_rounds)

func _build_choice_buttons() -> void:
	for noun: Dictionary in NOUNS:
		var word: String = noun.maya
		var button := _make_word_button(&"KalinNounButton")
		noun_grid.add_child(button)
		noun_buttons[word] = button
		button.pressed.connect(_select_noun.bind(word))
	for adjective: Dictionary in ADJECTIVES:
		var word: String = adjective.maya
		var button := _make_word_button(&"KalinAdjectiveButton")
		adjective_grid.add_child(button)
		adjective_buttons[word] = button
		button.pressed.connect(_select_adjective.bind(word))

func _make_word_button(variation: StringName) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(136, 58)
	button.toggle_mode = true
	button.theme_type_variation = variation
	button.add_theme_font_size_override("font_size", 17)
	return button

func _show_round() -> void:
	if round_index >= round_plan.size():
		_finish_level()
		return
	_resolving = false
	selected_noun = ""
	selected_adjective = ""
	feedback_label.text = "El libro mágico espera tu hechizo."
	feedback_label.add_theme_color_override("font_color", COLOR_INK)
	translation_label.add_theme_color_override("font_color", Color("5c4a33"))
	var challenge := _current_challenge()
	var guided := _is_guided_phase()
	animal_sprite.texture = load(challenge.sprite)
	animal_sprite.modulate = Color.WHITE
	animal_name.text = "%s · %s" % [challenge.animal_spanish, challenge.animal]
	phase_label.text = "FASE 1 · APRENDE" if guided else "FASE 2 · RECUERDA"
	request_label.text = "%s necesita que completes este hechizo:" % challenge.animal_spanish
	if guided:
		target_badge.text = "%s  %s" % [_noun_emoji(challenge.noun), challenge.translation]
		instruction_label.text = "Selecciona las dos palabras por su significado y lanza el hechizo."
	else:
		target_badge.text = "%s  %s" % [_noun_emoji(challenge.noun), _challenge_prompt(challenge)]
		instruction_label.text = "Forma la frase sin traducciones en las opciones."
	translation_label.text = "La traducción aparecerá cuando el hechizo sea correcto."
	_update_slots()
	_update_choice_labels()
	_set_choices_enabled(true)
	progress_label.text = "Ronda %d de %d" % [round_index + 1, round_plan.size()]

func _current_challenge() -> Dictionary:
	return CHALLENGES[round_plan[round_index]]

func _is_guided_phase() -> bool:
	return round_index < CHALLENGES.size()

func _challenge_prompt(challenge: Dictionary) -> String:
	var noun := _noun_data(challenge.noun)
	var adjective := _adjective_data(challenge.adjective)
	return "%s %s" % [str(noun.spanish).capitalize(), adjective.spanish]

func _update_choice_labels() -> void:
	var guided := _is_guided_phase()
	for noun: Dictionary in NOUNS:
		var button: Button = noun_buttons[noun.maya]
		button.text = "%s\n%s" % [noun.maya, str(noun.spanish).capitalize()] if guided else noun.maya
	for adjective: Dictionary in ADJECTIVES:
		var button: Button = adjective_buttons[adjective.maya]
		button.text = "%s\n%s" % [adjective.maya, str(adjective.spanish).capitalize()] if guided else adjective.maya

func _select_noun(word: String) -> void:
	if _resolving:
		return
	selected_noun = word
	_update_slots()
	_update_button_states()

func _select_adjective(word: String) -> void:
	if _resolving:
		return
	selected_adjective = word
	_update_slots()
	_update_button_states()

func _update_slots() -> void:
	noun_slot.text = selected_noun + "e'" if selected_noun != "" else "sustantivo + e'"
	adjective_slot.text = selected_adjective if selected_adjective != "" else "adjetivo"
	cast_button.disabled = selected_noun == "" or selected_adjective == "" or _resolving

func _update_button_states() -> void:
	for word: String in noun_buttons:
		(noun_buttons[word] as Button).button_pressed = word == selected_noun
	for word: String in adjective_buttons:
		(adjective_buttons[word] as Button).button_pressed = word == selected_adjective

func _set_choices_enabled(enabled: bool) -> void:
	for button: Button in noun_buttons.values():
		button.disabled = not enabled
	for button: Button in adjective_buttons.values():
		button.disabled = not enabled
	_update_button_states()
	cast_button.disabled = not enabled or selected_noun == "" or selected_adjective == ""

func _on_cast_pressed() -> void:
	if _resolving:
		return
	var challenge := _current_challenge()
	if selected_noun != challenge.noun or selected_adjective != challenge.adjective:
		_show_incorrect_feedback(challenge)
		return
	_resolving = true
	_set_choices_enabled(false)
	GameManager.learn_word(challenge.noun)
	GameManager.learn_word(challenge.adjective)
	noun_slot.text = _phrase_noun(challenge.phrase)
	adjective_slot.text = challenge.adjective
	translation_label.text = "%s\n%s" % [challenge.phrase, challenge.translation]
	translation_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	feedback_label.text = "¡Hechizo correcto! El objeto fue creado a la medida."
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	var tween := create_tween()
	tween.tween_property(spell_panel, "scale", Vector2(1.025, 1.025), 0.12)
	tween.tween_property(spell_panel, "scale", Vector2.ONE, 0.18)
	await get_tree().create_timer(1.35).timeout
	if not is_inside_tree():
		return
	round_index += 1
	_show_round()

func _show_incorrect_feedback(challenge: Dictionary) -> void:
	var noun_ok: bool = selected_noun == str(challenge.noun)
	var adjective_ok: bool = selected_adjective == str(challenge.adjective)
	if not noun_ok and not adjective_ok:
		feedback_label.text = "Las dos palabras necesitan otro intento. Observa la petición."
	elif not noun_ok:
		feedback_label.text = "El adjetivo funciona, pero el objeto no es el que pidió %s." % str(challenge.animal_spanish).to_lower()
	else:
		feedback_label.text = "El objeto es correcto, pero necesita otra cualidad."
	feedback_label.add_theme_color_override("font_color", COLOR_ERROR)
	var original_x := choices_panel.position.x
	var tween := create_tween()
	tween.tween_property(choices_panel, "position:x", original_x - 8.0, 0.05)
	tween.tween_property(choices_panel, "position:x", original_x + 8.0, 0.05)
	tween.tween_property(choices_panel, "position:x", original_x, 0.06)

func _phrase_noun(phrase: String) -> String:
	var parts := phrase.split(" ")
	return parts[1] if parts.size() > 1 else selected_noun

func _noun_data(word: String) -> Dictionary:
	for noun: Dictionary in NOUNS:
		if noun.maya == word:
			return noun
	return {}

func _adjective_data(word: String) -> Dictionary:
	for adjective: Dictionary in ADJECTIVES:
		if adjective.maya == word:
			return adjective
	return {}

func _noun_emoji(word: String) -> String:
	return _noun_data(word).get("emoji", "✨")

func _finish_level() -> void:
	GameManager.complete_level(3, 1)
	complete_summary.text = "Construiste las seis frases del GDD en dos fases.\nLas cinco cualidades ya están en tu Libro de Hechizos.\n+%d puntos mágicos" % GameManager.MAGIC_PER_LEVEL
	complete_shade.visible = true
	complete_panel.visible = true
	complete_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(complete_panel, "modulate:a", 1.0, 0.3)

func _on_magic_points_changed(value: int) -> void:
	magic_label.text = "%d pts mágicos" % value

func _safe_navigate(key: String) -> void:
	_resolving = true
	GameManager.go_to_scene(key)

func _on_menu_pressed() -> void:
	_safe_navigate("main_menu")

func _on_next_level_pressed() -> void:
	_safe_navigate("world4_level1")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
