## Reto opcional de memoria: el jugador decide cuándo ocultar las rocas.
extends "res://scripts/features/grid_paths/grid_path_level.gd"

@onready var preview_button: Button = $UI/PreviewButton
var previewing: bool = true


func _ready() -> void:
	super._ready()
	preview_button.pressed.connect(_toggle_preview)
	grid_board.set_interaction_enabled(false)
	_set_instr("Observa las rocas. Pulsa Listo cuando quieras empezar.")


func _toggle_preview() -> void:
	if _dialogue_open or _completing:
		return
	previewing = not previewing
	guide.stop()
	grid_board.set_obstacle_clues_visible(previewing)
	grid_board.set_nearby_obstacle_reveal(not previewing, 0.65)
	grid_board.set_interaction_enabled(not previewing)
	preview_button.text = "Listo →" if previewing else "Ver rocas"
	_set_instr(
		(
			"Observa las rocas. Tú decides cuándo continuar."
			if previewing
			else "Une los animales. Puedes volver a mirar las rocas."
		)
	)


func _show_help() -> void:
	if is_instance_valid(preview_button) and previewing:
		guide.point_at(preview_button)
	else:
		super._show_help()
