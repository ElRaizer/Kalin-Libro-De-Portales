## Mundo 4, nivel 1 — In k'a'at (Yo Quiero)
## Desafío de comprensión en dos fases. Primero ofrece apoyos en español y
## después presenta solamente pistas visuales para recuperar la frase maya.
extends Node2D

const UI_EFFECTS = preload("res://scripts/components/UIEffects.gd")
const PHRASE_BUILDER = preload("res://scripts/components/PhraseBuilderController.gd")
const EXERCISE_ENTRY = preload("res://scripts/data/ExerciseEntry.gd")

const RAW_FOODS: Array[Dictionary] = [
	{ "maya": "ja'", "spanish": "agua", "emoji": "💧" },
	{ "maya": "ja'as", "spanish": "plátano", "emoji": "🍌" },
	{ "maya": "pak'al", "spanish": "fruta", "emoji": "🍎" },
	{ "maya": "K'úum", "spanish": "calabaza", "emoji": "🎃" },
	{ "maya": "janal", "spanish": "comida", "emoji": "🍲" },
]
static var FOODS: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_FOODS)

const RAW_MODIFIERS: Array[Dictionary] = [
	{ "maya": "", "spanish": "sin cualidad", "symbol": "—" },
	{ "maya": "mejen", "spanish": "pequeño/a", "symbol": "◌" },
	{ "maya": "nojoch", "spanish": "grande", "symbol": "⬢" },
]
static var MODIFIERS: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_MODIFIERS)

## Peticiones del GDD. Las frases completas evitan construir morfología desde
## el código y facilitan una posterior revisión lingüística.
const RAW_CHALLENGES: Array[Dictionary] = [
	{ "animal": "Peek'", "animal_spanish": "Perro", "sprite": "res://Arte/sprites/animal_peek.svg", "food": "ja'", "modifier": "", "phrase": "In k'a'at ja'", "translation": "Quiero agua" },
	{ "animal": "Miis", "animal_spanish": "Gato", "sprite": "res://Arte/sprites/animal_miis.svg", "food": "ja'as", "modifier": "mejen", "phrase": "In k'a'at ja'as mejen", "translation": "Quiero un plátano pequeño" },
	{ "animal": "Kaax", "animal_spanish": "Gallina", "sprite": "res://Arte/sprites/animal_kaax.svg", "food": "pak'al", "modifier": "", "phrase": "In k'a'at pak'al", "translation": "Quiero fruta" },
	{ "animal": "Áak", "animal_spanish": "Tortuga", "sprite": "res://Arte/sprites/animal_aak.svg", "food": "K'úum", "modifier": "nojoch", "phrase": "In k'a'at K'úum nojoch", "translation": "Quiero una calabaza grande" },
	{ "animal": "K'éek'en", "animal_spanish": "Cerdo", "sprite": "res://Arte/sprites/animal_keek_en.svg", "food": "janal", "modifier": "", "phrase": "In k'a'at janal", "translation": "Quiero comida" },
	{ "animal": "Kéej", "animal_spanish": "Venado", "sprite": "res://Arte/sprites/animal_keej.svg", "food": "ja'as", "modifier": "", "phrase": "In k'a'at ja'as", "translation": "Quiero plátano" },
]
static var CHALLENGES: Array[ExerciseEntry] = EXERCISE_ENTRY.from_dictionaries(RAW_CHALLENGES)

const UNSET_MODIFIER := "__unset__"
const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var round_plan: Array[Dictionary] = []
var round_index: int = 0
var selected_food: String = ""
var selected_modifier: String = ""
var food_buttons: Dictionary = {}
var modifier_buttons: Dictionary = {}
var _resolving: bool = false
var _awaiting_continue := false
var _mistakes := 0
var guide: LearningGuide
var _serving: Control
var result_art: MeaningIllustration
var mission_progress: MissionProgress
var mission_break: MissionBreak
var _help_stage := 0
var _blocks_seen: Array[int] = []

