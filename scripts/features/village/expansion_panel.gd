extends VillagePanel
class_name ExpansionPanel

signal book_requested(origin: Control)
signal moment_requested
var profile: ExpansionProfile
var gathering: ExpansionGathering
var preview: Control
var _description: Label
var _guests: Dictionary[String, CheckButton] = {}
var _trials: Dictionary[String, Button] = {}
var _confirm: Button
var _replay: Button
var _book: Button
var _photo: Button


func _build_content() -> void:
	heading.text = profile.title
	close_button.text = "Salir y guardar"
	add_label(body, profile.invitation)
	var trials: HBoxContainer = HBoxContainer.new()
	body.add_child(trials)
	for purpose: String in VillageExpansion.PURPOSES:
		_trials[purpose] = add_button(
			trials, "Probar " + profile.purpose_titles[purpose], try_purpose.bind(purpose)
		)
	_description = add_label(body, "")
	preview = Control.new()
	preview.custom_minimum_size = Vector2(800, 160)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(preview)
	gathering = ExpansionGathering.new()
	preview.add_child(gathering)
	preview.resized.connect(_layout_preview)
	var choices: HBoxContainer = HBoxContainer.new()
	body.add_child(choices)
	for guest: String in VillageExpansion.GUESTS:
		var choice: CheckButton = CheckButton.new()
		choice.text = guest
		choice.theme_type_variation = &"KalinGuestChoice"
		choice.custom_minimum_size = Vector2(220, 52)
		choice.toggled.connect(func(_enabled: bool) -> void: select_guests())
		choices.add_child(choice)
		_guests[guest] = choice
	body.move_child(choices, body.get_child_count() - 2)
	_confirm = add_button(footer, "Inaugurar el claro", confirm_project)
	_replay = add_button(footer, "Reunirnos otra vez", replay)
	_book = add_button(footer, "Libro", func() -> void: book_requested.emit(_book))
	_photo = add_button(footer, "Componer foto", func() -> void: moment_requested.emit())


func open_project(origin: Control) -> void:
	if not GameManager.session.expansion_ready():
		return
	refresh()
	open_panel(origin)


func refresh(animate: bool = false) -> void:
	var state: Dictionary = GameManager.session.village_expansion
	for guest: String in _guests:
		_guests[guest].disabled = not GameManager.has_learned_word(guest)
		_guests[guest].set_pressed_no_signal(guest in state.guests)
	for purpose: String in _trials:
		_trials[purpose].text = (
			("Cambiar a " if state.complete else "Probar ")
			+ profile.purpose_titles[purpose]
			+ (" ✓" if purpose in state.tried else "")
		)
	_description.text = (
		profile.descriptions[state.purpose]
		if state.purpose in VillageExpansion.PURPOSES
		else "Prueba ambos usos, elige el que prefieras y marca uno o dos invitados."
	)
	_confirm.visible = not state.complete
	_confirm.disabled = state.tried.size() != 2 or state.guests.is_empty()
	_photo.visible = state.complete
	_replay.visible = state.complete
	notice.text = (
		(
			"Inauguración: %s con %s. Puedes cambiar el uso y los invitados; el recuerdo permanece."
			% [profile.purpose_titles[state.opening.purpose], ", ".join(state.opening.guests)]
		)
		if state.complete
		else "Todo es gratuito. Los objetos de la reunión son temporales; no ocupan tu almacén."
	)
	var guests: Array[String] = []
	guests.assign(state.guests)
	if guests.is_empty():
		for guest: String in VillageExpansion.GUESTS:
			if GameManager.has_learned_word(guest):
				guests.append(guest)
				break
	gathering.present(
		state.purpose if not state.purpose.is_empty() else "rest",
		guests,
		[Vector2(250, 225), Vector2(650, 225)],
		GameManager.session.snack_project.food,
		profile,
		animate
	)
	_layout_preview()
	layout_changed.emit()
	refresh_focus()


func _layout_preview() -> void:
	gathering.scale = Vector2.ONE * minf(preview.size.x / 900.0, preview.size.y / 240.0)
	gathering.position.x = (preview.size.x - 900.0 * gathering.scale.x) * 0.5


func try_purpose(purpose: String) -> void:
	if not GameManager.try_expansion(purpose):
		failed()
		return
	refresh(true)
	changed.emit()


func select_guests() -> void:
	var guests: Array[String] = []
	for guest: String in _guests:
		if _guests[guest].button_pressed:
			guests.append(guest)
	if not GameManager.select_expansion_guests(guests):
		failed()
		notice.text = "Elige uno o dos amigos. Si no se pudo guardar, conservamos el grupo anterior."
		return
	refresh()
	changed.emit()


func confirm_project() -> void:
	if not GameManager.inaugurate_expansion():
		failed()
		notice.text = "Prueba ambos usos y elige invitados. Deja libre la entrada del claro; si falla el guardado, puedes reintentar."
		return
	refresh(true)
	notice.text = "\n".join(_reactions())
	changed.emit()
	_replay.grab_focus()


func _reactions() -> Array[String]:
	var lines: Array[String] = []
	for guest: String in GameManager.session.village_expansion.guests:
		lines.append(profile.reactions[guest])
	return lines


func replay() -> void:
	if not GameManager.session.village_expansion.complete:
		return
	if not GameManager.confirm_clearing_reunion():
		notice.text = "No se pudo guardar la reunión. Puedes reintentar."
		return
	gathering.replay()
	notice.text = "\n".join(_reactions())


func failed() -> void:
	refresh()
	notice.text = "No se pudo guardar el cambio. Conservamos tu elección anterior; puedes reintentar."
