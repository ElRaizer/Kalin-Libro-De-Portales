extends RefCounted
class_name CountingSession

## Estado y reglas de «Las piedras que cuentan». Recibe la configuración y
## devuelve resultados; no conoce nodos, autoloads ni archivos. Los números de
## la partida salen de la semilla guardada, así que reanudar pide los mismos.
## El checkpoint se valida campo por campo.

## Qué pasó al poner una pieza, para que la vista lo cuente y lo haga sonar.
enum Placement {
	ADDED,  ## La pieza quedó en el piso elegido.
	MERGED,  ## Cinco puntos se juntaron en una barra.
	CARRIED,  ## Veinte subieron como un punto al piso de arriba.
	SHELL,  ## Se puso la concha del cero.
	FULL,  ## La pieza ya no cabe en ese piso.
	SHELL_TAKEN,  ## La concha sólo va en el piso de abajo vacío.
}

const MAX_MISTAKES: int = 1000

var round_index: int = 0
var waiting: bool = false
var seed_value: int = 1
var twenties: int = 0
var units: int = 0
var shell: bool = false
var active_floor: MayaNumeral.Floor = MayaNumeral.Floor.UNITS
var mistakes: int = 0


func restore(state: Dictionary, content: CountingSet) -> void:
	seed_value = clampi(_int(state.get("layout_seed"), seed_value), 1, 2000000000)
	round_index = clampi(_int(state.get("round"), 0), 0, content.round_count)
	if round_index >= content.round_count:
		return
	twenties = clampi(_int(state.get("twenties"), 0), 0, MayaNumeral.MAX_TWENTIES)
	units = clampi(_int(state.get("units"), 0), 0, MayaNumeral.BASE - 1)
	shell = state.get("shell") is bool and state.shell and units == 0
	active_floor = (
		MayaNumeral.Floor.TWENTIES
		if _int(state.get("floor"), 0) == MayaNumeral.Floor.TWENTIES
		else MayaNumeral.Floor.UNITS
	)
	mistakes = clampi(_int(state.get("mistakes"), 0), 0, MAX_MISTAKES)
	# El indicador de espera sólo vale si la tablilla guardada es correcta.
	waiting = state.get("waiting") is bool and state.waiting and is_solved(target(content))


func snapshot() -> Dictionary:
	return (
		{
			"round": round_index,
			"waiting": waiting,
			"layout_seed": seed_value,
			"twenties": twenties,
			"units": units,
			"shell": shell,
			"floor": int(active_floor),
			"mistakes": mistakes
		}
		. duplicate(true)
	)


## Los números de la partida, distintos entre sí y en el orden en que se piden.
func targets(content: CountingSet) -> Array[int]:
	var pool: Array[int] = []
	for value: int in range(content.min_value, content.max_value + 1):
		pool.append(value)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = hash("%d:numbers" % seed_value)
	for index: int in range(pool.size() - 1, 0, -1):
		var other: int = random.randi_range(0, index)
		var swap: int = pool[index]
		pool[index] = pool[other]
		pool[other] = swap
	return pool.slice(0, content.round_count)


func target(content: CountingSet) -> int:
	return targets(content)[round_index]


## Animal que pide el número de esta ronda.
func requester(content: CountingSet) -> String:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = hash("%d:%d:requester" % [seed_value, round_index])
	return content.requesters[random.randi_range(0, content.requesters.size() - 1)]


func is_guided(content: CountingSet) -> bool:
	return round_index < content.guided_rounds


func next_round() -> void:
	round_index += 1
	waiting = false
	mistakes = 0
	clear_numeral()


func is_finished(count: int) -> bool:
	return round_index >= count


# ─── Construir el numeral ────────────────────────────────────────────────────
func select_floor(value: MayaNumeral.Floor) -> void:
	active_floor = value


func add_dot() -> Placement:
	return _add(MayaNumeral.DOT_VALUE)


func add_bar() -> Placement:
	return _add(MayaNumeral.BAR_VALUE)


func add_shell() -> Placement:
	if active_floor != MayaNumeral.Floor.UNITS or units > 0 or shell:
		return Placement.SHELL_TAKEN
	shell = true
	return Placement.SHELL


func clear_numeral() -> void:
	twenties = 0
	units = 0
	shell = false
	active_floor = MayaNumeral.Floor.UNITS


func numeral_value() -> int:
	return MayaNumeral.value_of(twenties, units)


## Correcto: vale el número y, si sólo tiene veintenas, lleva la concha abajo.
func is_solved(number: int) -> bool:
	return numeral_value() == number and (shell or not MayaNumeral.needs_shell(number))


func miss() -> void:
	mistakes = mini(mistakes + 1, MAX_MISTAKES)


func _add(amount: int) -> Placement:
	if active_floor == MayaNumeral.Floor.TWENTIES:
		if twenties + amount > MayaNumeral.MAX_TWENTIES:
			return Placement.FULL
		twenties += amount
		return Placement.ADDED
	var total: int = units + amount
	if total >= MayaNumeral.BASE:
		if twenties >= MayaNumeral.MAX_TWENTIES:
			return Placement.FULL
		twenties += 1
		units = total - MayaNumeral.BASE
		shell = units == 0
		return Placement.CARRIED
	var merged: bool = (
		amount == MayaNumeral.DOT_VALUE and MayaNumeral.dots_of(units) == MayaNumeral.MAX_DOTS
	)
	units = total
	shell = false
	return Placement.MERGED if merged else Placement.ADDED


static func _int(value: Variant, fallback: int) -> int:
	if (value is int or value is float) and is_finite(float(value)):
		return int(clampf(float(value), -2000000000, 2000000000))
	return fallback
