@tool
extends Resource
class_name VillageTask

@export var requester := ""
@export_multiline var request := ""
@export var item := ""
@export var quality := ""
@export var success := ""

func words() -> Array[String]:
	var result: Array[String] = [item]
	if not quality.is_empty():
		result.append(quality)
	return result
