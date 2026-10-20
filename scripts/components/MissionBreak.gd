extends Control
class_name MissionBreak

signal continued
var continue_button: Button
var _previous_focus: Control
var vignette: StoryVignette

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.025, 0.06, 0.07, 0.94)
	add_child(shade)
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(160, 80)
	title.size = Vector2(960, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("fff0b8"))
	add_child(title)
	vignette = StoryVignette.new()
	vignette.position = Vector2(280, 170)
	vignette.size = Vector2(720, 350)
	add_child(vignette)
	continue_button = Button.new()
	continue_button.position = Vector2(1024, 646)
	continue_button.size = Vector2(232, 58)
	continue_button.text = "Seguir →"
	continue_button.theme = preload("res://themes/kalin_theme.tres")
	continue_button.theme_type_variation = &"KalinPrimaryButton"
	continue_button.pressed.connect(_continue)
	add_child(continue_button)
	hide()

func show_block(title: String, situation: String, word: String = "", quality: String = "", animal_word: String = "") -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	(get_node("Title") as Label).text = title
	if word.is_empty():
		vignette.show_situation(situation, true)
	else:
		vignette.show_reward(word, quality, animal_word)
	get_parent().move_child(self, -1)
	show()
	continue_button.grab_focus()

func _continue() -> void:
	hide()
	vignette.show_situation("")
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	continued.emit()

