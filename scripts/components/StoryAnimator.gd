extends RefCounted
class_name StoryAnimator

## Subsistema visual de StoryScene. Centraliza transiciones, efectos y los
## movimientos de Kalin; el controlador principal conserva únicamente el flujo
## narrativo y las interacciones educativas.

const BACKGROUND_FADE_SECONDS := 0.7
const AMBIENT_SECONDS := 0.9
const AMBIENT_COLORS := {
	StoryBeat.Mood.DIA: Color(1.0, 1.0, 1.0),
	StoryBeat.Mood.ATARDECER: Color(1.0, 0.84, 0.7),
	StoryBeat.Mood.NOCHE: Color(0.5, 0.56, 0.82),
	StoryBeat.Mood.TORMENTA: Color(0.72, 0.78, 0.92),
	StoryBeat.Mood.AMANECER: Color(1.0, 0.92, 0.84),
}
const CONTINUOUS_EFFECTS := {
	StoryBeat.Effect.HOJAS: "Hojas",
	StoryBeat.Effect.LLUVIA: "Lluvia",
	StoryBeat.Effect.MUEBLES: "Muebles",
	StoryBeat.Effect.PAGINAS: "Paginas",
	StoryBeat.Effect.CHISPAS: "Chispas",
}
const KALIN_BOB := 6.0
const SHAKE_SECONDS := 0.6
const SHAKE_STEPS := 10
const SHAKE_AMPLITUDE := 10.0
const FLASH_PEAK := 0.85
const FLASH_SECONDS := 0.6
const TITLE_FADE_SECONDS := 0.5
const TITLE_HOLD_SECONDS := 2.0
const WALK_SECONDS := 1.1
const WALK_DISTANCE := 420.0
const WALK_STEPS := 4.0
const WALK_TILT := 0.05
const WALK_BOUNCE := 10.0
const JUMP_HEIGHT := 46.0
const JUMP_COUNT := 2
const SHIVER_DISTANCE := 6.0
const SHIVER_REPEATS := 8
const SLEEP_ANGLE := 1.47
const SLEEP_POSITION := Vector2(200, 185)
const STAND_UP_SECONDS := 0.5
const BREATH_SCALE := 1.03
const PORTAL_CENTER := Vector2(800, 320)
const CROSS_SECONDS := 1.6
const CROSS_SCALE := 0.2

var sleeping: bool = false
var _host: Node2D
var _ambient: CanvasModulate
var _background: TextureRect
var _background_next: TextureRect
var _kalin: TextureRect
var _effects_root: Node2D
var _title_card: Panel
var _title_label: Label
var _subtitle_label: Label
var _flash_rect: ColorRect
var _celebration: Label
var _kalin_home: Vector2
var _current_background: Texture2D
var _celebration_tween: Tween
var _kalin_idle_tween: Tween
var _kalin_motion_tween: Tween
var _background_tween: Tween
var _ambient_tween: Tween
var _shake_tween: Tween
var _flash_tween: Tween
var _title_tween: Tween

func _init(
	host: Node2D,
	ambient: CanvasModulate,
	background: TextureRect,
	background_next: TextureRect,
	kalin: TextureRect,
	effects_root: Node2D,
	title_card: Panel,
	title_label: Label,
	subtitle_label: Label,
	flash_rect: ColorRect,
	celebration: Label
) -> void:
	_host = host
	_ambient = ambient
	_background = background
	_background_next = background_next
	_kalin = kalin
	_effects_root = effects_root
	_title_card = title_card
	_title_label = title_label
	_subtitle_label = subtitle_label
	_flash_rect = flash_rect
	_celebration = celebration
	_kalin_home = kalin.position
	_current_background = background.texture

func start_idle() -> void:
	if _kalin_idle_tween:
		_kalin_idle_tween.kill()
	_kalin_idle_tween = _host.create_tween().set_loops()
	_kalin_idle_tween.tween_property(_kalin, "position:y", _kalin_home.y - KALIN_BOB, 1.2).set_trans(Tween.TRANS_SINE)
	_kalin_idle_tween.tween_property(_kalin, "position:y", _kalin_home.y, 1.2).set_trans(Tween.TRANS_SINE)

