extends RefCounted
class_name GridPathController

## Reglas de construcción, retracción y finalización de caminos. GridBoard
## conserva la entrada y las señales públicas; este objeto modifica su estado.

var board: Node2D

func _init(owner_board: Node2D) -> void:
	board = owner_board

func try_finalize(destination_cell: Vector2i) -> void:
	if board.active_index < 0 or board.active_index in board.connected:
		return
	if board.tile_owner.get(destination_cell, -1) != board.active_index:
		return
	var previous_cell: Vector2i = board.words[board.active_index].start_cell
	if not board.paths[board.active_index].is_empty():
		previous_cell = board.paths[board.active_index].back()
	if board._are_adjacent(previous_cell, destination_cell):
		finalize(board.active_index)

func try_resume(cell: Vector2i) -> void:
	var index: int = board.tile_owner.get(cell, -1)
	if index < 0 or index in board.connected or board.paths.get(index, []).is_empty():
		return
	if board.paths[index].back() != cell:
		return
	board.active_index = index
	board.drawing = true
	board.last_cell = cell
	board._show_ring(index)
	board.word_selected.emit(board.words[index])
	board._update_nearby_obstacle_clues()

func try_retract(cell: Vector2i) -> bool:
	if board.active_index < 0 or board.paths.get(board.active_index, []).is_empty():
		return false
	var path: Array = board.paths[board.active_index]
	var current_tip: Vector2i = path.back()
	if not board._are_adjacent(cell, current_tip):
		return false
	var is_previous: bool = path.size() >= 2 and path[path.size() - 2] == cell
	var is_start: bool = path.size() == 1 and board.words[board.active_index].start_cell == cell
	if not is_previous and not is_start:
		return false
	var removed_cell: Vector2i = path.pop_back()
	board.grid_state[removed_cell.y][removed_cell.x] = board.Cell.EMPTY
	board.tile_owner.erase(removed_cell)
	board._reset_tile(removed_cell)
	board._refresh_path_line(board.active_index)
	board._update_nearby_obstacle_clues()
	return true

func extend(cell: Vector2i) -> void:
	if board.active_index < 0 or cell in board.paths[board.active_index]:
		return
	if cell in board.tile_owner and board.tile_owner[cell] != board.active_index:
		return
	var previous: Vector2i = board.words[board.active_index].start_cell if board.paths[board.active_index].is_empty() else board.paths[board.active_index].back()
	if not board._are_adjacent(cell, previous):
		return
	board.paths[board.active_index].append(cell)
	board.grid_state[cell.y][cell.x] = board.Cell.PATH
	board.tile_owner[cell] = board.active_index
	board._set_path_tile_tint(cell, board.words[board.active_index].color)
	board._refresh_path_line(board.active_index)
	board._update_nearby_obstacle_clues()

func clear(index: int) -> void:
	for cell: Vector2i in board.paths.get(index, []):
		board.grid_state[cell.y][cell.x] = board.Cell.EMPTY
		board.tile_owner.erase(cell)
		board._reset_tile(cell)
	board.paths[index] = []
	board._remove_path_line(index)
	board._update_nearby_obstacle_clues()

func reset_connected(index: int) -> void:
	if index not in board.connected:
		return
	board.connected.erase(index)
	board._reset_tile(board.words[index].destination_cell)
	clear(index)
	board.path_reset.emit(board.words[index], index)

func finalize(index: int) -> void:
	if index in board.connected:
		return
	board.connected.append(index)
	for cell: Vector2i in board.paths[index]:
		board._set_path_tile_tint(cell, board.words[index].color)
	board._set_path_tile_tint(board.words[index].destination_cell, board.words[index].color)
	board._refresh_path_line(index)
	board.drawing = false
	board.active_index = -1
	board.selection_ring.visible = false
	board._update_nearby_obstacle_clues()
	board.input_enabled = false
	board.word_connected.emit(board.words[index], index)
