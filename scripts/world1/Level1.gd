## Level1.gd  v4 — Sak Beh (Los Caminos Blancos)
## FIXES v4:
##   • await con is_inside_tree() → nunca crashea al navegar
##   • _completing flag → _on_level_complete() llamado exactamente 1 vez
##   • _safe_navigate() mata tweens antes de cambiar escena
##   • Instrucciones con panel de fondo visible
##   • Diálogo con Skip integrado (clic para cerrar)
extends Node2D

# ─── Grid ────────────────────────────────────────────────────────────────────
const COLS := 9;  const ROWS := 7
const TILE_PX := 80;  const GRID_X := 80;  const GRID_Y := 95
enum Cell { EMPTY, OBSTACLE, ANIMAL, HOUSE, PATH }

# ─── Recursos ────────────────────────────────────────────────────────────────
const RES_BG     := "res://Arte/backgrounds/bg_level1.svg"
const RES_PEEK   := "res://Arte/sprites/animal_peek.svg"
const RES_MIIS   := "res://Arte/sprites/animal_miis.svg"
const RES_KAAX   := "res://Arte/sprites/animal_kaax.svg"
const RES_TILE_E := "res://Arte/tiles/tile_empty.svg"
const RES_TILE_O := "res://Arte/tiles/tile_obstacle.svg"

# ─── Datos (BFS-verificados, 3 rutas sin solapamiento) ───────────────────────
const ANIMALS := [
	{ "id":0, "maya":"Peek'", "spanish":"Perro",   "sprite":RES_PEEK,
	  "grid_pos":Vector2i(0,1), "house_pos":Vector2i(8,1),
	  "color":Color(0.90,0.55,0.20) },
	{ "id":1, "maya":"Miis",  "spanish":"Gato",    "sprite":RES_MIIS,
	  "grid_pos":Vector2i(0,3), "house_pos":Vector2i(8,3),
	  "color":Color(0.55,0.38,0.85) },
	{ "id":2, "maya":"Kaax",  "spanish":"Gallina", "sprite":RES_KAAX,
	  "grid_pos":Vector2i(0,5), "house_pos":Vector2i(8,5),
	  "color":Color(0.25,0.65,0.30) },
]
# Soluciones: Peek'→fila2, Miis→fila4, Kaax→fila6 (3 obstáculos, BFS OK)
const OBSTACLES := [ Vector2i(3,1), Vector2i(5,3), Vector2i(4,5) ]

# ─── Estado ──────────────────────────────────────────────────────────────────
var grid_state: Array;  var tile_owner: Dictionary
var paths: Dictionary;  var connected: Array[int]
var drawing := false;   var active_id := -1
var last_gp := Vector2i(-1,-1)
var ring_tween: Tween
var _completing := false          # FIX: evita llamar complete más de 1 vez
var _dialogue_open := false       # FIX: controla si el diálogo está activo
var tile_rects: Dictionary;       var animal_nodes: Dictionary

# ─── Nodos ──────────────────────────────────────────────────────────────────
@onready var bg_texture:   TextureRect = $Background
@onready var grid_root:    Node2D      = $GridRoot
@onready var sel_ring:     ColorRect   = $GridRoot/SelectionRing
@onready var dialogue:     Panel       = $UI/DialoguePanel
@onready var dlg_phrase:   Label       = $UI/DialoguePanel/VBox/Phrase
@onready var dlg_hint:     Label       = $UI/DialoguePanel/VBox/Hint
@onready var dlg_animal:   TextureRect = $UI/DialoguePanel/AnimalIcon
@onready var magic_lbl:    Label       = $UI/TopBar/MagicLabel
@onready var instr_lbl:    Label       = $UI/InstrPanel/InstrLbl
@onready var complete_pan: Panel       = $UI/CompletePanel
@onready var libro:        CanvasLayer = $LibroHechizos

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	bg_texture.texture = load(RES_BG)
	_apply_friendly_theme()
	_init_grid(); _build_tiles(); _build_animal_sprites(); _refresh_hud()
	dialogue.visible = false;  complete_pan.visible = false
	sel_ring.visible = false
	_set_instr("Haz clic en un animal y arrastra hasta su casa.\nConecta los tres para completar el nivel.")
	GameManager.magic_points_changed.connect(func(_v): _refresh_hud())

