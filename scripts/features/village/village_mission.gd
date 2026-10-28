extends "res://scripts/features/exploration/exploration_scene.gd"
class_name VillageMission

## Encargos en el mundo: escuchar la necesidad, crear, caminar y entregar.
## El taller ofrece apoyos si la escritura falla. Después hay que transportar
## el objeto y entregarlo al destinatario para completar el encargo.
@export var tasks: Array[VillageTask] = []
@export var gathering_title: String = "¡Una aldea para compartir!"
@export_enum("home", "party", "meal") var mission_kind: String = "meal"
var gathering_seen: bool = false
@export var completion_objective: String = "¡Listo! Sigue hasta la salida →"
var task_indices: Array[int] = []
var _mission: VillageMissionState = VillageMissionState.new()
var _workbench_attempt: LearningAttempt = LearningAttempt.new()
var met: Array[int]:
	get:
		return _mission.met
	set(value):
		_mission.met = value
var delivered: Array[int]:
	get:
		return _mission.delivered
	set(value):
		_mission.delivered = value
var active_task: int:
	get:
		return _mission.active_task
	set(value):
		_mission.active_task = value
var carried: Dictionary:
	get:
		return _mission.carried
	set(value):
		_mission.carried = value
var task_support: Dictionary:
	get:
		return _mission.task_support
	set(value):
		_mission.task_support = value
var task_mistakes: Dictionary:
	get:
		return _mission.task_mistakes
	set(value):
		_mission.task_mistakes = value
var _seed: int = 1
var _cards_mode: bool = false
var _draft_item: String = ""
var _draft_quality: String = ""
var drafts: Dictionary:
	get:
		return _mission.drafts
	set(value):
		_mission.drafts = value
var _restoring_draft: bool = false
var _residents: Array[String] = []
var _combination_tasks: Array[String] = []
@onready var gathering: VillageGathering = $UI/VillageGathering
@onready var mission_panel: Panel = $UI/MissionPanel
@onready var recall: RecallPanel = $UI/MissionPanel/RecallPanel
@onready var noun_choices: HBoxContainer = $UI/MissionPanel/Cards/Nouns
@onready var quality_choices: HBoxContainer = $UI/MissionPanel/Cards/Qualities
@onready var forge_button: Button = $UI/MissionPanel/Forge
@onready var feedback: Label = $UI/MissionPanel/Feedback
@onready var carried_art: MeaningIllustration = $Kalin/Carried


