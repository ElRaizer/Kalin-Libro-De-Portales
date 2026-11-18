extends VillagePanel
class_name GardenStoragePanel

var profile: GardenProfile
var editor: GardenEditor
var _slots: VBoxContainer
var _inventory: VBoxContainer
var _capacity: Label
var _confirmation: HBoxContainer
var _confirm: Button
var _pending_id: int = 0
var _pending_slot: int = -1
var _undo: Button


func _build_content() -> void:
	heading.text = "Mis acomodos y mis copias"
	_capacity = add_label(body, "")
	add_label(
		body,
		"Guardar y mover no gastan puntos ni liberan capacidad. Eliminar una copia sí libera un espacio; su diseño permanece."
	)
	_slots = VBoxContainer.new()
	_slots.add_theme_constant_override("separation", 12)
	body.add_child(_slots)
	add_label(
		body,
		"Restaurar un acomodo usa las mismas copias. Los muebles de esta parcela que sobren irán al almacén. Si falta una pieza, conservamos todo el jardín."
	)
	_inventory = VBoxContainer.new()
	_inventory.add_theme_constant_override("separation", 8)
	body.add_child(_inventory)
	_confirmation = HBoxContainer.new()
	_confirmation.add_theme_constant_override("separation", 12)
	content.add_child(_confirmation)
	content.move_child(_confirmation, notice.get_index())
	_confirm = add_button(_confirmation, "Confirmar", confirm_action)
	add_button(_confirmation, "Cancelar", cancel_action)
	_confirmation.hide()
	_undo = add_button(footer, "Deshacer última edición", undo_edit)


func open_storage(origin: Control) -> void:
	if visible or get_tree().paused:
		return
	_pending_id = 0
	_pending_slot = -1
	refresh()
	notice.text = "Los cambios se guardan al confirmarlos. Deshacer está disponible durante esta visita."
	open_panel(origin)


func refresh() -> void:
	var session: GameSession = GameManager.session
	_capacity.text = (
		"Copias: %d de %d · límite compartido por los tres jardines y el almacén."
		% [session.garden.objects.size(), GardenLayout.MAX_OBJECTS]
	)
	for container: VBoxContainer in [_slots, _inventory]:
		for child: Node in container.get_children():
			container.remove_child(child)
			child.queue_free()
	var saved: Array = session.garden_compositions.get(editor.district, [])
	for index: int in range(maxi(profile.composition_slots, saved.size())):
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_slots.add_child(row)
		var occupied: bool = index < saved.size() and not saved[index].is_empty()
		var title: String = (
			"Acomodo %d · %s"
			% [index + 1, "%d muebles" % saved[index].objects.size() if occupied else "vacío"]
		)
		var label: Label = add_label(row, title)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var save_button: Button = add_button(row, "Guardar aquí", request_save.bind(index))
		save_button.disabled = index >= profile.composition_slots
		var restore_button: Button = add_button(row, "Restaurar", restore_composition.bind(index))
		restore_button.disabled = not occupied
	for object: Dictionary in session.garden.objects:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_inventory.add_child(row)
		var location: String = (
			"Almacén"
			if object.stored
			else {"patio": "Patio", "workshop": "Taller", "shore": "Orilla"}[object.district]
		)
		var label: Label = add_label(
			row,
			"#%d · %s · %s" % [int(object.id), CombinationCatalog.targets()[object.key], location]
		)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var remove: Button = add_button(row, "Eliminar copia", request_delete.bind(int(object.id)))
		remove.size_flags_horizontal = Control.SIZE_SHRINK_END
	_undo.disabled = not editor.has_undo()
	_confirmation.visible = _pending_id != 0 or _pending_slot >= 0
	layout_changed.emit()
	refresh_focus()


func request_delete(id: int) -> void:
	_pending_id = id
	_pending_slot = -1
	_confirmation.show()
	_confirm.text = "Eliminar copia #%d" % id
	notice.text = "Se elimina sólo esta copia. El diseño y los acomodos guardados permanecen. Puedes deshacer durante esta visita."
	_confirm.grab_focus()
	refresh_focus()


func request_save(slot: int) -> void:
	_pending_id = 0
	_pending_slot = slot
	_confirmation.show()
	_confirm.text = "Guardar en acomodo %d" % (slot + 1)
	notice.text = "Se guardará el jardín colocado en esta parcela, sustituyendo ese espacio. El almacén no forma parte del acomodo."
	_confirm.grab_focus()
	refresh_focus()


func confirm_action() -> void:
	var message: String = ""
	if _pending_id != 0:
		message = editor.delete_copy(_pending_id)
	elif _pending_slot >= 0:
		if not GameManager.save_garden_composition(
			editor.district, _pending_slot, profile.composition_slots
		):
			message = "No se pudo guardar el acomodo. Conservamos el anterior; puedes reintentar."
	else:
		return
	if message.is_empty():
		_pending_id = 0
		_pending_slot = -1
		refresh()
		close_button.grab_focus()
		notice.text = "Cambio guardado. Tus diseños y puntos se conservan."
	else:
		notice.text = message


func cancel_action() -> void:
	_pending_id = 0
	_pending_slot = -1
	_confirmation.hide()
	notice.text = "Cancelado. Conservamos tus copias y acomodos."
	close_button.grab_focus()
	refresh_focus()


func restore_composition(slot: int) -> void:
	_pending_id = 0
	_pending_slot = -1
	var message: String = editor.apply_composition(slot)
	refresh()
	close_button.grab_focus()
	notice.text = (
		"Acomodo restaurado. Puedes deshacer esta edición." if message.is_empty() else message
	)


func undo_edit() -> void:
	_pending_id = 0
	_pending_slot = -1
	editor.undo()
	refresh()
	notice.text = (
		"Última edición deshecha."
		if not editor.has_undo()
		else "No se pudo deshacer. Conservamos el jardín; puedes reintentar."
	)


func close_panel() -> void:
	_pending_id = 0
	_pending_slot = -1
	_confirmation.hide()
	super.close_panel()
