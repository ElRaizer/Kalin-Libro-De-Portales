## Escena de exploración reutilizable. Kalin camina por un sendero lineal de la
## isla (la cámara lo sigue y el cielo se mueve más despacio, con parallax),
## examina objetos (ExplorationSpot) y al llegar a la meta empieza el capítulo
## de historia indicado en `next_scene_key`.
##   Controles: ← → o A D para caminar, clic o toque para ir a un punto,
##   E / Espacio / Enter para examinar y avanzar el diálogo, Esc para saltar.
## Cada exploración hereda esta escena: dibuja su terreno, ajusta el Path2D
## «Sendero» y coloca instancias de ExplorationSpot dentro de «Spots», todo
## desde el editor y sin escribir código.
extends Node2D
class_name ExplorationScene

const KALIN_NORMAL: Texture2D = preload("res://Arte/sprites/kalin_normal.svg")
const KALIN_SURPRISED: Texture2D = preload("res://Arte/sprites/kalin_surprised.svg")
const ARRIVE_DISTANCE := 8.0
const STEP_LENGTH := 70.0                  # píxeles recorridos en cada zancada
const WALK_BOUNCE := 9.0
const WALK_TILT := 0.06
const BREATH_SPEED := 2.4
const BREATH_SCALE := 0.015
const BLOCK_MARGIN := 120.0                # Kalin se detiene antes de un obstáculo
const CHAR_REVEAL_SECONDS := 0.022
const FADE_SECONDS := 0.6
const ARROW_BOB := 10.0
const ARROW_SPEED := 4.0
const ANIMAL_HOP := 8.0
const ANIMAL_HOP_SPEED := 3.2
const NOTICE_SECONDS := 2.6
const PROMPT_ABOVE_KALIN := 18.0           # el botón nunca tapa la cara de Kalin
const COLOR_HINT := Color("f5e6b8")
const COLOR_NOTICE := Color("ffd27a")

@export_category("Exploración")
@export var chapter_title: String = "Mundo 1 · Exploración"
@export var next_scene_key: String = "world1_story1"
## Meta que se muestra en el panel inferior izquierdo.
@export var objective_text: String = "Sigue el sendero."
@export_range(80.0, 600.0, 10.0) var walk_speed: float = 300.0

@export_category("Entrada")
## Diálogo opcional que aparece al empezar, antes de que Kalin pueda caminar.
@export var intro_speaker: String = "Kalin"
@export var intro_lines: Array[String] = []
@export var intro_surprised: bool = false

# ─── Estado ──────────────────────────────────────────────────────────────────
var spots: Array[ExplorationSpot] = []
var discovered: int = 0
var _ground_points: PackedVector2Array = PackedVector2Array()
var _ground_xs: PackedFloat32Array = PackedFloat32Array()
var _min_x: float = 0.0
var _max_x: float = 0.0
var _has_target: bool = false
var _target_x: float = 0.0
var _pending_spot: ExplorationSpot
var _nearby_spot: ExplorationSpot
var _active_spot: ExplorationSpot
var _dialogue_lines: Array[String] = []
var _dialogue_speaker: String = ""
var _line_index: int = -1
var _dialogue_open: bool = false
var _resolving: bool = false
var _navigating: bool = false
var _walk_phase: float = 0.0
var _time: float = 0.0
var _animal_bases: Dictionary = {}         # Sprite2D -> posición en reposo
var _arrow_base_x: float = 0.0
var _text_tween: Tween
var _notice_tween: Tween

