## El jugador puede consultar los destinos durante el reto de recuerdo.
extends "res://scripts/features/grid_paths/grid_path_level.gd"

@onready var preview_button: Button = $UI/PreviewButton
var previewing: bool = true
var _bridge_demo: Tween


func _ready() -> void:
	super._ready()
	preview_button.pressed.connect(_toggle_preview)
	grid_board.set_interaction_enabled(false)
	_set_instr("Observa las casas. Pulsa Listo cuando quieras empezar.")
	if not grid_board.bridges.is_empty() and not _completing:
		_demonstrate_bridge()


func _toggle_preview() -> void:
	if _dialogue_open or _completing:
		return
	previewing = not previewing
	if is_instance_valid(_bridge_demo):
		_bridge_demo.kill()
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
		if not grid_board.bridges.is_empty():
			_demonstrate_bridge()
		else:
			guide.point_at(preview_button)
	else:
		super._show_help()


func _demonstrate_bridge() -> void:
	if is_instance_valid(_bridge_demo):
		_bridge_demo.kill()
	var center: Vector2 = (
		grid_board.cell_to_local_position(grid_board.bridges[0])
		+ Vector2.ONE * grid_board.tile_size * 0.5
	)
	var horizontal: Array[Vector2] = [
		center - Vector2(grid_board.tile_size, 0), center, center + Vector2(grid_board.tile_size, 0)
	]
	var vertical: Array[Vector2] = [
		center - Vector2(0, grid_board.tile_size), center, center + Vector2(0, grid_board.tile_size)
	]
	guide.drag_path(grid_board, horizontal)
	_bridge_demo = create_tween()
	_bridge_demo.tween_interval(2.0)
	_bridge_demo.tween_callback(guide.drag_path.bind(grid_board, vertical))
	_bridge_demo.tween_interval(2.0)
	_bridge_demo.tween_callback(guide.point_at.bind(preview_button))
