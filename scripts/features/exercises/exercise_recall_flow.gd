extends RefCounted
class_name ExerciseRecallFlow

## Presentación de escritura, ayudas y distribución comunes a los ejercicios.


static func phase(panel: RecallPanel, guided: bool) -> String:
	return (
		"practice"
		if guided
		else (
			"reconstruction" if panel.visible and panel.mode != RecallPanel.Mode.WRITE else "recall"
		)
	)


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
	if not choices.has_meta("practice_rect"):
		choices.set_meta("practice_rect", Rect2(choices.position, choices.size))
		choices.set_meta("practice_ink", choices.self_modulate)
	var original: Rect2 = choices.get_meta("practice_rect")
	spell.visible = not enabled
	choices.self_modulate = Color(1, 1, 1, 0) if enabled else choices.get_meta("practice_ink")
	choices.position = (
		Vector2(original.position.x, spell.position.y) if enabled else original.position
	)
	choices.size = (
		Vector2(original.size.x, original.end.y - spell.position.y) if enabled else original.size
	)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 8
	panel.offset_top = 8
	panel.offset_right = -8
	panel.offset_bottom = -8
