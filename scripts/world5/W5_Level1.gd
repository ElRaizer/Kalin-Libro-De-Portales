## Mundo 5 — El Portal de Regreso
## Recapitulación de las estructuras aprendidas y cierre narrativo.
extends Node2D
const EXERCISE_ENTRY = preload("res://scripts/data/ExerciseEntry.gd")

const RAW_CHALLENGES: Array[Dictionary] = [
	{
		"section": "IDENTIDAD", "prompt": "Ayuda a Peek' a presentarse.",
		"clue": "🐶  Me llamo Perro", "correct": "In k'aaba'e' Peek'",
		"options": ["In k'aaba'e' Peek'", "In k'a'at Peek'", "Yuum bo'otik"], "learn": ""
	},
	{
		"section": "OBJETOS", "prompt": "Crea una mesa para tus amigos.",
		"clue": "🪑  Hay una mesa", "correct": "Ti' yaan jun mayak",
		"options": ["Ti' yaan jun mayak", "In mayake' mejen", "In k'a'at mayak"], "learn": ""
	},
	{
		"section": "CUALIDADES", "prompt": "Crea una mesa grande.",
		"clue": "🪑  ⬢  Mi mesa es grande", "correct": "In mayake' nojoch",
		"options": ["In mayake' nojoch", "In mayake' mejen", "Ti' yaan jun mayak"], "learn": ""
	},
	{
		"section": "PETICIONES", "prompt": "Kalin necesita agua antes de cruzar el portal.",
		"clue": "💧  Quiero agua", "correct": "In k'a'at ja'",
		"options": ["In k'a'at ja'", "In k'aaba'e' ja'", "Ti' yaan jun ja'"], "learn": ""
	},
	{
		"section": "SALUDO", "prompt": "Saluda al guardián.",
		"clue": "☀️  Buenos días", "correct": "Bix a beel",
		"options": ["Bix a beel", "Yuum bo'otik", "Tak ti' uláak' k'iin"], "learn": "Bix a beel"
	},
	{
		"section": "AGRADECIMIENTO", "prompt": "Agradece la ayuda de tus amigos.",
		"clue": "🙏  Muchas gracias", "correct": "Yuum bo'otik",
		"options": ["Yuum bo'otik", "Bix a beel", "Ka xi'ik tech jats'uts"], "learn": "Yuum bo'otik"
	},
	{
		"section": "DESPEDIDA", "prompt": "Despídete antes de volver a casa.",
		"clue": "👋  Adiós, nos vemos", "correct": "Tak ti' uláak' k'iin",
		"options": ["Tak ti' uláak' k'iin", "Ka xi'ik tech jats'uts", "In k'a'at ja'as"], "learn": "Tak ti' uláak' k'iin"
	},
	{
		"section": "BUEN CAMINO", "prompt": "Los animales desean que a Kalin le vaya bien.",
		"clue": "🌿  Que te vaya bien", "correct": "Ka xi'ik tech jats'uts",
		"options": ["Ka xi'ik tech jats'uts", "Yuum bo'otik", "Bix a beel"], "learn": "Ka xi'ik tech jats'uts"
	},
]
static var CHALLENGES: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_CHALLENGES)

const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var challenge_index: int = 0
var option_buttons: Array[Button] = []
var _resolving: bool = false
var _awaiting_continue := false
var _mistakes := 0
var guide: LearningGuide
var challenge_art: MeaningIllustration
var next_button: Button

