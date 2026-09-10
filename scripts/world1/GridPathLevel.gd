## Controlador común para los niveles que conectan palabras sobre GridBoard.
## Los datos visuales y educativos se configuran con GridWordData en la escena.
extends Node2D
class_name GridPathLevel

@export_category("Progreso y navegación")
@export_range(1, 99, 1) var level_number: int = 1
@export var next_scene_key: String = "world1_level2"

@export_category("Instrucciones")
@export_multiline var default_instruction: String = "Haz clic en una ficha y arrastra hasta su destino.\nConecta las tres para completar el nivel."
@export var selection_instruction: String = "Arrastra desde \"%s\" hasta \"%s\"."

var _completing: bool = false
var _dialogue_open: bool = false
var _dialogue_serial: int = 0

@onready var grid_board: GridBoard = $GridBoard
@onready var dialogue: Panel = $UI/DialoguePanel
@onready var dlg_phrase: Label = $UI/DialoguePanel/VBox/Phrase
@onready var dlg_hint: Label = $UI/DialoguePanel/VBox/Hint
@onready var dlg_icon: TextureRect = $UI/DialoguePanel/WordIcon
@onready var dlg_vbox: VBoxContainer = $UI/DialoguePanel/VBox
@onready var magic_lbl: Label = $UI/TopBar/MagicLabel
@onready var instr_lbl: Label = $UI/InstrPanel/InstrLbl
@onready var complete_pan: Panel = $UI/CompletePanel
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	dialogue.visible = false
	complete_pan.visible = false
	_refresh_hud()
	_set_default_instruction()
	GameManager.magic_points_changed.connect(_on_magic_points_changed)
	grid_board.word_selected.connect(_on_word_selected)
	grid_board.word_connected.connect(_on_word_connected)
	grid_board.drawing_stopped.connect(_on_drawing_stopped)

func _input(event: InputEvent) -> void:
	if _dialogue_open and event is InputEventMouseButton and event.pressed:
		_close_dialogue()
		get_viewport().set_input_as_handled()

func _on_magic_points_changed(_new_total: int) -> void:
	_refresh_hud()

func _on_word_selected(word: GridWordData) -> void:
	var start_name: String = word.get_start_text().replace("\n", " ")
	var destination_name: String = word.get_destination_text().replace("\n", " ")
	_set_instr(selection_instruction % [start_name, destination_name])

func _on_word_connected(word: GridWordData, word_index: int) -> void:
	GameManager.learn_word(word.maya_word)
	_show_word_dialogue(word, word_index)

func _on_drawing_stopped() -> void:
	if not _dialogue_open and not _completing:
		_set_default_instruction()

func _show_word_dialogue(word: GridWordData, word_index: int) -> void:
	if _dialogue_open:
		return
	dlg_phrase.text = word.phrase if not word.phrase.is_empty() else "%s = %s" % [word.maya_word, word.spanish_word]
	dlg_hint.text = word.explanation if not word.explanation.is_empty() else "%s significa %s." % [word.maya_word, word.spanish_word]
	dlg_icon.texture = word.sprite
	dlg_icon.visible = word.sprite != null
	if dlg_icon.visible:
		dlg_vbox.offset_left = 108.0
		dlg_vbox.offset_right = 800.0
	else:
		dlg_vbox.offset_left = 24.0
		dlg_vbox.offset_right = 796.0

	_dialogue_serial += 1
	var current_dialogue: int = _dialogue_serial
	_dialogue_open = true
	dialogue.visible = true
	grid_board.set_interaction_enabled(false)

	var word_node: Control = grid_board.get_word_node(word_index)
	if word_node:
		var tween: Tween = create_tween()
		tween.tween_property(word_node, "position:y", word_node.position.y - 14, 0.15)
		tween.tween_property(word_node, "position:y", word_node.position.y, 0.20)

	await get_tree().create_timer(3.2).timeout
	if is_inside_tree() and current_dialogue == _dialogue_serial:
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
	GameManager.complete_level(1, level_number)
	complete_pan.visible = true
	_set_instr("Nivel completado. Pulsa el botón para continuar.")

func _safe_navigate(key: String) -> void:
	grid_board.set_interaction_enabled(false)
	_dialogue_open = false
	dialogue.visible = false
	GameManager.go_to_scene(key)

func _on_next_level_pressed() -> void:
	_safe_navigate(next_scene_key)

func _on_menu_pressed() -> void:
	_safe_navigate("main_menu")

func _on_book_pressed() -> void:
	libro.show_book()

func _set_default_instruction() -> void:
	_set_instr(default_instruction)

func _set_instr(text: String) -> void:
	instr_lbl.text = text

func _refresh_hud() -> void:
	magic_lbl.text = "%d pts mágicos" % GameManager.magic_points
