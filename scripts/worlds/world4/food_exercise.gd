@tool
## Mundo 4, nivel 1 — In k'a'at (Yo Quiero)
## Desafío de comprensión en dos fases. Primero ofrece apoyos en español y
## después presenta solamente pistas visuales para recuperar la frase maya.
extends Node2D

@onready var choices_panel: Panel = $UI/ChoicesPanel
@onready var spell_panel: Panel = $UI/SpellPanel

@export var illustration_scene: PackedScene
@export var content: ExerciseSet
@export var vary_combinations: bool = true
var _session_challenges: Array[ExerciseEntry] = []
var _combination_plan: Array[String] = []
var _combination_animals: Array[String] = []
var foods: Array[ExerciseEntry]:
	get:
		return content.foods
var modifiers: Array[ExerciseEntry]:
	get:
		return content.modifiers
var challenges: Array[ExerciseEntry]:
	get:
		return content.challenges if _session_challenges.is_empty() else _session_challenges

const PHRASE_BUILDER = preload("res://scripts/features/exercises/phrase_builder_controller.gd")

## Peticiones del GDD. Las frases completas evitan construir morfología desde
## el código y facilitan una posterior revisión lingüística.

const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")

var _exercise: PhraseExerciseSession = PhraseExerciseSession.new()
var round_plan: Array[Dictionary]:
	get:
		return _exercise.plan
	set(value):
		_exercise.plan = value
var round_index: int:
	get:
		return _exercise.round_index
	set(value):
		_exercise.round_index = value
var selected_food: String:
	get:
		return _exercise.selected[0]
	set(value):
		_exercise.selected[0] = value
var selected_modifier: String:
	get:
		return _exercise.selected[1]
	set(value):
		_exercise.selected[1] = value
var food_buttons: Dictionary = {}
var modifier_buttons: Dictionary = {}
var _compact_layout: bool = false
var _resolving: bool:
	get:
		return _exercise.resolving
	set(value):
		_exercise.resolving = value
var _awaiting_continue: bool:
	get:
		return _exercise.awaiting_continue
	set(value):
		_exercise.awaiting_continue = value
var _mistakes: int:
	get:
		return _exercise.attempt.mistakes
	set(value):
		_exercise.attempt.mistakes = value
var guide: LearningGuide
var _serving: Control
@onready var result_art: MeaningIllustration = $UI/FeedbackPanel/ResultArt
@onready var mission_progress: MissionProgress = $UI/MissionProgress
@onready var mission_break: MissionBreak = $UI/MissionBreak
var _help_stage: int = 0
var _blocks_seen: Array[int]:
	get:
		return _exercise.blocks_seen
	set(value):
		_exercise.blocks_seen = value
var _attempt: LearningAttempt:
	get:
		return _exercise.attempt
	set(value):
		_exercise.attempt = value
var _layout_seed: int:
	get:
		return _exercise.seed_value
	set(value):
		_exercise.seed_value = value
var _saved_scaffold: Dictionary:
	get:
		return _exercise.saved_scaffold
	set(value):
		_exercise.saved_scaffold = value
var _practice_fallback: bool:
	get:
		return _exercise.cards
	set(value):
		_exercise.cards = value
@onready var recall: RecallPanel = $UI/ChoicesPanel/RecallPanel

@onready var header: Panel = $UI/LevelHeader
@onready var animal_sprite: TextureRect = $UI/RequestPanel/Content/AnimalSprite
@onready var phase_label: Label = $UI/RequestPanel/Content/PhaseLabel
@onready var animal_label: Label = $UI/RequestPanel/Content/AnimalLabel
@onready var request_label: Label = $UI/RequestPanel/Content/RequestLabel
@onready var food_grid: GridContainer = $UI/ChoicesPanel/Content/FoodGrid
@onready var modifier_grid: GridContainer = $UI/ChoicesPanel/Content/ModifierGrid
@onready var food_slot: Label = $UI/SpellPanel/Content/Sentence/FoodSlot
@onready var modifier_slot: Label = $UI/SpellPanel/Content/Sentence/ModifierSlot
@onready var serve_button: Button = $UI/ServeButton
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var _feedback_left: float = feedback_label.offset_left
@onready var _feedback_color: Color = feedback_label.get_theme_color("font_color")
@onready var progress_label: Label = $UI/StatusPanel/Status/ProgressLabel
@onready var instruction_label: Label = $UI/StatusPanel/Status/InstructionLabel
@onready var completion: Control = $UI/CompletionOverlay
@onready var libro: CanvasLayer = $LibroHechizos