## Estilo consistente y de alto contraste (igual que el resto de niveles):
## paneles crema con borde cafe (texto oscuro legible) y barra de
## instrucciones oscura semitransparente (texto claro legible). Sin esto,
## el dialogo y el panel de "completado" quedaban con el tema por defecto
## de Godot y el texto oscuro podia perderse contra un fondo oscuro.
func _apply_friendly_theme() -> void:
	var cream := StyleBoxFlat.new()
	cream.bg_color = Color(0.98, 0.94, 0.84, 0.97)
	cream.border_color = Color(0.45, 0.30, 0.15)
	cream.set_border_width_all(4)
	cream.corner_radius_top_left = 14;     cream.corner_radius_top_right = 14
	cream.corner_radius_bottom_left = 14;  cream.corner_radius_bottom_right = 14
	for panel in [dialogue, complete_pan]:
		if panel: panel.add_theme_stylebox_override("panel", cream)
	var instr_panel := instr_lbl.get_parent() as Panel
	if instr_panel:
		var dark := StyleBoxFlat.new()
		dark.bg_color = Color(0.10, 0.14, 0.10, 0.82)
		dark.border_color = Color(1.0, 0.85, 0.35, 0.9)
		dark.set_border_width_all(2)
		dark.corner_radius_top_left = 10;    dark.corner_radius_top_right = 10
		dark.corner_radius_bottom_left = 10; dark.corner_radius_bottom_right = 10
		instr_panel.add_theme_stylebox_override("panel", dark)
		instr_lbl.add_theme_color_override("font_color", Color(1, 0.98, 0.9))

# ─── Grid ─────────────────────────────────────────────────────────────────────
func _init_grid() -> void:
	grid_state=[]; tile_owner={}; paths={}; connected=[]; tile_rects={}; animal_nodes={}
	for r in range(ROWS):
		var row:=[]; for c in range(COLS): row.append(Cell.EMPTY)
		grid_state.append(row)
	for pos in OBSTACLES: grid_state[pos.y][pos.x] = Cell.OBSTACLE
	for a in ANIMALS:
		grid_state[a.grid_pos.y][a.grid_pos.x] = Cell.ANIMAL
		grid_state[a.house_pos.y][a.house_pos.x] = Cell.HOUSE
		tile_owner[a.grid_pos] = a.id;  tile_owner[a.house_pos] = a.id
		paths[a.id] = []

func _build_tiles() -> void:
	var tex_e := load(RES_TILE_E) as Texture2D
	var tex_o := load(RES_TILE_O) as Texture2D
	for r in range(ROWS):
		for c in range(COLS):
			var gp := Vector2i(c,r);  var pos := _screen_pos(gp)
			var cell: int = grid_state[r][c]
			var node := TextureRect.new()
			node.size = Vector2(TILE_PX-2,TILE_PX-2);  node.position = pos+Vector2(1,1)
			node.stretch_mode = TextureRect.STRETCH_SCALE
			match cell:
				Cell.OBSTACLE: node.texture = tex_o
				Cell.HOUSE:    node.texture = tex_e; node.modulate = Color(0.82,0.74,0.54)
				_:             node.texture = tex_e
			grid_root.add_child(node);  tile_rects[gp] = node
			if cell == Cell.HOUSE:
				var aid: int = tile_owner[gp]
				var lbl := Label.new()
				lbl.text = ANIMALS[aid].maya
				lbl.position = pos+Vector2(2,TILE_PX-22);  lbl.size.x = TILE_PX-4
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", 12)
				lbl.add_theme_color_override("font_color", Color(0.12,0.06,0.0))
				grid_root.add_child(lbl)

func _build_animal_sprites() -> void:
	for a in ANIMALS:
		var pos := _screen_pos(a.grid_pos)
		var spr := TextureRect.new()
		spr.texture = load(a.sprite) as Texture2D
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spr.size = Vector2(TILE_PX-4,TILE_PX-4);  spr.position = pos+Vector2(2,2)
		grid_root.add_child(spr);  animal_nodes[a.id] = spr

