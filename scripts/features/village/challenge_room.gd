extends CanvasLayer
class_name ChallengeRoom

signal changed
signal closed
var words: Array[String] = []
var targets: Array[Array] = []
var index: int = 0
var waiting: bool = false
var visit: int = 0
var attempt: LearningAttempt = LearningAttempt.new()
var recall: RecallPanel
var _prompt: Label
var _feedback: Label
var _submit: Button
var _origin: WeakRef
var _was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.04, 0.13, 0.13, 0.94)
	shade.theme = preload("res://themes/kalin_theme.tres")
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"KalinCreamPanel"
	panel.position = Vector2(110, 45)
	panel.size = Vector2(1060, 630)
	shade.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	_prompt = Label.new()
	_prompt.custom_minimum_size = Vector2(980, 90)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.add_theme_font_size_override("font_size", 26)
	_prompt.add_theme_color_override("font_color", Color("164b48"))
	content.add_child(_prompt)
	recall = (
		preload("res://scenes/features/exercises/recall_panel.tscn").instantiate() as RecallPanel
	)
	recall.external_submit = true
	recall.custom_minimum_size = Vector2(980, 300)
	recall.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(recall)
	recall.submitted.connect(submit)
	recall.word_support_used.connect(attempt.use_word_support)
	recall.answer_changed.connect(changed.emit)
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size.y = 50
	_feedback.add_theme_font_size_override("font_size", 24)
	_feedback.add_theme_color_override("font_color", Color("164b48"))
	content.add_child(_feedback)
	var actions: HBoxContainer = HBoxContainer.new()
	content.add_child(actions)
	_add_button(actions, "Salir y guardar", close_room)
	_add_button(
		actions,
		"Pista",
		func() -> void:
			recall.advance_support()
			changed.emit()
	)
	_submit = _add_button(actions, "Confirmar", submit)
	hide()


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 54)
	button.theme_type_variation = &"KalinSecondaryButton"
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func restore(state: Dictionary) -> void:
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
	if index < words.size():
		_show_word()
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
			_feedback.text = "Aporte guardado. Puedes continuar."
			_submit.text = "Siguiente"
		else:
			waiting = false


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
		var candidates: Array[String] = words.duplicate()
		var used: Array[String] = []
		words.clear()
		for word: String in candidates:
			if word in used:
				continue
			var answers: Array[String] = ChallengePlanner.targets(word, GameManager.learned_words())
			for answer: String in answers:
				if answer in used:
					answers.assign([word])
					break
			words.append(word)
			targets.append(answers)
			used.append_array(answers)
		if not words.is_empty():
			_show_word()
	_origin = weakref(origin)
	_was_paused = get_tree().paused
	get_tree().paused = true
	show()
	if words.is_empty():
		_prompt.text = "Sala de retos"
		_feedback.text = "Primero conoce palabras en la aventura. Después podremos usarlas aquí."
		recall.hide()
		_submit.disabled = true
	else:
		_submit.disabled = false
		recall.first.grab_focus()
	changed.emit()


func _show_word() -> void:
	attempt.begin("challenge_room/%s@%d" % [words[index], visit])
	_prompt.text = (
		"Reto %d de %d\n%s"
		% [index + 1, words.size(), ChallengePlanner.situation(words[index], _answers())]
	)
	recall.configure(_labels(), targets[index])
	_submit.text = "Confirmar"
	_feedback.text = "Puedes pedir una pista cuando la necesites."
	var record: Dictionary = GameManager.learning_record(words[index])
	if GameManager.session.learning_clock + 1 - int(record.last_seen) < LearningProgress.RECALL_GAP:
		attempt.use_content_help()
		recall.set_mode(RecallPanel.Mode.BLOCKS, false)
		_feedback.text = "Vamos a ensayar con piezas. Después usaremos estas palabras en otra ocasión."


func submit() -> void:
	if index >= words.size():
		return
	if waiting:
		index += 1
		waiting = false
		if index == words.size():
			close_room()
		else:
			_show_word()
		changed.emit()
		return
	if not recall.ready_to_submit():
		return
	var answers: Array[String] = _answers()
	var correct: bool = true
	var phase: String = "recall" if recall.mode == RecallPanel.Mode.WRITE else "reconstruction"
	for position: int in range(answers.size()):
		var match_result: Dictionary = WordMatcher.match_word(
			recall.values()[position], answers[position]
		)
		attempt.observe(answers[position], match_result.correct, match_result.supported, phase)
		correct = correct and match_result.correct
	if not correct:
		attempt.miss()
		_feedback.text = "Prueba de nuevo o pide una pista. Los errores no quitan puntos."
		changed.emit()
		return
	var before: int = GameManager.session.magic_points
	GameManager.record_learning(
		answers,
		phase,
		attempt.context,
		attempt.supported,
		attempt.mistakes,
		attempt.evidence(answers)
	)
	var gained: int = GameManager.session.magic_points - before
	_feedback.text = (
		"Aporte completado · +%d puntos" % gained
		if gained > 0
		else "Aporte completado. Esta palabra ya entregó estos puntos."
	)
	waiting = true
	_submit.text = "Siguiente" if index + 1 < words.size() else "Terminar tanda"
	changed.emit()


func mark_content_help() -> void:
	if index < words.size() and not waiting:
		attempt.use_content_help()
		changed.emit()


func snapshot() -> Dictionary:
	return {
		"words": words.duplicate(),
		"targets": targets.duplicate(true),
		"index": index,
		"visit": visit,
		"waiting": waiting,
		"attempt": attempt.snapshot(),
		"answer": recall.first.text,
		"second_answer": recall.second.text,
		"scaffold": recall.scaffold_state()
	}


func close_room() -> void:
	hide()
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
