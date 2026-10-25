extends Button

var panel: RecallPanel
var fragment_index: int = -1
var field_index: int = -1
var slot_index: int = -1


func _get_drag_data(_at: Vector2) -> Variant:
	if disabled or fragment_index < 0 or not is_instance_valid(panel):
		return null
	if field_index < 0 and fragment_index in panel._used:
		return null
	set_drag_preview(create_drag_preview())
	return {"kind": "recall_fragment", "panel": panel, "index": fragment_index}


func create_drag_preview() -> Control:
	# Godot coloca la raíz de la vista previa en el cursor. El desplazamiento
	# pertenece al hijo para que el centro se mantenga bajo el dedo o el ratón.
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var preview: Button = Button.new()
	preview.text = text
	preview.theme = theme
	preview.theme_type_variation = &"KalinNounButton"
	preview.add_theme_font_size_override("font_size", 26)
	var extent: Vector2 = size.max(get_combined_minimum_size())
	preview.custom_minimum_size = extent
	preview.size = extent
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(preview)
	preview.position = -extent * 0.5
	return holder


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return is_instance_valid(panel) and panel.accepts_fragment(data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	if field_index >= 0:
		panel.move_fragment(int(data.index), field_index, slot_index)
	else:
		panel.return_fragment(int(data.index))
