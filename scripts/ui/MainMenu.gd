## MainMenu.gd — Menú principal con mapa de niveles y progreso
extends Node2D

@onready var magic_lbl:  Label        = $UI/TopBar/MagicLabel
@onready var book_btn:   Button       = $UI/Center/VBox/BookBtn
@onready var libro:      CanvasLayer  = $LibroHechizos

# Botones de nivel (se buscan por nombre en la escena)
@onready var play_btn:   Button = $UI/Center/VBox/PlayBtn

func _ready() -> void:
	_refresh_ui()
	GameManager.magic_points_changed.connect(_on_progress_changed)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.progress_reset.connect(_refresh_ui)

func _refresh_ui() -> void:
	magic_lbl.text = "%d puntos mágicos" % GameManager.magic_points
	var word_count: int = GameManager.words_learned.size()
	book_btn.text  = "Libro de Hechizos  (%d palabras)" % word_count
	# Texto del botón Jugar según progreso
	var next: String = GameManager.next_unlocked_scene()
	if next == "main_menu":
		play_btn.text = "¡Completado! Jugar de nuevo"
	elif GameManager.completed_levels.is_empty():
		play_btn.text = "Jugar — Mundo 1, Nivel 1"
	else:
		var info: Dictionary = GameManager.get_level_info(next)
		play_btn.text = "Continuar — Mundo %d, Nivel %d" % [info.get("world", 1), info.get("level", 1)]

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
