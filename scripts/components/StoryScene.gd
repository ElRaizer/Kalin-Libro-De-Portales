## Escena de historia reutilizable. Presenta a Kalin y a los animales con
## animaciones, diálogos y pequeñas interacciones para repasar vocabulario:
##   DIALOGO:  alguien habla; se avanza con clic, Espacio o Enter.
##   CONOCER:  el jugador toca a cada animal y escucha "In k'aaba'e' ___".
##   ADIVINAR: el jugador elige al animal que se nombra en maya.
##   ELEGIR:   el jugador elige la palabra maya correcta entre botones; un
##             error revela el significado de la palabra elegida.
## Cada capítulo hereda esta escena y configura sus momentos (StoryBeat) en el
## Inspector. Tocar a un animal en cualquier momento repite su frase.
## Las cinemáticas usan la misma escena: cada StoryBeat puede cambiar el
## ambiente de color, activar efectos (hojas, lluvia, muebles, páginas,
## chispas), mover a Kalin, sacudir la pantalla, lanzar un destello, mostrar un
## cartel de título y avanzar solo (`auto_advance`). Los fondos nuevos entran
## con un fundido.
extends Node2D
class_name StoryScene

const KALIN_NORMAL: Texture2D = preload("res://Arte/sprites/kalin_normal.svg")
const KALIN_SURPRISED: Texture2D = preload("res://Arte/sprites/kalin_surprised.svg")
const STORY_ANIMATOR = preload("res://scripts/components/StoryAnimator.gd")
const MAX_ACTORS := 4
const ACTOR_SIZE := Vector2(180, 210)
const ACTOR_SPACING := 28.0
const ACTOR_AREA_LEFT := 360.0
const ACTOR_AREA_WIDTH := 880.0
const ACTOR_TOP := 250.0
const ENTRY_DISTANCE := 460.0
const CHOICE_SIZE := Vector2(220, 84)
const CHOICE_FONT_SIZE := 20
const ENTRY_STAGGER := 0.12
const HOP_HEIGHT := 22.0
const CHAR_REVEAL_SECONDS := 0.022
const COLOR_SUCCESS := Color("2e8b57")
const COLOR_RETRY := Color("b56a1f")
const COLOR_HINT := Color("f5e6b8")
## Alias públicos conservados para herramientas y pruebas de las escenas.
const AMBIENT_COLORS = STORY_ANIMATOR.AMBIENT_COLORS
const CONTINUOUS_EFFECTS = STORY_ANIMATOR.CONTINUOUS_EFFECTS
const SLEEP_ANGLE = STORY_ANIMATOR.SLEEP_ANGLE
const STAND_UP_SECONDS = STORY_ANIMATOR.STAND_UP_SECONDS
const CROSS_SECONDS = STORY_ANIMATOR.CROSS_SECONDS
const CROSS_SCALE = STORY_ANIMATOR.CROSS_SCALE

@export_category("Capítulo")
@export var chapter_title: String = "Mundo 1 · Capítulo 1"
@export var next_scene_key: String = "world1_level1"
@export var beats: Array[StoryBeat] = []

# ─── Estado ──────────────────────────────────────────────────────────────────
var beat_index: int = -1
var actor_buttons: Dictionary = {}          # palabra maya -> Button
var _stage_words: Array[String] = []
var _met_words: Array[String] = []
var _known_words: Array[String] = []
var _waiting_to_continue: bool = false
var _navigating: bool = false
var _text_tween: Tween
var _animator: RefCounted
var _kalin_sleeping: bool:
	get:
		return _animator != null and _animator.sleeping