@onready var header: Panel = $UI/LevelHeader
@onready var section_label: Label = $UI/ChallengePanel/Content/SectionLabel
@onready var prompt_label: Label = $UI/ChallengePanel/Content/PromptLabel
@onready var clue_label: Label = $UI/ChallengePanel/Content/ClueLabel
@onready var options_box: VBoxContainer = $UI/OptionsPanel/Content/Options
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var progress_label: Label = $UI/PortalStatus/Status/ProgressLabel
@onready var portal_energy: ProgressBar = $UI/PortalStatus/Status/PortalEnergy
@onready var portal_label: Label = $UI/PortalStatus/Status/PortalLabel
@onready var portal_glow: ColorRect = $PortalGlow
@onready var completion: Control = $UI/CompletionOverlay
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	header.menu_pressed.connect(_on_menu_pressed)
	header.book_pressed.connect(_on_book_pressed)
	completion.next_pressed.connect(_on_epilogue_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	portal_energy.max_value = CHALLENGES.size()
	portal_energy.value = 0
	guide = LearningGuide.install(self, $UI/LevelHeader/Bar, _show_help)
	challenge_art = $UI/ChallengePanel/Content/ChallengeArt
	next_button = Button.new()
	next_button.position = Vector2(1050, 592)
	next_button.size = Vector2(180, 48)
	next_button.theme = preload("res://themes/kalin_theme.tres")
	next_button.theme_type_variation = &"KalinPrimaryButton"
	next_button.text = "Continuar →"
	next_button.pressed.connect(_advance_challenge)
	$UI.add_child(next_button)
	var state := GameManager.get_scene_state(self)
	challenge_index = clampi(int(state.get("challenge", 0)), 0, CHALLENGES.size())
	portal_energy.value = challenge_index
	portal_glow.color.a = minf(0.16 + 0.06 * challenge_index, 0.62)
	_show_challenge()
	if challenge_index < CHALLENGES.size() and bool(state.get("waiting", false)):
		_render_success(false)

func _show_challenge() -> void:
	guide.stop()
	next_button.hide()
	if challenge_index >= CHALLENGES.size():
		_finish_world()
		return
	_resolving = false
	_awaiting_continue = false
	_mistakes = 0
	var challenge := CHALLENGES[challenge_index]
	section_label.text = "Página %d / %d" % [challenge_index + 1, CHALLENGES.size()]
	prompt_label.text = challenge.prompt
	clue_label.text = challenge.clue.get_slice("  ", 1)
	var word := "Peek'"
	var quality := ""
	match challenge.section:
		"OBJETOS": word = "mayak"
		"CUALIDADES":
			word = "mayak"
			quality = "nojoch"
		"PETICIONES": word = "ja'"
		"SALUDO", "AGRADECIMIENTO", "DESPEDIDA", "BUEN CAMINO": word = challenge.correct
	challenge_art.show_meaning(word, quality)
	feedback_label.text = "Elige el hechizo."
	feedback_label.add_theme_color_override("font_color", Color("5b4630"))
	progress_label.text = "%d / %d páginas" % [challenge_index, CHALLENGES.size()]
	portal_label.text = "El portal está despertando"
	_build_options(challenge.options)
	GameManager.checkpoint(self)

func _build_options(options: Array) -> void:
	for child: Node in options_box.get_children():
		child.queue_free()
	option_buttons.clear()
	var shuffled: Array = options.duplicate()
	shuffled.shuffle()
	for phrase: String in shuffled:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 50)
		button.theme_type_variation = &"KalinSecondaryButton"
		button.add_theme_font_size_override("font_size", 19)
		button.text = phrase
		button.pressed.connect(_on_option_pressed.bind(phrase))
		options_box.add_child(button)
		option_buttons.append(button)
	if not option_buttons.is_empty():
		option_buttons[0].grab_focus()

func _on_option_pressed(phrase: String) -> void:
	if _resolving:
		return
	var challenge := CHALLENGES[challenge_index]
	guide.stop()
	if phrase != challenge.correct:
		_mistakes += 1
		var meaning := GameManager.get_vocabulary_entry(phrase)
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
		if _mistakes >= 2:
			_show_help()
		return
	if str(challenge.learn) != "":
		GameManager.learn_word(challenge.learn)
	_render_success(true)

func _finish_world() -> void:
	_resolving = true
	_awaiting_continue = false
	guide.stop()
	next_button.hide()
	GameManager.complete_level(5, 1)
	portal_glow.color.a = 0.72
	completion.show_completion("¡El portal está abierto!", "Tus palabras ayudaron a toda la aldea.", "Volver a casa →")
	GameManager.checkpoint(self)

func _on_menu_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("main_menu")

## "Cerrar la aventura" abre el epílogo con la despedida de los animales.
func _on_epilogue_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("world5_story1")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))

func _render_success(animate: bool) -> void:
	_resolving = true
	_awaiting_continue = true
	guide.stop()
	for button: Button in option_buttons:
		button.disabled = true
		if button.text == CHALLENGES[challenge_index].correct:
			button.text = "✓ " + button.text
	feedback_label.text = "✓ %s" % CHALLENGES[challenge_index].correct
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	portal_energy.value = challenge_index + 1
	progress_label.text = "%d / %d páginas" % [challenge_index + 1, CHALLENGES.size()]
	create_tween().tween_property(portal_glow, "color:a", minf(0.16 + 0.06 * (challenge_index + 1), 0.62), 0.5)
	next_button.show()
	next_button.grab_focus()
	if animate:
		challenge_art.celebrate()
		guide.page_to_book(challenge_art.global_position, $UI/LevelHeader/Bar/BookButton.get_global_rect().get_center())
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
		for button: Button in option_buttons:
			if button.text == CHALLENGES[challenge_index].correct:
				guide.point_at(button)
				return

func get_checkpoint_state() -> Dictionary:
	return {"challenge": challenge_index, "waiting": _awaiting_continue}
