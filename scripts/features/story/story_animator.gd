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
const CROSS_SECONDS := 2.6
const CROSS_SCALE := 0.72
const FAREWELL_HESITATE: Texture2D = preload("res://Arte/sprites/kalin_farewell_hesitate.svg")
const REACH_PAGE: Texture2D = preload("res://Arte/sprites/kalin_reach_page.svg")
const PORTAL_STEP: Texture2D = preload("res://Arte/sprites/kalin_portal_step.svg")
const PORTAL_LOOK_BACK: Texture2D = preload("res://Arte/sprites/kalin_portal_look_back.svg")
const GESTURE_TEXTURES: Dictionary[StoryBeat.KalinMotion, Texture2D] = {
	StoryBeat.KalinMotion.PROTECT_BOOK: preload("res://Arte/sprites/kalin_protect_book.svg"),
	StoryBeat.KalinMotion.THINK_HOME: preload("res://Arte/sprites/kalin_think_home.svg"),
	StoryBeat.KalinMotion.FAREWELL: FAREWELL_HESITATE,
	StoryBeat.KalinMotion.CRUZA: PORTAL_STEP,
}
const FAREWELL_WAVE: Texture2D = preload("res://Arte/sprites/kalin_farewell.svg")

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
var kalin_base_scale: Vector2
var _kalin_rotation: float
var _kalin_alpha: float
var _kalin_z_index: int
var _host_home: Vector2
var _celebration_scale: Vector2
var _celebration_alpha: float
var _speaker_tween: Tween
var _current_background: Texture2D
var _celebration_tween: Tween
var _kalin_idle_tween: Tween
var _kalin_motion_tween: Tween
var _background_tween: Tween
var _ambient_tween: Tween
var _shake_tween: Tween
var _flash_tween: Tween
var _title_tween: Tween
var _gesture_texture: Texture2D
var _gesture_active: bool = false
var _motion: StoryBeat.KalinMotion = StoryBeat.KalinMotion.QUIETO
var _page: TextureRect
var _page_ink: TextureRect
var _page_word: Label
var _page_home: Vector2
var _page_scale: Vector2
var _page_tween: Tween
var _page_motion: StoryBeat.PageMotion = StoryBeat.PageMotion.NONE


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
	kalin_base_scale = kalin.scale
	_kalin_rotation = kalin.rotation
	_kalin_alpha = kalin.modulate.a
	_kalin_z_index = kalin.z_index
	_host_home = host.position
	_celebration_scale = celebration.scale
	_celebration_alpha = celebration.modulate.a
	_current_background = background.texture
	_page = effects_root.get_node("StoryPage") as TextureRect
	_page_ink = _page.get_node("Ink") as TextureRect
	_page_word = _page.get_node("Word") as Label
	_page_home = _page.position
	_page_scale = _page.scale


func start_idle() -> void:
	if _kalin_idle_tween:
		_kalin_idle_tween.kill()
	if _host.get_node("/root/AccessibilityManager").reduced_motion:
		_kalin.position.y = _kalin_home.y
		return
	_kalin_idle_tween = _host.create_tween().set_loops()
	(
		_kalin_idle_tween
		. tween_property(_kalin, "position:y", _kalin_home.y - KALIN_BOB, 1.2)
		. set_trans(Tween.TRANS_SINE)
	)
	_kalin_idle_tween.tween_property(_kalin, "position:y", _kalin_home.y, 1.2).set_trans(
		Tween.TRANS_SINE
	)


