extends RefCounted
class_name CountingSolver

## Resuelve la ronda actual de «Las piedras que cuentan» con la misma entrada que
## usa el jugador (botones, puesto, opciones y escritura). Sólo para pruebas.


static func solve_round(level: Node) -> void:
	var current: CountingRound = level._round()
	match current.kind:
		CountingRound.Kind.STELE:
			for index: int in range(current.numbers.size()):
				level._on_stele_number_pressed(index)
		CountingRound.Kind.BUILD:
			level._on_clear_pressed()
			var value: int = VocabularyCatalog.number_value(current.number)
			for index: int in range(MayaNumeral.bars_of(value)):
				level._on_bar_pressed()
			for index: int in range(MayaNumeral.dots_of(value)):
				level._on_dot_pressed()
			level._on_action_pressed()
		CountingRound.Kind.MARKET:
			var wanted: int = VocabularyCatalog.number_value(current.number)
			for button: Button in level._stall_buttons:
				if wanted > 0 and str(button.get_meta("good", "")) == current.item:
					button.button_pressed = true
					wanted -= 1
			level._on_action_pressed()
		CountingRound.Kind.FRIENDS:
			for button: Button in level._option_buttons:
				if button.visible and str(button.get_meta("answer", "")) == current.answer:
					level._on_option_pressed(button)
		CountingRound.Kind.RECALL:
			level.recall.first.text = current.answer
			level.recall.second.text = current.item
			level.recall.answer_changed.emit()
			level._on_action_pressed()


## Resuelve todas las rondas y pasa por cada «Continuar».
static func solve_level(level: Node) -> void:
	while not level._session.is_finished(level.content.rounds.size()):
		solve_round(level)
		level._on_action_pressed()
