## Valida el sistema de sonido: buses, catálogo, archivos y que cada parte del
## juego pida los efectos correctos (sin tarjeta de sonido se registra en
## AudioManager.effect_history lo que sonaría).
extends SceneTree

const AUDIO_ROOT: String = "res://Audio"
const BUSES: Array[String] = ["Musica", "Ambiente", "Efectos", "Voces"]
const SURFACES: Array[String] = ["arena", "tierra", "pasto", "piedra"]
const EXPLORATIONS: Dictionary = {
	"world1_explore1": "arena",
	"world1_explore2": "tierra",
	"world3_explore2": "pasto",
	"world4_explore1": "piedra",
}
## Nombres de archivo en español, en minúsculas y sin acentos ni espacios.
const FILE_NAME_PATTERN: String = "^[a-z][a-z0-9_]*\\.ogg$"
## Efectos que AudioManager pide por su cuenta (botones, palabras y niveles).
const AUTOMATIC_EFFECTS: Array[String] = [
	"boton_clic", "boton_pasar", "palabra_aprendida", "nivel_completado"
]

var failures: Array[String] = []
var audio: Node
var catalog: AudioCatalog


func _initialize() -> void:
	await process_frame
	var manager: Node = root.get_node("GameManager")
	manager.session.scene_states.clear()
	manager.session.resume_scene_key = ""
	manager._save_repository = load("res://scripts/core/persistence/save_repository.gd").new(
		"user://audio_validation_progress.json"
	)
	audio = root.get_node_or_null("AudioManager")
	if audio == null:
		failures.append("Falta el autoload AudioManager")
		_finish()
		return
	catalog = audio.catalog
	if catalog == null:
		failures.append("AudioManager no tiene catálogo de audio")
		_finish()
		return
	_validate_buses()
	_validate_catalog()
	_validate_files()
	_validate_code_keys()
	await _validate_scene_music()
	await _validate_buttons()
	await _validate_progress_feedback(manager)
	await _validate_volume()
	await _validate_story_sounds()
	await _validate_exploration_sounds()
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("Validación de audio: OK")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _validate_buses() -> void:
	for bus_name: String in BUSES:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index < 0:
			failures.append("Falta el bus de audio '%s'" % bus_name)
		elif AudioServer.get_bus_send(index) != &"Master":
			failures.append("El bus '%s' debe enviar a Master" % bus_name)


## Cada escena del juego tiene música, y la música y los ambientes se repiten.
func _validate_catalog() -> void:
	for scene_key: String in GameContent.SCENE_PATHS:
		if not catalog.has_music(scene_key) or catalog.music_for(scene_key) == null:
			failures.append("La escena '%s' no tiene música en el catálogo" % scene_key)
	for scene_key: String in catalog.scene_music:
		if scene_key not in GameContent.SCENE_PATHS:
			failures.append(
				"El catálogo tiene música para una escena que no existe: '%s'" % scene_key
			)
		_check_loop(catalog.scene_music[scene_key], "música de " + scene_key, true)
	for scene_key: String in catalog.scene_ambience:
		if scene_key not in GameContent.SCENE_PATHS:
			failures.append(
				"El catálogo tiene ambiente para una escena que no existe: '%s'" % scene_key
			)
		_check_loop(catalog.scene_ambience[scene_key], "ambiente de " + scene_key, true)
	if catalog.rain_ambience == null:
		failures.append("Falta el ambiente de lluvia para los momentos de historia")
	else:
		_check_loop(catalog.rain_ambience, "ambiente de lluvia", true)
	for key: String in catalog.effects:
		var stream: AudioStream = catalog.effects[key]
		if stream == null:
			failures.append("El efecto '%s' está vacío" % key)
			continue
		for inner: AudioStream in _streams_of(stream):
			_check_loop(inner, "efecto " + key, false)
	for surface: String in SURFACES:
		var footsteps: AudioStream = catalog.effect("pasos_" + surface)
		if (
			footsteps is not AudioStreamRandomizer
			or (footsteps as AudioStreamRandomizer).streams_count < 3
		):
			failures.append(
				(
					"Los pasos sobre %s deben variar (AudioStreamRandomizer con 3 o más sonidos)"
					% surface
				)
			)


func _check_loop(stream: AudioStream, label: String, should_loop: bool) -> void:
	var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
	if ogg == null:
		failures.append("%s debe ser un archivo .ogg" % label.capitalize())
	elif ogg.loop != should_loop:
		failures.append(
			"%s %s repetirse en bucle" % [label.capitalize(), "debe" if should_loop else "no debe"]
		)


func _streams_of(stream: AudioStream) -> Array[AudioStream]:
	var result: Array[AudioStream] = []
	if stream is AudioStreamRandomizer:
		var randomizer: AudioStreamRandomizer = stream as AudioStreamRandomizer
		for index: int in range(randomizer.streams_count):
			result.append(randomizer.get_stream(index))
	else:
		result.append(stream)
	return result


