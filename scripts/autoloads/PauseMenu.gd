extends CanvasLayer

var shade: ColorRect
var resume_button: Button
var _previous_focus: Control

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	shade = ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.025, 0.06, 0.07, 0.84)
	add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(410, 205)
	panel.size = Vector2(460, 310)
	panel.theme = preload("res://themes/kalin_theme.tres")
	panel.theme_type_variation = &"KalinCreamPanel"
	shade.add_child(panel)
	var title := Label.new()
	title.text = "Aventura en pausa"
	title.position = Vector2(30, 24)
	title.size.x = 400
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("3b2415"))
	panel.add_child(title)
	resume_button = _button(panel, "Seguir jugando →", 88, resume_game)
	_button(panel, "Ver el mapa", 162, _menu)
	shade.hide()

func _button(parent: Node, caption: String, y: float, action: Callable) -> Button:
	var button := Button.new()
	button.position = Vector2(30, y)
	button.size = Vector2(400, 58)
	button.text = caption
	button.theme_type_variation = &"KalinPrimaryButton" if y == 88 else &"KalinSecondaryButton"
	button.pressed.connect(action)
	parent.add_child(button)
	return button

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
		board._stop_drawing()
		return
	if scene.scene_file_path == GameManager.SCENE_PATHS.main_menu or get_tree().paused:
		return
	open_pause()

func open_pause() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	GameManager.checkpoint_current_scene()
	get_tree().paused = true
	shade.show()
	resume_button.grab_focus()

func resume_game() -> void:
	shade.hide()
	get_tree().paused = false
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null

func _menu() -> void:
	resume_game()
	GameManager.go_to_scene("main_menu")

