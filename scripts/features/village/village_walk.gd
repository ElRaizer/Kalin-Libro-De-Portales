extends ExplorationScene
class_name VillageWalk

@export var encounters: Array[VillageEncounter] = []
@export var interpret_requests: bool = true
var translated: Array[int] = []
var helped: Array[int] = []
var _translation_button: Button
var solved: Array[int] = []
var _choice_index: int = -1
var _choice_order: Array[int] = []
var _layout_seed: int = 1
var _encounter_plan: Array[int] = []
var _return_scene: String = ""
var _mistakes: int = 0
var _residents: Array[String] = []
var _combination_tasks: Array[String] = []
@onready var choices_root: Node2D = $Choices
@onready var leave_choices: Button = $UI/LeaveChoices


func _ready() -> void:
	for encounter: VillageEncounter in encounters:
		if encounter == null or not encounter.get_configuration_issues().is_empty():
			push_error("Configura los encuentros del paseo antes de jugar.")
			return
	if encounters.size() != 3:
		push_error("El paseo necesita tres encuentros.")
		return
	var saved: Dictionary = GameManager.get_scene_state(self)
	solved = ExerciseProgress.restore_markers(saved.get("solved"), encounters.size())
	translated = ExerciseProgress.restore_markers(saved.get("translated"), encounters.size())
	helped = ExerciseProgress.restore_markers(saved.get("helped"), encounters.size())
	_layout_seed = int(saved.get("layout_seed", randi_range(1, 2000000000)))
	_prepare_encounters(saved)
	var world: int = 2 if GameManager.scene_key_for(self) == "world2_explore1" else 3
	var pool: Array[String] = CombinationCatalog.stage(world)
	_combination_tasks = CombinationVariation.needs(
		pool, saved, 3, _layout_seed, GameManager.session.learning_progress
	)
	if not _combination_tasks.is_empty():
		for index: int in range(3):
			encounters[index].task = encounters[index].task.duplicate()
			CombinationCatalog.apply_task(encounters[index].task, _combination_tasks[index])
			encounters[index].alternate_task = null
			encounters[index].choices = CombinationVariation.choices(
				_combination_tasks[index], pool, _layout_seed + index
			)
	_residents = VillageResidents.select(saved, _layout_seed)
	for index: int in range(encounters.size()):
		encounters[index].task = encounters[index].task.duplicate()
		VillageDialogue.personalize(
			encounters[index].task, _residents[index], _layout_seed, variation_context()
		)
		if encounters[index].alternate_task != null:
			encounters[index].alternate_task = encounters[index].alternate_task.duplicate()
			VillageDialogue.personalize(
				encounters[index].alternate_task,
				_residents[index],
				_layout_seed,
				variation_context()
			)
	_return_scene = str(saved.get("return_scene", ""))
	if not _return_scene.is_empty() and _return_scene in GameContent.SCENE_PATHS:
		next_scene_key = _return_scene
	for index: int in range(encounters.size()):
		var spot: ExplorationSpot = _encounter_spot(index)
		var task: VillageTask = encounters[index].task
		spot.speaker = task.requester
		spot.lines.assign([task.request])
		spot.spot_texture = GameManager.get_visual_texture(task.requester)
	var recipients: Array[ExplorationSpot] = [
		_encounter_spot(0), _encounter_spot(1), _encounter_spot(2)
	]
	VillageResidents.install(self, recipients, _residents, _layout_seed)
	choices_root.z_index = 1000
	super._ready()
	$UI/BookButton.pressed.connect(func(): $LibroHechizos.show_book($UI/BookButton))
	leave_choices.pressed.connect(_close_choices)
	_translation_button = $UI/TranslationButton
	_translation_button.pressed.connect(_translate_request)
	for index: int in range(3):
		(choices_root.get_child(index) as Button).pressed.connect(_choose.bind(index))
	_restore_results()
	_update_counter()
	var pending: int = int(saved.get("choosing", -1))
	if (
		pending >= 0
		and pending < encounters.size()
		and pending not in solved
		and not is_dialogue_open()
	):
		_show_choices(pending, clampi(int(saved.get("mistakes", 0)), 0, 1000))


