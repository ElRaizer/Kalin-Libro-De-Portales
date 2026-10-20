## Controlador común para los niveles que conectan palabras sobre GridBoard.
## Los datos visuales y educativos se configuran con GridWordData en la escena.
extends Node2D
class_name GridPathLevel

@export_category("Progreso y navegación")
@export_range(1, 99, 1) var world_number: int = 1
@export_range(1, 99, 1) var level_number: int = 1
@export var next_scene_key: String = "world1_level2"
@export var level_title: String = "Mundo 1 · Caminos Blancos"
@export var completion_title: String = "¡Nivel completado!"
@export_multiline var completion_summary: String = "Reconstruiste los caminos y recuperaste nuevas palabras."
@export var completion_next_text: String = "Siguiente nivel →"

@export_category("Instrucciones")
@export_multiline var default_instruction: String = "Haz clic en una ficha y arrastra hasta su destino. Conecta las tres para completar el nivel."
@export var selection_instruction: String = "Arrastra desde \"%s\" hasta \"%s\"."

@export_category("Llegada a casa")
@export var arriving_animal_scene: PackedScene
## Ritmo por casilla: las rutas largas conservan la misma velocidad.
@export_range(0.25, 0.8, 0.05) var arrival_step_seconds: float = 0.42
const ARRIVAL_HOP_HEIGHT := 9.0
const ARRIVAL_TILT := 0.06

var _completing: bool = false
var _dialogue_open: bool = false
var _dialogue_serial: int = 0
var _arrival_animating := false
var _dialogue_word_index := -1
var guide: LearningGuide
@onready var continue_button: Button = $UI/DialoguePanel/ContinueButton
@onready var arrival_button: Button = $UI/ArrivalButton
var arrival_tween: Tween
@onready var mission_progress: MissionProgress = $UI/MissionProgress

@onready var grid_board: GridBoard = $GridBoard
@onready var dialogue: Panel = $UI/DialoguePanel
@onready var dlg_phrase: Label = $UI/DialoguePanel/VBox/Phrase
@onready var dlg_hint: Label = $UI/DialoguePanel/VBox/Hint
@onready var dlg_icon: TextureRect = $UI/DialoguePanel/WordIcon
@onready var dlg_vbox: VBoxContainer = $UI/DialoguePanel/VBox
@onready var level_header: LevelHeader = $UI/LevelHeader
@onready var instr_lbl: Label = $UI/InstrPanel/InstrLbl
@onready var completion_overlay: CompletionOverlay = $UI/CompletionOverlay
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	dialogue.visible = false
	level_header.set_title(level_title)
	_set_default_instruction()
	_set_mouse_passthrough(dialogue)
	dialogue.mouse_filter = Control.MOUSE_FILTER_STOP
	continue_button.pressed.connect(_close_dialogue)
	guide = LearningGuide.install(self, $UI/LevelHeader/Bar, _show_help)
	grid_board.set_destination_word_colors(level_number == 1)
	arrival_button.pressed.connect(_speed_up_arrival)
	level_header.menu_pressed.connect(_on_menu_pressed)
	level_header.book_pressed.connect(_on_book_pressed)
	completion_overlay.next_pressed.connect(_on_next_level_pressed)
	completion_overlay.replay_pressed.connect(_on_replay_pressed)
	completion_overlay.menu_pressed.connect(_on_menu_pressed)
	grid_board.word_selected.connect(_on_word_selected)
	grid_board.word_connected.connect(_on_word_connected)
	grid_board.drawing_stopped.connect(_on_drawing_stopped)
	grid_board.invalid_move.connect(_on_invalid_move)
	var state := GameManager.get_scene_state(self)
	grid_board.restore_path_state(state.get("board", {}) if state.get("board", {}) is Dictionary else {})
	mission_progress.update_progress(grid_board.connected.size(), grid_board.words.size(), "Lleva a tus amigos a casa")
	var pending_word := clampi(int(state.get("dialogue_word", -1)), -1, grid_board.words.size() - 1)
	grid_board.focus_first_path(level_number == 1 and "paths" not in GameManager.tutorials_seen and grid_board.connected.is_empty())
	if bool(state.get("complete", false)):
		_completing = true
		completion_overlay.show_completion(completion_title, completion_summary, completion_next_text)
	elif bool(state.get("dialogue_open", false)) and pending_word in grid_board.connected:
		call_deferred("_show_word_dialogue", grid_board.words[pending_word], pending_word)
	elif grid_board.is_completed():
		call_deferred("_on_level_complete")
	else:
		call_deferred("_show_help")

func _unhandled_input(event: InputEvent) -> void:
	if (
		_dialogue_open and not _arrival_animating
		and (
			(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
			or (event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE])
		)
	):
		_close_dialogue()
		get_viewport().set_input_as_handled()

func _on_word_selected(word: GridWordData) -> void:
	guide.stop()
	var start_name: String = word.get_start_text().replace("\n", " ")
	var destination_name: String = word.get_destination_text().replace("\n", " ")
	_set_instr(selection_instruction % [start_name, destination_name])

func _on_word_connected(word: GridWordData, word_index: int) -> void:
	GameManager.learn_word(word.maya_word)
	_show_word_dialogue(word, word_index)

func _on_drawing_stopped() -> void:
	GameManager.checkpoint(self)
	if not _dialogue_open and not _completing:
		_set_default_instruction()

