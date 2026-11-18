extends Resource
class_name SnackProfile

@export var title: String = "Una merienda junto al estanque"
@export_multiline
var invitation: String = "Kay y Ch'íich' proponen compartir una merienda. Elige a quién invitar y qué preparar. Ensayar y reunirse es gratis."
@export var guest_reactions: Dictionary[String, String] = {
	"Kay":
	"Kay: Gracias por traer la merienda al agua. Puedo quedarme en mi estanque y compartir contigo.",
	"Ch'íich'":
	"Ch'íich': Mi cuenco está listo en la orilla. Aquí podemos reunirnos sin estorbarnos."
}
@export var flower_border: Texture2D = preload("res://Arte/aldea/garden_border.svg")
@export var gathering_size: Vector2 = Vector2(1000, 280)


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	if title.is_empty() or invitation.is_empty() or flower_border == null:
		issues.append("Configura la invitación, el título y el adorno de la merienda.")
	for guest: String in SnackState.GUESTS:
		if str(guest_reactions.get(guest, "")).is_empty():
			issues.append("Configura una reacción por invitado.")
	return issues