@onready var header: Panel = $UI/LevelHeader
@onready var animal_sprite: TextureRect = $UI/RequestPanel/Content/AnimalSprite
@onready var phase_label: Label = $UI/RequestPanel/Content/PhaseLabel
@onready var animal_label: Label = $UI/RequestPanel/Content/AnimalLabel
@onready var request_label: Label = $UI/RequestPanel/Content/RequestLabel
@onready var visual_clue: MeaningIllustration = $UI/RequestPanel/Content/VisualClue
@onready var food_grid: GridContainer = $UI/ChoicesPanel/Content/FoodGrid
@onready var modifier_grid: GridContainer = $UI/ChoicesPanel/Content/ModifierGrid
@onready var food_slot: Label = $UI/SpellPanel/Content/Sentence/FoodSlot
@onready var modifier_slot: Label = $UI/SpellPanel/Content/Sentence/ModifierSlot
@onready var serve_button: Button = $UI/ChoicesPanel/Content/ServeButton
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var progress_label: Label = $UI/StatusPanel/Status/ProgressLabel
@onready var instruction_label: Label = $UI/StatusPanel/Status/InstructionLabel
@onready var completion: Control = $UI/CompletionOverlay
@onready var libro: CanvasLayer = $LibroHechizos

func _ready() -> void:
	_setup_drop_slots()
	header.menu_pressed.connect(_on_menu_pressed)
	header.book_pressed.connect(_on_book_pressed)
	completion.next_pressed.connect(_on_next_level_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	_build_round_plan()
	_build_choice_buttons()
	_configure_keyboard_navigation()
	guide = LearningGuide.install(self, $UI/LevelHeader/Bar, _show_help)
	mission_progress = ExercisePresentation.setup(self, true)
	_configure_keyboard_navigation()
	result_art = MeaningIllustration.new()
	result_art.position = Vector2(12, -6)
	result_art.size = Vector2(124, 76)
	$UI/FeedbackPanel.add_child(result_art)
	mission_break = MissionBreak.new()
	$UI.add_child(mission_break)
	mission_break.continued.connect(func():
		_refresh_step()
		guide.watch_action(food_slot)
	)
	var state := GameManager.get_scene_state(self)
	_blocks_seen = ExerciseProgress.restore_markers(state.get("blocks"), CHALLENGES.size() * 2)
	round_plan = ExerciseProgress.restore_plan(state.get("plan"), CHALLENGES.size(), round_plan)
	round_index = clampi(int(state.get("round", 0)), 0, round_plan.size())
	_show_round()
	if not _resolving:
		var food := str(state.get("food", ""))
		var modifier := str(state.get("modifier", ""))
		if food in food_buttons:
			_select_food(food)
		if state.has("modifier") and modifier in modifier_buttons:
			_select_modifier(modifier)
		if bool(state.get("waiting", false)) and food == _current_challenge().food and modifier == _current_challenge().modifier:
			_render_success(false)

func _build_round_plan() -> void:
	round_plan = PHRASE_BUILDER.build_two_phase_plan(CHALLENGES.size())

func _build_choice_buttons() -> void:
	food_buttons = PHRASE_BUILDER.collect_buttons(food_grid, _select_food)
	modifier_buttons = PHRASE_BUILDER.collect_buttons(modifier_grid, _select_modifier)

func _configure_keyboard_navigation() -> void:
	PHRASE_BUILDER.configure_navigation(food_grid, modifier_grid, serve_button)

func _setup_drop_slots() -> void:
	food_slot.connect("word_dropped", _select_food)
	modifier_slot.connect("word_dropped", _select_modifier)

func _current_challenge() -> ExerciseEntry:
	return CHALLENGES[int(round_plan[round_index].challenge)]

func _is_guided_phase() -> bool:
	return bool(round_plan[round_index].guided)

func _show_round() -> void:
	guide.stop()
	mission_break.hide()
	result_art.hide()
	feedback_label.offset_left = 12
	if is_instance_valid(_serving):
		_serving.queue_free()
	if round_index >= round_plan.size():
		_finish_level()
		return
	_resolving = false
	_awaiting_continue = false
	_mistakes = 0
	_help_stage = 0
	selected_food = ""
	selected_modifier = ""
	PHRASE_BUILDER.clear_mark(food_slot)
	PHRASE_BUILDER.clear_mark(modifier_slot)
	var challenge := _current_challenge()
	var guided := _is_guided_phase()
	phase_label.text = "Aprende" if guided else "Recuerda"
	animal_label.text = challenge.animal
	animal_sprite.texture = load(challenge.sprite)
	request_label.text = challenge.translation if guided else "¿Qué quiere?"
	request_label.visible = guided
	instruction_label.text = ""
	visual_clue.show_meaning(challenge.food, challenge.modifier)
	feedback_label.text = "Elige el alimento."
	feedback_label.add_theme_color_override("font_color", Color("5b4630"))
	food_slot.text = "alimento"
	_update_modifier_slot()
	_update_choice_labels(guided)
	_update_button_states()
	_set_choices_enabled(true)
	serve_button.text = "Servir ✦"
	_refresh_step()
	mission_progress.update_progress(round_index, round_plan.size(), "La comida · %d / 3 · %s" % [round_index % 3 + 1, "Con ayuda" if guided else ("Una pista" if round_index < CHALLENGES.size() + 3 else "A tu turno")])
	progress_label.text = "%s %d / %d" % ["Aprende" if guided else "Repasa", round_index % CHALLENGES.size() + 1, CHALLENGES.size()]
	if not food_buttons.is_empty():
		(food_buttons.values()[0] as Button).grab_focus()
	if round_index == 0 and "requests" not in GameManager.tutorials_seen:
		call_deferred("_show_help")
	else:
		guide.watch_action(food_slot)
	if round_index > 0 and round_index % 3 == 0 and round_index not in _blocks_seen:
		_blocks_seen.append(round_index)
		guide.stop()
		var recent: ExerciseEntry = CHALLENGES[int(round_plan[round_index - 1].challenge)]
		mission_break.show_block("¡Tus amigos recuperan sus fuerzas!", "hambre", recent.food, recent.modifier, recent.animal)
	GameManager.checkpoint(self)

func _refresh_step() -> void:
	var needs_size := not _current_challenge().modifier.is_empty() or not selected_modifier.is_empty()
	ExercisePresentation.focus_step(food_grid, modifier_grid, not selected_food.is_empty(), needs_size)
	$UI/ChoicesPanel/Content/ModifierHeading.visible = needs_size
	$UI/ChoicesPanel/Content/FoodHeading.text = "1 · Alimento" + ("  ✓" if not selected_food.is_empty() else "")
	$UI/ChoicesPanel/Content/ModifierHeading.text = "2 · Tamaño" + ("  ✓" if not selected_modifier.is_empty() else "")
	(modifier_buttons[""] as Button).visible = not selected_modifier.is_empty()
	for button: Button in food_buttons.values():
		button.custom_minimum_size.y = 94 if needs_size else 130
		button.add_theme_constant_override("icon_max_width", 56 if needs_size else 76)
		button.focus_neighbor_bottom = button.get_path_to(modifier_buttons["mejen"] if needs_size else serve_button)

func _update_choice_labels(guided: bool) -> void:
	var bridge := not guided and round_index < CHALLENGES.size() + 3
	for food: ExerciseEntry in FOODS:
		var button: Button = food_buttons[food.maya]
		button.text = "%s\n%s" % [food.maya, food.spanish] if bridge else food.maya
		button.icon = load(GameManager.get_book_illustration(food.maya)) if guided else null
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 56)
	for modifier: ExerciseEntry in MODIFIERS:
		var button: Button = modifier_buttons[modifier.maya]
		button.text = "Quitar tamaño ↻" if modifier.maya == "" else ("%s\n%s" % [modifier.maya, modifier.spanish] if bridge else modifier.maya)
		button.icon = load(GameManager.get_book_illustration(modifier.maya)) if guided and modifier.maya != "" else null
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 56)

