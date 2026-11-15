extends RefCounted
class_name GridReplayLayouts


static func cells(raw: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Array in raw:
		result.append(Vector2i(int(cell[0]), int(cell[1])))
	return result


## El testigo resuelve las parejas; sólo los dos pisos de un puente pueden compartir celda.
static func has_solution(layout: Dictionary, columns: int, rows: int) -> bool:
	var occupied: Dictionary = {}
	var crossings: Array[Vector2i] = cells(layout.get("bridges", []))
	for cell: Vector2i in cells(layout.obstacles):
		if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows or occupied.has(cell):
			return false
		occupied[cell] = true
	var seen_bridges: Array[Vector2i] = []
	for cell: Vector2i in crossings:
		if (
			cell.x < 0
			or cell.x >= columns
			or cell.y < 0
			or cell.y >= rows
			or cell in seen_bridges
			or occupied.has(cell)
		):
			return false
		seen_bridges.append(cell)
	if (
		layout.starts.size() != layout.goals.size()
		or layout.solution.size() != layout.starts.size()
	):
		return false
	for index: int in range(layout.starts.size()):
		var route: Array[Vector2i] = cells(layout.solution[index])
		if (
			route.size() < 2
			or route[0] != cells(layout.starts)[index]
			or route.back() != cells(layout.goals)[index]
		):
			return false
		for cursor: int in range(route.size()):
			var cell: Vector2i = route[cursor]
			var identity: Variant = cell
			if cell in crossings:
				if (
					cursor == 0
					or cursor == route.size() - 1
					or route[cursor + 1] - cell != cell - route[cursor - 1]
				):
					return false
				identity = Vector3i(cell.x, cell.y, 0 if cell.y == route[cursor - 1].y else 1)
			if (
				cell.x < 0
				or cell.x >= columns
				or cell.y < 0
				or cell.y >= rows
				or occupied.has(cell)
				or occupied.has(identity)
			):
				return false
			if cursor > 0:
				var step: Vector2i = cell - route[cursor - 1]
				if absi(step.x) + absi(step.y) != 1:
					return false
			occupied[identity] = true
	return true


static func configure(board: GridBoard, level: int, state: Dictionary, seed_value: int) -> String:
	var source: Dictionary = GridVariantCatalog.DATA.levels.get(str(level), {})
	if source.is_empty() or board.columns != 12 or board.rows != 7 or board.words.size() != 3:
		return ""
	# Un tablero personalizado en el Inspector conserva las decisiones de autor.
	if cells(source.base.obstacles) != board.obstacles or not board.bridges.is_empty():
		return ""
	for index: int in range(board.words.size()):
		if (
			board.words[index].start_cell != cells(source.base.starts)[index]
			or board.words[index].destination_cell != cells(source.base.goals)[index]
		):
			return ""
	var chosen: int = -1
	var previous: int = -1
	for index: int in range(source.variants.size()):
		if source.variants[index].id == state.get("board_variant", ""):
			chosen = index
		if source.variants[index].id == ReplayVariation.previous(state, "board_variant", ""):
			previous = index
	if chosen < 0:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value
		chosen = ReplayVariation.pick(source.variants.size(), rng, previous)
	var layout: Dictionary = source.variants[chosen]
	if not has_solution(layout, board.columns, board.rows):
		return ""
	board.apply_layout(
		cells(layout.starts),
		cells(layout.goals),
		cells(layout.obstacles),
		cells(layout.get("bridges", []))
	)
	return str(layout.id)
