extends Resource
class_name IntroPanelData

@export_file("*.svg", "*.png", "*.webp") var background_path := ""
@export_file("*.svg", "*.png", "*.webp") var kalin_path := ""
@export var kalin_x := 800.0
@export_multiline var text := ""
@export_multiline var subtext := ""

static func from_dictionary(data: Dictionary) -> IntroPanelData:
	var panel := IntroPanelData.new()
	panel.background_path = str(data.get("bg", ""))
	panel.kalin_path = str(data.get("kalin", ""))
	panel.kalin_x = float(data.get("kalin_x", 800.0))
	panel.text = str(data.get("text", ""))
	panel.subtext = str(data.get("subtext", ""))
	return panel

static func from_dictionaries(values: Array) -> Array[IntroPanelData]:
	var panels: Array[IntroPanelData] = []
	for value: Dictionary in values:
		panels.append(from_dictionary(value))
	return panels
