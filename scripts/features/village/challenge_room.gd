extends CanvasLayer
class_name ChallengeRoom

signal changed
signal closed
signal batch_completed
signal book_requested(origin: Control)
signal layout_changed
signal project_delivery_requested(word: String)
@export var profile: ChallengeProfile = preload("res://data/village/challenges.tres")
var words: Array[String] = []
var targets: Array[Array] = []
var visitors: Array[String] = []
var index: int = 0
var waiting: bool = false
var visit: int = 0
var attempt: LearningAttempt = LearningAttempt.new()
var recall: RecallPanel
var controls: ColorRect
var blocking_layer: CanvasLayer
var preview: ChallengePreview
var _prompt: Label
var _request: Label
var _result: VBoxContainer
var _phrase: Label
var _translation: Label
var _outcome: Label
var _feedback: Label
var _submit: Button
var _hint_button: Button
var _delivery: Button
var _origin: WeakRef
var _was_paused: bool = false
var _rehearsal: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	controls = ColorRect.new()
	controls.size = Vector2(1280, 720)
	controls.color = Color(0.04, 0.13, 0.13, 0.94)
	controls.theme = preload("res://themes/kalin_theme.tres")
	add_child(controls)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"KalinCreamPanel"
	panel.position = Vector2(54, 24)
	panel.size = Vector2(1172, 672)
	controls.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	_prompt = _label(content, 30)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	content.add_child(body)
	var situation: VBoxContainer = VBoxContainer.new()
	situation.custom_minimum_size.x = 350
	body.add_child(situation)
	_request = _label(situation, 26)
	preview = ChallengePreview.new()
	preview.custom_minimum_size = Vector2(350, 210)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	situation.add_child(preview)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var workspace: VBoxContainer = VBoxContainer.new()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(workspace)
	recall = (
		preload("res://scenes/features/exercises/recall_panel.tscn").instantiate() as RecallPanel
	)
	recall.external_submit = true
	recall.custom_minimum_size = Vector2(0, 300)
	workspace.add_child(recall)
	recall.submitted.connect(submit)
	recall.word_support_used.connect(attempt.use_word_support)
	recall.answer_changed.connect(changed.emit)
	_result = VBoxContainer.new()
	_result.add_theme_constant_override("separation", 16)
	workspace.add_child(_result)
	_phrase = _label(_result, 32)
	_translation = _label(_result, 26)
	_outcome = _label(_result, 26)
	_delivery = _add_button(_result, "Llevar al rincón", _request_delivery)
	_result.hide()
	_feedback = _label(content, 24)
	_feedback.custom_minimum_size.y = 68
	var actions: HBoxContainer = HBoxContainer.new()
	content.add_child(actions)
	_add_button(actions, "Salir y guardar", close_room)
	_hint_button = _add_button(
		actions,
		"Pista",
		func() -> void:
			recall.advance_support()
			layout_changed.emit()
			changed.emit()
	)
	_submit = _add_button(actions, "Confirmar", submit)
	var book_button: Button = _add_button(
		actions, "Libro", func() -> void: book_requested.emit(get_viewport().gui_get_focus_owner())
	)
	book_button.custom_minimum_size.x = 140
	hide()


func _label(parent: Control, font_size: int) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("164b48"))
	parent.add_child(label)
	return label


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 54)
	button.theme_type_variation = &"KalinSecondaryButton"
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func restore(state: Dictionary) -> void:
	_rehearsal = state.get("rehearsal") is bool and state.rehearsal
	words.clear()
	var source: Variant = state.get("words", [])
	if source is Array and source.size() <= 3:
		for word: Variant in source:
			if word is String and word in GameManager.learned_words() and word not in words:
				words.append(word)
	index = 0
	var number: Variant = state.get("index", 0)
	if SaveSchema.is_number(number) and float(number) == floor(float(number)):
		index = clampi(int(number), 0, words.size())
	visit = 0
	var saved_visit: Variant = state.get("visit", 0)
	if (
		SaveSchema.is_number(saved_visit)
		and float(saved_visit) == floor(float(saved_visit))
		and float(saved_visit) >= 0
		and float(saved_visit) <= 1000000
	):
		visit = int(saved_visit)
	waiting = state.get("waiting") is bool and state.waiting and index < words.size()
	attempt.restore(state.get("attempt"))
	targets.clear()
	visitors.clear()
	for position: int in range(words.size()):
		var answers: Array[String] = ChallengePlanner.targets(
			words[position], GameManager.learned_words()
		)
		var stored: Variant = state.get("targets", [])
		if stored is Array and position < stored.size() and stored[position] is Array:
			var candidate: Array = stored[position]
			if _valid_targets(candidate, words[position]):
				answers.assign(candidate)
		targets.append(answers)
		var guest: String = ChallengePlanner.visitor(answers, GameManager.learned_words(), visit)
		var saved_guests: Variant = state.get("visitors", [])
		if saved_guests is Array and position < saved_guests.size():
			var saved_guest: Variant = saved_guests[position]
			if (
				saved_guest is String
				and (
					saved_guest.is_empty()
					or (
						saved_guest in ["Áak", "Miis"]
						and saved_guest in GameManager.learned_words()
						and saved_guest not in answers
					)
				)
			):
				guest = saved_guest
		visitors.append(guest)
	if index < words.size():
		_show_word(true)
		var scaffold: Dictionary = (
			state.get("scaffold", {}) if state.get("scaffold") is Dictionary else {}
		)
		scaffold = SceneStateSchema.sanitize({"scaffold": scaffold}).get("scaffold", {})
		var mode: int = RecallPanel.Mode.WRITE
		var saved_mode: Variant = scaffold.get("mode", 0)
		if (
			SaveSchema.is_number(saved_mode)
			and float(saved_mode) == floor(float(saved_mode))
			and float(saved_mode) >= 0
			and float(saved_mode) <= 2
		):
			mode = int(saved_mode)
		recall.configure(_labels(), targets[index], mode)
		recall.restore_scaffold(scaffold)
		if state.get("answer") is String and recall.mode != RecallPanel.Mode.BLOCKS:
			recall.first.text = state.answer
			if state.get("second_answer") is String:
				recall.second.text = state.second_answer
		if waiting and _correct_answers() and _recorded_result():
			_show_result(0, true)
		else:
			waiting = false
			_render_scene(false)


