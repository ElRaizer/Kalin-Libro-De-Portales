@tool
extends Resource
class_name VillageTask

@export var requester: String = ""
@export_multiline var request: String = ""
@export var item: String = ""
@export var quality: String = ""
@export var success: String = ""


func words() -> Array[String]:
	var result: Array[String] = [item]
	if not quality.is_empty():
		result.append(quality)
	return result
