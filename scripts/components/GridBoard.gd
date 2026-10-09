@tool
extends Node2D
class_name GridBoard

const CONFIG_VALIDATOR = preload("res://scripts/components/GridBoardValidator.gd")
const BOARD_RENDERER = preload("res://scripts/components/GridBoardRenderer.gd")
const OBSTACLE_HINTS = preload("res://scripts/components/GridObstacleHints.gd")
const PATH_CONTROLLER = preload("res://scripts/components/GridPathController.gd")

## Componente reutilizable para previsualizar un tablero de caminos en Godot.
## Sus propiedades se editan en el Inspector de cada instancia de GridBoard.
## También controla el arrastre y emite señales para que el nivel decida sus
## diálogos, recompensas y condiciones narrativas. Cada ficha puede presentar
## una textura (animales) o texto (objetos, adjetivos y vocabulario futuro).

signal word_selected(word: GridWordData)
signal word_connected(word: GridWordData, word_index: int)
signal path_reset(word: GridWordData, word_index: int)
signal drawing_stopped

enum Cell { EMPTY, OBSTACLE, WORD, DESTINATION, PATH }

@export_category("Tamaño y posición")
@export_range(1, 30, 1) var columns: int = 9:
	set(value):
		columns = max(value, 1)
		_schedule_rebuild()

@export_range(1, 30, 1) var rows: int = 7:
	set(value):
		rows = max(value, 1)
		_schedule_rebuild()

@export_range(24, 200, 1, "or_greater") var tile_size: int = 80:
	set(value):
		tile_size = max(value, 1)
		_schedule_rebuild()

@export var grid_origin: Vector2 = Vector2(80, 95):
	set(value):
		grid_origin = value
		_schedule_rebuild()

@export_category("Recursos visuales")
@export var empty_tile: Texture2D:
	set(value):
		empty_tile = value
		_schedule_rebuild()

@export var obstacle_tile: Texture2D:
	set(value):
		obstacle_tile = value
		_schedule_rebuild()

@export var destination_color: Color = Color(0.82, 0.74, 0.54, 1.0):
	set(value):
		destination_color = value
		_schedule_rebuild()

@export_category("Visual del camino")
@export_range(2.0, 60.0, 1.0) var path_line_width: float = 18.0:
	set(value):
		path_line_width = maxf(value, 2.0)
		_refresh_all_path_visuals()

@export_range(1.0, 2.5, 0.05) var path_tip_scale: float = 1.45:
	set(value):
		path_tip_scale = clampf(value, 1.0, 2.5)
		_refresh_all_path_visuals()

## Cantidad de color que conserva el tile debajo de la línea.
## 0 no altera el tile y 1 aplica completamente el color del camino.
@export_range(0.0, 1.0, 0.01) var path_tile_tint: float = 0.12:
	set(value):
		path_tile_tint = clampf(value, 0.0, 1.0)
		_refresh_all_path_visuals()

@export_category("Contenido del nivel")
@export var obstacles: Array[Vector2i] = []:
	set(value):
		obstacles = value
		_schedule_rebuild()

@export var words: Array[GridWordData] = []:
	set(value):
		words = value
		_schedule_rebuild()

@export_category("Editor")
@export var show_preview_in_editor: bool = true:
	set(value):
		show_preview_in_editor = value
		_schedule_rebuild()

@onready var preview_root: Node2D = $Preview
@onready var selection_ring: ColorRect = $SelectionRing
var _rebuild_queued: bool = false
var _watched_words: Array[GridWordData] = []
var grid_state: Array[Array] = []
var tile_owner: Dictionary = {}
var paths: Dictionary = {}
var connected: Array[int] = []
var tile_rects: Dictionary = {}
var word_nodes: Dictionary = {}
var path_lines: Dictionary = {}
var path_tips: Dictionary = {}
var destination_nodes: Dictionary = {}
var drawing: bool = false
var active_index: int = -1
var last_cell: Vector2i = Vector2i(-1, -1)
var input_enabled: bool = true
var ring_tween: Tween
var keyboard_cursor: Panel
var keyboard_cell: Vector2i = Vector2i(-1, -1)
var keyboard_visual_visible: bool = true
var obstacle_clues_visible: bool = true
var reveal_obstacles_near_tip: bool = false
var nearby_obstacle_opacity: float = 0.5
var revealed_obstacles: Array[Vector2i] = []
var obstacle_reveal_tweens: Dictionary = {}
var _renderer: RefCounted
var _obstacle_hints: RefCounted
var _path_controller: RefCounted

