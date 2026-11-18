extends VBoxContainer
class_name CountingWorkbench

signal changed

var activity: CountingActivity = CountingActivity.new()
var prompt: Label
var explanation: Label
var provision: CountingProvision
var action_controls: HBoxContainer
var _upper: NumeralView
var _lower: NumeralView
var _floor_buttons: Array[Button] = []
var _pieces: Array[Button] = []
var _submit: Button
var _hint: Button


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	prompt = _label(self, "")
	var stage: HBoxContainer = HBoxContainer.new()
	stage.add_theme_constant_override("separation", 30)
	add_child(stage)
	var tablet: VBoxContainer = VBoxContainer.new()
	tablet.custom_minimum_size.x = 280
	stage.add_child(tablet)
	for floor_index: int in [1, 0]:
		_label(tablet, "Arriba · veintenas" if floor_index == 1 else "Abajo · unidades")
		var button: Button = _button(tablet, "", select_floor.bind(floor_index))
		button.custom_minimum_size = Vector2(280, 88)
		button.toggle_mode = true
		_floor_buttons.append(button)
		var numeral: NumeralView = NumeralView.new()
		numeral.dot_texture = preload("res://Arte/numeros/pieza_cacao.svg")
		numeral.bar_texture = preload("res://Arte/numeros/pieza_barra.svg")
		numeral.shell_texture = preload("res://Arte/numeros/pieza_concha.svg")
		numeral.piece_scale = 0.65
		numeral.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(numeral)
		numeral.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if floor_index == 1:
			_upper = numeral
		else:
			_lower = numeral
	provision = CountingProvision.new()
	provision.custom_minimum_size = Vector2(300, 240)
	provision.tray_texture = preload("res://Arte/numeros/tianguis_seed_tray.svg")
	provision.seed_texture = preload("res://Arte/numeros/pieza_cacao.svg")
	stage.add_child(provision)
	var pieces: HBoxContainer = HBoxContainer.new()
	pieces.add_theme_constant_override("separation", 10)
	add_child(pieces)
	for kind: String in ["dot", "bar", "shell", "remove", "clear"]:
		var titles: Dictionary[String, String] = {
			"dot": "Punto · 1",
			"bar": "Barra · 5",
			"shell": "Concha · 0",
			"remove": "Borrar",
			"clear": "Limpiar"
		}
		_pieces.append(_button(pieces, titles[kind], edit.bind(kind)))
	explanation = _label(self, "")
	action_controls = HBoxContainer.new()
	action_controls.add_theme_constant_override("separation", 12)
	add_child(action_controls)
	_hint = _button(action_controls, "Pista", use_help)
	_submit = _button(action_controls, "Comprobar", submit)


func move_actions_to(host: Control) -> void:
	action_controls.reparent(host)
	action_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func focus_input() -> void:
	if activity.finished():
		return
	if activity.session.waiting:
		_submit.grab_focus()
	else:
		_pieces[0].grab_focus()


func _label(parent: Node, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = &"KalinActivityLabel"
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 50
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = &"KalinSecondaryButton"
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func setup(settings: CountingSet, state: Dictionary = {}, targets: Array[int] = []) -> void:
	activity.setup(settings, state, targets)
	refresh()


func refresh() -> void:
	var done: bool = activity.finished()
	prompt.text = (
		"Cantidades preparadas."
		if done
		else (
			"Cantidad %d de %d · Forma %d"
			% [activity.session.round_index + 1, activity.content.round_count, activity.target()]
		)
	)
	_upper.show_value(activity.session.twenties)
	_lower.show_value(activity.session.units, activity.session.shell)
	_floor_buttons[0].set_pressed_no_signal(
		activity.session.active_floor == MayaNumeral.Floor.TWENTIES
	)
	_floor_buttons[1].set_pressed_no_signal(
		activity.session.active_floor == MayaNumeral.Floor.UNITS
	)
	for button: Button in _pieces + _floor_buttons:
		button.disabled = done or activity.session.waiting
	_hint.disabled = done or activity.session.waiting
	_submit.disabled = done
	_submit.text = "Continuar" if activity.session.waiting else "Comprobar"
	explanation.text = "Elige un piso y pon piezas. Cinco puntos forman una barra."
	if not done and activity.supports[activity.session.round_index] > 0:
		var number: int = activity.target()
		explanation.text = (
			"%d veintenas arriba; %d barras y %d puntos abajo%s."
			% [
				MayaNumeral.twenties_of(number),
				MayaNumeral.bars_of(MayaNumeral.units_of(number)),
				MayaNumeral.dots_of(MayaNumeral.units_of(number)),
				", con concha" if MayaNumeral.needs_shell(number) else ""
			]
		)
	if activity.session.waiting:
		explanation.text = "Cantidad confirmada. La bandeja muestra lo que preparaste."
	provision.show_quantity(activity.target() if activity.session.waiting else 0, false)


func select_floor(index: int) -> void:
	if activity.finished() or activity.session.waiting:
		return
	activity.session.select_floor(
		MayaNumeral.Floor.TWENTIES if index == 1 else MayaNumeral.Floor.UNITS
	)
	refresh()
	changed.emit()


func edit(kind: String) -> void:
	if activity.finished() or activity.session.waiting:
		return
	match kind:
		"dot":
			activity.session.add_dot()
		"bar":
			activity.session.add_bar()
		"shell":
			activity.session.add_shell()
		"remove":
			activity.session.remove_piece()
		"clear":
			activity.session.clear_numeral()
	refresh()
	changed.emit()


func use_help() -> void:
	activity.help()
	refresh()
	changed.emit()


func submit() -> void:
	activity.submit()
	refresh()
	changed.emit()
