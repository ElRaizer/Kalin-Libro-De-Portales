extends Resource
class_name ScreenLayoutProfile

## Rectángulos del modo compacto, en las coordenadas 1280 × 720 del editor.
@export var rectangles: Dictionary = {}
@export var font_sizes: Dictionary = {}
@export var hidden: Array[NodePath] = []
@export var minimum_body_font: int = 26
## Cero conserva la altura de autor. Las fases breves dejan visible el escenario.
@export var recall_height: float = 0.0
@export var single_recall_height: float = 0.0
@export var writing_height: float = 0.0
@export var single_writing_height: float = 0.0