func _encounter_spot(index: int) -> ExplorationSpot:
	return $Spots.get_node("Visit%d" % index) as ExplorationSpot


func _prepare_encounters(saved: Dictionary) -> void:
	var stored: Variant = saved.get("encounter_plan")
	var valid: bool = stored is Array and stored.size() == encounters.size()
	var used: Array[int] = []
	if valid:
		for value: Variant in stored:
			if (
				not (value is int or value is float)
				or value != int(value)
				or int(value) < 0
				or int(value) >= encounters.size() * 2
				or (int(value) >> 1) in used
			):
				valid = false
				break
			used.append(int(value) >> 1)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _layout_seed
	if valid:
		_encounter_plan.assign(stored)
	else:
		for index: int in ReplayVariation.order(encounters.size(), _layout_seed):
			_encounter_plan.append(
				(
					index * 2 + rng.randi_range(0, 1)
					if encounters[index].alternate_task != null
					else index * 2
				)
			)
		var previous_plan: Variant = ReplayVariation.previous(saved, "encounter_plan", [])
		if _encounter_plan == previous_plan and _encounter_plan.size() > 1:
			_encounter_plan.append(_encounter_plan.pop_front())
	var options: Array = []
	var preferred: Array[int] = []
	var locked: Array = solved.duplicate()
	var pending: int = int(saved.get("choosing", -1))
	for index: int in range(_encounter_plan.size()):
		var encounter: VillageEncounter = encounters[_encounter_plan[index] >> 1]
		var alternatives: Array[VillageTask] = [encounter.task]
		if encounter.alternate_task != null:
			alternatives.append(encounter.alternate_task)
		options.append(alternatives)
		preferred.append(_encounter_plan[index] % 2)
		if index == pending or str(saved.get("active", "")) == "Visit%d" % index:
			locked.append(index)
	var selected: Array[int] = VillageTaskVariation.distinct(options, preferred, locked)
	for index: int in range(_encounter_plan.size()):
		_encounter_plan[index] = (_encounter_plan[index] & ~1) + selected[index]
	# Reparar objetos repetidos puede devolver el plan anterior después del azar.
	# Rotar al final conserva las elecciones válidas sin repetir la visita completa.
	if (
		not valid
		and _encounter_plan == ReplayVariation.previous(saved, "encounter_plan", [])
		and _encounter_plan.size() > 1
	):
		_encounter_plan.append(_encounter_plan.pop_front())
	var session: Array[VillageEncounter] = []
	for code: int in _encounter_plan:
		var encounter: VillageEncounter = encounters[code >> 1].duplicate() as VillageEncounter
		if code % 2 == 1 and encounter.alternate_task != null:
			encounter.task = encounter.alternate_task
		session.append(encounter)
	encounters = session


func _index_for(spot: ExplorationSpot) -> int:
	return (
		str(spot.name).trim_prefix("Visit").to_int() if str(spot.name).begins_with("Visit") else -1
	)


func _can_walk() -> bool:
	return _choice_index < 0 and super._can_walk()


func _process(delta: float) -> void:
	super._process(delta)
	$UI/ObjectivePanel.visible = _choice_index < 0
	if _choice_index >= 0:
		_layout_choices()


func _layout_choices() -> void:
	# El escenario conserva sus objetos reales, y las tres elecciones quedan
	# dentro de pantalla aunque la cámara llegue al límite de la aldea.
	choices_root.global_position = (
		get_viewport().get_canvas_transform().affine_inverse() * Vector2(654, 274)
	)


func open_spot(spot: ExplorationSpot) -> void:
	var index: int = _index_for(spot)
	if index >= 0:
		spot.lines.assign(
			[encounters[index].task.success if index in solved else _request_text(index)]
		)
		spot.set_meta("village_success", encounters[index].task.success if index in solved else "")
	super.open_spot(spot)


