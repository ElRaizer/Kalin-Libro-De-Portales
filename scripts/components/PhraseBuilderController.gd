extends RefCounted
class_name PhraseBuilderController

const UI_EFFECTS = preload("res://scripts/components/UIEffects.gd")

static func collect_buttons(grid: Container, selection_callback: Callable) -> Dictionary:
	var buttons: Dictionary = {}
	for child: Node in grid.get_children():
		if child is DraggableWordButton:
			var button := child as DraggableWordButton
			buttons[button.word_value] = button
			button.pressed.connect(selection_callback.bind(button.word_value))
	return buttons

static func configure_navigation(first_grid: Container, second_grid: Container, action_button: Button) -> void:
	var first: Array[Button] = _buttons_in(first_grid)
	var second: Array[Button] = _buttons_in(second_grid)
	UI_EFFECTS.configure_horizontal_focus(first)
	UI_EFFECTS.configure_horizontal_focus(second)
	if second.is_empty():
		return
	for index: int in range(first.size()):
		var target := second[mini(index, second.size() - 1)]
		first[index].focus_neighbor_bottom = first[index].get_path_to(target)
	for button: Button in second:
		var target_index := mini(second.find(button), first.size() - 1)
		if target_index >= 0:
			button.focus_neighbor_top = button.get_path_to(first[target_index])
		button.focus_neighbor_bottom = button.get_path_to(action_button)

static func set_button_states(first: Dictionary, first_value: String, second: Dictionary, second_value: String) -> void:
	for value: String in first:
		(first[value] as Button).button_pressed = value == first_value
	for value: String in second:
		(second[value] as Button).button_pressed = value == second_value

static func set_enabled(first: Dictionary, second: Dictionary, enabled: bool) -> void:
	for button: Button in first.values():
		button.disabled = not enabled
	for button: Button in second.values():
		button.disabled = not enabled

static func celebrate(slot: Control, feedback: Label, message: String, color: Color) -> void:
	if slot.has_method("pop"):
		slot.pop()
	feedback.text = message
	feedback.add_theme_color_override("font_color", color)

static func build_two_phase_plan(count: int, shuffle_guided: bool = false) -> Array[Dictionary]:
	var guided: Array[int] = []
	var recall: Array[int] = []
	for index: int in range(count):
		guided.append(index)
		recall.append(index)
	if shuffle_guided:
		guided.shuffle()
	recall.shuffle()
	var plan: Array[Dictionary] = []
	for index: int in guided:
		plan.append({"challenge": index, "guided": true})
	for index: int in recall:
		plan.append({"challenge": index, "guided": false})
	return plan

static func _buttons_in(grid: Container) -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in grid.get_children():
		if child is Button:
			buttons.append(child as Button)
	return buttons
