## Escena de exploración reutilizable. Kalin camina por un sendero lineal de la
## isla (la cámara lo sigue y el cielo se mueve más despacio, con parallax),
## examina objetos (ExplorationSpot) y al llegar a la meta empieza el capítulo
## de historia indicado en `next_scene_key`.
##   Controles: ← → o A D para caminar, clic o toque para ir a un punto,
##   E / Espacio / Enter para examinar y avanzar el diálogo, Esc para pausar.
## Cada exploración hereda esta escena: dibuja su terreno, ajusta el Path2D
## «Sendero» y coloca instancias de ExplorationSpot dentro de «Spots», todo
## desde el editor y sin escribir código.
extends Node2D
class_name ExplorationScene

@export var normal_texture: Texture2D
@export var surprised_texture: Texture2D
const DIALOGUE_PRESENTER = preload("res://scripts/features/exploration/dialogue_presenter.gd")
const ARRIVE_DISTANCE := 8.0
const STEP_LENGTH := 70.0  # píxeles recorridos en cada zancada
const WALK_BOUNCE := 9.0
const WALK_TILT := 0.06
const BREATH_SPEED := 2.4
const BREATH_SCALE := 0.015
const BLOCK_MARGIN := 120.0  # Kalin se detiene antes de un obstáculo
const CHAR_REVEAL_SECONDS := 0.022
const FADE_SECONDS := 0.6
const ARROW_BOB := 10.0
const ARROW_SPEED := 4.0
const ANIMAL_HOP := 8.0
const ANIMAL_HOP_SPEED := 3.2
const NOTICE_SECONDS := 2.6
const PROMPT_ABOVE_KALIN := 18.0  # el botón nunca tapa la cara de Kalin
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

@export_category("Sonido")
## Suelo que pisa Kalin; elige la familia de pasos del catálogo de audio.
@export_enum("arena", "tierra", "pasto", "piedra") var footstep_surface: String = "tierra"

# ─── Estado ──────────────────────────────────────────────────────────────────
var spots: Array[ExplorationSpot] = []
var discovered: int = 0
## Palabras mayas anotadas en este recorrido (objetos con `vocabulary_word`).
var words_found: int = 0
var _ground_points: PackedVector2Array = PackedVector2Array()
var _ground_xs: PackedFloat32Array = PackedFloat32Array()
var _min_x: float = 0.0
var _max_x: float = 0.0
var _has_target: bool = false
var _target_x: float = 0.0
var _pending_spot: ExplorationSpot
var _nearby_spot: ExplorationSpot
var _active_spot: ExplorationSpot
var _resolving: bool = false
var _navigating: bool = false
var _walk_phase: float = 0.0
var _time: float = 0.0
var _animal_bases: Dictionary = {}  # Sprite2D -> posición en reposo
var _arrow_base_x: float = 0.0
var _notice_tween: Tween
var _dialogue: DialoguePresenter
var _intro_done: bool = false
var guide: LearningGuide
@onready var continue_button: Button = $UI/ContinueButton
var _kalin_base_scale: Vector2
var _kalin_base_position: Vector2
var _kalin_base_rotation: float
var _objective_color: Color

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
	_objective_color = objective_label.get_theme_color("font_color")
	_dialogue = DIALOGUE_PRESENTER.new(
		self,
		dialogue_box,
		speaker_label,
		dialogue_text,
		hint_label,
		_speaker_name,
		_set_dialogue_pose,
		_on_dialogue_finished,
		CHAR_REVEAL_SECONDS
	)
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
	guide = $LearningGuide
	add_to_group("comfort_visuals")
	_kalin_base_scale = kalin_sprite.scale
	_kalin_base_position = kalin_sprite.position
	_kalin_base_rotation = kalin_sprite.rotation
	continue_button.pressed.connect(advance_dialogue)
	$UI/HelpButton.pressed.connect(_show_help)
	$UI/MenuButton.pressed.connect(_on_menu_pressed)
	var state: Dictionary = GameManager.get_scene_state(self)
	var examined: Variant = state.get("examined", [])
	for spot: ExplorationSpot in spots:
		if examined is Array and str(spot.name) in examined:
			spot.mark_examined()
			if spot.reaction != ExplorationSpot.Reaction.NINGUNA:
				spot.sprite.hide()
			if not spot.is_goal:
				discovered += 1
			if spot.teaches_word():
				words_found += 1
	_place_kalin(clampf(float(state.get("x", _min_x)), _min_x, walk_limit()))
	camera.reset_smoothing()
	_intro_done = bool(state.get("intro_done", false))
	_update_counter()
	var active_name: String = str(state.get("active", ""))
	for spot: ExplorationSpot in spots:
		if (
			str(spot.name) == active_name
			and (
				not spot.examined
				or spot.has_meta("village_neighbour")
				or spot.has_meta("village_resident")
			)
		):
			open_spot(spot)
			break
	if not _dialogue.is_open() and not _intro_done and not intro_lines.is_empty():
		_start_dialogue(intro_speaker, intro_lines, intro_surprised)
	if _dialogue.is_open():
		_dialogue.restore_line(int(state.get("line", 0)))
	else:
		call_deferred("_show_help")


