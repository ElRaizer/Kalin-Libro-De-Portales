extends Node

## Sólo la cinemática de regreso compone este recuerdo sobre el cuarto de Kalin.
@export var first_beat: int = 3
@export var last_beat: int = 4
@export var drawing_beat: int = 5
@export var completed_drawing: TextureRect
@onready var moment: MemoryMoment = $UI/MemoryMoment
var _drawing_tween: Tween
var _drawing_alpha: float = 1.0


func _ready() -> void:
	moment.hide()
	if completed_drawing != null:
		_drawing_alpha = completed_drawing.modulate.a
		completed_drawing.hide()
	add_to_group("comfort_visuals")
	call_deferred("_connect_story")


func _connect_story() -> void:
	if not is_inside_tree():
		return
	var story: StoryScene = get_parent() as StoryScene
	story.beat_presented.connect(_on_beat_presented)
	# El momento guardado ya ocurrió: su imagen se reconstruye sin repetir la llegada.
	_present(story.beat_index, true)


func _on_beat_presented(index: int) -> void:
	_present(index, false)


func _present(index: int, immediate: bool) -> void:
	if _drawing_tween:
		_drawing_tween.kill()
	if completed_drawing != null:
		completed_drawing.visible = index >= drawing_beat
		completed_drawing.modulate.a = _drawing_alpha
		if completed_drawing.visible and not immediate and not AccessibilityManager.reduced_motion:
			completed_drawing.modulate.a = 0.0
			_drawing_tween = create_tween()
			_drawing_tween.tween_property(completed_drawing, "modulate:a", _drawing_alpha, 0.9)
	if index < first_beat or index > last_beat:
		moment.hide()
		return
	var saved: Dictionary = GameManager.saved_scene_state("world5_farewell")
	moment.show_memory(VillageMemory.from_checkpoint(saved))


func apply_comfort_settings() -> void:
	if AccessibilityManager.reduced_motion and completed_drawing != null:
		if _drawing_tween:
			_drawing_tween.kill()
		completed_drawing.modulate.a = _drawing_alpha
