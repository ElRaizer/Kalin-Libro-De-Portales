extends CanvasLayer

@onready var shade: ColorRect = $Shade
@onready var resume_button: Button = $Shade/Panel/ResumeButton
var _previous_focus: Control


func _ready() -> void:
	resume_button.pressed.connect(resume_game)
	$Shade/Panel/MenuButton.pressed.connect(_menu)
	for entry: Array in [
		["ReducedMotion", "reduced_motion"],
		["ReducedFlashes", "reduced_flashes"],
		["InstantText", "instant_text"]
	]:
		var button: CheckButton = $Shade/Panel.get_node(entry[0]) as CheckButton
		button.toggled.connect(_preference_toggled.bind(entry[1]))


func _preference_toggled(enabled: bool, key: String) -> void:
	AccessibilityManager.set_preference(key, enabled)


func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var book: Node = scene.get_node_or_null("LibroHechizos")
	if (
		scene.scene_file_path == GameContent.SCENE_PATHS.main_menu
		and not shade.visible
		and (book == null or not book.visible)
	):
		return
	get_viewport().set_input_as_handled()
	if shade.visible:
		resume_game()
		return
	if book and book.visible:
		book.hide_book()
		return
	if scene.has_method("close_transient_ui") and scene.close_transient_ui():
		return
	var board: Node = scene.get_node_or_null("GridBoard")
	if board and board.drawing:
		board.cancel_drawing()
		return
	if scene.scene_file_path == GameContent.SCENE_PATHS.main_menu or get_tree().paused:
		return
	open_pause()


func open_pause() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	GameManager.checkpoint_current_scene()
	get_tree().paused = true
	shade.show()
	var in_menu: bool = (
		get_tree().current_scene.scene_file_path == GameContent.SCENE_PATHS.main_menu
	)
	$Shade/Panel/Title.text = "A tu ritmo" if in_menu else "Aventura en pausa"
	$Shade/Panel/MenuButton.visible = not in_menu
	resume_button.text = "Volver al mapa" if in_menu else "Seguir jugando →"
	$Shade/Panel/ReducedMotion.set_pressed_no_signal(AccessibilityManager.reduced_motion)
	$Shade/Panel/ReducedFlashes.set_pressed_no_signal(AccessibilityManager.reduced_flashes)
	$Shade/Panel/InstantText.set_pressed_no_signal(AccessibilityManager.instant_text)
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
