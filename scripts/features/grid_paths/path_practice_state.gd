extends RefCounted
class_name PathPracticeState

var controller: GridPathController = GridPathController.new()
var variant: String = ""
var animal: String = ""
var supported: bool = false
var cursor: Vector2i = Vector2i.ZERO


static func animals(known: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for word: String in known:
		if (
			int(VocabularyCatalog.entry(word).get("world", 0)) == 1
			and word in VocabularyCatalog.learnable_keys()
		):
			result.append(word)
	return result


static func layout(id: String) -> Dictionary:
	for entry: Dictionary in GridVariantCatalog.DATA.levels["2"].variants:
		if entry.id == id:
			return entry.duplicate(true)
	return {}


static func valid_pair(value: Variant) -> bool:
	return (
		value is Array
		and value.size() == 2
		and CountingActivity.integer(value[0], 0, 11)
		and CountingActivity.integer(value[1], 0, 6)
	)


static func valid_state(value: Variant, known: Dictionary) -> bool:
	if (
		value is not Dictionary
		or value.get("variant") is not String
		or layout(value.variant).is_empty()
	):
		return false
	if value.get("animal") is not String or value.animal not in animals(known):
		return false
	if (
		value.get("connected") is not bool
		or value.get("supported") is not bool
		or not valid_pair(value.get("cursor"))
	):
		return false
	if value.get("path") is not Array or value.path.size() > 84:
		return false
	var trial: PathPracticeState = PathPracticeState.new()
	trial.configure(value.variant, value.animal)
	for pair: Variant in value.path:
		if not valid_pair(pair):
			return false
		var before: int = trial.controller.paths[0].size()
		trial.controller.extend(Vector2i(int(pair[0]), int(pair[1])))
		if trial.controller.paths[0].size() != before + 1:
			return false
	return not value.connected or trial.controller.can_finish(0)


func configure(id: String, word: String) -> void:
	variant = id
	animal = word
	var source: Dictionary = layout(id)
	var entry: GridWordData = GridWordData.new()
	entry.maya_word = word
	entry.start_cell = GridReplayLayouts.cells(source.starts)[0]
	entry.destination_cell = GridReplayLayouts.cells(source.goals)[0]
	controller = GridPathController.new()
	controller.configure(12, 7, [entry], GridReplayLayouts.cells(source.obstacles))
	controller.start(0)
	cursor = entry.start_cell
	supported = false


func prepare(known: Dictionary, seed_value: int) -> bool:
	var available: Array[String] = animals(known)
	if available.is_empty():
		return false
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = seed_value
	var variants: Array = GridVariantCatalog.DATA.levels["2"].variants
	configure(
		variants[random.randi_range(0, variants.size() - 1)].id,
		available[random.randi_range(0, available.size() - 1)]
	)
	return true


func restore(state: Dictionary, known: Dictionary) -> bool:
	if not valid_state(state, known):
		return false
	configure(state.variant, state.animal)
	for pair: Array in state.path:
		controller.extend(Vector2i(int(pair[0]), int(pair[1])))
	if state.connected:
		controller.try_finalize(controller.words[0].destination_cell)
	supported = state.supported
	cursor = Vector2i(int(state.cursor[0]), int(state.cursor[1]))
	return true


func snapshot() -> Dictionary:
	if variant.is_empty():
		return {}
	var path: Array[Array] = []
	for cell: Vector2i in controller.paths[0]:
		path.append([cell.x, cell.y])
	return {
		"variant": variant,
		"animal": animal,
		"path": path,
		"connected": not controller.connected.is_empty(),
		"supported": supported,
		"cursor": [cursor.x, cursor.y]
	}


func press(cell: Vector2i) -> void:
	if not controller.connected.is_empty() or not controller.is_valid_cell(cell):
		return
	cursor = cell
	if cell == controller.words[0].start_cell:
		controller.start(0)
	elif cell == controller.words[0].destination_cell:
		controller.try_finalize(cell)
	elif not controller.try_retract(cell):
		controller.extend(cell)
