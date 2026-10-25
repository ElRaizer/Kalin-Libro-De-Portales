extends CanvasLayer


func _ready() -> void:
	var manager: Node = get_parent()
	manager.save_status_changed.connect(_show_status)
	$Panel/Retry.pressed.connect(manager.retry_save)
	_show_status(manager.save_status_message)


func _show_status(message: String) -> void:
	$Panel.visible = not message.is_empty()
	$Panel/Message.text = message
