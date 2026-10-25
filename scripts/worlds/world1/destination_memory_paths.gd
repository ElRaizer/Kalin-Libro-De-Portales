## El jugador puede consultar los destinos durante el reto de recuerdo.
extends "res://scripts/features/grid_paths/grid_path_level.gd"

@onready var preview_button: Button = $UI/PreviewButton
var previewing: bool = true


func _ready() -> void:
	super._ready()
	preview_button.pressed.connect(_toggle_preview)
	grid_board.set_interaction_enabled(false)
	_set_instr("Observa las casas. Pulsa Listo cuando quieras empezar.")


func _toggle_preview() -> void:
	if _dialogue_open or _completing:
		return
	previewing = not previewing
	guide.stop()
	for index: int in range(grid_board.words.size()):
		var destination: Panel = grid_board.destination_nodes[index]
		var label: Label = destination.get_child(destination.get_child_count() - 1) as Label
		label.text = grid_board.words[index].spanish_word if previewing else "?"
	grid_board.set_interaction_enabled(not previewing)
	preview_button.text = "Listo →" if previewing else "Ver casas"
	_set_instr(
		(
			"Observa las casas. Tú decides cuándo continuar."
			if previewing
			else "Recuerda las casas. Puedes volver a mirarlas."
		)
	)


func _show_help() -> void:
	if is_instance_valid(preview_button) and previewing:
		guide.point_at(preview_button)
	else:
		super._show_help()
