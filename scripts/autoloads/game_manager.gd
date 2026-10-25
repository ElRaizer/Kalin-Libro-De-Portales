## Servicio de aplicación: coordina GameSession, SceneNavigator y SaveRepository.
## Las reglas y consultas pertenecen a sus módulos enfocados.
extends Node

signal word_learned(word_data: Dictionary)
signal magic_points_changed(new_total: int)
signal level_completed(world: int, level: int)
signal progress_reset
signal learning_changed
signal save_status_changed(message: String)
var save_status_message: String = ""
var load_failed: bool = false

var session: GameSession = GameSession.new()
@export var visual_catalog: VisualCatalog = preload("res://data/visual_catalog.tres")

var _save_repository: SaveRepository
var _scene_navigator: SceneNavigator


func _ready() -> void:
	_save_repository = SaveRepository.new()
	_load_save()
	_navigation()
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(quit_game)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _get_save_repository() -> SaveRepository:
	if not is_instance_valid(_save_repository):
		_save_repository = SaveRepository.new()
	return _save_repository


func learn_word(maya_word: String) -> void:
	var key: String = VocabularyCatalog.resolve(maya_word)
	if key.is_empty():
		push_warning("GameManager: palabra desconocida '%s'" % maya_word)
		return
	if session.learn_word(key):
		magic_points_changed.emit(session.magic_points)
		word_learned.emit(VocabularyCatalog.entry(key))
		_save()


func has_learned_word(maya_word: String) -> bool:
	var key: String = VocabularyCatalog.resolve(maya_word)
	return key != "" and key in session.words_learned


func record_learning(
	words: Array, phase: String, context: String, supported: bool = false, mistakes: int = 0
) -> void:
	var result: Dictionary = session.record_learning(words, phase, context, supported, mistakes)
	if not result.changed:
		return
	if not result.learned.is_empty():
		magic_points_changed.emit(session.magic_points)
		for word: String in result.learned:
			word_learned.emit(VocabularyCatalog.entry(word))
	learning_changed.emit()
	_save()


func learning_caption(word: String) -> String:
	return LearningProgress.caption(
		LearningProgress.sanitize(session.learning_progress.get(VocabularyCatalog.resolve(word)))
	)


func learning_detail(word: String) -> String:
	var record: Dictionary = LearningProgress.sanitize(
		session.learning_progress.get(VocabularyCatalog.resolve(word))
	)
	return (
		"Con fragmentos o bloques: %d · Escrituras sin ayuda: %d"
		% [record.reconstruction, record.writing]
	)


func mark_learning_support() -> void:
	var scene: Node = get_tree().current_scene
	if is_instance_valid(scene) and scene.has_method("mark_learning_help"):
		scene.mark_learning_help()


func recovered_pages_text() -> String:
	var count: int = get_recovered_word_count()
	return "%d %s" % [count, "página" if count == 1 else "páginas"]


func get_recovered_word_count() -> int:
	return session.recovered_word_count()


func get_book_illustration(maya_word: String) -> String:
	var texture: Texture2D = get_visual_texture(maya_word)
	return texture.resource_path if texture else ""


func get_visual_texture(maya_word: String) -> Texture2D:
	var key: String = VocabularyCatalog.resolve(maya_word)
	return visual_catalog.texture_for(key if not key.is_empty() else maya_word)


func get_visual_expression(maya_word: String, expression: String) -> Texture2D:
	return visual_catalog.expression_for(VocabularyCatalog.resolve(maya_word), expression)


func get_visual_key(texture: Texture2D) -> String:
	for entry: VisualEntry in visual_catalog.entries:
		if entry.texture == texture or texture in entry.expressions.values():
			return entry.key
	return ""


func complete_level(world: int, level: int) -> void:
	if session.complete_level(world, level):
		magic_points_changed.emit(session.magic_points)
	level_completed.emit(world, level)
	_save()


