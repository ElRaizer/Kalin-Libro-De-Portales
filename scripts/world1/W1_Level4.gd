## Desafío final de recuerdo: permite observar los destinos y luego retira
## sus palabras y colores antes de habilitar el tablero.
extends "res://scripts/world1/GridPathLevel.gd"

const DESTINATION_PREVIEW_SECONDS := 5.0

func _ready() -> void:
	super._ready()
	grid_board.set_interaction_enabled(false)
	_set_instr("Observa dónde vive cada animal. Las pistas se ocultarán en 5 segundos.")
	await get_tree().create_timer(DESTINATION_PREVIEW_SECONDS).timeout
	if not is_inside_tree():
		return
	grid_board.conceal_destination_clues()
	grid_board.set_interaction_enabled(true)
	_set_instr("Conecta cada animal con la casa que memorizaste. Los signos ? ya no dan pistas.")
