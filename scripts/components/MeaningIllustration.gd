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
		var contexts := {"Jats'uts": "fx_decoracion", "ki'": "fx_aroma", "jach'": "prop_peso"}
		quality_badge.texture = load("res://Arte/ilustraciones/%s.svg" % contexts[quality])
	_layout_art()

func _layout_art() -> void:
	if not is_instance_valid(picture):
		return
	var comparison := quality in ["mejen", "nojoch"]
	reference.visible = comparison
	quality_badge.visible = quality_badge.texture != null
	if comparison:
		# Los dos objetos conservan proporción y se apoyan en la misma base.
		var ratio := 4.0 / 3.0
		if picture.texture:
			ratio = float(picture.texture.get_width()) / picture.texture.get_height()
		var width := size.x * 0.64 * (0.55 if quality == "mejen" else 1.0)
		picture.size = Vector2(width, width / ratio)
		if picture.size.y > size.y:
			picture.size *= size.y / picture.size.y
		picture.position = Vector2(size.x * 0.36, size.y - picture.size.y)
		reference.size = Vector2(size.x * 0.32, size.x * 0.32 / ratio)
		reference.position = Vector2(0, size.y - reference.size.y)
	else:
		picture.position = Vector2.ZERO
		picture.size = size
	if quality_badge.visible:
		picture.size = size * Vector2(0.94, 0.85)
		picture.position = Vector2(0, size.y * 0.15)
		quality_badge.size = size * Vector2(0.44, 0.44)
		quality_badge.position = size * Vector2(0.48, 0.02)
		if quality == "jach'":
			quality_badge.position = size * Vector2(0.26, 0.24)

func celebrate() -> void:
	if celebration and celebration.is_valid():
		celebration.kill()
	pivot_offset = size * 0.5
	scale = Vector2(0.75, 0.75)
	celebration = create_tween()
	celebration.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
