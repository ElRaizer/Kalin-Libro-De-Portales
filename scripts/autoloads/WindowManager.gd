extends Node

## Mantiene la ventana dentro del rango de resoluciones compatible con la UI.
const MIN_WINDOW_SIZE := Vector2i(640, 360)
const MAX_WINDOW_SIZE := Vector2i(1920, 1080)


func _ready() -> void:
	# Las ejecuciones automatizadas en modo headless no crean una ventana nativa.
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	window.min_size = Vector2i.ZERO if OS.has_feature("mobile") or OS.has_feature("web") else MIN_WINDOW_SIZE
	window.max_size = Vector2i.ZERO if OS.has_feature("mobile") or OS.has_feature("web") else MAX_WINDOW_SIZE
