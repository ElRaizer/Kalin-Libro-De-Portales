extends VillagePanel
class_name PracticeHub

signal family_requested(family: String)
var available: Array[String] = []
var _buttons: Dictionary[String, Button] = {}


func _build_content() -> void:
	heading.text = "Sala de prácticas · Tú eliges"
	close_button.text = "Volver a la aldea"
	add_label(
		body,
		"Puedes practicar una sola actividad o alternarlas. Cada una guarda su borrador y sus apoyos. Puedes salir cuando quieras."
	)
	var labels: Dictionary[String, String] = {
		"words": "Palabras · encuentros y peticiones",
		"numbers": "Cantidades · preparar semillas",
		"paths": "Caminos · ayudar a venir",
		"mixed": "Mixto · alternar actividades"
	}
	for family: String in labels:
		_buttons[family] = add_button(body, labels[family], choose.bind(family))


func open_hub(origin: Control, families: Array[String], next_family: String) -> void:
	available = families.duplicate()
	for family: String in _buttons:
		_buttons[family].disabled = (
			available.is_empty() if family == "mixed" else family not in available
		)
	var family: String = {"words": "palabras", "numbers": "cantidades", "paths": "caminos"}[next_family]
	notice.text = "En mixto toca practicar %s." % family
	if "numbers" not in available:
		notice.text += " Cantidades se abre tras Las piedras que cuentan."
	open_panel(origin)


func choose(family: String) -> void:
	if not visible or (family != "mixed" and family not in available):
		return
	close_panel()
	family_requested.emit(family)
