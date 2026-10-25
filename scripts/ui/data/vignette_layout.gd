@tool
extends Resource
class_name VignetteLayout

@export_enum("camino", "casa", "tamano", "hambre", "portal") var situation: String = "camino"
@export var actor_word: String = "Peek'"
@export var unsolved_texture: Texture2D
@export var solved_texture: Texture2D
@export var position: Vector2
@export var size: Vector2
@export var solved_position: Vector2
@export var solved_size: Vector2
