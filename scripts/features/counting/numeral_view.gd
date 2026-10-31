@tool
extends Control
class_name NumeralView

## Dibuja un piso de un numeral maya: granos de cacao (puntos) arriba y varitas
## (barras) abajo, o la concha del cero, centrados en el control. Las texturas
## se eligen en el Inspector.

@export var dot_texture: Texture2D:
	set(value):
		dot_texture = value
		queue_redraw()
@export var bar_texture: Texture2D:
	set(value):
		bar_texture = value
		queue_redraw()
@export var shell_texture: Texture2D:
	set(value):
		shell_texture = value
		queue_redraw()
@export_range(0.3, 3.0, 0.05) var piece_scale: float = 1.0:
	set(value):
		piece_scale = value
		queue_redraw()
@export_range(0, 3) var bars: int = 0:
	set(value):
		bars = clampi(value, 0, MayaNumeral.MAX_BARS)
		queue_redraw()
@export_range(0, 4) var dots: int = 0:
	set(value):
		dots = clampi(value, 0, MayaNumeral.MAX_DOTS)
		queue_redraw()
## La concha sólo se dibuja en un piso sin puntos ni barras.
@export var shell: bool = false:
	set(value):
		shell = value
		queue_redraw()
## Separación entre piezas, en píxeles de la textura escalada.
@export var gap: float = 10.0:
	set(value):
		gap = value
		queue_redraw()


## Muestra el valor de un piso (0 a 19); el cero con concha si se pide.
func show_value(value: int, with_shell: bool = false) -> void:
	bars = MayaNumeral.bars_of(value)
	dots = MayaNumeral.dots_of(value)
	shell = with_shell and value == 0


func _draw() -> void:
	if bars == 0 and dots == 0:
		if shell and shell_texture != null:
			var shell_size: Vector2 = shell_texture.get_size() * piece_scale
			draw_texture_rect(shell_texture, Rect2((size - shell_size) * 0.5, shell_size), false)
		return
	if dot_texture == null or bar_texture == null:
		return
	var dot_size: Vector2 = dot_texture.get_size() * piece_scale
	var bar_size: Vector2 = bar_texture.get_size() * piece_scale
	var rows: int = bars + (1 if dots > 0 else 0)
	var heights: float = bars * bar_size.y + (dot_size.y if dots > 0 else 0.0)
	var y: float = (size.y - heights - gap * (rows - 1)) * 0.5
	if dots > 0:
		var row_width: float = dots * dot_size.x + (dots - 1) * gap
		var x: float = (size.x - row_width) * 0.5
		for index: int in range(dots):
			draw_texture_rect(dot_texture, Rect2(Vector2(x, y), dot_size), false)
			x += dot_size.x + gap
		y += dot_size.y + gap
	for index: int in range(bars):
		draw_texture_rect(
			bar_texture, Rect2(Vector2((size.x - bar_size.x) * 0.5, y), bar_size), false
		)
		y += bar_size.y + gap