# ─── Nodos ───────────────────────────────────────────────────────────────────
@onready var ambient: CanvasModulate = $Ambient
@onready var background: TextureRect = $Background
@onready var background_next: TextureRect = $BackgroundNext
@onready var kalin: TextureRect = $Stage/Kalin
@onready var effects_root: Node2D = $Effects
@onready var auto_timer: Timer = $AutoTimer
@onready var title_card: Panel = $UI/TitleCard
@onready var title_label: Label = $UI/TitleCard/TitleLabel
@onready var subtitle_label: Label = $UI/TitleCard/SubtitleLabel
@onready var flash_rect: ColorRect = $UI/Flash
@onready var actors_root: Control = $Stage/Actors
@onready var chapter_label: Label = $UI/ChapterPanel/ChapterLabel
@onready var skip_button: Button = $UI/SkipButton
@onready var word_bubble: Panel = $UI/WordBubble
@onready var bubble_maya: Label = $UI/WordBubble/Content/MayaLabel
@onready var bubble_spanish: Label = $UI/WordBubble/Content/SpanishLabel
@onready var celebration: Label = $UI/Celebration
@onready var choices_box: HBoxContainer = $UI/Choices
@onready var speaker_label: Label = $UI/DialogueBox/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $UI/DialogueBox/DialogueText
@onready var hint_label: Label = $UI/DialogueBox/HintLabel

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	chapter_label.text = chapter_title
	skip_button.pressed.connect(_finish_story)
	word_bubble.visible = false
	celebration.visible = false
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	_animator = STORY_ANIMATOR.new(
		self, ambient, background, background_next, kalin, effects_root,
		title_card, title_label, subtitle_label, flash_rect, celebration
	)
	_start_kalin_idle()
	_next_beat()