func celebrate_page() -> void:
	if _celebration_tween:
		_celebration_tween.kill()
	_celebration.visible = true
	# La página recuperada ya cuenta el cambio: evitar otra lluvia de páginas.
	if _page_motion == StoryBeat.PageMotion.NONE:
		present_page(StoryBeat.PageMotion.RECOVER, "")
	_celebration.pivot_offset = _celebration.size * 0.5
	_celebration.scale = (
		_celebration_scale
		if _host.get_node("/root/AccessibilityManager").reduced_motion
		else _celebration_scale * 0.6
	)
	_celebration.modulate.a = _celebration_alpha
	_celebration_tween = _host.create_tween()
	_celebration_tween.tween_property(_celebration, "scale", _celebration_scale, 0.35).set_trans(
		Tween.TRANS_BACK
	)
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
		var particles: CPUParticles2D = (
			_effects_root.get_node(NodePath(CONTINUOUS_EFFECTS[flag])) as CPUParticles2D
		)
		particles.emitting = (effects & flag) != 0


func shake_screen() -> void:
	if _shake_tween:
		_shake_tween.kill()
	_host.position = _host_home
	if _host.get_node("/root/AccessibilityManager").reduced_motion:
		return
	_shake_tween = _host.create_tween()
	var step_time: float = SHAKE_SECONDS / SHAKE_STEPS
	for step: int in range(SHAKE_STEPS):
		var fade: float = 1.0 - float(step) / SHAKE_STEPS
		var offset: Vector2 = (
			Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_AMPLITUDE * fade
		)
		_shake_tween.tween_property(_host, "position", _host_home + offset, step_time)
	_shake_tween.tween_property(_host, "position", _host_home, step_time)


func flash_screen() -> void:
	if _flash_tween:
		_flash_tween.kill()
	if _host.get_node("/root/AccessibilityManager").reduced_flashes:
		_flash_rect.modulate.a = 0.0
		return
	_flash_rect.modulate.a = FLASH_PEAK
	_flash_tween = _host.create_tween()
	_flash_tween.tween_property(_flash_rect, "modulate:a", 0.0, FLASH_SECONDS)


func apply_comfort_settings() -> void:
	var preferences: Node = _host.get_node("/root/AccessibilityManager")
	if preferences.reduced_motion:
		if _shake_tween:
			_shake_tween.kill()
		_host.position = _host_home
		for tween: Tween in [_speaker_tween, _kalin_motion_tween]:
			if tween:
				tween.kill()
		if not sleeping:
			_kalin.position = _kalin_home
			_kalin.rotation = _kalin_rotation
		_kalin.scale = kalin_base_scale
		start_idle()
		if _motion == StoryBeat.KalinMotion.CRUZA:
			if _kalin_idle_tween:
				_kalin_idle_tween.kill()
			_finish_crossing()
		elif _motion == StoryBeat.KalinMotion.PROTECT_BOOK:
			_set_gesture_texture(GESTURE_TEXTURES[_motion])
		elif _motion == StoryBeat.KalinMotion.FAREWELL:
			_set_gesture_texture(FAREWELL_HESITATE)
		if _page_tween:
			_page_tween.kill()
		if _page_motion != StoryBeat.PageMotion.NONE:
			_page.position = _page_home
			_page.rotation = 0.0
			_page.scale = _page_scale
			_page.modulate.a = 1.0
			_page_ink.modulate.a = 1.0 if _page_motion == StoryBeat.PageMotion.RECOVER else 0.0
			_page_word.visible_ratio = 1.0
	if preferences.reduced_flashes:
		if _flash_tween:
			_flash_tween.kill()
		_flash_rect.modulate.a = 0.0


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
	_motion = motion
	_gesture_active = GESTURE_TEXTURES.has(motion)
	if _gesture_active:
		_set_gesture_texture(GESTURE_TEXTURES[motion])
	match motion:
		StoryBeat.KalinMotion.ENTRA:
			_kalin_walk_in()
		StoryBeat.KalinMotion.SALTA:
			_kalin_jump()
		StoryBeat.KalinMotion.TIEMBLA:
			_kalin_shiver()
		StoryBeat.KalinMotion.DORMIDO:
			_kalin_sleep()
		StoryBeat.KalinMotion.CRUZA:
			_kalin_cross_portal()
		StoryBeat.KalinMotion.PROTECT_BOOK:
			_kalin_gesture(Vector2(-9, 5), -0.025, 0.32)
		StoryBeat.KalinMotion.THINK_HOME:
			_kalin_gesture(Vector2(0, 7), 0.025, 0.75)
		StoryBeat.KalinMotion.FAREWELL:
			_kalin_farewell()
		_:
			if not stand_up:
				start_idle()


