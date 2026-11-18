extends Resource
class_name RestCornerProfile

@export var title: String = "Un lugar para descansar"
@export_multiline var homecoming: String = ""
@export_multiline var invitation: String = ""
@export_multiline var proposal: String = ""
@export var options: Array[RestCornerOption] = []
@export_multiline var reward_line: String = ""
@export var garland: Texture2D
@export var garland_position: Vector2 = Vector2(400, 320)


func intro_lines() -> Array[String]:
	return [homecoming, invitation, proposal]


func option_for(word: String) -> RestCornerOption:
	for option: RestCornerOption in options:
		if option != null and option.word == word:
			return option
	return null


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	if options.size() != RestCornerState.WORDS.size() or garland == null:
		issues.append("Configura las tres alternativas y la guirnalda del rincón.")
	if (
		not garland_position.is_finite()
		or title.strip_edges().is_empty()
		or reward_line.strip_edges().is_empty()
	):
		issues.append("Configura el título, la recompensa y una posición finita.")
	for line: String in intro_lines():
		if line.strip_edges().is_empty() or line.length() > 180:
			issues.append("Cada momento de la invitación necesita un texto breve.")
	for word: String in RestCornerState.WORDS:
		var option: RestCornerOption = option_for(word)
		if option == null:
			issues.append("Falta la alternativa " + word)
			continue
		for line: String in [
			option.title,
			option.description,
			option.aak_reaction,
			option.miis_reaction,
			option.return_line
		]:
			if line.strip_edges().is_empty() or line.length() > 180:
				issues.append("Revisa los textos breves de " + word)
	return issues
