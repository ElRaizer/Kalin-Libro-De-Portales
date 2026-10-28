extends Node
class_name StoryInteraction

## Presentación, entrada y progreso de conocer, adivinar y elegir.
## StoryScene compone momentos y navegación; recibe eventos públicos de esta vista.
signal checkpoint_requested
signal hint_changed(text: String, color: Color)
signal speaker_requested(speaker: String)
signal completed
const COLOR_SUCCESS := Color("2e8b57")
const COLOR_RETRY := Color("b56a1f")
const COLOR_HINT := Color("f5e6b8")
var actor_buttons: Dictionary[String, Button] = {}
var met_words: Array[String] = []
var known_words: Array[String] = []
var attempt: LearningAttempt = LearningAttempt.new()
var resolved: bool = false
var actors_root: Control
var choices_box: GridContainer
var word_bubble: Panel
var bubble_maya: Label
var bubble_spanish: Label
var guide: LearningGuide
var continue_button: Button
var entry_distance: float = 460.0
var entry_stagger: float = 0.12
var hop_height: float = 22.0
var _actor_tweens: Dictionary[Button, Tween] = {}
var _stage_words: Array[String] = []
var _stage_initialized: bool = false
var _entering_actors: Dictionary[Button, bool] = {}
var _last_actor_kind: int = -1
var _bubble_scale: Vector2
var _bubble_tween: Tween
var _navigation_locked: bool = false
var _text_revealing: bool = false
var _beat: StoryBeat
var _index: int = -1
var _layout_seed: int = 1
var _restoring: bool = false


func setup(
	actors: Control,
	choices: GridContainer,
	bubble: Panel,
	learning_guide: LearningGuide,
	continuation: Button
) -> void:
	actors_root = actors
	choices_box = choices
	word_bubble = bubble
	bubble_maya = bubble.get_node("Content/MayaLabel")
	bubble_spanish = bubble.get_node("Content/SpanishLabel")
	guide = learning_guide
	continue_button = continuation
	_bubble_scale = bubble.scale
	for slot: Control in actors_root.get_children():
		var button: Button = slot.get_node("Button") as Button
		button.set_meta("home_position", button.position)
		button.set_meta("home_alpha", button.modulate.a)
		button.set_meta("word", "")
		button.pressed.connect(func(): press_actor(str(button.get_meta("word", ""))))
	for button: Button in choices_box.get_children():
		button.set_meta("authored_variation", button.theme_type_variation)
		button.pressed.connect(func(): press_choice(str(button.get_meta("word", "")), button))


func restore_session(state: Dictionary) -> void:
	attempt.restore(state.get("attempt"))
	known_words.clear()
	var known: Variant = state.get("known", [])
	if known is Array:
		for word: Variant in known:
			if word is String and word in GameContent.VOCABULARY and word not in known_words:
				known_words.append(word)


func begin(beat: StoryBeat, index: int, seed_value: int, scene_key: String) -> void:
	_beat = beat
	_index = index
	_layout_seed = seed_value
	resolved = false
	attempt.begin("%s:%d" % [scene_key, index])
	word_bubble.hide()
	_clear_choices()
	_set_stage_actors(beat.actors)
	match beat.kind:
		StoryBeat.Kind.CONOCER:
			met_words.clear()
			_set_hint("0 / %d amigos" % _stage_words.size(), COLOR_HINT)
		StoryBeat.Kind.ADIVINAR:
			_set_hint("", COLOR_HINT)
		StoryBeat.Kind.ELEGIR:
			_set_hint("Elige la palabra correcta.", COLOR_HINT)
			_build_choices(beat.options)
	refresh()


func set_text_revealing(value: bool) -> void:
	_text_revealing = value
	refresh()
	_show_meet_hint()


func set_navigation_locked(value: bool) -> void:
	_navigation_locked = value
	refresh()


func current_beat() -> StoryBeat:
	return _beat


func _set_hint(text: String, color: Color) -> void:
	hint_changed.emit(text, color)


