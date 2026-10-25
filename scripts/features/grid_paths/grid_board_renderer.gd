@tool
extends RefCounted
class_name GridBoardRenderer

## Genera los nodos de GridBoard durante la autoría en el editor. Durante la
## partida enlaza los nodos guardados y actualiza sus caminos y estados.

var board: GridBoard
var _base_colors: Dictionary = {}


func _init(owner_board: GridBoard) -> void:
	board = owner_board


func rebuild_preview() -> void:
	if not is_instance_valid(board.preview_root):
		return
	board.watch_word_changes()
	_base_colors.clear()
	for child: Node in board.preview_root.get_children():
		child.free()
	board.tile_rects.clear()
	board.word_nodes.clear()
	board.path_lines.clear()
	board.path_tips.clear()
	board.destination_nodes.clear()
	if Engine.is_editor_hint() and not board.show_preview_in_editor:
		return
	for row: int in range(board.rows):
		for column: int in range(board.columns):
			var cell: Vector2i = Vector2i(column, row)
			var tile: TextureRect = board.tile_scene.instantiate() as TextureRect
			tile.name = "Tile_%d_%d" % [column, row]
			tile.position = board.cell_to_local_position(cell) + Vector2.ONE
			tile.size = Vector2(board.tile_size - 2, board.tile_size - 2)
			tile.texture = board.obstacle_tile if cell in board.obstacles else board.empty_tile
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_add_saved_child(tile)
			board.tile_rects[cell] = tile
	for index: int in board.words.size():
		var word: GridWordData = board.words[index]
		if is_instance_valid(word):
			_add_destination_preview(word, index)
			_add_word_preview(word, index)
			var line: Line2D = board.path_line_scene.instantiate() as Line2D
			line.name = "PathLine_%d" % index
			line.hide()
			_add_saved_child(line)
			board.path_lines[index] = line
			var tip: Polygon2D = board.path_tip_scene.instantiate() as Polygon2D
			tip.name = "PathTip_%d" % index
			tip.hide()
			_add_saved_child(tip)
			board.path_tips[index] = tip
	board.add_keyboard_cursor()
	refresh_all_paths()


func _add_saved_child(node: Node) -> void:
	board.preview_root.add_child(node)
	# La estructura generada en el editor se guarda con la escena del nivel.
	_own_generated_node(node, board.owner if board.owner != null else board)


func _own_generated_node(node: Node, scene_root: Node) -> void:
	node.scene_file_path = ""
	node.owner = scene_root
	for child: Node in node.get_children():
		_own_generated_node(child, scene_root)


func bind_saved_nodes() -> void:
	board.tile_rects.clear()
	board.word_nodes.clear()
	board.destination_nodes.clear()
	board.path_lines.clear()
	board.path_tips.clear()
	for row: int in range(board.rows):
		for column: int in range(board.columns):
			var tile: TextureRect = (
				board.preview_root.get_node_or_null("Tile_%d_%d" % [column, row]) as TextureRect
			)
			if tile == null:
				push_error(
					"Actualiza los nodos de GridBoard en el inspector y guarda la escena antes de jugar."
				)
				return
			board.tile_rects[Vector2i(column, row)] = tile
			base_color(tile)
	for index: int in range(board.words.size()):
		var word: Panel = board.preview_root.get_node_or_null("Word_%d" % index) as Panel
		var destination: Panel = (
			board.preview_root.get_node_or_null("Destination_%d" % index) as Panel
		)
		var line: Line2D = board.preview_root.get_node_or_null("PathLine_%d" % index) as Line2D
		var tip: Polygon2D = board.preview_root.get_node_or_null("PathTip_%d" % index) as Polygon2D
		if word == null or destination == null or line == null or tip == null:
			push_error(
				"Faltan fichas del tablero. Actualiza los nodos en el inspector y guarda la escena."
			)
			return
		board.word_nodes[index] = word
		base_color(word)
		board.destination_nodes[index] = destination
		board.path_lines[index] = line
		board.path_tips[index] = tip
	board.keyboard_cursor = board.preview_root.get_node("KeyboardCursor") as Panel
	board.update_keyboard_cursor()
	refresh_all_paths()


func _add_word_preview(word: GridWordData, index: int) -> void:
	if not board.is_valid_cell(word.start_cell):
		return
	var panel: Panel = _create_word_panel(word.color, false)
	panel.name = "Word_%d" % index
	panel.position = board.cell_to_local_position(word.start_cell) + Vector2(2, 2)
	panel.size = Vector2(board.tile_size - 4, board.tile_size - 4)
	var sprite: TextureRect = panel.get_node("Icon") as TextureRect
	var label: Label = panel.get_node("Label") as Label
	sprite.texture = word.sprite
	sprite.visible = word.sprite != null
	label.visible = word.sprite == null or not word.start_text.is_empty()
	label.text = word.start_text if word.sprite else word.get_start_text()
	label.vertical_alignment = (
		VERTICAL_ALIGNMENT_BOTTOM if word.sprite else VERTICAL_ALIGNMENT_CENTER
	)
	_add_saved_child(panel)
	board.word_nodes[index] = panel


