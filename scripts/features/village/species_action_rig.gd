extends Node2D
class_name SpeciesActionRig

## Piezas originales excluyentes: los apoyos no giran con el torso ni se añaden extremidades.
const CODES: Dictionary = {
	"Peek'": "peek",
	"Miis": "miis",
	"Áak": "aak",
	"Ma'ax": "maax",
	"Kéej": "keej",
	"K'éek'en": "keek_en",
	"Báalam": "baalam",
	"T'u'ul": "tuul",
	"Kaax": "kaax",
	"Kuuts": "kuuts",
	"Ch'íich'": "chiich"
}
# Puntos del viewBox 120, sobre el extremo visible de cada pieza de cabeza.
const MOUTHS: Dictionary = {
	"Kaax": Vector2(26, 54),
	"Kuuts": Vector2(30, 58),
	"Ch'íich'": Vector2(12, 50),
	"Áak": Vector2(60, 44),
	"Miis": Vector2(60, 64),
	"Peek'": Vector2(60, 65),
	"Kéej": Vector2(60, 64),
	"Báalam": Vector2(60, 66),
	"K'éek'en": Vector2(60, 61),
	"T'u'ul": Vector2(60, 64),
	"Ma'ax": Vector2(60, 62)
}
var animal: String = ""
var upper: Node2D
var head: Node2D
var hand: Line2D
var palm: Polygon2D
var tongue: Line2D
var tail: Node2D
var fins: Node2D
var head_picture: Sprite2D


func configure(word: String) -> void:
	animal = word
	if word == "Kay":
		position = Vector2(-60, -60)
		_part(self, "kay", "body", Vector2.ZERO)
		tail = Node2D.new()
		tail.position = Vector2(24, 60)
		add_child(tail)
		_part(tail, "kay", "tail", Vector2(-24, -60))
		fins = Node2D.new()
		fins.position = Vector2(60, 70)
		add_child(fins)
		_part(fins, "kay", "fins", Vector2(-60, -70))
		return
	var code: String = CODES.get(word, "")
	if code.is_empty():
		return
	position = Vector2(-60, -60)
	_part(self, code, "feet", Vector2.ZERO)
	upper = Node2D.new()
	upper.position = Vector2(60, 94)
	add_child(upper)
	_part(upper, code, "body", Vector2(-60, -94))
	head = Node2D.new()
	head.position = Vector2(0, -26)
	upper.add_child(head)
	# La unión cubre el pivote al inclinar; pertenece al torso, no a una cabeza flotante.
	var neck: Polygon2D = Polygon2D.new()
	neck.polygon = PackedVector2Array(
		[Vector2(-12, -34), Vector2(12, -34), Vector2(14, -18), Vector2(-14, -18)]
	)
	neck.color = (
		{
			"Miis": Color("a8a8c0"),
			"Áak": Color("8fb868"),
			"Kéej": Color("c89868"),
			"Peek'": Color("d4985a"),
			"Báalam": Color("e0a838"),
			"K'éek'en": Color("f0a0b4"),
			"T'u'ul": Color("c4c4ce")
		}
		. get(word, Color("8b6239"))
	)
	if word not in ["Kaax", "Kuuts", "Ch'íich'"]:
		upper.add_child(neck)
	else:
		neck.free()
	head_picture = _part(head, code, "head", Vector2(-60, -68))
	upper.move_child(head, upper.get_child_count() - 1)
	if word == "Ma'ax":
		hand = Line2D.new()
		hand.width = 12
		hand.default_color = Color("8b6239")
		hand.begin_cap_mode = Line2D.LINE_CAP_ROUND
		hand.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(hand)
		palm = Polygon2D.new()
		var palm_points: PackedVector2Array = PackedVector2Array()
		for index: int in range(12):
			palm_points.append(Vector2(cos(index * TAU / 12.0), sin(index * TAU / 12.0)) * 5)
		palm.polygon = palm_points
		palm.color = Color("c8a074")
		add_child(palm)
	tongue = Line2D.new()
	tongue.width = 2.5
	tongue.default_color = Color("df88a3")
	add_child(tongue)


