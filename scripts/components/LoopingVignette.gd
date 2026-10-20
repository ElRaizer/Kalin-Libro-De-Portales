extends Control

## Todas las propiedades dependen de la fase: el final coincide con el inicio.
signal mood_changed(expression: String)
@export_range(0.1, 30.0, 0.1) var cycle_seconds: float = 7.2
@export var catalog: VisualCatalog
@export var layouts: Array[VignetteLayout] = []
var situation := ""
var solved := false
@onready var actor: TextureRect = $Actor
@onready var _tail: TextureRect = $Actor/Tail
@onready var _thought: TextureRect = $Thought
@onready var _hunger: TextureRect = $Hunger
@onready var _question: TextureRect = $Question
@onready var _reward: MeaningIllustration = $Reward
var prop: Control
var elapsed := 0.0
var actor_home: Vector2
var _thought_home: Vector2
var _reward_home: Vector2
var _prop_home := Vector2.ZERO
var _faces: Dictionary = {}
var _hearts: Array[TextureRect] = []
var _pages: Array[TextureRect] = []
var _footprints: Array[TextureRect] = []
var _mood := ""
var _magic := 0.0
var _external_shadow := false

func _ready() -> void:
	actor_home = actor.position
	_thought_home = _thought.position
	_reward_home = _reward.position
	for index: int in range(3):
		_hearts.append(get_node("Heart%d" % index))
		_pages.append(get_node("Page%d" % index))
	for index: int in range(4):
		_footprints.append(get_node("Footprint%d" % index))
	set_process(false)

func show_situation(value: String, complete: bool = false) -> void:
	_clear()
	situation = value
	solved = complete
	visible = not value.is_empty()
	if not visible:
		return
	var layout: VignetteLayout
	for candidate: VignetteLayout in layouts:
		if candidate.situation == value:
			layout = candidate
			break
	if layout == null:
		push_warning("Falta la composición de la situación: %s" % value)
		hide()
		return
	_build_actor(layout.actor_word)
	prop = $Prop
	prop.texture = layout.solved_texture if complete else layout.unsolved_texture
	prop.position = layout.solved_position if complete else layout.position
	prop.size = layout.solved_size if complete else layout.size
	prop.show()
	_prop_home = prop.position
	_build_support("mayak" if value == "tamano" else "janal")
	seek_cycle(0)

func show_reward(word: String, quality: String, animal_word: String) -> void:
	_clear()
	situation = "regalo"
	solved = true
	show()
	_build_actor(animal_word)
	_reward.position = _reward_home
	_reward.show()
	_reward.show_meaning(word, quality)
	prop = _reward
	_prop_home = prop.position
	_build_support(word)
	seek_cycle(0)

func _clear() -> void:
	set_process(false)
	for child: Node in get_children():
		if child is CanvasItem:
			child.hide()
	elapsed = 0
	_mood = ""
	_magic = 0
	queue_redraw()

func _build_actor(word: String) -> void:
	var entry := catalog.find_entry(word)
	actor.texture = entry.texture if entry else null
	actor.show()
	_faces.clear()
	for expression: String in ["neutro", "duda", "hambre", "feliz", "parpadeo"]:
		_faces[expression] = entry.expression(expression) if entry else null
	_external_shadow = entry != null and entry.expressions.has("neutro")
	_tail.texture = entry.expressions.get("cola") if entry else null
	_tail.visible = _tail.texture != null

func _build_support(thought_word: String) -> void:
	for node: Control in [_question, _thought, _hunger]:
		node.show()
	$Thought/Content.texture = catalog.texture_for(thought_word)
	for node: Control in _hearts + _pages + _footprints:
		node.show()
	set_process(true)

func _process(delta: float) -> void:
	if is_visible_in_tree():
		seek_cycle(elapsed + delta)

## Capturas y validación utilizan la misma línea de tiempo que el juego real.
func seek_cycle(seconds: float) -> void:
	elapsed = fposmod(seconds, cycle_seconds)
	if not is_instance_valid(actor):
		return
	_apply_cycle(elapsed / cycle_seconds)
	queue_redraw()

