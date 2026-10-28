extends RefCounted
class_name MayaNumeral

## Numeración maya de puntos y barras para una sola posición: un punto vale 1
## y una barra vale 5. Cinco puntos se reúnen en una barra, así que un numeral
## nunca muestra más de cuatro puntos. Reglas puras, sin nodos ni autoloads.

const DOT_VALUE: int = 1
const BAR_VALUE: int = 5
const MAX_DOTS: int = 4
const MAX_BARS: int = 3


static func bars_of(value: int) -> int:
	return clampi(value, 0, max_value()) / BAR_VALUE


static func dots_of(value: int) -> int:
	return clampi(value, 0, max_value()) % BAR_VALUE


static func value_of(bars: int, dots: int) -> int:
	return clampi(bars, 0, MAX_BARS) * BAR_VALUE + clampi(dots, 0, MAX_DOTS) * DOT_VALUE


static func max_value() -> int:
	return MAX_BARS * BAR_VALUE + MAX_DOTS * DOT_VALUE


## Añade un punto. Si ya había cuatro, los cinco se reúnen en una barra nueva.
## Devuelve (barras, puntos); no cambia si el numeral ya está completo.
static func add_dot(bars: int, dots: int) -> Vector2i:
	if dots < MAX_DOTS:
		return Vector2i(bars, dots + 1)
	if bars < MAX_BARS:
		return Vector2i(bars + 1, 0)
	return Vector2i(bars, dots)


static func add_bar(bars: int, dots: int) -> Vector2i:
	return Vector2i(mini(bars + 1, MAX_BARS), dots)
