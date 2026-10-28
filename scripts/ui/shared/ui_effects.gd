extends RefCounted
class_name UIEffects

## Animaciones breves compartidas por las interfaces de aprendizaje.
## Mantenerlas aquí evita que cada nivel implemente versiones ligeramente
## distintas del mismo feedback visual.


static func configure_horizontal_focus(buttons: Array[Button]) -> void:
	if buttons.is_empty():
		return
	for index: int in range(buttons.size()):
		buttons[index].focus_neighbor_left = buttons[index].get_path_to(
			buttons[posmod(index - 1, buttons.size())]
		)
		buttons[index].focus_neighbor_right = buttons[index].get_path_to(
			buttons[(index + 1) % buttons.size()]
		)


static func shake(host: Node, control: Control, distance: float = 9.0) -> Tween:
	if host.get_node("/root/AccessibilityManager").reduced_motion:
		distance = 0
	var original_x: float = control.position.x
	var tween: Tween = host.create_tween()
	tween.tween_property(control, "position:x", original_x - distance, 0.05)
	tween.tween_property(control, "position:x", original_x + distance, 0.05)
	tween.tween_property(control, "position:x", original_x, 0.07)
	return tween
