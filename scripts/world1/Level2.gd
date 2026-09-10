## Level2.gd v3 — La Casa Maya (Objetos del hogar)
## Mecánica nueva (reemplaza el antiguo puzzle de caminos, que era idéntico
## al del Nivel 1): "Lanzar el hechizo correcto".
##
## Cada animal necesita un objeto para su casa. El jugador debe elegir el
## sustantivo maya correcto entre varias opciones para conjurarlo:
##   Fase 1 (Aprende):   se muestra la imagen Y la palabra en maya.
##   Fase 2 (Recuerda):  solo se muestra la imagen — sin apoyo escrito,
##                       tal como pide el GDD para el nivel avanzado.
## Vocabulario (ya validado en GameManager.VOCABULARY, nivel 2):
##   mayak (mesa), lak (plato), ch'áak (cama), chan (silla), janal (comida)
extends Node2D

const RES_BG := "res://Arte/backgrounds/bg_level1.svg"

# Objeto solicitado, animal que lo pide, y refuerzo gramatical.
const OBJECTS := [
	{ "maya": "mayak",  "spanish": "Mesa",   "emoji": "🪑",
	  "animal_spr": "res://Arte/sprites/animal_miis.svg",  "animal": "Míis",
	  "peticion": "Necesito un lugar para comer.",
	  "estructura": "Ti' yaan jun mayak", "traduccion": "Hay una mesa",
	  "color": Color(0.85, 0.42, 0.18) },
	{ "maya": "lak",    "spanish": "Plato",  "emoji": "🍽️",
	  "animal_spr": "res://Arte/sprites/animal_kaax.svg",  "animal": "Káax",
	  "peticion": "Necesito algo para servir mi comida.",
	  "estructura": "Ti' yaan jun lak", "traduccion": "Hay un plato",
	  "color": Color(0.30, 0.55, 0.82) },
	{ "maya": "ch'áak", "spanish": "Cama",   "emoji": "🛏️",
	  "animal_spr": "res://Arte/sprites/animal_peek.svg",  "animal": "Peek'",
	  "peticion": "Necesito un lugar para dormir.",
	  "estructura": "Ti' yaan jun ch'áak", "traduccion": "Hay una cama",
	  "color": Color(0.55, 0.35, 0.75) },
	{ "maya": "chan",   "spanish": "Silla",  "emoji": "💺",
	  "animal_spr": "res://Arte/sprites/animal_aak.svg",   "animal": "Aak'",
	  "peticion": "Necesito algo para sentarme.",
	  "estructura": "Ti' yaan jun chan", "traduccion": "Hay una silla",
	  "color": Color(0.22, 0.62, 0.28) },
	{ "maya": "janal",  "spanish": "Comida", "emoji": "🍲",
	  "animal_spr": "res://Arte/sprites/animal_keej.svg",  "animal": "Kéej",
	  "peticion": "Necesito algo para comer.",
	  "estructura": "Ti' yaan jun janal", "traduccion": "Hay comida",
	  "color": Color(0.80, 0.25, 0.20) },
]

const TOTAL_ROUNDS := 10   # 5 objetos x 2 fases

# ─── Estado ──────────────────────────────────────────────────────────────────
var round_order: Array[int] = []
var round_index := 0
var current_phase := 0            # 0 = imagen+palabra, 1 = solo imagen
var _completing := false
var _choice_buttons: Array[Button] = []

# ─── Nodos ───────────────────────────────────────────────────────────────────
@onready var bg:           TextureRect   = $Background
@onready var animal_spr:   TextureRect   = $UI/RequestPanel/AnimalSprite
@onready var need_lbl:     Label         = $UI/RequestPanel/VBox/NeedLbl
@onready var word_lbl:     Label         = $UI/RequestPanel/VBox/WordLbl
@onready var choices_grid: GridContainer = $UI/ChoicesGrid
@onready var feedback_pan: Panel         = $UI/FeedbackPanel
@onready var feedback_lbl: Label         = $UI/FeedbackPanel/FeedbackLbl
@onready var phase_lbl:    Label         = $UI/StatusPanel/StatusVBox/PhaseLbl
@onready var progress_lbl: Label         = $UI/StatusPanel/StatusVBox/ProgressLbl
@onready var complete_pan: Panel         = $UI/CompletePanel
@onready var magic_lbl:    Label         = $UI/TopBar/MagicLabel
@onready var libro:        CanvasLayer   = $LibroHechizos
@onready var request_pan:  Panel         = $UI/RequestPanel
@onready var status_pan:   Panel         = $UI/StatusPanel

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	bg.texture = load(RES_BG)
	_apply_theme()
	for i in range(OBJECTS.size()):
		round_order.append(i)
	round_order.shuffle()
	complete_pan.visible = false
	feedback_lbl.text = ""
	magic_lbl.text = "%d pts magicos" % GameManager.magic_points
	GameManager.magic_points_changed.connect(func(_v): magic_lbl.text = "%d pts magicos" % GameManager.magic_points)
	_show_round()

