## Cobertura por reto, alternancia, evidencia y continuación del taller y comida.
extends "res://tests/validate_game_expansion.gd"


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_folder = arg.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://phrase_episodes_validation.json"))
	manager.reset_save()
	manager.session.tutorials_seen.assign(["paths", "objects", "phrases", "requests"])
	(root.get_node("AccessibilityManager") as Node).reduced_motion = true
	_plans_and_boundaries()
	_contextual_plans()
	await _break_lifecycle()
	for world: int in [3, 4]:
		await _complete_episodes(world)
		await _supported_recall(world)
		await _breaks_and_walk(world)
	await process_frame
	if failures.is_empty():
		print(
			"OK: episodios, cobertura por reto, planes válidos, aprendizaje, JSON, paseo y repetición."
		)
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _break_lifecycle() -> void:
	var pause: Node = load("res://scenes/ui/shared/mission_break.tscn").instantiate()
	root.add_child(pause)
	pause.show_block("Cambio de episodio", "")
	root.remove_child(pause)
	# El foco diferido debe descartarse si su UI salió del árbol durante una transición.
	await process_frame
	_check(not pause.is_inside_tree(), "La pausa puede retirarse antes del foco diferido")
	pause.free()


func _contextual_plans() -> void:
	var session: PhraseExerciseSession = PhraseExerciseSession.new()
	session.build_plan(4, {}, [true, false, true, false])
	_check(session.plan.size() == 6, "Sólo las palabras nuevas requieren otra presentación")
	var state: Dictionary = JSON.parse_string(
		JSON.stringify(session.snapshot("noun", "adjective", ["", ""], {}))
	)
	var restored: PhraseExerciseSession = PhraseExerciseSession.new()
	restored.build_plan(4, state, [true, true, true, true])
	_check(
		restored.plan == session.plan, "Aprender durante la actividad no elimina pasos pendientes"
	)
	session.build_plan(4, {}, [true, true, true, true])
	_check(
		session.plan.size() == 4, "No se imponen doce respuestas cuando el contenido ya se presentó"
	)
	var recalled: Array[int] = []
	for step: Dictionary in session.plan:
		_check(
			not step.guided and int(step.challenge) not in recalled,
			"Conserva una recuperación por situación"
		)
		recalled.append(int(step.challenge))
	_check(recalled.size() == 4, "No omite contenido por azar")


func _plans_and_boundaries() -> void:
	for count: int in range(11):
		for seed_value: int in range(1, 33):
			var session: PhraseExerciseSession = PhraseExerciseSession.new()
			session.seed_value = seed_value
			session.build_plan(count, {})
			var presentations: Array[int] = []
			var recalls: Array[int] = []
			var run_length: int = 0
			_check(session.plan.size() == count * 2, "No se añaden rondas obligatorias")
			for index: int in range(session.plan.size()):
				session.round_index = index
				var challenge: int = session.challenge_index()
				if session.is_guided():
					_check(
						challenge not in presentations, "Cada reto se presenta exactamente una vez"
					)
					presentations.append(challenge)
				else:
					_check(
						challenge in presentations, "Cada reto se presenta antes de pedir recuerdo"
					)
					_check(challenge not in recalls, "Cada reto se recupera exactamente una vez")
					recalls.append(challenge)
				run_length = 1 if index == 0 or session.is_phase_start() else run_length + 1
				_check(run_length <= 3, "Las modalidades alternan en grupos de hasta tres retos")
				_check(
					session.phase_position() == run_length, "El contador sigue la modalidad actual"
				)
				if (
					session.is_phase_start()
					and not session.is_guided()
					and session.phase_size() > 1
				):
					_check(
						challenge != session.plan[index - 1].challenge,
						"El recuerdo no empieza copiando el ejemplo recién mostrado"
					)
				var saved: Dictionary = JSON.parse_string(
					JSON.stringify(session.snapshot("noun", "adjective", ["borrador", ""], {}))
				)
				var restored: PhraseExerciseSession = PhraseExerciseSession.new()
				restored.restore_attempt(saved)
				restored.build_plan(count, saved)
				_check(
					restored.plan == session.plan and restored.round_index == index,
					"JSON conserva todo el plan desde cualquier ronda"
				)
			_check(presentations.size() == count and recalls.size() == count, "Cobertura completa")
			if count > 0:
				_check(
					session.plan[0] == {"challenge": 0, "guided": true}, "Primer ejemplo sencillo"
				)
			var original: Array[Dictionary] = session.plan.duplicate(true)
			session.build_plan(count, {})
			_check(session.plan == original, "La semilla reproduce el plan completo")
			if count > 2:
				session.build_plan(count, {"previous_variation": {"plan": original}})
				_check(session.plan != original, "Repetir cambia el orden y conserva el ejemplo")
	var fallback: Array[Dictionary] = []
	var session: PhraseExerciseSession = PhraseExerciseSession.new()
	session.build_plan(6, {})
	fallback.assign(session.plan)
	for invalid: Variant in [null, [], {}, "0", true, -1, 6, 0.5, NAN, INF, 1e30]:
		var damaged: Array[Dictionary] = fallback.duplicate(true)
		damaged[0].challenge = invalid
		_check(
			ExerciseProgress.restore_plan(damaged, 6, []).is_empty(), "Rechazar índices inválidos"
		)
	for invalid: Variant in [null, [], {}, "true", 1]:
		var damaged: Array[Dictionary] = fallback.duplicate(true)
		damaged[0].guided = invalid
		_check(
			ExerciseProgress.restore_plan(damaged, 6, []).is_empty(), "Validar el tipo de modalidad"
		)
	var reversed: Array[Dictionary] = fallback.duplicate(true)
	reversed.reverse()
	_check(
		ExerciseProgress.restore_plan(reversed, 6, []).is_empty(),
		"Rechazar recuerdo sin presentación"
	)
	var duplicate: Array[Dictionary] = fallback.duplicate(true)
	duplicate[1] = duplicate[0].duplicate()
	_check(
		ExerciseProgress.restore_plan(duplicate, 6, []).is_empty(), "Rechazar cobertura duplicada"
	)
	# El contrato vigente admite planes completos: nunca reordenar una partida iniciada.
	var in_progress: Array[Dictionary] = []
	for guided: bool in [true, false]:
		for index: int in range(6):
			in_progress.append({"challenge": index, "guided": guided})
	session.build_plan(6, {"plan": in_progress, "round": 7})
	_check(
		session.plan == in_progress and session.round_index == 7,
		"Conservar planes vigentes en curso"
	)


