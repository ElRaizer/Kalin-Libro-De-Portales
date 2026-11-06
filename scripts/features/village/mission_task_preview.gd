extends Control
class_name MissionTaskPreview

const ART: PackedScene = preload("res://scenes/ui/shared/meaning_illustration.tscn")
const CATALOG: VisualCatalog = preload("res://data/visual_catalog.tres")
var _group: Node2D


func show_task(task: VillageTask) -> void:
	_clear()
	$Unknown.visible = task == null
	$Stage.visible = task != null
	show()
	if task == null:
		return
	_group = Node2D.new()
	_group.position = size * Vector2(0.5, 0.88)
	_group.scale = Vector2.ONE * minf(size.x / 340.0, size.y / 200.0)
	add_child(_group)
	var actor: Sprite2D = Sprite2D.new()
	actor.name = "Actor"
	actor.texture = VillageUseArt.ACTORS.get(task.requester, CATALOG.texture_for(task.requester))
	actor.position = Vector2(0, -60)
	actor.scale = Vector2.ONE * 130.0 / maxf(1, actor.texture.get_image().get_used_rect().size.y)
	_group.add_child(actor)
	var art: MeaningIllustration = ART.instantiate() as MeaningIllustration
	art.name = "Object"
	art.position = Vector2(-90, -130)
	art.size = Vector2(180, 130)
	_group.add_child(art)
	art.show_meaning(task.item, task.quality)
	VillageUseMotion.attach(actor, art, task.item, task.requester)


func _clear() -> void:
	if is_instance_valid(_group):
		remove_child(_group)
		_group.queue_free()
	_group = null