func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues: PackedStringArray = get_configuration_issues()
	if not issues.is_empty():
		push_error("Configuración incompleta: " + "; ".join(issues))
		return
	_setup_drop_slots()
	header.menu_pressed.connect(_on_menu_pressed)
	header.book_pressed.connect(_on_book_pressed)
	completion.next_pressed.connect(_on_next_level_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	_build_choice_buttons()
	recall.submitted.connect(_on_serve_pressed)
	recall.practice_requested.connect(_practice_with_cards)
	recall.support_used.connect(_on_recall_support)
	ExerciseRecallFlow.bind_support(recall, _attempt)
	recall.answer_changed.connect(_on_scaffold_changed)
	recall.first.text_changed.connect(_on_recall_changed)
	recall.second.text_changed.connect(_on_recall_changed)
	_configure_keyboard_navigation()
	guide = LearningGuide.install(self, $UI/LevelHeader/Bar, _show_help)
	mission_break.continued.connect(
		func():
			if recall.visible:
				recall.first.grab_focus()
				guide.watch_action(recall)
			else:
				_refresh_step()
				guide.watch_action(food_slot)
	)
	var state: Dictionary = GameManager.get_scene_state(self)
	_exercise.restore_attempt(state)
	if vary_combinations:
		var session: Dictionary = CombinationVariation.exercises(content, state, _layout_seed, 4)
		if not session.is_empty():
			_session_challenges.assign(session.entries)
			_combination_plan.assign(session.ids)
			_combination_animals.assign(session.animals)
			for entry: ExerciseEntry in _session_challenges:
				entry.sprite = GameManager.get_visual_texture(entry.animal)
	_build_round_plan(state)
	food_grid.set_meta("layout_seed", _layout_seed)
	_show_round()
	if recall.visible and state.has("food"):
		recall.first.text = str(state.get("food", ""))
		recall.second.text = str(state.get("modifier", ""))
	if not _resolving:
		var food: String = str(state.get("food", ""))
		var modifier: String = str(state.get("modifier", ""))
		if food in food_buttons:
			_select_food(food)
		if state.has("modifier") and modifier in modifier_buttons:
			_select_modifier(modifier)
		if (
			bool(state.get("waiting", false))
			and food == _current_challenge().food
			and modifier == _current_challenge().modifier
		):
			_render_success(false)


func _build_round_plan(state: Dictionary = {}) -> void:
	var presented: Array[bool] = []
	for challenge: ExerciseEntry in challenges:
		presented.append(
			(
				GameManager.has_learned_word(challenge.food)
				and (
					challenge.modifier.is_empty()
					or GameManager.has_learned_word(challenge.modifier)
				)
			)
		)
	_exercise.build_plan(challenges.size(), state, presented)


func _build_choice_buttons() -> void:
	food_buttons = PHRASE_BUILDER.collect_buttons(food_grid, _select_food)
	modifier_buttons = PHRASE_BUILDER.collect_buttons(modifier_grid, _select_modifier)


func _configure_keyboard_navigation() -> void:
	PHRASE_BUILDER.configure_navigation(food_grid, modifier_grid, serve_button)


func _setup_drop_slots() -> void:
	food_slot.connect("word_dropped", _select_food)
	modifier_slot.connect("word_dropped", _select_modifier)


func _current_challenge() -> ExerciseEntry:
	return challenges[_exercise.challenge_index()]


func _is_guided_phase() -> bool:
	return _exercise.is_guided()


func _show_round() -> void:
	guide.stop()
	mission_break.hide()
	result_art.hide()
	feedback_label.offset_left = _feedback_left
	if is_instance_valid(_serving):
		_serving.queue_free()
	if round_index >= round_plan.size():
		_finish_level()
		return
	var continuing: bool = _exercise.begin_round(
		"food",
		_current_challenge().animal,
		[_current_challenge().food, _current_challenge().modifier]
	)
	recall.hide()
	ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, false)
	$UI/ChoicesPanel/Content.show()
	_help_stage = 0
	selected_food = ""
	selected_modifier = ""
	PHRASE_BUILDER.clear_mark(food_slot)
	PHRASE_BUILDER.clear_mark(modifier_slot)
	var challenge: ExerciseEntry = _current_challenge()
	var guided: bool = _is_guided_phase()
	if guided:
		GameManager.learn_word(challenge.food)
		if not challenge.modifier.is_empty():
			GameManager.learn_word(challenge.modifier)
	phase_label.text = (
		"Práctica con tarjetas" if _practice_fallback else ("Práctica" if guided else "Recuerdo")
	)
	animal_label.text = challenge.animal
	animal_sprite.texture = challenge.sprite
	request_label.text = "Me gustaría:\n" + challenge.translation
	request_label.show()
	instruction_label.text = ""
	feedback_label.text = "Elige el alimento."
	feedback_label.add_theme_color_override("font_color", _feedback_color)
	food_slot.text = "alimento"
	_update_modifier_slot()
	PHRASE_BUILDER.show_even_choices(modifier_buttons, challenge.modifier, round_index)
	if not modifier_buttons[""].visible:
		for word: String in modifier_buttons:
			if word != challenge.modifier and modifier_buttons[word].visible:
				modifier_buttons[word].hide()
				break
		modifier_buttons[""].show()
	_update_choice_labels(guided)
	PHRASE_BUILDER.show_even_choices(food_buttons, challenge.food, round_index)
	PHRASE_BUILDER.shuffle_grid(modifier_grid, hash("%d:%d" % [_layout_seed, round_index]))
	_configure_keyboard_navigation()
	_update_button_states()
	_set_choices_enabled(true)
	serve_button.text = "Servir ✦"
	_refresh_step()
	if not guided and not _practice_fallback:
		$UI/ChoicesPanel/Content.hide()
		ExerciseRecallFlow.prepare(
			recall,
			["Alimento"] if challenge.modifier.is_empty() else ["Alimento", "Cualidad"],
			(
				[challenge.food]
				if challenge.modifier.is_empty()
				else [challenge.food, challenge.modifier]
			),
			_attempt,
			_saved_scaffold if continuing else {}
		)
		_saved_scaffold = {}
		ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, true)
		serve_button.disabled = false
		feedback_label.text = "Recuerda las palabras de la petición."
	mission_progress.update_progress(
		round_index,
		round_plan.size(),
		(
			"La comida · %d / %d · %s"
			% [
				round_index + 1,
				round_plan.size(),
				ExerciseRecallFlow.caption(recall, guided, _practice_fallback)
			]
		)
	)
	progress_label.text = (
		"Episodio %d · %s %d / %d"
		% [
			_exercise.episode_number(),
			"Aprende" if guided else "Repasa",
			_exercise.phase_position(),
			_exercise.phase_size()
		]
	)
	PHRASE_BUILDER.focus_first_visible(food_grid)
	if round_index == 0 and "requests" not in GameManager.session.tutorials_seen:
		call_deferred("_show_help")
	else:
		guide.watch_action(food_slot)
	if _exercise.is_phase_start() and round_index not in _blocks_seen:
		_blocks_seen.append(round_index)
		guide.stop()
		var recent: ExerciseEntry = challenges[int(round_plan[round_index - 1].challenge)]
		mission_break.show_episode(
			_exercise.episode_number(),
			_is_guided_phase(),
			"hambre",
			recent.food,
			recent.modifier,
			recent.animal
		)
		if _is_guided_phase():
			mission_break.offer_walk("world3_explore1", "world4_level1")
	GameManager.checkpoint(self)