func _complete_episodes(world: int) -> void:
	manager.reset_save()
	manager.session.tutorials_seen.assign(["phrases", "requests"])
	var key: String = "world%d_level1" % world
	var scene: Node = await _scene(key, {"layout_seed": 613})
	var plan: Array[Dictionary] = scene.round_plan.duplicate(true)
	var presented: Array[int] = []
	for index: int in range(plan.size()):
		_check(scene.round_index == index, "Continuar avanza una sola ronda")
		if scene.mission_break.visible:
			await process_frame
			_check(
				scene.mission_break.continue_button.has_focus(),
				"La pausa del episodio conserva foco"
			)
			scene.mission_break.continue_button.pressed.emit()
			if scene.recall.visible:
				_check(scene.recall.first.has_focus(), "Seguir hacia recuerdo enfoca la escritura")
		var challenge: ExerciseEntry = scene._current_challenge()
		var words: Array[String] = []
		words.assign([challenge.noun, challenge.adjective] if world == 3 else [challenge.food])
		if world == 4 and not challenge.modifier.is_empty():
			words.append(challenge.modifier)
		if plan[index].guided:
			presented.append(int(plan[index].challenge))
		else:
			_check(
				int(plan[index].challenge) in presented, "La escena ya enseñó el reto recuperado"
			)
			for word: String in words:
				_check(
					manager.has_learned_word(word),
					"La palabra está descubierta antes de recuperarla"
				)
			_check(
				scene.recall.visible and not scene._attempt.supported,
				"Cada episodio de recuerdo empieza por escritura sin apoyo"
			)
			_check(not (scene.result_art.visible), "El recuerdo no revela dibujos de solución")
		if scene.recall.visible:
			scene.recall.first.text = words[0]
			scene.recall.second.text = words[1] if words.size() > 1 else ""
		elif world == 3:
			scene._select_noun(challenge.noun)
			scene._select_adjective(challenge.adjective)
		else:
			scene._select_food(challenge.food)
			scene._select_modifier(challenge.modifier)
		var submit: Button = scene.cast_button if world == 3 else scene.serve_button
		var before: Dictionary = {}
		for word: String in words:
			before[word] = manager.learning_record(word)
		submit.pressed.emit()
		_check(scene._awaiting_continue, "La respuesta resuelve la ronda")
		for word: String in words:
			var record: Dictionary = manager.learning_record(word)
			_check(
				record.writing == before[word].writing + (0 if plan[index].guided else 1),
				"Sólo la escritura de recuerdo acredita evidencia independiente"
			)
			_check(
				record.recognition == before[word].recognition + (1 if plan[index].guided else 0),
				"Las tarjetas conservan su evidencia de reconocimiento"
			)
		var evidence: Dictionary = manager.session.snapshot()
		scene = await _resume(key)
		_check(
			scene.round_plan == plan and scene._awaiting_continue,
			"Reanudar conserva plan y resultado"
		)
		for field: String in [
			"learning_progress",
			"learning_clock",
			"magic_points",
			"words_learned",
			"completed_levels"
		]:
			_check(
				manager.session.snapshot()[field] == evidence[field],
				"Reabrir no duplica evidencia ni recompensa"
			)
		(scene.cast_button if world == 3 else scene.serve_button).pressed.emit()
	_check(
		scene.round_index == plan.size() and scene.completion.visible,
		"Completar todos los episodios"
	)
	var evidence: Dictionary = manager.session.learning_progress.duplicate(true)
	manager.replay_scene(key)
	await scene_changed
	await process_frame
	scene = current_scene
	_check(
		scene.round_index == 0 and scene.round_plan != plan,
		"Repetir crea otro plan desde el inicio"
	)
	_check(manager.session.learning_progress == evidence, "Repetir conserva el aprendizaje previo")


