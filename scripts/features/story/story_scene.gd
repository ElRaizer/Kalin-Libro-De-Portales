@tool
## Escena de historia reutilizable. Presenta a Kalin y a los animales con
## animaciones, diálogos y pequeñas interacciones para repasar vocabulario:
##   DIALOGO:  alguien habla; se avanza con clic, Espacio o Enter.
##   CONOCER:  el jugador toca a cada animal y escucha "In k'aaba'e' ___".
##   ADIVINAR: el jugador elige al animal que se nombra en maya.
##   ELEGIR:   el jugador elige la palabra maya correcta entre botones; un
##             error revela el significado de la palabra elegida.
## Cada capítulo hereda esta escena y configura sus momentos (StoryBeat) en el
## Inspector. Los animales sólo reciben entrada en CONOCER y ADIVINAR,
## después de su entrada y de presentar la consigna.
## Las cinemáticas usan la misma escena: cada StoryBeat puede cambiar el
## ambiente de color, activar efectos (hojas, lluvia, muebles, páginas,
## chispas), mover a Kalin, sacudir la pantalla, lanzar un destello, mostrar un
## cartel de título y avanzar solo (`auto_advance`). Los fondos nuevos entran
## con un fundido.
extends Node2D
class_name StoryScene

signal beat_presented(index: int)

@export var normal_texture: Texture2D
@export var surprised_texture: Texture2D
const STORY_ANIMATOR = preload("res://scripts/features/story/story_animator.gd")
const STORY_SOUND = preload("res://scripts/features/story/story_sound.gd")
@export var entry_distance: float = 460.0
@export var entry_stagger: float = 0.12
@export var hop_height: float = 22.0
@export var char_reveal_seconds: float = 0.022
const COLOR_HINT := Color("f5e6b8")
@export_category("Capítulo")
@export var chapter_title: String = "Mundo 1 · Capítulo 1"
@export var next_scene_key: String = "world1_level1"
@export var beats: Array[StoryBeat] = []

# ─── Estado ──────────────────────────────────────────────────────────────────
var beat_index: int = -1
var interaction: StoryInteraction = StoryInteraction.new()
var _narrative_ready: bool = false
var _navigating: bool = false
var _layout_seed: int = 1
var _guess_targets: Dictionary = {}
var _text_tween: Tween
var _animator: StoryAnimator
var _sound: StorySound
var guide: LearningGuide
var continue_button: Button
var vignette: StoryVignette

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
@onready var celebration: Label = $UI/Celebration
@onready var choices_box: GridContainer = $UI/Choices
@onready var speaker_label: Label = $UI/DialogueBox/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $UI/DialogueBox/DialogueText
@onready var hint_label: Label = $UI/DialogueBox/HintLabel


# ────────────────────────────────────────────────────────────────────────────
func _init() -> void:
	interaction.name = "StoryInteraction"
	add_child(interaction)


func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues: PackedStringArray = get_configuration_issues()
	if not issues.is_empty():
		push_error("Configuración del capítulo: " + "; ".join(issues))
		return
	chapter_label.text = chapter_title
	skip_button.pressed.connect(_finish_story)
	word_bubble.visible = false
	celebration.visible = false
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	_animator = STORY_ANIMATOR.new(
		self,
		ambient,
		background,
		background_next,
		kalin,
		effects_root,
		title_card,
		title_label,
		subtitle_label,
		flash_rect,
		celebration
	)
	_sound = STORY_SOUND.new()
	guide = $LearningGuide
	add_to_group("comfort_visuals")
	vignette = $Stage/Vignette
	vignette.mood_changed.connect(_on_vignette_mood)
	continue_button = $UI/DialogueBox/ContinueButton
	continue_button.pressed.connect(_on_continue_pressed)
	$UI/MenuButton.pressed.connect(_on_menu_pressed)
	_start_kalin_idle()
	var state: Dictionary = GameManager.get_scene_state(self)
	interaction.setup(actors_root, choices_box, word_bubble, guide, continue_button)
	interaction.entry_distance = entry_distance
	interaction.entry_stagger = entry_stagger
	interaction.hop_height = hop_height
	interaction.hint_changed.connect(_set_hint)
	interaction.speaker_requested.connect(_animate_speaker)
	interaction.checkpoint_requested.connect(func(): GameManager.checkpoint(self))
	interaction.restore_session(state)
	_layout_seed = int(state.get("layout_seed", randi_range(1, 2000000000)))
	_prepare_questions(state)
	var saved_beat: int = clampi(int(state.get("beat", 0)), 0, maxi(beats.size() - 1, 0))
	for index: int in range(saved_beat):
		if beats[index].background != null:
			background.texture = beats[index].background
		if beats[index].mood != StoryBeat.Mood.SIN_CAMBIO:
			_apply_mood(beats[index].mood)
	beat_index = saved_beat - 1
	_next_beat()
	interaction.restore_beat(state)


