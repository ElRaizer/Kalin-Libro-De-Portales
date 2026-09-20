## Mundo 4, nivel 1 — In k'a'at (Yo Quiero)
## Desafío de comprensión en dos fases. Primero ofrece apoyos en español y
## después presenta solamente pistas visuales para recuperar la frase maya.
extends Node2D

const FOODS: Array[Dictionary] = [
	{ "maya": "ja'", "spanish": "agua", "emoji": "💧" },
	{ "maya": "ja'as", "spanish": "plátano", "emoji": "🍌" },
	{ "maya": "pak'al", "spanish": "fruta", "emoji": "🍎" },
	{ "maya": "K'úum", "spanish": "calabaza", "emoji": "🎃" },
	{ "maya": "janal", "spanish": "comida", "emoji": "🍲" },
]

const MODIFIERS: Array[Dictionary] = [
	{ "maya": "", "spanish": "sin cualidad", "symbol": "—" },
	{ "maya": "mejen", "spanish": "pequeño/a", "symbol": "◌" },
	{ "maya": "nojoch", "spanish": "grande", "symbol": "⬢" },
]

## Peticiones del GDD. Las frases completas evitan construir morfología desde
## el código y facilitan una posterior revisión lingüística.
const CHALLENGES: Array[Dictionary] = [
	{ "animal": "Peek'", "animal_spanish": "Perro", "sprite": "res://Arte/sprites/animal_peek.svg", "food": "ja'", "modifier": "", "phrase": "In k'a'at ja'", "translation": "Quiero agua" },
	{ "animal": "Miis", "animal_spanish": "Gato", "sprite": "res://Arte/sprites/animal_miis.svg", "food": "ja'as", "modifier": "mejen", "phrase": "In k'a'at ja'as mejen", "translation": "Quiero un plátano pequeño" },
	{ "animal": "Kaax", "animal_spanish": "Gallina", "sprite": "res://Arte/sprites/animal_kaax.svg", "food": "pak'al", "modifier": "", "phrase": "In k'a'at pak'al", "translation": "Quiero fruta" },
	{ "animal": "Áak", "animal_spanish": "Tortuga", "sprite": "res://Arte/sprites/animal_aak.svg", "food": "K'úum", "modifier": "nojoch", "phrase": "In k'a'at K'úum nojoch", "translation": "Quiero una calabaza grande" },
	{ "animal": "K'éek'en", "animal_spanish": "Cerdo", "sprite": "res://Arte/sprites/animal_keek_en.svg", "food": "janal", "modifier": "", "phrase": "In k'a'at janal", "translation": "Quiero comida" },
	{ "animal": "Kéej", "animal_spanish": "Venado", "sprite": "res://Arte/sprites/animal_keej.svg", "food": "ja'as", "modifier": "", "phrase": "In k'a'at ja'as", "translation": "Quiero plátano" },
]

const UNSET_MODIFIER := "__unset__"
const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var round_plan: Array[Dictionary] = []
var round_index: int = 0
var selected_food: String = ""
var selected_modifier: String = UNSET_MODIFIER
var food_buttons: Dictionary = {}
var modifier_buttons: Dictionary = {}
var _resolving: bool = false

@onready var header: Panel = $UI/LevelHeader
@onready var animal_sprite: TextureRect = $UI/RequestPanel/Content/AnimalSprite
@onready var phase_label: Label = $UI/RequestPanel/Content/PhaseLabel
@onready var animal_label: Label = $UI/RequestPanel/Content/AnimalLabel
@onready var request_label: Label = $UI/RequestPanel/Content/RequestLabel
@onready var visual_clue: Label = $UI/RequestPanel/Content/VisualClue
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
	header.menu_pressed.connect(_on_menu_pressed)
	header.book_pressed.connect(_on_book_pressed)
	completion.next_pressed.connect(_on_next_level_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	_build_round_plan()
	_build_choice_buttons()
	_show_round()

func _build_round_plan() -> void:
	var guided: Array[int] = []
	var recall: Array[int] = []
	for index: int in range(CHALLENGES.size()):
		guided.append(index)
		recall.append(index)
	guided.shuffle()
	recall.shuffle()
	for index: int in guided:
		round_plan.append({"challenge": index, "guided": true})
	for index: int in recall:
		round_plan.append({"challenge": index, "guided": false})

func _build_choice_buttons() -> void:
	for food: Dictionary in FOODS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 58)
		button.toggle_mode = true
		button.theme_type_variation = &"KalinNounButton"
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_select_food.bind(str(food.maya)))
		food_grid.add_child(button)
		food_buttons[food.maya] = button
	for modifier: Dictionary in MODIFIERS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(165, 52)
		button.toggle_mode = true
		button.theme_type_variation = &"KalinAdjectiveButton"
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_select_modifier.bind(str(modifier.maya)))
		modifier_grid.add_child(button)
		modifier_buttons[modifier.maya] = button

func _current_challenge() -> Dictionary:
	return CHALLENGES[int(round_plan[round_index].challenge)]

func _is_guided_phase() -> bool:
	return bool(round_plan[round_index].guided)

