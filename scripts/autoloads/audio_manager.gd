## Autoload de sonido. Cambia la música y el ambiente al cambiar de escena con
## un fundido cruzado, reproduce los efectos por nombre y guarda el volumen.
## Qué suena en cada lugar se decide en `data/audio_catalog.tres` (Inspector);
## los reproductores son nodos de `scenes/autoloads/audio_manager.tscn`.
extends Node

signal volume_changed

const SETTINGS_PATH := "user://ajustes_audio.cfg"
const BUS_MUSIC := &"Musica"
const BUS_AMBIENCE := &"Ambiente"
const BUS_EFFECTS := &"Efectos"
const SILENT_DB := -60.0
## Los botones de este grupo no suenan al pulsarlos (por ejemplo, si ya tienen su propio sonido).
const NO_CLICK_GROUP := &"sin_sonido_clic"
const HISTORY_SIZE := 24
## Un mismo efecto no se repite antes de este tiempo (evita ráfagas al arrastrar).
const MIN_REPEAT_MSEC := 45

@export var catalog: AudioCatalog
@export_range(0.0, 4.0, 0.1) var music_fade_seconds: float = 1.2
@export_range(0.0, 4.0, 0.1) var ambience_fade_seconds: float = 1.6
## Cuánto baja la música mientras suena una fanfarria.
@export_range(-30.0, 0.0, 1.0) var duck_db: float = -14.0
@export_range(0.0, 6.0, 0.1) var duck_seconds: float = 3.6
## Espera entre el acierto y la campanita de palabra nueva para que no se encimen.
@export_range(0.0, 1.0, 0.05) var word_learned_delay: float = 0.4
## Volumen inicial (0 a 1) la primera vez que se juega.
@export_range(0.0, 1.0, 0.05) var default_music_volume: float = 0.8
@export_range(0.0, 1.0, 0.05) var default_effects_volume: float = 1.0

@onready var _music_players: Array[AudioStreamPlayer] = [$MusicaA, $MusicaB]
@onready var _ambience_players: Array[AudioStreamPlayer] = [$AmbienteA, $AmbienteB]
@onready var _effects: AudioStreamPlayer = $Efectos

## Últimos efectos pedidos; las pruebas lo usan para comprobar la retroalimentación.
var effect_history: Array[String] = []
var music_volume: float = 0.8
var effects_volume: float = 1.0
var muted: bool = false
var current_music: AudioStream
var current_ambience: AudioStream
var duck_offset_db: float = 0.0:
	set(value):
		duck_offset_db = value
		_apply_bus_volumes()

var _bus_trim_db: Dictionary[StringName, float] = {}
var _music_index: int = 0
var _ambience_index: int = 0
var _fade_tweens: Dictionary = {}
var _duck_tween: Tween
var _scene_ambience: AudioStream
var _last_played: Dictionary = {}
## Sin tarjeta de sonido (por ejemplo, en las pruebas con --headless) el
## controlador «Dummy» no mezcla y los streams nunca se liberan; entonces solo se
## lleva la cuenta de lo que sonaría, sin reproducir.
var _silent: bool = false
var _save_pending: bool = false
## Los efectos diferidos conservan referencias débiles al propietario y la escena.
## Su espera sigue el tiempo del mundo; la pausa no adelanta pasos o saltos.
var _scheduled: Array[Dictionary] = []


func _ready() -> void:
	_silent = AudioServer.get_driver_name() == "Dummy"
	for bus: StringName in [BUS_MUSIC, BUS_AMBIENCE, BUS_EFFECTS]:
		var index: int = AudioServer.get_bus_index(bus)
		if index >= 0:
			_bus_trim_db[bus] = AudioServer.get_bus_volume_db(index)
	_load_settings()
	if not _silent:
		_effects.play()
	get_tree().node_added.connect(_on_node_added)
	get_tree().scene_changed.connect(_on_scene_changed)
	GameManager.word_learned.connect(_on_word_learned)
	GameManager.level_completed.connect(_on_level_completed)
	set_process(false)
	_on_scene_changed.call_deferred()


