extends ExplorationScene
class_name PortalFarewell

## Cortesía y una preferencia personal que vuelve a verse en el libro al llegar a casa.
@export var gifts: Array[ExerciseEntry] = []
var collected: Array[int] = []
var memory: Dictionary = {}
var _memories: Array[Dictionary] = []
var choice_index: int = -1
var _seed: int = 1
var _choices: Array[String] = []
var _friend_memories: Array[String] = []
@onready var choices_panel: Panel = $UI/FarewellChoices
@onready var memory_choice: MemoryChoice = $UI/MemoryChoice


func _ready() -> void:
	var saved: Dictionary = GameManager.get_scene_state(self)
	collected = ExerciseProgress.restore_markers(saved.get("gifts"), 3)
	memory = VillageMemory.normalize(saved.get("memory"))
	if collected.size() < 3:
		memory.clear()
	_seed = int(saved.get("layout_seed", randi_range(1, 2000000000)))
	var visits: Array[Dictionary] = _mission_visits()
	for index: int in range(3):
		_friend_memories.append(_memory_line(gifts[index], visits))
		var spot: ExplorationSpot = _friend(index)
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
		($UI/FarewellChoices/Options.get_child(index) as Button).pressed.connect(
			_choose.bind(index)
		)
	memory_choice.selected.connect(_select_memory)
	memory_choice.confirmed.connect(_finish)
	memory_choice.closed.connect(func(): GameManager.checkpoint(self))
	_update_counter()
	if saved.get("memory_open", false) == true and collected.size() == 3 and not is_dialogue_open():
		_open_memory_choice()
	elif int(saved.get("farewell_choice", -1)) in range(3) and not is_dialogue_open():
		_show_choices(int(saved.farewell_choice))


func _friend(index: int) -> ExplorationSpot:
	return $Spots.get_node("Friend%d" % index) as ExplorationSpot


func _can_walk() -> bool:
	return not choices_panel.visible and not memory_choice.visible and super._can_walk()


func open_spot(spot: ExplorationSpot) -> void:
	if not _can_walk() or not _is_within_reach(spot):
		return
	if spot.is_goal:
		if collected.size() < 3:
			_start_dialogue(
				"Kalin", ["Me despediré de mis tres amigos antes de preparar el portal."], false
			)
		else:
			_has_target = false
			_open_memory_choice()
			GameManager.checkpoint(self)
		return
	var index: int = _friend_index(spot)
	if index >= 0 and index in collected:
		spot.lines.assign(_friend_lines(index))
	super.open_spot(spot)


func _friend_index(spot: ExplorationSpot) -> int:
	return (
		str(spot.name).trim_prefix("Friend").to_int()
		if str(spot.name).begins_with("Friend")
		else -1
	)


func _close_spot(spot: ExplorationSpot) -> void:
	var index: int = _friend_index(spot)
	if index >= 0:
		if index not in collected:
			_show_choices(index)
		return
	super._close_spot(spot)


func _show_choices(index: int) -> void:
	if index not in range(3) or index in collected:
		return
	guide.stop()
	choice_index = index
	_has_target = false
	$UI/FarewellChoices/Request.text = gifts[index].request
	_choices.assign(gifts[index].options)
	var order: Array[int] = ReplayVariation.order(_choices.size(), _seed + index)
	var original: Array = _choices.duplicate()
	for cursor: int in range(order.size()):
		_choices[cursor] = original[order[cursor]]
		var button: Button = $UI/FarewellChoices/Options.get_child(cursor) as Button
		button.text = (
			_choices[cursor]
			+ " · "
			+ str(VocabularyCatalog.entry(_choices[cursor]).get("spanish", ""))
		)
	choices_panel.show()
	($UI/FarewellChoices/Options.get_child(0) as Button).grab_focus()
	GameManager.checkpoint(self)


func _choose(index: int) -> void:
	if choice_index < 0 or not choices_panel.visible or index not in range(_choices.size()):
		return
	var gift: ExerciseEntry = gifts[choice_index]
	var phrase: String = _choices[index]
	# La recuperación evaluada ya ocurrió en el portal. Aquí se elige qué expresar,
	# con traducción visible y evidencia de práctica apoyada, sin otra respuesta obligatoria.
	var completed: int = choice_index
	GameManager.record_learning(
		[phrase],
		"practice",
		LearningContext.identify("farewell", gift.animal, [phrase], true, _seed),
		true
	)
	AudioManager.play_sfx("pagina_pasar")
	collected.append(completed)
	_friend(completed).mark_examined()
	_friend(completed).sprite.texture = GameManager.get_visual_expression(
		gift.animal, "reaccion_feliz"
	)
	_close_choices()
	_update_counter()
	_active_spot = _friend(completed)
	_start_dialogue(gift.animal, _friend_lines(completed), false)
	GameManager.checkpoint(self)


