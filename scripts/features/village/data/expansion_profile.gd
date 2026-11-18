extends Resource
class_name ExpansionProfile

@export var title: String = "La aldea que imaginamos"
@export_multiline
var invitation: String = "Ma'ax: En la orilla hay un claro para compartir. Probemos una pausa y una merienda; tú eliges cómo estrenarlo. Después podremos cambiarlo sin perder lo vivido."
@export var rest_word: String = "k'áanche'"
@export var purpose_titles: Dictionary[String, String] = {
	"rest": "Descanso compartido", "snack": "Reunión de merienda"
}
@export var descriptions: Dictionary[String, String] = {
	"rest": "Asientos para hacer una pausa y conversar con quienes invites.",
	"snack": "Un lugar para compartir la merienda que ya preparaste, sin volver a contar ni pagar."
}
@export var reactions: Dictionary[String, String] = {
	"Ma'ax": "Ma'ax: ¡Ahora la orilla tiene otro lugar para encontrarnos!",
	"Áak": "Áak: Podemos hacer una pausa aquí y volver cuando queramos.",
	"Miis": "Miis: Me gusta que podamos cambiar el lugar y guardar lo que vivimos."
}
@export var ground_color: Color = Color("c9d7a0")
@export var border: Texture2D = preload("res://Arte/aldea/garden_border.svg")


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	if title.strip_edges().is_empty() or invitation.strip_edges().is_empty() or border == null:
		issues.append("Configura título, invitación e ilustración de la ampliación.")
	if rest_word not in RestCornerState.WORDS:
		issues.append("El descanso debe utilizar un objeto de descanso vigente.")
	for purpose: String in VillageExpansion.PURPOSES:
		if purpose_titles.get(purpose, "").is_empty() or descriptions.get(purpose, "").is_empty():
			issues.append("Configura los dos propósitos de la ampliación.")
	for guest: String in VillageExpansion.GUESTS:
		if reactions.get(guest, "").is_empty():
			issues.append("Configura la reacción de cada invitado.")
	return issues
