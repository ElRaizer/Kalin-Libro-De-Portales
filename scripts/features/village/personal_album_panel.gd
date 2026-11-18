extends VillagePanel
class_name PersonalAlbumPanel

var garden_profile: GardenProfile
var rest_profile: RestCornerProfile
var snack_profile: SnackProfile
var expansion_profile: ExpansionProfile
var _camera: PersonalMomentView
var _stage_slot: AspectRatioContainer
var _clean_screen: ColorRect
var _clean_slot: AspectRatioContainer
var _gallery: VBoxContainer
var _composer: VBoxContainer
var _summary: Label
var _moments: OptionButton
var _replacement: OptionButton
var _title: LineEdit
var _guest_choices: HBoxContainer
var _guest_buttons: Array[CheckButton] = []
var _frame: OptionButton
var _pose: OptionButton
var _preview_motion: CheckButton
var _recent_button: Button
var _clean_button: Button
var _back: Button
var _save_button: Button
var _replace_button: Button
var _delete_button: Button
var _draft: Dictionary = {}
var _recent_invitation: Dictionary = {}
var _replacing: bool = false
var _delete_pending: bool = false
var _selected: int = 0


func _build_content() -> void:
	var spread: HBoxContainer = HBoxContainer.new()
	spread.add_theme_constant_override("separation", 20)
	body.add_child(spread)
	var sidebar: VBoxContainer = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 325
	sidebar.add_theme_constant_override("separation", 8)
	spread.add_child(sidebar)
	_gallery = VBoxContainer.new()
	_gallery.add_theme_constant_override("separation", 12)
	sidebar.add_child(_gallery)
	_summary = add_label(_gallery, "")
	_moments = _option(_gallery, "Recuerdos guardados", [], _select_moment)
	_recent_button = add_button(_gallery, "Componer última visita", _compose_invitation)
	_composer = VBoxContainer.new()
	_composer.add_theme_constant_override("separation", 4)
	sidebar.add_child(_composer)
	add_label(_composer, "Título")
	_title = LineEdit.new()
	_title.max_length = PersonalAlbum.TITLE_LENGTH
	_title.custom_minimum_size.y = 52
	_title.add_theme_font_size_override("font_size", 22)
	_title.placeholder_text = "Un nombre para este momento"
	_title.accessibility_name = "Título del recuerdo"
	_title.text_changed.connect(_update_save_button)
	_composer.add_child(_title)
	add_label(_composer, "Quién sale en la foto")
	_guest_choices = HBoxContainer.new()
	_composer.add_child(_guest_choices)
	for index: int in range(2):
		var guest: CheckButton = CheckButton.new()
		guest.custom_minimum_size.y = 52
		guest.add_theme_font_size_override("font_size", 22)
		guest.theme_type_variation = &"KalinGuestChoice"
		guest.toggled.connect(_choose_guests)
		_guest_choices.add_child(guest)
		_guest_buttons.append(guest)
	add_label(_composer, "Encuadre")
	_frame = _option(_composer, "Encuadre", ["Abierto", "Cercano"], _choose_frame)
	add_label(_composer, "Pose")
	_pose = _option(_composer, "Pose", ["Saludo", "Compartiendo"], _choose_pose)
	_preview_motion = CheckButton.new()
	_preview_motion.text = "Ver movimiento"
	_preview_motion.add_theme_font_size_override("font_size", 22)
	_preview_motion.theme_type_variation = &"KalinGuestChoice"
	_preview_motion.toggled.connect(_toggle_motion)
	_composer.add_child(_preview_motion)
	_replacement = _option(sidebar, "Recuerdo que quieres sustituir", [], _choose_replacement)
	_stage_slot = _photo_slot(spread)
	_stage_slot.custom_minimum_size.y = 392
	_camera = PersonalMomentView.new()
	_camera.garden_profile = garden_profile
	_camera.rest_profile = rest_profile
	_camera.snack_profile = snack_profile
	_camera.expansion_profile = expansion_profile
	_stage_slot.add_child(_camera)
	_clean_screen = ColorRect.new()
	_clean_screen.color = Color("102925")
	_clean_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clean_screen.focus_mode = Control.FOCUS_ALL
	_clean_screen.accessibility_name = "Foto sin controles. Pulsa Escape o Enter para volver."
	add_child(_clean_screen)
	_clean_slot = _photo_slot(_clean_screen)
	_clean_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clean_screen.hide()
	_back = add_button(footer, "Mi álbum", _back_to_album)
	_clean_button = add_button(footer, "Vista limpia", _show_clean)
	_clean_button.tooltip_text = "Pulsa Esc, Enter o toca la foto para volver."
	_save_button = add_button(footer, "Guardar foto", _save_moment)
	_replace_button = add_button(footer, "Sustituir…", _offer_replacement)
	_delete_button = add_button(footer, "Borrar foto…", _delete_moment)


