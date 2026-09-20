extends Node

## Mantiene la ventana dentro del rango de resoluciones compatible con la UI.
const MIN_WINDOW_SIZE := Vector2i(960, 540)
const MAX_WINDOW_SIZE := Vector2i(1920, 1080)


func _ready() -> void:
	# Las ejecuciones automatizadas en modo headless no crean una ventana nativa.
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	window.min_size = MIN_WINDOW_SIZE
	window.max_size = MAX_WINDOW_SIZE
