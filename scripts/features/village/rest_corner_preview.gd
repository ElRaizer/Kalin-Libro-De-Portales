extends Control
class_name RestCornerPreview

var actor: Sprite2D
var companion: Sprite2D
var art: MeaningIllustration
var motion: VillageUseMotion
var _group: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_stage)


func show_choice(
	word: String, garland: Texture2D, receiving: bool, guests: Array[String] = ["Áak", "Miis"]
) -> void:
	clear()
	_group = Node2D.new()
	add_child(_group)
	actor = _friend(guests[0], Vector2(-120, 0))
	if guests.size() > 1:
		companion = _friend(guests[1], Vector2(-240 if not word.is_empty() else 150, 0))
	if word.is_empty():
		var book: Sprite2D = Sprite2D.new()
		book.texture = preload("res://Arte/ilustraciones/ui_libro.svg")
		book.scale = Vector2.ONE * 125.0 / book.texture.get_width()
		book.position = Vector2(0, -65)
		_group.add_child(book)
	else:
		art = (
			preload("res://scenes/ui/shared/meaning_illustration.tscn").instantiate()
			as MeaningIllustration
		)
		art.position = Vector2(-110, -175)
		art.size = Vector2(220, 170)
		_group.add_child(art)
		art.show_meaning(word, "")
		motion = VillageUseMotion.attach(actor, art, word, guests[0])
		if receiving:
			motion.receive()
	if garland != null:
		var reward: Sprite2D = Sprite2D.new()
		reward.texture = garland
		reward.position = Vector2(260, -35)
		reward.scale = Vector2.ONE * 0.7
		_group.add_child(reward)
	_layout_stage()


func clear() -> void:
	if is_instance_valid(_group):
		remove_child(_group)
		_group.queue_free()
	_group = null
	actor = null
	companion = null
	art = null
	motion = null


func _friend(word: String, ground: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = VillageUseArt.ACTORS[word]
	var used: Rect2i = sprite.texture.get_image().get_used_rect()
	sprite.scale = Vector2.ONE * 120.0 / used.size.y
	sprite.position = (
		ground - Vector2(0, used.end.y - sprite.texture.get_height() * 0.5) * sprite.scale
	)
	_group.add_child(sprite)
	return sprite


func _layout_stage() -> void:
	if not is_instance_valid(_group):
		return
	_group.position = size * Vector2(0.55, 0.92)
	_group.scale = Vector2.ONE * minf(1.1, minf(size.x / 760.0, size.y / 250.0))
