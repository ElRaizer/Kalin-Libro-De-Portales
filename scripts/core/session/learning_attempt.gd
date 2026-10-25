extends RefCounted
class_name LearningAttempt

## La ayuda y los errores pertenecen al intento entero, incluso tras continuar
## desde un guardado. Seleccionar otra tarjeta no limpia esta evidencia.
var context: String = ""
var supported: bool = false
var mistakes: int = 0


func restore(value: Variant) -> void:
	if value is not Dictionary:
		return
	context = str(value.get("context", "")).left(160)
	supported = value.get("supported") is bool and value.supported
	var number: Variant = value.get("mistakes", 0)
	mistakes = (
		clampi(int(number), 0, 1000)
		if (number is int or number is float) and is_finite(float(number))
		else 0
	)


func begin(next_context: String) -> void:
	if context == next_context:
		return
	context = next_context
	supported = false
	mistakes = 0


func snapshot() -> Dictionary:
	return {"context": context, "supported": supported, "mistakes": mistakes}


func miss() -> void:
	mistakes += 1
	supported = true
