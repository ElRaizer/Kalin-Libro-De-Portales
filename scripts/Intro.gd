## Intro.gd
## Introducción visual novel de Kalin y el Libro de los Portales.
## Presenta al personaje, establece el contexto narrativo y lleva al Nivel 1.
## El jugador avanza con clic / espacio / Enter.

extends Node2D

# ─── Datos de los paneles narrativos ────────────────────────────────────────
const PANELS := [
	{
		"bg":       "res://Arte/backgrounds/bg_intro_room.svg",
		"kalin":    "",                     # sin sprite en este panel
		"kalin_x":  800,
		"text":     "En las tierras de la Península de Yucatán...",
		"subtext":  "",
		"auto_wait": 0.0,
	},
	{
		"bg":       "res://Arte/backgrounds/bg_intro_room.svg",
		"kalin":    "res://Arte/sprites/kalin_normal.svg",
		"kalin_x":  760,
		"text":     "Kalin era un joven aprendiz de hechicero.\nPasaba sus noches estudiando su mágico Libro de Hechizos.",
		"subtext":  "",
		"auto_wait": 0.0,
	},
	{
		"bg":       "res://Arte/backgrounds/bg_intro_room.svg",
		"kalin":    "res://Arte/sprites/kalin_normal.svg",
		"kalin_x":  760,
		"text":     "Una noche, el libro brilló con una luz extraña...\nlas páginas comenzaron a moverse solas.",
		"subtext":  "",
		"auto_wait": 0.0,
	},
	{
		"bg":       "res://Arte/backgrounds/bg_intro_portal.svg",
		"kalin":    "res://Arte/sprites/kalin_surprised.svg",
		"kalin_x":  200,
		"text":     "¡De repente, un portal mágico se abrió!\n¡Las páginas volaron por todos lados!",
		"subtext":  "",
		"auto_wait": 0.0,
	},
	{
		"bg":       "res://Arte/backgrounds/bg_intro_portal.svg",
		"kalin":    "res://Arte/sprites/kalin_surprised.svg",
		"kalin_x":  200,
		"text":     "Kalin fue absorbido por el portal.\nSus palabras mágicas se dispersaron por el mundo...",
		"subtext":  "\"¡Mis hechizos!  ¡Noooo!\"",
		"auto_wait": 0.0,
	},
	{
		"bg":       "res://Arte/backgrounds/bg_level1.svg",
		"kalin":    "res://Arte/sprites/kalin_surprised.svg",
		"kalin_x":  840,
		"text":     "Kalin despertó en una isla desconocida.\nAnimales extraños lo rodeaban...",
		"subtext":  "",
		"auto_wait": 0.0,
	},
	{
		"bg":       "res://Arte/backgrounds/bg_level1.svg",
		"kalin":    "res://Arte/sprites/kalin_normal.svg",
		"kalin_x":  840,
		"text":     "Un perro se acercó y dijo algo incomprensible:\n\"In k'aaba'e'  Peek'!\"",
		"subtext":  "Kalin no entendía nada... ¡necesitaba recuperar su libro!",
		"auto_wait": 0.0,
	},
	{
		"bg":       "res://Arte/backgrounds/bg_level1.svg",
		"kalin":    "res://Arte/sprites/kalin_normal.svg",
		"kalin_x":  840,
		"text":     "Para volver a casa, Kalin debe:\nRecolectar palabras en lengua maya y reescribir su libro.",
		"subtext":  "¡Ayúdalo a conectar los caminos y aprender maya!",
		"auto_wait": 0.0,
	},
]

# ─── Estado ──────────────────────────────────────────────────────────────────
var panel_index: int = 0
var is_animating: bool = false
var text_revealed: bool = false
var full_text: String = ""
var text_timer: float = 0.0
const CHAR_DELAY := 0.025   # segundos entre caracteres (typewriter)

# ─── Nodos ───────────────────────────────────────────────────────────────────
@onready var bg_rect:      TextureRect  = $BG
@onready var kalin_sprite: TextureRect  = $KalinSprite
@onready var dialogue_box: Panel        = $UI/DialogueBox
@onready var main_text:    RichTextLabel= $UI/DialogueBox/VBox/MainText
@onready var sub_text:     Label        = $UI/DialogueBox/VBox/SubText
@onready var continue_lbl: Label        = $UI/DialogueBox/ContinueLabel
@onready var panel_num_lbl:Label        = $UI/PanelNumber
@onready var skip_btn:     Button       = $UI/SkipBtn
@onready var typewriter_timer: Timer    = $TypewriterTimer
@onready var bg_tween:     Tween        = null

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	skip_btn.pressed.connect(_on_skip)
	typewriter_timer.wait_time = CHAR_DELAY
	typewriter_timer.timeout.connect(_typewriter_tick)
	_show_panel(0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_advance()

# ─── Navegación ──────────────────────────────────────────────────────────────

func _advance() -> void:
	if is_animating:
		return
	if not text_revealed:
		# Mostrar todo el texto de golpe
		_finish_typewriter()
		return
	# Siguiente panel
	panel_index += 1
	if panel_index >= PANELS.size():
		_go_to_level1()
	else:
		_show_panel(panel_index)

func _show_panel(idx: int) -> void:
	is_animating = true
	text_revealed = false
	var p: Dictionary = PANELS[idx]

	# Número de panel
	panel_num_lbl.text = "%d / %d" % [idx + 1, PANELS.size()]

	# Fondo
	_load_texture_async(bg_rect, p.bg)

	# Kalin sprite
	if p.kalin != "":
		_load_texture_async(kalin_sprite, p.kalin)
		kalin_sprite.position.x = p.kalin_x
		kalin_sprite.visible = true
		# Subtle entrance animation
		var tw: Tween = create_tween()
		kalin_sprite.modulate.a = 0.0
		tw.tween_property(kalin_sprite, "modulate:a", 1.0, 0.4)
	else:
		kalin_sprite.visible = false

	# Diálogo
	main_text.text = ""
	sub_text.text  = p.get("subtext", "")
	full_text      = p.text
	continue_lbl.visible = false

	# Fade in dialogue box
	dialogue_box.modulate.a = 0.0
	var tw2: Tween = create_tween()
	tw2.tween_property(dialogue_box, "modulate:a", 1.0, 0.3)
	await tw2.finished

	is_animating = false
	# Start typewriter
	_start_typewriter()

# ─── Typewriter effect ───────────────────────────────────────────────────────

func _start_typewriter() -> void:
	main_text.text   = ""
	main_text.visible_characters = 0
	main_text.text   = full_text
	typewriter_timer.start()

func _typewriter_tick() -> void:
	if main_text.visible_characters < main_text.get_total_character_count():
		main_text.visible_characters += 1
	else:
		_finish_typewriter()

func _finish_typewriter() -> void:
	typewriter_timer.stop()
	main_text.visible_characters = -1   # show all
	text_revealed = true
	continue_lbl.visible = true

# ─── Utilidades ──────────────────────────────────────────────────────────────

func _load_texture_async(rect: TextureRect, path: String) -> void:
	if path == "":
		rect.texture = null
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		rect.texture = tex

func _on_skip() -> void:
	_go_to_level1()

func _go_to_level1() -> void:
	# Mark intro as seen
	GameManager.go_to_level(1, 1)
