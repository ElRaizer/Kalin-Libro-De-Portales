extends Control
class_name MissionBreak

signal continued
@onready var continue_button: Button = $ContinueButton
var _previous_focus: Control
var _walk_key := ""
var _return_key := ""
@onready var vignette: StoryVignette = $Vignette

func _ready() -> void:
	continue_button.pressed.connect(_continue)
	$WalkButton.pressed.connect(_walk)

func show_block(title: String, situation: String, word: String = "", quality: String = "", animal_word: String = "") -> void:
	$WalkButton.hide()
	$WalkHint.hide()
	_previous_focus = get_viewport().gui_get_focus_owner()
	(get_node("Title") as Label).text = title
	if word.is_empty():
		vignette.show_situation(situation, true)
	else:
		vignette.show_reward(word, quality, animal_word)
	get_parent().move_child(self, -1)
	show()
	continue_button.grab_focus()

func offer_walk(key: String, return_key: String) -> void:
	_walk_key = key
	_return_key = return_key
	$WalkButton.show()
	$WalkHint.show()

func _walk() -> void:
	GameManager.start_walk(_walk_key, _return_key)

func _continue() -> void:
	hide()
	$WalkHint.hide()
	vignette.show_situation("")
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	continued.emit()
