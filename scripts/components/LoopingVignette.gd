extends Control

## Todas las propiedades dependen de la fase: el final coincide con el inicio.
signal mood_changed(expression: String)
const CYCLE_SECONDS := 7.2
const ACTOR_HOME := Vector2(48, 85)
const ACTOR_SIZE := Vector2(195, 195)
var situation := ""
var solved := false
var actor: TextureRect
var prop: Control
var elapsed := 0.0
var _prop_home := Vector2.ZERO
var _faces: Dictionary = {}
var _tail: TextureRect
var _thought: TextureRect
var _hunger: TextureRect
var _question: TextureRect
var _hearts: Array[TextureRect] = []
var _pages: Array[TextureRect] = []
var _footprints: Array[TextureRect] = []
var _mood := ""
var _magic := 0.0
var _external_shadow := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_situation(value: String, complete: bool = false) -> void:
	_clear()
	situation = value
	solved = complete
	visible = not value.is_empty()
	if not visible:
		return
	var word := "Áak" if value == "tamano" else ("Miis" if value == "casa" else "Peek'")
	_build_actor(word)
	var path := "res://Arte/ilustraciones/objeto_mayak.svg"
	var at := Vector2(430, 180)
	var dimensions := Vector2(140, 105)
	match value:
		"camino":
			path = "res://Arte/ilustraciones/escena_camino.svg"
			at = Vector2(255, 35)
			dimensions = Vector2(440, 270)
		"casa":
			path = "res://Arte/ilustraciones/objeto_chan.svg" if complete else "res://Arte/ilustraciones/silueta_chan.svg"
			at = Vector2(370, 55)
			dimensions = Vector2(290, 230)
		"tamano":
			if complete:
				at = Vector2(360, 30)
				dimensions = Vector2(335, 255)
		"hambre":
			path = "res://Arte/ilustraciones/comida_janal.svg" if complete else "res://Arte/ilustraciones/objeto_lak.svg"
			at = Vector2(365, 174)
			dimensions = Vector2(255, 130)
		"portal":
			path = "res://Arte/ilustraciones/ui_portal.svg"
			at = Vector2(335, -5)
			dimensions = Vector2(320, 295)
	prop = _picture(path, at, dimensions)
	_prop_home = at
	_build_support("mayak" if value == "tamano" else "janal")
	seek_cycle(0)

func show_reward(word: String, quality: String, animal_word: String) -> void:
	_clear()
	situation = "regalo"
	solved = true
	show()
	_build_actor(animal_word)
	var result := MeaningIllustration.new()
	result.position = Vector2(355, 35)
	result.size = Vector2(300, 255)
	add_child(result)
	result.show_meaning(word, quality)
	prop = result
	_prop_home = result.position
	_build_support(word)
	seek_cycle(0)

func _clear() -> void:
	set_process(false)
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	actor = null
	prop = null
	_tail = null
	_faces.clear()
	_hearts.clear()
	_pages.clear()
	_footprints.clear()
	elapsed = 0
	_mood = ""
	_magic = 0
	queue_redraw()

func _build_actor(word: String) -> void:
	var original: String = get_node("/root/GameManager").get_book_illustration(word)
	actor = _picture(original, ACTOR_HOME, ACTOR_SIZE)
	actor.z_index = 2
	actor.pivot_offset = Vector2(97.5, 182)
	var base := original.get_file().get_basename()
	for expression: String in ["neutro", "duda", "hambre", "feliz", "parpadeo"]:
		var path := "res://Arte/sprites/expresiones/%s_%s.svg" % [base, expression]
		_faces[expression] = load(path) if ResourceLoader.exists(path) else actor.texture
	var base_texture: Texture2D = _faces["neutro"]
	_external_shadow = base_texture.resource_path.contains("/expresiones/")
	var tail_path := "res://Arte/sprites/expresiones/%s_cola.svg" % base
	if ResourceLoader.exists(tail_path):
		_tail = _picture(tail_path, Vector2.ZERO, ACTOR_SIZE, actor)
		_tail.show_behind_parent = true
		_tail.pivot_offset = Vector2(94, 75) * ACTOR_SIZE.x / 120.0

func _build_support(thought_word: String) -> void:
	_question = _picture("res://Arte/ilustraciones/ui_pensar.svg", Vector2(265, 35), Vector2(65, 65))
	_question.z_index = 3
	_thought = _picture("res://Arte/ilustraciones/fx_pensamiento.svg", Vector2(410, -35), Vector2(300, 225))
	_thought.z_index = 3
	_picture(get_node("/root/GameManager").get_book_illustration(thought_word), Vector2(40, 15), Vector2(220, 160), _thought)
	_hunger = _picture("res://Arte/ilustraciones/fx_hambre.svg", Vector2.ZERO, Vector2(145, 105))
	_hunger.z_index = 3
	for index: int in range(3):
		_hearts.append(_picture("res://Arte/ilustraciones/ui_corazon.svg", Vector2.ZERO, Vector2(34, 34)))
		_pages.append(_picture("res://Arte/exploracion/prop_pagina.svg", Vector2.ZERO, Vector2(54, 42)))
		_hearts[index].z_index = 3
		_pages[index].z_index = 3
	for index: int in range(4):
		var mark := _picture("res://Arte/ilustraciones/fx_huella.svg", Vector2(110 + index * 43, 273 + index % 2 * 16), Vector2(24, 24))
		mark.rotation = PI / 2.0
		move_child(mark, 0)
		_footprints.append(mark)
	set_process(true)

func _picture(path: String, at: Vector2, dimensions: Vector2, parent: Node = null) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.texture = load(path) if not path.is_empty() else null
	picture.position = at
	picture.size = dimensions
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else self).add_child(picture)
	return picture

func _process(delta: float) -> void:
	if is_visible_in_tree():
		seek_cycle(elapsed + delta)

## Capturas y validación utilizan la misma línea de tiempo que el juego real.
func seek_cycle(seconds: float) -> void:
	elapsed = fposmod(seconds, CYCLE_SECONDS)
	if not is_instance_valid(actor):
		return
	_apply_cycle(elapsed / CYCLE_SECONDS)
	queue_redraw()

func _apply_cycle(phase: float) -> void:
	var travel := _ease(phase, 0.08, 0.30) - _ease(phase, 0.72, 0.94)
	var moving := _bell(phase, 0.08, 0.30) + _bell(phase, 0.72, 0.94)
	var attempt := _bell(phase, 0.30, 0.64)
	var relief := _bell(phase, 0.35, 0.70)
	var breath := (1.0 - cos(phase * TAU * 2)) * 0.5
	var stride := sin(phase * TAU * 12)
	var distance := 330.0 if situation == "casa" else (270.0 if situation == "hambre" else (220.0 if situation == "tamano" else 205.0))
	actor.position = ACTOR_HOME + Vector2(travel * distance, -absf(stride) * 11.0 * moving)
	actor.scale = Vector2.ONE * (1.0 + breath * 0.014)
	actor.rotation = stride * 0.045 * moving
	prop.position = _prop_home
	prop.scale = Vector2.ONE
	prop.rotation = 0
	prop.modulate = Color.WHITE
	_question.modulate.a = 0
	_thought.modulate.a = 0
	_thought.position = Vector2(410, -35)
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
				var t := fposmod(elapsed / CYCLE_SECONDS * 2 + index / 7.0, 1.0)
				var point := origin.lerp(center, t)
				point.y -= sin(t * PI) * 105
				draw_circle(point, 3 + sin(t * PI) * 3, Color(1.0, 0.92, 0.59, sin(t * PI) * _magic), true, -1, true)
