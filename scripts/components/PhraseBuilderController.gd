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

## Conserva la respuesta correcta y alterna los distractores sin cambiar la lección.
## El orden depende de la ronda para que una partida reanudada conserve sus opciones.
static func show_even_choices(buttons: Dictionary, correct: String, round_index: int) -> void:
	var words: Array = buttons.keys()
	var count := mini(4, words.size())
	count -= count % 2
	var visible_words: Array = [correct]
	for offset: int in range(words.size()):
		var word: String = words[(round_index + offset) % words.size()]
		if word != correct and visible_words.size() < count:
			visible_words.append(word)
	for word: String in buttons:
		(buttons[word] as Button).visible = word in visible_words
	# La posición se fija durante el intento y cambia entre rondas. La semilla
	# guardada por la escena reproduce la misma disposición al continuar.
	var grid: Node = (buttons[correct] as Button).get_parent()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%s" % [grid.get_meta("layout_seed", 1), round_index, grid.name])
	var shuffled: Array = buttons.values()
	for index: int in range(shuffled.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: Variant = shuffled[index]
		shuffled[index] = shuffled[other]
		shuffled[other] = swap
	for button: Button in shuffled:
		grid.move_child(button, -1)

static func shuffle_grid(grid: Container, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var children := grid.get_children()
	for index: int in range(children.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap: Node = children[index]
		children[index] = children[other]
		children[other] = swap
	for child: Node in children:
		grid.move_child(child, -1)

static func focus_first_visible(grid: Container) -> void:
	var buttons := _buttons_in(grid)
	if not buttons.is_empty():
		buttons[0].grab_focus()

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
		if child is Button and (child as Button).visible:
			buttons.append(child as Button)
	return buttons

static func mark_slot(slot: Control, correct: bool) -> void:
	var marker := slot.get_node("ResultMark") as Label
	marker.text = "✓" if correct else "↻"
	marker.add_theme_color_override("font_color", Color("2e8b57") if correct else Color("b56a1f"))
	marker.show()

static func clear_mark(slot: Control) -> void:
	var marker := slot.get_node_or_null("ResultMark") as Label
	if marker:
		marker.hide()
