## MainMenu.gd — Menú principal con mapa de niveles y progreso
extends Node2D

@onready var bg:         TextureRect  = $Background
@onready var magic_lbl:  Label        = $UI/TopBar/MagicLabel
@onready var book_btn:   Button       = $UI/Center/VBox/BookBtn
@onready var libro:      CanvasLayer  = $LibroHechizos

# Botones de nivel (se buscan por nombre en la escena)
@onready var play_btn:   Button = $UI/Center/VBox/PlayBtn

func _ready() -> void:
	var bg_tex := load("res://Arte/backgrounds/bg_menu.svg") as Texture2D
	if bg_tex: bg.texture = bg_tex
	_refresh_ui()
	GameManager.magic_points_changed.connect(func(_v): _refresh_ui())
	GameManager.level_completed.connect(func(_w,_l): _refresh_ui())

func _refresh_ui() -> void:
	magic_lbl.text = "%d puntos magicos" % GameManager.magic_points
	var word_count := GameManager.words_learned.size()
	book_btn.text  = "Libro de Hechizos  (%d palabras)" % word_count
	# Texto del botón Jugar según progreso
	var next := GameManager.next_unlocked_scene()
	if next == "main_menu":
		play_btn.text = "Completado! Jugar de nuevo"
	elif GameManager.completed_levels.is_empty():
		play_btn.text = "Jugar - Nivel 1"
	else:
		var nums := {"world1_level1":1,"world1_level2":2,"world1_level3":3,"world1_level4":4,"world1_level5":5,"world1_level6":6,"world1_level7":7}
		play_btn.text = "Continuar - Nivel %d" % nums.get(next, 1)

func _on_play_pressed() -> void:
	GameManager.go_to_scene(GameManager.next_unlocked_scene())

func _on_book_pressed()  -> void: libro.show_book()
func _on_reset_pressed() -> void:
	GameManager.reset_save()
	_refresh_ui()
func _on_quit_pressed()  -> void: get_tree().quit()