func _unhandled_input(event: InputEvent) -> void:
	if _navigating:
		return
	var is_click: bool = (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	)
	var is_key: bool = event is InputEventKey and event.pressed and not event.echo
	if is_key and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		PauseMenu.open_pause()
		return
	if not is_click and not (is_key and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]):
		return
	get_viewport().set_input_as_handled()
	if _is_revealing_text():
		_complete_text()
	elif can_continue():
		_play_sfx("dialogo_avanzar")
		_next_beat()


# ─── Momentos ────────────────────────────────────────────────────────────────
func current_beat() -> StoryBeat:
	return beats[beat_index]


func _prepare_questions(state: Dictionary) -> void:
	var plan: StoryQuestionPlan = StoryQuestionPlan.build(beats, _layout_seed, state)
	beats = plan.beats
	_guess_targets = plan.targets


func _next_beat() -> void:
	beat_index += 1
	if beat_index >= beats.size():
		_finish_story()
		return
	_show_beat(current_beat())


func _show_beat(beat: StoryBeat) -> void:
	guide.stop()
	_narrative_ready = false
	interaction.set_text_revealing(true)
	interaction.begin(beat, beat_index, _layout_seed, GameManager.scene_key_for(self))
	_change_background(beat.background)
	_apply_mood(beat.mood)
	_apply_effects(beat.effects)
	_apply_kalin_pose(beat.kalin_pose)
	var motion: StoryBeat.KalinMotion = _effective_motion(beat)
	var waking: bool = _animator.sleeping and motion == StoryBeat.KalinMotion.QUIETO
	_play_kalin_motion(motion)
	for effect_name: String in ["ConfetiPaginas", "ConfetiChispas"]:
		(effects_root.get_node(effect_name) as CPUParticles2D).visible = (
			beat.kind != StoryBeat.Kind.EXPLORAR
		)
	vignette.show_situation(
		"" if beat.visual_scene == "ninguna" else beat.visual_scene, beat.visual_solved
	)
	actors_root.visible = beat.visual_scene == "ninguna" or beat.visual_scene.is_empty()
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
	_sound.play_beat(beat, motion, waking)
	_schedule_auto_advance(beat)
	_narrative_ready = beat.kind in [StoryBeat.Kind.DIALOGO, StoryBeat.Kind.EXPLORAR]
	if _narrative_ready:
		_set_hint("▶ Continuar", COLOR_HINT)
	continue_button.disabled = not can_continue()
	interaction.refresh()
	if beat.kind in [StoryBeat.Kind.DIALOGO, StoryBeat.Kind.EXPLORAR]:
		hint_label.hide()
		if beat.auto_advance <= 0:
			guide.watch_continue(continue_button, 7.0)
	else:
		hint_label.show()
	GameManager.checkpoint(self)
	if beat.kind == StoryBeat.Kind.CONOCER:
		interaction.call_deferred("refresh")
	beat_presented.emit(beat_index)


func _on_vignette_mood(expression: String) -> void:
	if not kalin.visible or _animator.sleeping:
		return
	kalin.texture = (
		normal_texture
		if expression == "normal"
		else GameManager.get_visual_texture("kalin_" + expression)
	)


# ─── Actores ─────────────────────────────────────────────────────────────────
func _speaker_name(speaker: String) -> String:
	if speaker == "" or speaker == "Narrador":
		return ""
	if speaker == "Kalin":
		return "Kalin"
	var entry: Dictionary = VocabularyCatalog.entry(speaker)
	if entry.is_empty():
		return speaker
	return "%s · %s" % [speaker, entry.spanish]


func _reveal_text(text: String) -> void:
	if _text_tween:
		_text_tween.kill()
	dialogue_text.text = text
	if get_node("/root/AccessibilityManager").instant_text:
		dialogue_text.visible_ratio = 1.0
		call_deferred("_on_text_revealed")
		return
	dialogue_text.visible_ratio = 0.0
	_text_tween = create_tween()
	_text_tween.tween_property(
		dialogue_text, "visible_ratio", 1.0, text.length() * char_reveal_seconds
	)
	_text_tween.finished.connect(_on_text_revealed, CONNECT_ONE_SHOT)


func _is_revealing_text() -> bool:
	return _text_tween != null and _text_tween.is_running()


func apply_comfort_settings() -> void:
	_animator.apply_comfort_settings()
	interaction.apply_comfort_settings()
	if get_node("/root/AccessibilityManager").instant_text:
		_complete_text()


func _complete_text() -> void:
	if _text_tween:
		_text_tween.kill()
	dialogue_text.visible_ratio = 1.0
	_on_text_revealed()


func _on_text_revealed() -> void:
	interaction.set_text_revealing(false)


func _set_hint(text: String, color: Color) -> void:
	hint_label.text = text
	hint_label.add_theme_color_override("font_color", color)


# ─── Animaciones ─────────────────────────────────────────────────────────────
func _apply_kalin_pose(pose: StoryBeat.KalinPose) -> void:
	kalin.visible = pose != StoryBeat.KalinPose.OCULTO
	kalin.texture = surprised_texture if pose == StoryBeat.KalinPose.SORPRENDIDO else normal_texture


