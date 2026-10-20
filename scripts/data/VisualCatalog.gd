@tool
extends Resource
class_name VisualCatalog

## Referencias explícitas: el arte y sus expresiones se sustituyen en el inspector.
@export var sparkle_scene: PackedScene
@export var reaction_badge_scene: PackedScene
@export var entries: Array[VisualEntry] = []
@export var decorations: Dictionary[String, Texture2D] = {}

func find_entry(key: String) -> VisualEntry:
	for entry: VisualEntry in entries:
		if entry != null and entry.key == key:
			return entry
	return null

func texture_for(key: String) -> Texture2D:
	var entry := find_entry(key)
	return entry.texture if entry else decorations.get(key)

func expression_for(key: String, expression: String) -> Texture2D:
	var entry := find_entry(key)
	return entry.expression(expression) if entry else null