func _add_destination_preview(word: GridWordData, index: int) -> void:
	if not board.is_valid_cell(word.destination_cell):
		return
	var destination: Panel = _create_word_panel(word.color, true)
	destination.name = "Destination_%d" % index
	destination.position = board.cell_to_local_position(word.destination_cell) + Vector2(2, 2)
	destination.size = Vector2(board.tile_size - 4, board.tile_size - 4)
	var arrived: TextureRect = destination.get_node("ArrivedAnimal") as TextureRect
	arrived.texture = word.sprite
	arrived.visible = index in board.connected
	var label: Label = destination.get_node("Label") as Label
	label.text = word.get_destination_text()
	label.add_theme_font_size_override("font_size", 17 if label.text.length() > 6 else 20)
	_add_saved_child(destination)
	board.destination_nodes[index] = destination
	if not board.destination_word_colors:
		destination.add_theme_stylebox_override("panel", destination_style(Color("b99562")))


func destination_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = board.destination_style.duplicate() as StyleBoxFlat
	style.bg_color = color.lightened(0.55)
	style.border_color = color.darkened(0.15)
	return style


func _create_word_panel(word_color: Color, lightened: bool) -> Panel:
	var template: PackedScene = board.destination_scene if lightened else board.word_scene
	var panel: Panel = template.instantiate() as Panel
	var base_style: StyleBoxFlat = board.destination_style if lightened else board.word_style
	var style: StyleBoxFlat = base_style.duplicate() as StyleBoxFlat
	style.bg_color = (
		(word_color.lightened(0.55) if word_color != Color.WHITE else board.destination_color)
		if lightened
		else (word_color if word_color != Color.WHITE else base_style.bg_color)
	)
	style.border_color = word_color.darkened(0.15)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func show_selection_ring(index: int) -> Tween:
	var actual_position: Vector2 = board.cell_to_local_position(board.words[index].start_cell)
	board.selection_ring.position = actual_position - Vector2(5, 5)
	board.selection_ring.size = Vector2(board.tile_size + 10, board.tile_size + 10)
	board.selection_ring.color = board.words[index].color
	board.selection_ring.visible = true
	board.selection_ring.modulate = Color.WHITE
	var tween: Tween = board.create_tween().set_loops()
	tween.tween_property(board.selection_ring, "modulate:a", 0.2, 0.4)
	tween.tween_property(board.selection_ring, "modulate:a", 1.0, 0.4)
	return tween


func set_tile_color(cell: Vector2i, color: Color) -> void:
	var tile: TextureRect = board.tile_rects.get(cell) as TextureRect
	if tile:
		tile.modulate = base_color(tile) * color


func base_color(control: Control) -> Color:
	if not _base_colors.has(control):
		_base_colors[control] = control.modulate
	return _base_colors[control]


func set_path_tile_tint(cell: Vector2i, color: Color) -> void:
	set_tile_color(cell, Color.WHITE.lerp(color, board.path_tile_tint))


func refresh_all_paths() -> void:
	if not is_instance_valid(board.preview_root):
		return
	for index: int in board.paths:
		if board.word_nodes.has(index):
			var word: Control = board.word_nodes[index]
			word.modulate = (
				base_color(word) * Color(1, 1, 1, 0.35 if index in board.connected else 1.0)
			)
		if board.destination_nodes.has(index):
			var arrived: Control = (
				board.destination_nodes[index].get_node_or_null("ArrivedAnimal") as Control
			)
			if arrived:
				arrived.visible = index in board.connected
		for cell: Vector2i in board.paths[index]:
			set_path_tile_tint(cell, board.words[index].color)
		if index in board.connected:
			set_path_tile_tint(board.words[index].destination_cell, board.words[index].color)
		refresh_path_line(index)


func refresh_path_line(index: int) -> void:
	if (
		not is_instance_valid(board.preview_root)
		or not board.paths.has(index)
		or index >= board.words.size()
	):
		return
	var path: Array = board.paths[index]
	if path.is_empty():
		remove_path_line(index)
		return
	var line: Line2D = board.path_lines.get(index) as Line2D
	line.show()
	line.width = board.path_line_width
	line.default_color = board.words[index].color
	line.clear_points()
	line.add_point(_cell_center(board.words[index].start_cell))
	for cell: Vector2i in path:
		line.add_point(_cell_center(cell))
	if index in board.connected:
		line.add_point(_cell_center(board.words[index].destination_cell))
	_refresh_path_tip(index, path.back())


func remove_path_line(index: int) -> void:
	var line: Line2D = board.path_lines.get(index) as Line2D
	if line:
		line.clear_points()
		line.hide()
	_remove_path_tip(index)


func _refresh_path_tip(index: int, cell: Vector2i) -> void:
	if index in board.connected:
		_remove_path_tip(index)
		return
	var tip: Polygon2D = board.path_tips.get(index) as Polygon2D
	tip.show()
	var radius: float = board.path_line_width * board.path_tip_scale * 0.5
	var circle_points: PackedVector2Array = PackedVector2Array()
	for point_index: int in range(24):
		var angle: float = TAU * float(point_index) / 24.0
		circle_points.append(Vector2(cos(angle), sin(angle)) * radius)
	tip.polygon = circle_points
	tip.color = board.words[index].color
	tip.position = _cell_center(cell)


func _remove_path_tip(index: int) -> void:
	var tip: Polygon2D = board.path_tips.get(index) as Polygon2D
	if tip:
		tip.hide()


func _cell_center(cell: Vector2i) -> Vector2:
	return board.cell_to_local_position(cell) + Vector2.ONE * (float(board.tile_size) * 0.5)


func reset_tile(cell: Vector2i) -> void:
	var tile: TextureRect = board.tile_rects.get(cell) as TextureRect
	if tile:
		tile.modulate = base_color(tile)
