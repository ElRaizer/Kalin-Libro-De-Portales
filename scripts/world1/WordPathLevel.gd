## WordPathLevel.gd v2 — Base para niveles 2 y 3
## FIXES: await guardado, _completing flag, _safe_navigate, instrucciones visibles
extends Node2D

const COLS := 9;  const ROWS := 7
const TILE_PX := 80;  const GRID_X := 80;  const GRID_Y := 95
enum Cell { EMPTY, OBSTACLE, WORD, HOUSE, PATH }
const RES_TILE_E := "res://Arte/tiles/tile_empty.svg"
const RES_TILE_O := "res://Arte/tiles/tile_obstacle.svg"

var WORDS: Array = []
var OBSTACLES: Array = []
var LEVEL_TITLE: String = ""              # FIX: declarada en la base (Level2/3 la asignan)
var LEVEL_WORLD: int = 1;  var LEVEL_NUM: int = 2
# Fondo del nivel: cada nivel puede asignar el suyo en _setup_data()
# para que el tablero no se pierda con los colores del escenario.
var BG_PATH: String = "res://Arte/backgrounds/bg_level1.svg"

var grid_state: Array;  var tile_owner: Dictionary
var paths: Dictionary;  var connected: Array[int]
var drawing: bool = false;   var active_id: int = -1
var last_gp: Vector2i = Vector2i(-1,-1)
var ring_tween: Tween
var _completing: bool = false
var _dialogue_open: bool = false
var tile_rects: Dictionary;  var word_panels: Dictionary

@onready var bg_texture:   TextureRect = $Background
@onready var grid_root:    Node2D      = $GridRoot
@onready var sel_ring:     ColorRect   = $GridRoot/SelectionRing
@onready var dialogue:     Panel       = $UI/DialoguePanel
@onready var dlg_maya:     Label       = $UI/DialoguePanel/VBox/Phrase
@onready var dlg_hint:     Label       = $UI/DialoguePanel/VBox/Hint
@onready var dlg_struct:   Label       = $UI/DialoguePanel/VBox/Struct
@onready var magic_lbl:    Label       = $UI/TopBar/MagicLabel
@onready var instr_lbl:    Label       = $UI/InstrPanel/InstrLbl
@onready var complete_pan: Panel       = $UI/CompletePanel
@onready var libro:        CanvasLayer = $LibroHechizos

func _ready() -> void:
	_setup_data()
	bg_texture.texture = load(BG_PATH)
	_apply_friendly_theme()
	_init_grid(); _build_tiles(); _build_word_tiles(); _refresh_hud()
	dialogue.visible = false;  complete_pan.visible = false;  sel_ring.visible = false
	_set_instr("Conecta cada palabra maya con su traduccion en espanol.\nArrastra de izquierda a derecha.")
	GameManager.magic_points_changed.connect(func(_v): _refresh_hud())

## Estilo consistente y de alto contraste para todos los niveles de caminos:
## paneles crema con borde cafe (texto oscuro legible) y barra superior
## semitransparente oscura (texto claro legible sobre cualquier fondo).
func _apply_friendly_theme() -> void:
	var cream: StyleBoxFlat = StyleBoxFlat.new()
	cream.bg_color = Color(0.98, 0.94, 0.84, 0.97)
	cream.border_color = Color(0.45, 0.30, 0.15)
	cream.set_border_width_all(4)
	cream.corner_radius_top_left = 14;  cream.corner_radius_top_right = 14
	cream.corner_radius_bottom_left = 14;  cream.corner_radius_bottom_right = 14
	for panel in [dialogue, complete_pan]:
		if panel: panel.add_theme_stylebox_override("panel", cream)
	var instr_panel: Panel = instr_lbl.get_parent() as Panel
	if instr_panel:
		var dark: StyleBoxFlat = StyleBoxFlat.new()
		dark.bg_color = Color(0.10, 0.14, 0.10, 0.82)
		dark.border_color = Color(1.0, 0.85, 0.35, 0.9)
		dark.set_border_width_all(2)
		dark.corner_radius_top_left = 10;  dark.corner_radius_top_right = 10
		dark.corner_radius_bottom_left = 10;  dark.corner_radius_bottom_right = 10
		instr_panel.add_theme_stylebox_override("panel", dark)
		instr_lbl.add_theme_color_override("font_color", Color(1, 0.98, 0.9))

