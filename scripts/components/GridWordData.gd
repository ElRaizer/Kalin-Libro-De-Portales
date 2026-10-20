@tool
extends Resource
class_name GridWordData

## Datos editables de una palabra o concepto dentro de GridBoard.
## La textura es opcional: cuando no existe, la ficha de origen se presenta
## como texto. Los textos vacíos usan maya_word/spanish_word como respaldo.

@export_category("Contenido educativo")
@export var maya_word: String = "":
	set(value):
		if maya_word != value:
			maya_word = value
			emit_changed()
@export var spanish_word: String = "":
	set(value):
		if spanish_word != value:
			spanish_word = value
			emit_changed()
@export_multiline var phrase: String = "":
	set(value):
		if phrase != value:
			phrase = value
			emit_changed()
@export_multiline var explanation: String = "":
	set(value):
		if explanation != value:
			explanation = value
			emit_changed()

@export_category("Presentación")
@export var sprite: Texture2D:
	set(value):
		if sprite != value:
			sprite = value
			emit_changed()
@export_multiline var start_text: String = "":
	set(value):
		if start_text != value:
			start_text = value
			emit_changed()
@export_multiline var destination_text: String = "":
	set(value):
		if destination_text != value:
			destination_text = value
			emit_changed()
@export var color: Color = Color.WHITE:
	set(value):
		if color != value:
			color = value
			emit_changed()

@export_category("Posición en el tablero")
@export var start_cell: Vector2i = Vector2i.ZERO:
	set(value):
		if start_cell != value:
			start_cell = value
			emit_changed()
@export var destination_cell: Vector2i = Vector2i(8, 0):
	set(value):
		if destination_cell != value:
			destination_cell = value
			emit_changed()

func get_start_text() -> String:
	return start_text if not start_text.is_empty() else maya_word

func get_destination_text() -> String:
	return destination_text if not destination_text.is_empty() else spanish_word