func _update_modifier_slot() -> void:
	modifier_slot.text = selected_modifier
	modifier_slot.visible = not selected_modifier.is_empty() or not _current_challenge().modifier.is_empty()

func _select_food(value: String) -> void:
	if _resolving:
		return
	guide.stop()
	selected_food = value
	_refresh_step()
	food_slot.text = value
	_update_button_states()
	_celebrate_selection(food_slot)

func _select_modifier(value: String) -> void:
	if _resolving:
		return
	guide.stop()
	selected_modifier = value
	_refresh_step()
	_update_modifier_slot()
	_update_button_states()
	_celebrate_selection(modifier_slot)

func _celebrate_selection(slot: Control) -> void:
	if not selected_food.is_empty():
		result_art.show()
		result_art.show_meaning(selected_food, selected_modifier)
		feedback_label.offset_left = 145
	PHRASE_BUILDER.clear_mark(slot)
	var message := "Elige el alimento." if selected_food.is_empty() else ("Elige el tamaño." if not _current_challenge().modifier.is_empty() and selected_modifier.is_empty() else "¡Sirve la petición!")
	PHRASE_BUILDER.celebrate(slot, feedback_label, message, Color("5b4630"))
	GameManager.checkpoint(self)
	if round_index == 0 and "requests" not in GameManager.tutorials_seen:
		_show_help()
	else:
		var target: Control = food_slot if selected_food.is_empty() else (modifier_slot if not _current_challenge().modifier.is_empty() and selected_modifier.is_empty() else serve_button)
		guide.watch_action(target)

