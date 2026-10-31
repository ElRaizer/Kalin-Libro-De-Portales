extends Node2D
class_name VillageUseMotion

## Capas: casa 0, muebles 1, animal 2, tejido frontal 3, Kalin 4, opciones 6.
var actor: Sprite2D
var art: MeaningIllustration
var item: String = ""
var animal: String = ""
var actor_home: Vector2 = Vector2.ZERO
var actor_scale: Vector2 = Vector2.ONE
var art_home: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var pond: Sprite2D
var foot_y: float = 0.97
var _receiving: float = 1.0
var _action_time: float = 4.0
var _look: Texture2D
var _rest: Texture2D
var _portion: Sprite2D
var _stage: String = "rest"
var _rig: SpeciesActionRig
var _vessel: Sprite2D
var _stand: Line2D
var _water_front: Sprite2D
const FOOD: Array[String] = ["ja'", "ja'as", "ich", "K'úum", "janal"]


static func attach(
	target: Sprite2D, result: MeaningIllustration, word: String, actor_word: String
) -> VillageUseMotion:
	result.set_world_object(true)
	target.z_index = 1
	result.z_index = 0
	var motion: VillageUseMotion = result.get_node_or_null("UseMotion") as VillageUseMotion
	if motion == null:
		motion = VillageUseMotion.new()
		motion.name = "UseMotion"
		result.add_child(motion)
		motion.actor_home = target.position
		motion.actor_scale = target.scale
		motion.pond = Sprite2D.new()
		motion.pond.texture = VillageUseArt.POND
		motion.pond.scale = Vector2(0.9, 0.8)
		motion.add_child(motion.pond)
		motion._water_front = Sprite2D.new()
		motion._water_front.texture = preload("res://Arte/aldea/uso/pond_front.svg")
		motion._water_front.z_index = 3
		motion.add_child(motion._water_front)
	motion.actor = target
	target.set_meta("village_motion", weakref(motion))
	var habitat_reference: WeakRef = (
		target.get_meta("village_habitat") as WeakRef
		if target.has_meta("village_habitat")
		else null
	)
	if habitat_reference != null:
		var habitat: VillageHabitat = habitat_reference.get_ref() as VillageHabitat
		if is_instance_valid(habitat):
			habitat.set_using_result(true)
			motion.actor_scale = habitat.authored_scale
	target.self_modulate.a = 1
	motion.art = result
	motion.item = word
	motion.animal = actor_word
	motion._look = result.catalog.expression_for(actor_word, "activity_look")
	if motion.animal in VillageUseArt.ACTORS:
		target.texture = VillageUseArt.ACTORS[motion.animal]
	motion._rest = target.texture
	if motion._portion == null:
		motion._portion = Sprite2D.new()
		motion._portion.name = "Portion"
		motion._portion.z_index = 5
		motion.add_child(motion._portion)
	motion._portion.texture = (null if word == "ja'" else VillageUseArt.object_texture(word, ""))
	motion._portion.hide()
	if is_instance_valid(motion._rig):
		motion._rig.queue_free()
		motion._rig = null
	if word in FOOD:
		motion._rig = SpeciesActionRig.new()
		target.add_child(motion._rig)
		motion._rig.configure(actor_word)
		motion._rig.position += target.offset
	if motion._vessel == null:
		motion._vessel = Sprite2D.new()
		motion._vessel.centered = false
		motion._vessel.z_index = 4
		motion._vessel.texture = VillageUseArt.object_texture("ja'", "")
		motion.add_child(motion._vessel)
		motion._stand = Line2D.new()
		motion._stand.width = 6
		motion._stand.z_index = 3
		motion._stand.default_color = Color("986330")
		motion.add_child(motion._stand)
	motion._vessel.hide()
	motion._stand.hide()
	if target.texture:
		motion.foot_y = (
			float(target.texture.get_image().get_used_rect().end.y) / target.texture.get_height()
		)
	motion.art_home = result.position
	motion._pose(0.0)
	motion._apply_action(4.0)
	return motion


