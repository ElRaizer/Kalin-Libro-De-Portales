@tool
extends Node2D
class_name GridBoard

## Componente reutilizable para previsualizar un tablero de caminos en Godot.
## Sus propiedades se editan en el Inspector de cada instancia de GridBoard.
## También controla el arrastre y emite señales para que el nivel decida sus
## diálogos, recompensas y condiciones narrativas.

signal animal_selected(animal: GridAnimalData)
signal animal_connected(animal: GridAnimalData, animal_index: int)
signal drawing_stopped

enum Cell { EMPTY, OBSTACLE, ANIMAL, DESTINATION, PATH }

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

@export_category("Contenido del nivel")
@export var obstacles: Array[Vector2i] = []:
	set(value):
		obstacles = value
		_schedule_rebuild()

@export var animals: Array[GridAnimalData] = []:
	set(value):
		animals = value
		_schedule_rebuild()

@export_category("Editor")
@export var show_preview_in_editor: bool = true:
	set(value):
		show_preview_in_editor = value
		_schedule_rebuild()

@onready var preview_root: Node2D = $Preview
@onready var selection_ring: ColorRect = $SelectionRing
var _rebuild_queued: bool = false
var _watched_animals: Array[GridAnimalData] = []
var grid_state: Array[Array] = []
var tile_owner: Dictionary = {}
var paths: Dictionary = {}
var connected: Array[int] = []
var tile_rects: Dictionary = {}
var animal_nodes: Dictionary = {}
var drawing: bool = false
var active_index: int = -1
var last_cell: Vector2i = Vector2i(-1, -1)
var input_enabled: bool = true
var ring_tween: Tween

func _ready() -> void:
	selection_ring.visible = false
	if Engine.is_editor_hint():
		_watch_animal_changes()
		rebuild_preview()
	else:
		start_game()

func _exit_tree() -> void:
	for animal in _watched_animals:
		if is_instance_valid(animal) and animal.changed.is_connected(_schedule_rebuild):
			animal.changed.disconnect(_schedule_rebuild)
	_watched_animals.clear()

## Permite que una escena de nivel o el Inspector fuerce la actualización.
func rebuild_preview() -> void:
	_rebuild_queued = false
	if not is_instance_valid(preview_root):
		return
	_watch_animal_changes()
	for child in preview_root.get_children():
		child.free()
	tile_rects.clear()
	animal_nodes.clear()

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

	for index in animals.size():
		var animal: GridAnimalData = animals[index]
		if not is_instance_valid(animal):
			continue
		_add_destination_preview(animal, index)
		_add_animal_preview(animal, index)

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
	return not animals.is_empty() and connected.size() == animals.size()

func set_interaction_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		_stop_drawing()

func get_animal_node(animal_index: int) -> TextureRect:
	return animal_nodes.get(animal_index) as TextureRect

func _add_animal_preview(animal: GridAnimalData, index: int) -> void:
	if not is_valid_cell(animal.start_cell):
		return
	var sprite: TextureRect = TextureRect.new()
	sprite.name = "Animal_%d" % index
	sprite.position = cell_to_local_position(animal.start_cell) + Vector2(2, 2)
	sprite.size = Vector2(tile_size - 4, tile_size - 4)
	sprite.texture = animal.sprite
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = 2
	preview_root.add_child(sprite)
	animal_nodes[index] = sprite

func _add_destination_preview(animal: GridAnimalData, index: int) -> void:
	if not is_valid_cell(animal.destination_cell):
		return
	var destination: Panel = Panel.new()
	destination.name = "Destination_%d" % index
	destination.position = cell_to_local_position(animal.destination_cell) + Vector2(2, 2)
	destination.size = Vector2(tile_size - 4, tile_size - 4)
	destination.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destination.z_index = 1
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = animal.color.lightened(0.55) if animal.color != Color.WHITE else destination_color
	style.border_color = animal.color.darkened(0.15)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	destination.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = animal.maya_word
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.12, 0.06, 0.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destination.add_child(label)
	preview_root.add_child(destination)

