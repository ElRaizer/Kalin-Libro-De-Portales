@tool
extends Resource
class_name ExerciseSet

## Contenido de autor compartido por las dos fases de un ejercicio.
@export_enum("Casa:2", "Taller:3", "Comida:4", "Portal:5") var content_world: int = 2:
	set(value):
		content_world = value
		notify_property_list_changed()
@export var objects: Array[ExerciseEntry] = []
@export var nouns: Array[ExerciseEntry] = []
@export var adjectives: Array[ExerciseEntry] = []
@export var foods: Array[ExerciseEntry] = []
@export var modifiers: Array[ExerciseEntry] = []
@export var challenges: Array[ExerciseEntry] = []

func get_configuration_issues(world: int) -> PackedStringArray:
	var issues: PackedStringArray = []
	if world != content_world:
		issues.append("El recurso de contenido pertenece a otro mundo.")
	var lists: Dictionary = {"objects": objects} if world == 2 else ({"nouns": nouns, "adjectives": adjectives, "challenges": challenges} if world == 3 else ({"foods": foods, "modifiers": modifiers, "challenges": challenges} if world == 4 else {"challenges": challenges}))
	for list_name: String in lists:
		var entries: Array = lists[list_name]
		if entries.is_empty():
			issues.append("Agrega contenido a %s." % list_name)
		for index: int in range(entries.size()):
			var entry := entries[index] as ExerciseEntry
			if entry == null:
				issues.append("%s[%d] no tiene un recurso asignado." % [list_name, index])
				continue
			if list_name == "objects" or list_name == "challenges" and world in [3, 4]:
				if entry.sprite == null:
					issues.append("Asigna el retrato de %s[%d]." % [list_name, index])
			if list_name == "challenges" and world == 5:
				if entry.correct.is_empty() or entry.correct not in entry.options or entry.options.size() < 2:
					issues.append("El reto %d necesita varias opciones y su respuesta correcta." % (index + 1))
			elif list_name != "challenges" and list_name != "modifiers" and entry.maya.is_empty():
				issues.append("%s[%d] no tiene una palabra maya." % [list_name, index])
			if list_name == "challenges" and world in [3, 4]:
				var first := entry.noun if world == 3 else entry.food
				var second := entry.adjective if world == 3 else entry.modifier
				if not _contains(nouns if world == 3 else foods, first):
					issues.append("El reto %d usa una palabra que falta entre las opciones." % (index + 1))
				if not _contains(adjectives if world == 3 else modifiers, second):
					issues.append("El reto %d usa una cualidad que falta entre las opciones." % (index + 1))
				if entry.phrase.is_empty() or entry.translation.is_empty():
					issues.append("Completa la frase y traducción del reto %d." % (index + 1))
	return issues

func _validate_property(property: Dictionary) -> void:
	var fields: Dictionary = {2: ["objects"], 3: ["nouns", "adjectives", "challenges"], 4: ["foods", "modifiers", "challenges"], 5: ["challenges"]}
	if property.name in ["objects", "nouns", "adjectives", "foods", "modifiers", "challenges"] and property.name not in fields.get(content_world, []):
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _contains(entries: Array[ExerciseEntry], word: String) -> bool:
	for entry: ExerciseEntry in entries:
		if entry != null and entry.maya == word:
			return true
	return false