func _update_button_states() -> void:
	PHRASE_BUILDER.set_button_states(food_buttons, selected_food, modifier_buttons, selected_modifier)
	serve_button.disabled = selected_food == "" or (not _current_challenge().modifier.is_empty() and selected_modifier.is_empty()) or _resolving

func _set_choices_enabled(enabled: bool) -> void:
	PHRASE_BUILDER.set_enabled(food_buttons, modifier_buttons, enabled)
	serve_button.disabled = not enabled or selected_food == "" or (not _current_challenge().modifier.is_empty() and selected_modifier.is_empty())

func _on_serve_pressed() -> void:
	if _awaiting_continue:
		round_index += 1
		_show_round()
		return
	if _resolving:
		return
	var challenge := _current_challenge()
	if selected_food != challenge.food or selected_modifier != challenge.modifier:
		_show_incorrect_feedback(challenge)
		return
	GameManager.learn_word(challenge.food)
	if challenge.modifier != "":
		GameManager.learn_word(challenge.modifier)
	GameManager.mark_tutorial_seen("requests")
	_render_success(true)

func _show_incorrect_feedback(challenge: ExerciseEntry) -> void:
	_mistakes += 1
	guide.stop()
	result_art.show()
	result_art.show_meaning(selected_food, selected_modifier)
	feedback_label.offset_left = 145
	CharacterReaction.play(animal_sprite, false)
	var food_ok := selected_food == str(challenge.food)
	var modifier_ok := selected_modifier == str(challenge.modifier)
	PHRASE_BUILDER.mark_slot(food_slot, food_ok)
	PHRASE_BUILDER.mark_slot(modifier_slot, modifier_ok)
	if not food_ok:
		feedback_label.text = "Mira la imagen. Cambia el alimento."
	elif challenge.modifier == "":
		feedback_label.text = "Alimento: ✓. No pidió tamaño: elige Sin tamaño."
	else:
		feedback_label.text = "Alimento: ✓. Elige el tamaño de la imagen."
	feedback_label.add_theme_color_override("font_color", COLOR_ERROR)
	if _mistakes >= 2:
		_help_stage = mini(_mistakes - 2, 2)
		_show_help()

func _shake_choices() -> void:
	UI_EFFECTS.shake(self, $UI/ChoicesPanel)

