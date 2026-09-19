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

## Convención de nombres de archivo de audio:
## res://Arte/audio/<maya_word_ascii>.ogg
## Ejemplo: "Peek'" → "Peek.ogg", "K'úum" → "Kuum.ogg"
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

	var learned: Dictionary = GameManager.words_learned
	empty_label.visible  = learned.is_empty()
	word_count_lbl.text  = "Palabras aprendidas: %d / %d" % [
		learned.size(), GameManager.VOCABULARY.size()
	]

	# Agrupar por mundo y nivel para respetar la estructura de mecánicas.
	var by_stage: Dictionary = {}
	for word: String in learned:
		var world: int = learned[word].get("world", 0)
		var lvl: int = learned[word].get("level", 0)
		var stage_key: String = "%03d_%03d" % [world, lvl]
		if stage_key not in by_stage:
			by_stage[stage_key] = {"world": world, "level": lvl, "words": []}
		by_stage[stage_key].words.append(word)

	var stages: Array = by_stage.keys(); stages.sort()
	for stage_key: String in stages:
		var stage: Dictionary = by_stage[stage_key]
		word_grid.add_child(_make_separator("Mundo %d · Nivel %d" % [stage.world, stage.level]))
		for _i in range(2):
			word_grid.add_child(Control.new())   # relleno de columnas
		for word: String in stage.words:
			word_grid.add_child(_make_card(word, learned[word]))

# ─── Tarjeta individual ───────────────────────────────────────────────────────
func _make_card(maya_word: String, data: Dictionary) -> Panel:
	var card: Panel = Panel.new()
	card.custom_minimum_size = CARD_SIZE

	card.theme_type_variation = &"KalinBookCard"

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 3)

	# Emoji
	var emoji_lbl: Label = Label.new()
	emoji_lbl.text = data.get("emoji", "?")
	emoji_lbl.add_theme_font_size_override("font_size", 36)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Palabra maya
	var maya_lbl: Label = Label.new()
	maya_lbl.text = maya_word
	maya_lbl.add_theme_font_size_override("font_size", 20)
	maya_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	maya_lbl.add_theme_color_override("font_color", Color(0.18, 0.08, 0.0))

	# Traduccion
	var es_lbl: Label = Label.new()
	es_lbl.text = data.get("spanish", "")
	es_lbl.add_theme_font_size_override("font_size", 13)
	es_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	es_lbl.add_theme_color_override("font_color", Color(0.40, 0.28, 0.08))

	# Estructura de frase
	var struct_lbl: Label = Label.new()
	struct_lbl.text = data.get("estructura", "")
	struct_lbl.add_theme_font_size_override("font_size", 11)
	struct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	struct_lbl.add_theme_color_override("font_color", Color(0.25, 0.48, 0.18))
	struct_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ── Botón de audio ──────────────────────────────────────────────────────
	var audio_file: String = _audio_path(maya_word)
	var audio_exists: bool = ResourceLoader.exists(audio_file)

	var audio_btn: Button = Button.new()
	audio_btn.text = "Escuchar" if audio_exists else "Audio pronto"
	audio_btn.disabled = not audio_exists
	audio_btn.add_theme_font_size_override("font_size", 12)
	audio_btn.custom_minimum_size = Vector2(0, 28)

	# Color del botón según disponibilidad
	if audio_exists:
		audio_btn.theme_type_variation = &"KalinAudioButton"
		# Conectar con la palabra capturada en lambda
		audio_btn.pressed.connect(func(): _play_audio(maya_word))
	else:
		audio_btn.add_theme_color_override("font_color", Color(0.55, 0.45, 0.30))
		audio_btn.tooltip_text = "El archivo de audio será agregado próximamente."
		audio_btn.pressed.connect(func(): _show_notice("Audio de \"%s\" próximamente" % maya_word))

	vbox.add_child(emoji_lbl)
	vbox.add_child(maya_lbl)
	vbox.add_child(es_lbl)
	vbox.add_child(struct_lbl)
	vbox.add_child(audio_btn)
	card.add_child(vbox)
	return card

# ─── Reproducir audio ─────────────────────────────────────────────────────────
func _play_audio(maya_word: String) -> void:
	var path: String = _audio_path(maya_word)
	if not ResourceLoader.exists(path):
		_show_notice("Audio de \"%s\" no encontrado" % maya_word)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream:
		audio_player.stream = stream
		audio_player.play()

## Devuelve la ruta del archivo de audio para una palabra maya.
## Elimina acentos y apóstrofos para obtener un nombre portable.
func _audio_path(maya_word: String) -> String:
	return AUDIO_BASE + GameManager.get_audio_filename(maya_word)

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
	var lbl: Label = Label.new()
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