func _show_word_dialogue(word: GridWordData, word_index: int) -> void:
	if _dialogue_open:
		return
	_dialogue_word_index = word_index
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
	grid_board.set_interaction_enabled(false)
	guide.stop()
	_arrival_animating = true
	arrival_button.show()
	mission_progress.update_progress(grid_board.connected.size(), grid_board.words.size(), "¡El camino está listo!")
	var arrived := grid_board.destination_nodes[word_index].get_node_or_null("ArrivedAnimal") as Control
	if arrived:
		arrived.hide()
	if level_number == 1:
		GameManager.mark_tutorial_seen("paths")
		grid_board.focus_first_path(false)
	GameManager.checkpoint(self)
	var walker := arriving_animal_scene.instantiate() as TextureRect
	walker.name = "ArrivingAnimal"
	walker.texture = word.sprite
	walker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	walker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	walker.size = Vector2(grid_board.tile_size, grid_board.tile_size)
	walker.pivot_offset = Vector2(walker.size.x * 0.5, walker.size.y)
	walker.position = grid_board.cell_to_local_position(word.start_cell)
	walker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(walker)
	var route: Array = grid_board.paths[word_index].duplicate()
	route.append(word.destination_cell)
	var walk := walker.create_tween()
	arrival_tween = walk
	var previous_position := walker.position
	for step: int in range(route.size()):
		var next_position := grid_board.cell_to_local_position(route[step])
		var tilt_direction := 1.0 if step % 2 == 0 else -1.0
		walk.tween_method(_animate_arrival_step.bind(walker, previous_position, next_position, tilt_direction), 0.0, 1.0, arrival_step_seconds)
		previous_position = next_position
	await walk.finished
	if not is_inside_tree() or current_dialogue != _dialogue_serial:
		return
	walker.queue_free()
	if arrived:
		arrived.show()
	_arrival_animating = false
	arrival_button.hide()
	dialogue.visible = true
	continue_button.grab_focus()
	guide.watch_continue(continue_button)
	guide.page_to_book(grid_board.cell_to_local_position(word.destination_cell), $UI/LevelHeader/Bar/BookButton.get_global_rect().get_center())

func _animate_arrival_step(progress: float, walker: TextureRect, start: Vector2, destination: Vector2, tilt_direction: float) -> void:
	# La misma elevación y balanceo suaves que usa Kalin al explorar.
	var stride := sin(progress * PI)
	walker.position = start.lerp(destination, progress) + Vector2(0.0, -stride * ARRIVAL_HOP_HEIGHT)
	walker.rotation = stride * ARRIVAL_TILT * tilt_direction

func _close_dialogue() -> void:
	if not _dialogue_open or _arrival_animating:
		return
	_dialogue_open = false
	_dialogue_word_index = -1
	dialogue.visible = false
	guide.stop()
	if not _completing and grid_board.is_completed():
		_on_level_complete()
	elif not _completing:
		grid_board.set_interaction_enabled(true)
		_set_default_instruction()
	GameManager.checkpoint(self)

func _on_level_complete() -> void:
	_completing = true
	grid_board.set_interaction_enabled(false)
	guide.stop()
	GameManager.complete_level(world_number, level_number)
	completion_overlay.show_completion(completion_title, completion_summary, completion_next_text)
	_set_instr("Nivel completado. Pulsa el botón para continuar.")
	GameManager.checkpoint(self)

func _safe_navigate(key: String) -> void:
	grid_board.set_interaction_enabled(false)
	GameManager.go_to_scene(key)

func _on_next_level_pressed() -> void:
	_safe_navigate(next_scene_key)

func _on_menu_pressed() -> void:
	_safe_navigate("main_menu")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))

func _set_default_instruction() -> void:
	_set_instr(default_instruction)

func _set_instr(text: String) -> void:
	instr_lbl.text = text

func _set_mouse_passthrough(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in control.get_children():
		if child is Control:
			_set_mouse_passthrough(child)

func _show_help() -> void:
	if _completing:
		return
	if _dialogue_open:
		guide.point_at(continue_button)
		return
	for index: int in range(grid_board.words.size()):
		if index in grid_board.connected:
			continue
		var word: GridWordData = grid_board.words[index]
		var from := grid_board.cell_to_local_position(word.start_cell) + Vector2.ONE * grid_board.tile_size * 0.5
		# Demostrar el gesto, sin regalar la ruta de los tableros avanzados.
		var to := grid_board.cell_to_local_position(word.destination_cell) + Vector2.ONE * grid_board.tile_size * 0.5 if level_number == 1 else from + Vector2(grid_board.tile_size * 2, 0)
		guide.demonstrate([from, to])
		_set_instr("Arrastra desde el animal hasta su palabra.")
		return

func _on_invalid_move(reason: String, cell: Vector2i) -> void:
	_set_instr(reason)
	var tile: Control = grid_board.tile_rects.get(cell)
	if tile:
		var tint := tile.modulate
		var tween := create_tween()
		tween.tween_property(tile, "modulate", Color("f0a060"), 0.08)
		tween.tween_property(tile, "modulate", tint, 0.25)

func get_checkpoint_state() -> Dictionary:
	return {"board": grid_board.get_path_state(), "complete": _completing, "dialogue_word": _dialogue_word_index, "dialogue_open": _dialogue_open}

func _speed_up_arrival() -> void:
	if arrival_tween and arrival_tween.is_valid():
		arrival_tween.set_speed_scale(3.0)