func _process(delta: float) -> void:
	for entry: Dictionary in _scheduled.duplicate():
		var owner_reference: WeakRef = entry.owner
		var scene_reference: WeakRef = entry.scene
		if (
			(owner_reference != null and owner_reference.get_ref() == null)
			or (scene_reference != null and scene_reference.get_ref() != get_tree().current_scene)
		):
			_scheduled.erase(entry)
			continue
		if get_tree().paused:
			continue
		entry.remaining = float(entry.remaining) - delta
		if float(entry.remaining) <= 0.0:
			_scheduled.erase(entry)
			play_sfx(str(entry.key), float(entry.pitch))
	if _scheduled.is_empty():
		set_process(false)


## Al cerrar el juego se detienen los reproductores para liberar sus streams.
func _exit_tree() -> void:
	for player: AudioStreamPlayer in _music_players + _ambience_players + [_effects]:
		player.stop()


# ─── Música y ambiente ───────────────────────────────────────────────────────
func play_music(stream: AudioStream, fade: float = music_fade_seconds) -> void:
	if stream == current_music:
		return
	current_music = stream
	_music_index = _crossfade(_music_players, _music_index, stream, fade)


func stop_music(fade: float = music_fade_seconds) -> void:
	play_music(null, fade)


## Cambia el ambiente de la escena (por ejemplo, la lluvia de un momento de historia).
func play_ambience(stream: AudioStream, fade: float = ambience_fade_seconds) -> void:
	if stream == current_ambience:
		return
	current_ambience = stream
	_ambience_index = _crossfade(_ambience_players, _ambience_index, stream, fade)


## Vuelve al ambiente que el catálogo asigna a la escena actual.
func restore_scene_ambience() -> void:
	play_ambience(_scene_ambience)


func apply_scene_key(scene_key: String) -> void:
	if catalog == null or scene_key.is_empty():
		return
	if catalog.has_music(scene_key):
		play_music(catalog.music_for(scene_key))
	_scene_ambience = catalog.ambience_for(scene_key)
	play_ambience(_scene_ambience)


func _crossfade(
	players: Array[AudioStreamPlayer], index: int, stream: AudioStream, fade: float
) -> int:
	var old_player: AudioStreamPlayer = players[index]
	if old_player.stream != null:
		_fade(old_player, SILENT_DB, fade, true)
	if stream == null:
		return index
	var next_index: int = (index + 1) % players.size()
	var player: AudioStreamPlayer = players[next_index]
	player.stream = stream
	player.volume_db = SILENT_DB if fade > 0.0 else 0.0
	if not _silent:
		player.play()
	_fade(player, 0.0, fade, false)
	return next_index


func _fade(player: AudioStreamPlayer, target_db: float, seconds: float, stop_at_end: bool) -> void:
	var previous: Tween = _fade_tweens.get(player)
	if previous and previous.is_valid():
		previous.kill()
	if seconds <= 0.0:
		player.volume_db = target_db
		if stop_at_end:
			_release(player)
		return
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", target_db, seconds).set_trans(Tween.TRANS_SINE)
	if stop_at_end:
		tween.tween_callback(_release.bind(player))
	_fade_tweens[player] = tween