func _process(delta: float) -> void:
	continue_button.visible = is_dialogue_open()
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
		PauseMenu.open_pause()
		return
	var is_click: bool = (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	)
	if _dialogue.is_open():
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
	var terrain: Sprite2D = $Terreno as Sprite2D
	var terrain_bounds: Rect2 = terrain.get_global_transform() * terrain.get_rect()
	# Sólo completar los límites sin configurar; los del Inspector tienen prioridad.
	if camera.limit_left == -10000000:
		camera.limit_left = ceili(terrain_bounds.position.x)
	if camera.limit_top == -10000000:
		camera.limit_top = 0
	if camera.limit_bottom == 10000000:
		camera.limit_bottom = int(viewport_size.y)
	if camera.limit_right == 10000000:
		camera.limit_right = floori(terrain_bounds.end.x)


## Límite derecho actual: el primer obstáculo sin resolver o el final.
func walk_limit() -> float:
	var limit: float = _max_x
	for spot: ExplorationSpot in spots:
		if spot.is_blocking():
			limit = minf(limit, spot.global_position.x - BLOCK_MARGIN)
	return limit


# ─── Movimiento de Kalin ─────────────────────────────────────────────────────
func _can_walk() -> bool:
	return not (_navigating or _dialogue.is_open() or _resolving)


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
			if not (_notice_tween and _notice_tween.is_running()):
				AudioManager.play_sfx("camino_bloqueado")
			_show_notice("Algo bloquea el camino. ¡Examínalo!")
		_has_target = false
		_idle()
		return
	guide.stop()
	_place_kalin(new_x)
	var previous_step: int = int(_walk_phase / PI)
	_walk_phase += moved / STEP_LENGTH * PI
	# Un paso suena cada vez que Kalin apoya el pie (media vuelta de la zancada).
	if int(_walk_phase / PI) != previous_step:
		AudioManager.play_footstep(footstep_surface)
	var stride: float = (
		0.0 if get_node("/root/AccessibilityManager").reduced_motion else sin(_walk_phase)
	)
	# La ilustración se desplaza entera: saltitos y balanceo de recorte.
	kalin_sprite.position.y = _kalin_base_position.y - absf(stride) * WALK_BOUNCE
	kalin_sprite.rotation = _kalin_base_rotation + stride * WALK_TILT
	kalin_sprite.scale = _kalin_base_scale
	_check_auto_trigger()


func _place_kalin(x: float) -> void:
	kalin.position = Vector2(x, ground_y(x))


func _idle() -> void:
	kalin_sprite.position.y = lerpf(kalin_sprite.position.y, _kalin_base_position.y, 0.3)
	kalin_sprite.rotation = lerpf(kalin_sprite.rotation, _kalin_base_rotation, 0.3)
	var breath: float = (
		1.0
		if get_node("/root/AccessibilityManager").reduced_motion
		else 1.0 + sin(_time * BREATH_SPEED) * BREATH_SCALE
	)
	kalin_sprite.scale = _kalin_base_scale * Vector2(1.0, breath)


func apply_comfort_settings() -> void:
	var preferences: Node = get_node("/root/AccessibilityManager")
	if preferences.reduced_motion:
		_idle()
	if preferences.instant_text and _dialogue.is_open():
		if _dialogue.text_tween and _dialogue.text_tween.is_valid():
			_dialogue.text_tween.kill()
		dialogue_text.visible_ratio = 1.0