# ─── Nodos ───────────────────────────────────────────────────────────────────
@onready var sendero: Path2D = $Sendero
@onready var spots_root: Node2D = $Spots
@onready var animals_root: Node2D = $Animales
@onready var kalin: Node2D = $Kalin
@onready var kalin_sprite: Sprite2D = $Kalin/Sprite
@onready var camera: Camera2D = $Kalin/Camera
@onready var magic: CPUParticles2D = $Kalin/Magia
@onready var chapter_label: Label = $UI/ChapterPanel/ChapterLabel
@onready var skip_button: Button = $UI/SkipButton
@onready var objective_label: Label = $UI/ObjectivePanel/Content/ObjectiveLabel
@onready var counter_label: Label = $UI/ObjectivePanel/Content/CounterLabel
@onready var controls_label: Label = $UI/ControlsLabel
@onready var prompt_button: Button = $UI/PromptButton
@onready var arrow: TextureRect = $UI/Flecha
@onready var dialogue_box: Panel = $UI/DialogueBox
@onready var speaker_label: Label = $UI/DialogueBox/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $UI/DialogueBox/DialogueText
@onready var hint_label: Label = $UI/DialogueBox/HintLabel
@onready var fade: ColorRect = $UI/Fade

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	chapter_label.text = chapter_title
	objective_label.text = objective_text
	skip_button.pressed.connect(_finish)
	prompt_button.pressed.connect(_on_prompt_pressed)
	dialogue_box.hide()
	prompt_button.hide()
	_arrow_base_x = arrow.position.x
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, FADE_SECONDS)
	_collect_spots()
	_build_ground()
	_configure_camera()
	for animal: Node in animals_root.get_children():
		if animal is Sprite2D:
			_animal_bases[animal] = (animal as Sprite2D).position
	_place_kalin(_min_x)
	_update_counter()
	if not intro_lines.is_empty():
		_start_dialogue(intro_speaker, intro_lines, intro_surprised)

func _process(delta: float) -> void:
	_time += delta
	walk(Input.get_axis(&"kalin_izquierda", &"kalin_derecha"), delta)
	_update_nearby_spot()
	_update_arrow()
	_animate_animals()

func _unhandled_input(event: InputEvent) -> void:
	if _navigating:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_finish()
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if _dialogue_open:
		if is_click or event.is_action_pressed(&"kalin_interactuar"):
			get_viewport().set_input_as_handled()
			advance_dialogue()
		return
	if _resolving:
		return
	if event.is_action_pressed(&"kalin_interactuar"):
		if _nearby_spot != null:
			get_viewport().set_input_as_handled()
			open_spot(_nearby_spot)
		return
	if is_click:
		get_viewport().set_input_as_handled()
		_walk_to_point(get_global_mouse_position())

# ─── Sendero ─────────────────────────────────────────────────────────────────
func _collect_spots() -> void:
	for child: Node in spots_root.get_children():
		if child is ExplorationSpot:
			spots.append(child)
	spots.sort_custom(_sort_by_x)

func _sort_by_x(a: ExplorationSpot, b: ExplorationSpot) -> bool:
	return a.global_position.x < b.global_position.x

## Convierte el Path2D en una lista de puntos ordenados por x para saber a qué
## altura van los pies de Kalin en cualquier parte del camino.
func _build_ground() -> void:
	for point: Vector2 in sendero.curve.get_baked_points():
		var world_point: Vector2 = sendero.to_global(point)
		if not _ground_xs.is_empty() and world_point.x <= _ground_xs[_ground_xs.size() - 1]:
			continue
		_ground_points.append(world_point)
		_ground_xs.append(world_point.x)
	_min_x = _ground_xs[0]
	_max_x = _ground_xs[_ground_xs.size() - 1]

func ground_y(x: float) -> float:
	var index: int = clampi(_ground_xs.bsearch(x), 1, _ground_xs.size() - 1)
	var a: Vector2 = _ground_points[index - 1]
	var b: Vector2 = _ground_points[index]
	var t: float = clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0)
	return lerpf(a.y, b.y, t)

func _configure_camera() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_bottom = int(viewport_size.y)
	camera.limit_right = int(maxf(_max_x + viewport_size.x * 0.1, viewport_size.x))

## Límite derecho actual: el primer obstáculo sin resolver o el final.
func walk_limit() -> float:
	var limit: float = _max_x
	for spot: ExplorationSpot in spots:
		if spot.is_blocking():
			limit = minf(limit, spot.global_position.x - BLOCK_MARGIN)
	return limit

# ─── Movimiento de Kalin ─────────────────────────────────────────────────────
func _can_walk() -> bool:
	return not (_navigating or _dialogue_open or _resolving)

