## Nivel de memoria espacial: muestra los obstáculos brevemente y después
## oculta sus pistas visuales, aunque las celdas siguen bloqueadas.
extends "res://scripts/world1/GridPathLevel.gd"

const MEMORY_PREVIEW_SECONDS := 4

func _ready() -> void:
	super._ready()
	grid_board.set_interaction_enabled(false)
	for seconds_left: int in range(MEMORY_PREVIEW_SECONDS, 0, -1):
		var unit := "segundo" if seconds_left == 1 else "segundos"
		_set_instr("Memoriza las rocas del monte: desaparecerán en %d %s." % [seconds_left, unit])
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return
	if not is_inside_tree():
		return
	_set_instr("Las rocas se están ocultando...")
	await grid_board.fade_out_obstacle_clues()
	if not is_inside_tree():
		return
	grid_board.set_nearby_obstacle_reveal(true, 0.5)
	grid_board.set_interaction_enabled(true)
	_set_instr("Las rocas cercanas a la punta se verán tenuemente. Toca un animal conectado para rehacer su ruta.")