func _unhandled_input(event: InputEvent) -> void:
	if _navigating:
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_key: bool = event is InputEventKey and event.pressed and not event.echo
	if is_key and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_finish_story()
		return
	if not is_click and not (is_key and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		return
	get_viewport().set_input_as_handled()
	if _is_revealing_text():
		_complete_text()
	elif _waiting_to_continue:
		_next_beat()

# ─── Momentos ────────────────────────────────────────────────────────────────
func current_beat() -> StoryBeat:
	return beats[beat_index]

func _next_beat() -> void:
	beat_index += 1
	if beat_index >= beats.size():
		_finish_story()
		return
	_show_beat(current_beat())

func _show_beat(beat: StoryBeat) -> void:
	_waiting_to_continue = false
	word_bubble.visible = false
	_clear_choices()
	_change_background(beat.background)
	_apply_mood(beat.mood)
	_apply_effects(beat.effects)
	_apply_kalin_pose(beat.kalin_pose)
	_play_kalin_motion(_effective_motion(beat))
	_set_stage_actors(beat.actors)
	speaker_label.text = _speaker_name(beat.speaker)
	speaker_label.visible = speaker_label.text != ""
	_reveal_text(beat.text)
	_animate_speaker(beat.speaker)
	if beat.celebrate_page:
		_celebrate_page()
	elif celebration.visible:
		_animator.hide_celebration()
	if beat.screen_shake:
		_shake_screen()
	if beat.flash:
		_flash_screen()
	_show_title(beat.title, beat.subtitle)
	_schedule_auto_advance(beat)
	match beat.kind:
		StoryBeat.Kind.CONOCER:
			_met_words.clear()
			_set_hint("Toca a cada animal para saludarlo  (0 / %d)" % _stage_words.size(), COLOR_HINT)
			_set_actors_focusable(true)
		StoryBeat.Kind.ADIVINAR:
			_set_hint("Elige al animal correcto.", COLOR_HINT)
			_set_actors_focusable(true)
		StoryBeat.Kind.ELEGIR:
			_set_hint("Elige la palabra correcta.", COLOR_HINT)
			_set_actors_focusable(false)
			_build_choices(beat.options)
		_:
			_set_hint("▶ Continuar", COLOR_HINT)
			_set_actors_focusable(false)
			_waiting_to_continue = true

# ─── Actores ─────────────────────────────────────────────────────────────────
func _set_stage_actors(words: Array[String]) -> void:
	if words == _stage_words:
		return
	for button: Button in actor_buttons.values():
		button.queue_free()
	actor_buttons.clear()
	_stage_words = words.duplicate()
	var count: int = mini(words.size(), MAX_ACTORS)
	var total_width: float = count * ACTOR_SIZE.x + maxf(count - 1, 0) * ACTOR_SPACING
	var left: float = ACTOR_AREA_LEFT + (ACTOR_AREA_WIDTH - total_width) * 0.5
	for index: int in range(count):
		var word: String = words[index]
		var button := _make_actor_button(word)
		actors_root.add_child(button)
		actor_buttons[word] = button
		var target := Vector2(left + index * (ACTOR_SIZE.x + ACTOR_SPACING), ACTOR_TOP)
		_animate_entry(button, target, index * ENTRY_STAGGER)

func _make_actor_button(word: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"KalinStoryActor"
	button.size = ACTOR_SIZE
	button.custom_minimum_size = ACTOR_SIZE
	button.pivot_offset = ACTOR_SIZE * 0.5
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_font_size_override("font_size", 22)
	var illustration: String = GameManager.get_book_illustration(word)
	if illustration != "":
		button.icon = load(illustration)
	button.tooltip_text = "Toca para escuchar su nombre"
	button.pressed.connect(_on_actor_pressed.bind(word))
	_update_actor_label(button, word)
	return button

func _update_actor_label(button: Button, word: String) -> void:
	# En ADIVINAR los nombres se ocultan para que el jugador reconozca la imagen.
	var guessing: bool = beat_index >= 0 and current_beat().kind == StoryBeat.Kind.ADIVINAR and not _waiting_to_continue
	var known: bool = word in _known_words or GameManager.has_learned_word(word)
	button.text = word if known and not guessing else ""

func _set_actors_focusable(enabled: bool) -> void:
	for word: String in actor_buttons:
		var button: Button = actor_buttons[word]
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		_update_actor_label(button, word)
	if enabled and not _stage_words.is_empty():
		(actor_buttons[_stage_words[0]] as Button).grab_focus()
	else:
		get_viewport().gui_release_focus()

func _on_actor_pressed(word: String) -> void:
	if _navigating:
		return
	var button: Button = actor_buttons[word]
	_hop(button)
	var beat := current_beat()
	if _waiting_to_continue or beat.kind in [StoryBeat.Kind.DIALOGO, StoryBeat.Kind.ELEGIR]:
		_show_word_bubble(word, COLOR_SUCCESS)
		return
	if beat.kind == StoryBeat.Kind.CONOCER:
		_meet_actor(word)
	elif beat.kind == StoryBeat.Kind.ADIVINAR:
		_guess_actor(word, beat.target_word)

func _meet_actor(word: String) -> void:
	_show_word_bubble(word, COLOR_SUCCESS)
	if word not in _known_words:
		_known_words.append(word)
	if word not in _met_words:
		_met_words.append(word)
	_update_actor_label(actor_buttons[word], word)
	if _met_words.size() < _stage_words.size():
		_set_hint("Toca a cada animal para saludarlo  (%d / %d)" % [_met_words.size(), _stage_words.size()], COLOR_HINT)
		return
	_set_hint("¡Ya conoces a todos!  ▶ Continuar", COLOR_HINT)
	_resolve_interaction()

func _guess_actor(word: String, target: String) -> void:
	if word != target:
		# Repetir el nombre del animal elegido refuerza el vocabulario sin castigar.
		_show_word_bubble(word, COLOR_RETRY)
		_set_hint("¡Casi! Ese es %s. Busca a %s." % [word, target], COLOR_HINT)
		_shake(actor_buttons[word])
		return
	_show_word_bubble(word, COLOR_SUCCESS)
	if word not in _known_words:
		_known_words.append(word)
	_set_hint("¡Muy bien, es %s!  ▶ Continuar" % word, COLOR_HINT)
	_resolve_interaction()
	_sparkle(actor_buttons[word])

# ─── Opciones escritas (ELEGIR) ──────────────────────────────────────────────
func _build_choices(options: Array[String]) -> void:
	for word: String in options:
		var entry: Dictionary = GameManager.get_vocabulary_entry(word)
		var button := Button.new()
		# Los adjetivos del Mundo 3 conservan su color morado; el resto usa el
		# color de los sustantivos, como en los niveles.
		button.theme_type_variation = &"KalinAdjectiveButton" if int(entry.get("world", 0)) == 3 else &"KalinNounButton"
		button.custom_minimum_size = CHOICE_SIZE
		button.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		button.text = "%s  %s" % [entry.get("emoji", ""), word]
		button.pressed.connect(_on_choice_pressed.bind(word, button))
		choices_box.add_child(button)
	choices_box.visible = true
	if choices_box.get_child_count() > 0:
		(choices_box.get_child(0) as Button).grab_focus()

func _clear_choices() -> void:
	for child: Node in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()
	choices_box.visible = false

func _on_choice_pressed(word: String, button: Button) -> void:
	if _navigating or _waiting_to_continue:
		return
	var beat := current_beat()
	_animate_speaker(beat.speaker)
	if word != beat.target_word:
		# El botón equivocado revela su significado para que el error enseñe.
		var entry: Dictionary = GameManager.get_vocabulary_entry(word)
		button.text = "%s  %s\n%s" % [entry.get("emoji", ""), word, entry.get("spanish", "")]
		_set_hint("Esa palabra significa «%s». ¡Intenta otra!" % str(entry.get("spanish", "")).to_lower(), COLOR_HINT)
		_shake(button)
		return
	var target_entry: Dictionary = GameManager.get_vocabulary_entry(word)
	var phrase: String = beat.reveal_phrase if beat.reveal_phrase != "" else str(target_entry.get("estructura", word))
	var translation: String = beat.reveal_translation if beat.reveal_translation != "" else str(target_entry.get("traduccion", ""))
	_clear_choices()
	_show_bubble(phrase, translation, COLOR_SUCCESS)
	_set_hint("¡Muy bien, %s!  ▶ Continuar" % word, COLOR_HINT)
	_resolve_interaction()

func _resolve_interaction() -> void:
	_waiting_to_continue = true
	_set_actors_focusable(false)

# ─── Textos ──────────────────────────────────────────────────────────────────
func _speaker_name(speaker: String) -> String:
	if speaker == "" or speaker == "Narrador":
		return ""
	if speaker == "Kalin":
		return "Kalin"
	var entry: Dictionary = GameManager.get_vocabulary_entry(speaker)
	if entry.is_empty():
		return speaker
	return "%s · %s" % [speaker, entry.spanish]

func _show_word_bubble(word: String, color: Color) -> void:
	var entry: Dictionary = GameManager.get_vocabulary_entry(word)
	_show_bubble(str(entry.get("estructura", word)), str(entry.get("traduccion", "")), color)

func _show_bubble(phrase: String, translation: String, color: Color) -> void:
	bubble_maya.text = phrase
	bubble_spanish.text = translation
	bubble_maya.add_theme_color_override("font_color", color)
	word_bubble.visible = true
	word_bubble.pivot_offset = word_bubble.size * 0.5
	word_bubble.scale = Vector2(0.9, 0.9)
	create_tween().tween_property(word_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

func _reveal_text(text: String) -> void:
	if _text_tween:
		_text_tween.kill()
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0
	_text_tween = create_tween()
	_text_tween.tween_property(dialogue_text, "visible_ratio", 1.0, text.length() * CHAR_REVEAL_SECONDS)

func _is_revealing_text() -> bool:
	return _text_tween != null and _text_tween.is_running()

func _complete_text() -> void:
	_text_tween.kill()
	dialogue_text.visible_ratio = 1.0

func _set_hint(text: String, color: Color) -> void:
	hint_label.text = text
	hint_label.add_theme_color_override("font_color", color)

# ─── Animaciones ─────────────────────────────────────────────────────────────
func _apply_kalin_pose(pose: StoryBeat.KalinPose) -> void:
	kalin.visible = pose != StoryBeat.KalinPose.OCULTO
	kalin.texture = KALIN_SURPRISED if pose == StoryBeat.KalinPose.SORPRENDIDO else KALIN_NORMAL

func _start_kalin_idle() -> void:
	_animator.start_idle()

func _animate_speaker(speaker: String) -> void:
	if speaker in actor_buttons:
		_hop(actor_buttons[speaker])
	elif speaker == "Kalin" and not _kalin_sleeping:
		var tween := create_tween()
		tween.tween_property(kalin, "scale", Vector2(1.04, 1.04), 0.12)
		tween.tween_property(kalin, "scale", Vector2.ONE, 0.18)

func _animate_entry(button: Button, target: Vector2, delay: float) -> void:
	button.position = target + Vector2(ENTRY_DISTANCE, 0)
	button.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(button, "position", target, 0.55).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate:a", 1.0, 0.3).set_delay(delay)

func _hop(button: Button) -> void:
	var base_y: float = ACTOR_TOP
	var tween := create_tween()
	tween.tween_property(button, "position:y", base_y - HOP_HEIGHT, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "position:y", base_y, 0.16).set_trans(Tween.TRANS_BOUNCE)

func _shake(button: Button) -> void:
	var base_x: float = button.position.x
	var tween := create_tween()
	tween.tween_property(button, "position:x", base_x - 8.0, 0.05)
	tween.tween_property(button, "position:x", base_x + 8.0, 0.05)
	tween.tween_property(button, "position:x", base_x, 0.05)

func _sparkle(button: Button) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.14).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2.ONE, 0.2)

func _celebrate_page() -> void:
	_animator.celebrate_page()

# ─── Ambiente, fondos y efectos ──────────────────────────────────────────────
func _change_background(texture: Texture2D) -> void:
	_animator.change_background(texture, beat_index <= 0)

func _apply_mood(mood: StoryBeat.Mood) -> void:
	_animator.apply_mood(mood, beat_index <= 0)

func _apply_effects(effects: int) -> void:
	_animator.apply_effects(effects)

func _shake_screen() -> void:
	_animator.shake_screen()

func _flash_screen() -> void:
	_animator.flash_screen()

func _show_title(title: String, subtitle: String) -> void:
	_animator.show_title(title, subtitle)

func _schedule_auto_advance(beat: StoryBeat) -> void:
	auto_timer.stop()
	if beat.auto_advance <= 0.0 or beat.kind != StoryBeat.Kind.DIALOGO:
		return
	# Se espera a que termine de escribirse el texto y luego el tiempo indicado.
	auto_timer.start(beat.text.length() * CHAR_REVEAL_SECONDS + beat.auto_advance)

func _on_auto_timer_timeout() -> void:
	if _navigating or not _waiting_to_continue:
		return
	_next_beat()

# ─── Movimientos de Kalin ────────────────────────────────────────────────────
## En un momento con "página recuperada" Kalin salta de alegría, salvo que el
## momento pida otro movimiento o Kalin esté oculto.
func _effective_motion(beat: StoryBeat) -> StoryBeat.KalinMotion:
	if beat.celebrate_page and beat.kalin_motion == StoryBeat.KalinMotion.QUIETO and beat.kalin_pose != StoryBeat.KalinPose.OCULTO:
		return StoryBeat.KalinMotion.SALTA
	return beat.kalin_motion

func _play_kalin_motion(motion: StoryBeat.KalinMotion) -> void:
	_animator.play_kalin_motion(motion)

# ─── Navegación ──────────────────────────────────────────────────────────────
func _finish_story() -> void:
	if _navigating:
		return
	_navigating = true
	auto_timer.stop()
	GameManager.go_to_scene(next_scene_key)