func _refresh_step() -> void:
	if round_index >= round_plan.size():
		return
	var needs_size: bool = (
		not _current_challenge().modifier.is_empty() or not selected_modifier.is_empty()
	)
	var next_step: Control = serve_button
	if needs_size:
		for choice: Control in modifier_grid.get_children():
			if choice.visible:
				next_step = choice
				break
	ExercisePresentation.focus_step(
		food_grid, modifier_grid, not selected_food.is_empty(), needs_size
	)
	$UI/ChoicesPanel/Content/ModifierHeading.visible = needs_size
	$UI/ChoicesPanel/Content/FoodHeading.text = (
		"1 · Alimento" + ("  · elegido" if not selected_food.is_empty() else "")
	)
	$UI/ChoicesPanel/Content/ModifierHeading.text = (
		"2 · Cualidad" + ("  · elegida" if not selected_modifier.is_empty() else "")
	)
	for button: Button in food_buttons.values():
		if not button.has_meta("food_base_size"):
			button.set_meta("food_base_size", button.custom_minimum_size)
			button.set_meta("food_base_icon_width", button.get_theme_constant("icon_max_width"))
		button.custom_minimum_size = (
			Vector2(button.get_meta("food_base_size"))
			* Vector2(1, 1 if needs_size else 130.0 / 94.0)
		)
		button.add_theme_constant_override(
			"icon_max_width",
			roundi(
				(
					(40.0 if _compact_layout else float(button.get_meta("food_base_icon_width")))
					* (1.0 if needs_size else 76.0 / 56.0)
				)
			)
		)
		button.focus_neighbor_bottom = button.get_path_to(next_step)