func _setup_data() -> void: pass

func _init_grid() -> void:
	grid_state=[]; tile_owner={}; paths={}; connected=[]; tile_rects={}; word_panels={}
	for r in range(ROWS):
		var row: Array[int] = []; for _column in range(COLS): row.append(Cell.EMPTY)
		grid_state.append(row)
	for pos in OBSTACLES: grid_state[pos.y][pos.x] = Cell.OBSTACLE
	for w in WORDS:
		grid_state[w.grid_pos.y][w.grid_pos.x] = Cell.WORD
		grid_state[w.house_pos.y][w.house_pos.x] = Cell.HOUSE
		tile_owner[w.grid_pos] = w.id;  tile_owner[w.house_pos] = w.id
		paths[w.id] = []

func _build_tiles() -> void:
	var tex_e: Texture2D = load(RES_TILE_E) as Texture2D
	var tex_o: Texture2D = load(RES_TILE_O) as Texture2D
	for r in range(ROWS):
		for c in range(COLS):
			var gp: Vector2i = Vector2i(c,r);  var pos: Vector2 = _screen_pos(gp)
			var cell: int = grid_state[r][c]
			var node: TextureRect = TextureRect.new()
			node.size = Vector2(TILE_PX-2,TILE_PX-2);  node.position = pos+Vector2(1,1)
			node.stretch_mode = TextureRect.STRETCH_SCALE
			match cell:
				Cell.OBSTACLE: node.texture = tex_o
				Cell.HOUSE:    node.texture = tex_e; node.modulate = Color(0.82,0.74,0.54)
				_:             node.texture = tex_e
			grid_root.add_child(node);  tile_rects[gp] = node
			if cell == Cell.HOUSE:
				var wid: int = tile_owner[gp]
				var w: Dictionary = WORDS[wid]
				var p: Panel = Panel.new()
				p.size = Vector2(TILE_PX-4,TILE_PX-4);  p.position = pos+Vector2(2,2)
				var st: StyleBoxFlat = StyleBoxFlat.new()
				st.bg_color = w.color.lightened(0.55)
				st.set_border_width_all(2);  st.border_color = w.color
				st.corner_radius_top_left=6; st.corner_radius_top_right=6
				st.corner_radius_bottom_left=6; st.corner_radius_bottom_right=6
				p.add_theme_stylebox_override("panel", st)
				var lbl: Label = Label.new()
				lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				lbl.text = w.emoji+"\n"+w.spanish
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
				lbl.add_theme_font_size_override("font_size", 11)
				lbl.add_theme_color_override("font_color", Color(0.1,0.05,0.0))
				lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p.add_child(lbl);  grid_root.add_child(p)

func _build_word_tiles() -> void:
	for w in WORDS:
		var pos: Vector2 = _screen_pos(w.grid_pos)
		var p: Panel = Panel.new()
		p.size = Vector2(TILE_PX-4,TILE_PX-4);  p.position = pos+Vector2(2,2)
		var st: StyleBoxFlat = StyleBoxFlat.new()
		st.bg_color = w.color;  st.set_border_width_all(3);  st.border_color = w.color.darkened(0.3)
		st.corner_radius_top_left=6; st.corner_radius_top_right=6
		st.corner_radius_bottom_left=6; st.corner_radius_bottom_right=6
		p.add_theme_stylebox_override("panel", st)
		# Si la palabra trae un sprite (niveles de animales), lo mostramos
		# con el nombre maya en una franja inferior; si no, solo el texto.
		if w.has("sprite") and String(w.sprite) != "":
			var tex: Texture2D = load(w.sprite) as Texture2D
			if tex:
				var texr: TextureRect = TextureRect.new()
				texr.texture = tex
				texr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				texr.position = Vector2(2, 0)
				texr.size = Vector2(TILE_PX-8, TILE_PX-22)
				texr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				p.add_child(texr)
			var name_lbl: Label = Label.new()
			name_lbl.text = w.maya
			name_lbl.position = Vector2(0, TILE_PX-22)
			name_lbl.size = Vector2(TILE_PX-4, 18)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			name_lbl.add_theme_font_size_override("font_size", 12)
			name_lbl.add_theme_color_override("font_color", Color.WHITE)
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.add_child(name_lbl)
		else:
			var lbl: Label = Label.new()
			lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lbl.text = w.maya;  lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p.add_child(lbl)
		grid_root.add_child(p);  word_panels[w.id] = p

