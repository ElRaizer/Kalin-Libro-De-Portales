## MainMenu.gd — Menú principal con mapa de niveles y progreso
extends Node2D

@onready var magic_lbl:  Label        = $UI/TopBar/MagicLabel
@onready var book_btn:   Button       = $UI/Center/VBox/BookBtn
@onready var libro:      CanvasLayer  = $LibroHechizos
@onready var levels_grid: GridContainer = $UI/LevelsGrid

@onready var play_btn:   Button = $UI/Center/VBox/PlayBtn

var level_buttons: Array[Button] = []

func _ready() -> void:
	_setup_level_buttons()
	_refresh_ui()
	GameManager.magic_points_changed.connect(_on_progress_changed)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.progress_reset.connect(_refresh_ui)

func _setup_level_buttons() -> void:
	level_buttons.clear()
	for child: Node in levels_grid.get_children():
		if child is not Button:
			continue
		var button := child as Button
		level_buttons.append(button)
		var index: int = level_buttons.size() - 1
		if index < GameManager.LEVEL_ORDER.size():
			button.pressed.connect(_on_level_pressed.bind(index))

func _refresh_ui() -> void:
	magic_lbl.text = "%d puntos mágicos" % GameManager.magic_points
	var word_count: int = GameManager.words_learned.size()
	book_btn.text  = "Libro de Hechizos  (%d palabras)" % word_count
	_refresh_level_buttons()

	# Texto del botón Jugar según progreso
	var next: String = GameManager.next_unlocked_scene()
	if next == "main_menu":
		play_btn.text = "¡Completado! Jugar de nuevo"
	elif GameManager.completed_levels.is_empty():
		play_btn.text = "Comenzar aventura"
	else:
		var info: Dictionary = GameManager.get_level_info(next)
		play_btn.text = "Continuar — %s" % info.get("name", "Siguiente nivel")

func _refresh_level_buttons() -> void:
	for index: int in range(level_buttons.size()):
		var button: Button = level_buttons[index]
		if index >= GameManager.LEVEL_ORDER.size():
			button.hide()
			continue

		var level_data: Dictionary = GameManager.LEVEL_ORDER[index]
		var completed: bool = GameManager.is_level_completed(level_data.world, level_data.level)
		var unlocked: bool = completed or index == 0
		if index > 0:
			var previous: Dictionary = GameManager.LEVEL_ORDER[index - 1]
			unlocked = unlocked or GameManager.is_level_completed(previous.world, previous.level)

		button.disabled = not unlocked
		button.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
		button.tooltip_text = _level_tooltip(level_data, completed, unlocked)
		var status: String = "✓" if completed else ("▶" if unlocked else "🔒")
		button.text = "%s  %d. %s" % [status, index + 1, level_data.name]

func _level_tooltip(_level_data: Dictionary, completed: bool, unlocked: bool) -> String:
	if completed:
		return "Nivel completado · Haz clic para volver a jugar"
	if unlocked:
		return "Haz clic para jugar este nivel"
	return "Completa el nivel anterior para desbloquearlo"

func _on_level_pressed(index: int) -> void:
	if index < 0 or index >= GameManager.LEVEL_ORDER.size():
		return
	var button: Button = level_buttons[index]
	if button.disabled:
		return
	GameManager.go_to_scene(GameManager.LEVEL_ORDER[index].scene_key)

func _on_play_pressed() -> void:
	var next: String = GameManager.next_unlocked_scene()
	if next == "main_menu":
		next = GameManager.LEVEL_ORDER[0].scene_key
	GameManager.go_to_scene(next)

func _on_progress_changed(_new_total: int) -> void:
	_refresh_ui()

func _on_level_completed(_world: int, _level: int) -> void:
	_refresh_ui()

func _on_book_pressed() -> void:
	libro.show_book()

func _on_reset_pressed() -> void:
	GameManager.reset_save()

func _on_quit_pressed() -> void:
	get_tree().quit()