const NEARBY_OBSTACLE_FADE_SECONDS := 0.22
const ALL_OBSTACLES_FADE_SECONDS := 0.45

func _ready() -> void:
	add_to_group(&"keyboard_focus_visual")
	selection_ring.visible = false
	if Engine.is_editor_hint():
		_watch_word_changes()
		rebuild_preview()
	else:
		start_game()

func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()

## Devuelve problemas de configuración que pueden revisarse tanto en el
## editor como desde las pruebas automatizadas.
func get_configuration_issues() -> PackedStringArray:
	return CONFIG_VALIDATOR.validate(columns, rows, empty_tile, obstacle_tile, obstacles, words)

func _exit_tree() -> void:
	for word in _watched_words:
		if is_instance_valid(word) and word.changed.is_connected(_schedule_rebuild):
			word.changed.disconnect(_schedule_rebuild)
	_watched_words.clear()

## Permite que una escena de nivel o el Inspector fuerce la actualización.
func rebuild_preview() -> void:
	_rebuild_queued = false
	_get_renderer().rebuild_preview()

func _get_renderer() -> RefCounted:
	if not is_instance_valid(_renderer):
		_renderer = BOARD_RENDERER.new(self)
	return _renderer

func _get_obstacle_hints() -> RefCounted:
	if not is_instance_valid(_obstacle_hints):
		_obstacle_hints = OBSTACLE_HINTS.new(self)
	return _obstacle_hints

func _get_path_controller() -> RefCounted:
	if not is_instance_valid(_path_controller):
		_path_controller = PATH_CONTROLLER.new(self)
	return _path_controller

## Inicializa el estado jugable con las propiedades editadas en el Inspector.
func start_game() -> void:
	_setup_game_state()
	rebuild_preview()
	input_enabled = true

func cell_to_local_position(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * tile_size, cell.y * tile_size)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows

func is_completed() -> bool:
	return not words.is_empty() and connected.size() == words.size()

func set_interaction_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		_stop_drawing()
	elif keyboard_cell != Vector2i(-1, -1):
		keyboard_cell = _first_available_word_cell()
		_update_keyboard_cursor()
	if is_instance_valid(keyboard_cursor):
		keyboard_cursor.visible = keyboard_visual_visible and enabled and keyboard_cell != Vector2i(-1, -1)

func get_word_node(word_index: int) -> Control:
	return word_nodes.get(word_index) as Control

## Oculta solamente la apariencia de los obstáculos. Las celdas continúan
## bloqueadas, por lo que puede usarse como un reto de memoria sin cambiar la
## solución del tablero mientras el jugador está trazando un camino.
func set_obstacle_clues_visible(visible: bool) -> void:
	_get_obstacle_hints().set_visible(visible)

## Oculta todas las pistas de obstáculos con una transición conjunta. El
## estado bloqueado de las celdas no cambia durante ni después del efecto.
func fade_out_obstacle_clues(duration: float = ALL_OBSTACLES_FADE_SECONDS) -> void:
	await _get_obstacle_hints().fade_out_all(duration)

## Cuando las pistas generales están ocultas, revela con transparencia sólo
## los obstáculos ortogonalmente adyacentes a la punta del camino activo.
func set_nearby_obstacle_reveal(enabled: bool, opacity: float = 0.5) -> void:
	_get_obstacle_hints().set_nearby_reveal(enabled, opacity)

func _update_nearby_obstacle_clues() -> void:
	_get_obstacle_hints().update_nearby()

## Sustituye las palabras y colores de los destinos por una pista neutra. Las
## posiciones no cambian: el jugador debe recordar qué animal iba en cada una.
func conceal_destination_clues() -> void:
	for destination: Panel in destination_nodes.values():
		var label := destination.get_child(0) as Label
		if label:
			label.text = "?"
			label.add_theme_font_size_override("font_size", 24)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("e7dcc2")
		style.border_color = Color("766d62")
		style.set_border_width_all(3)
		style.set_corner_radius_all(6)
		destination.add_theme_stylebox_override("panel", style)

func _schedule_rebuild() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		update_configuration_warnings()
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	call_deferred("rebuild_preview")

