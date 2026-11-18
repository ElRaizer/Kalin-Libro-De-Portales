extends VillagePanel
class_name VillageVisitPanel

signal invitation_requested(animal: String, object_id: int)
signal dismissal_requested
signal moment_requested

var profile: VillageVisitProfile
var _object_id: int = 0
var _message: Label
var _groups: Dictionary[String, VBoxContainer] = {}
var _animal_keys: Array[String] = []
var _guests: Array[Button] = []
var _dismiss: Button
var _photo: Button


func _build_content() -> void:
	heading.text = "Un rato en tu rincón"
	_message = add_label(body, "")
	close_button.text = "Seguir paseando"
	for index: int in range(VillageNeighbours.DISTRICTS.size()):
		var district: String = VillageNeighbours.DISTRICTS[index]
		var group: VBoxContainer = VBoxContainer.new()
		group.add_theme_constant_override("separation", 6)
		body.add_child(group)
		_groups[district] = group
		add_label(group, VillageNeighbours.NAMES[index])
		var choices: GridContainer = GridContainer.new()
		choices.columns = 4
		choices.add_theme_constant_override("h_separation", 10)
		group.add_child(choices)
		for animal: String in VillageNeighbours.RESIDENTS[district]:
			if not VillageNeighbours.table_guest(animal, true):
				continue
			var button: Button = add_button(choices, animal, _invite.bind(animal))
			button.accessibility_name = "Invitar a " + animal
			button.icon = VillageUseArt.ACTORS[animal]
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 54)
			_animal_keys.append(animal)
			_guests.append(button)
	_photo = add_button(footer, "Componer foto", func() -> void: moment_requested.emit())
	_dismiss = add_button(footer, "Despedir ahora", _dismiss_guest)


func open_for(object_id: int, origin: Control) -> void:
	if visible or get_tree().paused:
		return
	var session: GameSession = GameManager.session
	if not VillageVisitState.usable_table(GardenLayout.object_by_id(session.garden, object_id)):
		return
	_object_id = object_id
	var occupied: bool = not session.village_visit.is_empty()
	var postgame: bool = session.has_finished_adventure()
	_message.text = "Elige a quién invitar a tu mesa. La visita es gratis y termina sola."
	if occupied:
		var animal: String = session.village_visit.animal
		_message.text = animal + ": «" + profile.reaction_for(animal) + "»"
	for district: String in _groups:
		_groups[district].hide()
	for index: int in range(_guests.size()):
		var animal: String = _animal_keys[index]
		var can_invite: bool = animal in session.words_learned
		var offered: bool = VillageNeighbours.table_guest(animal, postgame)
		_guests[index].visible = not occupied and offered and (can_invite or not postgame)
		_guests[index].disabled = not can_invite
		if _guests[index].visible:
			_groups[VillageNeighbours.district_for(animal)].show()
	notice.text = (
		"La visita seguirá al cerrar."
		if occupied
		else (
			"Kay recibe su merienda en el estanque."
			if postgame and "Kay" in session.words_learned
			else ""
		)
	)
	_dismiss.visible = occupied
	_photo.visible = occupied and int(session.village_visit.object_id) == object_id
	open_panel(origin)


func _invite(animal: String) -> void:
	close_panel()
	invitation_requested.emit(animal, _object_id)


func _dismiss_guest() -> void:
	close_panel()
	dismissal_requested.emit()