# ─── Input ────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	# Clic en el diálogo → ciérralo inmediatamente (skip)
	if _dialogue_open and event is InputEventMouseButton and event.pressed:
		_close_dialogue()
		return
	if complete_pan.visible: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			last_gp = Vector2i(-1,-1);  _handle_press(_grid_pos(event.position))
		else: _stop_drawing()
	elif event is InputEventMouseMotion and drawing:
		var gp := _grid_pos(event.position)
		if gp != last_gp: _fill_gap(last_gp, gp); last_gp = gp

func _handle_press(gp: Vector2i) -> void:
	if not _valid(gp): return
	match grid_state[gp.y][gp.x]:
		Cell.ANIMAL:
			var aid: int = tile_owner[gp]
			if aid in connected: return
			_clear_path(aid); active_id = aid; drawing = true; last_gp = gp
			_show_ring(aid)
			_set_instr("Arrastra desde  \"%s\"  (%s)  hasta su casa en maya" % [ANIMALS[aid].maya, ANIMALS[aid].spanish])
		Cell.EMPTY, Cell.PATH:
			if drawing: _extend_path(gp)
		Cell.HOUSE:
			if drawing and tile_owner.get(gp,-1) == active_id:
				_finalize_connection(active_id); _stop_drawing()

func _stop_drawing() -> void:
	drawing = false;  active_id = -1;  sel_ring.visible = false
	if ring_tween and ring_tween.is_valid(): ring_tween.kill()
	_set_instr("Haz clic en un animal y arrastra hasta su casa.\nConecta los tres para completar el nivel.")

func _fill_gap(from_gp: Vector2i, to_gp: Vector2i) -> void:
	if not _valid(to_gp): return
	if from_gp == Vector2i(-1,-1): _try_cell(to_gp); return
	var dx := to_gp.x-from_gp.x;  var dy := to_gp.y-from_gp.y
	var steps := maxi(absi(dx), absi(dy))
	for i in range(1, steps+1):
		var mid := Vector2i(from_gp.x+roundi(float(dx)*i/steps), from_gp.y+roundi(float(dy)*i/steps))
		if _valid(mid): _try_cell(mid)

func _try_cell(gp: Vector2i) -> void:
	match grid_state[gp.y][gp.x]:
		Cell.EMPTY, Cell.PATH: _extend_path(gp)
		Cell.HOUSE:
			if tile_owner.get(gp,-1) == active_id:
				_finalize_connection(active_id); _stop_drawing()

# ─── Caminos ──────────────────────────────────────────────────────────────────
func _extend_path(gp: Vector2i) -> void:
	if active_id < 0: return
	if gp in paths[active_id]: return
	if gp in tile_owner and tile_owner[gp] != active_id: return
	var ok := false
	if paths[active_id].is_empty(): ok = _adjacent(gp, ANIMALS[active_id].grid_pos)
	else: ok = _adjacent(gp, paths[active_id].back())
	if not ok: return
	paths[active_id].append(gp)
	grid_state[gp.y][gp.x] = Cell.PATH;  tile_owner[gp] = active_id
	_set_tile_color(gp, ANIMALS[active_id].color.lightened(0.40))

func _clear_path(aid: int) -> void:
	for gp: Vector2i in paths[aid]:
		grid_state[gp.y][gp.x] = Cell.EMPTY;  tile_owner.erase(gp);  _reset_tile(gp)
	paths[aid] = []

func _finalize_connection(aid: int) -> void:
	connected.append(aid)
	for gp: Vector2i in paths[aid]: _set_tile_color(gp, ANIMALS[aid].color)
	_set_tile_color(ANIMALS[aid].house_pos, ANIMALS[aid].color.lightened(0.25))
	GameManager.learn_word(ANIMALS[aid].maya)
	_show_dialogue(aid)