func _watch_word_changes() -> void:
	for word in _watched_words:
		if is_instance_valid(word) and word.changed.is_connected(_schedule_rebuild):
			word.changed.disconnect(_schedule_rebuild)
	_watched_words.clear()
	for word in words:
		if is_instance_valid(word):
			if not word.changed.is_connected(_schedule_rebuild):
				word.changed.connect(_schedule_rebuild)
			_watched_words.append(word)

func _setup_game_state() -> void:
	grid_state.clear()
	tile_owner.clear()
	paths.clear()
	connected.clear()
	for row in range(rows):
		var state_row: Array[int] = []
		for _column in range(columns):
			state_row.append(Cell.EMPTY)
		grid_state.append(state_row)
	for obstacle in obstacles:
		if is_valid_cell(obstacle):
			grid_state[obstacle.y][obstacle.x] = Cell.OBSTACLE
	for index in words.size():
		var word: GridWordData = words[index]
		if not is_instance_valid(word):
			continue
		if is_valid_cell(word.start_cell):
			grid_state[word.start_cell.y][word.start_cell.x] = Cell.WORD
			tile_owner[word.start_cell] = index
		if is_valid_cell(word.destination_cell):
			grid_state[word.destination_cell.y][word.destination_cell.x] = Cell.DESTINATION
			tile_owner[word.destination_cell] = index
		paths[index] = []

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not input_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			last_cell = Vector2i(-1, -1)
			_handle_press(_local_to_cell(to_local(event.position)))
		else:
			_stop_drawing()
	elif event is InputEventMouseMotion and drawing:
		var cell: Vector2i = _local_to_cell(to_local(event.position))
		if cell != last_cell:
			_fill_gap(last_cell, cell)
			last_cell = cell
	elif event is InputEventKey and event.pressed and not event.echo:
		if _handle_keyboard_input(event):
			get_viewport().set_input_as_handled()

func _handle_keyboard_input(event: InputEventKey) -> bool:
	var direction := Vector2i.ZERO
	if event.is_action_pressed(&"ui_left"):
		direction = Vector2i.LEFT
	elif event.is_action_pressed(&"ui_right"):
		direction = Vector2i.RIGHT
	elif event.is_action_pressed(&"ui_up"):
		direction = Vector2i.UP
	elif event.is_action_pressed(&"ui_down"):
		direction = Vector2i.DOWN
	elif event.is_action_pressed(&"ui_accept"):
		_ensure_keyboard_cursor()
		_handle_press(keyboard_cell)
		return true
	elif event.is_action_pressed(&"ui_cancel") and drawing:
		_clear_path(active_index)
		_stop_drawing()
		return true
	else:
		return false

	if keyboard_cell == Vector2i(-1, -1):
		_ensure_keyboard_cursor()
		return true
	var next_cell := keyboard_cell + direction
	if is_valid_cell(next_cell):
		keyboard_cell = next_cell
		_update_keyboard_cursor()
		if drawing:
			_try_cell(keyboard_cell)
			last_cell = keyboard_cell
	return true

func _ensure_keyboard_cursor() -> void:
	if keyboard_cell == Vector2i(-1, -1):
		keyboard_cell = _first_available_word_cell()
		_update_keyboard_cursor()

func _first_available_word_cell() -> Vector2i:
	for index: int in range(words.size()):
		if index not in connected and is_instance_valid(words[index]):
			return words[index].start_cell
	return Vector2i.ZERO

func _add_keyboard_cursor() -> void:
	keyboard_cursor = Panel.new()
	keyboard_cursor.name = "KeyboardCursor"
	keyboard_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keyboard_cursor.z_index = 20
	var cursor_style := StyleBoxFlat.new()
	cursor_style.bg_color = Color(0, 0, 0, 0)
	cursor_style.border_color = Color("fff06a")
	cursor_style.set_border_width_all(5)
	cursor_style.set_corner_radius_all(8)
	keyboard_cursor.add_theme_stylebox_override(&"panel", cursor_style)
	preview_root.add_child(keyboard_cursor)
	_update_keyboard_cursor()

func _update_keyboard_cursor() -> void:
	if not is_instance_valid(keyboard_cursor):
		return
	keyboard_cursor.visible = keyboard_visual_visible and input_enabled and keyboard_cell != Vector2i(-1, -1)
	if keyboard_cursor.visible:
		keyboard_cursor.position = cell_to_local_position(keyboard_cell) + Vector2(1, 1)
		keyboard_cursor.size = Vector2(tile_size - 2, tile_size - 2)