func apply_screen_layout(compact: bool) -> void:
	_compact_layout = compact
	for button: Button in modifier_buttons.values():
		button.add_theme_constant_override("icon_max_width", 40 if compact else 56)
	for heading: Label in [
		$UI/ChoicesPanel/Content/FoodHeading, $UI/ChoicesPanel/Content/ModifierHeading
	]:
		heading.add_theme_font_size_override("font_size", 22 if compact else 15)
	_refresh_step()


func _update_choice_labels(guided: bool) -> void:
	var bridge: bool = not guided and _exercise.episode_number() == 1
	for food: ExerciseEntry in foods:
		var button: Button = food_buttons[food.maya]
		button.text = "%s\n%s" % [food.maya, food.spanish] if bridge else food.maya
		button.icon = GameManager.get_visual_texture(food.maya) if guided else null
	for modifier: ExerciseEntry in modifiers:
		var button: Button = modifier_buttons[modifier.maya]
		button.text = (
			"Sin cualidad ↻"
			if modifier.maya == ""
			else ("%s\n%s" % [modifier.maya, modifier.spanish] if bridge else modifier.maya)
		)
		button.icon = (
			GameManager.get_visual_texture(modifier.maya)
			if guided and modifier.maya != ""
			else null
		)


func _update_modifier_slot() -> void:
	modifier_slot.text = selected_modifier
	modifier_slot.visible = (
		not selected_modifier.is_empty() or not _current_challenge().modifier.is_empty()
	)


func _select_food(value: String) -> void:
	if _resolving:
		return
	guide.stop()
	selected_food = value
	if recall.visible:
		recall.first.text = value
		return
	_refresh_step()
	food_slot.text = value
	_update_button_states()
	_celebrate_selection(food_slot)


func _select_modifier(value: String) -> void:
	if _resolving:
		return
	guide.stop()
	selected_modifier = value
	if recall.visible:
		recall.second.text = value
		return
	_refresh_step()
	_update_modifier_slot()
	_update_button_states()
	_celebrate_selection(modifier_slot)


func _celebrate_selection(slot: Control) -> void:
	result_art.hide()
	feedback_label.offset_left = _feedback_left
	PHRASE_BUILDER.clear_mark(slot)
	var message: String = (
		"Elige el alimento."
		if selected_food.is_empty()
		else (
			"Elige el tamaño."
			if not _current_challenge().modifier.is_empty() and selected_modifier.is_empty()
			else "¡Sirve la petición!"
		)
	)
	PHRASE_BUILDER.celebrate(slot, feedback_label, message, _feedback_color)
	GameManager.checkpoint(self)
	if round_index == 0 and "requests" not in GameManager.session.tutorials_seen:
		_show_help()
	else:
		var target: Control = (
			food_slot
			if selected_food.is_empty()
			else (
				modifier_slot
				if not _current_challenge().modifier.is_empty() and selected_modifier.is_empty()
				else serve_button
			)
		)
		guide.watch_action(target)


func _update_button_states() -> void:
	PHRASE_BUILDER.set_button_states(
		food_buttons, selected_food, modifier_buttons, selected_modifier
	)
	serve_button.disabled = (
		selected_food == ""
		or (not _current_challenge().modifier.is_empty() and selected_modifier.is_empty())
		or _resolving
	)


func _set_choices_enabled(enabled: bool) -> void:
	PHRASE_BUILDER.set_enabled(food_buttons, modifier_buttons, enabled)
	serve_button.disabled = (
		not enabled
		or selected_food == ""
		or (not _current_challenge().modifier.is_empty() and selected_modifier.is_empty())
	)


