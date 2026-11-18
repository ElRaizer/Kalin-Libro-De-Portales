extends RefCounted
class_name CountingActivity

## Una tanda breve conserva apoyos y resultados sin duplicar las reglas del numeral.
var session: CountingSession = CountingSession.new()
var content: CountingSet
var supports: Array[int] = []
var confirmed: Array[int] = []


static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (
		SaveSchema.is_number(value)
		and float(value) == floor(float(value))
		and float(value) >= minimum
		and float(value) <= maximum
	)


static func valid_state(value: Variant, settings: CountingSet) -> bool:
	if value is not Dictionary or value.get("counting") is not Dictionary:
		return false
	var state: Dictionary = value.counting
	var limits: Dictionary = {
		"round": settings.round_count,
		"layout_seed": 2000000000,
		"twenties": MayaNumeral.MAX_TWENTIES,
		"units": 19,
		"floor": 1,
		"mistakes": CountingSession.MAX_MISTAKES
	}
	for field: String in limits:
		if not integer(state.get(field), 1 if field == "layout_seed" else 0, int(limits[field])):
			return false
	if state.get("waiting") is not bool or state.get("shell") is not bool:
		return false
	if state.shell and int(state.units) != 0:
		return false
	if state.get("targets") is not Array or state.targets.size() != settings.round_count:
		return false
	var seen: Array[int] = []
	for number: Variant in state.targets:
		if not integer(number, settings.min_value, settings.max_value) or int(number) in seen:
			return false
		seen.append(int(number))
	if value.get("supports") is not Array or value.supports.size() != settings.round_count:
		return false
	for level: Variant in value.supports:
		if not integer(level, 0, 2):
			return false
	if value.get("confirmed") is not Array or value.confirmed.size() != int(state.round):
		return false
	for index: int in range(value.confirmed.size()):
		if (
			not integer(value.confirmed[index], settings.min_value, settings.max_value)
			or int(value.confirmed[index]) != seen[index]
		):
			return false
	if int(state.round) == settings.round_count:
		return (
			not state.waiting
			and int(state.units) == 0
			and int(state.twenties) == 0
			and not state.shell
		)
	var number: int = seen[int(state.round)]
	return (
		not state.waiting
		or (
			MayaNumeral.value_of(int(state.twenties), int(state.units)) == number
			and (not MayaNumeral.needs_shell(number) or state.shell)
		)
	)


func setup(settings: CountingSet, state: Dictionary = {}, targets: Array[int] = []) -> void:
	content = settings
	supports.clear()
	confirmed.clear()
	session = CountingSession.new()
	if valid_state(state, settings):
		session.restore(state.counting, settings)
		supports.assign(state.supports)
		confirmed.assign(state.confirmed)
	else:
		var initial: Dictionary = {"layout_seed": 17}
		if not targets.is_empty():
			initial.targets = targets.duplicate()
		session.restore(initial, settings)
		supports.resize(settings.round_count)
		supports.fill(0)
	session.targets(settings)


func snapshot() -> Dictionary:
	return {
		"counting": session.snapshot(),
		"supports": supports.duplicate(),
		"confirmed": confirmed.duplicate()
	}


func finished() -> bool:
	return session.is_finished(content.round_count)


func target() -> int:
	return 0 if finished() else session.target(content)


func submit() -> void:
	if finished():
		return
	if session.waiting:
		confirmed.append(target())
		session.next_round()
	elif session.is_solved(target()):
		session.waiting = true
	else:
		session.miss()
		supports[session.round_index] = maxi(1, supports[session.round_index])


func help() -> void:
	if finished() or session.waiting:
		return
	var index: int = session.round_index
	supports[index] = mini(2, supports[index] + 1)
	if supports[index] < 2:
		return
	var number: int = target()
	session.clear_numeral()
	session.select_floor(MayaNumeral.Floor.TWENTIES)
	for step: int in range(MayaNumeral.twenties_of(number)):
		session.add_dot()
	session.select_floor(MayaNumeral.Floor.UNITS)
	for step: int in range(MayaNumeral.bars_of(MayaNumeral.units_of(number))):
		session.add_bar()
	for step: int in range(MayaNumeral.dots_of(MayaNumeral.units_of(number))):
		session.add_dot()
	if MayaNumeral.needs_shell(number):
		session.add_shell()
