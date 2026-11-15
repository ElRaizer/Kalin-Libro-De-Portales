extends Control
class_name CountingProvision

## Resultado del reparto: las semillas aparecen sólo al confirmar la tablilla.
## Se reconstruye desde la ronda resuelta, sin mantener otro progreso de misión.
@export var tray_texture: Texture2D
@export var seed_texture: Texture2D
var quantity: int = 0
var revealed: float = 0.0:
	set(value):
		revealed = value
		queue_redraw()
var _arrival: Tween


func _ready() -> void:
	add_to_group("comfort_visuals")
	resized.connect(queue_redraw)


func show_quantity(value: int, animate: bool) -> void:
	if _arrival:
		_arrival.kill()
	quantity = clampi(value, 0, MayaNumeral.max_value())
	revealed = float(quantity)
	if not animate or get_node("/root/AccessibilityManager").reduced_motion:
		return
	revealed = 0.0
	_arrival = create_tween()
	_arrival.tween_property(self, "revealed", float(quantity), 0.65)


func apply_comfort_settings() -> void:
	if get_node("/root/AccessibilityManager").reduced_motion:
		if _arrival:
			_arrival.kill()
		revealed = float(quantity)


func _draw() -> void:
	if tray_texture:
		draw_texture_rect(tray_texture, Rect2(Vector2.ZERO, size), false)
	if seed_texture == null:
		return
	# Filas estables permiten reconocer que cambió la cantidad, sin amontonar
	# semillas en el borde. La cifra y el numeral siguen siendo las referencias.
	var seed_size: Vector2 = size * Vector2(0.105, 0.043)
	for index: int in range(mini(quantity, floori(revealed))):
		var column: int = index % 5
		var row: int = index / 5
		var at: Vector2 = size * Vector2(0.17 + column * 0.145, 0.16 + row * 0.055)
		draw_texture_rect(seed_texture, Rect2(at, seed_size), false)