func _close_spot(spot: ExplorationSpot) -> void:
	var index: int = _index_for(spot)
	if index >= 0:
		if index not in solved:
			_show_choices(index)
		return
	super._close_spot(spot)


func _show_choices(index: int, previous_mistakes: int = 0) -> void:
	_choice_index = index
	_mistakes = previous_mistakes
	_has_target = false
	_pending_spot = null
	guide.stop()
	camera.offset.x = 230.0
	_layout_choices()
	_choice_order.assign([0, 1, 2])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [_layout_seed, index])
	for cursor: int in range(2, 0, -1):
		var other: int = rng.randi_range(0, cursor)
		var swap: int = _choice_order[cursor]
		_choice_order[cursor] = _choice_order[other]
		_choice_order[other] = swap
	for cursor: int in range(3):
		var spell: ExerciseEntry = encounters[index].choices[_choice_order[cursor]]
		var button: Button = choices_root.get_child(cursor) as Button
		(button.get_node("Art") as MeaningIllustration).show_meaning(spell.noun, spell.adjective)
		(button.get_node("Word") as Label).text = (
			spell.translation
			if interpret_requests
			else spell.noun + ("\n" + spell.adjective if not spell.adjective.is_empty() else "")
		)
		button.tooltip_text = "Elegir " + spell.translation
	choices_root.show()
	leave_choices.show()
	_translation_button.visible = interpret_requests
	_translation_button.disabled = index in translated
	controls_label.text = "Elige un hechizo sobre el escenario · Tab / Enter"
	controls_label.hide()
	objective_label.text = _request_text(index)
	$UI/ObjectivePanel.hide()
	$UI/ChoiceRequest.show()
	$UI/ChoiceRequest/Request.text = (
		"%s necesita tu ayuda:\n%s" % [encounters[index].task.requester, _request_text(index)]
	)
	(choices_root.get_child(0) as Button).grab_focus()
	GameManager.checkpoint(self)


func _choose(button_index: int) -> void:
	if _choice_index < 0 or is_dialogue_open():
		return
	var index: int = _choice_index
	var encounter: VillageEncounter = encounters[index]
	var spell: ExerciseEntry = encounter.choices[_choice_order[button_index]]
	if spell.noun != encounter.task.item or spell.adjective != encounter.task.quality:
		_mistakes += 1
		AudioManager.play_sfx("error_suave")
		_show_notice("Mira lo que representa esa opción y vuelve a leer las fichas de la petición.")
		CharacterReaction.play(choices_root.get_child(button_index), false)
		GameManager.checkpoint(self)
		return
	for word: String in encounter.task.words():
		GameManager.learn_word(word)
	GameManager.record_learning(
		encounter.task.words(),
		"recognition" if interpret_requests else "practice",
		GameManager.scene_key_for(self) + ":visit%d@%d" % [index, _layout_seed],
		not interpret_requests or index in translated or index in helped,
		_mistakes
	)
	AudioManager.play_sfx("acierto")
	AudioManager.play_sfx("hechizo_lanzar")
	solved.append(index)
	_close_choices()
	_restore_results()
	var result: MeaningIllustration = $Results.get_child(index) as MeaningIllustration
	result.celebrate()
	magic.restart()
	_update_counter()
	_start_dialogue(encounter.task.requester, [encounter.task.success], false)
	GameManager.checkpoint(self)


func _close_choices() -> void:
	guide.stop()
	_choice_index = -1
	choices_root.hide()
	$UI/ChoiceRequest.hide()
	leave_choices.hide()
	_translation_button.hide()
	camera.offset.x = 0
	controls_label.text = "← → · Toca para caminar · E para conversar"
	controls_label.show()
	_restore_objective()
	$UI/BookButton.grab_focus()
	GameManager.checkpoint(self)


