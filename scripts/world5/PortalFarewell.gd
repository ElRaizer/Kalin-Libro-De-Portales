extends ExplorationScene
class_name PortalFarewell

## El cierre se prepara caminando, usando las expresiones ya descubiertas y
## devolviendo las páginas al portal. No añade vocabulario ni acredita recuerdo libre.
@export var gifts: Array[ExerciseEntry] = []
var collected: Array[int] = []
var placed: Array[int] = []
var choice_index := -1
var selected_page := ""
var _seed := 1
var _choices: Array[String] = []
const PAGE_KEYS: Array[String] = ["paths", "home", "friends"]
const PAGE_NAMES: Array[String] = ["Caminos", "Hogar", "Amistad"]
@onready var choices_panel: Panel = $UI/FarewellChoices
@onready var assembly: Panel = $UI/Assembly

func _ready() -> void:
	var saved := GameManager.get_scene_state(self)
	collected = ExerciseProgress.restore_markers(saved.get("gifts"), 3)
	placed = ExerciseProgress.restore_markers(saved.get("pages"), 3)
	if collected.size() < 3:
		placed.clear()
	_seed = int(saved.get("layout_seed", randi_range(1, 2000000000)))
	for index: int in range(3):
		var spot := _friend(index)
		spot.speaker = gifts[index].animal
		spot.lines.assign([gifts[index].request])
		spot.spot_texture = GameManager.get_visual_texture(gifts[index].animal)
	var recipients: Array[ExplorationSpot] = [_friend(0), _friend(1), _friend(2)]
	var residents: Array[String] = [gifts[0].animal, gifts[1].animal, gifts[2].animal]
	VillageResidents.install(self, recipients, residents, _seed)
	super._ready()
	skip_button.hide()
	$UI/BookButton.pressed.connect(func(): $LibroHechizos.show_book($UI/BookButton))
	$UI/FarewellChoices/Close.pressed.connect(_close_choices)
	for index: int in range(4):
		($UI/FarewellChoices/Options.get_child(index) as Button).pressed.connect(_choose.bind(index))
	for index: int in range(3):
		var card := $UI/Assembly/Cards.get_child(index) as DraggableWordButton
		card.pressed.connect(_select_page.bind(PAGE_KEYS[index]))
		var slot := $UI/Assembly/Slots.get_child(index) as WordDropSlot
		slot.word_dropped.connect(_place_page.bind(index))
		slot.gui_input.connect(_slot_input.bind(index))
	$UI/Assembly/Close.pressed.connect(func(): assembly.hide())
	$UI/Assembly/Continue.pressed.connect(_finish)
	_update_counter()
	_restore_pages()
	if saved.get("assembly_open", false) == true and collected.size() == 3 and not is_dialogue_open():
		assembly.show()
	elif int(saved.get("farewell_choice", -1)) in range(3) and not is_dialogue_open():
		_show_choices(int(saved.farewell_choice))

func _friend(index: int) -> ExplorationSpot:
	return $Spots.get_node("Friend%d" % index) as ExplorationSpot

func _can_walk() -> bool:
	return not choices_panel.visible and not assembly.visible and super._can_walk()

func open_spot(spot: ExplorationSpot) -> void:
	if not _can_walk() or not _is_within_reach(spot):
		return
	if spot.is_goal:
		if collected.size() < 3:
			_start_dialogue("Kalin", ["Me despediré de mis tres amigos antes de preparar el portal."], false)
		else:
			_has_target = false
			assembly.show()
			_restore_pages()
			($UI/Assembly/Cards.get_child(0) as Button).grab_focus()
			GameManager.checkpoint(self)
		return
	var index := _friend_index(spot)
	if index >= 0 and index in collected:
		spot.lines.assign([gifts[index].translation])
	super.open_spot(spot)

func _friend_index(spot: ExplorationSpot) -> int:
	return str(spot.name).trim_prefix("Friend").to_int() if str(spot.name).begins_with("Friend") else -1

func _close_spot(spot: ExplorationSpot) -> void:
	var index := _friend_index(spot)
	if index >= 0:
		if index not in collected:
			_show_choices(index)
		return
	super._close_spot(spot)

func _show_choices(index: int) -> void:
	choice_index = index
	_has_target = false
	$UI/FarewellChoices/Request.text = gifts[index].request
	_choices.assign(gifts[index].options)
	var order := ReplayVariation.order(_choices.size(), _seed + index)
	var original := _choices.duplicate()
	for cursor: int in range(order.size()):
		_choices[cursor] = original[order[cursor]]
		var button := $UI/FarewellChoices/Options.get_child(cursor) as Button
		button.text = _choices[cursor]
	choices_panel.show()
	($UI/FarewellChoices/Options.get_child(0) as Button).grab_focus()
	GameManager.checkpoint(self)

