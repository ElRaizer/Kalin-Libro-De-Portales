@tool
extends Control
class_name MeaningIllustration

@export var catalog: VisualCatalog:
	set(value):
		catalog = value
		_refresh_editor_preview()
@export var initial_word: String = "":
	set(value):
		initial_word = value
		_refresh_editor_preview()
@export var initial_quality: String = "":
	set(value):
		initial_quality = value
		_refresh_editor_preview()

## Una misma ilustración en peticiones, resultados y pistas de tamaño.
@onready var picture: TextureRect = $Picture
@onready var reference: TextureRect = $Reference
@onready var quality_badge: TextureRect = $QualityBadge
var word: String = ""
var quality: String = ""
var celebration: Tween
var _base_scale: Vector2

func _ready() -> void:
	_base_scale = scale
	resized.connect(_layout_art)
	if not initial_word.is_empty():
		show_meaning(initial_word, initial_quality)
	_layout_art()

func _refresh_editor_preview() -> void:
	if Engine.is_editor_hint() and is_node_ready():
		update_configuration_warnings()
		if catalog != null:
			show_meaning(initial_word, initial_quality)

func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(["Asigna el catálogo de ilustraciones."]) if catalog == null else PackedStringArray()


func show_meaning(maya_word: String, modifier: String = "") -> void:
	word = maya_word
	quality = modifier
	picture.texture = catalog.texture_for(word)
	reference.texture = picture.texture
	quality_badge.texture = null
	var contexts := {"Jats'uts": "fx_decoracion", "ki'": "fx_aroma", "jach'": "prop_peso"}
	if quality in contexts:
		quality_badge.texture = catalog.texture_for(contexts[quality])
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
	scale = _base_scale * 0.75
	celebration = create_tween()
	celebration.tween_property(self, "scale", _base_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
