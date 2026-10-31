extends Node2D
class_name VillageHabitat

## Agua visible también antes de entregar un encargo. Una actuación puede ocupar su lugar.
var actor: Sprite2D
var authored_scale: Vector2 = Vector2.ONE
var authored_position: Vector2 = Vector2.ZERO


func configure(target: Sprite2D) -> void:
	actor = target
	authored_scale = target.scale
	authored_position = target.position
	actor.set_meta("village_habitat", weakref(self))
	actor.scale = authored_scale * 0.72
	actor.z_index = z_index + 1
	for front: bool in [false, true]:
		var water: Sprite2D = Sprite2D.new()
		water.texture = (
			preload("res://Arte/aldea/uso/pond_front.svg") if front else VillageUseArt.POND
		)
		water.position = Vector2(0, -60)
		water.scale = Vector2(0.9, 0.8)
		water.z_index = 2 if front else 0
		add_child(water)


func set_using_result(using_result: bool) -> void:
	visible = not using_result
	if not using_result and is_instance_valid(actor):
		actor.self_modulate.a = 1
		actor.scale = authored_scale * 0.72
		actor.position = authored_position
		actor.z_index = z_index + 1
