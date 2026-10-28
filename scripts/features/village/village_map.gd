extends CanvasLayer
class_name VillageMap

signal travel_requested(district: String)

var _origin: WeakRef
var _panel: PanelContainer
var _heading: Label
var _places: Array[Button] = []
var _was_paused: bool = false
const AREAS: Array[String] = ["patio", "workshop", "shore"]
const NAMES: Array[String] = ["El patio", "El taller", "La orilla"]
const DETAILS: Array[String] = [
	"Tu jardín\nSala de retos", "Mesa de trazos\nTus vecinos", "El estanque\nEl portal"
]
const WORLDS: Array[int] = [1, 3, 4]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.04, 0.13, 0.13, 0.8)
	shade.theme = preload("res://themes/kalin_theme.tres")
	add_child(shade)
	_panel = PanelContainer.new()
	_panel.position = Vector2(100, 145)
	_panel.size = Vector2(1080, 420)
	_panel.theme_type_variation = &"KalinCreamPanel"
	shade.add_child(_panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_panel.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	margin.add_child(content)
	_heading = Label.new()
	_heading.add_theme_color_override("font_color", Color("164b48"))
	_heading.add_theme_font_size_override("font_size", 30)
	content.add_child(_heading)
	var choices: HBoxContainer = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 16)
	content.add_child(choices)
	for index: int in range(AREAS.size()):
		var place: Button = Button.new()
		place.custom_minimum_size = Vector2(300, 225)
		place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		place.theme_type_variation = &"KalinSecondaryButton"
		place.add_theme_font_size_override("font_size", 24)
		place.pressed.connect(_travel.bind(AREAS[index]))
		choices.add_child(place)
		_places.append(place)
	var close: Button = Button.new()
	close.text = "Seguir caminando"
	close.custom_minimum_size.y = 56
	close.theme_type_variation = &"KalinSecondaryButton"
	close.pressed.connect(close_map)
	content.add_child(close)
	hide()


func open_map(current: String, world: int, origin: Control) -> void:
	if visible or get_tree().paused:
		return
	_origin = weakref(origin)
	_was_paused = get_tree().paused
	_heading.text = "Explora la aldea · estás en " + NAMES[AREAS.find(current)]
	for index: int in range(AREAS.size()):
		var unlocked: bool = world >= WORLDS[index]
		_places[index].disabled = not unlocked or current == AREAS[index]
		_places[index].text = (
			NAMES[index]
			+ "\n\n"
			+ DETAILS[index]
			+ "\n\n"
			+ (
				"Estás aquí"
				if current == AREAS[index]
				else (
					"Ir a este barrio →" if unlocked else "Se abre en el mundo %d" % WORLDS[index]
				)
			)
		)
	get_tree().paused = true
	show()
	(_panel.find_children("*", "Button", true, false).back() as Button).grab_focus()


func _travel(area: String) -> void:
	close_map()
	travel_requested.emit(area)


func close_map() -> void:
	hide()
	get_tree().paused = _was_paused
	var origin: Control = _origin.get_ref() as Control if _origin != null else null
	if is_instance_valid(origin) and origin.is_visible_in_tree():
		origin.grab_focus()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_map()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible:
		get_tree().paused = _was_paused