## Mismo estilo visual (crema/café + barra oscura) que el resto de niveles,
## para que la escena se vea consistente aunque la mecánica sea distinta.
func _apply_theme() -> void:
	var cream := StyleBoxFlat.new()
	cream.bg_color = Color(0.98, 0.94, 0.84, 0.97)
	cream.border_color = Color(0.45, 0.30, 0.15)
	cream.set_border_width_all(4)
	cream.corner_radius_top_left = 14;     cream.corner_radius_top_right = 14
	cream.corner_radius_bottom_left = 14;  cream.corner_radius_bottom_right = 14
	for panel in [request_pan, complete_pan, feedback_pan]:
		panel.add_theme_stylebox_override("panel", cream)

	var dark := StyleBoxFlat.new()
	dark.bg_color = Color(0.10, 0.14, 0.10, 0.82)
	dark.border_color = Color(1.0, 0.85, 0.35, 0.9)
	dark.set_border_width_all(2)
	dark.corner_radius_top_left = 10;    dark.corner_radius_top_right = 10
	dark.corner_radius_bottom_left = 10; dark.corner_radius_bottom_right = 10
	status_pan.add_theme_stylebox_override("panel", dark)
	phase_lbl.add_theme_color_override("font_color", Color(1, 0.98, 0.9))
	progress_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.8))

# ─── Rondas ───────────────────────────────────────────────────────────────────
func _current_object() -> Dictionary:
	var obj_idx: int = round_order[round_index % round_order.size()]
	return OBJECTS[obj_idx]

func _show_round() -> void:
	if round_index >= TOTAL_ROUNDS:
		return
	feedback_lbl.text = ""
	var obj := _current_object()
	current_phase = 0 if round_index < round_order.size() else 1
	animal_spr.texture = load(obj.animal_spr)
	animal_spr.modulate = Color.WHITE
	animal_spr.position.x = 20

	if current_phase == 0:
		phase_lbl.text = "Fase 1 · Aprende — Ronda %d / %d" % [round_index + 1, TOTAL_ROUNDS]
		need_lbl.text = "%s dice: \"%s\"" % [obj.animal, obj.peticion]
		word_lbl.text = "%s   %s   (%s)" % [obj.emoji, obj.spanish, obj.maya]
	else:
		phase_lbl.text = "Fase 2 · Recuerda sin ayuda — Ronda %d / %d" % [round_index + 1, TOTAL_ROUNDS]
		need_lbl.text = "%s te mira en silencio, esperando su hechizo..." % obj.animal
		word_lbl.text = obj.emoji   # solo la imagen: sin palabra escrita
	word_lbl.add_theme_color_override("font_color", obj.color.darkened(0.15))
	_build_choices()
	progress_lbl.text = "Palabras en el libro: %d / %d" % [_learned_count(), OBJECTS.size()]

func _learned_count() -> int:
	var c := 0
	for o in OBJECTS:
		if GameManager.words_learned.has(o.maya):
			c += 1
	return c

func _build_choices() -> void:
	for child in choices_grid.get_children():
		child.queue_free()
	_choice_buttons.clear()
	var pool: Array = OBJECTS.duplicate()
	pool.shuffle()
	for obj: Dictionary in pool:
		var btn := Button.new()
		btn.text = obj.maya
		btn.custom_minimum_size = Vector2(230, 90)
		btn.add_theme_font_size_override("font_size", 24)
		var st := StyleBoxFlat.new()
		st.bg_color = obj.color
		st.set_border_width_all(3)
		st.border_color = obj.color.darkened(0.3)
		st.corner_radius_top_left = 12;    st.corner_radius_top_right = 12
		st.corner_radius_bottom_left = 12; st.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_color_override("font_color", Color.WHITE)
		choices_grid.add_child(btn)
		_choice_buttons.append(btn)
		var maya_word: String = obj.maya
		btn.pressed.connect(func(): _on_choice_pressed(maya_word))

# ─── Selección ────────────────────────────────────────────────────────────────
func _on_choice_pressed(maya_word: String) -> void:
	if _completing:
		return
	var obj := _current_object()
	if maya_word == obj.maya:
		_on_correct(obj)
	else:
		_on_wrong()

func _on_correct(obj: Dictionary) -> void:
	for b in _choice_buttons:
		b.disabled = true
	GameManager.learn_word(obj.maya)
	feedback_lbl.text = "¡Hechizo lanzado!  %s  =  %s   →  \"%s\"" % [obj.maya, obj.traduccion, obj.estructura]
	feedback_lbl.add_theme_color_override("font_color", Color(0.12, 0.45, 0.15))
	var tw := create_tween()
	tw.tween_property(animal_spr, "scale", Vector2(1.18, 1.18), 0.12)
	tw.tween_property(animal_spr, "scale", Vector2(1.0, 1.0), 0.18)
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	round_index += 1
	if round_index >= TOTAL_ROUNDS:
		_completing = true
		_on_level_complete()
	else:
		_show_round()

func _on_wrong() -> void:
	feedback_lbl.text = "Ese hechizo no es el correcto... intenta de nuevo."
	feedback_lbl.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	var tw := create_tween()
	tw.tween_property(animal_spr, "position:x", animal_spr.position.x - 10, 0.05)
	tw.tween_property(animal_spr, "position:x", animal_spr.position.x + 20, 0.05)
	tw.tween_property(animal_spr, "position:x", animal_spr.position.x - 10, 0.05)
	tw.tween_property(animal_spr, "position:x", animal_spr.position.x, 0.05)

# ─── Completar nivel ────────────────────────────────────────────────────────
func _on_level_complete() -> void:
	GameManager.complete_level(1, 2)
	complete_pan.visible = true

func _safe_navigate(key: String) -> void:
	_completing = true
	GameManager.go_to_scene(key)

func _on_menu_pressed() -> void: _safe_navigate("main_menu")
func _on_next_level_pressed() -> void: _safe_navigate("world1_level3")
func _on_book_pressed() -> void: libro.show_book()
func _on_replay_pressed() -> void: get_tree().reload_current_scene()