func is_level_completed(world: int, level: int) -> bool:
	return session.is_level_completed(world, level)


func next_unlocked_scene() -> String:
	return session.next_unlocked_scene()


func all_levels_completed() -> bool:
	return next_unlocked_scene() == "main_menu"


func go_to_scene(key: String) -> void:
	_navigation().go_to_scene(key)


func reset_save() -> void:
	var error: Error = _get_save_repository().delete_progress()
	if error != OK:
		_set_save_status("No se pudo reiniciar la partida. Puedes volver a intentarlo.")
		return
	session.reset()
	load_failed = false
	_set_save_status("")
	magic_points_changed.emit(0)
	progress_reset.emit()


func _save() -> void:
	# No sustituir una partida ilegible por datos vacíos al abrir el menú.
	if load_failed:
		return
	var data: Dictionary = session.snapshot()
	var error: Error = _get_save_repository().save_progress(data)
	_set_save_status(
		(
			"No se pudo guardar. Tu avance sigue en esta sesión. Pulsa Reintentar antes de salir."
			if error != OK
			else ""
		)
	)
	if error != OK:
		push_warning("GameManager: no se pudo guardar el progreso (error %d)" % error)


func _set_save_status(message: String) -> void:
	if save_status_message == message:
		return
	save_status_message = message
	save_status_changed.emit(message)


func retry_save() -> void:
	if load_failed:
		_load_save()
		return
	checkpoint_current_scene()
	_save()


func visit_village() -> void:
	_navigation().visit_village()


func start_walk(key: String, return_key: String) -> void:
	_navigation().start_walk(key, return_key)


func _load_save() -> void:
	var result: Dictionary = _get_save_repository().load_progress()
	if result.has("_load_error") or (not result.is_empty() and not session.restore(result)):
		load_failed = true
		_set_save_status(
			"No se pudo recuperar tu partida. Reintenta o pide ayuda antes de empezar de nuevo."
		)
		return
	load_failed = false
	_set_save_status("")
	magic_points_changed.emit(session.magic_points)


func scene_key_for(node: Node) -> String:
	return SceneNavigator.scene_key_for(node)


func checkpoint(node: Node) -> void:
	_navigation().checkpoint(node)


func schedule_checkpoint(node: Node) -> void:
	_navigation().schedule_checkpoint(node)


func checkpoint_current_scene() -> void:
	_navigation().checkpoint_current_scene()


func get_scene_state(node: Node) -> Dictionary:
	return _navigation().get_scene_state(node)


func continue_adventure() -> void:
	_navigation().continue_adventure()


func replay_scene(key: String) -> void:
	_navigation().replay_scene(key)


func mark_tutorial_seen(key: String) -> void:
	if key not in session.tutorials_seen:
		session.tutorials_seen.append(key)
		_save()


func quit_game() -> void:
	checkpoint_current_scene()
	_save()
	get_tree().quit()


func _navigation() -> SceneNavigator:
	if not is_instance_valid(_scene_navigator):
		_scene_navigator = SceneNavigator.new(session, _save)
		add_child(_scene_navigator)
	return _scene_navigator


## API de lectura para consumidores que no necesitan acceso al contenedor vivo.
func learned_words() -> Dictionary:
	return session.words_learned.duplicate(true)


func learning_record(word: String) -> Dictionary:
	return LearningProgress.sanitize(session.learning_progress.get(VocabularyCatalog.resolve(word)))


func saved_scene_state(key: String) -> Dictionary:
	var state: Variant = session.scene_states.get(key, {})
	return SceneStateSchema.sanitize(state) if state is Dictionary else {}


func has_scene_state(key: String) -> bool:
	return session.scene_states.has(key)


## Inyección explícita para herramientas y pruebas; conserva la sesión ante
## un fallo de restauración. No requiere manipular campos privados.
func use_save_repository(repository: SaveRepository) -> void:
	_save_repository = repository
	_load_save()
