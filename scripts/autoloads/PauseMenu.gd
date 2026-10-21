extends CanvasLayer

@onready var shade: ColorRect = $Shade
@onready var resume_button: Button = $Shade/Panel/ResumeButton
var _previous_focus: Control

func _ready() -> void:
	resume_button.pressed.connect(resume_game)
	$Shade/Panel/MenuButton.pressed.connect(_menu)


func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var book := scene.get_node_or_null("LibroHechizos")
	if scene.scene_file_path == GameManager.SCENE_PATHS.main_menu and (book == null or not book.visible):
		return
	get_viewport().set_input_as_handled()
	if shade.visible:
		resume_game()
		return
	if book and book.visible:
		book.hide_book()
		return
	var board := scene.get_node_or_null("GridBoard")
	if board and board.drawing:
		board.cancel_drawing()
		return
	if scene.scene_file_path == GameManager.SCENE_PATHS.main_menu or get_tree().paused:
		return
	open_pause()

func open_pause() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	GameManager.checkpoint_current_scene()
	get_tree().paused = true
	shade.show()
	AudioManager.play_sfx("pausa_abrir")
	resume_button.grab_focus()

func resume_game() -> void:
	if shade.visible:
		AudioManager.play_sfx("pausa_cerrar")
	shade.hide()
	get_tree().paused = false
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null

func _menu() -> void:
	resume_game()
	GameManager.go_to_scene("main_menu")
