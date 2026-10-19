@tool
extends RefCounted
class_name GridBoardRenderer

## Construye y actualiza la representación visual de GridBoard. Las reglas de
## conexión, ocupación y entrada permanecen en el tablero.

var board: Node2D

func _init(owner_board: Node2D) -> void:
	board = owner_board

func rebuild_preview() -> void:
	if not is_instance_valid(board.preview_root):
		return
	board._watch_word_changes()
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
			var cell := Vector2i(column, row)
			var tile := TextureRect.new()
			tile.name = "Tile_%d_%d" % [column, row]
			tile.position = board.cell_to_local_position(cell) + Vector2.ONE
			tile.size = Vector2(board.tile_size - 2, board.tile_size - 2)
			tile.texture = board.obstacle_tile if cell in board.obstacles else board.empty_tile
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			board.preview_root.add_child(tile)
			board.tile_rects[cell] = tile
	for index: int in board.words.size():
		var word: GridWordData = board.words[index]
		if is_instance_valid(word):
			_add_destination_preview(word, index)
			_add_word_preview(word, index)
	board._add_keyboard_cursor()
	refresh_all_paths()

func _add_word_preview(word: GridWordData, index: int) -> void:
	if not board.is_valid_cell(word.start_cell):
		return
	var panel := _create_word_panel(word.color, false)
	panel.name = "Word_%d" % index
	panel.position = board.cell_to_local_position(word.start_cell) + Vector2(2, 2)
	panel.size = Vector2(board.tile_size - 4, board.tile_size - 4)
	panel.z_index = 2
	if word.sprite:
		var sprite := TextureRect.new()
		sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sprite.texture = word.sprite
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(sprite)
		if not word.start_text.is_empty():
			_add_panel_label(panel, word.start_text, VERTICAL_ALIGNMENT_BOTTOM, 12, Color.WHITE)
	else:
		_add_panel_label(panel, word.get_start_text(), VERTICAL_ALIGNMENT_CENTER, 14, Color.WHITE)
	board.preview_root.add_child(panel)
	board.word_nodes[index] = panel

func _add_destination_preview(word: GridWordData, index: int) -> void:
	if not board.is_valid_cell(word.destination_cell):
		return
	var destination := _create_word_panel(word.color, true)
	destination.name = "Destination_%d" % index
	destination.position = board.cell_to_local_position(word.destination_cell) + Vector2(2, 2)
	destination.size = Vector2(board.tile_size - 4, board.tile_size - 4)
	destination.z_index = 1
	_add_panel_label(destination, word.get_destination_text(), VERTICAL_ALIGNMENT_CENTER, 12, Color(0.12, 0.06, 0.0))
	board.preview_root.add_child(destination)
	board.destination_nodes[index] = destination

func _create_word_panel(word_color: Color, lightened: bool) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = (word_color.lightened(0.55) if word_color != Color.WHITE else board.destination_color) if lightened else (word_color if word_color != Color.WHITE else Color(0.35, 0.45, 0.65))
	style.border_color = word_color.darkened(0.15)
	style.set_border_width_all(2 if lightened else 3)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _add_panel_label(panel: Panel, text: String, vertical: VerticalAlignment, font_size: int, font_color: Color) -> void:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = vertical
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

func show_selection_ring(index: int) -> Tween:
	var actual_position: Vector2 = board.cell_to_local_position(board.words[index].start_cell)
	board.selection_ring.position = actual_position - Vector2(5, 5)
	board.selection_ring.size = Vector2(board.tile_size + 10, board.tile_size + 10)
	board.selection_ring.color = board.words[index].color
	board.selection_ring.visible = true
	board.selection_ring.modulate = Color.WHITE
	var tween := board.create_tween().set_loops()
	tween.tween_property(board.selection_ring, "modulate:a", 0.2, 0.4)
	tween.tween_property(board.selection_ring, "modulate:a", 1.0, 0.4)
	return tween

func set_tile_color(cell: Vector2i, color: Color) -> void:
	var tile := board.tile_rects.get(cell) as TextureRect
	if tile:
		tile.modulate = color

func set_path_tile_tint(cell: Vector2i, color: Color) -> void:
	set_tile_color(cell, Color.WHITE.lerp(color, board.path_tile_tint))

func refresh_all_paths() -> void:
	if not is_instance_valid(board.preview_root):
		return
	for index: int in board.paths:
		for cell: Vector2i in board.paths[index]:
			set_path_tile_tint(cell, board.words[index].color)
		if index in board.connected:
			set_path_tile_tint(board.words[index].destination_cell, board.words[index].color)
		refresh_path_line(index)

func refresh_path_line(index: int) -> void:
	if not is_instance_valid(board.preview_root) or not board.paths.has(index) or index >= board.words.size():
		return
	var path: Array = board.paths[index]
	if path.is_empty():
		remove_path_line(index)
		return
	var line := board.path_lines.get(index) as Line2D
	if not line:
		line = Line2D.new()
		line.name = "PathLine_%d" % index
		line.z_index = 0
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.antialiased = true
		board.preview_root.add_child(line)
		board.path_lines[index] = line
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
	var line := board.path_lines.get(index) as Line2D
	if line:
		line.queue_free()
	board.path_lines.erase(index)
	_remove_path_tip(index)

func _refresh_path_tip(index: int, cell: Vector2i) -> void:
	if index in board.connected:
		_remove_path_tip(index)
		return
	var tip := board.path_tips.get(index) as Polygon2D
	if not tip:
		tip = Polygon2D.new()
		tip.name = "PathTip_%d" % index
		tip.z_index = 0
		board.preview_root.add_child(tip)
		board.path_tips[index] = tip
	var radius: float = board.path_line_width * board.path_tip_scale * 0.5
	var circle_points := PackedVector2Array()
	for point_index: int in range(24):
		var angle: float = TAU * float(point_index) / 24.0
		circle_points.append(Vector2(cos(angle), sin(angle)) * radius)
	tip.polygon = circle_points
	tip.color = board.words[index].color
	tip.position = _cell_center(cell)

func _remove_path_tip(index: int) -> void:
	var tip := board.path_tips.get(index) as Polygon2D
	if tip:
		tip.queue_free()
	board.path_tips.erase(index)

func _cell_center(cell: Vector2i) -> Vector2:
	return board.cell_to_local_position(cell) + Vector2.ONE * (float(board.tile_size) * 0.5)

func reset_tile(cell: Vector2i) -> void:
	var tile := board.tile_rects.get(cell) as TextureRect
	if tile:
		tile.modulate = Color.WHITE
