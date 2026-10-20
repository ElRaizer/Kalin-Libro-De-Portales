## Mundo 2, nivel 1 — La Casa Maya (Objetos del hogar)
## Mecánica nueva (reemplaza el antiguo puzzle de caminos, que era idéntico
## al del Nivel 1): "Lanzar el hechizo correcto".
##
## Cada animal necesita un objeto para su casa. El jugador debe elegir el
## sustantivo maya correcto entre varias opciones para conjurarlo:
##   Fase 1 (Aprende):   se muestra la imagen Y la palabra en maya.
##   Fase 2 (Recuerda):  solo se muestra la imagen — sin apoyo escrito,
##                       tal como pide el GDD para el nivel avanzado.
## Vocabulario centralizado en GameManager.VOCABULARY, mundo 2 nivel 1:
##   mayak (mesa), lak (plato), ch'áak (cama), chan (silla), janal (comida)
extends Node2D
const EXERCISE_ENTRY = preload("res://scripts/data/ExerciseEntry.gd")

# Objeto solicitado, animal que lo pide, y refuerzo gramatical.
const RAW_OBJECTS: Array[Dictionary] = [
	{ "maya": "mayak",
	  "animal_spr": "res://Arte/sprites/animal_miis.svg",  "animal": "Miis",
	  "peticion": "Necesito un lugar para comer.",
	  "color": Color(0.85, 0.42, 0.18) },
	{ "maya": "lak",
	  "animal_spr": "res://Arte/sprites/animal_kaax.svg",  "animal": "Kaax",
	  "peticion": "Necesito algo para servir mi comida.",
	  "color": Color(0.30, 0.55, 0.82) },
	{ "maya": "ch'áak",
	  "animal_spr": "res://Arte/sprites/animal_peek.svg",  "animal": "Peek'",
	  "peticion": "Necesito un lugar para dormir.",
	  "color": Color(0.55, 0.35, 0.75) },
	{ "maya": "chan",
	  "animal_spr": "res://Arte/sprites/animal_aak.svg",   "animal": "Áak",
	  "peticion": "Necesito algo para sentarme.",
	  "color": Color(0.22, 0.62, 0.28) },
	{ "maya": "janal",
	  "animal_spr": "res://Arte/sprites/animal_keej.svg",  "animal": "Kéej",
	  "peticion": "Necesito algo para comer.",
	  "color": Color(0.80, 0.25, 0.20) },
]
static var OBJECTS: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_OBJECTS)

const TOTAL_ROUNDS := 10
var round_order: Array[int] = []
var round_index := 0
var current_phase := 0
var _completing := false
var _waiting := false
var _mistakes := 0
var _choice_buttons: Array[Button] = []
var guide: LearningGuide
var next_button: Button
var request_art: MeaningIllustration
var room: Panel
var room_items: Dictionary = {}

