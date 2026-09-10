## Level4.gd v2 — In k'a'at (Yo Quiero)
## FIXES: await guardado, navegación segura, instrucciones visibles
extends Node2D

const FOODS := [
	{ "maya":"ja'",    "spanish":"Agua",    "emoji":"💧", "color":Color(0.25,0.60,0.90) },
	{ "maya":"Ja'as",  "spanish":"Platano", "emoji":"🍌", "color":Color(0.92,0.78,0.15) },
	{ "maya":"pak'al", "spanish":"Fruta",   "emoji":"🍎", "color":Color(0.85,0.25,0.25) },
	{ "maya":"K'uum",  "spanish":"Calabaza","emoji":"🎃", "color":Color(0.88,0.50,0.10) },
]
const RES_BG    := "res://Arte/backgrounds/bg_level1.svg"
const RES_KALIN := "res://Arte/sprites/kalin_normal.svg"

var learned_count := 0
var food_buttons: Array = []
var _completing := false

@onready var bg:          TextureRect    = $Background
@onready var kalin_img:   TextureRect    = $UI/KalinSprite
@onready var phrase_box:  Panel          = $UI/PhraseBox
@onready var phrase_lbl:  Label          = $UI/PhraseBox/VBox/PhraseLbl
@onready var hint_lbl:    Label          = $UI/PhraseBox/VBox/HintLbl
@onready var progress:    Label          = $UI/ProgressLbl
@onready var food_grid:   GridContainer  = $UI/FoodGrid
@onready var complete_pan:Panel          = $UI/CompletePanel
@onready var magic_lbl:   Label          = $UI/TopBar/MagicLabel
@onready var libro:       CanvasLayer    = $LibroHechizos

func _ready() -> void:
	bg.texture = load(RES_BG)
	kalin_img.texture = load(RES_KALIN)
	_apply_friendly_theme()
	_build_food_buttons()
	phrase_lbl.text = "In k'a'at ..."
	phrase_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	hint_lbl.text   = "Haz clic en un alimento para aprender a pedirlo en maya."
	progress.text   = "Aprendidos: 0 / 4"
	complete_pan.visible = false
	GameManager.magic_points_changed.connect(func(_v): magic_lbl.text = "%d pts" % GameManager.magic_points)
	magic_lbl.text = "%d pts" % GameManager.magic_points

## Mismo estilo de alto contraste que el resto de niveles: panel crema con
## borde cafe para que el texto oscuro (frase/pista) nunca se pierda.
func _apply_friendly_theme() -> void:
	var cream := StyleBoxFlat.new()
	cream.bg_color = Color(0.98, 0.94, 0.84, 0.97)
	cream.border_color = Color(0.45, 0.30, 0.15)
	cream.set_border_width_all(4)
	cream.corner_radius_top_left = 14;     cream.corner_radius_top_right = 14
	cream.corner_radius_bottom_left = 14;  cream.corner_radius_bottom_right = 14
	for panel in [phrase_box, complete_pan]:
		if panel: panel.add_theme_stylebox_override("panel", cream)

func _build_food_buttons() -> void:
	for i in range(FOODS.size()):
		var f: Dictionary = FOODS[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240, 130)
		btn.text = "%s\n%s\n(%s)" % [f.emoji, f.spanish, f.maya]
		btn.add_theme_font_size_override("font_size", 22)
		var st := StyleBoxFlat.new()
		st.bg_color = f.color;  st.set_border_width_all(3)
		st.border_color = f.color.darkened(0.3)
		st.corner_radius_top_left=12; st.corner_radius_top_right=12
		st.corner_radius_bottom_left=12; st.corner_radius_bottom_right=12
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_color_override("font_color", Color.WHITE)
		food_grid.add_child(btn);  food_buttons.append(btn)
		var ci := i
		btn.pressed.connect(func(): _on_food_pressed(ci))

func _on_food_pressed(idx: int) -> void:
	if _completing: return
	var f: Dictionary = FOODS[idx]
	phrase_lbl.text = "In k'a'at %s" % f.maya
	phrase_lbl.add_theme_color_override("font_color", Color(0.10, 0.08, 0.45))
	hint_lbl.text = "Yo quiero %s  (%s en maya)" % [f.spanish, f.maya]
	if not GameManager.words_learned.has(f.maya):
		GameManager.learn_word(f.maya)
		learned_count += 1
		# Marcar botón aprendido
		var st := StyleBoxFlat.new()
		st.bg_color = FOODS[idx].color.darkened(0.25)
		st.set_border_width_all(4);  st.border_color = Color.WHITE
		st.corner_radius_top_left=12; st.corner_radius_top_right=12
		st.corner_radius_bottom_left=12; st.corner_radius_bottom_right=12
		food_buttons[idx].add_theme_stylebox_override("normal", st)
		progress.text = "Aprendidos: %d / %d" % [learned_count, FOODS.size()]
	# Animar Kalin
	var tw := create_tween()
	tw.tween_property(kalin_img, "scale", Vector2(1.15,1.15), 0.12)
	tw.tween_property(kalin_img, "scale", Vector2(1.0,1.0),   0.18)
	if learned_count >= FOODS.size() and not _completing:
		_completing = true
		await get_tree().create_timer(1.5).timeout
		if not is_inside_tree(): return    # FIX: guarda await
		_on_level_complete()

func _on_level_complete() -> void:
	GameManager.complete_level(1, 4);  complete_pan.visible = true

func _safe_navigate(key: String) -> void:
	_completing = true;  GameManager.go_to_scene(key)
func _on_menu_pressed()   -> void: _safe_navigate("main_menu")
func _on_next_level_pressed() -> void: _safe_navigate("world1_level5")
func _on_book_pressed()   -> void: libro.show_book()
func _on_replay_pressed() -> void: get_tree().reload_current_scene()