# ─── Input ────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _dialogue_open and event is InputEventMouseButton and event.pressed:
		_close_dialogue(); return
	if complete_pan.visible: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			last_gp = Vector2i(-1,-1);  _handle_press(_grid_pos(event.position))
		else: _stop_drawing()
	elif event is InputEventMouseMotion and drawing:
		var gp: Vector2i = _grid_pos(event.position)
		if gp != last_gp: _fill_gap(last_gp, gp); last_gp = gp

func _handle_press(gp: Vector2i) -> void:
	if not _valid(gp): return
	match grid_state[gp.y][gp.x]:
		Cell.WORD:
			var wid: int = tile_owner[gp]
			if wid in connected: return
			_clear_path(wid); active_id = wid; drawing = true; last_gp = gp
			_show_ring(wid)
			_set_instr("Arrastra  \"%s\"  hasta  \"%s\"  (su casa en espanol)" % [WORDS[wid].maya, WORDS[wid].spanish])
		Cell.EMPTY, Cell.PATH:
			if drawing: _extend_path(gp)
		Cell.HOUSE:
			if drawing and tile_owner.get(gp,-1) == active_id:
				_finalize_connection(active_id); _stop_drawing()

func _stop_drawing() -> void:
	drawing = false;  active_id = -1;  sel_ring.visible = false
	if ring_tween and ring_tween.is_valid(): ring_tween.kill()
	_set_instr("Conecta cada palabra maya con su traduccion en espanol.\nArrastra de izquierda a derecha.")

func _fill_gap(from_gp: Vector2i, to_gp: Vector2i) -> void:
	if not _valid(to_gp): return
	if from_gp == Vector2i(-1,-1): _try_cell(to_gp); return
	var dx: int = to_gp.x-from_gp.x;  var dy: int = to_gp.y-from_gp.y
	var steps: int = maxi(absi(dx), absi(dy))
	for i in range(1, steps+1):
		var mid: Vector2i = Vector2i(from_gp.x+roundi(float(dx)*i/steps), from_gp.y+roundi(float(dy)*i/steps))
		if _valid(mid): _try_cell(mid)

func _try_cell(gp: Vector2i) -> void:
	match grid_state[gp.y][gp.x]:
		Cell.EMPTY, Cell.PATH: _extend_path(gp)
		Cell.HOUSE:
			if tile_owner.get(gp,-1) == active_id:
				_finalize_connection(active_id); _stop_drawing()

func _extend_path(gp: Vector2i) -> void:
	if active_id < 0: return
	if gp in paths[active_id]: return
	if gp in tile_owner and tile_owner[gp] != active_id: return
	var ok: bool = false
	if paths[active_id].is_empty(): ok = _adjacent(gp, WORDS[active_id].grid_pos)
	else: ok = _adjacent(gp, paths[active_id].back())
	if not ok: return
	paths[active_id].append(gp)
	grid_state[gp.y][gp.x] = Cell.PATH;  tile_owner[gp] = active_id
	_set_tile_color(gp, WORDS[active_id].color.lightened(0.40))

func _clear_path(wid: int) -> void:
	for gp: Vector2i in paths[wid]:
		grid_state[gp.y][gp.x] = Cell.EMPTY;  tile_owner.erase(gp);  _reset_tile(gp)
	paths[wid] = []

