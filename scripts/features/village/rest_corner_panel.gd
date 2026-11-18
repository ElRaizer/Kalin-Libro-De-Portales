extends CanvasLayer
class_name RestCornerPanel

signal changed
signal completed
signal designs_requested
signal moment_requested

var profile: RestCornerProfile
var controls: Control
var preview: RestCornerPreview
var _title: Label
var _message: Label
var _notice: Label
var _choices: HBoxContainer
var _option_buttons: Array[Button] = []
var _primary: Button
var _skip_intro: Button
var _designs: Button
var _photo: Button
var _close: Button
var _origin: WeakRef
var _was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	var shade: ColorRect = ColorRect.new()
	controls = shade
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.04, 0.13, 0.13, 0.87)
	shade.theme = preload("res://themes/kalin_theme.tres")
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(70, 32)
	panel.size = Vector2(1140, 650)
	panel.theme_type_variation = &"KalinCreamPanel"
	shade.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	_title = _label(content, 30)
	_message = _label(content, 26)
	_message.custom_minimum_size = Vector2(1080, 96)
	_choices = HBoxContainer.new()
	_choices.add_theme_constant_override("separation", 12)
	content.add_child(_choices)
	var group: ButtonGroup = ButtonGroup.new()
	for option: RestCornerOption in profile.options:
		var button: Button = _button(
			_choices, str(VocabularyCatalog.entry(option.word).spanish), _choose.bind(option.word)
		)
		button.icon = GameManager.get_visual_texture(option.word)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 46)
		button.toggle_mode = true
		button.button_group = group
		_option_buttons.append(button)
	preview = RestCornerPreview.new()
	preview.custom_minimum_size = Vector2(1000, 210)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview)
	_notice = _label(content, 22)
	_notice.custom_minimum_size.y = 42
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	_primary = _button(actions, "Continuar", _advance)
	_primary.custom_minimum_size.x = 300
	_skip_intro = _button(actions, "Ir a las opciones", _show_choices)
	_skip_intro.custom_minimum_size.x = 210
	_designs = _button(actions, "Diseños y jardín", _open_designs)
	_photo = _button(actions, "Componer foto", func() -> void: moment_requested.emit())
	for button: Button in [_designs, _photo]:
		button.custom_minimum_size.x = 210
	_close = _button(actions, "Salir y guardar", close_panel)
	_close.custom_minimum_size.x = 245
	hide()


func _label(parent: Control, font_size: int) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("164b48"))
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 56)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = &"KalinSecondaryButton"
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func open_project(origin: Control) -> void:
	if visible or get_tree().paused or not GameManager.session.has_finished_adventure():
		return
	_origin = weakref(origin)
	_was_paused = get_tree().paused
	get_tree().paused = true
	show()
	_refresh(false)
	if _primary.visible and not _primary.disabled:
		_primary.grab_focus()
	else:
		_focus_choice()


func _focus_choice() -> void:
	for button: Button in _option_buttons:
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return
	_close.grab_focus()


func _refresh(receiving: bool) -> void:
	var session: GameSession = GameManager.session
	var state: Dictionary = session.rest_corner
	var intro: bool = int(state.intro) < RestCornerState.INTRO_STEPS
	_title.text = "Tus amigos te invitan" if intro else profile.title
	_choices.visible = not intro and not state.complete
	_notice.visible = not intro
	_designs.visible = not intro
	_photo.visible = state.complete
	_skip_intro.visible = intro
	_primary.show()
	_primary.disabled = false
	_primary.text = "Continuar"
	var option: RestCornerOption = profile.option_for(state.choice)
	for index: int in range(_option_buttons.size()):
		var word: String = profile.options[index].word
		_option_buttons[index].disabled = word not in session.words_learned
		_option_buttons[index].set_pressed_no_signal(word == state.choice)
	if intro:
		_message.text = profile.intro_lines()[int(state.intro)]
	elif state.complete:
		if int(state.result) < RestCornerState.RESULT_STEPS:
			_message.text = option.aak_reaction if int(state.result) == 0 else option.miis_reaction
		else:
			_message.text = option.return_line
			_primary.text = "Volver a disfrutar"
		_notice.text = profile.reward_line
	else:
		_message.text = (
			"Elige cómo te gustaría hacer una pausa con tus amigos. Puedes probar las tres opciones."
			if option == null
			else option.title + ". " + option.description
		)
		_notice.text = "Prueba gratuita. Los muebles propios se construyen con tus diseños."
		_primary.text = "Este será nuestro rincón"
		_primary.disabled = option == null
	preview.show_choice(state.choice, profile.garland if state.complete else null, receiving)


func _choose(word: String) -> void:
	if GameManager.session.choose_rest_corner(word):
		_refresh(true)
		changed.emit()


func _advance() -> void:
	var session: GameSession = GameManager.session
	if int(session.rest_corner.intro) < RestCornerState.INTRO_STEPS:
		session.advance_rest_intro()
	elif not session.rest_corner.complete:
		if not session.confirm_rest_corner():
			return
		completed.emit()
	elif int(session.rest_corner.result) < RestCornerState.RESULT_STEPS:
		session.advance_rest_result()
	else:
		_refresh(true)
		return
	_refresh(false)
	if _primary.disabled:
		_focus_choice()
	changed.emit()


func _show_choices() -> void:
	if GameManager.session.finish_rest_intro():
		_refresh(false)
		_focus_choice()
		changed.emit()


func _open_designs() -> void:
	close_panel()
	designs_requested.emit()


func close_panel() -> void:
	if not visible:
		return
	hide()
	preview.clear()
	get_tree().paused = _was_paused
	changed.emit()
	var origin: Control = _origin.get_ref() as Control if _origin != null else null
	if is_instance_valid(origin) and origin.is_visible_in_tree():
		origin.grab_focus()
	_origin = null


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible:
		get_tree().paused = _was_paused
