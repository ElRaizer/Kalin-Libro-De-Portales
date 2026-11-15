extends RefCounted
class_name QualityCue

## Apoyos visuales de propiedades, sin introducir otro sustantivo en la tarjeta.
const ICONS: Dictionary[String, Texture2D] = {
	"nojoch": preload("res://Arte/ui/quality_large.svg"),
	"mejen": preload("res://Arte/ui/quality_small.svg"),
	"chich": preload("res://Arte/ui/quality_strong.svg"),
	"Jats'uts": preload("res://Arte/ui/quality_pretty.svg"),
	"ki'": preload("res://Arte/ui/quality_tasty.svg")
}


static func texture_for(word: String) -> Texture2D:
	return ICONS.get(word)
