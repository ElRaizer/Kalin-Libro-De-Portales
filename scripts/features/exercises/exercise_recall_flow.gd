extends RefCounted
class_name ExerciseRecallFlow

## Presentación de escritura, ayudas y distribución comunes a los ejercicios.


static func bind_support(panel: RecallPanel, attempt: LearningAttempt) -> void:
	panel.word_support_used.connect(attempt.use_word_support)


static func phase(panel: RecallPanel, guided: bool) -> String:
	if not panel.visible:
		return "recognition"
	if panel.mode != RecallPanel.Mode.WRITE:
		return "reconstruction"
	return "practice" if guided else "recall"


static func caption(panel: RecallPanel, guided: bool, cards: bool) -> String:
	if guided or cards:
		return "Práctica con tarjetas"
	return ["Escritura libre", "Completar · con apoyo", "Construir · con bloques"][panel.mode]


static func prepare(
	panel: RecallPanel,
	labels: Array,
	words: Array,
	attempt: LearningAttempt,
	saved: Dictionary = {}
) -> void:
	var mode_value: RecallPanel.Mode = RecallPanel.Mode.WRITE
	if saved.get("mode") is int or saved.get("mode") is float:
		mode_value = clampi(int(saved.mode), 0, 2)
	panel.configure(labels, words, mode_value)
	if mode_value != RecallPanel.Mode.WRITE:
		attempt.supported = true
	panel.restore_scaffold(saved)


static func expand_for_recall(
	choices: Control, spell: Control, panel: RecallPanel, enabled: bool
) -> void:
	choices.set_meta("recall_spell", spell)
	choices.set_meta("recall_panel", panel)
	choices.set_meta("recall_expanded", enabled)
	if not choices.has_meta("recall_connected"):
		choices.set_meta("recall_connected", true)
		panel.answer_changed.connect(
			func():
				if is_instance_valid(choices) and choices.is_inside_tree():
					expand_for_recall(
						choices, spell, panel, bool(choices.get_meta("recall_expanded"))
					)
		)
	if not choices.has_meta("practice_rect"):
		choices.set_meta("practice_rect", Rect2(choices.position, choices.size))
		choices.set_meta("practice_ink", choices.self_modulate)
	var original: Rect2 = choices.get_meta("practice_rect")
	spell.visible = not enabled
	choices.self_modulate = Color(1, 1, 1, 0) if enabled else choices.get_meta("practice_ink")
	choices.position = original.position
	choices.size = (
		Vector2(
			original.size.x,
			maxf(original.end.y, spell.position.y + spell.size.y) - original.position.y
		)
		if enabled
		else original.size
	)
	if enabled:
		var writing: bool = panel.mode != RecallPanel.Mode.BLOCKS and not panel.is_showing_result()
		var height_key: String = (
			("writing_height" if panel.second_box.visible else "single_writing_height")
			if writing
			else ("recall_height" if panel.second_box.visible else "single_recall_height")
		)
		var height: float = float(choices.get_meta(height_key, 0.0))
		if height > 0.0:
			choices.size.y = minf(choices.size.y, height)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_top = 8
	panel.offset_right = -8
	panel.offset_bottom = -8
