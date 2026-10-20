@tool
extends Resource
class_name VisualEntry

@export var key: String = ""
@export var texture: Texture2D
@export var expressions: Dictionary[String, Texture2D] = {}

func expression(name: String) -> Texture2D:
	return expressions.get(name, texture)
