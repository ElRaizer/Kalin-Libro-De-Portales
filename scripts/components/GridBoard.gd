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
signal invalid_move(reason: String, cell: Vector2i)

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

@export_category("Plantillas visuales")
@export var tile_scene: PackedScene
@export var word_scene: PackedScene
@export var destination_scene: PackedScene
@export var cursor_scene: PackedScene
@export var path_line_scene: PackedScene
@export var path_tip_scene: PackedScene
@export var word_style: StyleBoxFlat
@export var destination_style: StyleBoxFlat
@export var concealed_style: StyleBoxFlat

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
@export_tool_button("Actualizar nodos del tablero", "Reload") var update_board_nodes: Callable = rebuild_preview
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
var tutorial_only_index: int = -1
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
var destination_word_colors := true

func set_destination_word_colors(enabled: bool) -> void:
	destination_word_colors = enabled
	for index: int in destination_nodes:
		var color: Color = words[index].color if enabled else Color("b99562")
		(destination_nodes[index] as Panel).add_theme_stylebox_override("panel", _get_renderer().destination_style(color))

const NEARBY_OBSTACLE_FADE_SECONDS := 0.22
const ALL_OBSTACLES_FADE_SECONDS := 0.45

func _ready() -> void:
	add_to_group(&"keyboard_focus_visual")
	selection_ring.visible = false
	if Engine.is_editor_hint():
		_watch_word_changes()
		if preview_root.get_child_count() == 0:
			rebuild_preview()
		else:
			_get_renderer().bind_saved_nodes()
	else:
		start_game()

func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()

## Devuelve problemas de configuración que pueden revisarse tanto en el
## editor como desde las pruebas automatizadas.
func get_configuration_issues() -> PackedStringArray:
	var issues: PackedStringArray = CONFIG_VALIDATOR.validate(columns, rows, empty_tile, obstacle_tile, obstacles, words)
	var saved_preview := get_node_or_null("Preview")
	if saved_preview == null:
		issues.append("Falta el nodo Preview del tablero.")
		return issues
	if words.is_empty():
		return issues
	var complete := saved_preview.has_node("KeyboardCursor")
	for row: int in range(rows):
		for column: int in range(columns):
			complete = complete and saved_preview.has_node("Tile_%d_%d" % [column, row])
	for index: int in range(words.size()):
		for prefix: String in ["Word", "Destination", "PathLine", "PathTip"]:
			complete = complete and saved_preview.has_node("%s_%d" % [prefix, index])
	if not complete:
		issues.append("Pulsa Actualizar nodos del tablero y guarda la escena antes de jugar.")
	return issues

func _exit_tree() -> void:
	for word in _watched_words:
		if is_instance_valid(word) and word.changed.is_connected(_schedule_rebuild):
			word.changed.disconnect(_schedule_rebuild)
	_watched_words.clear()

## Permite que una escena de nivel o el Inspector fuerce la actualización.
func rebuild_preview() -> void:
	if not Engine.is_editor_hint() and is_inside_tree():
		push_error("Los nodos del tablero se generan desde el editor, antes de jugar.")
		return
	_rebuild_queued = false
	_get_renderer().rebuild_preview()
	if Engine.is_editor_hint() and is_inside_tree():
		update_configuration_warnings()

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

func get_hint_path(index: int, max_steps: int = 0) -> Array[Vector2i]:
	return _get_path_controller().hint_path(index, max_steps)

## Recoloca los nodos guardados; no genera escena ni modifica recursos compartidos.
func apply_layout(starts: Array[Vector2i], goals: Array[Vector2i], rocks: Array[Vector2i]) -> void:
	var session_words: Array[GridWordData] = []
	for index: int in range(words.size()):
		var word := words[index].duplicate() as GridWordData
		word.start_cell = starts[index]
		word.destination_cell = goals[index]
		session_words.append(word)
	words = session_words
	obstacles = rocks.duplicate()
	_setup_game_state()
	for cell: Vector2i in tile_rects:
		(tile_rects[cell] as TextureRect).texture = obstacle_tile if cell in obstacles else empty_tile
	for index: int in range(words.size()):
		(word_nodes[index] as Control).position = cell_to_local_position(starts[index]) + Vector2(2, 2)
		(destination_nodes[index] as Control).position = cell_to_local_position(goals[index]) + Vector2(2, 2)
	_update_keyboard_cursor()
	_refresh_all_path_visuals()

## Inicializa el estado jugable con las propiedades editadas en el Inspector.
func start_game() -> void:
	_setup_game_state()
	_get_renderer().bind_saved_nodes()
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
		var label := destination.get_child(destination.get_child_count() - 1) as Label
		if label:
			label.text = "?"
			label.add_theme_font_size_override("font_size", 24)
		destination.add_theme_stylebox_override("panel", concealed_style)


func _schedule_rebuild() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	update_configuration_warnings()
	if _rebuild_queued:
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
	keyboard_cursor = cursor_scene.instantiate() as Panel
	keyboard_cursor.name = "KeyboardCursor"
	preview_root.add_child(keyboard_cursor)
	keyboard_cursor.owner = owner if owner != null else self
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
			if tutorial_only_index >= 0 and index != tutorial_only_index:
				return
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
	if not is_valid_cell(cell):
		return
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
			elif drawing:
				invalid_move.emit("Busca su palabra maya", cell)
		Cell.OBSTACLE:
			if drawing:
				invalid_move.emit("Rodea la roca", cell)

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

func focus_first_path(enabled: bool) -> void:
	tutorial_only_index = 0 if enabled else -1
	for index: int in range(words.size()):
		word_nodes[index].visible = not enabled or index == 0
		destination_nodes[index].visible = not enabled or index == 0
	for cell: Vector2i in tile_rects:
		var tile: Control = tile_rects[cell]
		tile.modulate.a = _get_renderer()._base_color(tile).a * (1.0 if not enabled or (cell.y == words[0].start_cell.y and cell.x <= words[0].destination_cell.x) else 0.2)

func get_path_state() -> Dictionary:
	var saved: Dictionary = {}
	for index: int in paths:
		var cells: Array = []
		for cell: Vector2i in paths[index]:
			cells.append([cell.x, cell.y])
		saved[str(index)] = cells
	return {"paths": saved, "connected": connected.duplicate()}

func restore_path_state(state: Dictionary) -> void:
	var saved_paths: Variant = state.get("paths", {})
	var saved_connected: Variant = state.get("connected", [])
	if saved_paths is not Dictionary or saved_connected is not Array:
		return
	# JSON decodifica los números como float; Array.has no equipara sus tipos.
	var restored_connections: Array[int] = []
	for value: Variant in saved_connected:
		if (value is int or value is float) and value == int(value):
			restored_connections.append(int(value))
	for index: int in range(words.size()):
		var saved: Variant = saved_paths.get(str(index), [])
		if saved is not Array or saved.size() > rows * columns:
			continue
		active_index = index
		for pair: Variant in saved:
			if pair is not Array or pair.size() != 2 or not (pair[0] is float or pair[0] is int) or not (pair[1] is float or pair[1] is int):
				break
			var cell := Vector2i(int(pair[0]), int(pair[1]))
			if not is_valid_cell(cell) or grid_state[cell.y][cell.x] != Cell.EMPTY:
				break
			var before: int = paths[index].size()
			_extend_path(cell)
			if paths[index].size() == before:
				break
		var tip: Vector2i = words[index].start_cell if paths[index].is_empty() else paths[index].back()
		if index in restored_connections and _are_adjacent(tip, words[index].destination_cell):
			connected.append(index)
	active_index = -1
	drawing = false
	_refresh_all_path_visuals()

func cancel_drawing() -> void:
	_stop_drawing()
