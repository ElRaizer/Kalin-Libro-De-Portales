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
	words: Array,
	phase: String,
	context: String,
	supported: bool = false,
	mistakes: int = 0,
	evidence: Dictionary = {},
	award_points: bool = true
) -> void:
	var result: Dictionary = session.record_learning(
		words, phase, context, supported, mistakes, evidence, award_points
	)
	if not result.changed:
		return
	magic_points_changed.emit(session.magic_points)
	if not result.learned.is_empty():
		for word: String in result.learned:
			word_learned.emit(VocabularyCatalog.entry(word))
	learning_changed.emit()
	_save()


func prepare_sharing_corner() -> bool:
	if not session.prepare_sharing_corner():
		return false
	magic_points_changed.emit(session.magic_points)
	_save()
	return true


func purchase_design(word: String) -> bool:
	var before: Dictionary = session.snapshot()
	if not session.purchase_design(word):
		return false
	if not _save():
		session.restore(before)
		return false
	magic_points_changed.emit(session.magic_points)
	return true


func purchase_combination_designs(id: String) -> bool:
	var before: Dictionary = session.snapshot()
	if not session.purchase_combination_designs(id):
		return false
	if not _save():
		session.restore(before)
		return false
	magic_points_changed.emit(session.magic_points)
	return true


func set_laboratory_favorite(id: String, enabled: bool, limit: int) -> bool:
	var before: Array[String] = session.laboratory_favorites.duplicate()
	if not session.set_laboratory_favorite(id, enabled, limit):
		return false
	if not _save():
		session.laboratory_favorites = before
		return false
	return true


func set_garden_identity(district: String, title: String, decorations: Array[String]) -> bool:
	var before: Dictionary = session.garden_identity.duplicate(true)
	if not session.set_garden_identity(district, title, decorations):
		return false
	if not _save():
		session.garden_identity = before
		return false
	return true


func select_snack(guests: Array[String], food: String, decoration: String) -> bool:
	return _commit_snack_change(session.select_snack.bind(guests, food, decoration))


func begin_snack_preparation() -> bool:
	return _commit_snack_change(session.begin_snack_preparation)


func update_snack_preparation(state: Dictionary) -> bool:
	return _commit_snack_change(session.update_snack_preparation.bind(state))


func confirm_snack_project() -> bool:
	return _commit_snack_change(session.confirm_snack_project)


func confirm_village_guest(animal: String) -> bool:
	return _commit_village_experience(session.confirm_village_guest.bind(animal))


func confirm_clearing_reunion() -> bool:
	return _commit_village_experience(session.confirm_clearing_reunion)


func _commit_village_experience(action: Callable) -> bool:
	var before: Dictionary = session.village_experiences.duplicate(true)
	if not action.call():
		return false
	if not _save():
		session.village_experiences = before
		return false
	return true


func try_expansion(purpose: String) -> bool:
	return _commit_expansion_change(session.try_expansion.bind(purpose))


func select_expansion_guests(guests: Array[String]) -> bool:
	return _commit_expansion_change(session.select_expansion_guests.bind(guests))


func inaugurate_expansion() -> bool:
	return _commit_expansion_change(session.inaugurate_expansion)


func _commit_expansion_change(action: Callable) -> bool:
	var before: Dictionary = session.village_expansion.duplicate(true)
	if not action.call():
		return false
	if not _save():
		session.village_expansion = before
		return false
	return true


func _commit_snack_change(action: Callable) -> bool:
	var before: Dictionary = session.snack_project.duplicate(true)
	if not action.call():
		return false
	if not _save():
		session.snack_project = before
		return false
	return true


func save_personal_moment(moment: Dictionary, replacement: int = -1) -> bool:
	var candidate: Array[Dictionary] = session.album_with_moment(moment, replacement)
	return not candidate.is_empty() and _commit_personal_album(candidate)


func delete_personal_moment(index: int) -> bool:
	if index not in range(session.personal_moment_count()):
		return false
	return _commit_personal_album(session.album_without_moment(index))


func _commit_personal_album(candidate: Array[Dictionary]) -> bool:
	var data: Dictionary = session.snapshot()
	data.personal_album = candidate
	if not _write_progress(data):
		return false
	session.apply_personal_album(candidate)
	return true


func save_garden_composition(district: String, slot: int, capacity: int) -> bool:
	var before: Dictionary = session.garden_compositions.duplicate(true)
	if not session.save_garden_composition(district, slot, capacity):
		return false
	if not _save():
		session.garden_compositions = before
		return false
	return true


func apply_garden_composition(district: String, slot: int) -> String:
	var before: Dictionary = session.garden.duplicate(true)
	var error: String = session.apply_garden_composition(district, slot)
	if not error.is_empty():
		return error
	if not _save():
		session.garden = before
		return "No se pudo guardar el acomodo. Conservamos tu jardín anterior; puedes reintentar."
	return ""


func delete_garden_copy(id: int) -> String:
	var before: Dictionary = session.garden.duplicate(true)
	var error: String = session.delete_garden_copy(id)
	if not error.is_empty():
		return error
	if not _save():
		session.garden = before
		return "No se pudo guardar la eliminación. Conservamos la copia; puedes reintentar."
	return ""


func restore_garden_layout(candidate: Dictionary) -> bool:
	var before: Dictionary = session.garden.duplicate(true)
	if not session.replace_garden_layout(candidate):
		return false
	if not _save():
		session.garden = before
		return false
	return true


func learning_caption(word: String) -> String:
	return LearningProgress.caption(
		LearningProgress.sanitize(session.learning_progress.get(VocabularyCatalog.resolve(word)))
	)


func learning_detail(word: String) -> String:
	var record: Dictionary = LearningProgress.sanitize(
		session.learning_progress.get(VocabularyCatalog.resolve(word))
	)
	return LearningProgress.detail(record)


func mark_learning_support() -> void:
	var changed: bool = session.mark_pending_challenge_help()
	var scene: Node = get_tree().current_scene
	if is_instance_valid(scene) and scene.has_method("mark_learning_help"):
		scene.mark_learning_help()
	if changed:
		_save()


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


func go_to_scene(key: String) -> bool:
	return _navigation().go_to_scene(key)


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


func _save() -> bool:
	return _write_progress(session.snapshot())


func _write_progress(data: Dictionary) -> bool:
	# No sustituir una partida ilegible por datos vacíos al abrir el menú.
	if load_failed:
		return false
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
	return error == OK


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


func visit_home(return_key: String = "main_menu") -> void:
	_navigation().visit_home(return_key)


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
	if not _save():
		return
	_request_quit()


func _request_quit() -> void:
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