func receive() -> void:
	_receiving = 0.0
	_action_time = 0.0
	if item in FOOD:
		_pose(0.0)
		_apply_action(4.0 if get_node("/root/AccessibilityManager").reduced_motion else 0.0)
		return
	if get_node("/root/AccessibilityManager").reduced_motion:
		_receiving = 1.0
		_action_time = 4.0
		_pose(0.0)
	else:
		actor.position = actor_home
		actor.scale = actor_scale
		actor.rotation = 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree() or not is_instance_valid(actor) or not is_instance_valid(art):
		return
	elapsed += delta
	var reduced: bool = get_node("/root/AccessibilityManager").reduced_motion
	var speed: float = 1.2 if animal == "Áak" else (2.5 if animal == "Ma'ax" else 1.8)
	_pose(0.0 if reduced else sin(elapsed * speed))
	_receiving = minf(1.0, _receiving + delta / (0.9 if animal == "Áak" else 0.6))
	if _receiving < 1.0 and not reduced and item not in FOOD:
		var weight: float = smoothstep(0.0, 1.0, _receiving)
		actor.position = actor_home.lerp(actor.position, weight)
		actor.scale = actor_scale.lerp(actor.scale, weight)
		actor.rotation *= weight
		if animal != "Kay":
			actor.position.y -= sin(_receiving * PI) * 7.0
	_action_time += delta / (1.6 if animal == "Áak" else (0.7 if animal == "Ma'ax" else 1.0))
	if item in FOOD and _action_time >= 7.0 and not (animal == "Kay" and item == "ja'"):
		_action_time = 0.0
	_apply_action(4.0 if reduced else _action_time)


## Instantes reproducibles para la previsualización de actuaciones y sus secuencias.
func sample_action(seconds: float) -> void:
	_pose(0.0)
	_apply_action(maxf(0.0, seconds))


func action_stage() -> String:
	return _stage


func _apply_action(seconds: float) -> void:
	_portion.hide()
	_stage = "rest"
	actor.texture = _rest
	if item in FOOD:
		_apply_species_action(seconds)
		return
	actor.flip_h = false
	if seconds < 0.55:
		_stage = "look"
		actor.texture = _look


func _apply_species_action(seconds: float) -> void:
	_stage = (
		"look"
		if seconds < 0.55
		else ("reach" if seconds < 1.45 else ("consume" if seconds < 2.3 else "rest"))
	)
	actor.flip_h = false
	_vessel.hide()
	_stand.hide()
	if animal == "Kay":
		_apply_fish_action(seconds)
		return
	if not is_instance_valid(_rig):
		return
	actor.self_modulate.a = 0
	actor.rotation = 0
	var bird: bool = animal in ["Kaax", "Kuuts", "Ch'íich'"]
	_rig.scale.x = -1 if bird else 1
	_rig.position.x = actor.offset.x + (60 if bird else -60)
	_rig.sample(_rig.contact_time())
	var contact: Vector2 = _rig.mouth_position()
	_rig.sample(seconds)
	art.picture.hide()
	art.world_mat.hide()
	if item == "ja'":
		_serve_water(contact, seconds, bird)
	else:
		_serve_food(contact, seconds)


func _serve_water(contact: Vector2, seconds: float, bird: bool) -> void:
	var bowl: bool = animal != "Ma'ax" and not bird
	_vessel.texture = (
		preload("res://Arte/aldea/uso/drinking_bowl.svg")
		if bowl
		else VillageUseArt.object_texture("ja'", "")
	)
	var rim: Vector2 = Vector2(60, 18) if bowl else Vector2(120, 34)
	var bottom: Vector2 = Vector2(60, 57) if bowl else Vector2(120, 150)
	var factor: float = (0.45 if bowl else 0.2) * actor.global_scale.x
	_vessel.global_scale = Vector2.ONE * factor
	var base: Vector2 = contact - rim * factor
	var rest: Vector2 = base + Vector2(36, 18) * actor.global_scale.x if animal == "Ma'ax" else base
	var moment: float = _rig.contact_time()
	var lift: float = (
		smoothstep(0.6, moment, seconds) - smoothstep(moment + 0.65, moment + 1.5, seconds)
	)
	_vessel.global_position = rest.lerp(base, lift)
	_vessel.show()
	if animal == "Ma'ax":
		_rig.sample(seconds, _vessel.to_global(Vector2(163, 90)))
	_support_dish(rest + bottom * factor)


