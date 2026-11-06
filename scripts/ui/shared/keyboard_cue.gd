extends Control
class_name KeyboardCue

## Orientación de manejo local: no revela respuestas ni modifica evidencia.
var _idle: float = 0.0
var _clock: float = 0.0
var _interaction: bool = false
var _vertical: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = preload("res://themes/kalin_theme.tres")
	size = Vector2(220, 108)
	modulate.a = 0.0
	hide()


func update_cue(
	anchor: Vector2, enabled: bool, moved: bool, interaction: bool, vertical: bool, delta: float
) -> void:
	_idle = _idle + delta if enabled and not moved else 0.0
	_clock += delta
	if not enabled:
		modulate.a = 0.0
		hide()
		return
	_interaction = interaction
	_vertical = vertical
	var showing: bool = enabled and _idle >= (1.5 if interaction else 3.0)
	modulate.a = move_toward(modulate.a, 1.0 if showing else 0.0, delta * 4.0)
	visible = modulate.a > 0.01
	position = Vector2(clampf(anchor.x - 110, 12, 1048), clampf(anchor.y - 112, 84, 580))
	if visible:
		queue_redraw()


func _draw() -> void:
	var font: Font = get_theme_font("font", "KalinSecondaryButton")
	var keys: Array[String] = []
	if _interaction:
		keys.append("E")
	elif _vertical:
		keys.assign(["W ↑", "A ←", "S ↓", "D →"])
	else:
		keys.assign(["A ←", "D →"])
	for index: int in range(keys.size()):
		var offset: Vector2 = (
			Vector2(82, 45)
			if _interaction
			else (
				Vector2(74, 0)
				if keys.size() == 4 and index == 0
				else (
					Vector2((index - 1) * 74, 54)
					if keys.size() == 4
					else Vector2(35 + index * 78, 45)
				)
			)
		)
		var pressed: bool = (
			not get_node("/root/AccessibilityManager").reduced_motion
			and fmod(_clock, 1.4) < 0.5
			and index == int(_clock / 1.4) % keys.size()
		)
		var rect: Rect2 = Rect2(
			offset + (Vector2(0, 3) if pressed else Vector2.ZERO), Vector2(66, 46)
		)
		draw_style_box(
			get_theme_stylebox("pressed" if pressed else "normal", "KalinSecondaryButton"), rect
		)
		draw_string(
			font,
			rect.position + Vector2(10, 30),
			keys[index],
			HORIZONTAL_ALIGNMENT_CENTER,
			46,
			22,
			get_theme_color("font_color", "KalinSecondaryButton")
		)