func _supported_recall(world: int) -> void:
	var key: String = "world%d_level1" % world
	for offset: int in [0, 3]:
		var scene: Node = await _scene(key, PhraseExerciseFixture.recall_state(819, 6, offset))
		scene.mission_break.continue_button.pressed.emit()
		scene.recall.first.text = "borrador"
		if scene.recall.second_box.visible:
			scene.recall.second.text = scene.recall.expected[1]
		(scene.cast_button if world == 3 else scene.serve_button).pressed.emit()
		_check(scene.recall.mode == RecallPanel.Mode.CLOZE, "El primer error activa completar")
		scene.recall.first.text = "parcial"
		scene._show_help()
		var saved: Dictionary = scene.get_checkpoint_state()
		scene = await _resume(key)
		_check(
			(
				scene.recall.first.text == "parcial"
				and scene.recall.mode == RecallPanel.Mode.CLOZE
				and scene._attempt.snapshot() == saved.attempt
				and scene.round_plan == saved.plan
				and scene.round_index == saved.round
			),
			"Cada episodio conserva borrador, apoyo, errores, orientación y evidencia por palabra"
		)
		scene.recall.first.text = "incorrecto"
		(scene.cast_button if world == 3 else scene.serve_button).pressed.emit()
		_check(
			scene.recall.mode == RecallPanel.Mode.BLOCKS,
			"Reanudar conserva la progresión a bloques"
		)
		scene = await _resume(key)
		_check(
			scene.recall.mode == RecallPanel.Mode.BLOCKS, "Los bloques también sobreviven a JSON"
		)


func _breaks_and_walk(world: int) -> void:
	var key: String = "world%d_level1" % world
	for compact: bool in [false, true]:
		root.size = Vector2i(640, 360) if compact else Vector2i(1280, 720)
		for index: int in [3, 6, 9]:
			var scene: Node = await _scene(key, PhraseExerciseFixture.episode_state(713, index))
			scene.get_node("ScreenLayout").preview_compact = compact
			scene.get_node("ScreenLayout").refresh()
			await process_frame
			_check(
				scene.mission_break.visible, "Cada cambio de modalidad anuncia el siguiente grupo"
			)
			_check(
				(
					scene.mission_break.continue_button.text
					== ("Practicar →" if index == 6 else "Recordar →")
				),
				"La pausa anuncia la modalidad correcta"
			)
			_check(scene.mission_break.continue_button.has_focus(), "El foco permanece en la pausa")
			for node: Control in [
				scene.mission_break.get_node("Title"), scene.mission_break.continue_button
			]:
				_check(
					Rect2(0, 0, 1280, 720).encloses(node.get_global_rect()),
					"El episodio cabe en ambos perfiles"
				)
			await _capture(
				"episodio_%d_%d_%s" % [world, index, "compacto" if compact else "escritorio"]
			)
			if index == 6:
				_check(
					scene.mission_break.get_node("WalkButton").visible,
					"El paseo sigue siendo opcional"
				)
				var saved: Dictionary = scene.get_checkpoint_state()
				scene.mission_break.get_node("WalkButton").pressed.emit()
				await scene_changed
				await process_frame
				_check(
					current_scene.next_scene_key == key, "El paseo conserva su destino de retorno"
				)
				manager.go_to_scene(key)
				await scene_changed
				await process_frame
				_check(
					(
						current_scene.round_plan == saved.plan
						and current_scene.round_index == index
						and not current_scene.mission_break.visible
					),
					"Volver del paseo conserva el plan sin añadir rondas ni repetir la pausa"
				)
				scene = current_scene
			if scene.mission_break.visible:
				scene.mission_break.continue_button.pressed.emit()
			await process_frame
			await _capture(
				"modalidad_%d_%d_%s" % [world, index, "compacto" if compact else "escritorio"]
			)
	root.size = Vector2i(1280, 720)