@onready var animal_spr: TextureRect = $UI/RequestPanel/AnimalSprite
@onready var need_lbl: Label = $UI/RequestPanel/VBox/NeedLbl
@onready var word_lbl: Label = $UI/RequestPanel/VBox/WordLbl
@onready var choices_grid: GridContainer = $UI/ChoicesGrid
@onready var feedback_lbl: Label = $UI/FeedbackPanel/FeedbackLbl
@onready var phase_lbl: Label = $UI/StatusPanel/StatusVBox/PhaseLbl
@onready var progress_lbl: Label = $UI/StatusPanel/StatusVBox/ProgressLbl
@onready var completion: CompletionOverlay = $UI/CompletionOverlay
@onready var magic_lbl: Label = $UI/TopBar/MagicLabel
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	for index: int in range(OBJECTS.size()):
		round_order.append(index)
	round_order.shuffle()
	var state := GameManager.get_scene_state(self)
	round_order = ExerciseProgress.order_or(state.get("order"), OBJECTS.size(), round_order)
	round_index = clampi(int(state.get("round", 0)), 0, TOTAL_ROUNDS)
	completion.next_pressed.connect(_on_next_level_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	GameManager.magic_points_changed.connect(_on_magic_points_changed)
	_on_magic_points_changed(GameManager.magic_points)
	guide = LearningGuide.install(self, $UI/TopBar, _show_help)
	_build_room()
	request_art = MeaningIllustration.new()
	request_art.position = Vector2(495, 48)
	request_art.size = Vector2(164, 125)
	$UI/RequestPanel.add_child(request_art)
	next_button = Button.new()
	next_button.position = Vector2(1050, 574)
	next_button.size = Vector2(188, 52)
	next_button.theme = preload("res://themes/kalin_theme.tres")
	next_button.theme_type_variation = &"KalinPrimaryButton"
	next_button.text = "Continuar →"
	next_button.pressed.connect(_advance_round)
	$UI.add_child(next_button)
	_restore_room()
	if round_index >= TOTAL_ROUNDS:
		_on_level_complete()
	else:
		_show_round()
		if bool(state.get("waiting", false)):
			_render_success(false)

func _build_room() -> void:
	room = Panel.new()
	room.position = Vector2(26, 80)
	room.size = Vector2(460, 470)
	room.clip_contents = true
	room.theme = preload("res://themes/kalin_theme.tres")
	room.theme_type_variation = &"KalinRequestPanel"
	$UI.add_child(room)
	var background := TextureRect.new()
	background.texture = preload("res://Arte/backgrounds/bg_casa_maya.svg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.position = Vector2(5, 5)
	background.size = room.size - Vector2(10, 10)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(background)
	var label := Label.new()
	label.text = "La casa de tus amigos"
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("fff6e1"))
	label.add_theme_color_override("font_outline_color", Color("4a3016"))
	label.add_theme_constant_override("outline_size", 4)
	room.add_child(label)

func _place_object(word: String, animate: bool) -> void:
	if word in room_items:
		if animate:
			(room_items[word] as MeaningIllustration).celebrate()
		return
	var positions := [Vector2(163, 275), Vector2(181, 244), Vector2(12, 345), Vector2(308, 299), Vector2(325, 228)]
	var index := 0
	for item: ExerciseEntry in OBJECTS:
		if item.maya == word:
			break
		index += 1
	var art := MeaningIllustration.new()
	art.position = positions[mini(index, positions.size() - 1)]
	art.size = Vector2(128, 100)
	room.add_child(art)
	art.show_meaning(word)
	room_items[word] = art
	if animate:
		art.celebrate()

func _restore_room() -> void:
	for index: int in range(mini(round_index, OBJECTS.size())):
		_place_object(OBJECTS[round_order[index]].maya, false)

func _current_object() -> ExerciseEntry:
	return OBJECTS[round_order[round_index % round_order.size()]]

func _show_round() -> void:
	guide.stop()
	_waiting = false
	_mistakes = 0
	next_button.hide()
	feedback_lbl.text = "Elige el hechizo para ayudar."
	feedback_lbl.add_theme_color_override("font_color", Color("5b4630"))
	var obj := _current_object()
	var vocab := GameManager.get_vocabulary_entry(obj.maya)
	current_phase = 0 if round_index < OBJECTS.size() else 1
	animal_spr.texture = load(obj.animal_spr)
	need_lbl.text = obj.peticion if current_phase == 0 else "¿Qué palabra crea este objeto?"
	word_lbl.text = "%s · %s" % [obj.maya, vocab.spanish] if current_phase == 0 else ""
	word_lbl.add_theme_color_override("font_color", Color("704c9f"))
	request_art.show_meaning(obj.maya)
	phase_lbl.text = "%s · %d / %d" % ["Aprende" if current_phase == 0 else "Recuerda", round_index % OBJECTS.size() + 1, OBJECTS.size()]
	progress_lbl.text = "%d / %d muebles recuperados" % [mini(round_index, OBJECTS.size()), OBJECTS.size()]
	_build_choices()
	if round_index == 0 and "objects" not in GameManager.tutorials_seen:
		call_deferred("_show_help")
	GameManager.checkpoint(self)

func _build_choices() -> void:
	for child: Node in choices_grid.get_children():
		choices_grid.remove_child(child)
		child.queue_free()
	_choice_buttons.clear()
	var pool: Array[ExerciseEntry] = OBJECTS.duplicate()
	pool.erase(_current_object())
	pool.shuffle()
	var count := mini(round_index + 2, OBJECTS.size()) if current_phase == 0 else OBJECTS.size()
	pool = pool.slice(0, count - 1)
	pool.append(_current_object())
	pool.shuffle()
	for obj: ExerciseEntry in pool:
		var button := Button.new()
		button.text = obj.maya
		button.custom_minimum_size = Vector2(216, 92)
		button.theme_type_variation = &"KalinNounButton"
		button.add_theme_font_size_override("font_size", 23)
		if current_phase == 0:
			button.icon = load(GameManager.get_book_illustration(obj.maya))
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 60)
		button.pressed.connect(_on_choice_pressed.bind(str(obj.maya)))
		choices_grid.add_child(button)
		_choice_buttons.append(button)
	_choice_buttons[0].grab_focus()

