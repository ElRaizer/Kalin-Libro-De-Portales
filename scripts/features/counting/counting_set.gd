@tool
extends Resource
class_name CountingSet

## Configuración de «Las piedras que cuentan»; se edita en el Inspector. Cada
## partida sortea sus números dentro del rango, sin repetirlos.

## Cuántos números se forman para terminar el nivel.
@export_range(1, 20) var round_count: int = 8
@export_range(1, 59) var min_value: int = 1
@export_range(1, 59) var max_value: int = 50
## Las primeras rondas muestran cómo se reparte el número entre los pisos.
@export_range(0, 20) var guided_rounds: int = 2
## Animales del vocabulario que piden los números (se sortean).
@export var requesters: Array[String] = []


func get_configuration_issues() -> PackedStringArray:
	var issues: PackedStringArray = []
	if min_value < 1 or max_value > MayaNumeral.max_value() or min_value > max_value:
		issues.append(
			(
				"El rango de números debe ir de 1 a %d y empezar antes de terminar."
				% MayaNumeral.max_value()
			)
		)
	elif max_value - min_value + 1 < round_count:
		issues.append("El rango no alcanza para %d números distintos." % round_count)
	if requesters.is_empty():
		issues.append("Agrega al menos un animal que pida números.")
	for word: String in requesters:
		if VocabularyCatalog.entry(word).is_empty():
			issues.append("«%s» no está en el vocabulario." % word)
	return issues
