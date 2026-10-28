extends RefCounted
class_name VillageResidents

const HOMES := {
	"Peek'": preload("res://Arte/aldea/casa_peek.svg"),
	"Miis": preload("res://Arte/aldea/casa_miis.svg"),
	"Kaax": preload("res://Arte/aldea/casa_kaax.svg"),
	"Áak": preload("res://Arte/aldea/casa_aak.svg"),
	"Kéej": preload("res://Arte/aldea/casa_keej.svg"),
	"K'éek'en": preload("res://Arte/aldea/casa_keek_en.svg"),
	"Ma'ax": preload("res://Arte/aldea/casa_maax.svg"),
	"Kuuts": preload("res://Arte/aldea/casa_kuuts.svg"),
	"Báalam": preload("res://Arte/aldea/casa_baalam.svg"),
	"T'u'ul": preload("res://Arte/aldea/casa_tuul.svg"),
	"Kay": preload("res://Arte/aldea/casa_kay.svg"),
	"Ch'íich'": preload("res://Arte/aldea/casa_chiich.svg"),
}
const SPOT = preload("res://scenes/features/exploration/exploration_spot.tscn")


static func select(saved: Dictionary, seed_value: int) -> Array[String]:
	var stored: Variant = saved.get("residents")
	var result: Array[String] = []
	if stored is Array and stored.size() == 3:
		for word: Variant in stored:
			if (
				word is not String
				or word not in HOMES
				or word in GameContent.FUTURE_VOCABULARY
				or word in result
			):
				result.clear()
				break
			result.append(word)
		if result.size() == 3:
			return result
	var pool: Array[String] = _pool()
	var previous: Array = ReplayVariation.previous(saved, "residents", [])
	for index: int in ReplayVariation.order(pool.size(), seed_value):
		result.append(pool[index])
	if result.slice(0, 3) == previous:
		result.append(result.pop_front())
	result.resize(3)
	return result


static func _pool() -> Array[String]:
	var pool: Array[String] = []
	for word: String in HOMES:
		if word not in GameContent.FUTURE_VOCABULARY:
			pool.append(word)
	return pool


static func install(
	host: Node2D, recipients: Array[ExplorationSpot], residents: Array[String], seed_value: int
) -> void:
	var dialogue: VillageDialogue = VillageDialogue.new()
	dialogue.name = "VillageDialogue"
	dialogue.restore(host.get_node("/root/GameManager").get_scene_state(host), seed_value)
	host.add_child(dialogue)
	var homes: Node2D = Node2D.new()
	homes.name = "VillageHomes"
	host.add_child(homes)
	for index: int in range(recipients.size()):
		recipients[index].z_index = 1
		recipients[index].set_meta("village_resident", true)
		_home(homes, recipients[index].position, residents[index], 1.0)
	var remaining: Array[String] = []
	var pool: Array[String] = _pool()
	for index: int in ReplayVariation.order(pool.size(), seed_value + 1717):
		if pool[index] not in residents:
			remaining.append(pool[index])
	var positions: Array[Vector2] = [
		recipients[0].position - Vector2(440, 0),
		recipients[0].position.lerp(recipients[1].position, 0.5),
		recipients[1].position.lerp(recipients[2].position, 0.5)
	]
	for index: int in range(3):
		var word: String = remaining[index]
		var spot: ExplorationSpot = SPOT.instantiate() as ExplorationSpot
		spot.name = "Neighbour%d" % index
		spot.position = positions[index]
		spot.z_index = 1
		spot.prompt = "Saludar"
		spot.speaker = word
		spot.set_meta("village_neighbour", true)
		dialogue.prepare(spot)
		spot.spot_texture = host.get_node("/root/GameManager").get_visual_texture(word)
		spot.sprite_offset = Vector2(0, -61)
		spot.sprite_scale = Vector2.ONE
		spot.reach_radius = 130
		host.get_node("Spots").add_child(spot)
		_home(homes, spot.position, word, 0.8)


static func _home(parent: Node2D, ground: Vector2, word: String, factor: float) -> void:
	var home: Sprite2D = Sprite2D.new()
	home.name = "Home%d" % parent.get_child_count()
	home.texture = HOMES[word]
	home.scale = Vector2.ONE * factor
	home.position = ground + Vector2(-42, -151 * factor)
	home.set_meta("resident", word)
	parent.add_child(home)