## Mueve a Kalin en la dirección indicada (-1 izquierda, 1 derecha). Si no hay
## dirección, sigue hacia el destino elegido con clic, si lo hay. Durante un
## diálogo, una animación o el cambio de escena Kalin se queda quieto.
func walk(direction: float, delta: float) -> void:
	if not _can_walk():
		_idle()
		return
	if direction != 0.0:
		_has_target = false
		_pending_spot = null
	elif _has_target:
		var distance: float = _target_x - kalin.position.x
		if absf(distance) <= ARRIVE_DISTANCE:
			_has_target = false
			_on_arrived()
			return
		direction = signf(distance)
	if direction == 0.0:
		_idle()
		return
	var limit: float = walk_limit()
	var new_x: float = clampf(kalin.position.x + direction * walk_speed * delta, _min_x, limit)
	if _has_target:
		new_x = clampf(new_x, minf(kalin.position.x, _target_x), maxf(kalin.position.x, _target_x))
	var moved: float = absf(new_x - kalin.position.x)
	kalin_sprite.flip_h = direction < 0.0
	if moved < 0.01:
		if direction > 0.0 and limit < _max_x:
			_show_notice("Algo bloquea el camino. ¡Examínalo!")
		_has_target = false
		_idle()
		return
	_place_kalin(new_x)
	_walk_phase += moved / STEP_LENGTH * PI
	var stride: float = sin(_walk_phase)
	kalin_sprite.position.y = -absf(stride) * WALK_BOUNCE
	kalin_sprite.rotation = stride * WALK_TILT
	kalin_sprite.scale = Vector2.ONE
	_check_auto_trigger()

func _place_kalin(x: float) -> void:
	kalin.position = Vector2(x, ground_y(x))

func _idle() -> void:
	kalin_sprite.position.y = lerpf(kalin_sprite.position.y, 0.0, 0.3)
	kalin_sprite.rotation = lerpf(kalin_sprite.rotation, 0.0, 0.3)
	var breath: float = 1.0 + sin(_time * BREATH_SPEED) * BREATH_SCALE
	kalin_sprite.scale = Vector2(1.0, breath)

func _walk_to_point(world_point: Vector2) -> void:
	_pending_spot = null
	for spot: ExplorationSpot in spots:
		if spot.can_interact() and spot.contains_point(world_point):
			_pending_spot = spot
			world_point.x = spot.global_position.x - signf(spot.global_position.x - kalin.position.x) * spot.reach_radius * 0.5
			break
	_target_x = clampf(world_point.x, _min_x, _max_x)
	_has_target = true

func _on_arrived() -> void:
	if _pending_spot == null:
		return
	var spot: ExplorationSpot = _pending_spot
	_pending_spot = null
	if _is_within_reach(spot):
		open_spot(spot)

func _face(x: float) -> void:
	kalin_sprite.flip_h = x < kalin.position.x

# ─── Objetos ─────────────────────────────────────────────────────────────────
func _is_within_reach(spot: ExplorationSpot) -> bool:
	return absf(spot.global_position.x - kalin.position.x) <= spot.reach_radius

func _update_nearby_spot() -> void:
	_nearby_spot = null
	if _can_walk():
		var best_distance: float = INF
		for spot: ExplorationSpot in spots:
			var distance: float = absf(spot.global_position.x - kalin.position.x)
			if spot.can_interact() and distance <= spot.reach_radius and distance < best_distance:
				best_distance = distance
				_nearby_spot = spot
	prompt_button.visible = _nearby_spot != null
	if _nearby_spot == null:
		return
	prompt_button.text = "E · %s" % _nearby_spot.prompt
	var anchor: Vector2 = _nearby_spot.prompt_anchor()
	anchor.y = minf(anchor.y, _kalin_top() - PROMPT_ABOVE_KALIN)
	var screen_point: Vector2 = get_viewport().get_canvas_transform() * anchor
	prompt_button.position = screen_point - Vector2(prompt_button.size.x * 0.5, prompt_button.size.y)

func _kalin_top() -> float:
	return kalin.global_position.y - kalin_sprite.texture.get_height() * kalin_sprite.scale.y

func _check_auto_trigger() -> void:
	for spot: ExplorationSpot in spots:
		if spot.auto_trigger and not spot.examined and _is_within_reach(spot):
			open_spot(spot)
			return

func _on_prompt_pressed() -> void:
	if _nearby_spot != null and _can_walk():
		open_spot(_nearby_spot)

func open_spot(spot: ExplorationSpot) -> void:
	if not _can_walk():
		return
	_active_spot = spot
	_has_target = false
	_pending_spot = null
	_face(spot.global_position.x)
	_start_dialogue(spot.speaker, spot.lines, spot.surprised)

