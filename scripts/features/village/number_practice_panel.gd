extends VillagePanel
class_name NumberPracticePanel

signal completed
signal book_requested(origin: Control)
@export var settings: CountingSet = preload("res://data/village/practice_counting.tres")
var workbench: CountingWorkbench
var _finish: Button
var _repeat: Button
var _book: Button


func _build_content() -> void:
	heading.text = "Cantidades para compartir"
	close_button.text = "Salir y guardar"
	workbench = CountingWorkbench.new()
	body.add_child(workbench)
	workbench.move_actions_to(footer)
	workbench.changed.connect(_on_changed)
	_finish = add_button(footer, "Terminar tanda", finish_practice)
	_repeat = add_button(footer, "Repetir", repeat_practice)
	_book = add_button(footer, "Libro", func() -> void: book_requested.emit(_book))
	workbench.setup(settings)
	refresh()


func restore(state: Dictionary) -> void:
	if not CountingActivity.valid_state(state, settings):
		return
	workbench.setup(settings, state)
	refresh()


func open_practice(origin: Control) -> void:
	refresh()
	if open_panel(origin) and not workbench.activity.finished():
		workbench.focus_input()


func refresh() -> void:
	workbench.action_controls.visible = not workbench.activity.finished()
	_finish.visible = workbench.activity.finished()
	_repeat.visible = workbench.activity.finished()
	notice.text = "Dos cantidades a tu ritmo. Pistas y repetición gratuitas; no cambia tu registro de palabras."
	layout_changed.emit()
	refresh_focus()


func _on_changed() -> void:
	refresh()
	if workbench.activity.finished():
		_finish.grab_focus()
	changed.emit()


func repeat_practice() -> void:
	if not workbench.activity.finished():
		return
	var targets: Array[int] = workbench.activity.session.targets(settings)
	var new_targets: Array[int] = targets.duplicate()
	new_targets.reverse()
	workbench.setup(settings, {}, new_targets)
	refresh()
	changed.emit()


func finish_practice() -> void:
	if not visible or not workbench.activity.finished():
		return
	close_panel()
	completed.emit()


func close_panel() -> void:
	if not visible:
		return
	super.close_panel()
	changed.emit()