func _part(parent: Node2D, code: String, part: String, offset: Vector2) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://Arte/aldea/uso/rigs/%s_%s.svg" % [code, part]) as Texture2D
	sprite.centered = false
	sprite.position = offset
	sprite.scale = Vector2(120, 120) / sprite.texture.get_size()
	parent.add_child(sprite)
	return sprite


func sample(seconds: float, vessel_grip: Vector2 = Vector2.ZERO) -> void:
	if animal == "Kay":
		tail.rotation = sin(seconds * 18) * 0.14
		fins.rotation = sin(seconds * 22) * 0.18
		return
	if not is_instance_valid(upper):
		return
	var moment: float = contact_time()
	var lean: float = (
		smoothstep(0.45, moment - 0.15, seconds) - smoothstep(moment + 0.65, moment + 1.5, seconds)
	)
	var angles: Dictionary = {
		"Miis": 24.0,
		"Peek'": 20.0,
		"Báalam": 17.0,
		"K'éek'en": 22.0,
		"Kéej": 28.0,
		"T'u'ul": 14.0,
		"Áak": 12.0,
		"Ma'ax": 3.0
	}
	upper.rotation_degrees = float(angles.get(animal, 0.0)) * lean
	head.position = Vector2(0, -26)
	head.rotation_degrees = 8 * lean
	if animal == "Áak":
		head.position.y += lean * 3
	if animal in ["T'u'ul", "K'éek'en"] and lean > 0.95:
		head.rotation_degrees += sin(seconds * (28 if animal == "T'u'ul" else 13)) * 1.5
	if animal in ["Kaax", "Kuuts", "Ch'íich'"]:
		var dip: float = (
			smoothstep(0.45, moment - 0.1, seconds)
			- smoothstep(moment + 0.35, moment + 0.6, seconds)
		)
		var swallow: float = (
			smoothstep(moment + 0.6, moment + 0.8, seconds)
			- smoothstep(moment + 1.1, moment + 1.5, seconds)
		)
		head.rotation_degrees = (
			-float({"Kaax": 55, "Kuuts": 43, "Ch'íich'": 37}[animal]) * dip + 12 * swallow
		)
	if is_instance_valid(hand):
		var grip: Vector2 = (
			to_local(vessel_grip) if vessel_grip != Vector2.ZERO else Vector2(84, 92)
		)
		hand.points = PackedVector2Array(
			[Vector2(84, 73), Vector2(90, 78).lerp(grip, lean * 0.6), grip]
		)
		palm.position = grip
	tongue.clear_points()
	if animal in ["Miis", "Peek'", "Báalam"] and seconds > moment and seconds < moment + 0.5:
		var mouth: Vector2 = to_local(mouth_position())
		var flick: float = maxf(0.0, sin(seconds * (40.0 if animal == "Miis" else 25.0))) * 5
		tongue.points = PackedVector2Array([mouth, mouth + Vector2(2, flick)])


func contact_time() -> float:
	return float(
		(
			{
				"Miis": 1.4,
				"Peek'": 1.5,
				"Áak": 2.0,
				"Ma'ax": 1.6,
				"Kéej": 1.7,
				"K'éek'en": 1.45,
				"Báalam": 1.6,
				"T'u'ul": 1.3,
				"Kaax": 1.25,
				"Kuuts": 1.55,
				"Ch'íich'": 1.1
			}
			. get(animal, 1.6)
		)
	)


func mouth_position() -> Vector2:
	if animal == "Kay":
		return to_global(Vector2(104, 62))
	head.force_update_transform()
	head_picture.force_update_transform()
	var svg_point: Vector2 = MOUTHS.get(animal, Vector2(60, 64))
	return head_picture.to_global(svg_point * head_picture.texture.get_size() / Vector2(120, 120))