func _set_stage_actors(words: Array[String]) -> void:
	var kind: int = int(current_beat().kind)
	var regroup: bool = kind == StoryBeat.Kind.ADIVINAR and _last_actor_kind != kind
	_last_actor_kind = kind
	if _stage_initialized and words == _stage_words and not regroup:
		return
	_stage_initialized = true
	_entering_actors.clear()
	for slot: Control in actors_root.get_children():
		slot.hide()
		var button: Button = slot.get_node("Button") as Button
		if _actor_tweens.has(button):
			(_actor_tweens[button] as Tween).kill()
		button.position = button.get_meta("home_position")
		button.modulate.a = button.get_meta("home_alpha")
		button.set_meta("word", "")
		button.icon = null
		button.text = ""
	actor_buttons.clear()
	_stage_words = words.duplicate()
	var arranged: Array[String] = words.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_layout_seed, _index])
	for index: int in range(arranged.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: String = arranged[index]
		arranged[index] = arranged[other]
		arranged[other] = swap
	for index: int in range(arranged.size()):
		var word: String = arranged[index]
		var slot: Control = actors_root.get_child(index) as Control
		var button: Button = slot.get_node("Button") as Button
		slot.show()
		button.set_meta("word", word)
		button.icon = GameManager.get_visual_texture(word)
		_update_actor_label(button, word)
		actor_buttons[word] = button
		var target: Vector2 = button.get_meta("home_position")
		_animate_entry(button, target, index * entry_stagger)


func _update_actor_label(button: Button, word: String) -> void:
	# En ADIVINAR los nombres se ocultan para que el jugador reconozca la imagen.
	var guessing: bool = (
		_index >= 0
		and _beat != null
		and current_beat().kind == StoryBeat.Kind.ADIVINAR
		and not resolved
	)
	var known: bool = word in known_words or GameManager.has_learned_word(word)
	button.text = word if known and not guessing else ""


func _actor_input_allowed() -> bool:
	if not is_inside_tree() or is_queued_for_deletion():
		return false
	if _navigation_locked or resolved or _index < 0 or _beat == null:
		return false
	if get_tree().paused or not actors_root.is_visible_in_tree() or _text_revealing:
		return false
	return current_beat().kind in [StoryBeat.Kind.CONOCER, StoryBeat.Kind.ADIVINAR]


func _actor_is_available(word: String, button: Button) -> bool:
	if not _actor_input_allowed() or button == null or not button.is_visible_in_tree():
		return false
	if _entering_actors.has(button) or button.icon == null or button.modulate.a <= 0.001:
		return false
	if actor_buttons.get(word) != button or str(button.get_meta("word", "")) != word:
		return false
	return current_beat().kind != StoryBeat.Kind.CONOCER or word not in met_words


func refresh() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var first_available: Button
	var focused: Control = get_viewport().gui_get_focus_owner()
	for slot: Control in actors_root.get_children():
		var button: Button = slot.get_node("Button") as Button
		var word: String = str(button.get_meta("word", ""))
		var enabled: bool = _actor_is_available(word, button)
		button.disabled = not enabled
		button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		button.tooltip_text = (
			(
				"Toca para saludar"
				if current_beat().kind == StoryBeat.Kind.CONOCER
				else "Toca al animal que se nombra"
			)
			if enabled
			else ""
		)
		if actor_buttons.get(word) == button:
			_update_actor_label(button, word)
		if enabled and first_available == null:
			first_available = button
		if not enabled and button.has_focus():
			button.release_focus()
	if first_available != null and (focused == null or not focused.has_focus()):
		first_available.grab_focus()


func press_actor(word: String) -> void:
	var button: Button = actor_buttons.get(word) as Button
	if not _actor_is_available(word, button) or button.disabled:
		return
	_hop(button)
	var beat: StoryBeat = current_beat()
	if beat.kind == StoryBeat.Kind.CONOCER:
		_meet_actor(word)
	elif beat.kind == StoryBeat.Kind.ADIVINAR:
		_guess_actor(word, beat.target_word)


func _meet_actor(word: String) -> void:
	if not _restoring:
		GameManager.learn_word(word)
	CharacterReaction.play(actor_buttons[word])
	_show_word_bubble(word, COLOR_SUCCESS)
	if word not in known_words:
		known_words.append(word)
	if word not in met_words:
		met_words.append(word)
	refresh()
	_update_actor_label(actor_buttons[word], word)
	checkpoint_requested.emit()
	if met_words.size() < _stage_words.size():
		_set_hint("%d / %d amigos" % [met_words.size(), _stage_words.size()], COLOR_HINT)
		_show_meet_hint()
		return
	_set_hint("¡Listo!", COLOR_HINT)
	_resolve_interaction()


func _guess_actor(word: String, target: String) -> void:
	if word != target:
		attempt.miss()
		# Repetir el nombre del animal elegido refuerza el vocabulario sin castigar.
		_show_word_bubble(word, COLOR_RETRY)
		_set_hint("¡Casi! Ese es %s. Busca a %s." % [word, target], COLOR_HINT)
		_shake(actor_buttons[word])
		CharacterReaction.play(actor_buttons[word], false)
		checkpoint_requested.emit()
		return
	# Reconocer una imagen es práctica; la recuperación escrita se comprueba en
	# caminos, ejercicios y encargos. No llamar "recuerdo" a una elección al azar.
	if not _restoring:
		GameManager.record_learning(
			[target], "recognition", attempt.context, attempt.supported, attempt.mistakes
		)
	_show_word_bubble(word, COLOR_SUCCESS)
	if word not in known_words:
		known_words.append(word)
	_set_hint("¡Muy bien, es %s!  ▶ Continuar" % word, COLOR_HINT)
	_resolve_interaction()
	_sparkle(actor_buttons[word])


# ─── Opciones escritas (ELEGIR) ──────────────────────────────────────────────


func _build_choices(options: Array[String]) -> void:
	var arranged: Array[String] = options.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_layout_seed, _index])
	for index: int in range(arranged.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: String = arranged[index]
		arranged[index] = arranged[other]
		arranged[other] = swap
	for index: int in range(arranged.size()):
		var word: String = arranged[index]
		var entry: Dictionary = VocabularyCatalog.entry(word)
		var button: Button = choices_box.get_child(index) as Button
		button.show()
		button.disabled = false
		button.set_meta("word", word)
		# Los adjetivos del Mundo 3 conservan su color morado; el resto usa el
		# color de los sustantivos, como en los niveles.
		var authored_variation: StringName = button.get_meta("authored_variation")
		button.theme_type_variation = (
			(&"KalinAdjectiveButton" if int(entry.get("world", 0)) == 3 else &"KalinNounButton")
			if authored_variation in [&"KalinNounButton", &"KalinAdjectiveButton"]
			else authored_variation
		)
		button.text = word
	choices_box.visible = true
	if choices_box.get_child_count() > 0:
		(choices_box.get_child(0) as Button).grab_focus()


func choice_for_word(word: String) -> Button:
	for button: Button in choices_box.get_children():
		if str(button.get_meta("word", "")) == word and button.visible:
			return button
	return null


func debug_can_answer() -> bool:
	if (
		not is_inside_tree()
		or is_queued_for_deletion()
		or not OS.is_debug_build()
		or _navigation_locked
		or resolved
		or _index < 0
		or _beat == null
		or _text_revealing
	):
		return false
	var beat: StoryBeat = current_beat()
	if beat.kind == StoryBeat.Kind.ELEGIR:
		var button: Button = choice_for_word(beat.target_word)
		return button != null and not button.disabled
	if beat.kind == StoryBeat.Kind.ADIVINAR:
		return _actor_is_available(beat.target_word, actor_buttons.get(beat.target_word))
	if beat.kind == StoryBeat.Kind.CONOCER:
		for word: String in _stage_words:
			if _actor_is_available(word, actor_buttons.get(word)):
				return true
	return false


func debug_answer() -> void:
	if not debug_can_answer():
		return
	attempt.supported = true
	var beat: StoryBeat = current_beat()
	if beat.kind == StoryBeat.Kind.ELEGIR:
		press_choice(beat.target_word, choice_for_word(beat.target_word))
	elif beat.kind == StoryBeat.Kind.ADIVINAR:
		press_actor(beat.target_word)
	else:
		for word: String in _stage_words:
			if _actor_is_available(word, actor_buttons.get(word)):
				press_actor(word)
				break


func _clear_choices() -> void:
	for child: Node in choices_box.get_children():
		(child as Button).hide()
		(child as Button).disabled = true
	choices_box.visible = false


func press_choice(word: String, button: Button) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or _navigation_locked or resolved:
		return
	var beat: StoryBeat = current_beat()
	if beat.kind != StoryBeat.Kind.ELEGIR or get_tree().paused:
		return
	if (
		button == null
		or button.get_parent() != choices_box
		or not button.is_visible_in_tree()
		or button.disabled
	):
		return
	if word not in beat.options or str(button.get_meta("word", "")) != word:
		return
	speaker_requested.emit(beat.speaker)
	if word != beat.target_word:
		attempt.miss()
		# El botón equivocado revela su significado para que el error enseñe.
		var entry: Dictionary = VocabularyCatalog.entry(word)
		button.text = "%s\n%s" % [word, entry.get("spanish", "")]
		_set_hint(
			"Esa palabra significa «%s». ¡Intenta otra!" % str(entry.get("spanish", "")).to_lower(),
			COLOR_HINT
		)
		_shake(button)
		checkpoint_requested.emit()
		return
	if not _restoring:
		GameManager.record_learning(
			[word], "recognition", attempt.context, attempt.supported, attempt.mistakes
		)
	var target_entry: Dictionary = VocabularyCatalog.entry(word)
	var phrase: String = (
		beat.reveal_phrase
		if beat.reveal_phrase != ""
		else str(target_entry.get("estructura", word))
	)
	var translation: String = (
		beat.reveal_translation
		if beat.reveal_translation != ""
		else str(target_entry.get("traduccion", ""))
	)
	_clear_choices()
	_show_bubble(phrase, translation, COLOR_SUCCESS)
	_set_hint("¡Muy bien, %s!  ▶ Continuar" % word, COLOR_HINT)
	_resolve_interaction()


func _resolve_interaction() -> void:
	resolved = true
	refresh()
	guide.stop()
	continue_button.disabled = false
	continue_button.grab_focus()
	completed.emit()
	checkpoint_requested.emit()


# ─── Textos ──────────────────────────────────────────────────────────────────


func _show_word_bubble(word: String, color: Color) -> void:
	var entry: Dictionary = VocabularyCatalog.entry(word)
	_show_bubble(str(entry.get("estructura", word)), str(entry.get("traduccion", "")), color)


func _show_bubble(phrase: String, translation: String, color: Color) -> void:
	bubble_maya.text = phrase
	bubble_spanish.text = translation
	bubble_maya.add_theme_color_override("font_color", color)
	word_bubble.visible = true
	word_bubble.pivot_offset = word_bubble.size * 0.5
	if _bubble_tween:
		_bubble_tween.kill()
	word_bubble.scale = (
		_bubble_scale
		if get_node("/root/AccessibilityManager").reduced_motion
		else _bubble_scale * 0.9
	)
	_bubble_tween = create_tween()
	_bubble_tween.tween_property(word_bubble, "scale", _bubble_scale, 0.18).set_trans(
		Tween.TRANS_BACK
	)


func _animate_entry(button: Button, target: Vector2, delay: float) -> void:
	_entering_actors[button] = true
	button.position = (
		target
		if get_node("/root/AccessibilityManager").reduced_motion
		else target + Vector2(entry_distance, 0)
	)
	button.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	_actor_tweens[button] = tween
	(
		tween
		. tween_property(button, "position", target, 0.55)
		. set_delay(delay)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(button, "modulate:a", float(button.get_meta("home_alpha")), 0.3).set_delay(
		delay
	)
	tween.finished.connect(_on_actor_entered.bind(button), CONNECT_ONE_SHOT)


func _on_actor_entered(button: Button) -> void:
	_entering_actors.erase(button)
	refresh()
	_show_meet_hint()


func _hop(button: Button) -> void:
	if _actor_tweens.has(button):
		(_actor_tweens[button] as Tween).kill()
	button.position = button.get_meta("home_position")
	button.modulate.a = button.get_meta("home_alpha")
	var base_y: float = (button.get_meta("home_position") as Vector2).y
	var tween: Tween = create_tween()
	_actor_tweens[button] = tween
	(
		tween
		. tween_property(
			button,
			"position:y",
			base_y - (0.0 if get_node("/root/AccessibilityManager").reduced_motion else hop_height),
			0.12
		)
		. set_trans(Tween.TRANS_SINE)
	)
	tween.tween_property(button, "position:y", base_y, 0.16).set_trans(Tween.TRANS_BOUNCE)


func _shake(button: Button) -> void:
	if _actor_tweens.has(button):
		(_actor_tweens[button] as Tween).kill()
		button.position = button.get_meta("home_position")
		button.modulate.a = button.get_meta("home_alpha")
	var base_x: float = button.position.x
	var tween: Tween = create_tween()
	if button.has_meta("home_position"):
		_actor_tweens[button] = tween
	tween.tween_property(
		button,
		"position:x",
		base_x - (0.0 if get_node("/root/AccessibilityManager").reduced_motion else 8.0),
		0.05
	)
	tween.tween_property(
		button,
		"position:x",
		base_x + (0.0 if get_node("/root/AccessibilityManager").reduced_motion else 8.0),
		0.05
	)
	tween.tween_property(button, "position:x", base_x, 0.05)


func _sparkle(button: Button) -> void:
	CharacterReaction.play(button)


func _show_meet_hint() -> void:
	if not _actor_input_allowed() or current_beat().kind != StoryBeat.Kind.CONOCER:
		return
	for word: String in _stage_words:
		if word not in met_words:
			if _actor_is_available(word, actor_buttons[word]):
				guide.point_at(actor_buttons[word])
			else:
				guide.stop()
			return


func animate_speaker(speaker: String) -> void:
	if speaker in actor_buttons and not _entering_actors.has(actor_buttons[speaker]):
		_hop(actor_buttons[speaker])


func apply_comfort_settings() -> void:
	if get_node("/root/AccessibilityManager").reduced_motion:
		for button: Button in _actor_tweens:
			var tween: Tween = _actor_tweens[button]
			if tween and tween.is_valid():
				tween.kill()
			button.position = button.get_meta("home_position")
			button.modulate.a = button.get_meta("home_alpha")
		_entering_actors.clear()
		if _bubble_tween:
			_bubble_tween.kill()
		word_bubble.scale = _bubble_scale
	refresh()


func snapshot() -> Dictionary:
	return {
		"known": known_words.duplicate(),
		"met": met_words.duplicate(),
		"resolved": resolved,
		"attempt": attempt.snapshot()
	}


func restore_beat(state: Dictionary) -> void:
	_restoring = true
	var met: Variant = state.get("met", [])
	if _beat.kind == StoryBeat.Kind.CONOCER and met is Array:
		for word: Variant in met:
			if word is String and word in actor_buttons and word not in met_words:
				_meet_actor(word)
	elif state.get("resolved") is bool and state.resolved:
		match _beat.kind:
			StoryBeat.Kind.ADIVINAR:
				_guess_actor(_beat.target_word, _beat.target_word)
			StoryBeat.Kind.ELEGIR:
				press_choice(_beat.target_word, choice_for_word(_beat.target_word))
	_restoring = false
