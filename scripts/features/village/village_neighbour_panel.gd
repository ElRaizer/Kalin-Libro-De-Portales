extends VillagePanel
class_name VillageNeighbourPanel

signal next_requested
signal activity_requested

var _portrait: TextureRect
var _speaker: Label
var _line: Label
var _next: Button
var _activity: Button


func _panel_bounds() -> Rect2:
	return Rect2(120, 130, 1040, 460)


func _build_content() -> void:
	close_button.text = "Seguir paseando"
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 30)
	body.add_child(row)
	var portrait_card: PanelContainer = PanelContainer.new()
	portrait_card.theme_type_variation = &"KalinFeedbackPanel"
	portrait_card.custom_minimum_size = Vector2(188, 188)
	row.add_child(portrait_card)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.custom_minimum_size = Vector2(158, 158)
	portrait_card.add_child(_portrait)
	var dialogue: VBoxContainer = VBoxContainer.new()
	dialogue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue.alignment = BoxContainer.ALIGNMENT_CENTER
	dialogue.add_theme_constant_override("separation", 20)
	row.add_child(dialogue)
	_speaker = add_label(dialogue, "")
	_speaker.add_theme_font_size_override("font_size", 30)
	_line = add_label(dialogue, "")
	_line.add_theme_font_size_override("font_size", 28)
	_next = add_button(footer, "Continuar", func() -> void: next_requested.emit())
	_activity = add_button(footer, "", func() -> void: activity_requested.emit())


func set_line(title: String, animal: String, line: String, last: bool, action: String = "") -> void:
	heading.text = title
	_speaker.text = animal
	_portrait.texture = VillageUseArt.ACTORS.get(animal)
	_line.text = line
	_next.text = "Terminar conversación" if last else "Continuar"
	_activity.text = action
	_activity.visible = last and not action.is_empty()
	refresh_focus()


func focus_line() -> void:
	_next.grab_focus()
