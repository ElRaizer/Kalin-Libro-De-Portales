extends RefCounted
class_name PersonalAlbum

const LIMIT: int = 12
const TITLE_LENGTH: int = 32
const KINDS: Array[String] = ["visit", "rest", "snack", "expansion"]
const FRAMES: Array[String] = ["wide", "close"]
const PRESET_POSES: Array[float] = [0.2, 4.0]
const POSE_DURATION: float = 7.0


static func valid_state(value: Variant, known: Dictionary) -> bool:
	if value is not Array or value.size() > LIMIT:
		return false
	for moment: Variant in value:
		if not valid_moment(moment, known):
			return false
	return true


static func valid_moment(value: Variant, known: Dictionary) -> bool:
	if value is not Dictionary or value.size() != 6:
		return false
	if not GardenIdentity.valid_name(value.get("title")) or value.title.is_empty():
		return false
	if (
		value.get("kind") is not String
		or value.kind not in KINDS
		or value.get("frame") is not String
		or value.frame not in FRAMES
		or not SaveSchema.is_number(value.get("pose"))
		or float(value.pose) < 0.0
		or float(value.pose) >= POSE_DURATION
		or value.get("setting") is not Dictionary
	):
		return false
	return (
		_valid_guests(value.kind, value.get("guests"), known)
		and _valid_setting(value.kind, value.setting, known)
	)


static func _valid_guests(kind: String, guests: Variant, known: Dictionary) -> bool:
	if guests is not Array or guests.is_empty() or guests.size() > (1 if kind == "visit" else 2):
		return false
	if kind == "visit":
		return (
			guests[0] is String
			and guests[0] in known
			and VillageNeighbours.table_guest(guests[0], true)
		)
	var compatible: Array[String] = RestCornerState.GUESTS
	if kind == "snack":
		compatible = SnackState.GUESTS
	elif kind == "expansion":
		compatible = VillageExpansion.GUESTS
	var seen: Array[String] = []
	for guest: Variant in guests:
		if guest is not String or guest not in compatible or guest not in known or guest in seen:
			return false
		seen.append(guest)
	return true


static func _valid_setting(kind: String, value: Dictionary, known: Dictionary) -> bool:
	match kind:
		"visit":
			return _valid_visit(value, known)
		"rest":
			return (
				value.size() == 1
				and value.get("word") is String
				and value.word in RestCornerState.WORDS
				and value.word in known
			)
		"snack":
			return (
				value.size() == 2
				and value.get("decoration") is String
				and value.decoration in SnackState.DECORATIONS
				and _valid_food(value.get("food"), known)
			)
		"expansion":
			if value.size() != 2 or value.get("purpose") is not String:
				return false
			if value.purpose == "rest":
				return value.get("word") is String and value.word in RestCornerState.WORDS
			return value.purpose == "snack" and _valid_food(value.get("food"), known)
	return false


static func _valid_food(value: Variant, known: Dictionary) -> bool:
	return (
		value is String
		and value in SnackState.FOODS
		and LaboratoryState.known_combination(value, known)
	)


static func _valid_visit(value: Dictionary, known: Dictionary) -> bool:
	if value.size() != 5 or value.get("identity") is not Dictionary:
		return false
	if (
		value.identity.size() != 2
		or not GardenIdentity.valid_state({"patio": value.identity}, true)
	):
		return false
	var table_id: Variant = value.get("table")
	if (
		not SaveSchema.is_number(table_id)
		or float(table_id) != floorf(float(table_id))
		or float(table_id) < 1
		or float(table_id) >= 1000000
		or value.get("objects") is not Array
		or value.objects.size() > GardenLayout.MAX_OBJECTS
	):
		return false
	for object: Variant in value.objects:
		if object is not Dictionary or object.size() != 8:
			return false
	if not GardenCompositions.valid_state(
		{"patio": [{"objects": value.objects}]}, known, 1000000, GameContent.VILLAGE_SPACES
	):
		return false
	var snapshot: Dictionary = {"objects": value.objects}
	var table: Dictionary = GardenLayout.object_by_id(snapshot, int(table_id))
	if not VillageVisitState.usable_table(table):
		return false
	if (
		not SaveSchema.is_number(value.get("guest_x"))
		or not SaveSchema.is_number(value.get("guest_y"))
	):
		return false
	var table_point: Vector2 = GardenLayout.point(table)
	var gap: float = GardenLayout.footprint(table.key, int(table.orientation)).x * 0.5 + 68
	return (
		is_equal_approx(absf(float(value.guest_x) - table_point.x), gap)
		and is_equal_approx(float(value.guest_y), table_point.y)
	)
