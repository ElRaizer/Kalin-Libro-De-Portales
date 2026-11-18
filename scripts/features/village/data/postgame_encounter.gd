extends Resource
class_name PostgameEncounter

@export var id: String = ""
@export_enum("patio", "workshop", "shore") var district: String = "patio"
@export var location: Vector2 = Vector2(640, 520)
@export var title: String = ""
@export_enum("homecoming", "rested", "snack", "opening", "visited")
var condition: String = "homecoming"
@export var visitor: String = ""
@export var speakers: Array[String] = []
@export_multiline var lines: Array[String] = []
@export_enum("none", "rest", "snack", "expansion", "album", "laboratory")
var activity: String = "none"


func eligible(session: GameSession) -> bool:
	if not session.has_finished_adventure():
		return false
	for speaker: String in speakers:
		if speaker not in session.words_learned:
			return false
	match condition:
		"rested":
			return session.rest_corner.complete
		"snack":
			return session.expansion_ready()
		"opening":
			return session.village_expansion.complete
		"visited":
			return session.hosted_village_guest(visitor)
	return condition == "homecoming"


func timely(session: GameSession) -> bool:
	match condition:
		"homecoming":
			return not session.rest_corner.complete
		"rested":
			return not session.snack_project.complete
		"snack":
			return not session.village_expansion.complete
	return true


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	if (
		id.is_empty()
		or title.strip_edges().is_empty()
		or title.length() > 36
		or district not in VillageNeighbours.DISTRICTS
		or not location.is_finite()
	):
		issues.append(
			"Configura la identidad, el título breve, el barrio y la ubicación del encuentro."
		)
	if lines.is_empty() or lines.size() != speakers.size():
		issues.append("Cada línea necesita un interlocutor.")
	for speaker: String in speakers:
		if VillageNeighbours.district_for(speaker).is_empty():
			issues.append("El interlocutor debe pertenecer a la aldea.")
	for line: String in lines:
		if line.strip_edges().is_empty() or line.length() > 160:
			issues.append("Cada línea necesita un texto breve.")
	if condition == "visited" and VillageNeighbours.district_for(visitor).is_empty():
		issues.append("Indica quién hizo la visita previa.")
	return issues
