## MainMenu.gd — Menú principal con mapa de niveles y progreso
extends Node2D

@onready var magic_lbl: Label = $UI/TopBar/MagicLabel
@onready var book_btn: Button = $UI/Center/VBox/BookBtn
@onready var libro: CanvasLayer = $LibroHechizos
@onready var levels_grid: GridContainer = $UI/LevelsGrid

@onready var play_btn: Button = $UI/Center/VBox/PlayBtn

var level_buttons: Array[Button] = []
var selected_world: int = 1
var world_buttons: Array[Button] = []
@onready var reset_confirmation: ResetConfirmation = $UI/ResetConfirmation
@onready var kalin_marker: TextureRect = $UI/WorldMap/KalinLocation
@onready var next_stop: Label = $UI/NextStop


func _ready() -> void:
	selected_world = int(
		VocabularyCatalog.level_info(GameManager.next_unlocked_scene()).get("world", 1)
	)
	if GameManager.session.resume_scene_key.begins_with("world"):
		selected_world = clampi(
			GameManager.session.resume_scene_key.trim_prefix("world").get_slice("_", 0).to_int(),
			1,
			5
		)
	_setup_level_buttons()
	_build_world_map()
	reset_confirmation.confirmed.connect(GameManager.reset_save)
	_refresh_ui()
	play_btn.grab_focus()
	GameManager.magic_points_changed.connect(_on_progress_changed)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.progress_reset.connect(_on_progress_reset)
	$UI/ComfortButton.pressed.connect(PauseMenu.open_pause)
	$UI/VisitButton.pressed.connect(GameManager.visit_village)


func _setup_level_buttons() -> void:
	level_buttons.clear()
	for child: Node in levels_grid.get_children():
		if child is not Button:
			continue
		var button: Button = child as Button
		level_buttons.append(button)
		var index: int = level_buttons.size() - 1
		if index < GameContent.LEVEL_ORDER.size():
			button.pressed.connect(_on_level_pressed.bind(index))


func _refresh_ui() -> void:
	magic_lbl.text = (
		"%d / %d páginas recuperadas"
		% [GameManager.get_recovered_word_count(), VocabularyCatalog.learnable_keys().size()]
	)
	var word_count: int = GameManager.get_recovered_word_count()
	book_btn.text = "Libro de Hechizos  (%d palabras)" % word_count
	$UI/VisitButton.visible = GameManager.is_level_completed(4, 1)
	$UI/VisitHint.visible = $UI/VisitButton.visible
	$UI/Center/VBox/ResetBtn.visible = (
		GameManager.load_failed
		or not GameManager.session.words_learned.is_empty()
		or not GameManager.session.completed_levels.is_empty()
		or not GameManager.session.resume_scene_key.is_empty()
	)
	_refresh_level_buttons()

	# Texto del botón Jugar según progreso
	var next: String = GameManager.next_unlocked_scene()
	if not GameManager.session.resume_scene_key.is_empty():
		play_btn.text = "Continuar →"
	elif next == "main_menu":
		play_btn.text = "¡Completado! Jugar de nuevo"
	elif (
		GameManager.session.resume_scene_key.is_empty()
		and GameManager.session.completed_levels.is_empty()
	):
		play_btn.text = "Jugar →"
	else:
		play_btn.text = "Continuar →"
	_refresh_world_map()
	if is_instance_valid(next_stop):
		var info: Dictionary = VocabularyCatalog.level_info(next)
		next_stop.text = (
			"¡Aventura completa!"
			if info.is_empty()
			else "Siguiente: " + str(info.get("map_label", ""))
		)
		var visits: Dictionary = {
			"world2_explore1": "La casa cobra vida",
			"world3_explore1": "Una aldea a su medida",
			"world2_mission1": "Rincones para compartir",
			"world3_mission1": "Una fiesta a la medida",
			"world4_mission1": "Los encargos de la aldea",
			"village_practice": "Tu visita a la aldea"
		}
		if GameManager.session.resume_scene_key in visits:
			next_stop.text = "Continuar: " + visits[GameManager.session.resume_scene_key]


func _refresh_level_buttons() -> void:
	for index: int in range(level_buttons.size()):
		var button: Button = level_buttons[index]
		if index >= GameContent.LEVEL_ORDER.size():
			button.hide()
			continue

		var level_data: Dictionary = GameContent.LEVEL_ORDER[index]
		button.visible = int(level_data.world) == selected_world
		var completed: bool = GameManager.is_level_completed(level_data.world, level_data.level)
		var unlocked: bool = completed or index == 0
		if index > 0:
			var previous: Dictionary = GameContent.LEVEL_ORDER[index - 1]
			unlocked = unlocked or GameManager.is_level_completed(previous.world, previous.level)

		button.disabled = not unlocked
		button.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
		button.tooltip_text = _level_tooltip(level_data, completed, unlocked)
		var status: String = "✓" if completed else ("▶" if unlocked else "🔒")
		button.text = (
			"%s  %d · %s"
			% [status, int(level_data.level), level_data.get("map_label", level_data.name)]
		)


