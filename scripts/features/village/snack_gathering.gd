extends Control
class_name SnackGathering

var actors: Array[Sprite2D] = []
var arts: Array[MeaningIllustration] = []
var motions: Array[VillageUseMotion] = []
var _group: Node2D
var _profile: SnackProfile


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)


func present(state: Dictionary, profile: SnackProfile, animate: bool) -> void:
	clear()
	_profile = profile
	_group = Node2D.new()
	add_child(_group)
	var ground: Panel = Panel.new()
	ground.position = Vector2(0, 210)
	ground.size = Vector2(1000, 70)
	var surface: StyleBoxFlat = StyleBoxFlat.new()
	surface.bg_color = Color("c2cc98") if state.decoration == "leaves" else Color("d4c5a0")
	surface.set_corner_radius_all(26)
	ground.add_theme_stylebox_override("panel", surface)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.add_child(ground)
	if state.decoration == "flowers":
		var border: Sprite2D = Sprite2D.new()
		border.texture = profile.flower_border
		border.centered = false
		border.position = Vector2(50, 205)
		border.scale = Vector2(900, 73) / border.texture.get_size()
		_group.add_child(border)
	var kalin: KalinWalker = KalinWalker.new()
	kalin.position = Vector2(120, 265)
	kalin.scale = Vector2.ONE * 0.78
	_group.add_child(kalin)
	var supply: MeaningIllustration = (
		preload("res://scenes/ui/shared/meaning_illustration.tscn").instantiate()
		as MeaningIllustration
	)
	supply.position = Vector2(545, 125)
	supply.size = Vector2(110, 110)
	_group.add_child(supply)
	supply.show_meaning(state.food.get_slice("|", 0), "")
	supply.set_world_object(true)
	for guest: String in state.guests:
		var stage: Node2D = Node2D.new()
		stage.position = Vector2(760 if guest == "Kay" else 400, 250)
		_group.add_child(stage)
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
		art.show_meaning(state.food.get_slice("|", 0), "")
		var motion: VillageUseMotion = VillageUseMotion.attach(
			actor, art, state.food.get_slice("|", 0), guest
		)
		motion.use_shared_provision()
		if animate:
			motion.receive()
		actors.append(actor)
		arts.append(art)
		motions.append(motion)
	_layout()


func _layout() -> void:
	if is_instance_valid(_group):
		_group.scale = (
			Vector2.ONE
			* minf(size.x / _profile.gathering_size.x, size.y / _profile.gathering_size.y)
		)
		_group.position.x = (size.x - _profile.gathering_size.x * _group.scale.x) * 0.5


func clear() -> void:
	if is_instance_valid(_group):
		remove_child(_group)
		_group.queue_free()
	_group = null
	actors.clear()
	arts.clear()
	motions.clear()
