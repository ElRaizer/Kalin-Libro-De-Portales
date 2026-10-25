extends RefCounted
class_name VillageTaskVariation

## Las tres parejas de necesidades se eligen juntas. Se conserva la preferencia
## aleatoria/de aprendizaje siempre que no repita un objeto en la misma visita.
## Las peticiones ya conocidas o resueltas de un guardado quedan bloqueadas.
static func distinct(choices: Array, preferred: Array[int], locked: Array[int] = []) -> Array[int]:
	var best := preferred.duplicate()
	var best_score := 1000000
	for mask: int in range(1 << choices.size()):
		var candidate: Array[int] = []
		var items: Array[String] = []
		var changes := 0
		var valid := true
		for index: int in range(choices.size()):
			var option := preferred[index] ^ ((mask >> index) & 1)
			if option >= choices[index].size() or index in locked and option != preferred[index]:
				valid = false
				break
			candidate.append(option)
			changes += int(option != preferred[index])
			var task: VillageTask = choices[index][option]
			if task.item not in items:
				items.append(task.item)
		if not valid:
			continue
		var score := (choices.size() - items.size()) * 100 + changes
		if score < best_score:
			best = candidate
			best_score = score
	return best
