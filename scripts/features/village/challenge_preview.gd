extends Control
class_name ChallengePreview

var actor: Sprite2D
var art: MeaningIllustration
var motion: VillageUseMotion
var _group: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_stage)


## La petición sólo muestra al interlocutor. La solución visual exige confirmación.
func present(answers: Array[String], guest: String, resolved: bool, animate: bool) -> void:
	clear()
	_group = Node2D.new()
	add_child(_group)
	if not guest.is_empty():
		actor = _friend(guest, Vector2(-75, 0))
	else:
		var kalin: KalinWalker = KalinWalker.new()
		kalin.position = Vector2(-80, 0)
		kalin.scale = Vector2.ONE * 0.8
		_group.add_child(kalin)
	var word: String = answers[0] if not answers.is_empty() else ""
	var world: int = int(VocabularyCatalog.entry(word).get("world", 0))
	if resolved and world == 1:
		_friend(word, Vector2(90, 0))
	elif resolved and CombinationCatalog.allowed(CombinationCatalog.key(word)):
		art = (
			preload("res://scenes/ui/shared/meaning_illustration.tscn").instantiate()
			as MeaningIllustration
		)
		art.position = Vector2(-30, -150)
		art.size = Vector2(180, 150)
		_group.add_child(art)
		art.show_meaning(word, answers[1] if answers.size() == 2 else "")
		if actor != null:
			motion = VillageUseMotion.attach(actor, art, word, guest)
			if animate:
				motion.receive()
	else:
		var book: Sprite2D = Sprite2D.new()
		book.texture = preload("res://Arte/ilustraciones/ui_libro.svg")
		book.scale = Vector2.ONE * 100.0 / book.texture.get_width()
		book.position = Vector2(90, -60)
		_group.add_child(book)
	_layout_stage()


func clear() -> void:
	if is_instance_valid(_group):
		remove_child(_group)
		_group.queue_free()
	_group = null
	actor = null
	art = null
	motion = null


func _friend(word: String, ground: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = VillageUseArt.ACTORS[word]
	var used: Rect2i = sprite.texture.get_image().get_used_rect()
	sprite.scale = Vector2.ONE * 115.0 / used.size.y
	sprite.position = (
		ground - Vector2(0, used.end.y - sprite.texture.get_height() * 0.5) * sprite.scale
	)
	_group.add_child(sprite)
	return sprite


func _layout_stage() -> void:
	if is_instance_valid(_group):
		_group.position = size * Vector2(0.5, 0.90)
		_group.scale = Vector2.ONE * minf(size.x / 380.0, size.y / 230.0)
