@tool
## Mundo 5 — El Portal de Regreso
## Recapitulación de las estructuras aprendidas y cierre narrativo.
extends Node2D

@export var content: ExerciseSet
var challenges: Array[ExerciseEntry]:
	get:
		return content.challenges


const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var challenge_index: int = 0
var option_buttons: Array[Button] = []
var _resolving: bool = false
var _awaiting_continue := false
var _mistakes := 0
var guide: LearningGuide
var challenge_art: MeaningIllustration
@onready var next_button: Button = $UI/NextButton
@onready var portal_visual: PortalVisual = $PortalVisual
@onready var mission_progress: MissionProgress = $UI/MissionProgress
var _help_stage := 0
@onready var feedback_art: MeaningIllustration = $UI/FeedbackPanel/FeedbackArt

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
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues := get_configuration_issues()
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
	var state := GameManager.get_scene_state(self)
	challenge_index = clampi(int(state.get("challenge", 0)), 0, challenges.size())
	portal_energy.value = challenge_index
	portal_visual.energy = challenge_index
	portal_glow.color.a = minf(0.16 + 0.06 * challenge_index, 0.62)
	_show_challenge()
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
	_mistakes = 0
	_help_stage = 0
	feedback_art.hide()
	feedback_label.offset_left = 14
	var challenge := challenges[challenge_index]
	section_label.text = "Página %d / %d" % [challenge_index + 1, challenges.size()]
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
	progress_label.text = "%d / %d páginas" % [challenge_index, challenges.size()]
	portal_label.text = "El portal está despertando"
	_build_options(challenge.options)
	guide.watch_action(options_box)
	mission_progress.update_progress(challenge_index, challenges.size(), "El portal · %d / %d" % [challenge_index + 1, challenges.size()])
	GameManager.checkpoint(self)

func _build_options(options: Array) -> void:
	for child: Node in options_box.get_children():
		(child as Button).hide()
	option_buttons.clear()
	var shuffled: Array = options.duplicate()
	shuffled.shuffle()
	for index: int in range(shuffled.size()):
		var phrase: String = shuffled[index]
		var button := options_box.get_child(index) as Button
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
	var challenge := challenges[challenge_index]
	guide.stop()
	if phrase != challenge.correct:
		_mistakes += 1
		feedback_art.show()
		var created := phrase
		var quality := "mejen" if phrase.ends_with(" mejen") else ("nojoch" if phrase.ends_with(" nojoch") else "")
		if phrase.contains("mayak"):
			created = "mayak"
		elif phrase.ends_with(" Peek'"):
			created = "Peek'"
		elif phrase.ends_with(" ja'"):
			created = "ja'"
		elif phrase.ends_with(" ja'as"):
			created = "ja'as"
		feedback_art.show_meaning(created, quality)
		feedback_label.offset_left = 135
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
			_help_stage = mini(_mistakes - 2, 2)
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
	feedback_art.hide()
	feedback_label.offset_left = 14
	_resolving = true
	_awaiting_continue = true
	guide.stop()
	for button: Button in option_buttons:
		button.disabled = true
		if button.text == challenges[challenge_index].correct:
			button.text = "✓ " + button.text
	feedback_label.text = "✓ %s" % challenges[challenge_index].correct
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	portal_energy.value = challenge_index + 1
	portal_visual.set_energy(challenge_index + 1)
	mission_progress.update_progress(challenge_index + 1, challenges.size(), "El portal · %d / %d" % [challenge_index + 1, challenges.size()])
	progress_label.text = "%d / %d páginas" % [challenge_index + 1, challenges.size()]
	create_tween().tween_property(portal_glow, "color:a", minf(0.16 + 0.06 * (challenge_index + 1), 0.62), 0.5)
	next_button.show()
	next_button.grab_focus()
	guide.watch_continue(next_button)
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
		if _help_stage < 2:
			guide.highlight(challenge_art if _help_stage == 0 else options_box)
			_help_stage += 1
			return
		for button: Button in option_buttons:
			if button.text == challenges[challenge_index].correct:
				guide.point_at(button)
				return

func get_checkpoint_state() -> Dictionary:
	return {"challenge": challenge_index, "waiting": _awaiting_continue}

func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del ejercicio."])
	var issues := content.get_configuration_issues(5)
	var slots := get_node("UI/OptionsPanel/Content/Options").get_child_count()
	for challenge: ExerciseEntry in challenges:
		if challenge != null and challenge.options.size() > slots:
			issues.append("Añade botones en UI/OptionsPanel/Content/Options para todas las respuestas.")
			break
	return issues

func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()
