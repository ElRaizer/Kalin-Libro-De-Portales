extends RefCounted
class_name CountingSession

## Estado y reglas del tianguis de los números. Recibe datos de autor y devuelve
## resultados; no conoce nodos, autoloads ni archivos. El checkpoint se valida
## campo por campo y una ronda sólo se da por resuelta si su respuesta lo está.

## Cuántas veces aparece cada cosa en el puesto (la pedida y la otra).
const STALL_COPIES: int = 5

var round_index: int = 0
var waiting: bool = false
var cards: bool = false
var seed_value: int = 1
var met: Array[String] = []
var bars: int = 0
var dots: int = 0
## Índices del puesto que ya están en la canasta.
var basket: Array[int] = []
## Respuesta elegida o escrita: número con clasificador y lo contado.
var answer: String = ""
var item: String = ""
var attempt: LearningAttempt = LearningAttempt.new()


func restore(state: Dictionary, rounds: Array[CountingRound]) -> void:
	seed_value = clampi(_int(state.get("layout_seed"), seed_value), 1, 2000000000)
	round_index = clampi(_int(state.get("round"), 0), 0, rounds.size())
	attempt.restore(state.get("attempt"))
	cards = state.get("cards") is bool and state.cards
	if round_index >= rounds.size():
		return
	var current: CountingRound = rounds[round_index]
	met.clear()
	var saved_met: Variant = state.get("met", [])
	if saved_met is Array:
		for word: Variant in saved_met:
			if word is String and word in current.numbers and word not in met:
				met.append(word)
	bars = clampi(_int(state.get("bars"), 0), 0, MayaNumeral.MAX_BARS)
	dots = clampi(_int(state.get("dots"), 0), 0, MayaNumeral.MAX_DOTS)
	basket.clear()
	var saved_basket: Variant = state.get("basket", [])
	if saved_basket is Array:
		for index: Variant in saved_basket:
			if (
				(index is int or index is float)
				and is_finite(float(index))
				and int(index) >= 0
				and int(index) < STALL_COPIES * 2
				and int(index) not in basket
			):
				basket.append(int(index))
	answer = (
		str(state.get("recall_text", "")).left(80) if state.get("recall_text") is String else ""
	)
	item = str(state.get("noun", "")).left(80) if state.get("noun") is String else ""
	# El indicador de espera sólo vale si la respuesta guardada es correcta.
	waiting = state.get("waiting") is bool and state.waiting and is_solved(current)


func snapshot() -> Dictionary:
	return (
		{
			"round": round_index,
			"waiting": waiting,
			"cards": cards,
			"layout_seed": seed_value,
			"met": met.duplicate(),
			"bars": bars,
			"dots": dots,
			"basket": basket.duplicate(),
			"recall_text": answer,
			"noun": item,
			"attempt": attempt.snapshot()
		}
		. duplicate(true)
	)


## Empieza una ronda nueva. Devuelve true si continúa la misma ronda guardada.
func begin(current: CountingRound) -> bool:
	var context: String = LearningContext.identify(
		"counting/%s" % CountingRound.Kind.keys()[current.kind].to_lower(),
		current.requester,
		[current.number, current.item],
		current.guided,
		seed_value
	)
	return LearningContext.begin(attempt, context)


func next_round() -> void:
	round_index += 1
	waiting = false
	cards = false
	met.clear()
	bars = 0
	dots = 0
	basket.clear()
	answer = ""
	item = ""


func is_finished(count: int) -> bool:
	return round_index >= count


# ─── Estela ──────────────────────────────────────────────────────────────────
## Devuelve true si el número es nuevo en esta estela.
func meet(current: CountingRound, word: String) -> bool:
	if word not in current.numbers or word in met:
		return false
	met.append(word)
	return true


# ─── Construir el numeral ────────────────────────────────────────────────────
func add_dot() -> bool:
	var merged: bool = dots == MayaNumeral.MAX_DOTS
	var result: Vector2i = MayaNumeral.add_dot(bars, dots)
	bars = result.x
	dots = result.y
	return merged


func add_bar() -> void:
	var result: Vector2i = MayaNumeral.add_bar(bars, dots)
	bars = result.x
	dots = result.y


func clear_numeral() -> void:
	bars = 0
	dots = 0


func numeral_value() -> int:
	return MayaNumeral.value_of(bars, dots)


# ─── Tianguis ────────────────────────────────────────────────────────────────
## Puesto barajado con la semilla de la partida: la cosa pedida y la otra.
func stall(current: CountingRound) -> Array[String]:
	var goods: Array[String] = []
	for copy: int in range(STALL_COPIES):
		goods.append(current.item)
		goods.append(current.distractor)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = hash("%d:%d" % [seed_value, round_index])
	for index: int in range(goods.size() - 1, 0, -1):
		var other: int = random.randi_range(0, index)
		var swap: String = goods[index]
		goods[index] = goods[other]
		goods[other] = swap
	return goods


func toggle_basket(index: int) -> bool:
	if index < 0 or index >= STALL_COPIES * 2:
		return false
	if index in basket:
		basket.erase(index)
		return false
	basket.append(index)
	return true


## Opciones barajadas con la semilla para que no aparezcan siempre igual.
func shuffled_options(current: CountingRound) -> Array[String]:
	var options: Array[String] = current.options.duplicate()
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = hash("%d:%d:options" % [seed_value, round_index])
	for index: int in range(options.size() - 1, 0, -1):
		var other: int = random.randi_range(0, index)
		var swap: String = options[index]
		options[index] = options[other]
		options[other] = swap
	return options


# ─── Comprobaciones ──────────────────────────────────────────────────────────
func is_solved(current: CountingRound) -> bool:
	match current.kind:
		CountingRound.Kind.STELE:
			return met.size() == current.numbers.size()
		CountingRound.Kind.BUILD:
			return numeral_value() == VocabularyCatalog.number_value(current.number)
		CountingRound.Kind.MARKET:
			return basket_result(current) == "ok"
		CountingRound.Kind.FRIENDS:
			return answer == current.answer
		CountingRound.Kind.RECALL:
			return check_written(current, answer, item).correct
	return false


## "ok", "other" (hay algo que no se pidió), "few" o "many".
func basket_result(current: CountingRound) -> String:
	var goods: Array[String] = stall(current)
	var count: int = 0
	for index: int in basket:
		if goods[index] != current.item:
			return "other"
		count += 1
	var wanted: int = VocabularyCatalog.number_value(current.number)
	return "ok" if count == wanted else ("few" if count < wanted else "many")


## Escritura: el número con su clasificador y lo contado. Omitir acentos cuenta
## como apoyo, igual que en los demás ejercicios.
func check_written(current: CountingRound, typed_answer: String, typed_item: String) -> Dictionary:
	if cards:
		return {"correct": typed_answer == current.answer, "supported": true}
	var number_match: Dictionary = WordMatcher.match_word(typed_answer, current.answer)
	var item_match: Dictionary = WordMatcher.match_word(typed_item, current.item)
	return {
		"correct": number_match.correct and item_match.correct,
		"supported": number_match.supported or item_match.supported,
		"number_ok": number_match.correct,
		"item_ok": item_match.correct
	}


func miss() -> void:
	attempt.miss()


static func _int(value: Variant, fallback: int) -> int:
	if (value is int or value is float) and is_finite(float(value)):
		return int(clampf(float(value), -2000000000, 2000000000))
	return fallback
