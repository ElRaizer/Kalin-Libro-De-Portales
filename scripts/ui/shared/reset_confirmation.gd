extends Control
class_name ResetConfirmation

signal confirmed

var _previous_focus: Control
@onready var cancel_button: Button = $Panel/Buttons/CancelButton


func _ready() -> void:
	cancel_button.pressed.connect(_close)
	$Panel/Buttons/ConfirmButton.pressed.connect(_confirm)


func show_dialog() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	show()
	SoundCue.play(self, "panel_abrir")
	cancel_button.grab_focus()


func _close() -> void:
	if visible:
		SoundCue.play(self, "panel_cerrar")
	hide()
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()
	_previous_focus = null


func _confirm() -> void:
	_close()
	confirmed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