func set_gesture_texture(texture: Texture2D) -> void:
	_gesture_texture = texture


func has_gesture() -> bool:
	return _gesture_active


func _set_gesture_texture(texture: Texture2D) -> void:
	# Un recorte personalizado conserva su autoría durante todas las fases del gesto.
	_kalin.texture = _gesture_texture if _gesture_texture != null else texture


func _kalin_gesture(offset: Vector2, angle: float, seconds: float) -> void:
	if _host.get_node("/root/AccessibilityManager").reduced_motion:
		return
	_kalin_motion_tween = _host.create_tween().set_parallel(true)
	_kalin_motion_tween.tween_property(_kalin, "position", _kalin_home + offset, seconds)
	_kalin_motion_tween.tween_property(_kalin, "rotation", _kalin_rotation + angle, seconds)


func _kalin_farewell() -> void:
	if _host.get_node("/root/AccessibilityManager").reduced_motion:
		return
	# Mirar a los amigos y abrazar el libro preceden al saludo, sin sonrisa eufórica.
	_kalin_motion_tween = _host.create_tween()
	_kalin_motion_tween.tween_property(_kalin, "rotation", _kalin_rotation + 0.015, 0.45)
	_kalin_motion_tween.tween_interval(0.6)
	_kalin_motion_tween.tween_callback(_set_gesture_texture.bind(FAREWELL_WAVE))
	_kalin_motion_tween.tween_property(_kalin, "rotation", _kalin_rotation - 0.015, 0.35)
	_kalin_motion_tween.tween_property(_kalin, "rotation", _kalin_rotation, 0.4)


func _reach_for_page() -> void:
	if _motion != StoryBeat.KalinMotion.PROTECT_BOOK:
		return
	if _host.get_node("/root/AccessibilityManager").reduced_motion:
		return
	if _kalin_motion_tween:
		_kalin_motion_tween.kill()
	_kalin_motion_tween = _host.create_tween()
	_kalin_motion_tween.tween_interval(0.25)
	_kalin_motion_tween.tween_callback(_set_gesture_texture.bind(REACH_PAGE))
	_kalin_motion_tween.tween_property(_kalin, "rotation", _kalin_rotation + 0.045, 0.35)
	_kalin_motion_tween.tween_interval(0.5)
	_kalin_motion_tween.tween_callback(
		_set_gesture_texture.bind(GESTURE_TEXTURES[StoryBeat.KalinMotion.PROTECT_BOOK])
	)
	_kalin_motion_tween.tween_property(_kalin, "rotation", _kalin_rotation, 0.4)