func set_keyboard_visual_visible(value: bool) -> void:
	keyboard_visual_visible = value
	_update_keyboard_cursor()

func _handle_press(cell: Vector2i) -> void:
	if not is_valid_cell(cell):
		return
	match grid_state[cell.y][cell.x]:
		Cell.WORD:
			var index: int = tile_owner[cell]
			if index in connected:
				_reset_connected_path(index)
			_clear_path(index)
			active_index = index
			drawing = true
			last_cell = cell
			_show_ring(index)
			word_selected.emit(words[index])
			_update_nearby_obstacle_clues()
		Cell.EMPTY:
			if drawing:
				_extend_path(cell)
		Cell.PATH:
			if drawing:
				_extend_path(cell)
			else:
				_try_resume_path(cell)
		Cell.DESTINATION:
			if drawing and tile_owner.get(cell, -1) == active_index:
				_try_finalize_connection(cell)

func _fill_gap(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if not is_valid_cell(to_cell):
		return
	if from_cell == Vector2i(-1, -1):
		_try_cell(to_cell)
		return
	var dx: int = to_cell.x - from_cell.x
	var dy: int = to_cell.y - from_cell.y
	var steps: int = maxi(absi(dx), absi(dy))
	for step in range(1, steps + 1):
		var middle: Vector2i = Vector2i(
			from_cell.x + roundi(float(dx) * step / steps),
			from_cell.y + roundi(float(dy) * step / steps)
		)
		if is_valid_cell(middle):
			_try_cell(middle)

func _try_cell(cell: Vector2i) -> void:
	if drawing and _try_retract_path(cell):
		return
	match grid_state[cell.y][cell.x]:
		Cell.EMPTY, Cell.PATH:
			_extend_path(cell)
		Cell.WORD:
			# Volver a la ficha inicial elimina el primer tramo del camino.
			_try_retract_path(cell)
		Cell.DESTINATION:
			if tile_owner.get(cell, -1) == active_index:
				_try_finalize_connection(cell)

func _try_finalize_connection(destination_cell: Vector2i) -> void:
	_get_path_controller().try_finalize(destination_cell)

func _try_resume_path(cell: Vector2i) -> void:
	_get_path_controller().try_resume(cell)

func _try_retract_path(cell: Vector2i) -> bool:
	return _get_path_controller().try_retract(cell)

func _extend_path(cell: Vector2i) -> void:
	_get_path_controller().extend(cell)

func _clear_path(index: int) -> void:
	_get_path_controller().clear(index)

func _reset_connected_path(index: int) -> void:
	_get_path_controller().reset_connected(index)

func _finalize_connection(index: int) -> void:
	_get_path_controller().finalize(index)

func _stop_drawing() -> void:
	if not drawing and active_index < 0:
		return
	drawing = false
	active_index = -1
	selection_ring.visible = false
	_update_nearby_obstacle_clues()
	if ring_tween and ring_tween.is_valid():
		ring_tween.kill()
	drawing_stopped.emit()

func _show_ring(index: int) -> void:
	if ring_tween and ring_tween.is_valid():
		ring_tween.kill()
	ring_tween = _get_renderer().show_selection_ring(index)

func _local_to_cell(actual_position: Vector2) -> Vector2i:
	return Vector2i(
		floori((actual_position.x - grid_origin.x) / tile_size),
		floori((actual_position.y - grid_origin.y) / tile_size)
	)

func _are_adjacent(first: Vector2i, second: Vector2i) -> bool:
	var delta: Vector2i = first - second
	return (abs(delta.x) == 1 and delta.y == 0) or (delta.x == 0 and abs(delta.y) == 1)

func _set_tile_color(cell: Vector2i, color: Color) -> void:
	_get_renderer().set_tile_color(cell, color)

func _set_path_tile_tint(cell: Vector2i, color: Color) -> void:
	_get_renderer().set_path_tile_tint(cell, color)

func _refresh_all_path_visuals() -> void:
	_get_renderer().refresh_all_paths()

func _refresh_path_line(index: int) -> void:
	_get_renderer().refresh_path_line(index)

func _remove_path_line(index: int) -> void:
	_get_renderer().remove_path_line(index)

func _reset_tile(cell: Vector2i) -> void:
	_get_renderer().reset_tile(cell)
