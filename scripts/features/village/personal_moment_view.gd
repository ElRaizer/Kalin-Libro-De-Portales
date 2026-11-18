extends Control
class_name PersonalMomentView

## Escenario aislado cuya cámara encuadra sólo la representación del recuerdo.
const SCENE_SIZE: Vector2i = Vector2i(1280, 720)
const PATIO: Texture2D = preload("res://Arte/backgrounds/bg_village_patio.svg")
const SHORE: Texture2D = preload("res://Arte/backgrounds/bg_village_shore.svg")

var garden_profile: GardenProfile
var rest_profile: RestCornerProfile
var snack_profile: SnackProfile
var expansion_profile: ExpansionProfile
var _viewport: SubViewport
var _picture: TextureRect
var _stage: Node2D
var _motions: Array[VillageUseMotion] = []
var _center: Vector2
var _frame: String = "wide"
var _frozen: bool = true
var _elapsed: float = 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.size = SCENE_SIZE
	_viewport.disable_3d = true
	_viewport.world_2d = World2D.new()
	add_child(_viewport)
	_picture = TextureRect.new()
	_picture.texture = _viewport.get_texture()
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)
	resized.connect(_layout_camera)
	set_process(false)


func present(moment: Dictionary) -> void:
	clear()
	if moment.is_empty():
		return
	_stage = Node2D.new()
	_viewport.add_child(_stage)
	var landscape: Sprite2D = Sprite2D.new()
	landscape.centered = false
	landscape.texture = PATIO if moment.kind in ["visit", "rest"] else SHORE
	_stage.add_child(landscape)
	match moment.kind:
		"visit":
			_show_visit(moment.setting, moment.guests[0])
		"rest":
			_show_rest(moment)
		"snack":
			_show_snack(moment)
		"expansion":
			_show_expansion(moment)
	set_frame(moment.frame)
	set_pose(float(moment.pose))
	set_process(not _frozen)


func _show_visit(setting: Dictionary, guest: String) -> void:
	var identity: GardenIdentityView = GardenIdentityView.new()
	_stage.add_child(identity)
	identity.configure(garden_profile, setting.identity)
	if "gathering" in setting.identity.decorations:
		var garland: Sprite2D = Sprite2D.new()
		garland.texture = rest_profile.garland
		garland.position = rest_profile.garland_position
		garland.z_index = int(garland.position.y + 50)
		_stage.add_child(garland)
	var table: GardenObject
	var snapshot: Dictionary = {"objects": setting.objects}
	for object: Dictionary in setting.objects:
		var furniture: GardenObject = GardenObject.new()
		_stage.add_child(furniture)
		var support: Dictionary = GardenLayout.object_by_id(snapshot, int(object.support))
		furniture.configure(object, false, int(support.get("orientation", 0)))
		if furniture.object_id == int(setting.table):
			table = furniture
	var anchor: Vector2 = Vector2(float(setting.guest_x), float(setting.guest_y))
	var guest_stage: Node2D = Node2D.new()
	guest_stage.z_index = table.z_index + 2
	_stage.add_child(guest_stage)
	var actor: Sprite2D = Sprite2D.new()
	actor.texture = VillageUseArt.ACTORS[guest]
	actor.scale = Vector2.ONE * 96.0 / actor.texture.get_image().get_used_rect().size.y
	guest_stage.add_child(actor)
	_track(VillageUseMotion.attach(actor, table.art, "mayak", guest, anchor))
	_center = (anchor + table.position) * 0.5 - Vector2(0, 104)


func _show_rest(moment: Dictionary) -> void:
	var preview: RestCornerPreview = RestCornerPreview.new()
	preview.position = Vector2(230, 160)
	preview.size = Vector2(800, 270)
	_stage.add_child(preview)
	var guests: Array[String] = []
	guests.assign(moment.guests)
	preview.show_choice(moment.setting.word, rest_profile.garland, false, guests)
	_track(preview.motion)
	_center = Vector2(660, 335)


func _show_snack(moment: Dictionary) -> void:
	var gathering: SnackGathering = SnackGathering.new()
	gathering.position = Vector2(230, 175)
	gathering.size = Vector2(820, 230)
	_stage.add_child(gathering)
	var state: Dictionary = moment.setting.duplicate()
	state.guests = moment.guests
	gathering.present(state, snack_profile, false)
	for motion: VillageUseMotion in gathering.motions:
		_track(motion)
	_center = Vector2(595, 300)


func _show_expansion(moment: Dictionary) -> void:
	var space: VillageSpace = GameContent.VILLAGE_SPACES.space("shore")
	var ground: Panel = Panel.new()
	ground.position = space.extension_plot.position
	ground.size = space.extension_plot.size
	var surface: StyleBoxFlat = StyleBoxFlat.new()
	surface.bg_color = Color(expansion_profile.ground_color, 0.7)
	surface.set_corner_radius_all(20)
	ground.add_theme_stylebox_override("panel", surface)
	_stage.add_child(ground)
	var word: String = moment.setting.get("word", "")
	if moment.setting.purpose == "snack":
		var border: Sprite2D = Sprite2D.new()
		border.texture = expansion_profile.border
		border.centered = false
		border.position = ground.position
		border.scale = ground.size / border.texture.get_size()
		_stage.add_child(border)
		word = moment.setting.food.get_slice("|", 0)
	var gathering: ExpansionGathering = ExpansionGathering.new()
	_stage.add_child(gathering)
	var guests: Array[String] = []
	guests.assign(moment.guests)
	var anchors: Array[Vector2] = space.guest_anchors
	if guests.size() == 1:
		anchors = [(space.guest_anchors[0] + space.guest_anchors[1]) * 0.5]
	gathering.present_use(word, guests, anchors, false, 0.68)
	for motion: VillageUseMotion in gathering.motions:
		_track(motion)
	_center = space.extension_plot.get_center() - Vector2(0, 40)


func _track(motion: VillageUseMotion) -> void:
	motion.set_process(false)
	_motions.append(motion)


func set_frame(frame: String) -> void:
	_frame = frame
	_layout_camera()


func set_pose(seconds: float) -> void:
	_elapsed = seconds
	_sample(seconds)


func current_pose() -> float:
	return _elapsed


func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	set_process(not frozen and is_instance_valid(_stage))


func _process(delta: float) -> void:
	if _frozen or AccessibilityManager.reduced_motion:
		return
	_elapsed = fmod(_elapsed + delta, PersonalAlbum.POSE_DURATION)
	_sample(_elapsed)


func _sample(seconds: float) -> void:
	for motion: VillageUseMotion in _motions:
		motion.sample_action(seconds)


func _layout_camera() -> void:
	if not is_instance_valid(_picture) or not is_instance_valid(_stage):
		return
	var scale_factor: float = maxf(size.x / SCENE_SIZE.x, size.y / SCENE_SIZE.y)
	scale_factor *= 2.0 if _frame == "close" else 1.25
	_picture.size = Vector2(SCENE_SIZE) * scale_factor
	var offset: Vector2 = _center * scale_factor - size * 0.5
	_picture.position = -offset.clamp(Vector2.ZERO, _picture.size - size)


func clear() -> void:
	set_process(false)
	_motions.clear()
	if is_instance_valid(_stage):
		_viewport.remove_child(_stage)
		_stage.queue_free()
	_stage = null
