extends Control
class_name MeaningIllustration

## Una misma ilustración en peticiones, resultados y pistas de tamaño.
var picture: TextureRect
var reference: TextureRect
var quality_badge: TextureRect
var word: String = ""
var quality: String = ""
var celebration: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_art)
	_build()
	_layout_art()

func _build() -> void:
	if is_instance_valid(picture):
		return
	picture = _texture_rect()
	reference = _texture_rect()
	reference.modulate.a = 0.26
	quality_badge = _texture_rect()

func _texture_rect() -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func show_meaning(maya_word: String, modifier: String = "") -> void:
	_build()
	word = maya_word
	quality = modifier
	var manager: Node = get_node("/root/GameManager")
	var path: String = manager.get_book_illustration(word)
	picture.texture = load(path) if not path.is_empty() else null
	reference.texture = picture.texture
	quality_badge.texture = null
	if quality in ["Jats'uts", "ki'", "jach'"]:
		quality_badge.texture = load(manager.get_book_illustration(quality))
	_layout_art()

func _layout_art() -> void:
	if not is_instance_valid(picture):
		return
	var comparison := quality in ["mejen", "nojoch"]
	reference.visible = comparison
	quality_badge.visible = quality_badge.texture != null
	if comparison:
		# Referencia idéntica y fija: cambia el tamaño del objeto, no su símbolo.
		var factor := 0.3 if quality == "mejen" else 0.95
		picture.size = size * Vector2(0.66, factor)
		picture.position = Vector2(size.x * 0.34, size.y - picture.size.y)
		reference.size = size * Vector2(0.36, 0.65)
		reference.position = Vector2(0, size.y - reference.size.y)
	else:
		picture.position = Vector2.ZERO
		picture.size = size
	if quality_badge.visible:
		picture.size.x = size.x * 0.53
		quality_badge.size = Vector2(size.x * 0.54, size.y)
		quality_badge.position = Vector2(size.x * 0.46, 0)

func celebrate() -> void:
	if celebration and celebration.is_valid():
		celebration.kill()
	pivot_offset = size * 0.5
	scale = Vector2(0.75, 0.75)
	celebration = create_tween()
	celebration.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
