extends RefCounted
class_name GridPathFixture


## Recorrer la aventura requiere una solución conjunta, no tres caminos voraces
## que pueden bloquearse entre sí. El catálogo ya contiene testigos revisados;
## las suites los trazan mediante la entrada real y comprueban la finalización.
static func routes(board: GridBoard) -> Dictionary:
	if (
		board.columns != GridVariantCatalog.DATA.columns
		or board.rows != GridVariantCatalog.DATA.rows
	):
		return {}
	for level: Dictionary in GridVariantCatalog.DATA.levels.values():
		for layout: Dictionary in level.variants:
			if (
				GridReplayLayouts.cells(layout.obstacles) != board.obstacles
				or GridReplayLayouts.cells(layout.get("bridges", [])) != board.bridges
				or layout.starts.size() != board.words.size()
			):
				continue
			var starts: Array[Vector2i] = GridReplayLayouts.cells(layout.starts)
			var goals: Array[Vector2i] = GridReplayLayouts.cells(layout.goals)
			var matches: bool = true
			for index: int in range(board.words.size()):
				matches = (
					matches
					and board.words[index].start_cell == starts[index]
					and board.words[index].destination_cell == goals[index]
				)
			if not matches:
				continue
			var result: Dictionary = {}
			for index: int in range(board.words.size()):
				result[index] = GridReplayLayouts.cells(layout.solution[index]).slice(1)
			return result
	return {}
