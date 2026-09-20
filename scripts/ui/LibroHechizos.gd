## Libro de Hechizos paginado. Cada pliego muestra dos entradas con contexto,
## ejemplo de uso, estructura e ilustración o un espacio para arte futuro.
extends CanvasLayer

const AUDIO_BASE := "res://Arte/audio/"
const WORDS_PER_SPREAD := 2

@onready var close_button: Button = $BG/Book/CloseButton
@onready var previous_button: Button = $BG/Book/Footer/PreviousButton
@onready var next_button: Button = $BG/Book/Footer/NextButton
@onready var page_label: Label = $BG/Book/Footer/PageLabel
@onready var word_count_label: Label = $BG/Book/Header/WordCount
@onready var empty_label: Label = $BG/Book/EmptyLabel
@onready var left_page: Panel = $BG/Book/Pages/LeftPage
@onready var right_page: Panel = $BG/Book/Pages/RightPage
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var audio_notice: Label = $BG/AudioNotice

var _entries: Array[String] = []
var _spread_index: int = 0
var _visible_words: Array[String] = ["", ""]
var _notice_tween: Tween

func _ready() -> void:
	visible = false
	close_button.pressed.connect(hide_book)
	previous_button.pressed.connect(_previous_spread)
	next_button.pressed.connect(_next_spread)
	left_page.get_node("Content/AudioButton").pressed.connect(_play_visible_audio.bind(0))
	right_page.get_node("Content/AudioButton").pressed.connect(_play_visible_audio.bind(1))
	GameManager.word_learned.connect(_on_word_learned)
	audio_notice.visible = false

func show_book() -> void:
	_collect_entries()
	_spread_index = clampi(_spread_index, 0, maxi(_spread_count() - 1, 0))
	_render_spread()
	visible = true
	close_button.grab_focus()

func hide_book() -> void:
	visible = false
	if audio_player.playing:
		audio_player.stop()

func _collect_entries() -> void:
	_entries.clear()
	for maya_word: String in GameManager.words_learned:
		if maya_word not in GameManager.FUTURE_VOCABULARY:
			_entries.append(maya_word)
	_entries.sort_custom(_sort_entries)
	word_count_label.text = "%d de %d entradas recuperadas" % [
		_entries.size(), GameManager.get_learnable_word_count()
	]

func _sort_entries(a: String, b: String) -> bool:
	var a_data := GameManager.get_vocabulary_entry(a)
	var b_data := GameManager.get_vocabulary_entry(b)
	var a_stage := int(a_data.get("world", 0)) * 100 + int(a_data.get("level", 0))
	var b_stage := int(b_data.get("world", 0)) * 100 + int(b_data.get("level", 0))
	return a.to_lower() < b.to_lower() if a_stage == b_stage else a_stage < b_stage

func _spread_count() -> int:
	return ceili(float(_entries.size()) / WORDS_PER_SPREAD)

func _render_spread() -> void:
	var empty := _entries.is_empty()
	empty_label.visible = empty
	left_page.visible = not empty
	right_page.visible = not empty
	previous_button.disabled = empty or _spread_index <= 0
	next_button.disabled = empty or _spread_index >= _spread_count() - 1
	if empty:
		page_label.text = "El libro espera su primera palabra"
		return
	var first_index := _spread_index * WORDS_PER_SPREAD
	_render_page(left_page, first_index, 0)
	_render_page(right_page, first_index + 1, 1)
	page_label.text = "Pliego %d de %d" % [_spread_index + 1, _spread_count()]

func _render_page(page: Panel, entry_index: int, visible_slot: int) -> void:
	var content := page.get_node("Content") as VBoxContainer
	var locked := page.get_node("LockedPage") as Label
	if entry_index >= _entries.size():
		content.visible = false
		locked.visible = true
		locked.text = "La siguiente página aún está en blanco..."
		_visible_words[visible_slot] = ""
		return
	content.visible = true
	locked.visible = false
	var maya_word := _entries[entry_index]
	var data := GameManager.get_vocabulary_entry(maya_word)
	_visible_words[visible_slot] = maya_word
	(content.get_node("StageLabel") as Label).text = "Mundo %d · Nivel %d" % [data.world, data.level]
	(content.get_node("MayaLabel") as Label).text = maya_word
	(content.get_node("SpanishLabel") as Label).text = str(data.get("spanish", ""))
	(content.get_node("ExampleLabel") as Label).text = "Ejemplo\n%s" % str(data.get("estructura", ""))
	(content.get_node("TranslationLabel") as Label).text = str(data.get("traduccion", ""))
	(content.get_node("DiagramLabel") as Label).text = _structure_diagram(str(data.get("estructura", maya_word)))
	var illustration := content.get_node("Illustration/ContextSprite") as TextureRect
	var placeholder := content.get_node("Illustration/Placeholder") as Label
	var image_path := GameManager.get_book_illustration(maya_word)
	if image_path != "" and ResourceLoader.exists(image_path):
		illustration.texture = load(image_path)
		illustration.visible = true
		placeholder.visible = false
	else:
		illustration.texture = null
		illustration.visible = false
		placeholder.visible = true
		placeholder.text = "%s\nIlustración futura" % str(data.get("emoji", "✦"))
	var audio_button := content.get_node("AudioButton") as Button
	var audio_exists := ResourceLoader.exists(_audio_path(maya_word))
	audio_button.disabled = not audio_exists
	audio_button.text = "Escuchar pronunciación" if audio_exists else "Audio próximamente"
	audio_button.tooltip_text = "La grabación se integrará en una etapa posterior." if not audio_exists else ""

func _structure_diagram(example: String) -> String:
	var tokens := example.split(" ", false)
	if tokens.size() <= 1:
		return "[ %s ]" % example
	var boxes: Array[String] = []
	for token: String in tokens:
		boxes.append("[ %s ]" % token)
	return "  →  ".join(boxes)

func _previous_spread() -> void:
	if _spread_index <= 0:
		return
	_spread_index -= 1
	_render_spread()

func _next_spread() -> void:
	if _spread_index >= _spread_count() - 1:
		return
	_spread_index += 1
	_render_spread()

func _play_visible_audio(slot: int) -> void:
	if slot < 0 or slot >= _visible_words.size() or _visible_words[slot] == "":
		return
	var maya_word := _visible_words[slot]
	var path := _audio_path(maya_word)
	if not ResourceLoader.exists(path):
		_show_notice("Audio de \"%s\" próximamente" % maya_word)
		return
	var stream := load(path) as AudioStream
	if stream:
		audio_player.stream = stream
		audio_player.play()

func _audio_path(maya_word: String) -> String:
	return AUDIO_BASE + GameManager.get_audio_filename(maya_word)

func _show_notice(message: String) -> void:
	audio_notice.text = message
	audio_notice.visible = true
	audio_notice.modulate.a = 1.0
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(2.0)
	_notice_tween.tween_property(audio_notice, "modulate:a", 0.0, 0.4)
	_notice_tween.tween_callback(func(): audio_notice.visible = false)

func _on_word_learned(_data: Dictionary) -> void:
	if visible:
		_collect_entries()
		_render_spread()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			hide_book()
		KEY_LEFT:
			_previous_spread()
		KEY_RIGHT:
			_next_spread()
		_:
			return
	get_viewport().set_input_as_handled()
