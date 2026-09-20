## Mundo 5 — El Portal de Regreso
## Recapitulación de las estructuras aprendidas y cierre narrativo.
extends Node2D

const CHALLENGES: Array[Dictionary] = [
	{
		"section": "IDENTIDAD", "prompt": "El libro pregunta cómo se presenta Peek'.",
		"clue": "🐶  Me llamo Perro", "correct": "In k'aaba'e' Peek'",
		"options": ["In k'aaba'e' Peek'", "In k'a'at Peek'", "Yuum bo'otik"], "learn": ""
	},
	{
		"section": "OBJETOS", "prompt": "Recuerda el hechizo que dice que hay una mesa.",
		"clue": "🪑  Hay una mesa", "correct": "Ti' yaan jun mayak",
		"options": ["Ti' yaan jun mayak", "In mayake' mejen", "In k'a'at mayak"], "learn": ""
	},
	{
		"section": "CUALIDADES", "prompt": "Completa la descripción de la mesa grande.",
		"clue": "🪑  ⬢  Mi mesa es grande", "correct": "In mayake' nojoch",
		"options": ["In mayake' nojoch", "In mayake' mejen", "Ti' yaan jun mayak"], "learn": ""
	},
	{
		"section": "PETICIONES", "prompt": "Kalin necesita agua antes de cruzar el portal.",
		"clue": "💧  Quiero agua", "correct": "In k'a'at ja'",
		"options": ["In k'a'at ja'", "In k'aaba'e' ja'", "Ti' yaan jun ja'"], "learn": ""
	},
	{
		"section": "SALUDO", "prompt": "El guardián del portal te saluda por la mañana.",
		"clue": "☀️  Buenos días", "correct": "Bix a beel",
		"options": ["Bix a beel", "Yuum bo'otik", "Tak ti' uláak' k'iin"], "learn": "Bix a beel"
	},
	{
		"section": "AGRADECIMIENTO", "prompt": "Kalin agradece a los animales toda su ayuda.",
		"clue": "🙏  Muchas gracias", "correct": "Yuum bo'otik",
		"options": ["Yuum bo'otik", "Bix a beel", "Ka xi'ik tech jats'uts"], "learn": "Yuum bo'otik"
	},
	{
		"section": "DESPEDIDA", "prompt": "Elige la despedida que abrirá el portal de regreso.",
		"clue": "👋  Adiós, nos vemos", "correct": "Tak ti' uláak' k'iin",
		"options": ["Tak ti' uláak' k'iin", "Ka xi'ik tech jats'uts", "In k'a'at ja'as"], "learn": "Tak ti' uláak' k'iin"
	},
	{
		"section": "BUEN CAMINO", "prompt": "Los animales desean que a Kalin le vaya bien.",
		"clue": "🌿  Que te vaya bien", "correct": "Ka xi'ik tech jats'uts",
		"options": ["Ka xi'ik tech jats'uts", "Yuum bo'otik", "Bix a beel"], "learn": "Ka xi'ik tech jats'uts"
	},
]

const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var challenge_index: int = 0
var option_buttons: Array[Button] = []
var _resolving: bool = false

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
	completion.next_pressed.connect(_on_menu_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	portal_energy.max_value = CHALLENGES.size()
	portal_energy.value = 0
	_show_challenge()

func _show_challenge() -> void:
	if challenge_index >= CHALLENGES.size():
		_finish_world()
		return
	_resolving = false
	var challenge := CHALLENGES[challenge_index]
	section_label.text = "FRAGMENTO %d · %s" % [challenge_index + 1, challenge.section]
	prompt_label.text = challenge.prompt
	clue_label.text = challenge.clue
	feedback_label.text = "Elige la frase que completa esta página del libro."
	feedback_label.add_theme_color_override("font_color", Color("5b4630"))
	progress_label.text = "%d / %d fragmentos" % [challenge_index, CHALLENGES.size()]
	portal_label.text = "Energía del portal: %d%%" % int(100.0 * challenge_index / CHALLENGES.size())
	_build_options(challenge.options)

func _build_options(options: Array) -> void:
	for child: Node in options_box.get_children():
		child.queue_free()
	option_buttons.clear()
	var shuffled: Array = options.duplicate()
	shuffled.shuffle()
	for phrase: String in shuffled:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 60)
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
	if phrase != challenge.correct:
		feedback_label.text = "Esa frase no corresponde a la pista. Revisa su estructura e intenta otra vez."
		feedback_label.add_theme_color_override("font_color", COLOR_ERROR)
		return
	_resolving = true
	for button: Button in option_buttons:
		button.disabled = true
	if str(challenge.learn) != "":
		GameManager.learn_word(challenge.learn)
	feedback_label.text = "¡Fragmento recuperado!  %s" % challenge.correct
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	portal_energy.value = challenge_index + 1
	portal_label.text = "Energía del portal: %d%%" % int(100.0 * (challenge_index + 1) / CHALLENGES.size())
	var target_alpha := 0.16 + 0.06 * (challenge_index + 1)
	create_tween().tween_property(portal_glow, "color:a", minf(target_alpha, 0.62), 0.35)
	await get_tree().create_timer(1.15).timeout
	if not is_inside_tree():
		return
	challenge_index += 1
	_show_challenge()

func _finish_world() -> void:
	GameManager.complete_level(5, 1)
	portal_glow.color.a = 0.72
	completion.show_completion(
		"¡El Libro está completo!",
		"Kalin recordó sus hechizos, agradeció a sus amigos y abrió el portal.\nCada punto mágico cuenta la historia de lo que aprendiste.",
		"Cerrar la aventura"
	)

func _on_menu_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("main_menu")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
