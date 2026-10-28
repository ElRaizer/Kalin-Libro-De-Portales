extends "res://scripts/features/exploration/exploration_scene.gd"
class_name VillageMission

## Encargos en el mundo: escuchar la necesidad, crear, caminar y entregar.
## El taller ofrece apoyos si la escritura falla. Después hay que transportar
## el objeto y entregarlo al destinatario para completar el encargo.
@export var tasks: Array[VillageTask] = []
@export var free_practice: bool = false
@export var completion_objective: String = "¡Listo! Sigue hasta la salida →"
var task_indices: Array[int] = []
var met: Array[int] = []
var delivered: Array[int] = []
var active_task: int = -1
var carried: Dictionary = {}
var task_support: Dictionary = {}
var task_mistakes: Dictionary = {}
var _seed: int = 1
var _cards_mode: bool = false
var _draft_item: String = ""
var _draft_quality: String = ""
var drafts: Dictionary = {}
var _restoring_draft: bool = false
var _residents: Array[String] = []
var _combination_tasks: Array[String] = []
@onready var mission_panel: Panel = $UI/MissionPanel
@onready var recall: RecallPanel = $UI/MissionPanel/RecallPanel
@onready var noun_choices: HBoxContainer = $UI/MissionPanel/Cards/Nouns
@onready var quality_choices: HBoxContainer = $UI/MissionPanel/Cards/Qualities
@onready var forge_button: Button = $UI/MissionPanel/Forge
@onready var feedback: Label = $UI/MissionPanel/Feedback
@onready var carried_art: MeaningIllustration = $Kalin/Carried


