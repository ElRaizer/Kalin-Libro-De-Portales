extends Control
class_name VillageGathering

signal closed
var _previous_focus: WeakRef
@onready var close_button: Button = $Panel/Close


func _ready() -> void:
	hide()
	close_button.pressed.connect(close_gathering)


func show_gathering(tasks: Array[VillageTask], title: String, origin: Control) -> void:
	$Panel/Title.text = title
	_previous_focus = weakref(origin)
	for index: int in range(3):
		var group: Node2D = $Panel/Stage.get_node("Friend%d" % index)
		group.visible = index < tasks.size()
		if not group.visible:
			continue
		var task: VillageTask = tasks[index]
		var actor: Sprite2D = group.get_node("Actor")
		var art: MeaningIllustration = group.get_node("Object")
		actor.texture = VillageUseArt.ACTORS.get(
			task.requester, GameManager.get_visual_texture(task.requester)
		)
		var extent: Vector2i = actor.texture.get_image().get_used_rect().size
		actor.scale = Vector2.ONE * 148.0 / maxf(1.0, extent.y)
		art.show_meaning(task.item, task.quality)
		var motion: VillageUseMotion = VillageUseMotion.attach(
			actor, art, task.item, task.requester
		)
		motion.receive()
	show()
	close_button.grab_focus()


func close_gathering() -> void:
	if not visible:
		return
	hide()
	var origin: Control = _previous_focus.get_ref() as Control if _previous_focus != null else null
	if is_instance_valid(origin) and origin.is_visible_in_tree():
		origin.grab_focus()
	_previous_focus = null
	closed.emit()