func _photo_slot(parent: Control) -> AspectRatioContainer:
	var slot: AspectRatioContainer = AspectRatioContainer.new()
	slot.ratio = 16.0 / 9.0
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(slot)
	return slot


func _option(
	parent: Control, label: String, choices: Array[String], action: Callable
) -> OptionButton:
	var menu: OptionButton = OptionButton.new()
	menu.custom_minimum_size.y = 52
	menu.add_theme_font_size_override("font_size", 22)
	menu.fit_to_longest_item = false
	menu.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	menu.accessibility_name = label
	menu.theme_changed.connect(
		func() -> void:
			menu.get_popup().add_theme_font_size_override(
				"font_size", menu.get_theme_font_size("font_size")
			)
	)
	menu.item_selected.connect(action)
	for choice: String in choices:
		menu.add_item(choice)
	parent.add_child(menu)
	return menu


func open_gallery(origin: Control, invitation: Dictionary) -> void:
	if open_panel(origin):
		_recent_invitation = invitation.duplicate(true)
		_show_gallery()
		_focus_gallery()


func open_composer(origin: Control, source: Dictionary, invitation: Dictionary) -> void:
	if open_panel(origin):
		_recent_invitation = invitation.duplicate(true)
		_begin(source)


func _begin(source: Dictionary) -> void:
	_draft = source.duplicate(true)
	_replacing = false
	_delete_pending = false
	_title.text = source.title
	for index: int in range(_guest_buttons.size()):
		var guest: CheckButton = _guest_buttons[index]
		guest.visible = index < source.guests.size()
		if guest.visible:
			guest.text = source.guests[index]
			guest.set_pressed_no_signal(true)
	_frame.select(PersonalAlbum.FRAMES.find(source.frame))
	_pose.select(PersonalAlbum.PRESET_POSES.find(float(source.pose)))
	_camera.set_frozen(true)
	_preview_motion.set_pressed_no_signal(false)
	notice.text = "En la vista limpia, pulsa Esc o Enter para volver."
	_camera.present(_draft)
	_update_controls()
	_title.grab_focus()


func _compose_invitation() -> void:
	_begin(_recent_invitation)


func _show_gallery(message: String = "") -> void:
	_draft.clear()
	_replacing = false
	_delete_pending = false
	var moments: Array[Dictionary] = GameManager.session.personal_moments()
	_moments.clear()
	for moment: Dictionary in moments:
		_moments.add_item(moment.title)
	_selected = clampi(_selected, 0, maxi(0, moments.size() - 1))
	_moments.select(_selected if not moments.is_empty() else -1)
	_summary.text = "%d de %d recuerdos" % [moments.size(), PersonalAlbum.LIMIT]
	if moments.is_empty() and message.is_empty():
		message = "Todavía no hay fotos. Puedes componer una tras una invitación o reunión."
	notice.text = message
	_camera.set_frozen(true)
	_camera.present({} if moments.is_empty() else moments[_selected])
	_update_controls()


func _select_moment(index: int) -> void:
	_selected = index
	_show_gallery()
	_moments.grab_focus()


func _back_to_album() -> void:
	if _replacing:
		_replacing = false
		notice.text = "Puedes conservar tu borrador o volver al álbum."
		_update_controls()
		_save_button.grab_focus()
	else:
		_show_gallery()
		_focus_gallery()


func _focus_gallery() -> void:
	if _moments.visible:
		_moments.grab_focus()
	elif _recent_button.visible:
		_recent_button.grab_focus()
	else:
		close_button.grab_focus()


func _update_controls() -> void:
	var composing: bool = not _draft.is_empty()
	var has_moments: bool = _moments.item_count > 0
	heading.text = "Componer un momento" if composing else "Mi álbum"
	close_button.text = "Salir al jardín" if composing else "Volver al jardín"
	_gallery.visible = not composing
	_moments.visible = has_moments
	_recent_button.visible = not _recent_invitation.is_empty()
	_composer.visible = composing and not _replacing
	_preview_motion.visible = not AccessibilityManager.reduced_motion
	_replacement.visible = _replacing
	_stage_slot.visible = composing or has_moments
	_clean_button.visible = _stage_slot.visible and not _replacing and not _delete_pending
	_back.visible = composing or _delete_pending
	_back.text = (
		"Cancelar sustitución" if _replacing else ("Cancelar" if _delete_pending else "Mi álbum")
	)
	_save_button.visible = composing
	_replace_button.visible = (
		composing
		and not _replacing
		and GameManager.session.personal_moment_count() in range(1, PersonalAlbum.LIMIT)
	)
	_save_button.text = "Confirmar sustitución" if _replacing else "Guardar foto"
	_delete_button.visible = not composing and has_moments
	_delete_button.text = "Confirmar borrado" if _delete_pending else "Borrar foto…"
	_update_save_button(_title.text)
	layout_changed.emit()
	refresh_focus()