func _walk_to_point(world_point: Vector2) -> void:
	_pending_spot = null
	for spot: ExplorationSpot in spots:
		if spot.can_interact() and spot.contains_point(world_point):
			_pending_spot = spot
			world_point.x = (
				spot.global_position.x
				- signf(spot.global_position.x - kalin.position.x) * spot.reach_radius * 0.8
			)
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
	prompt_button.text = _nearby_spot.prompt
	prompt_button.tooltip_text = "Clic o E para interactuar"
	var anchor: Vector2 = _nearby_spot.prompt_anchor()
	anchor.y = minf(anchor.y, _kalin_top() - PROMPT_ABOVE_KALIN)
	var screen_point: Vector2 = get_viewport().get_canvas_transform() * anchor
	prompt_button.position = (
		screen_point - Vector2(prompt_button.size.x * 0.5, prompt_button.size.y)
	)


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
	var village_dialogue: VillageDialogue = get_node_or_null("VillageDialogue") as VillageDialogue
	if village_dialogue:
		village_dialogue.prepare(spot)
	_active_spot = spot
	_has_target = false
	_pending_spot = null
	_face(spot.global_position.x)
	if spot.has_meta("village_neighbour") or spot.has_meta("village_resident"):
		AudioManager.play_sfx("animal_tocar")
	elif not spot.is_goal:
		AudioManager.play_sfx("examinar_objeto")
	_start_dialogue(spot.speaker, spot.dialogue_lines(), spot.surprised)


func _close_spot(spot: ExplorationSpot) -> void:
	var first_time: bool = not spot.examined
	spot.mark_examined()
	if spot.is_goal:
		AudioManager.play_sfx("meta_alcanzada")
		_finish()
		return
	if not first_time:
		return
	discovered += 1
	if spot.name == &"Pagina":
		_show_notice("¡Encontraste tu libro! Las palabras volverán con tus hechizos.")
	if spot.teaches_word():
		words_found += 1
		AudioManager.play_sfx("palabra_anotada")
		_show_notice("Anotaste «%s» en tu libro" % spot.vocabulary_word, true)
	_update_counter()
	var tween: Tween = spot.play_reaction(kalin.global_position + Vector2(0.0, -120.0))
	if tween == null:
		return
	_resolving = true
	magic.restart()
	AudioManager.play_sfx(
		"magia_apartar" if spot.reaction == ExplorationSpot.Reaction.APARTAR else "recoger_objeto"
	)
	tween.finished.connect(_on_reaction_finished)


func _on_reaction_finished() -> void:
	_resolving = false


func _update_counter() -> void:
	var total: int = 0
	var total_words: int = 0
	for spot: ExplorationSpot in spots:
		if not spot.is_goal:
			total += 1
		if spot.teaches_word():
			total_words += 1
	counter_label.text = "Descubrimientos: %d / %d" % [discovered, total]
	if total_words > 0:
		counter_label.text += "   ·   Palabras mayas: %d / %d" % [words_found, total_words]
	counter_label.visible = total > 0


## Muestra un aviso breve sobre la meta. Los avisos de vocabulario reemplazan al
## anterior para que cada palabra anotada se vea completa.
func _show_notice(text: String, replace_current: bool = false) -> void:
	if _notice_tween and _notice_tween.is_running():
		if not replace_current:
			return
		_notice_tween.kill()
	objective_label.text = text
	objective_label.add_theme_color_override("font_color", COLOR_NOTICE)
	_notice_tween = create_tween()
	_notice_tween.tween_interval(NOTICE_SECONDS)
	_notice_tween.tween_callback(_restore_objective)


func _restore_objective() -> void:
	objective_label.text = objective_text
	objective_label.add_theme_color_override("font_color", _objective_color)


# ─── Diálogo ─────────────────────────────────────────────────────────────────
func _start_dialogue(speaker: String, lines: Array[String], surprised: bool) -> void:
	_dialogue.start(speaker, lines, surprised)
	prompt_button.hide()


func advance_dialogue() -> void:
	var text_complete: bool = _dialogue.text_tween == null or not _dialogue.text_tween.is_running()
	if _dialogue.is_open() and text_complete:
		AudioManager.play_sfx("dialogo_avanzar")
	_dialogue.advance()


func is_dialogue_open() -> bool:
	return _dialogue.is_open()