func _restore_results() -> void:
	for index: int in range(encounters.size()):
		var result: MeaningIllustration = $Results.get_child(index) as MeaningIllustration
		result.visible = index in solved
		if not result.visible:
			continue
		var spot: ExplorationSpot = _encounter_spot(index)
		spot.mark_examined()
		spot.z_index = 1
		spot.sprite.texture = GameManager.get_visual_expression(
			encounters[index].task.requester, "reaccion_feliz"
		)
		result.position = spot.position + Vector2(-90, -125)
		result.show_meaning(encounters[index].task.item, encounters[index].task.quality)
		VillageUseMotion.attach(
			spot.sprite, result, encounters[index].task.item, encounters[index].task.requester
		)
		if free_roam:
			spot.z_index = int(spot.position.y)
			result.z_index = int(spot.position.y) - 1
	if free_roam and _roaming != null:
		_roaming.ensure_safe(navigation_obstacles())


func _update_counter() -> void:
	if is_instance_valid(counter_label):
		counter_label.text = (
			"Amigos ayudados: %d / %d · Puedes seguir el sendero"
			% [solved.size(), encounters.size()]
		)


func _restore_objective() -> void:
	if _choice_index >= 0:
		objective_label.text = _request_text(_choice_index)
		objective_label.remove_theme_color_override("font_color")
	else:
		super._restore_objective()


func mark_learning_help() -> void:
	var index: int = (
		_choice_index
		if _choice_index >= 0
		else (_index_for(_active_spot) if is_instance_valid(_active_spot) else -1)
	)
	if index >= 0 and index not in helped:
		helped.append(index)
		GameManager.checkpoint(self)


func close_transient_ui() -> bool:
	if _choice_index < 0:
		return false
	_close_choices()
	return true


func _show_help() -> void:
	if _choice_index >= 0:
		mark_learning_help()
		var task: VillageTask = encounters[_choice_index].task
		for index: int in range(_choice_order.size()):
			var spell: ExerciseEntry = encounters[_choice_index].choices[_choice_order[index]]
			if spell.noun == task.item and spell.adjective == task.quality:
				guide.point_at(choices_root.get_child(index))
				break
	else:
		super._show_help()


func _show_orientation() -> void:
	if _choice_index >= 0:
		guide.highlight($UI/ChoiceRequest)
	else:
		super._show_orientation()


func get_checkpoint_state() -> Dictionary:
	var saved: Dictionary = super.get_checkpoint_state()
	if not _combination_tasks.is_empty():
		saved.combination_tasks = _combination_tasks.duplicate()
	saved.merge(
		{
			"solved": solved.duplicate(),
			"choosing": _choice_index,
			"mistakes": _mistakes,
			"layout_seed": _layout_seed,
			"encounter_plan": _encounter_plan.duplicate(),
			"residents": _residents.duplicate(),
			"return_scene": _return_scene,
			"translated": translated.duplicate(),
			"helped": helped.duplicate()
		}
	)
	return saved.duplicate(true)


func _request_text(index: int) -> String:
	var task: VillageTask = encounters[index].task
	if not interpret_requests or index in translated:
		return task.request
	return (
		task.purpose
		+ "\n"
		+ task.item
		+ (" · " + task.quality if not task.quality.is_empty() else "")
	)


func _translate_request() -> void:
	if _choice_index < 0:
		return
	if _choice_index not in translated:
		translated.append(_choice_index)
	_translation_button.disabled = true
	$UI/ChoiceRequest/Request.text = (
		"%s necesita tu ayuda:\n%s"
		% [encounters[_choice_index].task.requester, _request_text(_choice_index)]
	)
	GameManager.checkpoint(self)


func navigation_obstacles() -> Array[Rect2]:
	var obstacles: Array[Rect2] = super.navigation_obstacles()
	for index: int in solved:
		var spot: ExplorationSpot = _encounter_spot(index)
		obstacles.append(Rect2(spot.position - Vector2(180, 25), Vector2(360, 50)))
	return obstacles
