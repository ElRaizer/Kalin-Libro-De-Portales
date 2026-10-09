extends RefCounted
class_name GridObstacleHints

var board: Node2D

func _init(owner_board: Node2D) -> void:
	board = owner_board

func set_visible(value: bool) -> void:
	board.obstacle_clues_visible = value
	for obstacle: Vector2i in board.obstacles:
		_kill_tween(obstacle)
		var tile := board.tile_rects.get(obstacle) as TextureRect
		if tile:
			tile.texture = board.obstacle_tile if value else board.empty_tile
			tile.modulate = Color.WHITE
	board.revealed_obstacles.clear()
	update_nearby()

func fade_out_all(duration: float) -> void:
	board.obstacle_clues_visible = true
	var tween := board.create_tween().set_parallel(true)
	for obstacle: Vector2i in board.obstacles:
		_kill_tween(obstacle)
		var tile := board.tile_rects.get(obstacle) as TextureRect
		if tile:
			tile.texture = board.obstacle_tile
			tween.tween_property(tile, "modulate:a", 0.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if board.is_inside_tree():
		set_visible(false)

func set_nearby_reveal(enabled: bool, opacity: float) -> void:
	board.reveal_obstacles_near_tip = enabled
	board.nearby_obstacle_opacity = clampf(opacity, 0.1, 0.9)
	update_nearby()

func update_nearby() -> void:
	var desired: Array[Vector2i] = []
	if not board.obstacle_clues_visible and board.reveal_obstacles_near_tip and board.drawing and board.active_index >= 0:
		var tip_cell: Vector2i = board.words[board.active_index].start_cell
		if not board.paths[board.active_index].is_empty():
			tip_cell = board.paths[board.active_index].back()
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var adjacent := tip_cell + direction
			if adjacent in board.obstacles:
				desired.append(adjacent)
	var previous: Array = board.revealed_obstacles.duplicate()
	board.revealed_obstacles = desired
	for obstacle: Vector2i in previous:
		if obstacle not in desired:
			_fade_out(obstacle)
	for obstacle: Vector2i in desired:
		if obstacle not in previous:
			_fade_in(obstacle)

func _fade_in(cell: Vector2i) -> void:
	var tile := board.tile_rects.get(cell) as TextureRect
	if not tile:
		return
	_kill_tween(cell)
	if tile.texture != board.obstacle_tile:
		tile.texture = board.obstacle_tile
		tile.modulate = Color(1, 1, 1, 0)
	var tween := board.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "modulate:a", board.nearby_obstacle_opacity, board.NEARBY_OBSTACLE_FADE_SECONDS)
	board.obstacle_reveal_tweens[cell] = tween

func _fade_out(cell: Vector2i) -> void:
	var tile := board.tile_rects.get(cell) as TextureRect
	if not tile:
		return
	_kill_tween(cell)
	var tween := board.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(tile, "modulate:a", 0.0, board.NEARBY_OBSTACLE_FADE_SECONDS)
	tween.tween_callback(_finish_hiding.bind(cell))
	board.obstacle_reveal_tweens[cell] = tween

func _finish_hiding(cell: Vector2i) -> void:
	board.obstacle_reveal_tweens.erase(cell)
	if cell in board.revealed_obstacles or board.obstacle_clues_visible:
		return
	var tile := board.tile_rects.get(cell) as TextureRect
	if tile:
		tile.texture = board.empty_tile
		tile.modulate = Color.WHITE

func _kill_tween(cell: Vector2i) -> void:
	var tween := board.obstacle_reveal_tweens.get(cell) as Tween
	if tween and tween.is_valid():
		tween.kill()
	board.obstacle_reveal_tweens.erase(cell)
