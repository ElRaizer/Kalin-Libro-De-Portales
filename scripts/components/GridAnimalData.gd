@tool
extends Resource
class_name GridAnimalData

## Datos editables de una ficha para GridBoard.
## Crea un recurso desde el Inspector para cada animal/palabra del nivel.

@export_category("Identidad")
@export var maya_word: String = ""
@export var spanish_word: String = ""
@export_multiline var phrase: String = ""

@export_category("Presentación")
@export var sprite: Texture2D
@export var color: Color = Color.WHITE

@export_category("Posición en el tablero")
@export var start_cell: Vector2i = Vector2i.ZERO
@export var destination_cell: Vector2i = Vector2i(8, 0)