func _apply_cycle(phase: float) -> void:
	var travel := _ease(phase, 0.08, 0.30) - _ease(phase, 0.72, 0.94)
	var moving := _bell(phase, 0.08, 0.30) + _bell(phase, 0.72, 0.94)
	var attempt := _bell(phase, 0.30, 0.64)
	var relief := _bell(phase, 0.35, 0.70)
	var breath := (1.0 - cos(phase * TAU * 2)) * 0.5
	var stride := sin(phase * TAU * 12)
	var distance := 330.0 if situation == "casa" else (270.0 if situation == "hambre" else (220.0 if situation == "tamano" else 205.0))
	actor.position = actor_home + Vector2(travel * distance, -absf(stride) * 11.0 * moving)
	actor.scale = Vector2.ONE * (1.0 + breath * 0.014)
	actor.rotation = stride * 0.045 * moving
	prop.position = _prop_home
	prop.scale = Vector2.ONE
	prop.rotation = 0
	prop.modulate = Color.WHITE
	_question.modulate.a = 0
	_thought.modulate.a = 0
	_thought.position = _thought_home
	_hunger.modulate.a = 0
	_magic = 0
	var emotion := "neutro"
	var kalin_mood := "pensando"
	if solved:
		# Se acerca, usa o admira lo que recibió y vuelve caminando a su sitio.
		emotion = "feliz" if relief > 0.15 else "neutro"
		actor.position.y -= relief * 15.0
		actor.rotation += sin(phase * TAU * 4) * relief * 0.035
		kalin_mood = "feliz" if relief > 0.2 else "normal"
		if situation == "casa":
			actor.position.y -= (_ease(phase, 0.30, 0.45) - _ease(phase, 0.62, 0.72)) * 100.0
			actor.scale.y -= attempt * 0.09
		if situation == "hambre":
			actor.rotation += attempt * 0.11
			actor.scale.y -= attempt * 0.035 * (1.0 + sin(phase * TAU * 24))
	else:
		match situation:
			"camino":
				actor.rotation += attempt * 0.15
				actor.position.x -= attempt * 14.0
				_question.modulate.a = _bell(phase, 0.44, 0.74)
				emotion = "duda" if attempt > 0.12 else "neutro"
			"casa":
				# Busca dónde sentarse; al no haber silla pierde el equilibrio.
				actor.position.y += -_bell(phase, 0.26, 0.48) * 100.0 + _bell(phase, 0.44, 0.65) * 18.0
				actor.rotation += sin(phase * TAU * 10) * attempt * 0.09
				prop.modulate.a = 0.64 - attempt * 0.40
				_question.modulate.a = _bell(phase, 0.48, 0.76)
				emotion = "duda" if attempt > 0.1 else "neutro"
			"tamano":
				# El caparazón no cabe; la mesa se sacude al intentarlo.
				actor.scale += Vector2(0.065, -0.045) * attempt
				actor.position.x += attempt * 17.0
				prop.position.x += sin(phase * TAU * 20) * attempt * 3.0
				_thought.modulate.a = _bell(phase, 0.46, 0.83) * 0.95
				_thought.position.y -= _bell(phase, 0.46, 0.83) * 9.0
				emotion = "duda" if attempt > 0.08 else "neutro"
			"hambre":
				# Olfatea el plato vacío, se toca la barriga e imagina comida.
				actor.rotation += attempt * 0.12
				actor.position.x += sin(phase * TAU * 30) * attempt * 2.5
				_hunger.position = actor.position + Vector2(26, 100)
				_hunger.modulate.a = attempt * 0.85
				_thought.modulate.a = _bell(phase, 0.42, 0.84)
				_thought.position.y -= _bell(phase, 0.42, 0.84) * 9.0
				emotion = "hambre" if attempt > 0.08 else "neutro"
	if situation == "portal":
		actor.hide()
		_magic = _bell(phase, 0.12, 0.82)
		prop.pivot_offset = prop.size * 0.5
		prop.scale = Vector2.ONE * (1.0 + _magic * 0.055)
		prop.modulate.a = 0.65 + _magic * 0.35
		kalin_mood = "magia" if _magic > 0.18 else "pensando"
	else:
		actor.show()
	if emotion == "neutro" and ((phase > 0.035 and phase < 0.055) or (phase > 0.95 and phase < 0.97)):
		emotion = "parpadeo"
	actor.texture = _faces[emotion]
	if is_instance_valid(_tail):
		_tail.rotation = sin(phase * TAU * 6) * (0.19 if solved else 0.11)
	for index: int in range(_hearts.size()):
		var t := fposmod(phase + index / 3.0, 1.0)
		_hearts[index].position = Vector2(270 + sin(t * TAU + index) * 32, 75 - t * 80)
		_hearts[index].modulate.a = pow(sin(t * PI), 2.0) * relief if solved else 0.0
		var angle := phase * TAU + index * TAU / 3.0
		_pages[index].position = Vector2(475 + cos(angle) * 135, 128 + sin(angle) * 118)
		_pages[index].rotation = sin(angle) * 0.22
		_pages[index].modulate.a = 0.55 + _magic * 0.4 if situation == "portal" else 0.0
	for index: int in range(_footprints.size()):
		_footprints[index].modulate.a = travel * 0.38 if situation == "camino" else 0.0
	if kalin_mood != _mood:
		_mood = kalin_mood
		mood_changed.emit(_mood)

static func _ease(value: float, start: float, end: float) -> float:
	var t := clampf((value - start) / (end - start), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func _bell(value: float, start: float, end: float) -> float:
	if value <= start or value >= end:
		return 0.0
	return pow(sin((value - start) / (end - start) * PI), 2.0)

func _draw() -> void:
	if not visible or not is_instance_valid(actor):
		return
	if situation != "portal" and _external_shadow:
		draw_set_transform(Vector2(actor.position.x + 97, 285), 0, Vector2(1, 0.15))
		draw_circle(Vector2.ZERO, 63, Color(0.23, 0.16, 0.08, 0.17), true, -1, true)
		draw_set_transform(Vector2.ZERO)
	elif situation == "portal":
		var center := Vector2(495, 143)
		var origin := Vector2(-102, 169) # Mano levantada de Kalin en StoryScene.
		for ring: int in range(3):
			draw_circle(center, 85 + ring * 15 + _magic * 6, Color(0.23, 0.83, 0.77, 0.05 + _magic * 0.06), false, 9, true)
		if _magic > 0.01:
			var points := PackedVector2Array()
			for index: int in range(33):
				var t := index / 32.0
				var point := origin.lerp(center, t)
				point.y -= sin(t * PI) * 105
				points.append(point)
			draw_polyline(points, Color(1.0, 0.83, 0.32, _magic * 0.45), 3, true)
			for index: int in range(7):
				var t := fposmod(elapsed / cycle_seconds * 2 + index / 7.0, 1.0)
				var point := origin.lerp(center, t)
				point.y -= sin(t * PI) * 105
				draw_circle(point, 3 + sin(t * PI) * 3, Color(1.0, 0.92, 0.59, sin(t * PI) * _magic), true, -1, true)
