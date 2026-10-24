extends RefCounted
class_name GridReplayLayouts

static func cells(raw: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Array in raw:
		result.append(Vector2i(int(cell[0]), int(cell[1])))
	return result

## El testigo debe resolver simultáneamente todas las parejas, sin cruces.
static func has_solution(layout: Dictionary, columns: int, rows: int) -> bool:
	var occupied := {}
	for cell: Vector2i in cells(layout.obstacles):
		if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows or occupied.has(cell):
			return false
		occupied[cell] = true
	if layout.starts.size() != layout.goals.size() or layout.solution.size() != layout.starts.size():
		return false
	for index: int in range(layout.starts.size()):
		var route := cells(layout.solution[index])
		if route.size() < 2 or route[0] != cells(layout.starts)[index] or route.back() != cells(layout.goals)[index]:
			return false
		for cursor: int in range(route.size()):
			var cell := route[cursor]
			if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows or occupied.has(cell):
				return false
			if cursor > 0:
				var step := cell - route[cursor - 1]
				if absi(step.x) + absi(step.y) != 1:
					return false
			occupied[cell] = true
	return true

static func configure(board: GridBoard, level: int, state: Dictionary, seed_value: int) -> String:
	var source: Dictionary = GridVariantCatalog.DATA.levels.get(str(level), {})
	if source.is_empty() or board.columns != 12 or board.rows != 7 or board.words.size() != 3:
		return ""
	# Un tablero personalizado en el Inspector conserva las decisiones de autor.
	if cells(source.base.obstacles) != board.obstacles:
		return ""
	for index: int in range(board.words.size()):
		if board.words[index].start_cell != cells(source.base.starts)[index] or board.words[index].destination_cell != cells(source.base.goals)[index]:
			return ""
	var chosen := -1
	var previous := -1
	for index: int in range(source.variants.size()):
		if source.variants[index].id == state.get("board_variant", ""):
			chosen = index
		if source.variants[index].id == ReplayVariation.previous(state, "board_variant", ""):
			previous = index
	if chosen < 0:
		# Los guardados anteriores conservan la geometría original de sus trazos.
		if state.has("board"):
			return ""
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		chosen = ReplayVariation.pick(source.variants.size(), rng, previous)
	var layout: Dictionary = source.variants[chosen]
	if not has_solution(layout, board.columns, board.rows):
		return ""
	board.apply_layout(cells(layout.starts), cells(layout.goals), cells(layout.obstacles))
	return str(layout.id)