func _serve_food(contact: Vector2, seconds: float) -> void:
	_vessel.texture = preload("res://Arte/aldea/uso/eating_bowl.svg")
	var factor: float = 0.45 * actor.global_scale.x
	_vessel.global_scale = Vector2.ONE * factor
	var served: Vector2 = contact
	if animal == "Ma'ax":
		served += Vector2(34, 22) * actor.global_scale.x
	_vessel.global_position = served - Vector2(60, 18) * factor
	_vessel.show()
	_support_dish(_vessel.to_global(Vector2(60, 57)))
	if _portion.texture == null:
		return
	_portion.show()
	var used: Rect2i = _portion.texture.get_image().get_used_rect()
	var scale_factor: float = 22 * actor.global_scale.x / maxf(used.size.x, used.size.y)
	var food_point: Vector2 = served
	if animal == "Ma'ax":
		# Sólo la especie con mano lleva la porción: el extremo de la mano permanece unido.
		var moment: float = _rig.contact_time()
		var take: float = (
			smoothstep(0.55, moment, seconds) - smoothstep(moment + 0.6, moment + 1.5, seconds)
		)
		food_point = served.lerp(_rig.mouth_position(), take) + Vector2(0, -sin(take * PI) * 7)
		var grip: Vector2 = food_point + Vector2(0, used.size.y * scale_factor * 0.5)
		_rig.sample(seconds, grip)
	_portion.global_scale = Vector2.ONE * scale_factor
	_portion.global_position = (
		food_point - (Vector2(used.get_center()) - _portion.texture.get_size() * 0.5) * scale_factor
	)
	_portion.modulate.a = 1.0
	if art.quality_badge.visible:
		art.quality_badge.size = Vector2(28, 28)
		art.quality_badge.global_position = food_point + Vector2(14, -28) * actor.global_scale


func _support_dish(bottom: Vector2) -> void:
	_stand.show()
	var support: Vector2 = (
		actor.get_rect().position + actor.texture.get_size() * Vector2(0.5, foot_y)
	)
	var floor_point: Vector2 = Vector2(bottom.x, actor.to_global(support).y)
	var side: float = 0.0 if animal in ["Ma'ax", "Ch'íich'"] else 32.0
	_stand.points = PackedVector2Array(
		[
			to_local(floor_point + Vector2(side - 16, 0)),
			to_local(bottom + Vector2(side - 16, 0)),
			to_local(bottom + Vector2(-16, 0)),
			to_local(bottom + Vector2(side + 16, 0)),
			to_local(floor_point + Vector2(side + 16, 0))
		]
	)


func _apply_fish_action(seconds: float) -> void:
	actor.self_modulate.a = 0
	_rig.sample(seconds)
	if item == "ja'":
		art.picture.hide()
		art.world_mat.hide()
		pond.scale.y = 0.8 + smoothstep(0.55, 2.0, seconds) * 0.04
		_water_front.global_scale = pond.global_scale
		return
	var home: Vector2 = actor.position
	var approach: float = smoothstep(0.55, 1.45, seconds) - smoothstep(2.5, 3.3, seconds)
	actor.position = home + Vector2(approach * 32, sin(seconds * 8) * approach * 2)
	var turn: float = 1.0
	if seconds > 2.1 and seconds < 2.5:
		turn = cos(smoothstep(2.1, 2.5, seconds) * PI)
	elif seconds >= 2.5 and seconds < 3.3:
		turn = -1
	elif seconds >= 3.3 and seconds < 3.7:
		turn = -cos(smoothstep(3.3, 3.7, seconds) * PI)
	actor.scale.x *= maxf(absf(turn), 0.08) * (-1.0 if turn < 0 else 1.0)
	if seconds > 0.55 and seconds < 2.05 and _portion.texture != null:
		_portion.show()
		var mouth: Vector2 = _rig.mouth_position()
		_portion.global_position = mouth + Vector2(0, -32 * (1.0 - smoothstep(0.55, 1.45, seconds)))
		_portion.global_scale = Vector2.ONE * 12 / _portion.texture.get_width()
		_portion.modulate.a = 1.0 - smoothstep(1.6, 2.05, seconds)


