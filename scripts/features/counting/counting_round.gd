@tool
extends Resource
class_name CountingRound

## Una ronda del tianguis de los números. Las frases completas se guardan como
## texto revisable: la morfología maya (número + clasificador) no se construye
## desde el código.

enum Kind {
	STELE,  ## Conocer los numerales tallados en la estela.
	BUILD,  ## Formar el número con granos de cacao y varitas.
	MARKET,  ## Llenar la canasta con la cantidad pedida (cosas, -p'éel).
	FRIENDS,  ## Contar a los amigos que llegaron (animales, -túul).
	RECALL,  ## Escribir de memoria cuántos hay y qué son.
}

@export var kind: Kind = Kind.BUILD
## Con apoyo: muestra la traducción y cuenta como práctica.
@export var guided: bool = false

@export_category("Número")
## Clave del vocabulario canónico con `value` (por ejemplo, "óox").
@export var number: String = ""
## Sólo para la estela: los números que se presentan.
@export var numbers: Array[String] = []

@export_category("Petición")
## Animal que pide o que llega (clave del vocabulario).
@export var requester: String = ""
## Lo que se cuenta: una cosa o un animal del vocabulario.
@export var item: String = ""
## En el tianguis, la otra cosa del puesto que no se pidió.
@export var distractor: String = ""
## Petición en español; sólo se muestra en las rondas con apoyo.
@export_multiline var request: String = ""

@export_category("Frase")
## Frase maya completa, por ejemplo "In k'a'at óoxp'éel ja'as".
@export var phrase: String = ""
## Número con su clasificador, por ejemplo "óoxp'éel" o "kantúul".
@export var answer: String = ""
@export var translation: String = ""
## Respuestas para elegir (en número par, como el resto del juego).
@export var options: Array[String] = []
