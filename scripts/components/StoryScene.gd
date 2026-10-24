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

@export var normal_texture: Texture2D
@export var surprised_texture: Texture2D
const STORY_ANIMATOR = preload("res://scripts/components/StoryAnimator.gd")
@export var entry_distance: float = 460.0
@export var entry_stagger: float = 0.12
@export var hop_height: float = 22.0
@export var char_reveal_seconds: float = 0.022
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
var _actor_tweens: Dictionary = {}
var _stage_words: Array[String] = []
var _stage_initialized := false
var _entering_actors: Dictionary = {}
var _met_words: Array[String] = []
var _known_words: Array[String] = []
var _waiting_to_continue: bool = false
var _navigating: bool = false
var _attempt := LearningAttempt.new()
var _layout_seed := 1
var _guess_targets: Dictionary = {}
var _last_actor_kind := -1
var _text_tween: Tween
var _animator: RefCounted
var _bubble_scale: Vector2
var _bubble_tween: Tween
var guide: LearningGuide
var continue_button: Button
var vignette: StoryVignette
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
@onready var choices_box: GridContainer = $UI/Choices
@onready var speaker_label: Label = $UI/DialogueBox/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $UI/DialogueBox/DialogueText
@onready var hint_label: Label = $UI/DialogueBox/HintLabel

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues := get_configuration_issues()
	if not issues.is_empty():
		push_error("Configuración del capítulo: " + "; ".join(issues))
		return
	chapter_label.text = chapter_title
	_bubble_scale = word_bubble.scale
	skip_button.pressed.connect(_finish_story)
	for slot: Control in actors_root.get_children():
		var button := slot.get_node("Button") as Button
		button.set_meta("home_position", button.position)
		button.set_meta("home_alpha", button.modulate.a)
		button.set_meta("word", "")
		button.pressed.connect(func(): _on_actor_pressed(str(button.get_meta("word", ""))))
	for button: Button in choices_box.get_children():
		button.set_meta("authored_variation", button.theme_type_variation)
		button.pressed.connect(func(): _on_choice_pressed(str(button.get_meta("word", "")), button))
	word_bubble.visible = false
	celebration.visible = false
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	_animator = STORY_ANIMATOR.new(
		self, ambient, background, background_next, kalin, effects_root,
		title_card, title_label, subtitle_label, flash_rect, celebration
	)
	guide = $LearningGuide
	add_to_group("comfort_visuals")
	vignette = $Stage/Vignette
	vignette.mood_changed.connect(_on_vignette_mood)
	continue_button = $UI/DialogueBox/ContinueButton
	continue_button.pressed.connect(_on_continue_pressed)
	$UI/MenuButton.pressed.connect(_on_menu_pressed)
	_start_kalin_idle()
	var state: Dictionary = GameManager.get_scene_state(self)
	_attempt.restore(state.get("attempt"))
	_layout_seed = int(state.get("layout_seed", randi_range(1, 2000000000)))
	_prepare_questions(state)
	var saved_beat := clampi(int(state.get("beat", 0)), 0, maxi(beats.size() - 1, 0))
	if int(state.get("revision", 1)) < 2:
		var legacy_index := int(state.get("beat", 0))
		var retained: Array = []
		match GameManager.scene_key_for(self):
			"world2_story1": retained = [0, 1, 5, 6, 7, 8, 9, 10]
			"world3_story1": retained = [0, 5, 6, 7, 8, 9, 10]
			"world4_story1": retained = [0, 4, 5, 6, 7, 8, 9]
		for index: int in range(retained.size()):
			if int(retained[index]) >= legacy_index:
				saved_beat = index
				break
	var known: Variant = state.get("known", [])
	if known is Array:
		for word: Variant in known:
			if word is String and word in GameManager.VOCABULARY:
				_known_words.append(word)
	for index: int in range(saved_beat):
		if beats[index].background != null:
			background.texture = beats[index].background
		if beats[index].mood != StoryBeat.Mood.SIN_CAMBIO:
			_apply_mood(beats[index].mood)
	beat_index = saved_beat - 1
	_next_beat()
	var met: Variant = state.get("met", [])
	if current_beat().kind == StoryBeat.Kind.CONOCER and met is Array:
		for word: Variant in met:
			if word is String and word in actor_buttons:
				_meet_actor(word)
	elif bool(state.get("resolved", false)) and current_beat().kind != StoryBeat.Kind.DIALOGO:
		if current_beat().kind == StoryBeat.Kind.ADIVINAR:
			_guess_actor(current_beat().target_word, current_beat().target_word)
		elif current_beat().kind == StoryBeat.Kind.ELEGIR:
			_on_choice_pressed(current_beat().target_word, choice_for_word(current_beat().target_word))
		elif current_beat().kind == StoryBeat.Kind.EXPLORAR:
			_resolve_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if _navigating:
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
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
	elif _waiting_to_continue:
		_next_beat()

