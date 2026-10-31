extends RefCounted
class_name CountingSolver

## Forma en la tablilla el número de la ronda actual con los mismos botones que
## usa el jugador. Sólo para pruebas.


static func solve_round(level: Node) -> void:
	var target: int = level.current_target()
	level._on_clear_pressed()
	var twenties: int = MayaNumeral.twenties_of(target)
	if twenties > 0:
		level.upper_floor.pressed.emit()
		for step: int in range(twenties):
			level._on_dot_pressed()
		level.lower_floor.pressed.emit()
	var units: int = MayaNumeral.units_of(target)
	for step: int in range(MayaNumeral.bars_of(units)):
		level._on_bar_pressed()
	for step: int in range(MayaNumeral.dots_of(units)):
		level._on_dot_pressed()
	if MayaNumeral.needs_shell(target):
		level._on_shell_pressed()


static func solve_level(level: Node) -> void:
	while not level._session.is_finished(level.content.round_count):
		solve_round(level)
		level._on_action_pressed()
		level._on_action_pressed()