func _release(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null


## Baja la música unos segundos para que se luzca una fanfarria.
func duck_music(seconds: float = duck_seconds) -> void:
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(self, "duck_offset_db", duck_db, 0.25)
	_duck_tween.tween_interval(maxf(seconds - 1.0, 0.0))
	_duck_tween.tween_property(self, "duck_offset_db", 0.0, 0.75)


# ─── Efectos ─────────────────────────────────────────────────────────────────
## Reproduce un efecto del catálogo por su nombre (por ejemplo "acierto").
func play_sfx(key: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	effect_history.append(key)
	if effect_history.size() > HISTORY_SIZE:
		effect_history.remove_at(0)
	var now: int = Time.get_ticks_msec()
	if now - int(_last_played.get(key, -MIN_REPEAT_MSEC)) < MIN_REPEAT_MSEC:
		return
	_last_played[key] = now
	if catalog == null:
		return
	var stream: AudioStream = catalog.effect(key)
	if stream == null:
		push_warning("AudioManager: efecto desconocido '%s'" % key)
		return
	play_stream(stream, pitch_scale, volume_db)


## Programa un efecto para dentro de `delay` segundos (pasos, saltos, campanitas).
func play_sfx_later(
	key: String, delay: float, pitch_scale: float = 1.0, source: Object = null
) -> void:
	if delay <= 0.0:
		play_sfx(key, pitch_scale)
		return
	var scene: Node = get_tree().current_scene
	var effect_owner: Object = source if source != null else scene
	_scheduled.append(
		{
			"remaining": delay,
			"key": key,
			"pitch": pitch_scale,
			"owner": weakref(effect_owner) if effect_owner != null else null,
			"scene": weakref(scene) if scene != null else null
		}
	)
	set_process(true)


## Sin propietario cancela todo; con él sólo retira sus efectos momentáneos.
func cancel_scheduled(source: Object = null) -> void:
	if source == null:
		_scheduled.clear()
	else:
		for entry: Dictionary in _scheduled.duplicate():
			var reference: WeakRef = entry.owner
			if reference != null and reference.get_ref() == source:
				_scheduled.erase(entry)
	set_process(not _scheduled.is_empty())


func play_stream(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if _silent:
		return
	if not _effects.playing:
		_effects.play()
	var playback: AudioStreamPlaybackPolyphonic = (
		_effects.get_stream_playback() as AudioStreamPlaybackPolyphonic
	)
	if playback:
		playback.play_stream(
			stream, 0.0, volume_db, pitch_scale, AudioServer.PLAYBACK_TYPE_DEFAULT, BUS_EFFECTS
		)


## Pasos de Kalin según el suelo: "arena", "tierra", "pasto" o "piedra".
func play_footstep(surface: String) -> void:
	play_sfx("pasos_" + surface)


func clear_history() -> void:
	effect_history.clear()
	cancel_scheduled()


# ─── Volumen ─────────────────────────────────────────────────────────────────
func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()
	_queue_save()


func set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()
	_queue_save()


func set_muted(value: bool) -> void:
	muted = value
	_apply_bus_volumes()
	_queue_save()


func _apply_bus_volumes() -> void:
	_set_bus(BUS_MUSIC, music_volume, duck_offset_db)
	_set_bus(BUS_AMBIENCE, effects_volume, 0.0)
	_set_bus(BUS_EFFECTS, effects_volume, 0.0)
	AudioServer.set_bus_mute(0, muted)
	volume_changed.emit()


func _set_bus(bus_name: StringName, linear: float, offset_db: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(
		index, _bus_trim_db.get(bus_name, 0.0) + linear_to_db(maxf(linear, 0.001)) + offset_db
	)


func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	music_volume = default_music_volume
	effects_volume = default_effects_volume
	muted = false
	if config.load(SETTINGS_PATH) == OK:
		music_volume = _settings_volume(
			config.get_value("volumen", "musica", music_volume), music_volume
		)
		effects_volume = _settings_volume(
			config.get_value("volumen", "sonidos", effects_volume), effects_volume
		)
		var saved_mute: Variant = config.get_value("volumen", "silencio", false)
		if saved_mute is bool:
			muted = saved_mute
	_apply_bus_volumes()


func _settings_volume(value: Variant, fallback: float) -> float:
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), 0.0, 1.0)
	return fallback


## Los deslizadores cambian el valor muchas veces por segundo: se guarda una vez por cuadro.
func _queue_save() -> void:
	if not _save_pending:
		_save_pending = true
		_save_settings.call_deferred()


func _save_settings() -> void:
	_save_pending = false
	var config: ConfigFile = ConfigFile.new()
	config.set_value("volumen", "musica", music_volume)
	config.set_value("volumen", "sonidos", effects_volume)
	config.set_value("volumen", "silencio", muted)
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("AudioManager: no se pudo guardar el volumen (error %d)" % error)


# ─── Conexiones automáticas ──────────────────────────────────────────────────
func _on_scene_changed() -> void:
	var scene: Node = get_tree().current_scene
	if scene != null:
		apply_scene_key(GameManager.scene_key_for(scene))


## Todos los botones suenan al pulsarlos y al pasar el ratón, sin configurarlos uno por uno.
func _on_node_added(node: Node) -> void:
	if node is not BaseButton or node.is_in_group(NO_CLICK_GROUP):
		return
	var button: BaseButton = node as BaseButton
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(_on_button_hovered.bind(button))


func _on_button_pressed() -> void:
	play_sfx("boton_clic")


func _on_button_hovered(button: BaseButton) -> void:
	if not button.disabled and button.is_visible_in_tree():
		play_sfx("boton_pasar")


func _on_word_learned(_word_data: Dictionary) -> void:
	play_sfx_later("palabra_aprendida", word_learned_delay)


func _on_level_completed(_world: int, _level: int) -> void:
	duck_music()
	play_sfx("nivel_completado")
