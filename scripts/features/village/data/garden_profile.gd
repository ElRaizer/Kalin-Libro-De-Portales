extends Resource
class_name GardenProfile

@export_range(1, 2) var composition_slots: int = 2
@export var sign_texture: Texture2D
@export var border_texture: Texture2D
@export var sign_rect: Rect2 = Rect2(450, 160, 340, 128)
@export var name_rect: Rect2 = Rect2(466, 168, 308, 80)
@export var border_rect: Rect2 = Rect2(222, 340, 816, 208)
@export var decoration_titles: Dictionary[String, String] = {
	"sign": "Letrero de bienvenida",
	"border": "Borde de flores",
	"gathering": "Guirnalda de reunión"
}


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	if composition_slots < 1 or composition_slots > GardenCompositions.MAX_SLOTS:
		issues.append("Configura uno o dos espacios por parcela.")
	if sign_texture == null or border_texture == null:
		issues.append("Configura las ilustraciones del letrero y del borde.")
	for rectangle: Rect2 in [sign_rect, name_rect, border_rect]:
		if (
			not rectangle.position.is_finite()
			or not rectangle.size.is_finite()
			or rectangle.size.x <= 0
			or rectangle.size.y <= 0
		):
			issues.append("Los adornos necesitan rectángulos finitos de tamaño positivo.")
	for id: String in GardenIdentity.DECORATIONS:
		if str(decoration_titles.get(id, "")).strip_edges().is_empty():
			issues.append("Configura el nombre de cada adorno.")
	return issues
