## Libro de Hechizos paginado. Cada pliego muestra dos entradas con contexto,
## ejemplo de uso, estructura e ilustración o un espacio para arte futuro.
extends CanvasLayer

const AUDIO_BASE := "res://Arte/audio/"
var _words_per_spread: int = 2
var _compact: bool = false
@onready var compact_page: Panel = $BG/Book/CompactPage

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
@onready var _notice_alpha: float = $BG/AudioNotice.modulate.a
@onready var motion: Node = $Motion
@onready var pages: Control = $BG/Book/Pages
@onready var _pages_position: Vector2 = pages.position

var _entries: Array[String] = []
var _spread_index: int = 0
var _visible_words: Array[String] = ["", ""]
var _notice_tween: Tween
var _previous_focus: Control
var _owns_pause: bool = false
var _new_word: String = ""
var _category: int = 0
var category_buttons: Array[Button] = []
var _known_words: Dictionary = {}
var _source_button: Control
var _source_rect: Rect2 = Rect2(1170, 20, 80, 44)
var _turn_tween: Tween
var _highlight_tween: Tween
var _turning: bool = false
var _highlight_word: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	close_button.pressed.connect(hide_book)
	previous_button.pressed.connect(_previous_spread)
	next_button.pressed.connect(_next_spread)
	left_page.get_node("Content/AudioButton").pressed.connect(_play_visible_audio.bind(0))
	right_page.get_node("Content/AudioButton").pressed.connect(_play_visible_audio.bind(1))
	GameManager.word_learned.connect(_on_word_learned)
	GameManager.progress_reset.connect(_reset_book)
	GameManager.learning_changed.connect(_refresh_learning)
	audio_notice.visible = false
	_known_words = GameManager.learned_words()
	_build_categories()
	motion.opened.connect(_on_opened)
	motion.closed.connect(_on_closed)
	compact_page.get_node("Content/AudioButton").pressed.connect(_play_visible_audio.bind(0))
	get_window().size_changed.connect(_update_screen_layout)
	_update_screen_layout()


func _reset_book() -> void:
	_known_words.clear()
	_entries.clear()
	_new_word = ""
	_category = 0
	_spread_index = 0
	if visible:
		_cancel_turn()
		_collect_entries()
		_render_spread()


func _build_categories() -> void:
	for index: int in range($BG/Book/Categories.get_child_count()):
		var button: Button = $BG/Book/Categories.get_child(index) as Button
		button.pressed.connect(_select_category.bind(index))
		category_buttons.append(button)


func _select_category(index: int) -> void:
	for category_index: int in range(category_buttons.size()):
		category_buttons[category_index].set_pressed_no_signal(category_index == _category)
	if index == _category or index < 0 or index >= category_buttons.size():
		return
	if _turning or motion.busy:
		return
	_turn_pages(
		func():
			_category = index
			_spread_index = 0
			_collect_entries()
			_render_spread(),
		1 if index > _category else -1
	)


func show_book(source: Control = null) -> void:
	if visible:
		return
	GameManager.mark_learning_support()
	_previous_focus = get_viewport().gui_get_focus_owner()
	_source_button = source
	if is_instance_valid(source):
		_source_rect = source.get_global_rect()
	_owns_pause = not get_tree().paused
	get_tree().paused = true
	if not _new_word.is_empty():
		_category = VocabularyCatalog.book_category(_new_word)
	_collect_entries()
	if _new_word in _entries:
		_spread_index = floori(float(_entries.find(_new_word)) / _words_per_spread)
		_highlight_word = _new_word
		_new_word = ""
	_spread_index = clampi(_spread_index, 0, maxi(_spread_count() - 1, 0))
	_render_spread()
	visible = true
	_set_page_input(false)
	SoundCue.play(self, "libro_abrir")
	motion.open_from(_source_rect)


