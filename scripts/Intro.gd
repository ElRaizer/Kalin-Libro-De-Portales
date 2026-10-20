@tool
## Intro.gd
## Introducción visual novel de Kalin y el Libro de los Portales.
## Presenta al personaje, establece el contexto narrativo y lleva al Nivel 1.
## El jugador avanza con clic / espacio / Enter.

extends Node2D

@export var panels: Array[IntroPanelData] = []

# ─── Estado ──────────────────────────────────────────────────────────────────
var panel_index: int = 0
var is_animating: bool = false
var text_revealed: bool = false
var full_text: String = ""
@onready var continue_button: Button = $UI/ContinueButton
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

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	if not get_configuration_issues().is_empty():
		push_error("La introducción necesita paneles con sus fondos y personajes.")
		return
	continue_button.pressed.connect(_advance)
	$UI/MenuButton.pressed.connect(_on_menu_pressed)
	skip_btn.pressed.connect(_on_skip)
	typewriter_timer.wait_time = CHAR_DELAY
	typewriter_timer.timeout.connect(_typewriter_tick)
	_show_panel(clampi(int(GameManager.get_scene_state(self).get("panel", 0)), 0, panels.size() - 1))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# `_input` permite avanzar incluso sobre paneles decorativos. Los botones
		# se excluyen para que un clic en "Saltar intro" no avance dos veces.
		if get_viewport().gui_get_hovered_control() is BaseButton:
			return
		get_viewport().set_input_as_handled()
		# Atender el evento antes de avanzar: el último panel cambia de escena y
		# este nodo deja de tener un Viewport inmediatamente.
		_advance()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
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
	if panel_index >= panels.size():
		_go_to_level1()
	else:
		_show_panel(panel_index)

func _show_panel(idx: int) -> void:
	panel_index = idx
	GameManager.checkpoint(self)
	is_animating = true
	text_revealed = false
	var p: IntroPanelData = panels[idx]

	# Número de panel
	panel_num_lbl.text = "%d / %d" % [idx + 1, panels.size()]

	# Fondo
	bg_rect.texture = p.background

	# Kalin sprite
	if p.kalin != null:
		kalin_sprite.texture = p.kalin
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
	sub_text.text  = p.subtext
	full_text      = p.text
	continue_lbl.visible = false
	continue_button.disabled = true

	# Fade in dialogue box
	dialogue_box.modulate.a = 0.0
	var tw2: Tween = create_tween()
	tw2.tween_property(dialogue_box, "modulate:a", 1.0, 0.3)
	tw2.finished.connect(_on_panel_faded)

func _on_panel_faded() -> void:
	is_animating = false
	continue_button.disabled = false
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
	continue_lbl.visible = false

# ─── Utilidades ──────────────────────────────────────────────────────────────

func _on_menu_pressed() -> void:
	GameManager.go_to_scene("main_menu")

func _on_skip() -> void:
	GameManager.go_to_scene("world1_explore1")

func _go_to_level1() -> void:
	# La intro continúa con la cinemática de la noche del huracán y luego con el
	# primer capítulo de historia del Mundo 1.
	GameManager.go_to_scene("world1_cine1")

func get_checkpoint_state() -> Dictionary:
	return {"panel": panel_index}

func get_configuration_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if panels.is_empty():
		issues.append("Agrega al menos un panel narrativo.")
	for panel: IntroPanelData in panels:
		if panel == null or panel.background == null:
			issues.append("Asigna un recurso y un fondo a cada panel narrativo.")
	return issues

func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()
