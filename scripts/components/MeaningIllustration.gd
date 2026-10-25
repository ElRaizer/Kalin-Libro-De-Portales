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
@export var world_object := false

## Una misma ilustración en peticiones, resultados y pistas de tamaño.
@onready var picture: TextureRect = $Picture
@onready var reference: TextureRect = $Reference
@onready var quality_badge: TextureRect = $QualityBadge
@onready var world_front: TextureRect = $WorldFront
@onready var world_mat: TextureRect = $WorldMat
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
	var contexts := {"Jats'uts": "fx_decoracion", "ki'": "fx_aroma", "chich": "prop_peso"}
	if quality in contexts:
		quality_badge.texture = catalog.texture_for(contexts[quality])
	_layout_art()

func _layout_art() -> void:
	if not is_instance_valid(picture):
		return
	var comparison := quality in ["mejen", "nojoch"]
	world_front.hide()
	world_mat.hide()
	if world_object:
		reference.hide()
		quality_badge.hide()
		var factor := 0.76 if quality == "mejen" else (1.2 if quality == "nojoch" else 1.0)
		var widths := {"k'áan": 1.42, "k'áanche'": 1.0, "mayak": 1.15, "lak": 0.72, "janal": 0.78, "ja'": 0.5, "ja'as": 0.65, "ich": 0.65, "K'úum": 0.78}
		var texture := VillageUseArt.object_texture(word, quality)
		if texture:
			picture.texture = texture
		if picture.texture == null:
			return
		var width: float = size.x * float(widths.get(word, 1.0)) * factor
		var extent := Vector2(width, width * picture.texture.get_height() / picture.texture.get_width())
		picture.size = extent
		var floor_points := {"k'áan": 150.0 / 180, "lak": 140.0 / 180, "janal": 155.0 / 180, "ja'": 151.0 / 180}
		picture.position = Vector2((size.x - extent.x) * 0.5, size.y - 5 - extent.y * float(floor_points.get(word, 160.0 / 180)))
		if word == "k'áan":
			world_front.texture = VillageUseArt.HAMMOCK_FRONTS.get(quality, VillageUseArt.HAMMOCK_FRONT)
			world_front.position = picture.position
			world_front.size = extent
			world_front.show()
		if word in ["lak", "janal", "ja'", "ja'as", "ich", "K'úum"]:
			world_mat.texture = VillageUseArt.MAT
			world_mat.size = Vector2(maxf(width * 0.9, 96), 30)
			world_mat.position = Vector2((size.x - world_mat.size.x) * 0.5, size.y - 20)
			world_mat.show()
		if quality == "ki'":
			quality_badge.visible = true
			quality_badge.size = Vector2(width * 0.55, width * 0.42)
			quality_badge.position = picture.position + Vector2(width * 0.23, -width * 0.1)
		elif quality == "Jats'uts" and word in ["ja'as", "ich", "K'úum"]:
			quality_badge.show()
			quality_badge.size = Vector2(width * 0.42, width * 0.32)
			quality_badge.position = picture.position + Vector2(width * 0.63, -width * 0.04)
		return
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
		if quality == "chich":
			quality_badge.position = size * Vector2(0.26, 0.24)

func picture_rect() -> Rect2:
	if picture.texture == null:
		return Rect2(picture.position, picture.size)
	var texture_size := picture.texture.get_size()
	var fitted := texture_size * minf(picture.size.x / texture_size.x, picture.size.y / texture_size.y)
	return Rect2(picture.position + (picture.size - fitted) * 0.5, fitted)

func celebrate() -> void:
	if celebration and celebration.is_valid():
		celebration.kill()
	if world_object:
		scale = _base_scale
		self_modulate = Color.WHITE
		if not get_node("/root/AccessibilityManager").reduced_motion:
			celebration = create_tween()
			celebration.tween_property(self, "self_modulate", Color(1.2, 1.14, 1.0), 0.15)
			celebration.tween_property(self, "self_modulate", Color.WHITE, 0.25)
		return
	if get_node("/root/AccessibilityManager").reduced_motion:
		scale = _base_scale
		return
	pivot_offset = size * 0.5
	scale = _base_scale * 0.75
	celebration = create_tween()
	celebration.tween_property(self, "scale", _base_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
