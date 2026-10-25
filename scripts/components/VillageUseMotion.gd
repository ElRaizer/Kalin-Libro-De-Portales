extends Node2D
class_name VillageUseMotion

## Capas: casa 0, muebles 1, animal 2, tejido frontal 3, Kalin 4, opciones 6.
var actor: Sprite2D
var art: MeaningIllustration
var item := ""
var animal := ""
var actor_home := Vector2.ZERO
var actor_scale := Vector2.ONE
var art_home := Vector2.ZERO
var elapsed := 0.0
var pond: Sprite2D
var foot_y := 0.97

static func attach(target: Sprite2D, result: MeaningIllustration, word: String) -> void:
	result.world_object = true
	result._layout_art()
	(target.get_parent() as CanvasItem).z_index = 1
	target.z_index = 1
	(result.get_parent() as CanvasItem).z_index = 1
	result.z_index = 0
	var player := result.get_parent().get_parent().get_node_or_null("Kalin") as CanvasItem
	if player:
		player.z_index = 4
	var motion := result.get_node_or_null("UseMotion") as VillageUseMotion
	if motion == null:
		motion = VillageUseMotion.new()
		motion.name = "UseMotion"
		result.add_child(motion)
		motion.actor_home = target.position
		motion.actor_scale = target.scale
		motion.pond = Sprite2D.new()
		motion.pond.texture = VillageUseArt.POND
		motion.pond.scale = Vector2(0.7, 0.6)
		motion.add_child(motion.pond)
	motion.actor = target
	motion.art = result
	motion.item = word
	var spot := target.get_parent() as ExplorationSpot
	motion.animal = spot.speaker if spot else ""
	if motion.animal in VillageUseArt.ACTORS:
		target.texture = VillageUseArt.ACTORS[motion.animal]
	if target.texture:
		motion.foot_y = float(target.texture.get_image().get_used_rect().end.y) / target.texture.get_height()
	motion.art_home = result.position
	motion._pose(0.0)

func _process(delta: float) -> void:
	if not is_instance_valid(actor) or not is_instance_valid(art):
		return
	elapsed += delta
	_pose(0.0 if get_node("/root/AccessibilityManager").reduced_motion else sin(elapsed * 1.8))

func _pose(wave: float) -> void:
	if actor.texture == null:
		return
	actor.position = actor_home
	actor.scale = actor_scale
	actor.rotation = 0
	art.position = art_home
	pond.visible = animal == "Kay"
	if animal == "Kay":
		_adjacent(wave)
		actor.rotation = 0
		var ground := (actor.get_parent() as Node2D).to_global(Vector2(actor.position.x, 0))
		_anchor_actor(Vector2(0.5, 0.79), ground + Vector2(0, -3 + wave))
		pond.global_position = ground - Vector2(0, 22)
		return
	match item:
		"k'áan":
			actor.rotation = -0.8 + wave * 0.025
			_fit_actor(Vector2(0.64, 0.82))
			art.position = art_home + Vector2(0, wave * 1.5)
			_anchor_actor(Vector2(0.5, 0.5), art.get_global_transform() * (art.picture_rect().position + art.picture_rect().size * Vector2(0.5, 0.47)))
		"k'áanche'":
			_fit_actor(Vector2(0.67, 0.95))
			var rect := art.picture_rect()
			_anchor_actor(Vector2(0.5, foot_y), art.get_global_transform() * (rect.position + rect.size * Vector2(0.5, 160.0 / 180)))
		_:
			_adjacent(wave)

func _adjacent(wave: float) -> void:
	var rect := art.picture_rect()
	var fraction := 0.75 if item == "mayak" else (0.9 if item == "k'áan" else 0.76)
	var object_width := rect.size.x * fraction
	var actor_width := actor.texture.get_width() * actor.scale.x
	var span := actor_width + 14 + object_width
	var home := (actor.get_parent() as Node2D).to_global(Vector2.ZERO)
	var actor_x := home.x - span * 0.5 + actor_width * 0.5
	var object_x := home.x + span * 0.5 - object_width * 0.5
	art.global_position.x += object_x - (art.get_global_transform() * rect.get_center()).x
	actor.rotation = wave * 0.008
	_anchor_actor(Vector2(0.5, foot_y), Vector2(actor_x, home.y))

func _anchor_actor(fraction: Vector2, world_point: Vector2) -> void:
	var anchor := actor.get_rect().position + actor.texture.get_size() * fraction
	actor.position = (actor.get_parent() as Node2D).to_local(world_point) - (anchor * actor.scale).rotated(actor.rotation)

func _fit_actor(fraction: Vector2) -> void:
	var extent := art.picture_rect().size * fraction
	var texture_size := actor.texture.get_size()
	var c := absf(cos(actor.rotation))
	var s := absf(sin(actor.rotation))
	var rotated := Vector2(texture_size.x * c + texture_size.y * s, texture_size.x * s + texture_size.y * c)
	var factor := minf(extent.x / rotated.x, extent.y / rotated.y)
	actor.scale = Vector2.ONE * factor