func _on_choice_pressed(word: String) -> void:
	if _completing or _waiting:
		return
	guide.stop()
	if word == _current_object().maya:
		GameManager.learn_word(word)
		GameManager.mark_tutorial_seen("objects")
		_render_success(true)
	else:
		_mistakes += 1
		var meaning := GameManager.get_vocabulary_entry(word)
		feedback_lbl.text = "%s significa %s. Busca el objeto de la imagen." % [word, meaning.spanish]
		feedback_lbl.add_theme_color_override("font_color", Color("b56a1f"))
		if _mistakes >= 2:
			_show_help()

func _render_success(animate: bool) -> void:
	_waiting = true
	guide.stop()
	for button: Button in _choice_buttons:
		button.disabled = true
	var obj := _current_object()
	var vocab := GameManager.get_vocabulary_entry(obj.maya)
	feedback_lbl.text = "✓ %s\n%s" % [vocab.estructura, vocab.traduccion]
	feedback_lbl.add_theme_color_override("font_color", Color("2e8b57"))
	_place_object(obj.maya, animate)
	progress_lbl.text = "%d / %d muebles recuperados" % [room_items.size(), OBJECTS.size()]
	next_button.show()
	next_button.grab_focus()
	guide.watch_continue(next_button)
	if animate:
		guide.page_to_book(request_art.global_position, $UI/TopBar/BookBtn.get_global_rect().get_center())
	GameManager.checkpoint(self)

func _advance_round() -> void:
	if not _waiting:
		return
	round_index += 1
	if round_index >= TOTAL_ROUNDS:
		_on_level_complete()
	else:
		_show_round()

func _show_help() -> void:
	if _waiting:
		guide.point_at(next_button)
		return
	for button: Button in _choice_buttons:
		if button.text == _current_object().maya:
			guide.point_at(button)
			feedback_lbl.text = "Toca una palabra. El objeto aparecerá en la casa."
			return

func _on_level_complete() -> void:
	_completing = true
	guide.stop()
	next_button.hide()
	GameManager.complete_level(2, 1)
	completion.show_completion("¡La casa está lista!", "Recuperaste los muebles de tus amigos.", "Al taller →")
	GameManager.checkpoint(self)

func _on_magic_points_changed(value: int) -> void:
	magic_lbl.text = GameManager.recovered_pages_text()

func _on_menu_pressed() -> void:
	GameManager.go_to_scene("main_menu")

func _on_next_level_pressed() -> void:
	GameManager.go_to_scene("world2_story1")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))

func get_checkpoint_state() -> Dictionary:
	return {"order": round_order, "round": round_index, "waiting": _waiting}
