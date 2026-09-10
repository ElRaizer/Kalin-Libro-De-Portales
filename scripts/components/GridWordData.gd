@tool
extends Resource
class_name GridWordData

## Datos editables de una palabra o concepto dentro de GridBoard.
## La textura es opcional: cuando no existe, la ficha de origen se presenta
## como texto. Los textos vacíos usan maya_word/spanish_word como respaldo.

@export_category("Contenido educativo")
@export var maya_word: String = ""
@export var spanish_word: String = ""
@export_multiline var phrase: String = ""
@export_multiline var explanation: String = ""

@export_category("Presentación")
@export var sprite: Texture2D
@export_multiline var start_text: String = ""
@export_multiline var destination_text: String = ""
@export var color: Color = Color.WHITE

@export_category("Posición en el tablero")
@export var start_cell: Vector2i = Vector2i.ZERO
@export var destination_cell: Vector2i = Vector2i(8, 0)

func get_start_text() -> String:
	return start_text if not start_text.is_empty() else maya_word

func get_destination_text() -> String:
	return destination_text if not destination_text.is_empty() else spanish_word
