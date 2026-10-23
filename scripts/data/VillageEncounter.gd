extends Resource
class_name VillageEncounter

## Una necesidad y tres hechizos visibles en el escenario. Es práctica contextual,
## nunca evidencia de recuerdo libre: se ven palabras e ilustraciones.
@export var task: VillageTask
@export var choices: Array[ExerciseEntry] = []

func get_configuration_issues() -> PackedStringArray:
	var issues := PackedStringArray()
	if task == null:
		return PackedStringArray(["Asigna la necesidad del personaje."])
	if task.request.is_empty() or task.success.is_empty():
		issues.append("La necesidad y la reacción necesitan texto.")
	if task.requester not in GameContent.VOCABULARY:
		issues.append("El personaje no pertenece al catálogo.")
	if choices.size() != 3:
		issues.append("Cada encuentro necesita tres hechizos.")
	var found := false
	var seen: Array[String] = []
	for choice: ExerciseEntry in choices:
		if choice == null:
			issues.append("Hay un hechizo sin configurar.")
			continue
		var key := choice.noun + ":" + choice.adjective
		if key in seen:
			issues.append("Los hechizos deben ofrecer elecciones distintas.")
		seen.append(key)
		if choice.noun not in GameContent.VOCABULARY or (not choice.adjective.is_empty() and choice.adjective not in GameContent.VOCABULARY):
			issues.append("Un hechizo usa palabras fuera del catálogo.")
		found = found or choice.noun == task.item and choice.adjective == task.quality
	if not found:
		issues.append("Incluye un hechizo que resuelva la necesidad.")
	return issues
