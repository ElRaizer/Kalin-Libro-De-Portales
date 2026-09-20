extends Panel
class_name LevelHeader

signal menu_pressed
signal book_pressed

@export var title: String = "Nivel"

@onready var title_label: Label = $Bar/TitleLabel
@onready var magic_label: Label = $Bar/MagicLabel
@onready var menu_button: Button = $Bar/MenuButton
@onready var book_button: Button = $Bar/BookButton

func _ready() -> void:
	title_label.text = title
	menu_button.pressed.connect(menu_pressed.emit)
	book_button.pressed.connect(book_pressed.emit)
	GameManager.magic_points_changed.connect(set_magic_points)
	set_magic_points(GameManager.magic_points)

func set_title(value: String) -> void:
	title = value
	if is_node_ready():
		title_label.text = value

func set_magic_points(value: int) -> void:
	magic_label.text = "%d puntos mágicos" % value