func _ready() -> void:
	var saved: Dictionary = GameManager.get_scene_state(self)
	_seed = int(saved.get("layout_seed", randi_range(1, 2000000000)))
	_restore_tasks(saved)
	_residents = VillageResidents.select(saved, _seed)
	for index: int in range(tasks.size()):
		tasks[index] = tasks[index].duplicate()
	var key: String = GameManager.scene_key_for(self)
	var world: int = 2 if key == "world2_mission1" else (3 if key == "world3_mission1" else 4)
	_combination_tasks = CombinationVariation.needs(
		CombinationCatalog.stage(world), saved, 3, _seed, GameManager.session.learning_progress
	)
	if not _combination_tasks.is_empty():
		for position_index: int in range(task_indices.size()):
			var group: int = task_indices[position_index] / 2
			CombinationCatalog.apply_task(tasks[group * 2], _combination_tasks[position_index])
			CombinationCatalog.apply_task(tasks[group * 2 + 1], _combination_tasks[position_index])
	for position_index: int in range(task_indices.size()):
		var group: int = task_indices[position_index] / 2
		VillageDialogue.personalize(
			tasks[group * 2], _residents[position_index], _seed, variation_context()
		)
		VillageDialogue.personalize(
			tasks[group * 2 + 1], _residents[position_index], _seed, variation_context()
		)
	met = ExerciseProgress.restore_markers(saved.get("mission_met"), 3)
	delivered = ExerciseProgress.restore_markers(saved.get("delivered"), 3)
	active_task = clampi(int(saved.get("active_task", -1)), -1, 2)
	if saved.get("drafts") is Dictionary:
		for index: int in range(3):
			var draft: Variant = saved.drafts.get(str(index))
			if draft is Dictionary:
				drafts[str(index)] = {
					"item": str(draft.get("item", "")).left(100),
					"quality": str(draft.get("quality", "")).left(100),
					"cards": draft.get("cards") is bool and draft.cards,
					"scaffold":
					draft.get("scaffold", {}) if draft.get("scaffold") is Dictionary else {}
				}
	if saved.get("task_support") is Dictionary:
		for index: int in range(3):
			var supported: Variant = saved.task_support.get(str(index), false)
			task_support[str(index)] = supported is bool and supported
	if saved.get("task_mistakes") is Dictionary:
		for index: int in range(3):
			var value: Variant = saved.task_mistakes.get(str(index), 0)
			if (value is int or value is float) and is_finite(float(value)):
				task_mistakes[str(index)] = clampi(int(value), 0, 1000)
	if saved.get("carried") is Dictionary:
		var candidate: Dictionary = saved.carried
		if (
			_valid_item(str(candidate.get("item", "")))
			and _valid_quality(str(candidate.get("quality", "")))
		):
			carried = {
				"item": str(candidate.item),
				"quality": str(candidate.get("quality", "")),
				"supported": candidate.get("supported", true) == true,
				"mistakes": clampi(int(candidate.get("mistakes", 0)), 0, 1000),
				"phase":
				"reconstruction" if str(candidate.get("phase")) == "reconstruction" else "recall"
			}
	for index: int in range(3):
		var task: VillageTask = tasks[task_indices[index]]
		var spot: ExplorationSpot = $Spots.get_node("Recipient%d" % index) as ExplorationSpot
		spot.speaker = task.requester
		spot.lines.assign([task.request])
		spot.spot_texture = GameManager.get_visual_texture(task.requester)
	var recipients: Array[ExplorationSpot] = []
	for index: int in range(3):
		recipients.append($Spots.get_node("Recipient%d" % index))
	VillageResidents.install(self, recipients, _residents, _seed)
	super._ready()
	skip_button.visible = free_practice
	if free_practice:
		skip_button.text = "Volver al mapa"
	$UI/BookButton.pressed.connect(func(): $LibroHechizos.show_book($UI/BookButton))
	$UI/MissionPanel/Close.pressed.connect(_close_workbench)
	forge_button.pressed.connect(_forge)
	recall.submitted.connect(_forge)
	recall.practice_requested.connect(_show_cards)
	recall.support_used.connect(mark_learning_help)
	recall.answer_changed.connect(_scaffold_changed)
	recall.first.text_changed.connect(_draft_changed)
	recall.second.text_changed.connect(_draft_changed)
	for button: Button in noun_choices.get_children():
		button.pressed.connect(
			func():
				_draft_item = str(button.get_meta("word"))
				_update_recipe()
				GameManager.checkpoint(self)
		)
	for button: Button in quality_choices.get_children():
		button.pressed.connect(
			func():
				_draft_quality = str(button.get_meta("word"))
				_update_recipe()
				GameManager.checkpoint(self)
		)
	mission_panel.hide()
	$UI/JournalButton.pressed.connect(
		func():
			$UI/Journal.visible = not $UI/Journal.visible
			if $UI/Journal.visible:
				_update_journal()
	)
	$UI/Journal/Close.pressed.connect(func(): $UI/Journal.hide())
	for index: int in range(3):
		($UI/Journal/Tasks.get_child(index) as Button).pressed.connect(_track_task.bind(index))
	_restore_deliveries()
	_update_carried()
	_update_counter()
	if (
		saved.get("workbench_open", false) == true
		and not is_dialogue_open()
		and active_task >= 0
		and active_task not in delivered
	):
		# La ayuda diferida de ExplorationScene debe terminar antes de reabrirlo;
		# de otro modo interpretaría la restauración como una petición de tarjetas.
		call_deferred("_open_workbench")


