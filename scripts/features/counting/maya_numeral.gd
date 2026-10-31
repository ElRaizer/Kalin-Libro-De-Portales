extends RefCounted
class_name MayaNumeral

## Numeración maya de puntos, barras y concha en dos pisos. En cada piso un
## punto vale 1 y una barra vale 5, así que un piso guarda de 0 a 19; el piso de
## arriba cuenta veintenas. La concha es el cero: aparece abajo cuando el número
## tiene veintenas justas (20, 40). Reglas puras, sin nodos ni autoloads.

enum Floor { UNITS, TWENTIES }

const DOT_VALUE: int = 1
const BAR_VALUE: int = 5
## Base vigesimal: veinte en un piso suben como un punto al piso de arriba.
const BASE: int = 20
const MAX_DOTS: int = 4
const MAX_BARS: int = 3
## Veintenas que caben arriba. Con dos se escribe hasta 59, lo bastante para
## buscar números del 1 al 50 y equivocarse por arriba.
const MAX_TWENTIES: int = 2


## Barras de un piso (0 a 19).
static func bars_of(floor_value: int) -> int:
	return clampi(floor_value, 0, BASE - 1) / BAR_VALUE


## Puntos de un piso (0 a 19). Nunca más de cuatro: cinco forman una barra.
static func dots_of(floor_value: int) -> int:
	return clampi(floor_value, 0, BASE - 1) % BAR_VALUE


static func twenties_of(number: int) -> int:
	return clampi(number, 0, max_value()) / BASE


static func units_of(number: int) -> int:
	return clampi(number, 0, max_value()) % BASE


static func value_of(twenties: int, units: int) -> int:
	return clampi(twenties, 0, MAX_TWENTIES) * BASE + clampi(units, 0, BASE - 1)


static func max_value() -> int:
	return MAX_TWENTIES * BASE + BASE - 1


## El número se escribe con concha abajo: tiene veintenas y ninguna unidad.
static func needs_shell(number: int) -> bool:
	return twenties_of(number) > 0 and units_of(number) == 0
