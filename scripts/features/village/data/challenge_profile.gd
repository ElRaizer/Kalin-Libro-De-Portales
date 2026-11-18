extends Resource
class_name ChallengeProfile

@export_multiline
var welcome: String = "Una visita trae una pequeña petición. Puedes ayudar a tu ritmo."
@export_multiline
var animal_result: String = "Su amigo ya tiene nombre. Ahora pueden encontrarse en la aldea."
@export_multiline
var greeting_result: String = "La conversación ya puede empezar. ¡Qué gusto volver a encontrarnos!"
@export_multiline
var object_result: String = "El pedido está listo para compartir. Tu visitante puede disfrutarlo."
@export_multiline
var quality_result: String = "El taller ya sabe cómo preparar la pieza. Gracias por describirla."


func outcome(answers: Array[String]) -> String:
	var world: int = int(VocabularyCatalog.entry(answers[0]).world)
	if world == 1:
		return animal_result
	if world == 5:
		return greeting_result
	if world == 3:
		return quality_result
	return object_result