func debug_can_answer() -> bool:
	return OS.is_debug_build() and choices_panel.visible and choice_index >= 0


func debug_answer() -> void:
	if debug_can_answer():
		_choose(_choices.find(gifts[choice_index].correct))


func _close_choices() -> void:
	choice_index = -1
	choices_panel.hide()
	$UI/FarewellChoices/Feedback.text = "Elige lo que quieres expresar."
	GameManager.checkpoint(self)


func _open_memory_choice() -> void:
	_place_kalin($Spots/Salida.position.x - 360)
	camera.offset.x = 280
	camera.reset_smoothing()
	_memories = VillageMemory.options(_mission_visits(), gifts)
	memory_choice.open_choice(_memories, memory)
	$UI/ObjectivePanel.hide()
	controls_label.hide()
	prompt_button.hide()


func _mission_visits() -> Array[Dictionary]:
	var visits: Array[Dictionary] = []
	for world: int in [2, 3, 4]:
		visits.append(GameManager.saved_scene_state("world%d_mission1" % world))
	return visits


func _friend_lines(index: int) -> Array[String]:
	return [
		_friend_memories[index],
		(
			gifts[index].translation
			if _friend_memories[index] != gifts[index].translation
			else "Esta página guardará el recuerdo de nuestra amistad."
		)
	]


func _memory_line(gift: ExerciseEntry, visits: Array[Dictionary]) -> String:
	var shared: Dictionary = VillageMemory.for_animal(visits, gift.animal)
	if shared.is_empty():
		return gift.translation
	var item_name: String = str(VocabularyCatalog.entry(shared.item).get("spanish", shared.item))
	var quality_name: String = (
		str(VocabularyCatalog.entry(shared.quality).get("spanish", shared.quality))
		if not shared.quality.is_empty()
		else ""
	)
	var description: String = (
		item_name + (" · " + quality_name if not quality_name.is_empty() else "")
	)
	return "Recuerdo lo que preparaste para mí: %s. ¡Ahora es parte de nuestra aldea!" % description


func _select_memory(value: Dictionary) -> void:
	if collected.size() != 3:
		return
	memory = VillageMemory.normalize(value)
	AudioManager.play_sfx("portal_energia")
	GameManager.checkpoint(self)


func _process(delta: float) -> void:
	super._process(delta)
	if choices_panel.visible or memory_choice.visible:
		guide.stop()
	$UI/ObjectivePanel.visible = not memory_choice.visible and not choices_panel.visible
	controls_label.visible = not memory_choice.visible and not choices_panel.visible
	if not memory_choice.visible:
		camera.offset.x = 0


func _update_counter() -> void:
	if not is_instance_valid(counter_label):
		return
	counter_label.text = "Recuerdos compartidos: %d / 3" % collected.size()
	objective_label.text = (
		"Despídete de tus amigos."
		if collected.size() < 3
		else "Elige un recuerdo para llevar a casa →"
	)
	for index: int in range(collected.size()):
		_friend(collected[index]).sprite.texture = GameManager.get_visual_expression(
			gifts[collected[index]].animal, "reaccion_feliz"
		)


func _finish() -> void:
	if collected.size() != 3 or memory.is_empty():
		return
	memory_choice.hide()
	super._finish()


func close_transient_ui() -> bool:
	if choices_panel.visible:
		_close_choices()
		return true
	if memory_choice.visible:
		memory_choice.hide()
		GameManager.checkpoint(self)
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if choices_panel.visible or memory_choice.visible:
		return
	super._unhandled_input(event)


func _show_help() -> void:
	if choices_panel.visible:
		guide.point_at($UI/FarewellChoices/Options.get_child(0))
	elif memory_choice.visible:
		guide.highlight(memory_choice)
	else:
		super._show_help()


func _show_orientation() -> void:
	if memory_choice.visible or choices_panel.visible:
		guide.stop()
		return
	super._show_orientation()


func get_checkpoint_state() -> Dictionary:
	var saved: Dictionary = super.get_checkpoint_state()
	saved.merge(
		{
			"gifts": collected.duplicate(),
			"memory": memory.duplicate(true),
			"farewell_choice": choice_index,
			"memory_open": memory_choice.visible,
			"layout_seed": _seed
		}
	)
	return saved.duplicate(true)