## Los archivos tienen nombres en español y ninguno queda sin usar.
func _validate_files() -> void:
	var used: Dictionary = {}
	var loops: Array[AudioStream] = []
	loops.append_array(catalog.scene_music.values())
	loops.append_array(catalog.scene_ambience.values())
	loops.append(catalog.rain_ambience)
	for stream: AudioStream in loops:
		if stream:
			used[stream.resource_path] = true
	for stream: AudioStream in catalog.effects.values():
		for inner: AudioStream in _streams_of(stream):
			used[inner.resource_path] = true
	var pattern: RegEx = RegEx.create_from_string(FILE_NAME_PATTERN)
	var prefixes: Dictionary = {"musica": "musica_", "ambiente": "ambiente_", "efectos": ""}
	for folder: String in prefixes:
		var files: PackedStringArray = DirAccess.get_files_at("%s/%s" % [AUDIO_ROOT, folder])
		if files.is_empty():
			failures.append("La carpeta Audio/%s está vacía" % folder)
		for file: String in files:
			if file.ends_with(".import"):
				continue
			var path: String = "%s/%s/%s" % [AUDIO_ROOT, folder, file]
			if pattern.search(file) == null or not file.begins_with(prefixes[folder]):
				failures.append("Nombre de audio fuera de la convención: %s" % path)
			if path not in used:
				failures.append("Archivo de audio sin usar en el catálogo: %s" % path)


## Toda clave que el código pide existe en el catálogo.
func _validate_code_keys() -> void:
	var calls: RegEx = RegEx.create_from_string(
		'(?:play_sfx|play_sfx_later|SoundCue\\.play\\(self,)\\s*\\(?\\s*"([a-z0-9_]+)"\\s*[,)]'
	)
	var tables: RegEx = RegEx.create_from_string(
		'(?:StoryBeat\\.Effect\\.[A-Z]+|KalinMotion\\.[A-Z]+):\\s*"([a-z0-9_]+)"'
	)
	var keys: Dictionary = {}
	for path: String in _gd_files("res://scripts"):
		var source: String = FileAccess.get_file_as_string(path)
		for regex: RegEx in [calls, tables]:
			for found: RegExMatch in regex.search_all(source):
				keys[found.get_string(1)] = path
	for key: String in AUTOMATIC_EFFECTS:
		keys[key] = "AudioManager"
	if keys.size() < 30:
		failures.append(
			(
				"Se esperaban más efectos en el código; ¿cambió la forma de pedirlos? (%d)"
				% keys.size()
			)
		)
	for key: String in keys:
		if not catalog.has_effect(key):
			failures.append(
				"El código pide el efecto '%s' (%s) pero no está en el catálogo" % [key, keys[key]]
			)


func _gd_files(folder: String) -> Array[String]:
	var result: Array[String] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			result.append(folder.path_join(file))
	for sub: String in DirAccess.get_directories_at(folder):
		result.append_array(_gd_files(folder.path_join(sub)))
	return result


## Al cambiar de escena cambian la música y el ambiente; si se repite la pieza, sigue sonando.
func _validate_scene_music() -> void:
	audio.apply_scene_key("world1_level1")
	var level_music: AudioStream = audio.current_music
	if level_music != catalog.music_for("world1_level1"):
		failures.append("La música del Mundo 1 no se aplicó")
	audio.apply_scene_key("world1_level2")
	if audio.current_music != level_music:
		failures.append("Los niveles del Mundo 1 deben compartir la misma pieza sin reiniciarla")
	audio.apply_scene_key("world1_cine1")
	if (
		audio.current_ambience != catalog.ambience_for("world1_cine1")
		or audio.current_ambience == null
	):
		failures.append("La cinemática del huracán debe sonar con lluvia")
	audio.apply_scene_key("main_menu")
	if audio.current_ambience != null:
		failures.append("El menú principal no debe tener ambiente")
	change_scene_to_file(GameContent.SCENE_PATHS.main_menu)
	for _frame: int in range(4):
		await process_frame
	if audio.current_music != catalog.music_for("main_menu"):
		failures.append("Abrir el menú principal debe poner su música")
	var menu: Node = current_scene
	if menu == null or menu.get_node_or_null("UI/TopBar/SoundToggle") == null:
		failures.append("El menú principal debe tener el botón de sonido")
	current_scene = null
	if menu:
		menu.queue_free()
	await process_frame


func _validate_buttons() -> void:
	audio.clear_history()
	var button: Button = Button.new()
	root.add_child(button)
	button.pressed.emit()
	if "boton_clic" not in audio.effect_history:
		failures.append("Los botones deben sonar al pulsarlos")
	audio.clear_history()
	var quiet: Button = Button.new()
	quiet.add_to_group(audio.NO_CLICK_GROUP)
	root.add_child(quiet)
	await create_timer(0.1).timeout
	quiet.pressed.emit()
	if "boton_clic" in audio.effect_history:
		failures.append("Los botones del grupo sin_sonido_clic no deben sonar")
	button.queue_free()
	quiet.queue_free()
	await process_frame


