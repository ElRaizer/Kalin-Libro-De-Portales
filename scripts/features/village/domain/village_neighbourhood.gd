extends RefCounted
class_name VillageNeighbourhood

var encounter_line: int = 0
var talk_animal: String = ""
var talk_line: int = 0
var talk_topics: Array[String] = []
var _encounter: PostgameEncounter
var _heard: Array[String] = []
var _session: GameSession
var _profile: VillageNeighbourProfile


func restore(saved: Variant, session: GameSession, profile: VillageNeighbourProfile) -> void:
	_session = session
	_profile = profile
	_encounter = null
	_heard.clear()
	encounter_line = 0
	finish_talk()
	if saved is Dictionary:
		_restore_heard(saved.get("heard"))
		var id: Variant = saved.get("encounter")
		for entry: PostgameEncounter in profile.encounters:
			if entry != null and id is String and entry.id == id and _available(entry):
				_encounter = entry
				encounter_line = _line(saved.get("encounter_line"), entry.lines.size())
				break
		_restore_talk(saved.get("talk"))
	if _encounter == null:
		for entry: PostgameEncounter in profile.encounters:
			if _available(entry) and entry.timely(_session):
				_encounter = entry
				break


func _available(entry: PostgameEncounter) -> bool:
	return (
		entry != null
		and not entry.lines.is_empty()
		and entry.id not in _heard
		and entry.eligible(_session)
	)


func _restore_heard(value: Variant) -> void:
	if value is not Array or value.size() > _profile.encounters.size():
		return
	for id: Variant in value:
		if id is not String or id in _heard:
			continue
		for entry: PostgameEncounter in _profile.encounters:
			if entry != null and entry.id == id and entry.eligible(_session):
				_heard.append(id)
				break


func _restore_talk(value: Variant) -> void:
	if value is not Dictionary or value.get("animal") is not String:
		return
	if (
		value.animal not in _session.words_learned
		or VillageNeighbours.district_for(value.animal).is_empty()
	):
		return
	if value.get("topics") is not Array or value.topics.size() > 6:
		return
	var evidence: Array[String] = topics_for(value.animal)
	var topics: Array[String] = []
	for topic: Variant in value.topics:
		if topic is not String or topic in topics or topic not in evidence:
			return
		topics.append(topic)
	talk_animal = value.animal
	talk_topics = topics
	talk_line = _line(value.get("line"), 1 + topics.size())


func _line(value: Variant, length: int) -> int:
	if not SaveSchema.is_number(value) or float(value) != floor(float(value)):
		return 0
	return int(value) if float(value) >= 0 and float(value) < length else 0


func encounter() -> PostgameEncounter:
	return _encounter


func advance_encounter() -> bool:
	if encounter_line + 1 < _encounter.lines.size():
		encounter_line += 1
		return true
	_heard.append(_encounter.id)
	_encounter = null
	encounter_line = 0
	return false


func begin_talk(animal: String) -> void:
	if talk_animal != animal:
		talk_animal = animal
		talk_topics = topics_for(animal)
		talk_line = 0


func finish_talk() -> void:
	talk_animal = ""
	talk_topics.clear()
	talk_line = 0


func topics_for(animal: String) -> Array[String]:
	var topics: Array[String] = []
	if _session.received_village_delivery(animal):
		topics.append("mission")
	if _session.hosted_village_guest(animal):
		topics.append("visit")
	if _session.rest_corner.complete and animal in RestCornerState.GUESTS:
		topics.append("rest")
	if _session.snack_project.complete and animal in _session.snack_project.guests:
		topics.append("snack")
	if _session.village_expansion.complete and animal in _session.village_expansion.opening.guests:
		topics.append("opening")
	elif animal in _session.village_experiences.clearing:
		topics.append("clearing")
	return topics


func opportunity() -> Dictionary:
	if not _session.has_finished_adventure():
		return {}
	if _encounter != null and _encounter.timely(_session):
		return _encounter_opportunity()
	if not _session.rest_corner.complete:
		return {"area": "patio", "action": "rest", "title": "Un lugar para descansar"}
	if not _session.snack_project.complete:
		return {"area": "shore", "action": "snack", "title": "Merienda junto al estanque"}
	if not _session.village_expansion.complete:
		return {"area": "shore", "action": "expansion", "title": "La aldea que imaginamos"}
	if _encounter != null:
		return _encounter_opportunity()
	return {"area": "shore", "action": "expansion", "title": "Otra reunión en el claro"}


func _encounter_opportunity() -> Dictionary:
	return {"area": _encounter.district, "action": "encounter", "title": _encounter.title}


func snapshot() -> Dictionary:
	var state: Dictionary = {
		"heard": _heard.duplicate(),
		"encounter": _encounter.id if _encounter != null else "",
		"encounter_line": encounter_line,
	}
	if not talk_animal.is_empty():
		state.talk = {"animal": talk_animal, "line": talk_line, "topics": talk_topics.duplicate()}
	return state