func hide_book() -> void:
	if not visible or motion.closing:
		return
	SoundCue.play(self, "libro_cerrar")
	_cancel_turn()
	_clear_effects()
	_set_page_input(false)
	close_button.release_focus()
	audio_player.stop()
	if is_instance_valid(_source_button):
		_source_rect = _source_button.get_global_rect()
	motion.close_to(_source_rect)


func _on_opened() -> void:
	_set_page_input(true)
	close_button.grab_focus()
	if _highlight_word in _visible_words:
		var page: Panel = (
			compact_page
			if _compact
			else (left_page if _visible_words[0] == _highlight_word else right_page)
		)
		_highlight_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_highlight_tween.tween_property(page, "self_modulate", Color(1.08, 1.04, 0.83), 0.18)
		_highlight_tween.tween_property(page, "self_modulate", Color.WHITE, 0.5)
	_highlight_word = ""


func _on_closed() -> void:
	visible = false
	if _owns_pause:
		get_tree().paused = false
	_owns_pause = false
	if audio_player.playing:
		audio_player.stop()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null
	_source_button = null


func _clear_effects() -> void:
	if _highlight_tween:
		_highlight_tween.kill()
	left_page.self_modulate = Color.WHITE
	right_page.self_modulate = Color.WHITE
	compact_page.self_modulate = Color.WHITE
	_highlight_word = ""
	if _notice_tween:
		_notice_tween.kill()
	audio_notice.hide()


func _exit_tree() -> void:
	if _owns_pause and get_tree() != null:
		get_tree().paused = false


func _collect_entries() -> void:
	_entries.clear()
	for maya_word: String in GameManager.learned_words():
		var section: int = VocabularyCatalog.book_category(maya_word)
		if (
			maya_word not in GameContent.FUTURE_VOCABULARY
			and (
				_category == 0 or section == _category or (_category == 4 and maya_word == "janal")
			)
		):
			_entries.append(maya_word)
	_entries.sort_custom(_sort_entries)
	for index: int in range(category_buttons.size()):
		category_buttons[index].button_pressed = index == _category
	word_count_label.text = (
		"%d de %d entradas recuperadas"
		% [GameManager.get_recovered_word_count(), VocabularyCatalog.learnable_keys().size()]
	)


func _sort_entries(a: String, b: String) -> bool:
	var a_data: Dictionary = VocabularyCatalog.entry(a)
	var b_data: Dictionary = VocabularyCatalog.entry(b)
	var a_stage: int = int(a_data.get("world", 0)) * 100 + int(a_data.get("level", 0))
	var b_stage: int = int(b_data.get("world", 0)) * 100 + int(b_data.get("level", 0))
	if a_stage != b_stage:
		return a_stage < b_stage
	# Los números se leen en su orden (jun, ka'a, óox...), no alfabéticamente.
	var a_value: int = VocabularyCatalog.number_value(a)
	var b_value: int = VocabularyCatalog.number_value(b)
	if a_value > 0 and b_value > 0:
		return a_value < b_value
	return a.to_lower() < b.to_lower()


func _spread_count() -> int:
	return ceili(float(_entries.size()) / _words_per_spread)


func _render_spread() -> void:
	var empty: bool = _entries.is_empty()
	empty_label.visible = empty
	left_page.visible = not empty and not _compact
	right_page.visible = not empty and not _compact
	compact_page.visible = not empty and _compact
	_set_page_input(not _turning and not motion.busy)
	if empty:
		_visible_words.assign(["", ""])
		empty_label.text = "Las palabras que recuperes aparecerán aquí."
		page_label.text = "Todavía no hay palabras en esta sección"
		return
	var first_index: int = _spread_index * _words_per_spread
	if _compact:
		_render_page(compact_page, first_index, 0)
		_visible_words[1] = ""
	else:
		_render_page(left_page, first_index, 0)
		_render_page(right_page, first_index + 1, 1)
	var last_index: int = mini(first_index + _words_per_spread, _entries.size())
	page_label.text = (
		"Página %d de %d" % [last_index, _entries.size()]
		if first_index + 1 == last_index
		else "Páginas %d–%d de %d" % [first_index + 1, last_index, _entries.size()]
	)