func _close_spot(spot: ExplorationSpot) -> void:
	var first_time: bool = not spot.examined
	spot.mark_examined()
	if spot.is_goal:
		_finish()
		return
	if not first_time:
		return
	discovered += 1
	_update_counter()
	var tween: Tween = spot.play_reaction(kalin.global_position + Vector2(0.0, -120.0))
	if tween == null:
		return
	_resolving = true
	magic.restart()
	tween.finished.connect(_on_reaction_finished)

func _on_reaction_finished() -> void:
	_resolving = false

func _update_counter() -> void:
	var total: int = 0
	for spot: ExplorationSpot in spots:
		if not spot.is_goal:
			total += 1
	counter_label.text = "Descubrimientos: %d / %d" % [discovered, total]
	counter_label.visible = total > 0

func _show_notice(text: String) -> void:
	if _notice_tween and _notice_tween.is_running():
		return
	objective_label.text = text
	objective_label.add_theme_color_override("font_color", COLOR_NOTICE)
	_notice_tween = create_tween()
	_notice_tween.tween_interval(NOTICE_SECONDS)
	_notice_tween.tween_callback(_restore_objective)

func _restore_objective() -> void:
	objective_label.text = objective_text
	objective_label.remove_theme_color_override("font_color")

# ─── Diálogo ─────────────────────────────────────────────────────────────────
func _start_dialogue(speaker: String, lines: Array[String], surprised: bool) -> void:
	_dialogue_open = true
	_dialogue_speaker = speaker
	_dialogue_lines = lines
	_line_index = -1
	kalin_sprite.texture = KALIN_SURPRISED if surprised else KALIN_NORMAL
	speaker_label.text = _speaker_name(speaker)
	speaker_label.visible = speaker_label.text != ""
	hint_label.text = "▶ Continuar"
	hint_label.add_theme_color_override("font_color", COLOR_HINT)
	dialogue_box.show()
	prompt_button.hide()
	_next_line()

func advance_dialogue() -> void:
	if not _dialogue_open:
		return
	if _text_tween != null and _text_tween.is_running():
		_text_tween.kill()
		dialogue_text.visible_ratio = 1.0
		return
	_next_line()

func is_dialogue_open() -> bool:
	return _dialogue_open

func _next_line() -> void:
	_line_index += 1
	if _line_index >= _dialogue_lines.size():
		_end_dialogue()
		return
	var text: String = _dialogue_lines[_line_index]
	if _text_tween:
		_text_tween.kill()
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0
	_text_tween = create_tween()
	_text_tween.tween_property(dialogue_text, "visible_ratio", 1.0, text.length() * CHAR_REVEAL_SECONDS)

func _end_dialogue() -> void:
	_dialogue_open = false
	dialogue_box.hide()
	kalin_sprite.texture = KALIN_NORMAL
	var spot: ExplorationSpot = _active_spot
	_active_spot = null
	if spot != null:
		_close_spot(spot)

func _speaker_name(speaker: String) -> String:
	if speaker == "" or speaker == "Narrador":
		return ""
	if speaker == "Kalin":
		return "Kalin"
	var entry: Dictionary = GameManager.get_vocabulary_entry(speaker)
	if entry.is_empty():
		return speaker
	return "%s · %s" % [speaker, entry.spanish]

# ─── Ambiente ────────────────────────────────────────────────────────────────
func _update_arrow() -> void:
	var goal_ahead: bool = false
	for spot: ExplorationSpot in spots:
		if spot.is_goal and spot.global_position.x > kalin.position.x + get_viewport_rect().size.x * 0.4:
			goal_ahead = true
	arrow.visible = goal_ahead and _can_walk() and _nearby_spot == null
	arrow.position.x = _arrow_base_x + sin(_time * ARROW_SPEED) * ARROW_BOB

func _animate_animals() -> void:
	var index: int = 0
	for animal: Sprite2D in _animal_bases:
		var base: Vector2 = _animal_bases[animal]
		var hop: float = absf(sin(_time * ANIMAL_HOP_SPEED + index * 1.3))
		animal.position = base + Vector2(0.0, -hop * ANIMAL_HOP)
		index += 1

# ─── Navegación ──────────────────────────────────────────────────────────────
func _finish() -> void:
	if _navigating:
		return
	_navigating = true
	_dialogue_open = false
	dialogue_box.hide()
	prompt_button.hide()
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(_go_to_next_scene)

func _go_to_next_scene() -> void:
	GameManager.go_to_scene(next_scene_key)
