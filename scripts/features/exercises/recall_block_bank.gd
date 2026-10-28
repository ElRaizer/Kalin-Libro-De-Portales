extends HFlowContainer

var panel: RecallPanel


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return is_instance_valid(panel) and panel.accepts_fragment(data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	SoundCue.play(self, "palabra_regresar")
	panel.return_fragment(int(data.index))