func _set_dialogue_pose(surprised: bool) -> void:
	kalin_sprite.texture = surprised_texture if surprised else normal_texture


func _on_dialogue_finished() -> void:
	if is_instance_valid(continue_button):
		continue_button.hide()
	var spot: ExplorationSpot = _active_spot
	_active_spot = null
	if spot != null:
		var village_dialogue: VillageDialogue = (
			get_node_or_null("VillageDialogue") as VillageDialogue
		)
		if village_dialogue:
			village_dialogue.finish(spot)
		_close_spot(spot)
	else:
		_intro_done = true
		_show_help()
	GameManager.checkpoint(self)


func _speaker_name(speaker: String) -> String:
	if speaker == "" or speaker == "Narrador":
		return ""
	if speaker == "Kalin":
		return "Kalin"
	var entry: Dictionary = VocabularyCatalog.entry(speaker)
	if entry.is_empty():
		return speaker
	return "%s · %s" % [speaker, entry.spanish]


# ─── Ambiente ────────────────────────────────────────────────────────────────
func _update_arrow() -> void:
	var goal_ahead: bool = false
	for spot: ExplorationSpot in spots:
		if (
			spot.is_goal
			and spot.global_position.x > kalin.position.x + get_viewport_rect().size.x * 0.4
		):
			goal_ahead = true
	arrow.visible = goal_ahead and _can_walk() and _nearby_spot == null
	arrow.position.x = (
		_arrow_base_x
		+ (
			0.0
			if get_node("/root/AccessibilityManager").reduced_motion
			else sin(_time * ARROW_SPEED) * ARROW_BOB
		)
	)


func _animate_animals() -> void:
	var index: int = 0
	for animal: Sprite2D in _animal_bases:
		var base: Vector2 = _animal_bases[animal]
		var hop: float = (
			0.0
			if get_node("/root/AccessibilityManager").reduced_motion
			else absf(sin(_time * ANIMAL_HOP_SPEED + index * 1.3))
		)
		animal.position = base + Vector2(0.0, -hop * ANIMAL_HOP)
		index += 1


# ─── Navegación ──────────────────────────────────────────────────────────────
func _finish() -> void:
	if _navigating:
		return
	_navigating = true
	if _dialogue.is_open():
		_dialogue.close()
	prompt_button.hide()
	var tween: Tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(_go_to_next_scene)


func _go_to_next_scene() -> void:
	GameManager.go_to_scene(next_scene_key)


func _show_help() -> void:
	if _dialogue.is_open() or _navigating:
		return
	var closest: ExplorationSpot
	var distance: float = INF
	for spot: ExplorationSpot in spots:
		if spot.examined or not spot.can_interact() or not spot.sprite.is_visible_in_tree():
			continue
		var point: Vector2 = (
			spot.sprite.get_global_transform_with_canvas() * spot.sprite.get_rect().get_center()
		)
		if (
			get_viewport_rect().grow(-50).has_point(point)
			and absf(spot.position.x - kalin.position.x) < distance
		):
			closest = spot
			distance = absf(spot.position.x - kalin.position.x)
	if closest:
		guide.click_world(closest.sprite, closest.sprite.get_rect().get_center())
		return
	# El movimiento por el mundo también se inicia con un clic, no arrastrando.
	var ahead: float = clampf(kalin.position.x + 260, _min_x, walk_limit())
	if absf(ahead - kalin.position.x) < ARRIVE_DISTANCE:
		ahead = clampf(kalin.position.x - 200, _min_x, _max_x)
	guide.click_world(self, to_local(Vector2(ahead, ground_y(ahead))))


func get_checkpoint_state() -> Dictionary:
	var examined: Array[String] = []
	for spot: ExplorationSpot in spots:
		if spot.examined:
			examined.append(str(spot.name))
	var state: Dictionary = {
		"x": kalin.position.x,
		"examined": examined,
		"intro_done": _intro_done,
		"active": str(_active_spot.name) if _active_spot != null else "",
		"line": _dialogue.line_index if _dialogue.is_open() else 0
	}
	for child: Node in get_children():
		if child.has_method("checkpoint_extension"):
			state.merge(child.checkpoint_extension().duplicate(true))
	return state.duplicate(true)


func _on_menu_pressed() -> void:
	GameManager.go_to_scene("main_menu")


func variation_context() -> String:
	return GameManager.scene_key_for(self)