func _finalize_connection(wid: int) -> void:
	connected.append(wid)
	for gp: Vector2i in paths[wid]: _set_tile_color(gp, WORDS[wid].color)
	_set_tile_color(WORDS[wid].house_pos, WORDS[wid].color.lightened(0.25))
	GameManager.learn_word(WORDS[wid].maya)
	_show_dialogue(wid)

func _show_ring(wid: int) -> void:
	var pos: Vector2 = _screen_pos(WORDS[wid].grid_pos)
	sel_ring.position = pos-Vector2(5,5);  sel_ring.size = Vector2(TILE_PX+10,TILE_PX+10)
	sel_ring.color = WORDS[wid].color;  sel_ring.visible = true;  sel_ring.modulate = Color.WHITE
	if ring_tween and ring_tween.is_valid(): ring_tween.kill()
	ring_tween = create_tween().set_loops()
	ring_tween.tween_property(sel_ring, "modulate:a", 0.20, 0.40)
	ring_tween.tween_property(sel_ring, "modulate:a", 1.00, 0.40)

func _show_dialogue(wid: int) -> void:
	if _dialogue_open: return
	var w: Dictionary = WORDS[wid]
	dlg_maya.text   = "%s  =  %s  %s" % [w.maya, w.emoji, w.spanish]
	dlg_hint.text   = w.get("traduccion", "")
	dlg_struct.text = w.get("estructura", "")
	_dialogue_open = true;  dialogue.visible = true
	var p = word_panels.get(wid)
	if p:
		var tw: Tween = create_tween()
		tw.tween_property(p, "position:y", p.position.y-14, 0.15)
		tw.tween_property(p, "position:y", p.position.y,    0.20)
	await get_tree().create_timer(3.2).timeout
	if not is_inside_tree(): return       # FIX
	_close_dialogue()

func _close_dialogue() -> void:
	if not _dialogue_open: return
	_dialogue_open = false;  dialogue.visible = false
	if not _completing and connected.size() == WORDS.size():
		_completing = true
		await get_tree().create_timer(0.4).timeout
		if not is_inside_tree(): return   # FIX
		_on_level_complete()

func _on_level_complete() -> void:
	GameManager.complete_level(LEVEL_WORLD, LEVEL_NUM)
	complete_pan.visible = true
	_set_instr("Nivel completado. Pulsa el boton para continuar.")

func _safe_navigate(key: String) -> void:
	if ring_tween and ring_tween.is_valid(): ring_tween.kill()
	_dialogue_open = false;  dialogue.visible = false
	GameManager.go_to_scene(key)

func _on_next_level_pressed() -> void: _safe_navigate("world1_level%d" % (LEVEL_NUM + 1))
func _on_menu_pressed()       -> void: _safe_navigate("main_menu")
func _on_book_pressed()       -> void: libro.show_book()

func _set_instr(text: String) -> void:
	if instr_lbl: instr_lbl.text = text

func _screen_pos(gp: Vector2i) -> Vector2:
	return Vector2(GRID_X+gp.x*TILE_PX, GRID_Y+gp.y*TILE_PX)
func _grid_pos(screen: Vector2) -> Vector2i:
	return Vector2i(int((screen.x-GRID_X)/TILE_PX), int((screen.y-GRID_Y)/TILE_PX))
func _valid(gp: Vector2i) -> bool:
	return gp.x>=0 and gp.x<COLS and gp.y>=0 and gp.y<ROWS
func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	var d: Vector2i = a-b; return (abs(d.x)==1 and d.y==0) or (d.x==0 and abs(d.y)==1)
func _set_tile_color(gp: Vector2i, col: Color) -> void:
	var node: TextureRect = tile_rects.get(gp); if node: node.modulate = col
func _reset_tile(gp: Vector2i) -> void:
	var node: TextureRect = tile_rects.get(gp); if node: node.modulate = Color.WHITE
func _refresh_hud() -> void:
	if magic_lbl: magic_lbl.text = "%d pts magicos" % GameManager.magic_points
