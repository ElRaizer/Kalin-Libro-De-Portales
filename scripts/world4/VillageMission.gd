extends "res://scripts/components/ExplorationScene.gd"
class_name VillageMission

## Encargos en el mundo: escuchar la necesidad, crear, caminar y entregar.
## El taller acepta objetos equivocados; la consecuencia se comprueba con el
## destinatario. No basta con acertar una tarjeta para cerrar un encargo.
@export var tasks: Array[VillageTask] = []
@export var free_practice := false
var task_indices: Array[int] = []
var met: Array[int] = []
var delivered: Array[int] = []
var active_task := -1
var carried: Dictionary = {}
var task_support: Dictionary = {}
var _seed := 1
var _cards_mode := false
var _draft_item := ""
var _draft_quality := ""
var drafts: Dictionary = {}
var _restoring_draft := false
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
	met = ExerciseProgress.restore_markers(saved.get("mission_met"), 3)
	delivered = ExerciseProgress.restore_markers(saved.get("delivered"), 3)
	active_task = clampi(int(saved.get("active_task", -1)), -1, 2)
	if saved.get("drafts") is Dictionary:
		for index: int in range(3):
			var draft: Variant = saved.drafts.get(str(index))
			if draft is Dictionary:
				drafts[str(index)] = {"item": str(draft.get("item", "")).left(100), "quality": str(draft.get("quality", "")).left(100), "cards": draft.get("cards", false) == true}
	if saved.get("task_support") is Dictionary:
		for index: int in range(3):
			task_support[str(index)] = saved.task_support.get(str(index), false) == true
	if saved.get("carried") is Dictionary:
		var candidate: Dictionary = saved.carried
		if _valid_item(str(candidate.get("item", ""))) and _valid_quality(str(candidate.get("quality", ""))):
			carried = {"item": str(candidate.item), "quality": str(candidate.get("quality", "")), "supported": candidate.get("supported", true) == true, "mistakes": clampi(int(candidate.get("mistakes", 0)), 0, 1000)}
	for index: int in range(3):
		var task := tasks[task_indices[index]]
		var spot := $Spots.get_node("Recipient%d" % index) as ExplorationSpot
		spot.speaker = task.requester
		spot.lines.assign([task.request])
		spot.spot_texture = GameManager.get_visual_texture(task.requester)
	super._ready()
	skip_button.visible = free_practice
	if free_practice:
		skip_button.text = "Volver al mapa"
	$UI/BookButton.pressed.connect(func(): $LibroHechizos.show_book($UI/BookButton))
	$UI/MissionPanel/Close.pressed.connect(_close_workbench)
	forge_button.pressed.connect(_forge)
	recall.submitted.connect(_forge)
	recall.practice_requested.connect(_show_cards)
	recall.first.text_changed.connect(_draft_changed)
	recall.second.text_changed.connect(_draft_changed)
	for button: Button in noun_choices.get_children():
		button.pressed.connect(func():
			_draft_item = str(button.get_meta("word"))
			_update_recipe()
			GameManager.checkpoint(self)
		)
	for button: Button in quality_choices.get_children():
		button.pressed.connect(func():
			_draft_quality = str(button.get_meta("word"))
			_update_recipe()
			GameManager.checkpoint(self)
		)
	mission_panel.hide()
	_restore_deliveries()
	_update_carried()
	_update_counter()
	if saved.get("workbench_open", false) == true and not is_dialogue_open() and active_task >= 0 and active_task not in delivered:
		# La ayuda diferida de ExplorationScene debe terminar antes de reabrirlo;
		# de otro modo interpretaría la restauración como una petición de tarjetas.
		call_deferred("_open_workbench")

