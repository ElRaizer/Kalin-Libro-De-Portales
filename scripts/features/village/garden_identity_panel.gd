extends VillagePanel
class_name GardenIdentityPanel

var profile: GardenProfile
var district: String = "patio"
var name_field: LineEdit
var _decorations: Dictionary[String, CheckButton] = {}
var _save: Button


func _build_content() -> void:
	heading.text = "El nombre de mi rincón"
	add_label(
		body, "Elige un nombre y los detalles que te gustaría ver al volver. No cuesta puntos."
	)
	name_field = LineEdit.new()
	name_field.max_length = GardenIdentity.MAX_NAME_LENGTH
	name_field.placeholder_text = "Mi rincón"
	name_field.custom_minimum_size.y = 56
	name_field.add_theme_font_size_override("font_size", 26)
	body.add_child(name_field)
	add_label(body, "Los adornos de bienvenida se obtienen al terminar Un lugar para descansar.")
	for id: String in GardenIdentity.DECORATIONS:
		var choice: CheckButton = CheckButton.new()
		choice.text = str(profile.decoration_titles[id])
		choice.custom_minimum_size.y = 56
		choice.add_theme_font_size_override("font_size", 24)
		body.add_child(choice)
		_decorations[id] = choice
	_save = add_button(footer, "Guardar mi rincón", save_identity)


func open_identity(area: String, origin: Control) -> void:
	if visible or get_tree().paused:
		return
	district = area
	var session: GameSession = GameManager.session
	var entry: Dictionary = GardenIdentity.entry_for(
		session.garden_identity, area, session.rest_corner.complete
	)
	name_field.text = entry.name
	for id: String in _decorations:
		_decorations[id].disabled = not session.rest_corner.complete
		_decorations[id].set_pressed_no_signal(id in entry.decorations)
	notice.text = "Guardar confirma tus elecciones. Volver o Esc descarta el borrador."
	if open_panel(origin):
		name_field.grab_focus()


func save_identity() -> void:
	var decorations: Array[String] = []
	for id: String in _decorations:
		if _decorations[id].button_pressed:
			decorations.append(id)
	if GameManager.set_garden_identity(district, name_field.text.strip_edges(), decorations):
		notice.text = "Tu rincón quedó guardado. Puedes cambiarlo cuando quieras."
		changed.emit()
	else:
		notice.text = "No se pudo guardar. Conservamos el nombre y los adornos anteriores; puedes reintentar."