func _on_serve_pressed() -> void:
	if _exercise.advance():
		_show_round()
		return
	if _resolving:
		return
	var challenge: ExerciseEntry = _current_challenge()
	if recall.visible and not recall.ready_to_submit():
		return
	var answers: Array = recall.values() if recall.visible else [selected_food, selected_modifier]
	if not _exercise.submit(
		answers,
		[challenge.food, challenge.modifier],
		recall.visible,
		ExerciseRecallFlow.phase(recall, _is_guided_phase())
	):
		_show_incorrect_feedback(challenge)
		return
	AudioManager.play_sfx("acierto")
	AudioManager.play_sfx("comida_servir")
	GameManager.learn_word(challenge.food)
	if challenge.modifier != "":
		GameManager.learn_word(challenge.modifier)
	var practiced: Array[String] = [challenge.food]
	if not challenge.modifier.is_empty():
		practiced.append(challenge.modifier)
	GameManager.record_learning(
		practiced,
		ExerciseRecallFlow.phase(recall, _is_guided_phase()),
		_attempt.context,
		_attempt.supported,
		_attempt.mistakes,
		_attempt.evidence(practiced)
	)
	GameManager.mark_tutorial_seen("requests")
	_render_success(true)


func _show_incorrect_feedback(challenge: ExerciseEntry) -> void:
	AudioManager.play_sfx("error_suave")
	_exercise.miss()
	guide.stop()
	result_art.hide()
	feedback_label.offset_left = _feedback_left
	CharacterReaction.play(animal_sprite, false)
	var food_ok: bool = selected_food == str(challenge.food)
	var modifier_ok: bool = selected_modifier == str(challenge.modifier)
	PHRASE_BUILDER.mark_slot(food_slot, food_ok)
	PHRASE_BUILDER.mark_slot(modifier_slot, modifier_ok)
	if not food_ok:
		feedback_label.text = "Revisa la petición. Cambia el alimento."
	elif challenge.modifier == "":
		feedback_label.text = "Alimento: ✓. No pidió cualidad: elige Sin cualidad."
	else:
		feedback_label.text = "Alimento: ✓. Revisa la cualidad que pidió."
	feedback_label.add_theme_color_override("font_color", COLOR_ERROR)
	if recall.visible:
		recall.advance_support()
	elif _mistakes >= 2:
		_help_stage = mini(_mistakes - 2, 2)
		_show_help()
	GameManager.checkpoint(self)


func _finish_level() -> void:
	_exercise.finish()
	guide.stop()
	GameManager.complete_level(4, 1)
	completion.show_completion(
		"¡Todos han comido!", "Entendiste las peticiones de tus amigos.", "Al tianguis →"
	)
	GameManager.checkpoint(self)


func _on_menu_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("main_menu")


func _on_next_level_pressed() -> void:
	_resolving = true
	GameManager.go_to_scene("world4_story2")


func _on_book_pressed() -> void:
	libro.show_book($UI/LevelHeader/Bar/BookButton)


func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))


func _render_success(animate: bool) -> void:
	_exercise.resolve()
	var result: ExerciseEntry = _current_challenge()
	ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, true)
	$UI/ChoicesPanel/Content.hide()
	recall.show_result(result.food, result.modifier, result.phrase, result.translation)
	mission_progress.update_progress(
		round_index + 1,
		round_plan.size(),
		"La comida · %d / %d · ¡Entregado!" % [round_index + 1, round_plan.size()]
	)
	guide.stop()
	_set_choices_enabled(false)
	var challenge: ExerciseEntry = _current_challenge()
	food_slot.text = challenge.food
	_update_modifier_slot()
	PHRASE_BUILDER.mark_slot(food_slot, true)
	if challenge.modifier != "":
		PHRASE_BUILDER.mark_slot(modifier_slot, true)
	feedback_label.text = "✓ %s\n%s" % [challenge.phrase, challenge.translation]
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	serve_button.text = "Continuar →"
	serve_button.disabled = false
	serve_button.grab_focus()
	guide.watch_continue(serve_button)
	result_art.hide()
	feedback_label.offset_left = _feedback_left
	if animate:
		CharacterReaction.play(animal_sprite)
		_deliver_food(challenge)
		guide.page_to_book(
			recall.global_position, $UI/LevelHeader/Bar/BookButton.get_global_rect().get_center()
		)
	GameManager.checkpoint(self)


