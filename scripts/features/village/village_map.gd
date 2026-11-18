extends CanvasLayer
class_name VillageMap

signal travel_requested(district: String)
signal opportunity_requested

var controls: Control
var _origin: WeakRef
var _panel: PanelContainer
var _heading: Label
var _opportunity: Button
var _close: Button
var _places: Array[Button] = []
var _was_paused: bool = false
const AREAS: Array[String] = VillageNeighbours.DISTRICTS
const NAMES: Array[String] = VillageNeighbours.NAMES
const DETAILS: Array[String] = [
	"Tu jardín\nSala de retos", "Mesa de trazos\nTus vecinos", "El estanque\nEl portal"
]
const WORLDS: Array[int] = [1, 3, 4]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 12
	var shade: ColorRect = ColorRect.new()
	shade.name = "MapControls"
	controls = shade
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.04, 0.13, 0.13, 0.8)
	shade.theme = preload("res://themes/kalin_theme.tres")
	add_child(shade)
	_panel = PanelContainer.new()
	_panel.position = Vector2(100, 98)
	_panel.size = Vector2(1080, 524)
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
	_opportunity = Button.new()
	_opportunity.custom_minimum_size.y = 56
	_opportunity.theme_type_variation = &"KalinSecondaryButton"
	_opportunity.add_theme_font_size_override("font_size", 24)
	_opportunity.pressed.connect(_follow_opportunity)
	content.add_child(_opportunity)
	_close = Button.new()
	_close.text = "Seguir caminando"
	_close.custom_minimum_size.y = 56
	_close.theme_type_variation = &"KalinSecondaryButton"
	_close.add_theme_font_size_override("font_size", 24)
	_close.pressed.connect(close_map)
	content.add_child(_close)
	hide()


func open_map(current: String, world: int, origin: Control, suggestion: Dictionary = {}) -> void:
	if visible or get_tree().paused:
		return
	_origin = weakref(origin)
	_was_paused = get_tree().paused
	_heading.text = "Mapa de la aldea · estás en " + NAMES[AREAS.find(current)].to_lower()
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
		if AREAS[index] == "shore" and GameManager.session.village_expansion.complete:
			_places[index].text += "\nEl claro compartido"
	_opportunity.visible = not suggestion.is_empty()
	if _opportunity.visible:
		var area_name: String = NAMES[AREAS.find(suggestion.area)]
		_opportunity.text = "Ir a «%s» · %s" % [suggestion.title, area_name]
	get_tree().paused = true
	show()
	_close.grab_focus()


func _follow_opportunity() -> void:
	close_map()
	opportunity_requested.emit()


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
