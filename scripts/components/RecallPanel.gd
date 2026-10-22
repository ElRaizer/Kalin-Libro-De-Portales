extends PanelContainer
class_name RecallPanel

signal submitted
signal practice_requested
@export var external_submit := false

@onready var first: LineEdit = $Margin/Content/Fields/First/Input
@onready var second: LineEdit = $Margin/Content/Fields/Second/Input
@onready var second_box: VBoxContainer = $Margin/Content/Fields/Second
@onready var caption: Label = $Margin/Content/Hint
var _active: LineEdit

func _ready() -> void:
	first.text_submitted.connect(func(_text: String):
		if second_box.visible:
			second.grab_focus()
		else:
			submitted.emit()
	)
	second.text_submitted.connect(func(_text: String): submitted.emit())
	first.focus_entered.connect(func(): _active = first)
	second.focus_entered.connect(func(): _active = second)
	$Margin/Content/Actions/Practice.pressed.connect(practice_requested.emit)
	$Margin/Content/Actions/Submit.visible = not external_submit
	$Margin/Content/Actions/Submit.pressed.connect(submitted.emit)
	for button: Button in $Margin/Content/Letters.get_children():
		button.pressed.connect(_insert_letter.bind(button.text))

func configure(labels: Array) -> void:
	$Margin/Content/Fields/First/Name.text = labels[0]
	second_box.visible = labels.size() > 1
	if second_box.visible:
		$Margin/Content/Fields/Second/Name.text = labels[1]
	first.clear()
	second.clear()
	_active = first
	caption.text = "Escribe en maya. Si necesitas ayuda, puedes volver a practicar."
	show()
	call_deferred("_focus_first")

func _focus_first() -> void:
	if is_inside_tree() and first.is_visible_in_tree():
		first.grab_focus()

func values() -> Array[String]:
	return [first.text.strip_edges(), second.text.strip_edges()]

func _insert_letter(letter: String) -> void:
	if not is_instance_valid(_active):
		_active = first
	_active.insert_text_at_caret(letter)
	_active.grab_focus()

## La grafía sin acentos permite continuar, con la corrección visible y marcada
## como práctica apoyada. Nunca cuenta como recuerdo independiente.
static func match_word(typed: String, expected: String) -> Dictionary:
	var actual := " ".join(typed.strip_edges().replace("’", "'").replace("·", " ").to_lower().split(" ", false))
	var wanted := " ".join(expected.replace("·", " ").to_lower().split(" ", false))
	if actual == wanted:
		return {"correct": true, "supported": false, "word": expected}
	var normalized := actual
	var normalized_expected := wanted
	for pair: Array in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"]]:
		normalized = normalized.replace(pair[0], pair[1])
		normalized_expected = normalized_expected.replace(pair[0], pair[1])
	return {"correct": normalized == normalized_expected, "supported": normalized == normalized_expected, "word": expected if normalized == normalized_expected else typed}