func _exit_tree() -> void:
	if is_instance_valid(actor):
		var owner_reference: WeakRef = (
			actor.get_meta("village_motion") as WeakRef
			if actor.has_meta("village_motion")
			else null
		)
		if owner_reference != null and owner_reference.get_ref() == self:
			actor.self_modulate.a = 1
			actor.remove_meta("village_motion")
			var habitat_reference: WeakRef = (
				actor.get_meta("village_habitat") as WeakRef
				if actor.has_meta("village_habitat")
				else null
			)
			if habitat_reference != null:
				var habitat: VillageHabitat = habitat_reference.get_ref() as VillageHabitat
				if is_instance_valid(habitat):
					habitat.set_using_result(false)
	if is_instance_valid(_rig):
		_rig.queue_free()


func _pose(wave: float) -> void:
	if actor.texture == null:
		return
	actor.position = actor_home
	actor.scale = actor_scale
	actor.rotation = 0
	art.position = art_home
	pond.visible = animal == "Kay"
	_water_front.visible = animal == "Kay"
	if animal == "Kay":
		_adjacent(wave)
		actor.rotation = 0
		var ground: Vector2 = (actor.get_parent() as Node2D).to_global(Vector2(actor.position.x, 0))
		# La escala de celebración puede ser mayor que la del mundo: cabe bajo la superficie.
		var water_height: float = pond.texture.get_height() * pond.global_scale.y
		var fish_height: float = actor.texture.get_height() * actor.global_scale.y
		actor.scale *= minf(0.72, water_height * 0.6 / maxf(1.0, fish_height))
		_anchor_actor(Vector2(0.5, 0.65), ground + Vector2(0, -48 + wave))
		pond.global_position = ground - Vector2(0, 60)
		_water_front.global_position = pond.global_position
		_water_front.global_scale = pond.global_scale
		art.position.x += 45
		return
	match item:
		"k'áan":
			actor.rotation = -0.8 + wave * 0.025
			_fit_actor(Vector2(0.64, 0.82))
			art.position = art_home + Vector2(0, wave * 1.5)
			_anchor_actor(
				Vector2(0.5, 0.5),
				(
					art.get_global_transform()
					* (art.picture_rect().position + art.picture_rect().size * Vector2(0.5, 0.47))
				)
			)
		"k'áanche'":
			_fit_actor(Vector2(0.67, 0.95))
			var rect: Rect2 = art.picture_rect()
			_anchor_actor(
				Vector2(0.5, foot_y),
				art.get_global_transform() * (rect.position + rect.size * Vector2(0.5, 160.0 / 180))
			)
		_:
			_adjacent(0.0 if item in FOOD else wave)


func _adjacent(wave: float) -> void:
	var rect: Rect2 = art.picture_rect()
	var fraction: float = 0.75 if item == "mayak" else (0.9 if item == "k'áan" else 0.76)
	var object_width: float = rect.size.x * fraction
	var actor_width: float = actor.texture.get_width() * actor.scale.x
	var span: float = actor_width + 14 + object_width
	var home: Vector2 = (actor.get_parent() as Node2D).to_global(Vector2.ZERO)
	var actor_x: float = home.x - span * 0.5 + actor_width * 0.5
	var object_x: float = home.x + span * 0.5 - object_width * 0.5
	art.global_position.x += object_x - (art.get_global_transform() * rect.get_center()).x
	actor.rotation = wave * 0.008
	if item in ["ja'", "ja'as", "ich", "K'úum", "janal"]:
		actor.rotation += maxf(wave, 0.0) * 0.07
	_anchor_actor(Vector2(0.5, foot_y), Vector2(actor_x, home.y))


func _anchor_actor(fraction: Vector2, world_point: Vector2) -> void:
	var anchor: Vector2 = actor.get_rect().position + actor.texture.get_size() * fraction
	actor.position = (
		(actor.get_parent() as Node2D).to_local(world_point)
		- (anchor * actor.scale).rotated(actor.rotation)
	)


func _fit_actor(fraction: Vector2) -> void:
	var extent: Vector2 = art.picture_rect().size * fraction
	var texture_size: Vector2 = actor.texture.get_size()
	var c: float = absf(cos(actor.rotation))
	var s: float = absf(sin(actor.rotation))
	var rotated: Vector2 = Vector2(
		texture_size.x * c + texture_size.y * s, texture_size.x * s + texture_size.y * c
	)
	var factor: float = minf(extent.x / rotated.x, extent.y / rotated.y)
	actor.scale = Vector2.ONE * factor
