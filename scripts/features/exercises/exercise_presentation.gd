extends RefCounted
class_name ExercisePresentation

## Solo el énfasis que depende del estado. La distribución vive en las escenas.


static func focus_step(
	first: Control, second: Control, first_done: bool, second_needed: bool = true
) -> void:
	for control: Control in [first, second]:
		if not control.has_meta("step_base_modulate"):
			control.set_meta("step_base_modulate", control.modulate)
	first.modulate = (
		Color(first.get_meta("step_base_modulate"))
		* (Color(0.84, 0.84, 0.84) if first_done else Color.WHITE)
	)
	second.modulate = (
		Color(second.get_meta("step_base_modulate"))
		* (Color.WHITE if first_done else Color(0.82, 0.82, 0.82))
	)
	second.visible = second_needed