func _level_tooltip(level_data: Dictionary, completed: bool, unlocked: bool) -> String:
	var title: String = str(level_data.name) + "\n"
	if completed:
		return title + "Completado · Toca para repetir"
	if unlocked:
		return title + "Toca para continuar la aventura"
	return title + "Completa la parada anterior"


func _on_level_pressed(index: int) -> void:
	if index < 0 or index >= GameContent.LEVEL_ORDER.size():
		return
	var button: Button = level_buttons[index]
	if button.disabled:
		return
	var key: String = GameContent.LEVEL_ORDER[index].scene_key
	if GameManager.is_level_completed(
		GameContent.LEVEL_ORDER[index].world, GameContent.LEVEL_ORDER[index].level
	):
		GameManager.replay_scene(key)
	else:
		var info: Dictionary = GameContent.LEVEL_ORDER[index]
		var entry_scenes: Array[String] = [key, str(info.story_key)]
		if index == 0:
			entry_scenes.append_array(["intro", "world1_explore1", "world1_story1"])
		elif key == "world2_level1":
			entry_scenes.append("world1_cine2")
		elif key == "world3_level1":
			entry_scenes.append("world2_explore1")
		elif key == "world4_level1":
			entry_scenes.append("world3_explore1")
		if GameManager.session.resume_scene_key in entry_scenes:
			GameManager.continue_adventure()
		elif GameManager.has_scene_state(key):
			GameManager.go_to_scene(key)
		else:
			GameManager.go_to_scene("intro" if index == 0 else str(info.story_key))


func _on_play_pressed() -> void:
	GameManager.continue_adventure()


func _on_progress_changed(_new_total: int) -> void:
	_refresh_ui()


func _on_level_completed(_world: int, _level: int) -> void:
	_refresh_ui()


func _on_book_pressed() -> void:
	libro.show_book(book_btn)


func _on_reset_pressed() -> void:
	reset_confirmation.show_dialog()


func _on_quit_pressed() -> void:
	GameManager.quit_game()


func _on_progress_reset() -> void:
	selected_world = 1
	_refresh_ui()


func _build_world_map() -> void:
	for index: int in range(5):
		var button: Button = $UI/WorldMap.get_node("World%d" % (index + 1)) as Button
		button.pressed.connect(_select_world.bind(index + 1))
		world_buttons.append(button)
		button.set_meta("map_base_modulate", button.modulate)
	kalin_marker.set_meta("map_offset", kalin_marker.position - world_buttons[0].position)


func _select_world(world: int) -> void:
	selected_world = world
	_refresh_level_buttons()
	_refresh_world_map()


func _refresh_world_map() -> void:
	var location: int = int(
		VocabularyCatalog.level_info(GameManager.next_unlocked_scene()).get(
			"world", 5 if GameManager.all_levels_completed() else 1
		)
	)
	if GameManager.session.resume_scene_key.begins_with("world"):
		location = clampi(
			GameManager.session.resume_scene_key.trim_prefix("world").get_slice("_", 0).to_int(),
			1,
			5
		)
	if is_instance_valid(kalin_marker):
		kalin_marker.position = (
			world_buttons[location - 1].position + Vector2(kalin_marker.get_meta("map_offset"))
		)
	for index: int in range(world_buttons.size()):
		var unlocked: bool = index == 0
		for level: Dictionary in GameContent.LEVEL_ORDER:
			if int(level.world) == index + 1:
				var level_index: int = GameContent.LEVEL_ORDER.find(level)
				unlocked = (
					unlocked
					or level_index == 0
					or GameManager.is_level_completed(
						GameContent.LEVEL_ORDER[level_index - 1].world,
						GameContent.LEVEL_ORDER[level_index - 1].level
					)
				)
		world_buttons[index].disabled = not unlocked
		world_buttons[index].modulate = (
			Color(world_buttons[index].get_meta("map_base_modulate"))
			* (Color.WHITE if selected_world == index + 1 else Color(0.85, 0.85, 0.85))
		)


func apply_screen_layout(compact: bool) -> void:
	levels_grid.columns = 2 if compact else 4
	for button: Button in level_buttons:
		button.custom_minimum_size.y = 76 if compact else 56