func _choose(index: int) -> void:
	if choice_index < 0 or not choices_panel.visible:
		return
	var gift := gifts[choice_index]
	var phrase := _choices[index]
	if phrase != gift.correct:
		$UI/FarewellChoices/Feedback.text = "Esa expresión dice: " + str(GameManager.get_vocabulary_entry(phrase).get("spanish", ""))
		return
	var completed := choice_index
	GameManager.record_learning([phrase], "practice", ExerciseRecallFlow.context("farewell", gift.animal, [phrase], true, _seed), true)
	collected.append(completed)
	_friend(completed).mark_examined()
	_friend(completed).sprite.texture = GameManager.get_visual_expression(gift.animal, "reaccion_feliz")
	_close_choices()
	magic.restart()
	_update_counter()
	_start_dialogue(gift.animal, [gift.translation, "Esta página guardará el recuerdo de nuestra amistad."], false)
	GameManager.checkpoint(self)

func debug_can_answer() -> bool:
	return OS.is_debug_build() and (choices_panel.visible and choice_index >= 0 or assembly.visible and placed.size() < 3)

func debug_answer() -> void:
	if not debug_can_answer():
		return
	if choices_panel.visible:
		_choose(_choices.find(gifts[choice_index].correct))
	else:
		for index: int in range(3):
			if index not in placed:
				_place_page(PAGE_KEYS[index], index)
				break

func _close_choices() -> void:
	choice_index = -1
	choices_panel.hide()
	$UI/FarewellChoices/Feedback.text = "Elige lo que quieres expresar."
	GameManager.checkpoint(self)

func _select_page(key: String) -> void:
	selected_page = key
	$UI/Assembly/Hint.text = "Ahora toca el lugar de la página «%s», o arrástrala hasta él." % PAGE_NAMES[PAGE_KEYS.find(key)]

func _slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT or event.is_action_pressed("ui_accept"):
		_place_page(selected_page, index)
		get_viewport().set_input_as_handled()

func _place_page(key: String, index: int) -> void:
	if not assembly.visible or collected.size() < 3 or index in placed:
		return
	if key != PAGE_KEYS[index]:
		$UI/Assembly/Hint.text = "Busca el mismo símbolo que aparece en la página."
		return
	placed.append(index)
	selected_page = ""
	_restore_pages()
	GameManager.checkpoint(self)

func _restore_pages() -> void:
	for index: int in range(3):
		var card := $UI/Assembly/Cards.get_child(index) as Button
		card.disabled = index in placed
		var slot := $UI/Assembly/Slots.get_child(index) as WordDropSlot
		slot.text = "\n" + PAGE_NAMES[index]
		slot.add_theme_color_override("font_color", Color("176b67"))
		if index in placed:
			PhraseBuilderController.mark_slot(slot, true)
		else:
			PhraseBuilderController.clear_mark(slot)
	$UI/Assembly/Continue.visible = placed.size() == 3
	$UI/Assembly/Hint.text = "¡El portal guarda lo que vivimos! Ya puedo despedirme." if placed.size() == 3 else "Cada página guarda un recuerdo. Tócala y elige su lugar, o arrástrala."
	$UI/Assembly/PortalVisual.set_energy(float(placed.size()) * 8.0 / 3.0)
	if placed.size() == 3:
		$UI/Assembly/Continue.grab_focus()

func _update_counter() -> void:
	if not is_instance_valid(counter_label):
		return
	counter_label.text = "Recuerdos compartidos: %d / 3" % collected.size()
	objective_label.text = "Despídete de tus amigos y reúne las páginas." if collected.size() < 3 else "Lleva los recuerdos al portal →"
	for index: int in range(collected.size()):
		_friend(collected[index]).sprite.texture = GameManager.get_visual_expression(gifts[collected[index]].animal, "reaccion_feliz")

func _finish() -> void:
	if placed.size() != 3:
		return
	assembly.hide()
	super._finish()

func close_transient_ui() -> bool:
	if choices_panel.visible:
		_close_choices()
		return true
	if assembly.visible:
		assembly.hide()
		GameManager.checkpoint(self)
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if choices_panel.visible or assembly.visible:
		return
	super._unhandled_input(event)

func _show_help() -> void:
	if choices_panel.visible:
		guide.point_at($UI/FarewellChoices/Options.get_child(0))
	elif assembly.visible:
		for index: int in range(3):
			if index not in placed:
				guide.drag_between($UI/Assembly/Cards.get_child(index), $UI/Assembly/Slots.get_child(index))
				return
	else:
		super._show_help()

func get_checkpoint_state() -> Dictionary:
	var saved := super.get_checkpoint_state()
	saved.merge({"gifts": collected.duplicate(), "pages": placed.duplicate(), "farewell_choice": choice_index, "assembly_open": assembly.visible, "layout_seed": _seed})
	return saved