# ─── Anillo de selección ──────────────────────────────────────────────────────
func _show_ring(aid: int) -> void:
	var pos := _screen_pos(ANIMALS[aid].grid_pos)
	sel_ring.position = pos - Vector2(5,5)
	sel_ring.size     = Vector2(TILE_PX+10, TILE_PX+10)
	sel_ring.color    = ANIMALS[aid].color
	sel_ring.visible  = true;  sel_ring.modulate = Color.WHITE
	if ring_tween and ring_tween.is_valid(): ring_tween.kill()
	ring_tween = create_tween().set_loops()
	ring_tween.tween_property(sel_ring, "modulate:a", 0.20, 0.40)
	ring_tween.tween_property(sel_ring, "modulate:a", 1.00, 0.40)

# ─── Diálogo ──────────────────────────────────────────────────────────────────
func _show_dialogue(aid: int) -> void:
	# FIX: No iniciar un nuevo diálogo si ya hay uno abierto o si estamos completando
	if _dialogue_open: return
	var a: Dictionary = ANIMALS[aid]
	dlg_phrase.text = "In k'aaba'e'  %s" % a.maya
	dlg_hint.text   = "(Me llamo %s — en maya: %s)" % [a.spanish, a.maya]
	var tex := load(a.sprite) as Texture2D
	if tex: dlg_animal.texture = tex
	_dialogue_open = true
	dialogue.visible = true
	# Saltito del sprite
	var anode = animal_nodes.get(aid)
	if anode:
		var tw := create_tween()
		tw.tween_property(anode, "position:y", anode.position.y - 14, 0.15)
		tw.tween_property(anode, "position:y", anode.position.y,       0.20)
	# Esperar — con guarda de validez
	await get_tree().create_timer(3.2).timeout
	if not is_inside_tree(): return        # FIX: no continuar si la escena cambió
	_close_dialogue()

func _close_dialogue() -> void:
	if not _dialogue_open: return
	_dialogue_open = false
	dialogue.visible = false
	# FIX: solo completar UNA vez
	if not _completing and connected.size() == ANIMALS.size():
		_completing = true
		await get_tree().create_timer(0.4).timeout
		if not is_inside_tree(): return    # FIX: guarda tras segundo await
		_on_level_complete()

# ─── Completar nivel ──────────────────────────────────────────────────────────
func _on_level_complete() -> void:
	GameManager.complete_level(1, 1)
	complete_pan.visible = true
	_set_instr("Nivel completado. Pulsa el boton para continuar.")

# ─── Navegación SEGURA ────────────────────────────────────────────────────────
func _safe_navigate(key: String) -> void:
	# Matar tweens pendientes antes de navegar
	if ring_tween and ring_tween.is_valid(): ring_tween.kill()
	_dialogue_open = false
	dialogue.visible = false
	GameManager.go_to_scene(key)

func _on_next_level_pressed() -> void: _safe_navigate("world1_level2")
func _on_menu_pressed()       -> void: _safe_navigate("main_menu")
func _on_book_pressed()       -> void: libro.show_book()

# ─── Instrucciones ────────────────────────────────────────────────────────────
func _set_instr(text: String) -> void:
	if instr_lbl: instr_lbl.text = text

# ─── Utilidades ──────────────────────────────────────────────────────────────
func _screen_pos(gp: Vector2i) -> Vector2:
	return Vector2(GRID_X + gp.x * TILE_PX, GRID_Y + gp.y * TILE_PX)
func _grid_pos(screen: Vector2) -> Vector2i:
	return Vector2i(int((screen.x-GRID_X)/TILE_PX), int((screen.y-GRID_Y)/TILE_PX))
func _valid(gp: Vector2i) -> bool:
	return gp.x>=0 and gp.x<COLS and gp.y>=0 and gp.y<ROWS
func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	var d := a-b; return (abs(d.x)==1 and d.y==0) or (d.x==0 and abs(d.y)==1)
func _set_tile_color(gp: Vector2i, col: Color) -> void:
	var node: TextureRect = tile_rects.get(gp); if node: node.modulate = col
func _reset_tile(gp: Vector2i) -> void:
	var node: TextureRect = tile_rects.get(gp); if node: node.modulate = Color.WHITE
func _refresh_hud() -> void:
	if magic_lbl: magic_lbl.text = "%d pts magicos" % GameManager.magic_points