func present_page(motion: StoryBeat.PageMotion, word: String) -> void:
	if _page_tween:
		_page_tween.kill()
	_page_motion = motion
	_page.visible = motion != StoryBeat.PageMotion.NONE
	_page.position = _page_home
	_page.scale = _page_scale
	_page.rotation = 0.0
	_page.modulate.a = 1.0
	_page_word.text = word
	_page_word.visible_ratio = 0.0
	_page_ink.modulate.a = 0.0
	if motion == StoryBeat.PageMotion.NONE:
		return
	if _host.get_node("/root/AccessibilityManager").reduced_motion:
		_page_ink.modulate.a = 1.0 if motion == StoryBeat.PageMotion.RECOVER else 0.0
		_page_word.visible_ratio = 1.0
		return
	_page_tween = _host.create_tween()
	if motion == StoryBeat.PageMotion.SCATTER:
		_reach_for_page()
		_page.position = Vector2(145, 390)
		_page.scale = _page_scale * 0.6
		_page_tween.set_parallel(true)
		_page_tween.tween_property(_page, "position", _page_home, 0.75).set_trans(Tween.TRANS_SINE)
		_page_tween.tween_property(_page, "scale", _page_scale, 0.75)
		_page_tween.tween_property(_page, "rotation", -0.18, 0.75)
		_page_tween.chain().tween_interval(0.4)
		_page_tween.chain().tween_property(_page, "position", Vector2(1360, 95), 1.2)
		_page_tween.parallel().tween_property(_page, "rotation", 0.65, 1.2)
		_page_tween.parallel().tween_property(_page, "modulate:a", 0.0, 0.4).set_delay(0.8)
	else:
		_page.rotation = -0.09
		_page_tween.tween_property(_page, "rotation", 0.0, 0.35)
		_page_tween.tween_property(_page_ink, "modulate:a", 1.0, 0.7)
		_page_tween.parallel().tween_property(_page_word, "visible_ratio", 1.0, 0.7)
		_page_tween.tween_interval(0.75)
		_page_tween.tween_property(_page, "position", Vector2(112, 470), 0.7)
		_page_tween.parallel().tween_property(_page, "scale", _page_scale * 0.25, 0.7)
		_page_tween.parallel().tween_property(_page, "modulate:a", 0.0, 0.3).set_delay(0.4)


func _reset_kalin(animated: bool) -> void:
	for tween: Tween in [_kalin_motion_tween, _kalin_idle_tween, _speaker_tween]:
		if tween:
			tween.kill()
	sleeping = false
	_kalin.modulate.a = _kalin_alpha
	_kalin.z_index = _kalin_z_index
	if animated:
		_kalin_motion_tween = _host.create_tween().set_parallel(true)
		_kalin_motion_tween.tween_property(_kalin, "position", _kalin_home, STAND_UP_SECONDS)
		_kalin_motion_tween.tween_property(_kalin, "rotation", _kalin_rotation, STAND_UP_SECONDS)
		_kalin_motion_tween.tween_property(_kalin, "scale", kalin_base_scale, STAND_UP_SECONDS)
		_kalin_motion_tween.chain().tween_callback(start_idle)
		return
	_kalin.position = _kalin_home
	_kalin.rotation = _kalin_rotation
	_kalin.scale = kalin_base_scale


func animate_speaker() -> void:
	if _kalin_motion_tween and _kalin_motion_tween.is_running():
		return
	if _speaker_tween:
		_speaker_tween.kill()
	_speaker_tween = _host.create_tween()
	_speaker_tween.tween_property(
		_kalin,
		"scale",
		(
			kalin_base_scale
			if _host.get_node("/root/AccessibilityManager").reduced_motion
			else kalin_base_scale * 1.04
		),
		0.12
	)
	_speaker_tween.tween_property(_kalin, "scale", kalin_base_scale, 0.18)


func _kalin_walk_in() -> void:
	_kalin.position.x = _kalin_home.x - WALK_DISTANCE
	_kalin_motion_tween = _host.create_tween()
	_kalin_motion_tween.tween_method(_walk_step, 0.0, 1.0, WALK_SECONDS)
	_kalin_motion_tween.tween_callback(start_idle)


func _walk_step(progress: float) -> void:
	var stride: float = (
		0.0
		if _host.get_node("/root/AccessibilityManager").reduced_motion
		else sin(progress * TAU * WALK_STEPS)
	)
	_kalin.position.x = lerpf(
		_kalin_home.x - WALK_DISTANCE, _kalin_home.x, sin(progress * PI * 0.5)
	)
	_kalin.position.y = _kalin_home.y - absf(stride) * WALK_BOUNCE
	_kalin.rotation = _kalin_rotation + stride * WALK_TILT


