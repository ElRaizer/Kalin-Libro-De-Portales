extends RefCounted
class_name UIEffects

## Animaciones breves compartidas por las interfaces de aprendizaje.
## Mantenerlas aquí evita que cada nivel implemente versiones ligeramente
## distintas del mismo feedback visual.

const SPARKLE_COLOR := Color("ffd85a")

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
	var original_x: float = control.position.x
	var tween := host.create_tween()
	tween.tween_property(control, "position:x", original_x - distance, 0.05)
	tween.tween_property(control, "position:x", original_x + distance, 0.05)
	tween.tween_property(control, "position:x", original_x, 0.07)
	return tween

static func success_burst(host: Node, parent: Node, origin: Control, count: int = 9) -> void:
	for index: int in range(count):
		var sparkle := Label.new()
		sparkle.text = "✦"
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkle.add_theme_font_size_override("font_size", 18 + index % 3 * 4)
		sparkle.add_theme_color_override("font_color", SPARKLE_COLOR)
		parent.add_child(sparkle)
		sparkle.position = origin.position + origin.size * 0.5
		var angle := TAU * float(index) / float(count)
		var target := sparkle.position + Vector2.from_angle(angle) * (62.0 + index * 5.0)
		var tween := host.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "position", target, 0.45)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.45)
		tween.chain().tween_callback(sparkle.queue_free)