func _schedule_rebuild() -> void:
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	call_deferred("rebuild_preview")

func _watch_animal_changes() -> void:
	for animal in _watched_animals:
		if is_instance_valid(animal) and animal.changed.is_connected(_schedule_rebuild):
			animal.changed.disconnect(_schedule_rebuild)
	_watched_animals.clear()
	for animal in animals:
		if is_instance_valid(animal):
			animal.changed.connect(_schedule_rebuild)
			_watched_animals.append(animal)

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
	for index in animals.size():
		var animal: GridAnimalData = animals[index]
		if not is_instance_valid(animal):
			continue
		if is_valid_cell(animal.start_cell):
			grid_state[animal.start_cell.y][animal.start_cell.x] = Cell.ANIMAL
			tile_owner[animal.start_cell] = index
		if is_valid_cell(animal.destination_cell):
			grid_state[animal.destination_cell.y][animal.destination_cell.x] = Cell.DESTINATION
			tile_owner[animal.destination_cell] = index
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

func _handle_press(cell: Vector2i) -> void:
	if not is_valid_cell(cell):
		return
	match grid_state[cell.y][cell.x]:
		Cell.ANIMAL:
			var index: int = tile_owner[cell]
			if index in connected:
				return
			_clear_path(index)
			active_index = index
			drawing = true
			last_cell = cell
			_show_ring(index)
			animal_selected.emit(animals[index])
		Cell.EMPTY, Cell.PATH:
			if drawing:
				_extend_path(cell)
		Cell.DESTINATION:
			if drawing and tile_owner.get(cell, -1) == active_index:
				_finalize_connection(active_index)

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
	match grid_state[cell.y][cell.x]:
		Cell.EMPTY, Cell.PATH:
			_extend_path(cell)
		Cell.DESTINATION:
			if tile_owner.get(cell, -1) == active_index:
				_finalize_connection(active_index)

func _extend_path(cell: Vector2i) -> void:
	if active_index < 0 or cell in paths[active_index]:
		return
	if cell in tile_owner and tile_owner[cell] != active_index:
		return
	var previous: Vector2i

	if paths[active_index].is_empty():
		previous = animals[active_index].start_cell
	else:
		previous = paths[active_index].back()
	if not _are_adjacent(cell, previous):
		return
	paths[active_index].append(cell)
	grid_state[cell.y][cell.x] = Cell.PATH
	tile_owner[cell] = active_index
	_set_tile_color(cell, animals[active_index].color.lightened(0.4))

func _clear_path(index: int) -> void:
	for cell: Vector2i in paths.get(index, []):
		grid_state[cell.y][cell.x] = Cell.EMPTY
		tile_owner.erase(cell)
		_reset_tile(cell)
	paths[index] = []

func _finalize_connection(index: int) -> void:
	if index in connected:
		return
	connected.append(index)
	for cell: Vector2i in paths[index]:
		_set_tile_color(cell, animals[index].color)
	_set_tile_color(animals[index].destination_cell, animals[index].color.lightened(0.25))
	drawing = false
	active_index = -1
	selection_ring.visible = false
	input_enabled = false
	animal_connected.emit(animals[index], index)

func _stop_drawing() -> void:
	if not drawing and active_index < 0:
		return
	drawing = false
	active_index = -1
	selection_ring.visible = false
	if ring_tween and ring_tween.is_valid():
		ring_tween.kill()
	drawing_stopped.emit()

func _show_ring(index: int) -> void:
	var actual_position: Vector2 = cell_to_local_position(animals[index].start_cell)
	selection_ring.position = actual_position - Vector2(5, 5)
	selection_ring.size = Vector2(tile_size + 10, tile_size + 10)
	selection_ring.color = animals[index].color
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

func _reset_tile(cell: Vector2i) -> void:
	var tile: TextureRect = tile_rects.get(cell) as TextureRect
	if tile:
		tile.modulate = Color.WHITE