func open_room(origin: Control) -> void:
	if visible or get_tree().paused:
		return
	if index >= words.size():
		words = ChallengePlanner.select_words(
			GameManager.learned_words(),
			GameManager.session.learning_progress,
			GameManager.session.learning_clock + 1
		)
		index = 0
		visit += 1
		waiting = false
		targets.clear()
		visitors.clear()
		var candidates: Array[String] = words.duplicate()
		var used: Array[String] = []
		words.clear()
		for word: String in candidates:
			if word in used:
				continue
			var answers: Array[String] = ChallengePlanner.targets(
				word, GameManager.learned_words(), GameManager.session.learning_progress, used
			)
			words.append(word)
			targets.append(answers)
			visitors.append(ChallengePlanner.visitor(answers, GameManager.learned_words(), visit))
			used.append_array(answers)
		if not words.is_empty():
			_show_word()
	_origin = weakref(origin)
	_was_paused = get_tree().paused
	get_tree().paused = true
	show()
	if words.is_empty():
		_prompt.text = "Sala de retos"
		_request.text = "Cada palabra que conozcas abre una nueva ocasión para compartir."
		_feedback.text = "Primero conoce palabras en la aventura. Después podremos usarlas aquí."
		recall.hide()
		_result.hide()
		preview.clear()
		_hint_button.disabled = true
		_submit.disabled = true
	else:
		_submit.disabled = false
		_delivery.visible = waiting and _can_deliver()
		_render_scene(false)
		if waiting:
			_submit.grab_focus()
		else:
			recall.focus_answer()
	layout_changed.emit()
	changed.emit()


func _show_word(restoring: bool = false) -> void:
	var next_context: String = ChallengePlanner.context(_answers(), visit)
	var saved_context: String = "challenge_room/%s@%d" % [words[index], visit]
	# Reanudar conserva el intento ya vivido, también si sólo guardaba la palabra ancla.
	var continuing_attempt: bool = restoring and attempt.context in [next_context, saved_context]
	if not continuing_attempt:
		attempt.begin(next_context)
	_prompt.text = "Sala de retos · Encuentro %d de %d" % [index + 1, words.size()]
	_request.text = ChallengePlanner.situation(words[index], _answers())
	_result.hide()
	_hint_button.disabled = false
	recall.configure(_labels(), targets[index])
	_submit.text = "Confirmar"
	_feedback.text = profile.welcome + " Puedes pedir una pista."
	if not continuing_attempt:
		_rehearsal = false
		for word: String in _answers():
			var record: Dictionary = GameManager.learning_record(word)
			_rehearsal = (
				_rehearsal
				or (
					GameManager.session.learning_clock + 1 - int(record.last_seen)
					< LearningProgress.RECALL_GAP
				)
			)
	if _rehearsal:
		_feedback.text = "Ensaya por escrito. Esta práctica reciente no añade puntos."
	_render_scene(false)
	layout_changed.emit()


func submit() -> void:
	if index >= words.size():
		return
	if waiting:
		index += 1
		waiting = false
		if index == words.size():
			close_room()
			batch_completed.emit()
		else:
			_show_word()
		changed.emit()
		return
	if not recall.ready_to_submit():
		return
	var answers: Array[String] = _answers()
	var correct: bool = true
	var phase: String = "recall" if recall.mode == RecallPanel.Mode.WRITE else "reconstruction"
	if _rehearsal and recall.mode == RecallPanel.Mode.WRITE:
		phase = "practice"
	for position: int in range(answers.size()):
		var match_result: Dictionary = WordMatcher.match_word(
			recall.values()[position], answers[position]
		)
		attempt.observe(answers[position], match_result.correct, match_result.supported, phase)
		correct = correct and match_result.correct
	if not correct:
		attempt.miss()
		recall.advance_support()
		layout_changed.emit()
		_feedback.text = "Practiquemos con apoyo. Este intento no añade puntos."
		changed.emit()
		return
	var before: int = GameManager.session.magic_points
	var evidence: Dictionary = attempt.evidence(answers)
	var independent: bool = not attempt.supported and attempt.mistakes == 0 and phase == "recall"
	for word: String in answers:
		var detail: Dictionary = evidence[word]
		independent = (
			independent
			and not detail.supported
			and not detail.spelling
			and int(detail.mistakes) == 0
			and detail.phase == "recall"
		)
	GameManager.record_learning(
		answers, phase, attempt.context, attempt.supported, attempt.mistakes, evidence, independent
	)
	var gained: int = GameManager.session.magic_points - before
	waiting = true
	_show_result(gained, false)
	changed.emit()


