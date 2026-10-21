@tool
extends Resource
class_name ExerciseEntry

## Los campos del inspector son los mismos que consume la lógica del ejercicio.
@export_category("Palabra")
@export var maya: String = ""
@export var spanish: String = ""
# Compatibilidad con recursos antiguos: la presentación actual usa el catálogo
# y los estilos de las escenas. Estos campos ya no controlan la apariencia.
@export_storage var emoji: String = ""
@export_storage var symbol: String = ""
@export_category("Petición")
@export var animal: String = ""
@export var animal_spanish: String = ""
@export var sprite: Texture2D
@export_multiline var request: String = ""
@export_storage var color: Color = Color.WHITE
@export_category("Frase")
@export var noun: String = ""
@export var adjective: String = ""
@export var food: String = ""
@export var modifier: String = ""
@export var phrase: String = ""
@export var translation: String = ""
@export_category("Repaso")
@export var section: String = ""
@export_multiline var prompt: String = ""
@export var clue: String = ""
@export var correct: String = ""
@export var options: Array[String] = []
@export var learn: String = ""
