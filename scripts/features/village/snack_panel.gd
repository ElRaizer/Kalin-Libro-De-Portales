extends VillagePanel
class_name SnackPanel

signal book_requested(origin: Control)
signal moment_requested(guests: Array[String])

var profile: SnackProfile
var workbench: CountingWorkbench
var gathering: SnackGathering
var _selection: VBoxContainer
var _guests: Dictionary[String, CheckButton] = {}
var _food: OptionButton
var _decoration: OptionButton
var _start: Button
var _confirm: Button
var _book: Button
var _photo: Button
var _summary: Label
var _kay: Button
var _replay_guests: Array[String] = []


func _build_content() -> void:
	heading.text = profile.title
	close_button.text = "Salir y guardar"
	_selection = VBoxContainer.new()
	_selection.add_theme_constant_override("separation", 10)
	body.add_child(_selection)
	add_label(_selection, profile.invitation)
	var guests: HBoxContainer = HBoxContainer.new()
	_selection.add_child(guests)
	for guest: String in SnackState.GUESTS:
		var button: CheckButton = CheckButton.new()
		button.text = guest
		button.custom_minimum_size = Vector2(260, 56)
		button.add_theme_font_size_override("font_size", 26)
		guests.add_child(button)
		_guests[guest] = button
	add_label(_selection, "Merienda conocida · una ración de cinco bocados por invitado")
	_food = OptionButton.new()
	_food.custom_minimum_size.y = 54
	_food.add_theme_font_size_override("font_size", 26)
	_selection.add_child(_food)
	add_label(_selection, "Así nos gustaría reunirnos")
	_decoration = OptionButton.new()
	_decoration.custom_minimum_size.y = 54
	_decoration.add_theme_font_size_override("font_size", 26)
	_decoration.add_item("Un rincón sencillo")
	_decoration.add_item("Un borde de flores")
	_selection.add_child(_decoration)
	_start = add_button(_selection, "Preparar estas cantidades", start_preparation)
	workbench = CountingWorkbench.new()
	body.add_child(workbench)
	workbench.move_actions_to(footer)
	workbench.changed.connect(_save_preparation)
	_summary = add_label(body, "")
	gathering = SnackGathering.new()
	gathering.custom_minimum_size = profile.gathering_size
	body.add_child(gathering)
	_confirm = add_button(footer, "Reunirnos", confirm_project)
	_book = add_button(footer, "Libro", func() -> void: book_requested.emit(_book))
	_photo = add_button(footer, "Componer foto", _request_moment)
	_kay = add_button(body, "Invitar a Kay al estanque", _invite_kay)


func open_project(origin: Control) -> void:
	if not GameManager.session.has_finished_adventure() or visible or get_tree().paused:
		return
	refresh(false)
	if open_panel(origin) and workbench.visible:
		workbench.focus_input()


func refresh(animate: bool = false) -> void:
	var state: Dictionary = GameManager.session.snack_project
	var choosing: bool = state.preparation.is_empty()
	_selection.visible = choosing
	workbench.visible = not choosing and not state.complete
	workbench.action_controls.visible = (
		workbench.visible and int(state.preparation.counting.round) < 2
	)
	_photo.visible = state.complete
	_kay.visible = (
		state.complete and GameManager.has_learned_word("Kay") and "Kay" not in state.guests
	)
	_confirm.visible = (
		not choosing and (state.complete or int(state.preparation.counting.round) == 2)
	)
	_confirm.text = "Volver a reunirnos" if state.complete else "Reunirnos"
	gathering.visible = state.complete
	_summary.visible = not choosing and int(state.preparation.counting.round) == 2
	if choosing:
		_food.clear()
		for id: String in SnackState.FOODS:
			if LaboratoryState.known_combination(id, GameManager.learned_words()):
				_food.add_item(CombinationCatalog.targets()[id])
				_food.set_item_metadata(_food.item_count - 1, id)
				if id == state.food:
					_food.select(_food.item_count - 1)
		for guest: String in _guests:
			_guests[guest].disabled = not GameManager.has_learned_word(guest)
			_guests[guest].set_pressed_no_signal(guest in state.guests)
		_decoration.select(SnackState.DECORATIONS.find(state.decoration))
		_start.disabled = _food.item_count == 0
		notice.text = "Elige uno o dos invitados conocidos. No necesitas comprar comida ni muebles."
	else:
		workbench.setup(SnackState.counting_set(), state.preparation)
		var quantities: Array[int] = SnackState.targets(state.guests)
		_summary.text = (
			"%s · %s\n%d raciones y %d bocados. %s"
			% [
				", ".join(state.guests),
				CombinationCatalog.targets()[state.food],
				quantities[0],
				quantities[1],
				"Rincón sencillo." if state.decoration == "leaves" else "Reunión con flores."
			]
		)
		notice.text = "Cuenta las raciones primero y los bocados después. Puedes usar pistas; preparar no cuesta puntos."
		if int(state.preparation.counting.round) < 2:
			workbench.prompt.text += (
				" · Raciones" if int(state.preparation.counting.round) == 0 else " · Bocados"
			)
		if state.complete:
			var scene: Dictionary = state.duplicate(true)
			if not _replay_guests.is_empty():
				scene.guests = _replay_guests.duplicate()
				_summary.text = "Una visita de Kay · " + CombinationCatalog.targets()[state.food]
			gathering.present(scene, profile, animate)
			var reactions: PackedStringArray = PackedStringArray()
			for guest: String in scene.guests:
				reactions.append(profile.guest_reactions[guest])
			notice.text = "\n".join(reactions)
	layout_changed.emit()
	refresh_focus()


func start_preparation() -> void:
	var guests: Array[String] = []
	for guest: String in _guests:
		if _guests[guest].button_pressed and not _guests[guest].disabled:
			guests.append(guest)
	if guests.is_empty() or _food.selected < 0:
		notice.text = "Elige al menos un invitado conocido y una merienda."
		return
	if (
		not GameManager.select_snack(
			guests,
			_food.get_item_metadata(_food.selected),
			SnackState.DECORATIONS[_decoration.selected]
		)
		or not GameManager.begin_snack_preparation()
	):
		notice.text = "No se pudo guardar la preparación. Conservamos tu elección; puedes reintentar."
		return
	refresh()
	workbench.focus_input()
	changed.emit()


func _save_preparation() -> void:
	if not GameManager.update_snack_preparation(workbench.activity.snapshot()):
		refresh()
		notice.text = "No se pudo guardar. Conservamos la tablilla anterior; puedes reintentar."
		return
	refresh()
	if workbench.activity.finished():
		_confirm.grab_focus()
	changed.emit()


func confirm_project() -> void:
	_replay_guests.clear()
	var completed: bool = GameManager.session.snack_project.complete
	if not completed and not GameManager.confirm_snack_project():
		notice.text = "No se pudo guardar la reunión. Conservamos las cantidades preparadas."
		return
	refresh(true)
	changed.emit()


func _invite_kay() -> void:
	if not GameManager.confirm_village_guest("Kay"):
		notice.text = "No se pudo guardar la visita de Kay. Puedes reintentar."
		return
	_replay_guests = ["Kay"]
	refresh(true)
	changed.emit()


func _request_moment() -> void:
	var guests: Array[String] = []
	guests.assign(
		GameManager.session.snack_project.guests if _replay_guests.is_empty() else _replay_guests
	)
	moment_requested.emit(guests)


func close_panel() -> void:
	_replay_guests.clear()
	gathering.clear()
	super.close_panel()
