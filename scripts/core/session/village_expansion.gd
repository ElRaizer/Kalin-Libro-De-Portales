extends RefCounted
class_name VillageExpansion

const PURPOSES: Array[String] = ["rest", "snack"]
const GUESTS: Array[String] = ["Ma'ax", "Áak", "Miis"]


static func empty_state() -> Dictionary:
	return {"tried": [], "purpose": "", "guests": [], "opening": {}, "complete": false}


static func valid_guests(value: Variant, known: Dictionary, allow_empty: bool) -> bool:
	if value is not Array or value.size() > 2 or (value.is_empty() and not allow_empty):
		return false
	var seen: Array[String] = []
	for guest: Variant in value:
		if guest is not String or guest not in GUESTS or guest not in known or guest in seen:
			return false
		seen.append(guest)
	return true


static func valid_state(value: Variant, known: Dictionary, ready: bool) -> bool:
	if value is not Dictionary or value.size() != 5:
		return false
	if value.get("tried") is not Array or value.tried.size() > 2:
		return false
	var tried: Array[String] = []
	for purpose: Variant in value.tried:
		if purpose is not String or purpose not in PURPOSES or purpose in tried:
			return false
		tried.append(purpose)
	if (
		value.get("purpose") is not String
		or (value.purpose != "" and value.purpose not in tried)
		or value.get("complete") is not bool
		or value.get("opening") is not Dictionary
		or not valid_guests(value.get("guests"), known, not value.complete)
	):
		return false
	if not ready:
		return value == empty_state()
	if not value.complete:
		return value.opening.is_empty()
	return (
		tried.size() == 2
		and value.purpose in PURPOSES
		and value.opening.size() == 2
		and value.opening.get("purpose") is String
		and value.opening.purpose in PURPOSES
		and valid_guests(value.opening.get("guests"), known, false)
	)


static func memory(state: Dictionary) -> Dictionary:
	return state.opening.duplicate(true) if state.complete else {}
