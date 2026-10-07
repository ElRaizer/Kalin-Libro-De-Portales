@tool
extends Node2D
class_name ExplorationSpot

## Punto interactuable de una escena de exploración (ExplorationScene).
## Se coloca arrastrándolo sobre el sendero y se configura en el Inspector:
## qué dice Kalin al examinarlo, si bloquea el paso y qué le pasa al terminar.
## Mientras nadie lo examina brilla para invitar al jugador a acercarse.

enum Reaction {
	NINGUNA,   ## El objeto se queda donde está y deja de brillar.
	APARTAR,   ## La magia de Kalin lo levanta y lo quita del camino.
	RECOGER,   ## Vuela hacia Kalin y desaparece (lo guarda en su libro).
}

const PULSE_SPEED := 3.0
const PULSE_STRENGTH := 0.22
const LIFT_HEIGHT := 70.0
const LIFT_SECONDS := 0.55
const SLIDE_DISTANCE := 260.0
const SLIDE_SECONDS := 0.6
const COLLECT_SECONDS := 0.7
const COLLECT_SCALE := 0.2
const CLICK_PADDING := 24.0
const PROMPT_GAP := 34.0
const NO_SPRITE_HEIGHT := 180.0
const MAGIC_TINT := Color(1.4, 1.35, 1.0)

@export_category("Interacción")
## Texto del botón que aparece al acercarse ("Examinar", "Mover", "Saludar"...).
@export var prompt: String = "Examinar"
## "Kalin", "Narrador" o la palabra maya del animal que habla.
@export var speaker: String = "Kalin"
## Cada línea es un globo de diálogo; se avanza con clic, E, Espacio o Enter.
@export var lines: Array[String] = []:
	set(value):
		lines = value
		update_configuration_warnings()
## Kalin pone cara de sorpresa mientras dura el diálogo.
@export var surprised: bool = false
## Distancia horizontal a la que Kalin puede examinar el objeto.
@export_range(40.0, 400.0, 10.0) var reach_radius: float = 150.0

@export_category("Camino")
## Kalin no puede pasar de este punto hasta examinarlo.
@export var blocks_path: bool = false
## Al terminar su diálogo la exploración termina y empieza la historia.
@export var is_goal: bool = false
## El diálogo se abre solo cuando Kalin llega (sin pulsar nada).
@export var auto_trigger: bool = false
## Qué le pasa al objeto la primera vez que se examina.
@export var reaction: Reaction = Reaction.NINGUNA

# ─── Estado ──────────────────────────────────────────────────────────────────
var examined: bool = false
var _time: float = 0.0
var _reaction_tween: Tween

# ─── Nodos ───────────────────────────────────────────────────────────────────
@onready var sprite: Sprite2D = $Sprite
@onready var glow: CPUParticles2D = $Brillo

# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_time = randf() * TAU

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or examined:
		return
	# Un pulso de luz suave indica que el objeto todavía guarda algo.
	_time += delta
	var pulse: float = (sin(_time * PULSE_SPEED) + 1.0) * 0.5 * PULSE_STRENGTH
	sprite.modulate = Color(1.0 + pulse, 1.0 + pulse, 1.0 + pulse * 0.5)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if lines.is_empty():
		warnings.append("Agrega al menos una línea de diálogo en «lines».")
	return warnings

# ─── API para ExplorationScene ───────────────────────────────────────────────

## true mientras el objeto impide que Kalin siga avanzando.
func is_blocking() -> bool:
	return blocks_path and not examined

## Un objeto que ya se apartó o se recogió no vuelve a mostrar su botón.
func can_interact() -> bool:
	return not examined or reaction == Reaction.NINGUNA

## Indica si un punto del mundo cae sobre el dibujo del objeto (para el clic).
func contains_point(world_point: Vector2) -> bool:
	if sprite.texture == null or not sprite.visible:
		return absf(world_point.x - global_position.x) <= reach_radius * 0.5 and world_point.y <= global_position.y
	var local_point: Vector2 = sprite.to_local(world_point)
	return sprite.get_rect().grow(CLICK_PADDING).has_point(local_point)

## Posición (en el mundo) sobre la que flota el botón de interacción.
func prompt_anchor() -> Vector2:
	if sprite.texture == null:
		return global_position + Vector2(0.0, -NO_SPRITE_HEIGHT)
	var top: Vector2 = sprite.to_global(Vector2(0.0, sprite.get_rect().position.y))
	return top + Vector2(0.0, -PROMPT_GAP)

func mark_examined() -> void:
	examined = true
	glow.emitting = false
	sprite.modulate = Color.WHITE

## Anima la reacción configurada y devuelve el Tween (o null si no hay).
## `collector` es la posición global hacia la que vuela un objeto recogido.
func play_reaction(collector: Vector2) -> Tween:
	if _reaction_tween:
		_reaction_tween.kill()
	match reaction:
		Reaction.APARTAR:
			_reaction_tween = _move_aside()
		Reaction.RECOGER:
			_reaction_tween = _fly_to(collector)
		_:
			_reaction_tween = null
	return _reaction_tween

# ─── Animaciones ─────────────────────────────────────────────────────────────
func _move_aside() -> Tween:
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y - LIFT_HEIGHT, LIFT_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate", MAGIC_TINT, LIFT_SECONDS)
	tween.parallel().tween_property(sprite, "rotation", -0.12, LIFT_SECONDS)
	tween.tween_property(sprite, "position:x", sprite.position.x + SLIDE_DISTANCE, SLIDE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, SLIDE_SECONDS)
	tween.tween_callback(sprite.hide)
	return tween

func _fly_to(collector: Vector2) -> Tween:
	var target: Vector2 = to_local(collector)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "position", target, COLLECT_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", sprite.scale * COLLECT_SCALE, COLLECT_SECONDS)
	tween.tween_property(sprite, "modulate:a", 0.0, COLLECT_SECONDS * 0.4).set_delay(COLLECT_SECONDS * 0.6)
	tween.chain().tween_callback(sprite.hide)
	return tween