# ─── Momentos ────────────────────────────────────────────────────────────────
func current_beat() -> StoryBeat:
	return beats[beat_index]

func _prepare_questions(state: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _layout_seed
	var stored: Variant = state.get("guess_targets", {})
	var previous_targets: Variant = ReplayVariation.previous(state, "guess_targets", {})
	var asked: Array[String] = []
	var session: Array[StoryBeat] = []
	for index: int in range(beats.size()):
		var beat := beats[index].duplicate() as StoryBeat
		session.append(beat)
		if beat.kind != StoryBeat.Kind.ADIVINAR or beat.question_template.is_empty():
			continue
		var key := str(index)
		var candidates: Array[String] = []
		for word: String in beat.actors:
			if word != beat.speaker and word not in asked:
				candidates.append(word)
		if candidates.is_empty():
			candidates = beat.actors.duplicate()
		var chosen := beat.target_word
		if stored is Dictionary and str(stored.get(key, "")) in beat.actors:
			chosen = str(stored[key])
		elif not state.has("beat"):
			var previous_word := str(previous_targets.get(key, "")) if previous_targets is Dictionary else ""
			chosen = candidates[ReplayVariation.pick(candidates.size(), rng, candidates.find(previous_word))]
		# Un capítulo antiguo conserva su pregunta pendiente y su respuesta.
		beat.target_word = chosen
		beat.text = beat.question_template.replace("{animal}", chosen)
		_guess_targets[key] = chosen
		asked.append(chosen)
	beats = session

func _next_beat() -> void:
	beat_index += 1
	if beat_index >= beats.size():
		_finish_story()
		return
	_show_beat(current_beat())

func _show_beat(beat: StoryBeat) -> void:
	guide.stop()
	_attempt.begin("%s:%d" % [GameManager.scene_key_for(self), beat_index])
	_waiting_to_continue = false
	word_bubble.visible = false
	_clear_choices()
	_change_background(beat.background)
	_apply_mood(beat.mood)
	_apply_effects(beat.effects)
	_apply_kalin_pose(beat.kalin_pose)
	_play_kalin_motion(_effective_motion(beat))
	_set_stage_actors(beat.actors)
	for effect_name: String in ["ConfetiPaginas", "ConfetiChispas"]:
		(effects_root.get_node(effect_name) as CPUParticles2D).visible = beat.kind != StoryBeat.Kind.EXPLORAR
	vignette.show_situation("" if beat.visual_scene == "ninguna" else beat.visual_scene, beat.visual_solved)
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
	_schedule_auto_advance(beat)
	match beat.kind:
		StoryBeat.Kind.EXPLORAR:
			_set_hint("", COLOR_HINT)
			_waiting_to_continue = true
		StoryBeat.Kind.CONOCER:
			_met_words.clear()
			_set_hint("0 / %d amigos" % _stage_words.size(), COLOR_HINT)
		StoryBeat.Kind.ADIVINAR:
			_set_hint("", COLOR_HINT)
		StoryBeat.Kind.ELEGIR:
			_set_hint("Elige la palabra correcta.", COLOR_HINT)
			_build_choices(beat.options)
		_:
			_set_hint("▶ Continuar", COLOR_HINT)
			_waiting_to_continue = true
	continue_button.disabled = not _waiting_to_continue
	_refresh_actor_interaction()
	if beat.kind in [StoryBeat.Kind.DIALOGO, StoryBeat.Kind.EXPLORAR]:
		hint_label.hide()
		if beat.auto_advance <= 0:
			guide.watch_continue(continue_button, 7.0)
	else:
		hint_label.show()
	GameManager.checkpoint(self)
	if beat.kind == StoryBeat.Kind.CONOCER:
		call_deferred("_show_meet_hint")

func _on_vignette_mood(expression: String) -> void:
	if not kalin.visible or _kalin_sleeping:
		return
	kalin.texture = normal_texture if expression == "normal" else GameManager.get_visual_texture("kalin_" + expression)

# ─── Actores ─────────────────────────────────────────────────────────────────
func _set_stage_actors(words: Array[String]) -> void:
	var kind := int(current_beat().kind)
	var regroup := kind == StoryBeat.Kind.ADIVINAR and _last_actor_kind != kind
	_last_actor_kind = kind
	if _stage_initialized and words == _stage_words and not regroup:
		return
	_stage_initialized = true
	_entering_actors.clear()
	for slot: Control in actors_root.get_children():
		slot.hide()
		var button := slot.get_node("Button") as Button
		if _actor_tweens.has(button):
			(_actor_tweens[button] as Tween).kill()
		button.position = button.get_meta("home_position")
		button.modulate.a = button.get_meta("home_alpha")
		button.set_meta("word", "")
		button.icon = null
		button.text = ""
	actor_buttons.clear()
	_stage_words = words.duplicate()
	var arranged := words.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_layout_seed, beat_index])
	for index: int in range(arranged.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: String = arranged[index]
		arranged[index] = arranged[other]
		arranged[other] = swap
	for index: int in range(arranged.size()):
		var word: String = arranged[index]
		var slot := actors_root.get_child(index) as Control
		var button := slot.get_node("Button") as Button
		slot.show()
		button.set_meta("word", word)
		button.icon = GameManager.get_visual_texture(word)
		_update_actor_label(button, word)
		actor_buttons[word] = button
		var target: Vector2 = button.get_meta("home_position")
		_animate_entry(button, target, index * entry_stagger)

func _update_actor_label(button: Button, word: String) -> void:
	# En ADIVINAR los nombres se ocultan para que el jugador reconozca la imagen.
	var guessing: bool = beat_index >= 0 and beat_index < beats.size() and current_beat().kind == StoryBeat.Kind.ADIVINAR and not _waiting_to_continue
	var known: bool = word in _known_words or GameManager.has_learned_word(word)
	button.text = word if known and not guessing else ""

func _actor_input_allowed() -> bool:
	if _navigating or _waiting_to_continue or beat_index < 0 or beat_index >= beats.size():
		return false
	if get_tree().paused or not actors_root.is_visible_in_tree() or _is_revealing_text():
		return false
	return current_beat().kind in [StoryBeat.Kind.CONOCER, StoryBeat.Kind.ADIVINAR]

func _actor_is_available(word: String, button: Button) -> bool:
	if not _actor_input_allowed() or button == null or not button.is_visible_in_tree():
		return false
	if _entering_actors.has(button) or button.icon == null or button.modulate.a <= 0.001:
		return false
	if actor_buttons.get(word) != button or str(button.get_meta("word", "")) != word:
		return false
	return current_beat().kind != StoryBeat.Kind.CONOCER or word not in _met_words

func _refresh_actor_interaction() -> void:
	var first_available: Button
	var focused := get_viewport().gui_get_focus_owner()
	for slot: Control in actors_root.get_children():
		var button := slot.get_node("Button") as Button
		var word := str(button.get_meta("word", ""))
		var enabled := _actor_is_available(word, button)
		button.disabled = not enabled
		button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		button.tooltip_text = ("Toca para saludar" if current_beat().kind == StoryBeat.Kind.CONOCER else "Toca al animal que se nombra") if enabled else ""
		if actor_buttons.get(word) == button:
			_update_actor_label(button, word)
		if enabled and first_available == null:
			first_available = button
		if not enabled and button.has_focus():
			button.release_focus()
	if first_available != null and (focused == null or not focused.has_focus()):
		first_available.grab_focus()

func _on_actor_pressed(word: String) -> void:
	var button := actor_buttons.get(word) as Button
	if not _actor_is_available(word, button) or button.disabled:
		return
	_hop(button)
	var beat := current_beat()
	if beat.kind == StoryBeat.Kind.CONOCER:
		_meet_actor(word)
	elif beat.kind == StoryBeat.Kind.ADIVINAR:
		_guess_actor(word, beat.target_word)

func _meet_actor(word: String) -> void:
	GameManager.learn_word(word)
	CharacterReaction.play(actor_buttons[word])
	_show_word_bubble(word, COLOR_SUCCESS)
	if word not in _known_words:
		_known_words.append(word)
	if word not in _met_words:
		_met_words.append(word)
	_refresh_actor_interaction()
	_update_actor_label(actor_buttons[word], word)
	GameManager.checkpoint(self)
	if _met_words.size() < _stage_words.size():
		_set_hint("%d / %d amigos" % [_met_words.size(), _stage_words.size()], COLOR_HINT)
		_show_meet_hint()
		return
	_set_hint("¡Listo!", COLOR_HINT)
	_resolve_interaction()

func _guess_actor(word: String, target: String) -> void:
	if word != target:
		_attempt.miss()
		# Repetir el nombre del animal elegido refuerza el vocabulario sin castigar.
		_show_word_bubble(word, COLOR_RETRY)
		_set_hint("¡Casi! Ese es %s. Busca a %s." % [word, target], COLOR_HINT)
		_shake(actor_buttons[word])
		CharacterReaction.play(actor_buttons[word], false)
		GameManager.checkpoint(self)
		return
	# Reconocer una imagen es práctica; la recuperación escrita se comprueba en
	# caminos, ejercicios y encargos. No llamar "recuerdo" a una elección al azar.
	GameManager.record_learning([target], "practice", _attempt.context, _attempt.supported, _attempt.mistakes)
	_show_word_bubble(word, COLOR_SUCCESS)
	if word not in _known_words:
		_known_words.append(word)
	_set_hint("¡Muy bien, es %s!  ▶ Continuar" % word, COLOR_HINT)
	_resolve_interaction()
	_sparkle(actor_buttons[word])

# ─── Opciones escritas (ELEGIR) ──────────────────────────────────────────────
func _build_choices(options: Array[String]) -> void:
	var arranged := options.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_layout_seed, beat_index])
	for index: int in range(arranged.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: String = arranged[index]
		arranged[index] = arranged[other]
		arranged[other] = swap
	for index: int in range(arranged.size()):
		var word: String = arranged[index]
		var entry: Dictionary = GameManager.get_vocabulary_entry(word)
		var button := choices_box.get_child(index) as Button
		button.show()
		button.disabled = false
		button.set_meta("word", word)
		# Los adjetivos del Mundo 3 conservan su color morado; el resto usa el
		# color de los sustantivos, como en los niveles.
		var authored_variation: StringName = button.get_meta("authored_variation")
		button.theme_type_variation = (&"KalinAdjectiveButton" if int(entry.get("world", 0)) == 3 else &"KalinNounButton") if authored_variation in [&"KalinNounButton", &"KalinAdjectiveButton"] else authored_variation
		button.text = word
	choices_box.visible = true
	if choices_box.get_child_count() > 0:
		(choices_box.get_child(0) as Button).grab_focus()

func choice_for_word(word: String) -> Button:
	for button: Button in choices_box.get_children():
		if str(button.get_meta("word", "")) == word and button.visible:
			return button
	return null

func _clear_choices() -> void:
	for child: Node in choices_box.get_children():
		(child as Button).hide()
		(child as Button).disabled = true
	choices_box.visible = false

func _on_choice_pressed(word: String, button: Button) -> void:
	if _navigating or _waiting_to_continue:
		return
	var beat := current_beat()
	if beat.kind != StoryBeat.Kind.ELEGIR or get_tree().paused:
		return
	if button == null or button.get_parent() != choices_box or not button.is_visible_in_tree() or button.disabled:
		return
	if word not in beat.options or str(button.get_meta("word", "")) != word:
		return
	_animate_speaker(beat.speaker)
	if word != beat.target_word:
		_attempt.miss()
		# El botón equivocado revela su significado para que el error enseñe.
		var entry: Dictionary = GameManager.get_vocabulary_entry(word)
		button.text = "%s\n%s" % [word, entry.get("spanish", "")]
		_set_hint("Esa palabra significa «%s». ¡Intenta otra!" % str(entry.get("spanish", "")).to_lower(), COLOR_HINT)
		_shake(button)
		GameManager.checkpoint(self)
		return
	GameManager.record_learning([word], "practice", _attempt.context, _attempt.supported, _attempt.mistakes)
	var target_entry: Dictionary = GameManager.get_vocabulary_entry(word)
	var phrase: String = beat.reveal_phrase if beat.reveal_phrase != "" else str(target_entry.get("estructura", word))
	var translation: String = beat.reveal_translation if beat.reveal_translation != "" else str(target_entry.get("traduccion", ""))
	_clear_choices()
	_show_bubble(phrase, translation, COLOR_SUCCESS)
	_set_hint("¡Muy bien, %s!  ▶ Continuar" % word, COLOR_HINT)
	_resolve_interaction()

func _resolve_interaction() -> void:
	_waiting_to_continue = true
	_refresh_actor_interaction()
	guide.stop()
	continue_button.disabled = false
	continue_button.grab_focus()
	GameManager.checkpoint(self)

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
	if _bubble_tween:
		_bubble_tween.kill()
	word_bubble.scale = _bubble_scale * 0.9
	_bubble_tween = create_tween()
	_bubble_tween.tween_property(word_bubble, "scale", _bubble_scale, 0.18).set_trans(Tween.TRANS_BACK)

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
	_text_tween.tween_property(dialogue_text, "visible_ratio", 1.0, text.length() * char_reveal_seconds)
	_text_tween.finished.connect(_on_text_revealed, CONNECT_ONE_SHOT)

func _is_revealing_text() -> bool:
	return _text_tween != null and _text_tween.is_running()

func apply_comfort_settings() -> void:
	_animator.apply_comfort_settings()
	if get_node("/root/AccessibilityManager").instant_text:
		_complete_text()

func _complete_text() -> void:
	if _text_tween:
		_text_tween.kill()
	dialogue_text.visible_ratio = 1.0
	_on_text_revealed()

func _on_text_revealed() -> void:
	_refresh_actor_interaction()
	_show_meet_hint()

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
	if speaker in actor_buttons:
		if not _entering_actors.has(actor_buttons[speaker]):
			_hop(actor_buttons[speaker])
	elif speaker == "Kalin" and not _kalin_sleeping:
		_animator.animate_speaker()

func _animate_entry(button: Button, target: Vector2, delay: float) -> void:
	_entering_actors[button] = true
	button.position = target + Vector2(entry_distance, 0)
	button.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	_actor_tweens[button] = tween
	tween.tween_property(button, "position", target, 0.55).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate:a", float(button.get_meta("home_alpha")), 0.3).set_delay(delay)
	tween.finished.connect(_on_actor_entered.bind(button), CONNECT_ONE_SHOT)

func _on_actor_entered(button: Button) -> void:
	_entering_actors.erase(button)
	_refresh_actor_interaction()
	_show_meet_hint()

func _hop(button: Button) -> void:
	if _actor_tweens.has(button):
		(_actor_tweens[button] as Tween).kill()
	button.position = button.get_meta("home_position")
	button.modulate.a = button.get_meta("home_alpha")
	var base_y: float = (button.get_meta("home_position") as Vector2).y
	var tween := create_tween()
	_actor_tweens[button] = tween
	tween.tween_property(button, "position:y", base_y - hop_height, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "position:y", base_y, 0.16).set_trans(Tween.TRANS_BOUNCE)

func _shake(button: Button) -> void:
	if _actor_tweens.has(button):
		(_actor_tweens[button] as Tween).kill()
		button.position = button.get_meta("home_position")
		button.modulate.a = button.get_meta("home_alpha")
	var base_x: float = button.position.x
	var tween := create_tween()
	if button.has_meta("home_position"):
		_actor_tweens[button] = tween
	tween.tween_property(button, "position:x", base_x - 8.0, 0.05)
	tween.tween_property(button, "position:x", base_x + 8.0, 0.05)
	tween.tween_property(button, "position:x", base_x, 0.05)

func _sparkle(button: Button) -> void:
	CharacterReaction.play(button)

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
	auto_timer.start(maxf(beat.text.length() * 0.065 + 1.0, beat.text.length() * char_reveal_seconds + beat.auto_advance))

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
	_refresh_actor_interaction()
	auto_timer.stop()
	GameManager.go_to_scene(next_scene_key)

func _on_continue_pressed() -> void:
	if _is_revealing_text():
		_complete_text()
	elif _waiting_to_continue:
		_next_beat()

func _show_meet_hint() -> void:
	if not _actor_input_allowed() or current_beat().kind != StoryBeat.Kind.CONOCER:
		return
	for word: String in _stage_words:
		if word not in _met_words:
			if _actor_is_available(word, actor_buttons[word]):
				guide.point_at(actor_buttons[word])
			else:
				guide.stop()
			return

func get_checkpoint_state() -> Dictionary:
	return {"revision": 2, "beat": maxi(beat_index, 0), "known": _known_words, "met": _met_words, "resolved": _waiting_to_continue, "attempt": _attempt.snapshot(), "layout_seed": _layout_seed, "guess_targets": _guess_targets.duplicate()}

func _on_menu_pressed() -> void:
	_navigating = true
	_refresh_actor_interaction()
	auto_timer.stop()
	GameManager.go_to_scene("main_menu")

func get_configuration_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if next_scene_key not in GameContent.SCENE_PATHS:
		issues.append("Selecciona una clave de salida válida en next_scene_key.")
	if beats.is_empty():
		issues.append("Agrega al menos un momento al capítulo.")
	for index: int in range(beats.size()):
		var beat := beats[index]
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
		if not beat.question_template.is_empty() and (beat.kind != StoryBeat.Kind.ADIVINAR or not "{animal}" in beat.question_template):
			issues.append("La plantilla de pregunta necesita ADIVINAR y {animal}.")
		if beat.kind in [StoryBeat.Kind.CONOCER, StoryBeat.Kind.ADIVINAR] and beat.actors.size() % 2 != 0:
			issues.append("Las interacciones con animales necesitan una cantidad par de botones.")
		if beat.kind == StoryBeat.Kind.ELEGIR and (beat.options.size() < 2 or beat.target_word not in beat.options):
			issues.append("ELEGIR necesita opciones que incluyan la respuesta correcta.")
		if beat.kind == StoryBeat.Kind.ELEGIR and beat.options.size() % 2 != 0:
			issues.append("ELEGIR necesita una cantidad par de respuestas para completar las filas.")
		if beat.kind == StoryBeat.Kind.EXPLORAR and beat.visual_scene not in ["camino", "casa", "tamano", "hambre", "portal"]:
			issues.append("Selecciona una situación visual para EXPLORAR.")
	return issues

func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()