func _show_round() -> void:
	if round_index >= round_plan.size():
		_finish_level()
		return
	_resolving = false
	selected_food = ""
	selected_modifier = UNSET_MODIFIER
	var challenge := _current_challenge()
	var guided := _is_guided_phase()
	phase_label.text = "FASE 1 · APRENDE" if guided else "FASE 2 · RECUERDA"
	animal_label.text = "%s · %s" % [challenge.animal, challenge.animal_spanish]
	animal_sprite.texture = load(challenge.sprite)
	var food := _food_data(challenge.food)
	var modifier := _modifier_data(challenge.modifier)
	if guided:
		request_label.text = "%s pide: %s" % [challenge.animal_spanish, challenge.translation]
		instruction_label.text = "Construye la petición con apoyo en español."
	else:
		request_label.text = "Observa la pista y recuerda la petición en maya."
		instruction_label.text = "Sin traducción: elige alimento y cualidad de memoria."
	visual_clue.text = "%s  %s" % [food.emoji, modifier.symbol]
	feedback_label.text = "Selecciona un alimento y una cualidad para formar la petición."
	feedback_label.add_theme_color_override("font_color", Color("5b4630"))
	food_slot.text = "alimento"
	modifier_slot.text = "cualidad"
	_update_choice_labels(guided)
	_update_button_states()
	_set_choices_enabled(true)
	progress_label.text = "Ronda %d de %d" % [round_index + 1, round_plan.size()]

func _update_choice_labels(guided: bool) -> void:
	for food: Dictionary in FOODS:
		var button: Button = food_buttons[food.maya]
		button.text = "%s  %s\n%s" % [food.emoji, food.maya, food.spanish] if guided else "%s  %s" % [food.emoji, food.maya]
	for modifier: Dictionary in MODIFIERS:
		var button: Button = modifier_buttons[modifier.maya]
		button.text = "%s  %s\n%s" % [modifier.symbol, _modifier_display(modifier.maya), modifier.spanish] if guided else "%s  %s" % [modifier.symbol, _modifier_display(modifier.maya)]

func _modifier_display(value: String) -> String:
	return "" if value == "" else value

func _select_food(value: String) -> void:
	if _resolving:
		return
	selected_food = value
	food_slot.text = value
	_update_button_states()

func _select_modifier(value: String) -> void:
	if _resolving:
		return
	selected_modifier = value
	modifier_slot.text = _modifier_display(value)
	_update_button_states()

func _update_button_states() -> void:
	for value: String in food_buttons:
		(food_buttons[value] as Button).button_pressed = value == selected_food
	for value: String in modifier_buttons:
		(modifier_buttons[value] as Button).button_pressed = value == selected_modifier
	serve_button.disabled = selected_food == "" or selected_modifier == UNSET_MODIFIER or _resolving

func _set_choices_enabled(enabled: bool) -> void:
	for button: Button in food_buttons.values():
		button.disabled = not enabled
	for button: Button in modifier_buttons.values():
		button.disabled = not enabled
	serve_button.disabled = not enabled or selected_food == "" or selected_modifier == UNSET_MODIFIER

func _on_serve_pressed() -> void:
	if _resolving:
		return
	var challenge := _current_challenge()
	if selected_food != challenge.food or selected_modifier != challenge.modifier:
		_show_incorrect_feedback(challenge)
		return
	_resolving = true
	_set_choices_enabled(false)
	GameManager.learn_word(challenge.food)
	if challenge.modifier != "":
		GameManager.learn_word(challenge.modifier)
	food_slot.text = challenge.food
	modifier_slot.text = _modifier_display(challenge.modifier)
	feedback_label.text = "¡Petición entendida!  %s  ·  %s" % [challenge.phrase, challenge.translation]
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	var tween := create_tween()
	tween.tween_property(animal_sprite, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(animal_sprite, "scale", Vector2.ONE, 0.18)
	await get_tree().create_timer(1.15).timeout
	if not is_inside_tree():
		return
	round_index += 1
	_show_round()

func _show_incorrect_feedback(challenge: Dictionary) -> void:
	var food_ok := selected_food == str(challenge.food)
	var modifier_ok := selected_modifier == str(challenge.modifier)
	if not food_ok and not modifier_ok:
		feedback_label.text = "Revisa las dos pistas: alimento y cualidad no coinciden."
	elif not food_ok:
		feedback_label.text = "La cualidad está bien, pero el alimento es otro."
	else:
		feedback_label.text = "El alimento es correcto; revisa su tamaño o elige sin cualidad."
	feedback_label.add_theme_color_override("font_color", COLOR_ERROR)

func _finish_level() -> void:
	_resolving = true
	GameManager.complete_level(4, 1)
	completion.show_completion(
		"¡Mundo 4 completado!",
		"Comprendiste seis peticiones con y sin apoyo visual.\nEl portal ya reconoce la estructura In k'a'at.",
		"Ir al Portal de Regreso"
	)

func _food_data(value: String) -> Dictionary:
	for food: Dictionary in FOODS:
		if food.maya == value:
			return food
	return {}

func _modifier_data(value: String) -> Dictionary:
	for modifier: Dictionary in MODIFIERS:
		if modifier.maya == value:
			return modifier
	return MODIFIERS[0]

func _on_menu_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("main_menu")

func _on_next_level_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("world5_level1")

func _on_book_pressed() -> void:
	libro.show_book()

func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
