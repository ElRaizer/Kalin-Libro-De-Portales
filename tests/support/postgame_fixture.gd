extends RefCounted
class_name PostgameFixture

const NARRATIVE: Dictionary = {
	"kind": "home", "title": "Nuestro rincón", "animal": "Áak", "item": "mayak", "quality": "chich"
}


static func at_ending() -> GameSession:
	var session: GameSession = GardenFixture.complete_corner()
	_prepare_campaign(session)
	session.scene_states.erase("world5_cine1")
	session.rest_corner = RestCornerState.empty_state()
	session.resume_scene_key = "world5_cine1"
	return session


static func resumed() -> GameSession:
	var session: GameSession = GardenFixture.complete_snack()
	_prepare_campaign(session)
	session.try_expansion("rest")
	session.try_expansion("snack")
	session.select_expansion_guests(["Ma'ax", "Miis"])
	session.inaugurate_expansion()
	session.set_garden_identity("patio", "Nuestro patio", ["sign", "gathering"])
	var photo: Dictionary = {
		"title": "Una merienda con amigos",
		"kind": "snack",
		"frame": "wide",
		"pose": 4.0,
		"guests": session.snack_project.guests,
		"setting":
		{"food": session.snack_project.food, "decoration": session.snack_project.decoration}
	}
	session.apply_personal_album(session.album_with_moment(photo))
	var paths: PathPracticeState = PathPracticeState.new()
	paths.prepare(session.words_learned, 123)
	var route: Array[Vector2i] = GridReplayLayouts.cells(
		PathPracticeState.layout(paths.variant).solution[0]
	)
	paths.press(route[1])
	paths.supported = true
	session.resume_scene_key = "village_home"
	session.scene_states["village_home"] = {
		"district": "patio",
		"x": 630.0,
		"y": 550.0,
		"return_scene": "main_menu",
		"practice": {"mode": "mixed", "next": "paths", "paths": paths.snapshot()}
	}
	return session


static func _prepare_campaign(session: GameSession) -> void:
	for level: Dictionary in GameContent.LEVEL_ORDER:
		session.complete_level(level.world, level.level)
	session.scene_states["world5_farewell"] = {
		"complete": true, "gifts": [0, 1, 2], "memory": NARRATIVE
	}
	# La mesa y su plato permiten revisar visitas y superficie con el saldo agotado.
	var table_id: int = session.place_new_garden_object(
		"mayak|chich", Vector2(600, 440), "patio", 1
	)
	session.place_new_garden_object("lak|", Vector2.ZERO, "patio", 0, table_id)
	session.magic_points = 0