func _finish_level() -> void:
	_resolving = true
	_awaiting_continue = false
	guide.stop()
	GameManager.complete_level(4, 1)
	completion.show_completion("¡Todos han comido!", "Entendiste las peticiones de tus amigos.", "Al portal →")
	GameManager.checkpoint(self)

func _food_data(value: String) -> ExerciseEntry:
	for food: ExerciseEntry in FOODS:
		if food.maya == value:
			return food
	return null

func _modifier_data(value: String) -> ExerciseEntry:
	for modifier: ExerciseEntry in MODIFIERS:
		if modifier.maya == value:
			return modifier
	return MODIFIERS[0]

func _on_menu_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("main_menu")

func _on_next_level_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("world4_story1")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))

func _render_success(animate: bool) -> void:
	_resolving = true
	_awaiting_continue = true
	mission_progress.update_progress(round_index + 1, round_plan.size(), "La comida · %d / 3 · ¡Entregado!" % [round_index % 3 + 1])
	guide.stop()
	_set_choices_enabled(false)
	var challenge := _current_challenge()
	food_slot.text = challenge.food
	_update_modifier_slot()
	PHRASE_BUILDER.mark_slot(food_slot, true)
	if challenge.modifier != "":
		PHRASE_BUILDER.mark_slot(modifier_slot, true)
	feedback_label.text = "✓ %s\n%s" % [challenge.phrase, challenge.translation]
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	serve_button.text = "Continuar →"
	serve_button.disabled = false
	serve_button.grab_focus()
	guide.watch_continue(serve_button)
	result_art.hide()
	feedback_label.offset_left = 12
	if animate:
		CharacterReaction.play(animal_sprite)
		_deliver_food(challenge)
		guide.page_to_book(visual_clue.global_position, $UI/LevelHeader/Bar/BookButton.get_global_rect().get_center())
	GameManager.checkpoint(self)

func _deliver_food(challenge: ExerciseEntry) -> void:
	var serving := MeaningIllustration.new()
	serving.size = Vector2(140, 110)
	serving.position = food_slot.get_global_rect().get_center() - serving.size * 0.5
	$UI.add_child(serving)
	_serving = serving
	serving.show_meaning(challenge.food, challenge.modifier)
	var tween := serving.create_tween()
	tween.tween_property(serving, "position", animal_sprite.get_global_rect().get_center() + Vector2(20, 15), 0.75).set_trans(Tween.TRANS_SINE)
	tween.tween_property(serving, "scale", Vector2(0.25, 0.25), 0.35)
	tween.parallel().tween_property(serving, "modulate:a", 0.0, 0.35)
	tween.tween_callback(serving.queue_free)
	visual_clue.celebrate()

func _show_help() -> void:
	if mission_break.visible:
		guide.point_at(mission_break.continue_button)
		return
	if _awaiting_continue:
		guide.point_at(serve_button)
		return
	if _resolving:
		return
	var challenge := _current_challenge()
	var needs_food := selected_food != challenge.food
	if not selected_food.is_empty() and selected_modifier == challenge.modifier and _mistakes == 0:
		guide.point_at(serve_button)
		return
	var grid: Control = food_grid if needs_food else modifier_grid
	var slot: Control = food_slot if needs_food else modifier_slot
	if round_index == 0 and "requests" not in GameManager.tutorials_seen or _help_stage >= 2:
		var button: Control = food_buttons[challenge.food] if needs_food else modifier_buttons[challenge.modifier]
		guide.demonstrate([button.get_global_rect().get_center(), slot.get_global_rect().get_center()])
	elif _help_stage == 0:
		guide.highlight(slot)
	else:
		guide.highlight(grid)
	_help_stage += 1
	feedback_label.text = "Elige el alimento." if needs_food else "Elige el tamaño."

func get_checkpoint_state() -> Dictionary:
	return {"plan": round_plan, "round": round_index, "food": selected_food, "modifier": selected_modifier, "waiting": _awaiting_continue, "blocks": _blocks_seen}