func _kalin_jump() -> void:
	_kalin_motion_tween = _host.create_tween()
	for _jump: int in range(JUMP_COUNT):
		(
			_kalin_motion_tween
			. tween_property(
				_kalin,
				"position:y",
				(
					_kalin_home.y
					- (
						0.0
						if _host.get_node("/root/AccessibilityManager").reduced_motion
						else JUMP_HEIGHT
					)
				),
				0.18
			)
			. set_trans(Tween.TRANS_QUAD)
			. set_ease(Tween.EASE_OUT)
		)
		(
			_kalin_motion_tween
			. tween_property(_kalin, "position:y", _kalin_home.y, 0.22)
			. set_trans(Tween.TRANS_BOUNCE)
			. set_ease(Tween.EASE_OUT)
		)
	_kalin_motion_tween.tween_callback(start_idle)


func _kalin_shiver() -> void:
	_kalin_motion_tween = _host.create_tween()
	for repeat: int in range(SHIVER_REPEATS):
		var direction: float = 1.0 if repeat % 2 == 0 else -1.0
		_kalin_motion_tween.tween_property(
			_kalin,
			"position:x",
			(
				_kalin_home.x
				+ (
					direction
					* (
						0.0
						if _host.get_node("/root/AccessibilityManager").reduced_motion
						else SHIVER_DISTANCE
					)
				)
			),
			0.04
		)
	_kalin_motion_tween.tween_property(_kalin, "position:x", _kalin_home.x, 0.04)
	_kalin_motion_tween.tween_callback(start_idle)


func _kalin_sleep() -> void:
	sleeping = true
	_kalin.rotation = _kalin_rotation - SLEEP_ANGLE
	_kalin.position = SLEEP_POSITION
	_kalin_motion_tween = _host.create_tween().set_loops()
	(
		_kalin_motion_tween
		. tween_property(
			_kalin,
			"scale",
			(
				kalin_base_scale
				if _host.get_node("/root/AccessibilityManager").reduced_motion
				else kalin_base_scale * BREATH_SCALE
			),
			1.6
		)
		. set_trans(Tween.TRANS_SINE)
	)
	_kalin_motion_tween.tween_property(_kalin, "scale", kalin_base_scale, 1.6).set_trans(
		Tween.TRANS_SINE
	)


func _kalin_cross_portal() -> void:
	_kalin.z_index = _kalin_z_index + 1
	if _host.get_node("/root/AccessibilityManager").reduced_motion:
		_finish_crossing()
		return
	_kalin_motion_tween = _host.create_tween()
	_kalin_motion_tween.tween_method(_cross_portal_step, 0.0, 1.0, CROSS_SECONDS)


func _cross_portal_step(progress: float) -> void:
	# La pausa a mitad de camino permite mirar atrás antes de atravesar la luz.
	var travel: float = (
		progress * 1.5
		if progress < 0.4
		else (0.6 if progress < 0.58 else lerpf(0.6, 1.0, (progress - 0.58) / 0.42))
	)
	var stride: float = 0.0 if progress >= 0.4 and progress < 0.58 else sin(travel * PI * 5.0)
	var target: Vector2 = PORTAL_CENTER - _kalin.pivot_offset
	_kalin.position = _kalin_home.lerp(target, travel)
	_kalin.position.y -= absf(stride) * 9.0 * (1.0 - travel * 0.5)
	_kalin.rotation = _kalin_rotation + stride * 0.025
	_kalin.scale = kalin_base_scale * lerpf(1.0, CROSS_SCALE, travel)
	_kalin.modulate.a = _kalin_alpha * (1.0 - smoothstep(0.82, 1.0, travel))
	_set_gesture_texture(PORTAL_LOOK_BACK if progress >= 0.4 and progress < 0.58 else PORTAL_STEP)


func _finish_crossing() -> void:
	_kalin.position = PORTAL_CENTER - _kalin.pivot_offset
	_kalin.rotation = _kalin_rotation
	_kalin.scale = kalin_base_scale * CROSS_SCALE
	_kalin.modulate.a = 0.0