func _render_page(page: Panel, entry_index: int, visible_slot: int) -> void:
	var content: Control = page.get_node("Content") as Control
	var locked: Label = page.get_node("LockedPage") as Label
	if entry_index >= _entries.size():
		content.visible = false
		locked.visible = true
		locked.text = "La siguiente página aún está en blanco..."
		_visible_words[visible_slot] = ""
		return
	content.visible = true
	locked.visible = false
	var maya_word: String = _entries[entry_index]
	var data: Dictionary = VocabularyCatalog.entry(maya_word)
	_visible_words[visible_slot] = maya_word
	var stage: Label = content.get_node("StageLabel") as Label
	stage.text = GameManager.learning_caption(maya_word).get_slice(" · ", 0)
	stage.tooltip_text = (
		GameManager.learning_caption(maya_word) + "\n" + GameManager.learning_detail(maya_word)
	)
	(content.get_node("StageLabel") as Label).show()
	(content.get_node("MayaLabel") as Label).text = maya_word
	(content.get_node("SpanishLabel") as Label).text = str(data.get("spanish", ""))
	var example: String = str(data.get("estructura", ""))
	var translation: String = str(data.get("traduccion", ""))
	(content.get_node("ExampleLabel") as Label).text = example
	(content.get_node("TranslationLabel") as Label).text = translation
	(content.get_node("DiagramLabel") as Label).text = _structure_diagram(
		str(data.get("estructura", maya_word))
	)
	var illustration: TextureRect = content.get_node("Illustration/ContextSprite") as TextureRect
	var placeholder: Label = content.get_node("Illustration/Placeholder") as Label
	var image_path: String = GameManager.get_book_illustration(maya_word)
	if image_path != "" and ResourceLoader.exists(image_path):
		illustration.texture = GameManager.get_visual_texture(maya_word)
		illustration.visible = true
		placeholder.visible = false
	else:
		illustration.texture = null
		illustration.visible = false
		placeholder.visible = true
		placeholder.text = "%s\nIlustración futura" % str(data.get("emoji", "✦"))
	var audio_button: Button = content.get_node("AudioButton") as Button
	var audio_exists: bool = ResourceLoader.exists(_audio_path(maya_word))
	audio_button.disabled = _turning or motion.busy
	audio_button.text = (
		"Escuchar pronunciación" if audio_exists else "Pronunciación · audio próximamente"
	)
	audio_button.tooltip_text = (
		"Esta palabra todavía no tiene audio."
		if not audio_exists
		else "Escuchar la grabación de esta palabra."
	)


func _structure_diagram(example: String) -> String:
	var tokens: PackedStringArray = example.split(" ", false)
	if tokens.size() <= 1:
		return "[ %s ]" % example
	var boxes: Array[String] = []
	for token: String in tokens:
		boxes.append("[ %s ]" % token)
	return "  →  ".join(boxes)


func _refresh_learning() -> void:
	if visible:
		_cancel_turn()
		_render_spread()
		_set_page_input(not motion.busy)


func _previous_spread() -> void:
	if _spread_index <= 0 or _turning or motion.busy:
		return
	_turn_pages(
		func():
			_spread_index -= 1
			_render_spread(),
		-1
	)


func _next_spread() -> void:
	if _spread_index >= _spread_count() - 1 or _turning or motion.busy:
		return
	_turn_pages(
		func():
			_spread_index += 1
			_render_spread(),
		1
	)


