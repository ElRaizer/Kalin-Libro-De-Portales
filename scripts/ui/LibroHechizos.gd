## LibroHechizos.gd  v2
## Panel de vocabulario maya aprendido.
## Cada tarjeta tiene un botón de audio que reproduce el .ogg si existe,
## o muestra un aviso de "próximamente" si el archivo aún no está disponible.

extends CanvasLayer

# ─── Nodos ───────────────────────────────────────────────────────────────────
@onready var word_grid:      GridContainer = $BG/Panel/Scroll/WordGrid
@onready var close_btn:      Button        = $BG/Panel/CloseBtn
@onready var empty_label:    Label         = $BG/Panel/EmptyLabel
@onready var word_count_lbl: Label         = $BG/Panel/Header/WordCount
@onready var audio_player:   AudioStreamPlayer = $AudioPlayer
@onready var audio_notice:   Label         = $BG/AudioNotice

# ─── Constantes visuales ─────────────────────────────────────────────────────
const CARD_SIZE     := Vector2(220, 155)
const CARD_BG       := Color(0.96, 0.92, 0.78)
const CARD_BORDER   := Color(0.55, 0.38, 0.18)

## Convención de nombres de archivo de audio:
## res://Arte/audio/<maya_word_sin_apostrofe>.ogg
## Ejemplo: "Peek'" → "Peek.ogg",  "Miis" → "Miis.ogg"
const AUDIO_BASE := "res://Arte/audio/"

# ─── Estado ──────────────────────────────────────────────────────────────────
var _notice_tween: Tween

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	visible = false
	close_btn.pressed.connect(hide_book)
	GameManager.word_learned.connect(_on_word_learned)
	audio_notice.visible = false

func show_book() -> void:
	_populate()
	visible = true

func hide_book() -> void:
	visible = false
	if audio_player.playing: audio_player.stop()

# ─── Poblar tarjetas ─────────────────────────────────────────────────────────
func _populate() -> void:
	for child in word_grid.get_children():
		child.queue_free()

	var learned := GameManager.words_learned
	empty_label.visible  = learned.is_empty()
	word_count_lbl.text  = "Palabras aprendidas: %d / %d" % [
		learned.size(), GameManager.VOCABULARY.size()
	]

	# Agrupar por nivel
	var by_level: Dictionary = {}
	for word: String in learned:
		var lvl: int = learned[word].get("level", 0)
		if lvl not in by_level: by_level[lvl] = []
		by_level[lvl].append(word)

	var levels := by_level.keys(); levels.sort()
	for lvl in levels:
		word_grid.add_child(_make_separator("Nivel %d" % lvl))
		for _i in range(2):
			word_grid.add_child(Control.new())   # relleno de columnas
		for word: String in by_level[lvl]:
			word_grid.add_child(_make_card(word, learned[word]))

# ─── Tarjeta individual ───────────────────────────────────────────────────────
func _make_card(maya_word: String, data: Dictionary) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color   = CARD_BG
	style.border_color = CARD_BORDER
	style.set_border_width_all(2)
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)

	# Emoji
	var emoji_lbl := Label.new()
	emoji_lbl.text = data.get("emoji", "?")
	emoji_lbl.add_theme_font_size_override("font_size", 36)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Palabra maya
	var maya_lbl := Label.new()
	maya_lbl.text = maya_word
	maya_lbl.add_theme_font_size_override("font_size", 20)
	maya_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	maya_lbl.add_theme_color_override("font_color", Color(0.18, 0.08, 0.0))

	# Traduccion
	var es_lbl := Label.new()
	es_lbl.text = data.get("spanish", "")
	es_lbl.add_theme_font_size_override("font_size", 13)
	es_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	es_lbl.add_theme_color_override("font_color", Color(0.40, 0.28, 0.08))

	# Estructura de frase
	var struct_lbl := Label.new()
	struct_lbl.text = data.get("estructura", "")
	struct_lbl.add_theme_font_size_override("font_size", 11)
	struct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	struct_lbl.add_theme_color_override("font_color", Color(0.25, 0.48, 0.18))
	struct_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ── Botón de audio ──────────────────────────────────────────────────────
	var audio_file := _audio_path(maya_word)
	var audio_exists := ResourceLoader.exists(audio_file)

	var audio_btn := Button.new()
	audio_btn.text = "Escuchar" if audio_exists else "Audio pronto"
	audio_btn.disabled = not audio_exists
	audio_btn.add_theme_font_size_override("font_size", 12)
	audio_btn.custom_minimum_size = Vector2(0, 28)

	# Color del botón según disponibilidad
	if audio_exists:
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color     = Color(0.25, 0.55, 0.82)
		btn_style.corner_radius_top_left     = 5
		btn_style.corner_radius_top_right    = 5
		btn_style.corner_radius_bottom_left  = 5
		btn_style.corner_radius_bottom_right = 5
		audio_btn.add_theme_stylebox_override("normal", btn_style)
		audio_btn.add_theme_color_override("font_color", Color.WHITE)
		# Conectar con la palabra capturada en lambda
		audio_btn.pressed.connect(func(): _play_audio(maya_word))
	else:
		audio_btn.add_theme_color_override("font_color", Color(0.55, 0.45, 0.30))
		audio_btn.tooltip_text = "El archivo de audio sera agregado proximamente."
		audio_btn.pressed.connect(func(): _show_notice("Audio de \"%s\" proximamente" % maya_word))

	vbox.add_child(emoji_lbl)
	vbox.add_child(maya_lbl)
	vbox.add_child(es_lbl)
	vbox.add_child(struct_lbl)
	vbox.add_child(audio_btn)
	card.add_child(vbox)
	return card

# ─── Reproducir audio ─────────────────────────────────────────────────────────
func _play_audio(maya_word: String) -> void:
	var path := _audio_path(maya_word)
	if not ResourceLoader.exists(path):
		_show_notice("Audio de \"%s\" no encontrado" % maya_word)
		return
	var stream := load(path) as AudioStream
	if stream:
		audio_player.stream = stream
		audio_player.play()

## Devuelve la ruta del archivo de audio para una palabra maya.
## Elimina apóstrofes y espacios para obtener el nombre de archivo.
func _audio_path(maya_word: String) -> String:
	var clean := maya_word.replace("'", "").replace(" ", "_")
	return AUDIO_BASE + clean + ".ogg"

# ─── Aviso flotante ──────────────────────────────────────────────────────────
func _show_notice(msg: String) -> void:
	audio_notice.text    = msg
	audio_notice.visible = true
	if _notice_tween: _notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(2.2)
	_notice_tween.tween_property(audio_notice, "modulate:a", 0.0, 0.5)
	_notice_tween.tween_callback(func(): audio_notice.visible = false; audio_notice.modulate.a = 1.0)

# ─── Separador de nivel ───────────────────────────────────────────────────────
func _make_separator(title: String) -> Label:
	var lbl := Label.new()
	lbl.text = "-- %s --" % title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.4, 0.1))
	lbl.custom_minimum_size.y = 28
	return lbl

# ─── Señales ─────────────────────────────────────────────────────────────────
func _on_word_learned(_data: Dictionary) -> void:
	if visible: _populate()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			hide_book()