func celebrate_page() -> void:
	if _celebration_tween:
		_celebration_tween.kill()
	_celebration.visible = true
	(_effects_root.get_node("ConfetiPaginas") as CPUParticles2D).restart()
	(_effects_root.get_node("ConfetiChispas") as CPUParticles2D).restart()
	_celebration.pivot_offset = _celebration.size * 0.5
	_celebration.scale = Vector2(0.6, 0.6)
	_celebration.modulate.a = 1.0
	_celebration_tween = _host.create_tween()
	_celebration_tween.tween_property(_celebration, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	_celebration_tween.tween_interval(1.4)
	_celebration_tween.tween_property(_celebration, "modulate:a", 0.0, 0.5)
	_celebration_tween.tween_callback(_celebration.hide)

func hide_celebration() -> void:
	if _celebration_tween:
		_celebration_tween.kill()
	_celebration.hide()

func change_background(texture: Texture2D, immediate: bool) -> void:
	if texture == null or texture == _current_background:
		return
	if _background_tween and _background_tween.is_running():
		_background_tween.kill()
		_background.texture = _background_next.texture
	_current_background = texture
	if immediate:
		_background.texture = texture
		_background_next.hide()
		return
	_background_next.texture = texture
	_background_next.modulate.a = 0.0
	_background_next.show()
	_background_tween = _host.create_tween()
	_background_tween.tween_property(_background_next, "modulate:a", 1.0, BACKGROUND_FADE_SECONDS)
	_background_tween.tween_callback(_finish_background_fade.bind(texture))

func _finish_background_fade(texture: Texture2D) -> void:
	_background.texture = texture
	_background_next.hide()

func apply_mood(mood: StoryBeat.Mood, immediate: bool) -> void:
	if mood == StoryBeat.Mood.SIN_CAMBIO:
		return
	var color: Color = AMBIENT_COLORS[mood]
	if _ambient_tween:
		_ambient_tween.kill()
	if immediate:
		_ambient.color = color
		return
	_ambient_tween = _host.create_tween()
	_ambient_tween.tween_property(_ambient, "color", color, AMBIENT_SECONDS)

func apply_effects(effects: int) -> void:
	for flag: int in CONTINUOUS_EFFECTS:
		var particles := _effects_root.get_node(NodePath(CONTINUOUS_EFFECTS[flag])) as CPUParticles2D
		particles.emitting = (effects & flag) != 0

func shake_screen() -> void:
	if _shake_tween:
		_shake_tween.kill()
	_host.position = Vector2.ZERO
	_shake_tween = _host.create_tween()
	var step_time: float = SHAKE_SECONDS / SHAKE_STEPS
	for step: int in range(SHAKE_STEPS):
		var fade: float = 1.0 - float(step) / SHAKE_STEPS
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_AMPLITUDE * fade
		_shake_tween.tween_property(_host, "position", offset, step_time)
	_shake_tween.tween_property(_host, "position", Vector2.ZERO, step_time)

func flash_screen() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_rect.modulate.a = FLASH_PEAK
	_flash_tween = _host.create_tween()
	_flash_tween.tween_property(_flash_rect, "modulate:a", 0.0, FLASH_SECONDS)

func show_title(title: String, subtitle: String) -> void:
	if _title_tween:
		_title_tween.kill()
	if title == "":
		if _title_card.modulate.a > 0.0:
			_title_tween = _host.create_tween()
			_title_tween.tween_property(_title_card, "modulate:a", 0.0, TITLE_FADE_SECONDS * 0.5)
		return
	_title_label.text = title
	_subtitle_label.text = subtitle
	_subtitle_label.visible = subtitle != ""
	_title_card.modulate.a = 0.0
	_title_tween = _host.create_tween()
	_title_tween.tween_property(_title_card, "modulate:a", 1.0, TITLE_FADE_SECONDS)
	_title_tween.tween_interval(TITLE_HOLD_SECONDS)
	_title_tween.tween_property(_title_card, "modulate:a", 0.0, TITLE_FADE_SECONDS)

func play_kalin_motion(motion: StoryBeat.KalinMotion) -> void:
	var stand_up: bool = sleeping and motion == StoryBeat.KalinMotion.QUIETO
	_reset_kalin(stand_up)
	match motion:
		StoryBeat.KalinMotion.ENTRA: _kalin_walk_in()
		StoryBeat.KalinMotion.SALTA: _kalin_jump()
		StoryBeat.KalinMotion.TIEMBLA: _kalin_shiver()
		StoryBeat.KalinMotion.DORMIDO: _kalin_sleep()
		StoryBeat.KalinMotion.CRUZA: _kalin_cross_portal()
		_:
			if not stand_up:
				start_idle()

func _reset_kalin(animated: bool) -> void:
	for tween: Tween in [_kalin_motion_tween, _kalin_idle_tween]:
		if tween:
			tween.kill()
	sleeping = false
	_kalin.modulate.a = 1.0
	_kalin.z_index = 0
	if animated:
		_kalin_motion_tween = _host.create_tween().set_parallel(true)
		_kalin_motion_tween.tween_property(_kalin, "position", _kalin_home, STAND_UP_SECONDS)
		_kalin_motion_tween.tween_property(_kalin, "rotation", 0.0, STAND_UP_SECONDS)
		_kalin_motion_tween.tween_property(_kalin, "scale", Vector2.ONE, STAND_UP_SECONDS)
		_kalin_motion_tween.chain().tween_callback(start_idle)
		return
	_kalin.position = _kalin_home
	_kalin.rotation = 0.0
	_kalin.scale = Vector2.ONE

func _kalin_walk_in() -> void:
	_kalin.position.x = _kalin_home.x - WALK_DISTANCE
	_kalin_motion_tween = _host.create_tween()
	_kalin_motion_tween.tween_method(_walk_step, 0.0, 1.0, WALK_SECONDS)
	_kalin_motion_tween.tween_callback(start_idle)

func _walk_step(progress: float) -> void:
	var stride: float = sin(progress * TAU * WALK_STEPS)
	_kalin.position.x = lerpf(_kalin_home.x - WALK_DISTANCE, _kalin_home.x, sin(progress * PI * 0.5))
	_kalin.position.y = _kalin_home.y - absf(stride) * WALK_BOUNCE
	_kalin.rotation = stride * WALK_TILT

func _kalin_jump() -> void:
	_kalin_motion_tween = _host.create_tween()
	for _jump: int in range(JUMP_COUNT):
		_kalin_motion_tween.tween_property(_kalin, "position:y", _kalin_home.y - JUMP_HEIGHT, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_kalin_motion_tween.tween_property(_kalin, "position:y", _kalin_home.y, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_kalin_motion_tween.tween_callback(start_idle)

func _kalin_shiver() -> void:
	_kalin_motion_tween = _host.create_tween()
	for repeat: int in range(SHIVER_REPEATS):
		var direction: float = 1.0 if repeat % 2 == 0 else -1.0
		_kalin_motion_tween.tween_property(_kalin, "position:x", _kalin_home.x + direction * SHIVER_DISTANCE, 0.04)
	_kalin_motion_tween.tween_property(_kalin, "position:x", _kalin_home.x, 0.04)
	_kalin_motion_tween.tween_callback(start_idle)

func _kalin_sleep() -> void:
	sleeping = true
	_kalin.rotation = -SLEEP_ANGLE
	_kalin.position = SLEEP_POSITION
	_kalin_motion_tween = _host.create_tween().set_loops()
	_kalin_motion_tween.tween_property(_kalin, "scale", Vector2(BREATH_SCALE, BREATH_SCALE), 1.6).set_trans(Tween.TRANS_SINE)
	_kalin_motion_tween.tween_property(_kalin, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)

func _kalin_cross_portal() -> void:
	_kalin.z_index = 1
	_kalin_motion_tween = _host.create_tween().set_parallel(true)
	var target: Vector2 = PORTAL_CENTER - _kalin.pivot_offset
	_kalin_motion_tween.tween_property(_kalin, "position", target, CROSS_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_kalin_motion_tween.tween_property(_kalin, "scale", Vector2(CROSS_SCALE, CROSS_SCALE), CROSS_SECONDS).set_trans(Tween.TRANS_SINE)
	_kalin_motion_tween.tween_property(_kalin, "modulate:a", 0.0, CROSS_SECONDS * 0.4).set_delay(CROSS_SECONDS * 0.6)
