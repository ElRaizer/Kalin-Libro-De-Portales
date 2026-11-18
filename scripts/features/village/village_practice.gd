extends Node
class_name VillagePractice

signal changed
signal layout_changed(controls: Control)
signal book_requested(origin: Control)
var room: ChallengeRoom
var blocking_layer: CanvasLayer
var numbers: NumberPracticePanel
var paths: PathPracticePanel
var hub: PracticeHub
var mode: String = "words"
var next_family: String = "words"
var _origin: WeakRef
const FAMILIES: Array[String] = ["words", "numbers", "paths"]


func _ready() -> void:
	hub = PracticeHub.new()
	add_child(hub)
	numbers = NumberPracticePanel.new()
	add_child(numbers)
	paths = PathPracticePanel.new()
	add_child(paths)
	for panel: VillagePanel in [hub, numbers, paths]:
		panel.blocking_layer = blocking_layer
		panel.layout_changed.connect(func() -> void: layout_changed.emit(panel.controls))
		panel.changed.connect(changed.emit)
	numbers.book_requested.connect(book_requested.emit)
	paths.book_requested.connect(book_requested.emit)
	room.book_requested.connect(book_requested.emit)
	room.blocking_layer = blocking_layer
	hub.family_requested.connect(select_family)
	room.batch_completed.connect(_completed.bind("words"))
	numbers.completed.connect(_completed.bind("numbers"))
	paths.completed.connect(_completed.bind("paths"))


func available() -> Array[String]:
	var families: Array[String] = []
	if not GameManager.learned_words().is_empty():
		families.append("words")
	if GameManager.session.is_level_completed(4, 2):
		families.append("numbers")
	if not PathPracticeState.animals(GameManager.learned_words()).is_empty():
		families.append("paths")
	return families


func open_hub(origin: Control) -> void:
	_origin = weakref(origin)
	hub.open_hub(origin, available(), next_family)


func close_active() -> bool:
	for panel: VillagePanel in [hub, numbers, paths]:
		if panel.visible:
			panel.close_panel()
			return true
	return false


func select_family(family: String) -> void:
	if (
		get_tree().paused
		or (family != "mixed" and family not in available())
		or available().is_empty()
	):
		return
	mode = family
	if family == "mixed":
		var families: Array[String] = available()
		if next_family not in families:
			next_family = families[0] if not families.is_empty() else "words"
		family = next_family
	var origin: Control = _origin.get_ref() as Control if _origin != null else null
	match family:
		"words":
			room.open_room(origin)
		"numbers":
			numbers.open_practice(origin)
		"paths":
			paths.open_practice(origin)
	changed.emit()


func _completed(family: String) -> void:
	var families: Array[String] = available()
	for offset: int in range(1, FAMILIES.size() + 1):
		var candidate: String = FAMILIES[(FAMILIES.find(family) + offset) % FAMILIES.size()]
		if candidate in families:
			next_family = candidate
			break
	changed.emit()
	if mode == "mixed":
		select_family("mixed")


func snapshot() -> Dictionary:
	return {
		"mode": mode,
		"next": next_family,
		"numbers": numbers.workbench.activity.snapshot(),
		"paths": paths.activity.snapshot()
	}


func restore(state: Dictionary) -> void:
	if state.get("mode") is String and state.mode in FAMILIES + ["mixed"]:
		mode = state.mode
	if state.get("next") is String and state.next in FAMILIES:
		next_family = state.next
	if state.get("numbers") is Dictionary:
		numbers.restore(state.numbers)
	if state.get("paths") is Dictionary:
		paths.restore(state.paths)
