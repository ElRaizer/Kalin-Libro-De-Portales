extends Node

## Sólo la cinemática de regreso compone este recuerdo sobre el cuarto de Kalin.
@export var first_beat: int = 3
@export var last_beat: int = 4
@onready var moment: MemoryMoment = $UI/MemoryMoment


func _ready() -> void:
	moment.hide()
	call_deferred("_connect_story")


func _connect_story() -> void:
	if not is_inside_tree():
		return
	var story: StoryScene = get_parent() as StoryScene
	story.beat_presented.connect(_present)
	_present(story.beat_index)


func _present(index: int) -> void:
	if index < first_beat or index > last_beat:
		moment.hide()
		return
	var saved: Dictionary = GameManager.saved_scene_state("world5_farewell")
	moment.show_memory(VillageMemory.from_checkpoint(saved))