func _turn_pages(render: Callable, direction: int) -> void:
	_clear_effects()
	audio_player.stop()
	SoundCue.play(self, "pagina_pasar")
	_turning = true
	var focused: Control = get_viewport().gui_get_focus_owner()
	_set_page_input(false)
	_turn_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_turn_tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turn_tween.tween_property(pages, "modulate:a", 0.0, 0.10)
	_turn_tween.tween_property(pages, "position:x", _pages_position.x - 12.0 * direction, 0.10)
	_turn_tween.chain().tween_callback(
		func():
			render.call()
			_set_page_input(false)
			pages.position.x = _pages_position.x + 12.0 * direction
	)
	_turn_tween.chain().tween_property(pages, "modulate:a", 1.0, 0.15)
	_turn_tween.parallel().tween_property(pages, "position:x", _pages_position.x, 0.15)
	_turn_tween.chain().tween_callback(
		func():
			_turning = false
			_set_page_input(true)
			if is_instance_valid(focused) and focused is Button:
				if not focused.disabled:
					focused.grab_focus()
				else:
					close_button.grab_focus()
	)


func _cancel_turn() -> void:
	if _turn_tween:
		_turn_tween.kill()
	_turning = false
	pages.position = _pages_position
	pages.modulate.a = 1.0


func _set_page_input(enabled: bool) -> void:
	for button: Button in category_buttons:
		button.disabled = not enabled
	previous_button.disabled = not enabled or _entries.is_empty() or _spread_index <= 0
	next_button.disabled = (
		not enabled or _entries.is_empty() or _spread_index >= _spread_count() - 1
	)
	for page: Panel in [left_page, right_page, compact_page]:
		(page.get_node("Content/AudioButton") as Button).disabled = not enabled


func _play_visible_audio(slot: int) -> void:
	if motion.busy or _turning or not visible:
		return
	if slot < 0 or slot >= _visible_words.size() or _visible_words[slot] == "":
		return
	var maya_word: String = _visible_words[slot]
	var path: String = _audio_path(maya_word)
	if not ResourceLoader.exists(path):
		_show_notice("«%s» todavía no tiene audio. Próximamente." % maya_word)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream:
		audio_player.stream = stream
		audio_player.play()


func _audio_path(maya_word: String) -> String:
	return AUDIO_BASE + VocabularyCatalog.audio_filename(maya_word)


func _show_notice(message: String) -> void:
	audio_notice.text = message
	audio_notice.visible = true
	audio_notice.modulate.a = _notice_alpha
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(2.0)
	_notice_tween.tween_property(audio_notice, "modulate:a", 0.0, 0.4)
	_notice_tween.tween_callback(func(): audio_notice.visible = false)


func _on_word_learned(_data: Dictionary) -> void:
	for word: String in GameManager.learned_words():
		if word not in _known_words:
			_new_word = word
	_known_words = GameManager.learned_words()
	if visible:
		_cancel_turn()
		_collect_entries()
		_render_spread()
		_set_page_input(not motion.busy)


func _input(event: InputEvent) -> void:
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


func _update_screen_layout() -> void:
	var next_compact: bool = ScreenLayout.is_compact(get_window())
	var entry_index: int = _spread_index * _words_per_spread
	_cancel_turn()
	_compact = next_compact
	_words_per_spread = 1 if _compact else 2
	_spread_index = entry_index / _words_per_spread
	$BG/Book/Pages.visible = not _compact
	$BG/Book/Spine.visible = not _compact
	$BG/Book/FoldShadow.visible = not _compact
	compact_page.visible = _compact
	pages = compact_page if _compact else $BG/Book/Pages
	_pages_position = pages.position
	for button: Button in category_buttons:
		button.custom_minimum_size.y = 64 if _compact else 44
		button.add_theme_font_size_override("font_size", 26 if _compact else 18)
	previous_button.custom_minimum_size.y = 64 if _compact else 44
	previous_button.add_theme_font_size_override("font_size", 26 if _compact else 16)
	next_button.add_theme_font_size_override("font_size", 26 if _compact else 16)
	page_label.add_theme_font_size_override("font_size", 24 if _compact else 16)
	close_button.add_theme_font_size_override("font_size", 26 if _compact else 16)
	$BG/Book/Header/WordCount.add_theme_font_size_override("font_size", 22 if _compact else 15)
	next_button.custom_minimum_size.y = 60 if _compact else 44
	close_button.custom_minimum_size.y = 60 if _compact else 42
	if visible:
		_render_spread()
