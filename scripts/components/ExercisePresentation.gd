extends RefCounted
class_name ExercisePresentation

## Distribución común: petición, frase, tarjetas y una acción en el mismo lugar.
static func setup(host: Node, food: bool) -> MissionProgress:
	var ui := host.get_node("UI")
	if not food:
		(ui.get_node("TopBar/Bar/BackButton") as Button).theme_type_variation = &"KalinSecondaryButton"
		(ui.get_node("TopBar/Bar/BookButton") as Button).theme_type_variation = &"KalinSecondaryButton"
	var request := ui.get_node("RequestPanel") as Control
	request.position = Vector2(24, 86)
	request.size = Vector2(344, 536)
	var content := request.get_node("Content") as Control
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 18
	content.offset_top = 12
	content.offset_right = -18
	content.offset_bottom = -12
	content.get_node("PhaseLabel").hide()
	content.get_node("RequestLabel").hide()
	var animal := content.get_node("AnimalSprite") as Control
	animal.custom_minimum_size.y = 138
	var art := content.get_node("VisualClue" if food else "TargetArt") as Control
	art.custom_minimum_size.y = 218
	var name_label := content.get_node("AnimalLabel" if food else "AnimalName") as Label
	name_label.add_theme_font_size_override("font_size", 24)
	var spell := ui.get_node("SpellPanel") as Control
	spell.position = Vector2(388, 86)
	spell.size = Vector2(868, 156)
	var spell_content := spell.get_node("Content") as Control
	spell_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spell_content.offset_left = 18
	spell_content.offset_top = 18
	spell_content.offset_right = -18
	spell_content.offset_bottom = -12
	spell_content.get_node("Heading").hide()
	if not food:
		var translation := spell_content.get_node("TranslationLabel") as Control
		translation.custom_minimum_size.y = 38
		for slot_name: String in ["NounSlot", "AdjectiveSlot"]:
			(spell_content.get_node("Sentence/" + slot_name) as Control).custom_minimum_size.x = 270
	var choices := ui.get_node("ChoicesPanel") as Control
	choices.position = Vector2(388, 258)
	choices.size = Vector2(868, 284)
	var choice_content := choices.get_node("Content") as Control
	choice_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_content.offset_left = 16
	choice_content.offset_top = 12
	choice_content.offset_right = -16
	choice_content.offset_bottom = -12
	choice_content.set("alignment", BoxContainer.ALIGNMENT_CENTER)
	var first := choice_content.get_node("FoodGrid" if food else "NounGrid") as GridContainer
	var second := choice_content.get_node("ModifierGrid" if food else "AdjectiveGrid") as GridContainer
	for grid: GridContainer in [first, second]:
		grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for button: Button in grid.get_children():
			button.custom_minimum_size = Vector2(150, 94)
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.add_theme_font_size_override("font_size", 19)
	var action := choice_content.get_node("ServeButton" if food else "CastButton") as Button
	action.reparent(ui)
	action.theme = preload("res://themes/kalin_theme.tres")
	action.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	action.position = Vector2(1024, 646)
	action.custom_minimum_size = Vector2(232, 58)
	action.size = Vector2(232, 58)
	action.add_theme_font_size_override("font_size", 24)
	var feedback := ui.get_node("FeedbackPanel") as Control
	feedback.position = Vector2(388, 558)
	feedback.size = Vector2(868, 64)
	ui.get_node("StatusPanel").hide()
	var progress := MissionProgress.new()
	progress.name = "MissionProgress"
	progress.position = Vector2(28, 647)
	progress.size = Vector2(970, 58)
	ui.add_child(progress)
	return progress

static func focus_step(first: Control, second: Control, first_done: bool, second_needed: bool = true) -> void:
	first.modulate = Color(0.84, 0.84, 0.84) if first_done else Color.WHITE
	second.modulate = Color.WHITE if first_done else Color(0.82, 0.82, 0.82)
	second.visible = second_needed

