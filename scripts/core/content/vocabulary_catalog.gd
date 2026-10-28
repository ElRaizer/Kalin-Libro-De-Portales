extends RefCounted
class_name VocabularyCatalog

## Consultas puras del catálogo; nunca devuelven sus diccionarios por referencia.


static func resolve(word: String) -> String:
	if word in GameContent.VOCABULARY:
		return word
	var normalized: String = strip_accents(word).to_lower()
	for key: String in GameContent.VOCABULARY:
		if strip_accents(key).to_lower() == normalized:
			return key
	return ""


static func strip_accents(value: String) -> String:
	var result: String = value
	var pairs: Dictionary = {
		"á": "a",
		"é": "e",
		"í": "i",
		"ó": "o",
		"ú": "u",
		"ü": "u",
		"Á": "A",
		"É": "E",
		"Í": "I",
		"Ó": "O",
		"Ú": "U",
		"Ü": "U",
		"ñ": "n",
		"Ñ": "N",
	}
	for accented: String in pairs:
		result = result.replace(accented, pairs[accented])
	return result


static func audio_filename(maya_word: String) -> String:
	var key: String = resolve(maya_word)
	var source: String = key if key != "" else maya_word
	return strip_accents(source).replace("'", "").replace("’", "").replace(" ", "_") + ".ogg"


static func learnable_keys() -> Array[String]:
	var keys: Array[String] = []
	for maya_word: String in GameContent.VOCABULARY:
		if maya_word not in GameContent.FUTURE_VOCABULARY:
			keys.append(maya_word)
	return keys


static func entry(word: String) -> Dictionary:
	var key: String = resolve(word)
	return {} if key.is_empty() else GameContent.VOCABULARY[key].duplicate(true)


## Sección del Libro de Hechizos: `book_category` cuando la entrada la define
## (por ejemplo, los números) y, si no, el mundo donde se aprende.
static func book_category(word: String) -> int:
	var data: Dictionary = entry(word)
	return int(data.get("book_category", data.get("world", 0)))


## Valor numérico de una entrada que es un número (0 si no lo es).
static func number_value(word: String) -> int:
	return int(entry(word).get("value", 0))


static func level_info(scene_key: String) -> Dictionary:
	for level: Dictionary in GameContent.LEVEL_ORDER:
		if level.scene_key == scene_key:
			return level.duplicate(true)
	return {}
