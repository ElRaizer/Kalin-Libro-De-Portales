## Level1.gd — Controlador de interfaz para Sak Beh.
## GridBoard contiene el tablero, el arrastre y las rutas; este script solo
## coordina diálogo, progreso, puntos y navegación del nivel.
extends Node2D

var _completing: bool = false
var _dialogue_open: bool = false

@onready var grid_board: GridBoard = $GridBoard
@onready var dialogue: Panel = $UI/DialoguePanel
@onready var dlg_phrase: Label = $UI/DialoguePanel/VBox/Phrase
@onready var dlg_hint: Label = $UI/DialoguePanel/VBox/Hint
@onready var dlg_animal: TextureRect = $UI/DialoguePanel/AnimalIcon
@onready var magic_lbl: Label = $UI/TopBar/MagicLabel
@onready var instr_lbl: Label = $UI/InstrPanel/InstrLbl
@onready var complete_pan: Panel = $UI/CompletePanel
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	dialogue.visible = false
	complete_pan.visible = false
	_refresh_hud()
	_set_instr("Haz clic en un animal y arrastra hasta su casa.\nConecta los tres para completar el nivel.")
	GameManager.magic_points_changed.connect(_on_magic_points_changed)
	grid_board.animal_selected.connect(_on_animal_selected)
	grid_board.animal_connected.connect(_on_animal_connected)
	grid_board.drawing_stopped.connect(_on_drawing_stopped)

func _input(event: InputEvent) -> void:
	if _dialogue_open and event is InputEventMouseButton and event.pressed:
		_close_dialogue()
		get_viewport().set_input_as_handled()

func _on_magic_points_changed(_new_total: int) -> void:
	_refresh_hud()

func _on_animal_selected(animal: GridAnimalData) -> void:
	_set_instr("Arrastra desde  \"%s\"  (%s)  hasta su casa en maya" % [animal.maya_word, animal.spanish_word])

func _on_animal_connected(animal: GridAnimalData, animal_index: int) -> void:
	GameManager.learn_word(animal.maya_word)
	_show_animal_dialogue(animal, animal_index)

func _on_drawing_stopped() -> void:
	if not _dialogue_open and not _completing:
		_set_instr("Haz clic en un animal y arrastra hasta su casa.\nConecta los tres para completar el nivel.")

func _show_animal_dialogue(animal: GridAnimalData, animal_index: int) -> void:
	if _dialogue_open:
		return
	dlg_phrase.text = "In k'aaba'e'  %s" % animal.maya_word
	dlg_hint.text = "(Me llamo %s — en maya: %s)" % [animal.spanish_word, animal.maya_word]
	dlg_animal.texture = animal.sprite
	_dialogue_open = true
	dialogue.visible = true

	var animal_node: TextureRect = grid_board.get_animal_node(animal_index)
	if animal_node:
		var tween: Tween = create_tween()
		tween.tween_property(animal_node, "position:y", animal_node.position.y - 14, 0.15)
		tween.tween_property(animal_node, "position:y", animal_node.position.y, 0.20)

	await get_tree().create_timer(3.2).timeout
	if is_inside_tree():
		_close_dialogue()

func _close_dialogue() -> void:
	if not _dialogue_open:
		return
	_dialogue_open = false
	dialogue.visible = false
	if not _completing and grid_board.is_completed():
		_completing = true
		await get_tree().create_timer(0.4).timeout
		if is_inside_tree():
			_on_level_complete()
	elif not _completing:
		grid_board.set_interaction_enabled(true)

func _on_level_complete() -> void:
	GameManager.complete_level(1, 1)
	complete_pan.visible = true
	_set_instr("Nivel completado. Pulsa el boton para continuar.")

func _safe_navigate(key: String) -> void:
	grid_board.set_interaction_enabled(false)
	_dialogue_open = false
	dialogue.visible = false
	GameManager.go_to_scene(key)

func _on_next_level_pressed() -> void:
	_safe_navigate("world1_level2")

func _on_menu_pressed() -> void:
	_safe_navigate("main_menu")

func _on_book_pressed() -> void:
	libro.show_book()

func _set_instr(text: String) -> void:
	instr_lbl.text = text

func _refresh_hud() -> void:
	magic_lbl.text = "%d pts magicos" % GameManager.magic_points
