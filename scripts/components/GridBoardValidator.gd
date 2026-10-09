@tool
extends RefCounted
class_name GridBoardValidator

## Valida los datos editables de GridBoard sin depender de su estado jugable.
## Puede utilizarse desde el Inspector, pruebas o futuras herramientas de autor.

static func validate(
	columns: int,
	rows: int,
	empty_tile: Texture2D,
	obstacle_tile: Texture2D,
	obstacles: Array[Vector2i],
	words: Array[GridWordData]
) -> PackedStringArray:
	var issues: PackedStringArray = []
	if empty_tile == null:
		issues.append("Asigna una textura a empty_tile.")
	if obstacle_tile == null and not obstacles.is_empty():
		issues.append("Asigna una textura a obstacle_tile cuando existan obstáculos.")
	if words.is_empty():
		issues.append("Agrega al menos una palabra al tablero.")

	var occupied_cells: Dictionary = {}
	var maya_words: Dictionary = {}
	for obstacle: Vector2i in obstacles:
		if not _is_valid_cell(obstacle, columns, rows):
			issues.append("El obstáculo %s está fuera del tablero." % obstacle)
			continue
		if occupied_cells.has(obstacle):
			issues.append("La celda %s está ocupada más de una vez." % obstacle)
		occupied_cells[obstacle] = "obstáculo"

	for index: int in words.size():
		var word: GridWordData = words[index]
		if word == null:
			issues.append("La palabra %d no tiene un recurso asignado." % (index + 1))
			continue
		if word.maya_word.strip_edges().is_empty():
			issues.append("La palabra %d no tiene texto maya." % (index + 1))
		elif maya_words.has(word.maya_word):
			issues.append("La palabra maya '%s' está duplicada." % word.maya_word)
		else:
			maya_words[word.maya_word] = true
		_validate_word_cell(word.start_cell, "inicio de '%s'" % word.maya_word, columns, rows, occupied_cells, issues)
		_validate_word_cell(word.destination_cell, "destino de '%s'" % word.maya_word, columns, rows, occupied_cells, issues)
		if word.start_cell == word.destination_cell:
			issues.append("'%s' empieza y termina en la misma celda." % word.maya_word)
	return issues

static func _validate_word_cell(
	cell: Vector2i,
	label: String,
	columns: int,
	rows: int,
	occupied_cells: Dictionary,
	issues: PackedStringArray
) -> void:
	if not _is_valid_cell(cell, columns, rows):
		issues.append("El %s (%s) está fuera del tablero." % [label, cell])
		return
	if occupied_cells.has(cell):
		issues.append("La celda %s se comparte entre %s y %s." % [cell, occupied_cells[cell], label])
	occupied_cells[cell] = label

static func _is_valid_cell(cell: Vector2i, columns: int, rows: int) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows
