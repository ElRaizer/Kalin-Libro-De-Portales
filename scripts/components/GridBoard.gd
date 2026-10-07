@tool
extends Node2D
class_name GridBoard

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
	var issues: PackedStringArray = []
	if empty_tile == null:
		issues.append("Asigna una textura a empty_tile.")
	if obstacle_tile == null and not obstacles.is_empty():
		issues.append("Asigna una textura a obstacle_tile cuando existan obstáculos.")
	if words.is_empty():
		issues.append("Agrega al menos una palabra al tablero.")

	var occupied_cells: Dictionary = {}
	var maya_words: Dictionary = {}
	for obstacle: Vector2i in obstacles:
		if not is_valid_cell(obstacle):
			issues.append("El obstáculo %s está fuera del tablero." % obstacle)
			continue
		if occupied_cells.has(obstacle):
			issues.append("La celda %s está ocupada más de una vez." % obstacle)
		occupied_cells[obstacle] = "obstáculo"

	for index: int in words.size():
		var word: GridWordData = words[index]
		if word == null:
			issues.append("La palabra %d no tiene un recurso asignado." % (index + 1))
			continue
		if word.maya_word.strip_edges().is_empty():
			issues.append("La palabra %d no tiene texto maya." % (index + 1))
		elif maya_words.has(word.maya_word):
			issues.append("La palabra maya '%s' está duplicada." % word.maya_word)
		else:
			maya_words[word.maya_word] = true
		_validate_word_cell(word.start_cell, "inicio de '%s'" % word.maya_word, occupied_cells, issues)
		_validate_word_cell(
			word.destination_cell,
			"destino de '%s'" % word.maya_word,
			occupied_cells,
			issues
		)
		if word.start_cell == word.destination_cell:
			issues.append("'%s' empieza y termina en la misma celda." % word.maya_word)
	return issues

func _validate_word_cell(
	cell: Vector2i,
	label: String,
	occupied_cells: Dictionary,
	issues: PackedStringArray
) -> void:
	if not is_valid_cell(cell):
		issues.append("El %s (%s) está fuera del tablero." % [label, cell])
		return
	if occupied_cells.has(cell):
		issues.append(
			"La celda %s se comparte entre %s y %s." % [cell, occupied_cells[cell], label]
		)
	occupied_cells[cell] = label

func _exit_tree() -> void:
	for word in _watched_words:
		if is_instance_valid(word) and word.changed.is_connected(_schedule_rebuild):
			word.changed.disconnect(_schedule_rebuild)
	_watched_words.clear()

## Permite que una escena de nivel o el Inspector fuerce la actualización.
func rebuild_preview() -> void:
	_rebuild_queued = false
	if not is_instance_valid(preview_root):
		return
	_watch_word_changes()
	for child in preview_root.get_children():
		child.free()
	tile_rects.clear()
	word_nodes.clear()
	path_lines.clear()
	path_tips.clear()
	destination_nodes.clear()

	if Engine.is_editor_hint() and not show_preview_in_editor:
		return

	for row in range(rows):
		for column in range(columns):
			var cell: Vector2i = Vector2i(column, row)
			var tile: TextureRect = TextureRect.new()
			tile.name = "Tile_%d_%d" % [column, row]
			tile.position = cell_to_local_position(cell) + Vector2.ONE
			tile.size = Vector2(tile_size - 2, tile_size - 2)
			tile.texture = obstacle_tile if cell in obstacles else empty_tile
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview_root.add_child(tile)
			tile_rects[cell] = tile

	for index in words.size():
		var word: GridWordData = words[index]
		if not is_instance_valid(word):
			continue
		_add_destination_preview(word, index)
		_add_word_preview(word, index)
	_add_keyboard_cursor()

	_refresh_all_path_visuals()

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

func _add_word_preview(word: GridWordData, index: int) -> void:
	if not is_valid_cell(word.start_cell):
		return
	var panel: Panel = _create_word_panel(word.color, false)
	panel.name = "Word_%d" % index
	panel.position = cell_to_local_position(word.start_cell) + Vector2(2, 2)
	panel.size = Vector2(tile_size - 4, tile_size - 4)
	panel.z_index = 2

	if word.sprite:
		var sprite: TextureRect = TextureRect.new()
		sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sprite.texture = word.sprite
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(sprite)
		if not word.start_text.is_empty():
			_add_panel_label(panel, word.start_text, VERTICAL_ALIGNMENT_BOTTOM, 12, Color.WHITE)
	else:
		_add_panel_label(panel, word.get_start_text(), VERTICAL_ALIGNMENT_CENTER, 14, Color.WHITE)

	preview_root.add_child(panel)
	word_nodes[index] = panel

func _add_destination_preview(word: GridWordData, index: int) -> void:
	if not is_valid_cell(word.destination_cell):
		return
	var destination: Panel = _create_word_panel(word.color, true)
	destination.name = "Destination_%d" % index
	destination.position = cell_to_local_position(word.destination_cell) + Vector2(2, 2)
	destination.size = Vector2(tile_size - 4, tile_size - 4)
	destination.z_index = 1
	_add_panel_label(destination, word.get_destination_text(), VERTICAL_ALIGNMENT_CENTER, 12, Color(0.12, 0.06, 0.0))
	preview_root.add_child(destination)
	destination_nodes[index] = destination

## Oculta solamente la apariencia de los obstáculos. Las celdas continúan
## bloqueadas, por lo que puede usarse como un reto de memoria sin cambiar la
## solución del tablero mientras el jugador está trazando un camino.
func set_obstacle_clues_visible(visible: bool) -> void:
	obstacle_clues_visible = visible
	for obstacle: Vector2i in obstacles:
		_kill_obstacle_reveal_tween(obstacle)
		var tile := tile_rects.get(obstacle) as TextureRect
		if tile:
			tile.texture = obstacle_tile if visible else empty_tile
			tile.modulate = Color.WHITE
	revealed_obstacles.clear()
	_update_nearby_obstacle_clues()

## Oculta todas las pistas de obstáculos con una transición conjunta. El
## estado bloqueado de las celdas no cambia durante ni después del efecto.
func fade_out_obstacle_clues(duration: float = ALL_OBSTACLES_FADE_SECONDS) -> void:
	obstacle_clues_visible = true
	var tween := create_tween().set_parallel(true)
	for obstacle: Vector2i in obstacles:
		_kill_obstacle_reveal_tween(obstacle)
		var tile := tile_rects.get(obstacle) as TextureRect
		if tile:
			tile.texture = obstacle_tile
			tween.tween_property(tile, "modulate:a", 0.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if not is_inside_tree():
		return
	set_obstacle_clues_visible(false)

## Cuando las pistas generales están ocultas, revela con transparencia sólo
## los obstáculos ortogonalmente adyacentes a la punta del camino activo.
func set_nearby_obstacle_reveal(enabled: bool, opacity: float = 0.5) -> void:
	reveal_obstacles_near_tip = enabled
	nearby_obstacle_opacity = clampf(opacity, 0.1, 0.9)
	_update_nearby_obstacle_clues()

func _update_nearby_obstacle_clues() -> void:
	var desired_obstacles: Array[Vector2i] = []
	if not obstacle_clues_visible and reveal_obstacles_near_tip and drawing and active_index >= 0:
		var tip_cell: Vector2i = words[active_index].start_cell
		if not paths[active_index].is_empty():
			tip_cell = paths[active_index].back()
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var adjacent_cell := tip_cell + direction
			if adjacent_cell in obstacles:
				desired_obstacles.append(adjacent_cell)

	var previous_obstacles := revealed_obstacles.duplicate()
	revealed_obstacles = desired_obstacles
	for obstacle: Vector2i in previous_obstacles:
		if obstacle not in desired_obstacles:
			_fade_out_nearby_obstacle(obstacle)
	for obstacle: Vector2i in desired_obstacles:
		if obstacle not in previous_obstacles:
			_fade_in_nearby_obstacle(obstacle)

func _fade_in_nearby_obstacle(cell: Vector2i) -> void:
	var tile := tile_rects.get(cell) as TextureRect
	if not tile:
		return
	_kill_obstacle_reveal_tween(cell)
	if tile.texture != obstacle_tile:
		tile.texture = obstacle_tile
		tile.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "modulate:a", nearby_obstacle_opacity, NEARBY_OBSTACLE_FADE_SECONDS)
	obstacle_reveal_tweens[cell] = tween

func _fade_out_nearby_obstacle(cell: Vector2i) -> void:
	var tile := tile_rects.get(cell) as TextureRect
	if not tile:
		return
	_kill_obstacle_reveal_tween(cell)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(tile, "modulate:a", 0.0, NEARBY_OBSTACLE_FADE_SECONDS)
	tween.tween_callback(_finish_hiding_nearby_obstacle.bind(cell))
	obstacle_reveal_tweens[cell] = tween

func _finish_hiding_nearby_obstacle(cell: Vector2i) -> void:
	obstacle_reveal_tweens.erase(cell)
	if cell in revealed_obstacles or obstacle_clues_visible:
		return
	var tile := tile_rects.get(cell) as TextureRect
	if tile:
		tile.texture = empty_tile
		tile.modulate = Color.WHITE

func _kill_obstacle_reveal_tween(cell: Vector2i) -> void:
	var tween := obstacle_reveal_tweens.get(cell) as Tween
	if tween and tween.is_valid():
		tween.kill()
	obstacle_reveal_tweens.erase(cell)

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

func _create_word_panel(word_color: Color, lightened: bool) -> Panel:
	var panel: Panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if lightened:
		style.bg_color = word_color.lightened(0.55) if word_color != Color.WHITE else destination_color
	else:
		style.bg_color = word_color if word_color != Color.WHITE else Color(0.35, 0.45, 0.65)
	style.border_color = word_color.darkened(0.15)
	style.set_border_width_all(2 if lightened else 3)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _add_panel_label(panel: Panel, text: String, vertical: VerticalAlignment, font_size: int, font_color: Color) -> void:
	var label: Label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = vertical
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

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
	if active_index < 0 or active_index in connected:
		return
	if tile_owner.get(destination_cell, -1) != active_index:
		return

	var previous_cell: Vector2i = words[active_index].start_cell
	if not paths[active_index].is_empty():
		previous_cell = paths[active_index].back()
	if not _are_adjacent(previous_cell, destination_cell):
		return

	_finalize_connection(active_index)

func _try_resume_path(cell: Vector2i) -> void:
	var index: int = tile_owner.get(cell, -1)
	if index < 0 or index in connected or paths.get(index, []).is_empty():
		return
	if paths[index].back() != cell:
		return
	active_index = index
	drawing = true
	last_cell = cell
	_show_ring(index)
	word_selected.emit(words[index])
	_update_nearby_obstacle_clues()

func _try_retract_path(cell: Vector2i) -> bool:
	if active_index < 0 or paths.get(active_index, []).is_empty():
		return false
	var path: Array = paths[active_index]
	var current_tip: Vector2i = path.back()
	if not _are_adjacent(cell, current_tip):
		return false

	var is_previous_path_cell: bool = path.size() >= 2 and path[path.size() - 2] == cell
	var is_start_cell: bool = path.size() == 1 and words[active_index].start_cell == cell
	if not is_previous_path_cell and not is_start_cell:
		return false

	var removed_cell: Vector2i = path.pop_back()
	grid_state[removed_cell.y][removed_cell.x] = Cell.EMPTY
	tile_owner.erase(removed_cell)
	_reset_tile(removed_cell)
	_refresh_path_line(active_index)
	_update_nearby_obstacle_clues()
	return true

func _extend_path(cell: Vector2i) -> void:
	if active_index < 0 or cell in paths[active_index]:
		return
	if cell in tile_owner and tile_owner[cell] != active_index:
		return
	var previous: Vector2i

	if paths[active_index].is_empty():
		previous = words[active_index].start_cell
	else:
		previous = paths[active_index].back()
	if not _are_adjacent(cell, previous):
		return
	paths[active_index].append(cell)
	grid_state[cell.y][cell.x] = Cell.PATH
	tile_owner[cell] = active_index
	_set_path_tile_tint(cell, words[active_index].color)
	_refresh_path_line(active_index)
	_update_nearby_obstacle_clues()

func _clear_path(index: int) -> void:
	for cell: Vector2i in paths.get(index, []):
		grid_state[cell.y][cell.x] = Cell.EMPTY
		tile_owner.erase(cell)
		_reset_tile(cell)
	paths[index] = []
	_remove_path_line(index)
	_update_nearby_obstacle_clues()

func _reset_connected_path(index: int) -> void:
	if index not in connected:
		return
	connected.erase(index)
	_reset_tile(words[index].destination_cell)
	_clear_path(index)
	path_reset.emit(words[index], index)

func _finalize_connection(index: int) -> void:
	if index in connected:
		return
	connected.append(index)
	for cell: Vector2i in paths[index]:
		_set_path_tile_tint(cell, words[index].color)
	_set_path_tile_tint(words[index].destination_cell, words[index].color)
	_refresh_path_line(index)
	drawing = false
	active_index = -1
	selection_ring.visible = false
	_update_nearby_obstacle_clues()
	input_enabled = false
	word_connected.emit(words[index], index)

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
	var actual_position: Vector2 = cell_to_local_position(words[index].start_cell)
	selection_ring.position = actual_position - Vector2(5, 5)
	selection_ring.size = Vector2(tile_size + 10, tile_size + 10)
	selection_ring.color = words[index].color
	selection_ring.visible = true
	selection_ring.modulate = Color.WHITE
	if ring_tween and ring_tween.is_valid():
		ring_tween.kill()
	ring_tween = create_tween().set_loops()
	ring_tween.tween_property(selection_ring, "modulate:a", 0.2, 0.4)
	ring_tween.tween_property(selection_ring, "modulate:a", 1.0, 0.4)

func _local_to_cell(actual_position: Vector2) -> Vector2i:
	return Vector2i(
		floori((actual_position.x - grid_origin.x) / tile_size),
		floori((actual_position.y - grid_origin.y) / tile_size)
	)

func _are_adjacent(first: Vector2i, second: Vector2i) -> bool:
	var delta: Vector2i = first - second
	return (abs(delta.x) == 1 and delta.y == 0) or (delta.x == 0 and abs(delta.y) == 1)

func _set_tile_color(cell: Vector2i, color: Color) -> void:
	var tile: TextureRect = tile_rects.get(cell) as TextureRect
	if tile:
		tile.modulate = color

func _set_path_tile_tint(cell: Vector2i, color: Color) -> void:
	_set_tile_color(cell, Color.WHITE.lerp(color, path_tile_tint))

func _refresh_all_path_visuals() -> void:
	if not is_instance_valid(preview_root):
		return
	for index in paths:
		for cell: Vector2i in paths[index]:
			_set_path_tile_tint(cell, words[index].color)
		if index in connected:
			_set_path_tile_tint(words[index].destination_cell, words[index].color)
		_refresh_path_line(index)

func _refresh_path_line(index: int) -> void:
	if not is_instance_valid(preview_root) or not paths.has(index) or index >= words.size():
		return
	var path: Array = paths[index]
	if path.is_empty():
		_remove_path_line(index)
		return

	var line: Line2D = path_lines.get(index) as Line2D
	if not line:
		line = Line2D.new()
		line.name = "PathLine_%d" % index
		line.z_index = 0
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.antialiased = true
		preview_root.add_child(line)
		path_lines[index] = line

	line.width = path_line_width
	line.default_color = words[index].color
	line.clear_points()
	line.add_point(_cell_center(words[index].start_cell))
	for cell: Vector2i in path:
		line.add_point(_cell_center(cell))
	if index in connected:
		line.add_point(_cell_center(words[index].destination_cell))
	_refresh_path_tip(index, path.back())

func _remove_path_line(index: int) -> void:
	var line: Line2D = path_lines.get(index) as Line2D
	if line:
		line.queue_free()
	path_lines.erase(index)
	_remove_path_tip(index)

func _refresh_path_tip(index: int, cell: Vector2i) -> void:
	if index in connected:
		_remove_path_tip(index)
		return
	var tip: Polygon2D = path_tips.get(index) as Polygon2D
	if not tip:
		tip = Polygon2D.new()
		tip.name = "PathTip_%d" % index
		tip.z_index = 0
		preview_root.add_child(tip)
		path_tips[index] = tip

	var radius: float = path_line_width * path_tip_scale * 0.5
	var circle_points: PackedVector2Array = PackedVector2Array()
	for point_index in range(24):
		var angle: float = TAU * float(point_index) / 24.0
		circle_points.append(Vector2(cos(angle), sin(angle)) * radius)
	tip.polygon = circle_points
	tip.color = words[index].color
	tip.position = _cell_center(cell)

func _remove_path_tip(index: int) -> void:
	var tip: Polygon2D = path_tips.get(index) as Polygon2D
	if tip:
		tip.queue_free()
	path_tips.erase(index)

func _cell_center(cell: Vector2i) -> Vector2:
	return cell_to_local_position(cell) + Vector2.ONE * (float(tile_size) * 0.5)

func _reset_tile(cell: Vector2i) -> void:
	var tile: TextureRect = tile_rects.get(cell) as TextureRect
	if tile:
		tile.modulate = Color.WHITE
