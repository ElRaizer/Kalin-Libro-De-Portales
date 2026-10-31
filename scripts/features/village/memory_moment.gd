extends Panel
class_name MemoryMoment

@onready var actor: Sprite2D = $Stage/Actor
@onready var art: MeaningIllustration = $Stage/Object


func show_memory(value: Dictionary) -> void:
	var memory: Dictionary = VillageMemory.normalize(value)
	visible = not memory.is_empty()
	if memory.is_empty():
		return
	$Title.text = memory.title
	$Caption.text = "Con " + memory.animal
	actor.texture = GameManager.get_visual_expression(memory.animal, "reaccion_feliz")
	art.visible = not memory.item.is_empty()
	if art.visible:
		art.show_meaning(memory.item, memory.quality)
		VillageUseMotion.attach(actor, art, memory.item, memory.animal)
	else:
		actor.position = Vector2(0, -65)
		actor.scale = Vector2.ONE
