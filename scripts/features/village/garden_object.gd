extends Node2D
class_name GardenObject

## Vista del mueble: su origen es el apoyo en el suelo, también al ordenar profundidad.
var object_id: int = 0
var art: MeaningIllustration
var hit_area: Rect2
const CHAIR_VIEWS: Array[Texture2D] = [
	preload("res://Arte/aldea/uso/silla.svg"),
	preload("res://Arte/aldea/uso/chair_right.svg"),
	preload("res://Arte/aldea/uso/chair_back.svg"),
	preload("res://Arte/aldea/uso/chair_left.svg")
]


func configure(object: Dictionary, selected: bool = false, support_orientation: int = 0) -> void:
	object_id = int(object.id)
	position = GardenLayout.point(object)
	z_index = int(position.y)
	if art == null:
		art = (
			preload("res://scenes/ui/shared/meaning_illustration.tscn").instantiate()
			as MeaningIllustration
		)
		art.catalog = preload("res://data/visual_catalog.tres")
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
	var word: String = object.key.get_slice("|", 0)
	art.position = Vector2(-100, -145)
	art.size = Vector2(200, 150)
	art.show_meaning(word, object.key.get_slice("|", 1))
	art.set_world_object(true)
	if word == "k'áanche'" and int(object.orientation) != 0:
		art.picture.texture = CHAIR_VIEWS[int(object.orientation)]
		var quality: String = object.key.get_slice("|", 1)
		if quality in ["chich", "Jats'uts"]:
			var direction: String = ["", "right", "back", "left"][int(object.orientation)]
			art.picture.texture = (
				load(
					(
						"res://Arte/aldea/uso/chair_%s_%s.svg"
						% [direction, "strong" if quality == "chich" else "pretty"]
					)
				)
				as Texture2D
			)
	if word == "mayak" and int(object.orientation) != 0:
		var direction: String = ["", "right", "back", "left"][int(object.orientation)]
		var quality: String = object.key.get_slice("|", 1)
		var suffix: String = (
			"_strong" if quality == "chich" else ("_pretty" if quality == "Jats'uts" else "")
		)
		art.picture.texture = (
			load("res://Arte/aldea/uso/table_%s%s.svg" % [direction, suffix]) as Texture2D
		)
	if int(object.support) != 0:
		# La superficie está por encima del apoyo del suelo, no se simula con Z.
		art.position.y -= 51 if support_orientation % 2 == 0 else 26
		art.scale = Vector2.ONE * 0.65
		art.position.x = -65
		z_index += 1
	art.modulate = Color(1.12, 1.12, 0.8) if selected else Color.WHITE
	hit_area = Rect2(position + Vector2(-90, -130), Vector2(180, 145))