func _restore_tasks(saved: Dictionary) -> void:
	var loaded: Variant = saved.get("task_indices")
	if loaded is Array and loaded.size() == 3:
		var requesters: Array[String] = []
		for value: Variant in loaded:
			if not (value is float or value is int) or value != int(value) or int(value) < 0 or int(value) >= tasks.size():
				break
			var task := tasks[int(value)]
			if task.requester in requesters:
				break
			requesters.append(task.requester)
			task_indices.append(int(value))
		if task_indices.size() == 3:
			return
	task_indices.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for group: int in range(3):
		var first_index := group * 2
		var first_score := _recall_score(tasks[first_index])
		var second_score := _recall_score(tasks[first_index + 1])
		task_indices.append(first_index + (1 if second_score < first_score else (rng.randi_range(0, 1) if first_score == second_score else 0)))
	# Los personajes no conservan siempre el mismo lugar.
	for index: int in range(2, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := task_indices[index]
		task_indices[index] = task_indices[other]
		task_indices[other] = swap
	if task_indices == ReplayVariation.previous(saved, "task_indices", []) and task_indices.size() > 1:
		task_indices.append(task_indices.pop_front())

func _recall_score(task: VillageTask) -> int:
	var score := 0
	for word: String in task.words():
		score += LearningProgress.sanitize(GameManager.learning_progress.get(word)).recalls.size()
	return score

func _can_walk() -> bool:
	return not mission_panel.visible and super._can_walk()

func open_spot(spot: ExplorationSpot) -> void:
	if not _can_walk() or not _is_within_reach(spot):
		return
	if spot.name == &"Workbench":
		_open_workbench()
		return
	if spot.is_goal and delivered.size() < 3:
		_start_dialogue("Kalin", ["Todavía hay amigos esperando su encargo."], false)
		return
	var index := _recipient_index(spot)
	if index >= 0 and not carried.is_empty() and index not in delivered:
		_deliver(index, spot)
		return
	if index >= 0:
		active_task = index
		spot.lines.assign([tasks[task_indices[index]].success if index in delivered else tasks[task_indices[index]].request])
	super.open_spot(spot)

func _recipient_index(spot: ExplorationSpot) -> int:
	return str(spot.name).trim_prefix("Recipient").to_int() if str(spot.name).begins_with("Recipient") else -1

func _close_spot(spot: ExplorationSpot) -> void:
	var index := _recipient_index(spot)
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
	_has_target = false
	mission_panel.show()
	$UI/MissionPanel/Cards.hide()
	$UI/MissionPanel/Recipe.hide()
	_cards_mode = false
	_restoring_draft = true
	recall.configure(["Objeto o alimento", "Cualidad · opcional"])
	recall.second.placeholder_text = "Déjalo vacío si no hace falta"
	var draft: Dictionary = drafts.get(str(active_task), {})
	recall.first.text = str(draft.get("item", ""))
	recall.second.text = str(draft.get("quality", ""))
	_restoring_draft = false
	feedback.text = "Recuerda el encargo. Crea algo y llévaselo a quien lo pidió."
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
		GameManager.checkpoint(self)

func _store_draft() -> void:
	if active_task >= 0 and mission_panel.visible and not _restoring_draft:
		var values := [_draft_item, _draft_quality] if _cards_mode else recall.values()
		drafts[str(active_task)] = {"item": values[0], "quality": values[1], "cards": _cards_mode}

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
	var task := tasks[task_indices[active_task]]
	var items: Array[String] = [task.item]
	for word: String in ["mayak", "lak", "k'áanche'", "k'áan", "ja'", "janal", "ich"]:
		if word not in items and items.size() < 4:
			items.append(word)
	var qualities: Array[String] = [task.quality]
	for word: String in ["", "mejen", "nojoch", "chich", "Jats'uts", "ki'"]:
		if word not in qualities and qualities.size() < 4:
			qualities.append(word)
	for index: int in range(4):
		var noun := noun_choices.get_child(index) as Button
		noun.text = items[index]
		noun.set_meta("word", items[index])
		var quality := quality_choices.get_child(index) as Button
		quality.text = qualities[index] if not qualities[index].is_empty() else "Sin cualidad"
		quality.set_meta("word", qualities[index])
	PhraseBuilderController.shuffle_grid(noun_choices, _seed + active_task)
	PhraseBuilderController.shuffle_grid(quality_choices, _seed + active_task + 17)
	feedback.text = "Puedes consultar el libro y probar tus palabras en el mundo."
	_update_recipe()
	GameManager.checkpoint(self)

func _update_recipe() -> void:
	$UI/MissionPanel/Recipe.text = "%s%s" % [_draft_item if not _draft_item.is_empty() else "Elige un objeto", " · " + _draft_quality if not _draft_quality.is_empty() else ""]

func _valid_item(word: String) -> bool:
	return word in GameManager.VOCABULARY and int(GameManager.VOCABULARY[word].world) in [2, 4]

func _valid_quality(word: String) -> bool:
	return word.is_empty() or word in GameManager.VOCABULARY and int(GameManager.VOCABULARY[word].world) == 3

func _canonical_input(typed: String, quality: bool) -> Dictionary:
	if quality and typed.is_empty():
		return {"word": "", "supported": false}
	for word: String in GameManager.VOCABULARY:
		if not (_valid_quality(word) if quality else _valid_item(word)):
			continue
		var result := RecallPanel.match_word(typed, word)
		if result.correct:
			return result
	return {"word": typed, "supported": true}

func _forge() -> void:
	if not mission_panel.visible or active_task < 0:
		return
	var answers := [_draft_item, _draft_quality] if _cards_mode else recall.values()
	var item := _canonical_input(answers[0], false)
	var quality := _canonical_input(answers[1], true)
	if not _valid_item(item.word) or not _valid_quality(quality.word):
		mark_learning_help()
		feedback.text = "Revisa tus palabras. El libro te ayudará a escribirlas."
		return
	carried = {"item": item.word, "quality": quality.word, "supported": _cards_mode or item.supported or quality.supported or task_support.get(str(active_task), false), "mistakes": 0}
	drafts.erase(str(active_task))
	mission_panel.hide()
	magic.restart()
	_update_carried()
	_show_notice("¡Hechizo creado! Camina hasta el amigo que lo necesita.")
	GameManager.checkpoint(self)

func _deliver(index: int, spot: ExplorationSpot) -> void:
	var task := tasks[task_indices[index]]
	if index not in met or carried.item != task.item or carried.quality != task.quality:
		carried.supported = true
		carried.mistakes += 1
		task_support[str(index)] = true
		if index not in met:
			met.append(index)
		active_task = index
		_start_dialogue(task.requester, ["Ese encargo es diferente. " + task.request], false)
		GameManager.checkpoint(self)
		return
	GameManager.record_learning(task.words(), "recall", "village:" + task.requester + ":" + task.item + ":" + task.quality + "@%d" % _seed, bool(carried.supported) or task_support.get(str(index), false), int(carried.mistakes))
	delivered.append(index)
	carried.clear()
	_restore_deliveries()
	_update_carried()
	_update_counter()
	_start_dialogue(task.requester, [task.success], false)
	GameManager.checkpoint(self)

func _restore_deliveries() -> void:
	for index: int in range(3):
		var result := $Delivered.get_node("Item%d" % index) as MeaningIllustration
		result.visible = index in delivered
		if result.visible:
			var task := tasks[task_indices[index]]
			var spot := $Spots.get_node("Recipient%d" % index) as ExplorationSpot
			result.position = spot.position + Vector2(-180, -100)
			result.show_meaning(task.item, task.quality)
			spot.mark_examined()
			spot.sprite.texture = GameManager.get_visual_expression(task.requester, "reaccion_feliz")

func _update_carried() -> void:
	carried_art.visible = not carried.is_empty()
	$UI/CarriedLabel.text = "Llevas: %s%s" % [carried.item, " · " + str(carried.quality) if not str(carried.quality).is_empty() else ""] if not carried.is_empty() else "Taller ↔ Amigos · E para interactuar"
	if not carried.is_empty():
		carried_art.show_meaning(carried.item, carried.quality)

func _update_counter() -> void:
	if not is_instance_valid(counter_label):
		return
	counter_label.text = "Encargos entregados: %d / 3" % delivered.size()
	objective_label.text = ("¡Listo! Puedes visitar a tus amigos o volver al mapa." if free_practice else "¡Listo! Sigue hasta la salida →") if delivered.size() == 3 else "Habla con tus amigos, crea y entrega sus encargos."

func mark_learning_help() -> void:
	if active_task >= 0:
		task_support[str(active_task)] = true
	if not carried.is_empty():
		carried.supported = true
	GameManager.checkpoint(self)

func _show_help() -> void:
	if mission_panel.visible:
		_show_cards()
	else:
		_show_notice("Habla con un amigo. Vuelve al taller y lleva su encargo.")

func _update_arrow() -> void:
	if delivered.size() < 3:
		arrow.hide()
	else:
		super._update_arrow()

func _unhandled_input(event: InputEvent) -> void:
	if mission_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_workbench()
			get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func close_transient_ui() -> bool:
	if not mission_panel.visible:
		return false
	_close_workbench()
	return true

func get_checkpoint_state() -> Dictionary:
	_store_draft()
	var saved := super.get_checkpoint_state()
	saved.merge({"layout_seed": _seed, "task_indices": task_indices, "mission_met": met, "delivered": delivered, "active_task": active_task, "carried": carried.duplicate(true), "task_support": task_support.duplicate(true), "drafts": drafts.duplicate(true), "workbench_open": mission_panel.visible})
	return saved
