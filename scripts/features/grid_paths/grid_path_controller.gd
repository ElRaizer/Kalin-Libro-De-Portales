@tool
extends RefCounted
class_name GridPathController

## Estado y reglas del tablero. Puede usarse sin SceneTree ni nodos visuales.
## Los eventos describen cambios; GridBoard decide cómo presentarlos.
signal path_selected(index: int)
signal path_updated(index: int)
signal cell_erased(cell: Vector2i)
signal path_reset(index: int)
signal path_completed(index: int)
signal invalid_move(reason: String, cell: Vector2i)
enum Cell { EMPTY, OBSTACLE, WORD, DESTINATION, PATH }
var columns: int = 0
var rows: int = 0
var words: Array[GridWordData] = []
var grid_state: Array[Array] = []
var tile_owner: Dictionary = {}
var paths: Dictionary = {}
var connected: Array[int] = []
var drawing: bool = false
var active_index: int = -1
var last_cell: Vector2i = Vector2i(-1, -1)


func configure(
	width: int, height: int, entries: Array[GridWordData], obstacles: Array[Vector2i]
) -> void:
	columns = width
	rows = height
	words = entries
	grid_state.clear()
	tile_owner.clear()
	paths.clear()
	connected.clear()
	drawing = false
	active_index = -1
	last_cell = Vector2i(-1, -1)
	for row: int in range(rows):
		var cells: Array[int] = []
		cells.resize(columns)
		cells.fill(Cell.EMPTY)
		grid_state.append(cells)
	for obstacle: Vector2i in obstacles:
		if is_valid_cell(obstacle):
			grid_state[obstacle.y][obstacle.x] = Cell.OBSTACLE
	for index: int in range(words.size()):
		var word: GridWordData = words[index]
		if word == null:
			continue
		for cell: Vector2i in [word.start_cell, word.destination_cell]:
			if is_valid_cell(cell):
				grid_state[cell.y][cell.x] = (
					Cell.WORD if cell == word.start_cell else Cell.DESTINATION
				)
				tile_owner[cell] = index
		paths[index] = []


func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows


static func are_adjacent(first: Vector2i, second: Vector2i) -> bool:
	var delta: Vector2i = first - second
	return absi(delta.x) + absi(delta.y) == 1


func start(index: int) -> void:
	if index < 0 or index >= words.size():
		return
	reset_connected(index)
	clear(index)
	active_index = index
	drawing = true
	last_cell = words[index].start_cell
	path_selected.emit(index)


func hint_path(index: int, max_steps: int = 0) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if index < 0 or index >= words.size() or index in connected:
		return empty
	var start: Vector2i = words[index].start_cell
	var partial: Array = paths.get(index, [])
	if not partial.is_empty():
		start = partial.back()
	var goal: Vector2i = words[index].destination_cell
	var queue: Array[Vector2i] = [start]
	var parents: Dictionary = {start: start}
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell == goal:
			var route: Array[Vector2i] = [cell]
			while cell != start:
				cell = parents[cell]
				route.push_front(cell)
			if max_steps > 0 and route.size() > max_steps + 1:
				route.resize(max_steps + 1)
			return route
		for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
			var next: Vector2i = cell + direction
			if not is_valid_cell(next) or next in parents:
				continue
			if next != goal and grid_state[next.y][next.x] != Cell.EMPTY:
				continue
			parents[next] = cell
			queue.append(next)
	return empty


func try_finalize(destination_cell: Vector2i) -> void:
	if active_index < 0 or active_index in connected:
		return
	if destination_cell != words[active_index].destination_cell:
		return
	if tile_owner.get(destination_cell, -1) != active_index:
		return
	var previous_cell: Vector2i = words[active_index].start_cell
	if not paths[active_index].is_empty():
		previous_cell = paths[active_index].back()
	if are_adjacent(previous_cell, destination_cell):
		finalize(active_index)


func try_resume(cell: Vector2i) -> void:
	var index: int = tile_owner.get(cell, -1)
	if index < 0 or index in connected or paths.get(index, []).is_empty():
		return
	if paths[index].back() != cell:
		return
	active_index = index
	drawing = true
	last_cell = cell
	path_selected.emit(index)


func try_retract(cell: Vector2i) -> bool:
	if active_index < 0 or paths.get(active_index, []).is_empty():
		return false
	var path: Array = paths[active_index]
	var current_tip: Vector2i = path.back()
	if not are_adjacent(cell, current_tip):
		return false
	var is_previous: bool = path.size() >= 2 and path[path.size() - 2] == cell
	var is_start: bool = path.size() == 1 and words[active_index].start_cell == cell
	if not is_previous and not is_start:
		return false
	var removed_cell: Vector2i = path.pop_back()
	grid_state[removed_cell.y][removed_cell.x] = Cell.EMPTY
	tile_owner.erase(removed_cell)
	cell_erased.emit(removed_cell)
	path_updated.emit(active_index)
	return true


func extend(cell: Vector2i) -> void:
	if active_index < 0 or not is_valid_cell(cell) or cell in paths[active_index]:
		return
	if cell in tile_owner and tile_owner[cell] != active_index:
		invalid_move.emit("Los caminos no se cruzan", cell)
		return
	if grid_state[cell.y][cell.x] not in [Cell.EMPTY, Cell.PATH]:
		return
	var previous: Vector2i = (
		words[active_index].start_cell
		if paths[active_index].is_empty()
		else paths[active_index].back()
	)
	if not are_adjacent(cell, previous):
		return
	paths[active_index].append(cell)
	grid_state[cell.y][cell.x] = Cell.PATH
	tile_owner[cell] = active_index
	path_updated.emit(active_index)


func clear(index: int) -> void:
	for cell: Vector2i in paths.get(index, []):
		grid_state[cell.y][cell.x] = Cell.EMPTY
		tile_owner.erase(cell)
		cell_erased.emit(cell)
	paths[index] = []
	path_updated.emit(index)


func reset_connected(index: int) -> void:
	if index not in connected:
		return
	connected.erase(index)
	cell_erased.emit(words[index].destination_cell)
	clear(index)
	path_reset.emit(index)


func finalize(index: int) -> void:
	if index < 0 or index >= words.size() or index in connected:
		return
	connected.append(index)
	drawing = false
	active_index = -1
	path_completed.emit(index)
