## Nivel de memoria espacial: muestra los obstáculos brevemente y después
## oculta sus pistas visuales, aunque las celdas siguen bloqueadas.
extends "res://scripts/world1/GridPathLevel.gd"

const MEMORY_PREVIEW_SECONDS := 4.0

func _ready() -> void:
	super._ready()
	grid_board.set_interaction_enabled(false)
	_set_instr("Memoriza las rocas del monte: desaparecerán en 4 segundos.")
	await get_tree().create_timer(MEMORY_PREVIEW_SECONDS).timeout
	if not is_inside_tree():
		return
	grid_board.set_obstacle_clues_visible(false)
	grid_board.set_interaction_enabled(true)
	_set_instr("Las rocas siguen bloqueando el paso. ¡Recuerda dónde estaban!")