func _restore_tasks(saved: Dictionary) -> void:
	var loaded: Variant = saved.get("task_indices")
	if loaded is Array and loaded.size() == 3:
		var requesters: Array[String] = []
		for value: Variant in loaded:
			if (
				not (value is float or value is int)
				or value != int(value)
				or int(value) < 0
				or int(value) >= tasks.size()
			):
				break
			var task: VillageTask = tasks[int(value)]
			if task.requester in requesters:
				break
			requesters.append(task.requester)
			task_indices.append(int(value))
		if task_indices.size() == 3:
			return
	task_indices.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _seed
	for group: int in range(3):
		var first_index: int = group * 2
		var first_score: int = _recall_score(tasks[first_index])
		var second_score: int = _recall_score(tasks[first_index + 1])
		task_indices.append(
			(
				first_index
				+ (
					1
					if second_score < first_score
					else (rng.randi_range(0, 1) if first_score == second_score else 0)
				)
			)
		)
	# Los personajes no conservan siempre el mismo lugar.
	for index: int in range(2, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: int = task_indices[index]
		task_indices[index] = task_indices[other]
		task_indices[other] = swap
	if (
		task_indices == ReplayVariation.previous(saved, "task_indices", [])
		and task_indices.size() > 1
	):
		task_indices.append(task_indices.pop_front())
	_distinct_tasks(saved)


func _distinct_tasks(saved: Dictionary) -> void:
	var options: Array = []
	var preferred: Array[int] = []
	var locked: Array[int] = []
	for index: int in range(task_indices.size()):
		var group: int = task_indices[index] / 2
		options.append([tasks[group * 2], tasks[group * 2 + 1]])
		preferred.append(task_indices[index] % 2)
		if (
			index in saved.get("mission_met", [])
			or index in saved.get("delivered", [])
			or index == int(saved.get("active_task", -1))
		):
			locked.append(index)
	var selected: Array[int] = VillageTaskVariation.distinct(options, preferred, locked)
	for index: int in range(task_indices.size()):
		task_indices[index] = (task_indices[index] & ~1) + selected[index]


func _recall_score(task: VillageTask) -> int:
	var score: int = 0
	for word: String in task.words():
		score += GameManager.learning_record(word).recalls.size()
	return score


func _can_walk() -> bool:
	return not mission_panel.visible and not $UI/Journal.visible and super._can_walk()


func open_spot(spot: ExplorationSpot) -> void:
	if not _can_walk() or not _is_within_reach(spot):
		return
	if spot.name == &"Workbench":
		$UI/Journal.hide()
		_open_workbench()
		return
	if spot.is_goal and delivered.size() < 3:
		_start_dialogue("Kalin", ["Todavía hay amigos esperando su encargo."], false)
		return
	var index: int = _recipient_index(spot)
	if index >= 0 and not carried.is_empty() and index not in delivered:
		_deliver(index, spot)
		return
	if index >= 0:
		active_task = index
		spot.lines.assign(
			[
				(
					tasks[task_indices[index]].success
					if index in delivered
					else tasks[task_indices[index]].request
				)
			]
		)
		spot.set_meta(
			"village_success", tasks[task_indices[index]].success if index in delivered else ""
		)
	super.open_spot(spot)


func _recipient_index(spot: ExplorationSpot) -> int:
	return (
		str(spot.name).trim_prefix("Recipient").to_int()
		if str(spot.name).begins_with("Recipient")
		else -1
	)


func _close_spot(spot: ExplorationSpot) -> void:
	var index: int = _recipient_index(spot)
	if index >= 0:
		if index not in met:
			met.append(index)
		_update_counter()
		return
	super._close_spot(spot)


func _open_workbench() -> void:
	if active_task < 0 or active_task in delivered:
		_start_dialogue("Kalin", ["Hablaré con un amigo para saber qué necesita."], false)
		return
	$UI/Journal.hide()
	_has_target = false
	mission_panel.show()
	$UI/MissionPanel/Cards.hide()
	$UI/MissionPanel/Recipe.hide()
	_cards_mode = false
	_restoring_draft = true
	var task: VillageTask = tasks[task_indices[active_task]]
	var draft: Dictionary = drafts.get(str(active_task), {})
	var scaffold: Dictionary = draft.get("scaffold", {})
	var mode_value: int = clampi(int(scaffold.get("mode", RecallPanel.Mode.WRITE)), 0, 2)
	recall.configure(
		["Objeto o alimento"] if task.quality.is_empty() else ["Objeto o alimento", "Cómo es"],
		[task.item] if task.quality.is_empty() else [task.item, task.quality],
		mode_value
	)
	recall.restore_scaffold(scaffold)
	if mode_value != RecallPanel.Mode.WRITE:
		mark_learning_help()
	recall.second.placeholder_text = "Tu palabra en maya"
	if draft.has("item"):
		recall.first.text = str(draft.item)
		recall.second.text = str(draft.get("quality", "")) if not task.quality.is_empty() else ""
	_restoring_draft = false
	$UI/MissionPanel/Title.text = "Para %s" % task.requester
	$UI/MissionPanel/RequestHint.text = task.request
	feedback.text = (
		"Crea el encargo y llévalo a su destinatario."
		if carried.is_empty()
		else "Crear otro objeto sustituye el que llevas."
	)
	recall.first.grab_focus()
	if draft.get("cards", false) == true:
		_show_cards()
	GameManager.checkpoint(self)


func _close_workbench() -> void:
	_store_draft()
	mission_panel.hide()
	$UI/BookButton.grab_focus()
	GameManager.checkpoint(self)


func _draft_changed(_text: String) -> void:
	if mission_panel.visible and not _restoring_draft:
		GameManager.schedule_checkpoint(self)


func _scaffold_changed() -> void:
	if mission_panel.visible and not _restoring_draft and not recall.is_preparing():
		GameManager.schedule_checkpoint(self)


func _store_draft() -> void:
	if active_task >= 0 and mission_panel.visible and not _restoring_draft:
		var values: Array = [_draft_item, _draft_quality] if _cards_mode else recall.values()
		drafts[str(active_task)] = {
			"item": values[0],
			"quality": values[1],
			"cards": _cards_mode,
			"scaffold": recall.scaffold_state()
		}


func _show_cards() -> void:
	mark_learning_help()
	_cards_mode = true
	recall.hide()
	$UI/MissionPanel/Cards.show()
	$UI/MissionPanel/Recipe.show()
	var draft: Dictionary = drafts.get(str(active_task), {})
	_draft_item = str(draft.get("item", ""))
	_draft_quality = str(draft.get("quality", ""))
	if not _valid_item(_draft_item):
		_draft_item = ""
	if not _valid_quality(_draft_quality):
		_draft_quality = ""
	var task: VillageTask = tasks[task_indices[active_task]]
	quality_choices.visible = not task.quality.is_empty()
	if task.quality.is_empty():
		_draft_quality = ""
	var items: Array[String] = [task.item]
	for word: String in ["mayak", "lak", "k'áanche'", "k'áan", "ja'", "janal", "ich"]:
		if word not in items and items.size() < 4:
			items.append(word)
	var qualities: Array[String] = [task.quality]
	for word: String in ["", "mejen", "nojoch", "chich", "Jats'uts", "ki'"]:
		if word not in qualities and qualities.size() < 4:
			qualities.append(word)
	for index: int in range(4):
		var noun: Button = noun_choices.get_child(index) as Button
		noun.text = items[index]
		noun.set_meta("word", items[index])
		var quality: Button = quality_choices.get_child(index) as Button
		quality.text = qualities[index] if not qualities[index].is_empty() else "Sin cualidad"
		quality.set_meta("word", qualities[index])
	PhraseBuilderController.shuffle_grid(noun_choices, _seed + active_task)
	PhraseBuilderController.shuffle_grid(quality_choices, _seed + active_task + 17)
	feedback.text = "Puedes consultar el libro y probar tus palabras en el mundo."
	_update_recipe()
	GameManager.checkpoint(self)


func _update_recipe() -> void:
	$UI/MissionPanel/Recipe.text = (
		"%s%s"
		% [
			_draft_item if not _draft_item.is_empty() else "Elige un objeto",
			" · " + _draft_quality if not _draft_quality.is_empty() else ""
		]
	)


func _process(delta: float) -> void:
	super._process(delta)
	$UI/JournalButton.visible = (
		not is_dialogue_open() and not mission_panel.visible and not $UI/Journal.visible
	)
	$UI/CarriedLabel.visible = (
		not carried.is_empty()
		and not is_dialogue_open()
		and not mission_panel.visible
		and not $UI/Journal.visible
	)


func _valid_item(word: String) -> bool:
	return word in GameContent.VOCABULARY and int(GameContent.VOCABULARY[word].world) in [2, 4]


func _valid_quality(word: String) -> bool:
	return (
		word.is_empty()
		or word in GameContent.VOCABULARY and int(GameContent.VOCABULARY[word].world) == 3
	)


func _canonical_input(typed: String, quality: bool) -> Dictionary:
	if quality and typed.is_empty():
		return {"word": "", "supported": false}
	for word: String in GameContent.VOCABULARY:
		if not (_valid_quality(word) if quality else _valid_item(word)):
			continue
		var result: Dictionary = WordMatcher.match_word(typed, word)
		if result.correct:
			return result
	return {"word": typed, "supported": true}


func debug_can_answer() -> bool:
	return (
		OS.is_debug_build()
		and mission_panel.visible
		and active_task >= 0
		and active_task not in delivered
	)


func debug_answer() -> void:
	if not debug_can_answer():
		return
	mark_learning_help()
	var task: VillageTask = tasks[task_indices[active_task]]
	if _cards_mode:
		_draft_item = task.item
		_draft_quality = task.quality
		_update_recipe()
	else:
		recall.debug_fill([task.item, task.quality])
	_forge()


func _forge() -> void:
	if not mission_panel.visible or active_task < 0:
		return
	if not _cards_mode and not recall.ready_to_submit():
		return
	var answers: Array = [_draft_item, _draft_quality] if _cards_mode else recall.values()
	var item: Dictionary = _canonical_input(answers[0], false)
	var quality: Dictionary = _canonical_input(answers[1], true)
	var task: VillageTask = tasks[task_indices[active_task]]
	if item.word != task.item or quality.word != task.quality:
		task_mistakes[str(active_task)] = mini(
			int(task_mistakes.get(str(active_task), 0)) + 1, 1000
		)
		mark_learning_help()
		AudioManager.play_sfx("error_suave")
		if not _cards_mode:
			recall.advance_support()
		feedback.text = "Revisa el encargo de %s. La pista te ayudará." % task.requester
		_store_draft()
		GameManager.checkpoint(self)
		return
	carried = {
		"item": item.word,
		"quality": quality.word,
		"supported":
		(
			_cards_mode
			or item.supported
			or quality.supported
			or task_support.get(str(active_task), false)
		),
		"mistakes": int(task_mistakes.get(str(active_task), 0)),
		"phase":
		"reconstruction" if not _cards_mode and recall.mode != RecallPanel.Mode.WRITE else "recall"
	}
	drafts.erase(str(active_task))
	mission_panel.hide()
	magic.restart()
	AudioManager.play_sfx("hechizo_lanzar")
	_update_carried()
	_show_notice("¡Hechizo creado! Camina hasta el amigo que lo necesita.")
	GameManager.checkpoint(self)


func _deliver(index: int, spot: ExplorationSpot) -> void:
	var task: VillageTask = tasks[task_indices[index]]
	if index not in met or carried.item != task.item or carried.quality != task.quality:
		carried.supported = true
		carried.mistakes += 1
		task_mistakes[str(index)] = maxi(
			int(task_mistakes.get(str(index), 0)), int(carried.mistakes)
		)
		task_support[str(index)] = true
		if index not in met:
			met.append(index)
		active_task = index
		AudioManager.play_sfx("error_suave")
		_start_dialogue(task.requester, ["Ese encargo es diferente. " + task.request], false)
		GameManager.checkpoint(self)
		return
	var context: String = LearningContext.identify(
		"delivery/" + GameManager.scene_key_for(self), task.requester, task.words(), false, _seed
	)
	GameManager.record_learning(
		task.words(),
		carried.get("phase", "recall"),
		context,
		bool(carried.supported) or task_support.get(str(index), false),
		int(carried.mistakes)
	)
	AudioManager.play_sfx("acierto")
	delivered.append(index)
	carried.clear()
	_restore_deliveries()
	_update_carried()
	_update_counter()
	_start_dialogue(task.requester, [task.success], false)
	GameManager.checkpoint(self)


func _restore_deliveries() -> void:
	for index: int in range(3):
		var result: MeaningIllustration = (
			$Delivered.get_node("Item%d" % index) as MeaningIllustration
		)
		result.visible = index in delivered
		if result.visible:
			var task: VillageTask = tasks[task_indices[index]]
			var spot: ExplorationSpot = $Spots.get_node("Recipient%d" % index) as ExplorationSpot
			result.position = spot.position + Vector2(-90, -125)
			result.show_meaning(task.item, task.quality)
			spot.mark_examined()
			spot.sprite.texture = GameManager.get_visual_expression(
				task.requester, "reaccion_feliz"
			)
			VillageUseMotion.attach(spot.sprite, result, task.item)


func _update_carried() -> void:
	carried_art.visible = not carried.is_empty()
	$UI/CarriedLabel.text = (
		(
			"Llevas: %s%s"
			% [
				carried.item,
				" · " + str(carried.quality) if not str(carried.quality).is_empty() else ""
			]
		)
		if not carried.is_empty()
		else ""
	)
	if not carried.is_empty():
		carried_art.show_meaning(carried.item, carried.quality)


func _update_counter() -> void:
	if not is_instance_valid(counter_label):
		return
	counter_label.text = "Encargos entregados: %d / 3" % delivered.size()
	_update_journal()
	objective_label.text = (
		(
			"¡Listo! Puedes visitar a tus amigos o volver al mapa."
			if free_practice
			else completion_objective
		)
		if delivered.size() == 3
		else "Habla con tus amigos, crea y entrega sus encargos."
	)


func _track_task(index: int) -> void:
	if index not in met or index in delivered:
		return
	active_task = index
	$UI/Journal.hide()
	_show_notice(
		"Encargo de %s. Crea el objeto en el taller." % tasks[task_indices[index]].requester
	)
	GameManager.checkpoint(self)


func _update_journal() -> void:
	for index: int in range(3):
		var button: Button = $UI/Journal/Tasks.get_child(index) as Button
		button.disabled = index not in met or index in delivered
		var task: VillageTask = tasks[task_indices[index]]
		button.text = (
			"✓ %s · entregado" % task.requester
			if index in delivered
			else (
				"%s: %s" % [task.requester, task.request]
				if index in met
				else "? Habla con este amigo"
			)
		)


func mark_learning_help() -> void:
	if active_task >= 0:
		task_support[str(active_task)] = true
	if not carried.is_empty():
		carried.supported = true
	GameManager.checkpoint(self)


func _show_help() -> void:
	if mission_panel.visible:
		mark_learning_help()
		recall.explain_support()
		guide.highlight(recall)
	elif delivered.size() == 3:
		_show_notice("¡Listo! Puedes volver al mapa." if free_practice else completion_objective)
	else:
		_show_notice("Habla con un amigo. Vuelve al taller y lleva su encargo.")


func _update_arrow() -> void:
	if delivered.size() < 3:
		arrow.hide()
	else:
		super._update_arrow()


func _unhandled_input(event: InputEvent) -> void:
	if $UI/Journal.visible:
		if event.is_action_pressed("ui_cancel"):
			$UI/Journal.hide()
			get_viewport().set_input_as_handled()
		return
	if mission_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_workbench()
			get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func close_transient_ui() -> bool:
	if $UI/Journal.visible:
		$UI/Journal.hide()
		return true
	if not mission_panel.visible:
		return false
	_close_workbench()
	return true


func get_checkpoint_state() -> Dictionary:
	_store_draft()
	var saved: Dictionary = super.get_checkpoint_state()
	if not _combination_tasks.is_empty():
		saved.combination_tasks = _combination_tasks.duplicate()
	saved.merge(
		{
			"layout_seed": _seed,
			"task_indices": task_indices,
			"mission_met": met,
			"delivered": delivered,
			"active_task": active_task,
			"carried": carried.duplicate(true),
			"task_support": task_support.duplicate(true),
			"task_mistakes": task_mistakes.duplicate(true),
			"residents": _residents.duplicate(),
			"drafts": drafts.duplicate(true),
			"workbench_open": mission_panel.visible
		}
	)
	return saved.duplicate(true)


func _restore_objective() -> void:
	_update_counter()
	objective_label.add_theme_color_override("font_color", _objective_color)
