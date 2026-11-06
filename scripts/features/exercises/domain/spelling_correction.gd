extends RefCounted
class_name SpellingCorrection

## Alinea grafías, no sílabas. Sólo una comprobación confirma partes nuevas.
var expected: String = ""
var positions: Array[int] = []
var letters: Array[String] = []
var locked: Array[bool] = []


func prepare(typed: String, target: String) -> void:
	expected = target
	positions.clear()
	letters.clear()
	locked.clear()
	var actual: String = typed.replace("’", "'")
	var costs: Array[Array] = []
	for row: int in range(actual.length() + 1):
		var cells: Array[int] = []
		cells.resize(target.length() + 1)
		cells.fill(0)
		costs.append(cells)
	for row: int in range(actual.length(), -1, -1):
		for column: int in range(target.length(), -1, -1):
			if row == actual.length():
				costs[row][column] = target.length() - column
			elif column == target.length():
				costs[row][column] = actual.length() - row
			elif actual[row].to_lower() == target[column].to_lower():
				costs[row][column] = costs[row + 1][column + 1]
			else:
				costs[row][column] = (
					1
					+ mini(
						costs[row + 1][column + 1],
						mini(costs[row + 1][column], costs[row][column + 1])
					)
				)
	var row: int = 0
	var column: int = 0
	while row < actual.length() or column < target.length():
		if (
			row < actual.length()
			and column < target.length()
			and actual[row].to_lower() == target[column].to_lower()
		):
			_append(column, actual[row], true)
			row += 1
			column += 1
		elif (
			row < actual.length()
			and column < target.length()
			and costs[row][column] == 1 + costs[row + 1][column + 1]
		):
			_append(column, "", false)
			row += 1
			column += 1
		elif column < target.length() and costs[row][column] == 1 + costs[row][column + 1]:
			_append(column, "", false)
			column += 1
		else:
			_append(-1, actual[row], false)
			row += 1


func _append(position: int, letter: String, fixed: bool) -> void:
	positions.append(position)
	letters.append(letter)
	locked.append(fixed)


func value() -> String:
	var result: String = ""
	for index: int in range(positions.size()):
		result += letters[index] if not letters[index].is_empty() or positions[index] < 0 else "_"
	return result


func has_entry() -> bool:
	for index: int in range(positions.size()):
		if (
			not locked[index]
			and (
				positions[index] < 0 and letters[index].is_empty()
				or positions[index] >= 0 and not letters[index].is_empty()
			)
		):
			return true
	return value().to_lower() == expected.to_lower()


func has_pending() -> bool:
	return false in locked


func confirm() -> int:
	var improved: int = 0
	for index: int in range(positions.size()):
		if locked[index]:
			continue
		var correct: bool = (
			letters[index].is_empty()
			if positions[index] < 0
			else (
				letters[index].replace("’", "'").to_lower() == expected[positions[index]].to_lower()
			)
		)
		if correct:
			locked[index] = true
			improved += 1
		elif positions[index] >= 0:
			letters[index] = ""
	return improved


func apply_text(typed: String) -> void:
	var solved: bool = WordMatcher.match_word(typed, expected).correct
	for index: int in range(positions.size()):
		if locked[index]:
			continue
		if solved:
			letters[index] = "" if positions[index] < 0 else expected[positions[index]]
		else:
			letters[index] = typed[index] if index < typed.length() and typed[index] != "_" else ""


func snapshot() -> Dictionary:
	return {
		"expected": expected,
		"positions": positions.duplicate(),
		"letters": letters.duplicate(),
		"locked": locked.duplicate()
	}


func restore(saved: Dictionary, target: String) -> bool:
	if (
		saved.get("expected") is not String
		or saved.expected != target
		or saved.get("positions") is not Array
		or saved.get("letters") is not Array
		or saved.get("locked") is not Array
	):
		return false
	var count: int = saved.positions.size()
	if (
		count > 200
		or count < target.length()
		or saved.letters.size() != count
		or saved.locked.size() != count
	):
		return false
	var next_position: int = 0
	for index: int in range(count):
		var position: Variant = saved.positions[index]
		var letter: Variant = saved.letters[index]
		var fixed: Variant = saved.locked[index]
		if (
			not SaveSchema.is_number(position)
			or float(position) != floor(float(position))
			or letter is not String
			or letter.length() > 1
			or fixed is not bool
		):
			return false
		if int(position) == -1:
			if fixed and not letter.is_empty():
				return false
		elif int(position) != next_position or next_position >= target.length():
			return false
		else:
			if fixed and letter.replace("’", "'").to_lower() != target[next_position].to_lower():
				return false
			next_position += 1
	if next_position != target.length():
		return false
	expected = target
	positions.assign(saved.positions)
	letters.assign(saved.letters)
	locked.assign(saved.locked)
	return true