func _start_kalin_idle() -> void:
	_animator.start_idle()


func _animate_speaker(speaker: String) -> void:
	interaction.animate_speaker(speaker)
	if speaker == "Kalin" and not _animator.sleeping:
		_animator.animate_speaker()


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
	# Las escenas con texto esperan una lectura cómoda; se pueden adelantar.
	auto_timer.start(
		maxf(
			beat.text.length() * 0.065 + 1.0,
			beat.text.length() * char_reveal_seconds + beat.auto_advance
		)
	)


func _on_auto_timer_timeout() -> void:
	if _navigating or not can_continue():
		return
	_next_beat()


# ─── Movimientos de Kalin ────────────────────────────────────────────────────
## En un momento con "página recuperada" Kalin salta de alegría, salvo que el
## momento pida otro movimiento o Kalin esté oculto.
func _effective_motion(beat: StoryBeat) -> StoryBeat.KalinMotion:
	if (
		beat.celebrate_page
		and beat.kalin_motion == StoryBeat.KalinMotion.QUIETO
		and beat.kalin_pose != StoryBeat.KalinPose.OCULTO
	):
		return StoryBeat.KalinMotion.SALTA
	return beat.kalin_motion


func _play_kalin_motion(motion: StoryBeat.KalinMotion) -> void:
	_animator.play_kalin_motion(motion)


# ─── Navegación ──────────────────────────────────────────────────────────────
func _finish_story() -> void:
	if _navigating:
		return
	_navigating = true
	interaction.set_navigation_locked(true)
	auto_timer.stop()
	GameManager.go_to_scene(next_scene_key)


func _on_continue_pressed() -> void:
	if _is_revealing_text():
		_complete_text()
	elif can_continue():
		_play_sfx("dialogo_avanzar")
		_next_beat()


func can_continue() -> bool:
	return _narrative_ready or (interaction != null and interaction.resolved)


func _play_sfx(key: String) -> void:
	SoundCue.play(self, key)


func get_checkpoint_state() -> Dictionary:
	var saved: Dictionary = interaction.snapshot() if interaction != null else {}
	saved.merge(
		{
			"beat": maxi(beat_index, 0),
			"layout_seed": _layout_seed,
			"guess_targets": _guess_targets.duplicate(),
			"resolved": can_continue()
		}
	)
	return saved.duplicate(true)


func _on_menu_pressed() -> void:
	_navigating = true
	interaction.set_navigation_locked(true)
	auto_timer.stop()
	GameManager.go_to_scene("main_menu")


func get_configuration_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if next_scene_key not in GameContent.SCENE_PATHS:
		issues.append("Selecciona una clave de salida válida en next_scene_key.")
	if beats.is_empty():
		issues.append("Agrega al menos un momento al capítulo.")
	for index: int in range(beats.size()):
		var beat: StoryBeat = beats[index]
		if beat == null:
			issues.append("El momento %d no tiene un recurso asignado." % (index + 1))
			continue
		if beat.actors.size() > get_node("Stage/Actors").get_child_count():
			issues.append("Añade espacios de actor en Stage/Actors para este capítulo.")
		if beat.options.size() > get_node("UI/Choices").get_child_count():
			issues.append("Añade botones en UI/Choices para todas las respuestas del capítulo.")
		if beat.kind == StoryBeat.Kind.CONOCER and beat.actors.is_empty():
			issues.append("CONOCER necesita animales en actors.")
		if beat.kind == StoryBeat.Kind.ADIVINAR and beat.target_word not in beat.actors:
			issues.append("El animal objetivo debe aparecer en actors.")
		if (
			not beat.question_template.is_empty()
			and (beat.kind != StoryBeat.Kind.ADIVINAR or not "{animal}" in beat.question_template)
		):
			issues.append("La plantilla de pregunta necesita ADIVINAR y {animal}.")
		if (
			beat.kind in [StoryBeat.Kind.CONOCER, StoryBeat.Kind.ADIVINAR]
			and beat.actors.size() % 2 != 0
		):
			issues.append("Las interacciones con animales necesitan una cantidad par de botones.")
		if (
			beat.kind == StoryBeat.Kind.ELEGIR
			and (beat.options.size() < 2 or beat.target_word not in beat.options)
		):
			issues.append("ELEGIR necesita opciones que incluyan la respuesta correcta.")
		if beat.kind == StoryBeat.Kind.ELEGIR and beat.options.size() % 2 != 0:
			issues.append(
				"ELEGIR necesita una cantidad par de respuestas para completar las filas."
			)
		if (
			beat.kind == StoryBeat.Kind.EXPLORAR
			and beat.visual_scene not in ["camino", "casa", "tamano", "hambre", "portal"]
		):
			issues.append("Selecciona una situación visual para EXPLORAR.")
	return issues


func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()
