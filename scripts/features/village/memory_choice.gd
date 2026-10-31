extends Control
class_name MemoryChoice

signal selected(memory: Dictionary)
signal confirmed
signal closed
var _options: Array[Dictionary] = []
const SHORT_LABELS: Dictionary[String, String] = {
	"Preparar la fiesta": "La fiesta",
	"Compartir la comida": "La comida",
	"Desear buen viaje": "Buen viaje"
}


func _ready() -> void:
	hide()
	for index: int in range(3):
		($Panel/Options.get_child(index) as Button).pressed.connect(choose.bind(index))
	$Panel/Confirm.pressed.connect(func(): confirmed.emit())
	$Panel/Close.pressed.connect(close_choice)


func open_choice(options: Array[Dictionary], current: Dictionary) -> void:
	_options = options.duplicate(true)
	for index: int in range(3):
		var button: Button = $Panel/Options.get_child(index) as Button
		button.text = SHORT_LABELS.get(options[index].title, options[index].title)
		button.tooltip_text = options[index].title
		button.set_pressed_no_signal(current.get("kind", "") == options[index].kind)
	$Moment.show_memory(current)
	$Panel/Confirm.disabled = current.is_empty()
	$Panel/Hint.text = "Elige lo que quieres llevar en tu libro. Todos son recuerdos tuyos."
	show()
	($Panel/Options.get_child(0) as Button).grab_focus()


func choose(index: int) -> void:
	if not visible or index not in range(_options.size()):
		return
	for cursor: int in range(3):
		($Panel/Options.get_child(cursor) as Button).set_pressed_no_signal(cursor == index)
	$Moment.show_memory(_options[index])
	$Panel/Confirm.disabled = false
	$Panel/Hint.text = "Me llevaré este momento. También lo veré al llegar a casa."
	selected.emit(_options[index].duplicate(true))


func close_choice() -> void:
	hide()
	closed.emit()
