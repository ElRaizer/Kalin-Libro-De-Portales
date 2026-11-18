extends Node2D
class_name ExpansionGathering

var actors: Array[Sprite2D] = []
var motions: Array[VillageUseMotion] = []


func present(
	purpose: String,
	guests: Array[String],
	anchors: Array[Vector2],
	food: String,
	profile: ExpansionProfile,
	animate: bool,
	stage_scale: float = 1.0
) -> void:
	var word: String = profile.rest_word if purpose == "rest" else food.get_slice("|", 0)
	present_use(word, guests, anchors, animate, stage_scale)


func present_use(
	word: String, guests: Array[String], anchors: Array[Vector2], animate: bool, stage_scale: float
) -> void:
	clear()
	for index: int in range(guests.size()):
		var guest: String = guests[index]
		var stage: Node2D = Node2D.new()
		stage.position = anchors[index]
		stage.scale = Vector2.ONE * stage_scale
		stage.z_index = int(anchors[index].y)
		add_child(stage)
		var actor: Sprite2D = Sprite2D.new()
		actor.texture = VillageUseArt.ACTORS[guest]
		var bounds: Rect2i = actor.texture.get_image().get_used_rect()
		actor.scale = Vector2.ONE * 110.0 / bounds.size.y
		actor.position = -Vector2(0, bounds.end.y - actor.texture.get_height() * 0.5) * actor.scale
		stage.add_child(actor)
		var art: MeaningIllustration = (
			preload("res://scenes/ui/shared/meaning_illustration.tscn").instantiate()
			as MeaningIllustration
		)
		art.position = Vector2(-70, -155)
		art.size = Vector2(180, 150)
		stage.add_child(art)
		art.show_meaning(word, "")
		var motion: VillageUseMotion = VillageUseMotion.attach(actor, art, word, guest)
		if animate:
			motion.receive()
		actors.append(actor)
		motions.append(motion)


func replay() -> void:
	for motion: VillageUseMotion in motions:
		motion.receive()


func clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	actors.clear()
	motions.clear()