func _deliver_food(challenge: ExerciseEntry) -> void:
	var serving: MeaningIllustration = illustration_scene.instantiate() as MeaningIllustration
	serving.size = Vector2(140, 110)
	serving.position = food_slot.get_global_rect().get_center() - serving.size * 0.5
	$UI.add_child(serving)
	_serving = serving
	serving.show_meaning(challenge.food, challenge.modifier)
	var tween: Tween = serving.create_tween()
	(
		tween
		. tween_property(
			serving,
			"position",
			animal_sprite.get_global_rect().get_center() + Vector2(20, 15),
			0.75
		)
		. set_trans(Tween.TRANS_SINE)
	)
	tween.tween_property(serving, "scale", serving.scale * 0.25, 0.35)
	tween.parallel().tween_property(serving, "modulate:a", 0.0, 0.35)
	tween.tween_callback(serving.queue_free)


func _show_help() -> void:
	if mission_break.visible:
		guide.point_at(mission_break.continue_button)
		return
	if _awaiting_continue:
		guide.point_at(serve_button)
		return
	if _resolving:
		return
	if recall.visible:
		_attempt.guidance = true
		GameManager.checkpoint(self)
		recall.explain_support()
		guide.highlight(recall)
		return
	mark_learning_help()
	var challenge: ExerciseEntry = _current_challenge()
	var needs_food: bool = selected_food != challenge.food
	if not selected_food.is_empty() and selected_modifier == challenge.modifier and _mistakes == 0:
		guide.point_at(serve_button)
		return
	var grid: Control = food_grid if needs_food else modifier_grid
	var slot: Control = food_slot if needs_food else modifier_slot
	if (
		round_index == 0 and "requests" not in GameManager.session.tutorials_seen
		or _help_stage >= 2
	):
		var button: Control = (
			food_buttons[challenge.food] if needs_food else modifier_buttons[challenge.modifier]
		)
		guide.drag_between(button, slot)
	elif _help_stage == 0:
		guide.highlight(slot)
	else:
		guide.highlight(grid)
	_help_stage += 1
	feedback_label.text = "Elige el alimento." if needs_food else "Elige el tamaño."


func get_checkpoint_state() -> Dictionary:
	var answers: Array = (
		recall.values()
		if recall.visible and not recall.is_showing_result()
		else [selected_food, selected_modifier]
	)
	var state: Dictionary = _exercise.snapshot("food", "modifier", answers, recall.scaffold_state())
	if not _combination_plan.is_empty():
		state.merge(
			{
				"combination_plan": _combination_plan.duplicate(),
				"combination_animals": _combination_animals.duplicate()
			}
		)
	return state.duplicate(true)


func _on_recall_support() -> void:
	_attempt.supported = true
	GameManager.checkpoint(self)


func mark_learning_help() -> void:
	if not _resolving:
		_attempt.use_content_help()
		GameManager.checkpoint(self)


func _practice_with_cards() -> void:
	mark_learning_help()
	_practice_fallback = true
	ExerciseRecallFlow.expand_for_recall(choices_panel, spell_panel, recall, false)
	recall.hide()
	$UI/ChoicesPanel/Content.show()
	_update_choice_labels(false)
	_refresh_step()
	phase_label.text = "Práctica con tarjetas"
	mission_progress.update_progress(
		round_index,
		round_plan.size(),
		"La comida · %d / %d · Práctica con tarjetas" % [round_index + 1, round_plan.size()]
	)
	feedback_label.text = "Practiquemos con las tarjetas."
	PHRASE_BUILDER.focus_first_visible(food_grid)
	GameManager.checkpoint(self)


func _on_recall_changed(_text: String) -> void:
	if recall.visible and not _resolving:
		serve_button.disabled = false


func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del ejercicio."])
	return content.get_configuration_issues(4)


func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()


func _on_scaffold_changed() -> void:
	if recall.visible and not recall.is_preparing():
		phase_label.text = ExerciseRecallFlow.caption(recall, false, false)
		mission_progress.update_progress(
			round_index,
			round_plan.size(),
			"La comida · %d / %d · %s" % [round_index + 1, round_plan.size(), phase_label.text]
		)
		GameManager.schedule_checkpoint(self)