func _validate_progress_feedback(manager: Node) -> void:
	audio.clear_history()
	manager.level_completed.emit(1, 1)
	if "nivel_completado" not in audio.effect_history:
		failures.append("Completar un nivel debe sonar la fanfarria")
	await create_timer(0.4).timeout
	if audio.duck_offset_db > -1.0:
		failures.append("La música debe bajar mientras suena la fanfarria")
	audio.clear_history()
	manager.word_learned.emit({})
	await create_timer(audio.word_learned_delay + 0.2).timeout
	if "palabra_aprendida" not in audio.effect_history:
		failures.append("Aprender una palabra debe sonar la campanita del libro")
	# Los efectos programados no usan temporizadores: al salir no queda ninguno pendiente.
	audio.play_sfx_later("salto", 5.0)
	audio.cancel_scheduled()
	if not audio._scheduled.is_empty() or audio.is_processing():
		failures.append("Cancelar debe olvidar los efectos programados")


func _validate_volume() -> void:
	var previous: float = audio.music_volume
	audio.set_music_volume(0.5)
	var index: int = AudioServer.get_bus_index(&"Musica")
	var expected: float = linear_to_db(0.5) + float(audio.duck_offset_db)
	if absf(AudioServer.get_bus_volume_db(index) - expected) > 0.01:
		failures.append("El volumen de la música no se aplicó al bus")
	audio.set_muted(true)
	if not AudioServer.is_bus_mute(0):
		failures.append("Silenciar debe apagar el bus Master")
	audio.set_muted(false)
	audio.set_music_volume(previous)
	await process_frame
	var config: ConfigFile = ConfigFile.new()
	if config.load(audio.SETTINGS_PATH) != OK:
		failures.append("El volumen debe guardarse en %s" % audio.SETTINGS_PATH)
	var pause_menu: Node = root.get_node("PauseMenu")
	if pause_menu.get_node_or_null("Shade/Panel/VolumeControls") == null:
		failures.append("El menú de pausa debe tener los controles de volumen")


## La cinemática del huracán suena sola: caracol con el cartel y trueno con el relámpago.
func _validate_story_sounds() -> void:
	var beat: StoryBeat = StoryBeat.new()
	for property: String in ["sound", "music"]:
		if property not in beat:
			failures.append("StoryBeat debe tener la propiedad «%s» (categoría Sonido)" % property)
	audio.clear_history()
	var story: Node = (load(GameContent.SCENE_PATHS.world1_cine1) as PackedScene).instantiate()
	root.add_child(story)
	await process_frame
	var heard: Array[String] = []
	heard.append_array(audio.effect_history)
	while story.beat_index < story.beats.size() - 1:
		story._next_beat()
		heard.append_array(audio.effect_history)
	for key: String in ["cartel_caracol", "trueno"]:
		if key not in heard:
			failures.append("La cinemática del huracán debe sonar «%s»" % key)
	story.queue_free()
	await process_frame
	audio.clear_history()
	var chapter: Node = (load(GameContent.SCENE_PATHS.world1_story1) as PackedScene).instantiate()
	root.add_child(chapter)
	await process_frame
	var checked: bool = false
	while chapter.beat_index < chapter.beats.size() - 1 and not checked:
		chapter._next_beat()
		var current: StoryBeat = chapter.current_beat()
		if current.kind == StoryBeat.Kind.ADIVINAR:
			for _frame: int in range(90):
				await process_frame
			for word: String in current.actors:
				if word != current.target_word:
					chapter._guess_actor(word, current.target_word)
					break
			chapter._guess_actor(current.target_word, current.target_word)
			checked = true
	if not checked:
		failures.append("El Capítulo 1 debía tener un momento ADIVINAR para probar sus sonidos")
	for key: String in ["error_suave", "acierto"]:
		if key not in audio.effect_history:
			failures.append("Adivinar en la historia debe sonar «%s»" % key)
	chapter.queue_free()
	await process_frame


## Cada exploración pisa su propio suelo y examinar un objeto suena.
func _validate_exploration_sounds() -> void:
	for scene_key: String in EXPLORATIONS:
		var path: String = GameContent.SCENE_PATHS[scene_key]
		var exploration: Node = (load(path) as PackedScene).instantiate()
		if exploration.footstep_surface != EXPLORATIONS[scene_key]:
			failures.append(
				"%s debe sonar a pasos sobre %s" % [path.get_file(), EXPLORATIONS[scene_key]]
			)
		exploration.free()
	var orilla: Node = (load(GameContent.SCENE_PATHS.world1_explore1) as PackedScene).instantiate()
	root.add_child(orilla)
	await process_frame
	var guard: int = 0
	while orilla.is_dialogue_open() and guard < 50:
		# El primer avance completa el texto y el segundo pasa a la línea siguiente.
		orilla.advance_dialogue()
		orilla.advance_dialogue()
		guard += 1
	audio.clear_history()
	for _step: int in range(20):
		orilla.walk(1.0, 0.1)
	if "pasos_arena" not in audio.effect_history:
		failures.append("Kalin debe sonar a pasos sobre arena al caminar por la orilla")
	audio.clear_history()
	for spot: ExplorationSpot in orilla.spots:
		if not spot.is_goal:
			orilla.open_spot(spot)
			break
	if "examinar_objeto" not in audio.effect_history:
		failures.append("Examinar un objeto debe sonar")
	orilla.queue_free()
	await process_frame
