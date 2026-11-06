extends Node
class_name SceneNavigator

## Coordina transiciones y capturas. Sólo guarda snapshots separados de la
## escena; la sesión posee los datos y el repositorio recibe la escritura.
const SCENE_PATHS = GameContent.SCENE_PATHS
const LEVEL_ORDER = GameContent.LEVEL_ORDER
var _session: GameSession
var _save: Callable
var _checkpoint_timer: Timer
var _pending_checkpoint: WeakRef


func _init(session: GameSession, save_action: Callable) -> void:
	_session = session
	_save = save_action


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_checkpoint_timer = Timer.new()
	_checkpoint_timer.one_shot = true
	_checkpoint_timer.wait_time = 0.35
	_checkpoint_timer.timeout.connect(_flush_checkpoint)
	add_child(_checkpoint_timer)


func go_to_scene(key: String) -> bool:
	if key not in SCENE_PATHS:
		push_error("GameManager: clave de escena desconocida '%s'" % key)
		return false
	checkpoint_current_scene()
	var source_key: String = scene_key_for(get_tree().current_scene)
	var replay_run: String = _replay_run(source_key)
	var leaving_practice: bool = (
		get_tree().current_scene != null
		and get_tree().current_scene.scene_file_path == SCENE_PATHS.village_home
		and key == "main_menu"
	)
	var next_resume: String = _session.resume_scene_key
	if key != "main_menu":
		next_resume = key
	elif leaving_practice:
		next_resume = _session.practice_return_key
	elif (
		get_tree().current_scene != null
		and get_tree().current_scene.scene_file_path == SCENE_PATHS.world5_cine1
	):
		next_resume = ""
	var error: Error = _request_scene(SCENE_PATHS[key])
	if error != OK:
		push_error("GameManager: no se pudo abrir '%s' (error %d)" % [SCENE_PATHS[key], error])
		return false
	_session.resume_scene_key = next_resume
	if key not in ["main_menu", "village_home", source_key] and not replay_run.is_empty():
		var destination: Dictionary = _session.scene_states.get(key, {})
		if destination.get("replay_run", "") != replay_run:
			destination = ReplayVariation.replay_state(destination)
			destination.replay_run = replay_run
			_session.scene_states[key] = destination
	_save.call()
	return true


func _request_scene(path: String) -> Error:
	return get_tree().change_scene_to_file(path)


func start_walk(key: String, return_key: String) -> void:
	if key not in SCENE_PATHS or return_key not in SCENE_PATHS:
		return
	# El checkpoint de salida debe ocurrir antes de renovar un paseo completado.
	if not go_to_scene(key):
		return
	var saved: Dictionary = _session.scene_states.get(key, {}).duplicate(true)
	var solved: Variant = saved.get("solved", [])
	if solved is Array and solved.size() >= 3:
		saved = ReplayVariation.replay_state(saved)
	saved["return_scene"] = return_key
	_session.scene_states[key] = saved
	_save.call()


func visit_home(return_key: String = "main_menu") -> void:
	if return_key not in SCENE_PATHS:
		return
	var previous: String = _session.resume_scene_key
	if not go_to_scene("village_home"):
		return
	var saved: Dictionary = _session.scene_states.get("village_home", {}).duplicate(true)
	saved.return_scene = return_key
	_session.scene_states.village_home = saved
	if previous != "village_home":
		_session.practice_return_key = previous
	_save.call()


static func scene_key_for(node: Node) -> String:
	if not is_instance_valid(node):
		return ""
	return (
		str(SCENE_PATHS.find_key(node.scene_file_path))
		if node.scene_file_path in SCENE_PATHS.values()
		else ""
	)


func checkpoint(node: Node) -> void:
	if is_instance_valid(_checkpoint_timer):
		_checkpoint_timer.stop()
	_pending_checkpoint = null
	var key: String = scene_key_for(node)
	if key.is_empty() or not node.has_method("get_checkpoint_state"):
		return
	var replay_run: String = _replay_run(key)
	var snapshot: Dictionary = node.get_checkpoint_state().duplicate(true)
	var prior: Dictionary = _session.scene_states.get(key, {})
	if prior.get("previous_variation") is Dictionary:
		snapshot.previous_variation = prior.previous_variation.duplicate(true)
	if not replay_run.is_empty():
		snapshot.replay_run = replay_run
	_session.scene_states[key] = snapshot
	if node == get_tree().current_scene and key != "main_menu":
		_session.resume_scene_key = key
	_save.call()


func _replay_run(key: String) -> String:
	var state: Dictionary = _session.scene_states.get(key, {})
	var value: Variant = state.get("replay_run", "")
	return value if value is String else ""


## La escritura guarda al dejar de teclear; navegar y salir siguen guardando de inmediato.


func schedule_checkpoint(node: Node) -> void:
	if not is_instance_valid(node) or node != get_tree().current_scene:
		return
	_pending_checkpoint = weakref(node)
	_checkpoint_timer.start()


func _flush_checkpoint() -> void:
	var node: Node = _pending_checkpoint.get_ref() if _pending_checkpoint != null else null
	if is_instance_valid(node) and node == get_tree().current_scene:
		checkpoint(node)


func checkpoint_current_scene() -> void:
	if is_instance_valid(get_tree().current_scene):
		checkpoint(get_tree().current_scene)


func get_scene_state(node: Node) -> Dictionary:
	var state: Variant = _session.scene_states.get(scene_key_for(node), {})
	return SceneStateSchema.sanitize(state) if state is Dictionary else {}


func continue_adventure() -> void:
	if not _session.resume_scene_key.is_empty():
		go_to_scene(_session.resume_scene_key)
		return
	var next: String = _session.next_unlocked_scene()
	if next == "main_menu":
		replay_scene(LEVEL_ORDER[0].scene_key)
	elif _session.completed_levels.is_empty() and _session.words_learned.is_empty():
		go_to_scene("intro")
	else:
		go_to_scene(str(VocabularyCatalog.level_info(next).get("story_key", next)))


func replay_scene(key: String) -> bool:
	# Navegar antes de borrar evita que el checkpoint de salida restaure el estado viejo.
	if not go_to_scene(key):
		return false
	_session.scene_states[key] = ReplayVariation.replay_state(_session.scene_states.get(key, {}))
	_session.scene_states[key].replay_run = "%d-%d" % [Time.get_ticks_usec(), randi()]
	_save.call()
	return true
