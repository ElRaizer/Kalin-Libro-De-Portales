extends RefCounted
class_name CombinationCatalog

## Lista cerrada: sólo las 28 combinaciones directas acordadas. Sin inferir sinónimos.
const ROWS := [
	["mayak", "mejen", "Mesa pequeña", "una mesa pequeña"],
	["mayak", "nojoch", "Mesa grande", "una mesa grande"],
	["mayak", "Jats'uts", "Mesa bonita", "una mesa bonita"],
	["mayak", "chich", "Mesa fuerte", "una mesa fuerte"],
	["k'áanche'", "mejen", "Silla pequeña", "una silla pequeña"],
	["k'áanche'", "nojoch", "Silla grande", "una silla grande"],
	["k'áanche'", "Jats'uts", "Silla bonita", "una silla bonita"],
	["k'áanche'", "chich", "Silla fuerte", "una silla fuerte"],
	["k'áan", "mejen", "Hamaca pequeña", "una hamaca pequeña"],
	["k'áan", "nojoch", "Hamaca grande", "una hamaca grande"],
	["k'áan", "Jats'uts", "Hamaca bonita", "una hamaca bonita"],
	["k'áan", "chich", "Hamaca fuerte", "una hamaca fuerte"],
	["lak", "mejen", "Plato pequeño", "un plato pequeño"],
	["lak", "nojoch", "Plato grande", "un plato grande"],
	["lak", "Jats'uts", "Plato bonito", "un plato bonito"],
	["ja'as", "mejen", "Plátano pequeño", "un plátano pequeño"],
	["ja'as", "nojoch", "Plátano grande", "un plátano grande"],
	["ja'as", "Jats'uts", "Plátano bonito", "un plátano bonito"],
	["ja'as", "ki'", "Plátano delicioso", "un plátano delicioso"],
	["ich", "mejen", "Fruta pequeña", "una fruta pequeña"],
	["ich", "nojoch", "Fruta grande", "una fruta grande"],
	["ich", "Jats'uts", "Fruta bonita", "una fruta bonita"],
	["ich", "ki'", "Fruta deliciosa", "una fruta deliciosa"],
	["K'úum", "mejen", "Calabaza pequeña", "una calabaza pequeña"],
	["K'úum", "nojoch", "Calabaza grande", "una calabaza grande"],
	["K'úum", "Jats'uts", "Calabaza bonita", "una calabaza bonita"],
	["K'úum", "ki'", "Calabaza deliciosa", "una calabaza deliciosa"],
	["janal", "ki'", "Comida deliciosa", "comida deliciosa"],
]
const BASICS := {"mayak": "una mesa", "k'áanche'": "una silla", "k'áan": "una hamaca", "lak": "un plato", "janal": "comida", "ja'": "agua", "ja'as": "un plátano", "ich": "fruta", "K'úum": "una calabaza"}
const FURNITURE: Array[String] = ["mayak", "k'áanche'", "k'áan", "lak", "janal"]
const SOLIDS: Array[String] = ["ja'as", "ich", "K'úum"]

static func key(word: String, quality: String = "") -> String:
	return word + "|" + quality

static func row(id: String) -> Array:
	for entry: Array in ROWS:
		if key(entry[0], entry[1]) == id:
			return entry
	return []

static func allowed(id: String, allow_basic := true) -> bool:
	var parts := id.split("|")
	return parts.size() == 2 and ((allow_basic and parts[1].is_empty() and parts[0] in BASICS) or not row(id).is_empty())

static func targets() -> Dictionary:
	var result := {}
	for word: String in BASICS:
		result[key(word)] = BASICS[word]
	for entry: Array in ROWS:
		result[key(entry[0], entry[1])] = entry[3]
	return result

static func stage(world: int, basics_only := false) -> Array[String]:
	var result: Array[String] = []
	for id: String in targets():
		var parts := id.split("|")
		if (world < 4 and parts[0] not in FURNITURE) or ((world == 2 or basics_only) and not parts[1].is_empty()):
			continue
		result.append(id)
	return result

static func apply_entry(entry: ExerciseEntry, id: String, food := false) -> void:
	var parts := id.split("|")
	var description := row(id)
	entry.noun = parts[0]
	entry.adjective = parts[1]
	entry.food = parts[0]
	entry.modifier = parts[1]
	entry.translation = str(description[2]) if not description.is_empty() else str(GameContent.VOCABULARY[parts[0]].spanish)
	entry.phrase = "In k'a'at " + parts[0] + (" " + parts[1] if not parts[1].is_empty() else "") if food else parts[0] + (" · " + parts[1] if not parts[1].is_empty() else "")

static func apply_task(task: VillageTask, id: String) -> void:
	var parts := id.split("|")
	task.item = parts[0]
	task.quality = parts[1]