func _show_result(gained: int, restored: bool) -> void:
	var answers: Array[String] = _answers()
	_phrase.text = " · ".join(answers)
	var meanings: Array[String] = []
	for word: String in answers:
		meanings.append(VocabularyCatalog.entry(word).spanish)
	_translation.text = " · ".join(meanings)
	_outcome.text = profile.outcome(answers)
	var support: bool = (
		attempt.supported or attempt.mistakes > 0 or recall.mode != RecallPanel.Mode.WRITE
	)
	for detail: Dictionary in attempt.evidence(answers).values():
		support = support or detail.spelling or int(detail.mistakes) > 0
	_feedback.text = "Aportación guardada." if restored else "Aportación completada."
	_feedback.text += (
		" Practicaste con apoyo."
		if support
		else (" Ensayo escrito." if _rehearsal else " Escritura sin ayuda.")
	)
	if gained > 0:
		_feedback.text += "\n+%d puntos de magia." % gained
	else:
		_feedback.text += "\nTu práctica cuenta aunque no añada puntos."
	if index + 1 == words.size():
		_prompt.text = (
			"Tanda completa · Una situación compartida"
			if words.size() == 1
			else "Tanda completa · %d situaciones compartidas" % words.size()
		)
	_submit.text = "Siguiente" if index + 1 < words.size() else "Volver a la aldea"
	_hint_button.disabled = true
	recall.hide()
	_result.show()
	_delivery.visible = _can_deliver()
	_render_scene(not restored)
	_submit.grab_focus()
	layout_changed.emit()


func _render_scene(animate: bool) -> void:
	if index < words.size():
		preview.present(_answers(), visitors[index], waiting, animate)


func _can_deliver() -> bool:
	var session: GameSession = GameManager.session
	return (
		waiting
		and not session.rest_corner.complete
		and not session.rest_corner.choice.is_empty()
		and session.rest_corner.choice in _answers()
		and session.has_finished_adventure()
	)


func _request_delivery() -> void:
	if _can_deliver():
		project_delivery_requested.emit(GameManager.session.rest_corner.choice)


func mark_content_help() -> void:
	if index < words.size() and not waiting:
		attempt.use_content_help()
		changed.emit()


func snapshot() -> Dictionary:
	return {
		"words": words.duplicate(),
		"targets": targets.duplicate(true),
		"visitors": visitors.duplicate(),
		"index": index,
		"visit": visit,
		"waiting": waiting,
		"rehearsal": _rehearsal,
		"attempt": attempt.snapshot(),
		"answer": recall.first.text,
		"second_answer": recall.second.text,
		"scaffold": recall.scaffold_state()
	}


func close_room() -> void:
	hide()
	preview.clear()
	get_tree().paused = _was_paused
	var origin: Control = _origin.get_ref() as Control if _origin != null else null
	if (
		is_instance_valid(origin)
		and origin.is_visible_in_tree()
		and origin.focus_mode != Control.FOCUS_NONE
	):
		origin.grab_focus()
	changed.emit()
	closed.emit()


func _process(_delta: float) -> void:
	if visible:
		controls.process_mode = (
			Node.PROCESS_MODE_DISABLED
			if is_instance_valid(blocking_layer) and blocking_layer.visible
			else Node.PROCESS_MODE_ALWAYS
		)


func _exit_tree() -> void:
	if visible:
		get_tree().paused = _was_paused


func _answers() -> Array[String]:
	var answers: Array[String] = []
	answers.assign(targets[index])
	return answers


func _labels() -> Array[String]:
	var labels: Array[String] = ["Tu respuesta"]
	if targets[index].size() == 2:
		labels.assign(["Objeto", "Cómo es"])
	return labels


func _correct_answers() -> bool:
	var answers: Array[String] = _answers()
	for position: int in range(answers.size()):
		if not WordMatcher.match_word(recall.values()[position], answers[position]).correct:
			return false
	return true


func _recorded_result() -> bool:
	for word: String in _answers():
		if attempt.context not in GameManager.learning_record(word).contexts:
			return false
	return true


func _valid_targets(candidate: Array, primary: String) -> bool:
	if candidate.size() not in [1, 2] or primary not in candidate:
		return false
	for word: Variant in candidate:
		if word is not String or word not in GameManager.learned_words():
			return false
	return (
		candidate.size() == 1
		or CombinationCatalog.allowed(CombinationCatalog.key(candidate[0], candidate[1]), false)
	)
