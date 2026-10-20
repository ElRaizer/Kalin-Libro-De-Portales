extends CanvasLayer
class_name RecallCheck

signal completed
signal progress_changed

@onready var manager: Node = get_node("/root/GameManager")
var words: Array[String] = []
var question_index := 0
var mistakes := 0
var solved := false
var prompt: Label
var options: HBoxContainer
var next_button: Button

func _ready() -> void:
	layer = 8
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.025, 0.06, 0.05, 0.82)
	add_child(shade)
	var menu := Button.new()
	menu.position = Vector2(28, 18)
	menu.size = Vector2(130, 46)
	menu.theme = preload("res://themes/kalin_theme.tres")
	menu.theme_type_variation = &"KalinSecondaryButton"
	menu.text = "Menú"
	menu.pressed.connect(func(): manager.go_to_scene("main_menu"))
	shade.add_child(menu)
	var book := Button.new()
	book.position = Vector2(1120, 18)
	book.size = Vector2(130, 46)
	book.theme = menu.theme
	book.theme_type_variation = &"KalinPrimaryButton"
	book.text = "Libro"
	book.pressed.connect(func():
		var vocabulary_book := get_parent().get_node_or_null("LibroHechizos")
		if vocabulary_book:
			vocabulary_book.show_book())
	shade.add_child(book)
	var panel := PanelContainer.new()
	panel.position = Vector2(310, 140)
	panel.size = Vector2(660, 440)
	panel.theme = preload("res://themes/kalin_theme.tres")
	panel.theme_type_variation = &"KalinCreamPanel"
	shade.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 28)
	prompt.add_theme_color_override("font_color", Color("3b2415"))
	content.add_child(prompt)
	options = HBoxContainer.new()
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 16)
	content.add_child(options)
	next_button = Button.new()
	next_button.custom_minimum_size.y = 56
	next_button.theme_type_variation = &"KalinPrimaryButton"
	next_button.text = "Continuar →"
	next_button.pressed.connect(_next)
	content.add_child(next_button)
	visible = false

func start(vocabulary: Array[String], index: int = 0) -> void:
	words = vocabulary.duplicate()
	question_index = clampi(index, 0, words.size())
	visible = true
	_show_question()

func _show_question() -> void:
	if question_index >= words.size():
		hide()
		completed.emit()
		return
	solved = false
	mistakes = 0
	prompt.text = "Encuentra: %s\n%d / %d" % [words[question_index], question_index + 1, words.size()]
	next_button.disabled = true
	for child: Node in options.get_children():
		options.remove_child(child)
		child.queue_free()
	var choices := words.duplicate()
	choices.shuffle()
	for word: String in choices:
		var button := Button.new()
		button.custom_minimum_size = Vector2(185, 230)
		button.theme_type_variation = &"KalinSecondaryButton"
		button.icon = load(manager.get_book_illustration(word))
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 132)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.pressed.connect(_choose.bind(word, button))
		options.add_child(button)
	(options.get_child(0) as Button).grab_focus()

func _choose(word: String, button: Button) -> void:
	if solved:
		return
	button.text = word
	if word == words[question_index]:
		solved = true
		button.text = "✓ " + word
		prompt.text = "%s · %s" % [word, manager.get_vocabulary_entry(word).get("spanish", "")]
		next_button.disabled = false
		next_button.grab_focus()
		progress_changed.emit()
	else:
		mistakes += 1
		button.text += "\n" + str(manager.get_vocabulary_entry(word).get("spanish", ""))
		if mistakes >= 2:
			for child: Button in options.get_children():
				if child.icon == load(manager.get_book_illustration(words[question_index])):
					child.text = words[question_index]

func _next() -> void:
	if not solved:
		return
	question_index += 1
	solved = false
	progress_changed.emit()
	_show_question()

func restore_answer() -> void:
	if question_index >= words.size():
		return
	var target := words[question_index]
	for button: Button in options.get_children():
		if button.icon == load(manager.get_book_illustration(target)):
			_choose(target, button)
			return
