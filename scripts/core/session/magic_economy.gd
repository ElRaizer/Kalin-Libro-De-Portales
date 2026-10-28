extends RefCounted
class_name MagicEconomy

## Política única. La sesión posee el saldo; este módulo sólo calcula contratos.
const DESIGN_PRICE: int = 10
const PREPARATION_POINTS: int = 12
const FIRST_PROJECT: String = "sharing_corner"
const FIRST_DESIGNS: Array[String] = ["mayak", "chich"]


static func empty_state() -> Dictionary:
	return {"awards": {}, "designs": [], "preparations": [], "built": false}


static func design_words() -> Array[String]:
	var words: Array[String] = []
	for id: String in CombinationCatalog.targets():
		for word: String in id.split("|", false):
			if word not in words:
				words.append(word)
	return words


static func valid_state(value: Variant) -> bool:
	if value is not Dictionary:
		return false
	if value.get("awards") is not Dictionary or value.get("built") is not bool:
		return false
	for field: String in ["designs", "preparations"]:
		if value.get(field) is not Array:
			return false
		var seen: Array[String] = []
		for item: Variant in value[field]:
			if item is not String or item in seen:
				return false
			if field == "designs" and item not in design_words():
				return false
			if field == "preparations" and item != FIRST_PROJECT:
				return false
			seen.append(item)
	for word: Variant in value.awards:
		if word is not String or word not in VocabularyCatalog.learnable_keys():
			return false
		var number: Variant = value.awards[word]
		if (
			not SaveSchema.is_number(number)
			or float(number) != floor(float(number))
			or int(number) not in [4, 6, 10]
		):
			return false
	if not value.preparations.is_empty():
		for word: String in FIRST_DESIGNS:
			if int(value.awards.get(word, 0)) < 4:
				return false
	if not value.designs.is_empty() and FIRST_PROJECT not in value.preparations:
		return false
	if value.built:
		for word: String in FIRST_DESIGNS:
			if word not in value.designs:
				return false
	return not value.built or FIRST_PROJECT in value.preparations


static func reward(phase: String, supported: bool, evidence: Dictionary) -> int:
	if phase not in ["practice", "recognition", "reconstruction", "recall"]:
		return 0
	var support: int = 0
	if evidence.get("support_level") is int:
		support = clampi(evidence.support_level, 0, 2)
	elif supported:
		support = 2
	if phase in ["practice", "recognition"]:
		support = 2
	if phase == "reconstruction" and support == 0:
		support = 2
	return [10, 6, 4][support]


static func can_purchase(state: Dictionary, word: String, known: Dictionary, points: int) -> bool:
	return (
		word in design_words()
		and word in known
		and word not in state.designs
		and points >= DESIGN_PRICE
		and (state.built or word in FIRST_DESIGNS)
		and FIRST_PROJECT in state.preparations
	)


static func can_build(state: Dictionary, id: String, known: Dictionary) -> bool:
	if not CombinationCatalog.allowed(id):
		return false
	for word: String in id.split("|", false):
		if word not in known or word not in state.designs:
			return false
	return true
