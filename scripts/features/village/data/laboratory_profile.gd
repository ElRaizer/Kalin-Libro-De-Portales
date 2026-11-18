extends Resource
class_name LaboratoryProfile

## Reducir la capacidad no borra favoritos existentes; impide añadir otros.
@export_range(1, 12) var favorite_limit: int = 6