func _ready() -> void:
	var saved: Dictionary = GameManager.get_scene_state(self)
	gathering_seen = saved.get("gathering_seen") is bool and saved.gathering_seen
	gathering.closed.connect(_on_gathering_closed)
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
	var items: Array[String] = []
	var qualities: Array[String] = [""]
	for word: String in GameContent.VOCABULARY:
		if _valid_item(word):
			items.append(word)
		elif _valid_quality(word):
			qualities.append(word)
	_mission.restore(saved, items, qualities)
	gathering_seen = gathering_seen and delivered.size() == 3
	for index: int in range(3):
		var task: VillageTask = tasks[task_indices[index]]
		var spot: ExplorationSpot = $Spots.get_node("Recipient%d" % index) as ExplorationSpot
		spot.speaker = task.requester
		spot.lines.assign([task.request])
		spot.spot_texture = GameManager.get_visual_texture(task.requester)
	var recipients: Array[ExplorationSpot] = []
	for index: int in range(3):
		recipients.append($Spots.get_node("Recipient%d" % index))
	VillageResidents.install(self, recipients, _residents, _seed, true)
	for index: int in range(3):
		($UI/Direct.get_child(index) as Button).pressed.connect(visit_task.bind(index))
	$UI/Direct/Create.pressed.connect(visit_workbench)
	$UI/Direct/Exit.pressed.connect(visit_exit)
	super._ready()
	skip_button.hide()
	$UI/BookButton.pressed.connect(func(): $LibroHechizos.show_book($UI/BookButton))
	$UI/MissionPanel/Close.pressed.connect(_close_workbench)
	forge_button.pressed.connect(_forge)
	recall.submitted.connect(_forge)
	recall.practice_requested.connect(_show_cards)
	recall.support_used.connect(_on_recall_support)
	ExerciseRecallFlow.bind_support(recall, _workbench_attempt)
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
	$UI/VillageButton.text = "Mi aldea"
	$UI/VillageButton.pressed.connect(
		func() -> void: GameManager.visit_home(GameManager.scene_key_for(self))
	)
	$UI/JournalButton.text = "Encargos y lugares"
	$UI/JournalButton.pressed.connect(toggle_journal)
	$UI/Journal/Close.pressed.connect(toggle_journal)
	for index: int in range(3):
		($UI/Journal/Tasks.get_child(index) as Button).pressed.connect(_track_task.bind(index))
	_restore_deliveries()
	_update_carried()
	_update_counter()
	call_deferred("_show_gathering")
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
	return (
		not gathering.visible
		and not mission_panel.visible
		and not $UI/Journal.visible
		and super._can_walk()
	)


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
	_workbench_attempt = LearningAttempt.new()
	_workbench_attempt.restore(draft.get("attempt"))
	_workbench_attempt.begin(
		LearningContext.identify(
			"delivery/" + GameManager.scene_key_for(self),
			task.requester,
			task.words(),
			false,
			_seed
		)
	)
	var scaffold: Dictionary = draft.get("scaffold", {})
	var mode_value: int = clampi(int(scaffold.get("mode", RecallPanel.Mode.WRITE)), 0, 2)
	recall.configure(
		["Objeto o alimento"] if task.quality.is_empty() else ["Objeto o alimento", "Cómo es"],
		[task.item] if task.quality.is_empty() else [task.item, task.quality],
		mode_value
	)
	recall.restore_scaffold(scaffold)
	if mode_value != RecallPanel.Mode.WRITE:
		_on_recall_support()
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
			"scaffold": recall.scaffold_state(),
			"attempt": _workbench_attempt.snapshot()
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
	$UI/Direct.visible = $UI/Journal.visible and not is_dialogue_open()
	var world_ui: bool = not gathering.visible and not mission_panel.visible
	$UI/ObjectivePanel.visible = world_ui
	$UI/VillageButton.visible = world_ui and $UI/Journal.visible
	controls_label.hide()
	$UI/JournalButton.visible = (world_ui and not is_dialogue_open() and not $UI/Journal.visible)
	$UI/CarriedLabel.visible = (
		not carried.is_empty()
		and not is_dialogue_open()
		and not mission_panel.visible
		and not $UI/Journal.visible
		and not gathering.visible
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
	if not _cards_mode:
		_workbench_attempt.observe(
			task.item,
			item.word == task.item,
			item.supported and item.word == task.item,
			"recall" if recall.mode == RecallPanel.Mode.WRITE else "reconstruction"
		)
		if not task.quality.is_empty():
			_workbench_attempt.observe(
				task.quality,
				quality.word == task.quality,
				quality.supported and quality.word == task.quality,
				"recall" if recall.mode == RecallPanel.Mode.WRITE else "reconstruction"
			)
	if item.word != task.item or quality.word != task.quality:
		task_mistakes[str(active_task)] = mini(
			int(task_mistakes.get(str(active_task), 0)) + 1, 1000
		)
		_workbench_attempt.miss()
		task_support[str(active_task)] = true
		if not _cards_mode:
			recall.advance_support()
		feedback.text = "Revisa el encargo de %s. La pista te ayudará." % task.requester
		_store_draft()
		GameManager.checkpoint(self)
		return
	carried = {
		"attempt": _workbench_attempt.snapshot(),
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
	_update_carried()
	_show_notice("¡Hechizo creado! Elige al amigo para colocar o servir tu aporte.")
	GameManager.checkpoint(self)


func _deliver(index: int, spot: ExplorationSpot) -> void:
	var task: VillageTask = tasks[task_indices[index]]
	if not _mission.accepts_delivery(index, task.item, task.quality):
		carried.supported = true
		carried.mistakes += 1
		var carried_attempt: LearningAttempt = LearningAttempt.new()
		carried_attempt.restore(carried.get("attempt"))
		carried_attempt.use_content_help()
		carried.attempt = carried_attempt.snapshot()
		task_mistakes[str(index)] = maxi(
			int(task_mistakes.get(str(index), 0)), int(carried.mistakes)
		)
		task_support[str(index)] = true
		if index not in met:
			met.append(index)
		active_task = index
		_start_dialogue(task.requester, ["Ese encargo es diferente. " + task.request], false)
		GameManager.checkpoint(self)
		return
	var context: String = LearningContext.identify(
		"delivery/" + GameManager.scene_key_for(self), task.requester, task.words(), false, _seed
	)
	var delivered_attempt: LearningAttempt = LearningAttempt.new()
	delivered_attempt.restore(carried.get("attempt"))
	GameManager.record_learning(
		task.words(),
		carried.get("phase", "recall"),
		context,
		bool(carried.supported) or task_support.get(str(index), false),
		int(carried.mistakes),
		delivered_attempt.evidence(task.words())
	)
	delivered.append(index)
	carried.clear()
	_restore_deliveries(index)
	_update_carried()
	_update_counter()
	_start_dialogue(task.requester, [task.success], false)
	GameManager.checkpoint(self)


func _restore_deliveries(new_delivery: int = -1) -> void:
	for index: int in range(3):
		var result: MeaningIllustration = (
			$Delivered.get_node("Item%d" % index) as MeaningIllustration
		)
		var recipient: ExplorationSpot = $Spots.get_node("Recipient%d" % index)
		result.visible = index in delivered
		if result.visible:
			var task: VillageTask = tasks[task_indices[index]]
			var spot: ExplorationSpot = $Spots.get_node("Recipient%d" % index) as ExplorationSpot
			spot.z_index = 1
			result.position = spot.position + Vector2(-90, -125)

			result.show_meaning(task.item, task.quality)
			spot.mark_examined()
			spot.sprite.texture = GameManager.get_visual_expression(
				task.requester, "reaccion_feliz"
			)
			var motion: VillageUseMotion = VillageUseMotion.attach(
				spot.sprite, result, task.item, task.requester
			)
			if free_roam:
				spot.z_index = int(spot.position.y)
				result.z_index = int(spot.position.y) - 1
			if index == new_delivery:
				motion.receive()
	if free_roam and _roaming != null:
		_roaming.ensure_safe(navigation_obstacles())


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
	counter_label.text = "Aportes a la plaza: %d / 3" % delivered.size()
	_update_journal()
	objective_label.text = (
		completion_objective
		if delivered.size() == 3
		else {
			"home": "Nuestro rincón · elige a quién ayudar.",
			"party": "Preparemos juntos la fiesta.",
			"meal": "Una mesa compartida."
		}[mission_kind]
	)
	for index: int in range(3):
		var task: VillageTask = tasks[task_indices[index]]
		($UI/Direct.get_child(index) as Button).text = (
			("✓ " if index in delivered else "") + task.requester
		)
	$UI/Direct/Exit.disabled = delivered.size() < 3


func _track_task(index: int) -> void:
	if index not in met or index in delivered:
		return
	active_task = index
	$UI/Journal.hide()
	_show_notice(
		"Encargo de %s. Crea el objeto en el taller." % tasks[task_indices[index]].requester
	)
	GameManager.checkpoint(self)


func toggle_journal() -> void:
	$UI/Journal.visible = not $UI/Journal.visible
	$UI/Direct.visible = $UI/Journal.visible
	if $UI/Journal.visible:
		_update_journal()
		($UI/Direct.get_child(0) as Button).grab_focus()
	else:
		$UI/JournalButton.grab_focus()


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


func _on_recall_support() -> void:
	_workbench_attempt.supported = true
	if active_task >= 0:
		task_support[str(active_task)] = true


func mark_learning_help() -> void:
	_workbench_attempt.use_content_help()
	if active_task >= 0:
		task_support[str(active_task)] = true
		if not mission_panel.visible and active_task not in delivered:
			var task: VillageTask = tasks[task_indices[active_task]]
			var draft: Dictionary = drafts.get(str(active_task), {})
			var attempt: LearningAttempt = LearningAttempt.new()
			attempt.restore(draft.get("attempt"))
			attempt.begin(
				LearningContext.identify(
					"delivery/" + GameManager.scene_key_for(self),
					task.requester,
					task.words(),
					false,
					_seed
				)
			)
			attempt.use_content_help()
			draft.attempt = attempt.snapshot()
			drafts[str(active_task)] = draft
	if not carried.is_empty():
		carried.supported = true
		var attempt: LearningAttempt = LearningAttempt.new()
		attempt.restore(carried.get("attempt"))
		attempt.use_content_help()
		carried.attempt = attempt.snapshot()
	GameManager.checkpoint(self)


func _show_help() -> void:
	if mission_panel.visible:
		_workbench_attempt.guidance = true
		GameManager.checkpoint(self)
		recall.explain_support()
		guide.highlight(recall)
	elif delivered.size() == 3:
		_show_notice(completion_objective)
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
	if gathering.visible:
		gathering.close_gathering()
		return true
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
	saved.merge(_mission.snapshot())
	if not _combination_tasks.is_empty():
		saved.combination_tasks = _combination_tasks.duplicate()
	saved.merge(
		{
			"layout_seed": _seed,
			"task_indices": task_indices,
			"residents": _residents.duplicate(),
			"workbench_open": mission_panel.visible,
			"gathering_seen": gathering_seen
		}
	)
	return saved.duplicate(true)


func _restore_objective() -> void:
	_update_counter()
	objective_label.add_theme_color_override("font_color", _objective_color)


func _on_dialogue_finished() -> void:
	super._on_dialogue_finished()
	_show_gathering()


func _show_gathering() -> void:
	if gathering.visible or gathering_seen or delivered.size() != 3 or is_dialogue_open():
		return
	var completed: Array[VillageTask] = []
	guide.stop()
	for index: int in task_indices:
		completed.append(tasks[index])
	gathering.show_gathering(completed, gathering_title, $UI/BookButton)


func _on_gathering_closed() -> void:
	gathering_seen = true
	GameManager.checkpoint(self)


## Accesos equivalentes por toque, Tab y Enter; el paseo sigue siendo opcional.
func visit_task(index: int) -> void:
	$UI/Journal.hide()
	if not _can_walk() or index not in range(3):
		return
	var spot: ExplorationSpot = $Spots.get_node("Recipient%d" % index)
	_place_kalin(spot.position.x - 110)
	camera.reset_smoothing()
	open_spot(spot)


func visit_workbench() -> void:
	$UI/Journal.hide()
	if not _can_walk():
		return
	_place_kalin($Spots/Workbench.position.x)
	camera.reset_smoothing()
	_open_workbench()


func visit_exit() -> void:
	$UI/Journal.hide()
	if not _can_walk() or delivered.size() < 3:
		return
	_place_kalin($Spots/Salida.position.x - 80)
	camera.reset_smoothing()
	open_spot($Spots/Salida)


func _show_orientation() -> void:
	if not _can_walk():
		guide.stop()
		return
	super._show_orientation()


func navigation_obstacles() -> Array[Rect2]:
	var obstacles: Array[Rect2] = super.navigation_obstacles()
	for index: int in delivered:
		var spot: ExplorationSpot = $Spots.get_node("Recipient%d" % index) as ExplorationSpot
		obstacles.append(Rect2(spot.position - Vector2(180, 25), Vector2(360, 50)))
	return obstacles