func _choose_guests(_enabled: bool) -> void:
	var guests: Array[String] = []
	for guest: CheckButton in _guest_buttons:
		if guest.visible and guest.button_pressed:
			guests.append(guest.text)
	if guests.is_empty():
		for guest: CheckButton in _guest_buttons:
			guest.set_pressed_no_signal(guest.text in _draft.guests and guest.visible)
		notice.text = "Deja al menos un invitado en la foto."
		return
	_draft.guests = guests
	_draft.pose = _camera.current_pose()
	_camera.present(_draft)


func _choose_frame(index: int) -> void:
	_draft.frame = PersonalAlbum.FRAMES[index]
	_camera.set_frame(_draft.frame)


func _choose_pose(index: int) -> void:
	_draft.pose = PersonalAlbum.PRESET_POSES[index]
	_preview_motion.set_pressed_no_signal(false)
	_camera.set_frozen(true)
	_camera.set_pose(_draft.pose)


func _toggle_motion(enabled: bool) -> void:
	if enabled:
		_pose.select(-1)
		_pose.text = "En movimiento"
		_camera.set_frozen(false)
	else:
		_freeze_preview()


func _freeze_preview() -> void:
	_preview_motion.set_pressed_no_signal(false)
	_camera.set_frozen(true)
	if _draft.is_empty():
		return
	_draft.pose = floorf(_camera.current_pose() * 1000.0) / 1000.0
	_camera.set_pose(_draft.pose)
	_pose.select(PersonalAlbum.PRESET_POSES.find(_draft.pose))
	if _pose.selected < 0:
		_pose.text = "Pose en pausa"


func _update_save_button(value: String) -> void:
	_save_button.disabled = (
		value.strip_edges().is_empty() or (_replacing and _replacement.selected < 0)
	)
	refresh_focus()


func _choose_replacement(_index: int) -> void:
	_update_save_button(_title.text)


func _save_moment() -> void:
	_freeze_preview()
	_draft.title = _title.text.strip_edges()
	if not _replacing and GameManager.session.personal_moment_count() >= PersonalAlbum.LIMIT:
		_offer_replacement()
		return
	var index: int = _replacement.selected if _replacing else -1
	if not GameManager.save_personal_moment(_draft, index):
		notice.text = "No se pudo guardar la foto. Tu álbum y el borrador siguen disponibles."
		return
	_selected = index if index >= 0 else GameManager.session.personal_moment_count() - 1
	_show_gallery("Foto guardada en tu álbum.")
	_focus_gallery()


func _offer_replacement() -> void:
	_freeze_preview()
	_replacing = true
	_replacement.clear()
	for moment: Dictionary in GameManager.session.personal_moments():
		_replacement.add_item(moment.title)
	_replacement.select(-1)
	_replacement.text = "Elige una foto"
	var full: bool = GameManager.session.personal_moment_count() == PersonalAlbum.LIMIT
	notice.text = (
		"Tu álbum está lleno. Elige qué foto sustituir." if full else "Elige qué foto sustituir."
	)
	_update_controls()
	_replacement.grab_focus()


func _delete_moment() -> void:
	if not _delete_pending:
		_delete_pending = true
		notice.text = "¿Borrar «%s» del álbum?" % _moments.get_item_text(_selected)
		_update_controls()
		return
	if not GameManager.delete_personal_moment(_selected):
		notice.text = "No se pudo borrar la foto. Tu álbum sigue igual. Puedes reintentar."
		return
	_show_gallery("Foto borrada.")
	_focus_gallery()


func _show_clean() -> void:
	_freeze_preview()
	_camera.reparent(_clean_slot, false)
	controls.hide()
	_clean_screen.show()
	_clean_screen.grab_focus()


func _return_from_clean() -> void:
	_camera.reparent(_stage_slot, false)
	_clean_screen.hide()
	controls.show()
	_clean_button.grab_focus()


func close_panel() -> void:
	if _clean_screen.visible:
		_return_from_clean()
		return
	_camera.clear()
	_draft.clear()
	_recent_invitation.clear()
	super.close_panel()


func _input(event: InputEvent) -> void:
	if visible and _clean_screen.visible:
		if (
			event.is_action_pressed("ui_accept")
			or event.is_action_pressed("ui_cancel")
			or (event is InputEventMouseButton and event.pressed)
			or (event is InputEventScreenTouch and event.pressed)
		):
			_return_from_clean()
			get_viewport().set_input_as_handled()
		return
	if visible and (_replacing or _delete_pending) and event.is_action_pressed("ui_cancel"):
		if _replacement.get_popup().visible or _moments.get_popup().visible:
			return
		_back_to_album()
		get_viewport().set_input_as_handled()
		return
	if (
		visible
		and (
			_moments.get_popup().visible or _frame.get_popup().visible or _pose.get_popup().visible
		)
	):
		return
	super._input(event)
