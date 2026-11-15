## Dirección narrativa, transformaciones y lectura en escritorio y compacto.
extends "res://tests/validate_game_expansion.gd"


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_folder = argument.trim_prefix("--capture=")
			DirAccess.make_dir_recursive_absolute(capture_folder)
	manager = root.get_node("GameManager")
	manager.use_save_repository(SaveRepository.new("user://narrative_animation.json"))
	manager.reset_save()
	var preferences: Node = root.get_node("AccessibilityManager")
	var previous_preferences: Dictionary[String, bool] = {}
	for key: String in preferences.PREFERENCE_KEYS:
		previous_preferences[key] = preferences.get(key)
	preferences.manual_cinematics = true
	preferences.instant_text = true
	await _gesture_lifecycle()
	await _emotional_sequence()
	await _portal_crossing()
	await _page_lifecycle()
	await _table_transformation()
	await _reading_layouts()
	await _all_dialogues_fit()
	await _scene("main_menu")
	for key: String in previous_preferences:
		preferences.set_preference(key, previous_preferences[key])
	if failures.is_empty():
		print("OK: gestos, página protagonista, mesa compartida y lectura en ambos perfiles.")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _gesture_lifecycle() -> void:
	var story: Node = await _scene("world1_cine1")
	_check(story.kalin.visible, "La llegada muestra a Kalin protegiendo el libro")
	_check(story._animator.has_gesture(), "La pose del libro tiene su propia actuación")
	var gesture: Texture2D = story.kalin.texture
	story._on_vignette_mood("feliz")
	_check(story.kalin.texture == gesture, "La viñeta no sustituye un gesto narrativo")
	var saved_beat: int = story.beat_index
	story = await _resume("world1_cine1")
	_check(
		story.beat_index == saved_beat and story.kalin.texture == gesture,
		"Reanudar conserva el gesto y el momento sin adelantar la historia"
	)
	var preferences: Node = root.get_node("AccessibilityManager")
	preferences.set_preference("reduced_motion", true)
	story._animator.play_kalin_motion(StoryBeat.KalinMotion.FAREWELL)
	var home: Vector2 = story.kalin.position
	await create_timer(0.2).timeout
	_check(story.kalin.position == home, "El gesto reducido conserva la pose sin oscilación")
	story._next_beat()
	story._next_beat()
	story._next_beat()
	story._next_beat()
	_check(not story._animator.has_gesture(), "Un momento normal retira el gesto anterior")
	_check(
		story.kalin.texture == story.surprised_texture, "La pose normal recupera su arte de autor"
	)
	preferences.set_preference("reduced_motion", false)


func _page_lifecycle() -> void:
	var story: Node = await _scene("world1_story2", {"beat": 2})
	story._complete_text()
	var page: TextureRect = story.get_node("Effects/StoryPage")
	_check(page.visible, "Recuperar palabras presenta una página concreta")
	var word: Label = page.get_node("Word")
	_check(
		word.text == story.current_beat().page_word,
		"La página pertenece a lo vivido en el capítulo"
	)
	await process_frame
	root.get_tree().paused = true
	var paused_position: Vector2 = page.position
	await create_timer(0.12, true).timeout
	_check(page.position == paused_position, "La página se pausa con la escena")
	root.get_tree().paused = false
	root.get_node("AccessibilityManager").set_preference("reduced_motion", true)
	_check(word.visible_ratio == 1.0, "El movimiento reducido conserva la palabra legible")
	_check(is_equal_approx(page.modulate.a, 1.0), "Cambiar comodidad no deja una página invisible")
	story._next_beat()
	_check(not page.visible, "El siguiente momento retira la página y su transición")
	root.get_node("AccessibilityManager").set_preference("reduced_motion", false)


func _emotional_sequence() -> void:
	var story: Node = await _scene("world5_story1", {"beat": 1})
	var animator: StoryAnimator = story._animator
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_farewell_hesitate.svg"),
		"Despedirse comienza con el libro entre los brazos, antes de levantar la mano"
	)
	animator._kalin_motion_tween.custom_step(0.5)
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_farewell_hesitate.svg"),
		"La vacilación conserva un tiempo de lectura antes del saludo"
	)
	animator._kalin_motion_tween.custom_step(0.7)
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_farewell_hesitate.svg"),
		"La frase sobre lo difícil de despedirse conserva la expresión contenida hasta el final"
	)
	story = await _scene("world5_story1", {"beat": 4})
	animator = story._animator
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_farewell_hesitate.svg"),
		"El agradecimiento comienza mirando a los amigos antes del saludo"
	)
	animator._kalin_motion_tween.custom_step(1.2)
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_farewell.svg"),
		"Al agradecer, la mano se levanta una sola vez después de la vacilación"
	)
	var custom: Texture2D = story.surprised_texture
	animator.set_gesture_texture(custom)
	animator.play_kalin_motion(StoryBeat.KalinMotion.FAREWELL)
	animator._kalin_motion_tween.custom_step(1.3)
	_check(story.kalin.texture == custom, "Las fases respetan el recorte del Inspector")
	story = await _scene("world1_cine1", {"beat": 1})
	animator = story._animator
	animator._kalin_motion_tween.custom_step(0.4)
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_reach_page.svg"),
		"Kalin intenta retener la hoja que el viento arranca"
	)
	animator._kalin_motion_tween.custom_step(1.0)
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_protect_book.svg"),
		"Al perder la hoja vuelve a proteger el libro que conserva"
	)


func _portal_crossing() -> void:
	var story: Node = await _scene("world5_cine1", {"beat": 1})
	var animator: StoryAnimator = story._animator
	_check(
		story.current_beat().auto_advance >= StoryAnimator.CROSS_SECONDS,
		"El avance automático espera el cruce completo incluso con texto instantáneo"
	)
	animator.play_kalin_motion(StoryBeat.KalinMotion.CRUZA)
	animator._kalin_motion_tween.custom_step(1.2)
	_check(
		story.kalin.texture.resource_path.ends_with("kalin_portal_look_back.svg"),
		"Kalin se detiene a mirar atrás antes de cruzar"
	)
	_check(
		story.kalin.modulate.a == 1.0 and story.kalin.scale.x > animator.kalin_base_scale.x * 0.7,
		"El recorrido conserva una figura legible antes de tocar el plano del portal"
	)
	root.get_tree().paused = true
	var paused_position: Vector2 = story.kalin.position
	await create_timer(0.12, true).timeout
	_check(story.kalin.position == paused_position, "La pausa detiene también el cruce del portal")
	root.get_tree().paused = false
	var preferences: Node = root.get_node("AccessibilityManager")
	preferences.set_preference("reduced_motion", true)
	_check(
		story.kalin.modulate.a == 0.0,
		"Reducir movimiento durante el cruce conserva su desenlace sin devolver a Kalin al origen"
	)
	story._next_beat()
	_check(
		story.kalin.modulate.a == 1.0 and story.kalin.scale == animator.kalin_base_scale,
		"El siguiente momento restaura opacidad y escala después del cruce"
	)
	preferences.set_preference("reduced_motion", false)


func _table_transformation() -> void:
	var story: Node = await _scene("world2_story1", {"beat": 5})
	var vignette: Node = story.vignette
	vignette.set_process(false)
	if vignette._reveal_tween:
		vignette._reveal_tween.kill()
	vignette.set_reveal_progress(0.0)
	var small: Vector2 = vignette.prop.size
	vignette.set_reveal_progress(1.0)
	var large: Vector2 = vignette.prop.size
	_check(
		large.x > small.x and large.y > small.y,
		"La palabra transforma realmente el tamaño de la mesa"
	)
	for index: int in range(2):
		var plate: TextureRect = vignette.get_node("PlaceSetting%d" % index)
		_check(plate.visible, "Los dos platos muestran para qué hace falta la mesa grande")
		_check(
			(
				plate.position.x >= vignette.prop.position.x
				and plate.position.x + plate.size.x <= vignette.prop.position.x + large.x
			),
			"Los platos caben en la mesa después de transformarse"
		)
	await _capture("mesa_para_compartir")
	vignette.show_situation("hambre")
	_check(
		not vignette.get_node("PlaceSetting0").visible,
		"Cambiar de situación retira los platos y cancela la transformación previa"
	)


func _reading_layouts() -> void:
	manager.session.scene_states["world5_farewell"] = {
		"gifts": [0, 1, 2],
		"memory":
		{
			"kind": "home",
			"title": "Nuestro rincón",
			"animal": "Miis",
			"item": "mayak",
			"quality": ""
		}
	}
	var samples: Array[Dictionary] = [
		{"key": "world1_cine1", "beat": 0, "name": "proteger_libro"},
		{"key": "world1_cine1", "beat": 1, "name": "pagina_en_el_viento"},
		{"key": "world2_story1", "beat": 1, "name": "extranar_casa"},
		{"key": "world5_story1", "beat": 1, "name": "despedirse"},
		{"key": "world5_cine1", "beat": 1, "name": "mirar_atras"},
		{"key": "world5_cine1", "beat": 4, "name": "regresar_a_casa"}
	]
	for window_size: Vector2i in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = window_size
		for sample: Dictionary in samples:
			var story: Node = await _scene(sample.key, {"beat": sample.beat})
			story.get_node("ScreenLayout").preview_compact = window_size.x < 1024
			story.get_node("ScreenLayout").refresh()
			story._complete_text()
			if sample.name == "mirar_atras":
				story._animator._kalin_motion_tween.pause()
				story._animator._kalin_motion_tween.custom_step(1.2)
			await process_frame
			_check(
				story.dialogue_text.get_content_height() <= story.dialogue_text.size.y + 1,
				"El diálogo completo cabe sin recortarse: %s a %d" % [sample.name, window_size.x]
			)
			_check(
				(
					story.continue_button.get_global_rect().intersects(
						story.dialogue_text.get_global_rect()
					)
					== false
				),
				"Continuar no cubre el texto narrativo: " + str(sample.name)
			)
			await _capture("%s_%d" % [sample.name, window_size.x])
	root.size = Vector2i(1280, 720)


func _all_dialogues_fit() -> void:
	for compact: bool in [false, true]:
		for key: String in GameContent.SCENE_PATHS:
			if "_story" not in key and "_cine" not in key:
				continue
			var story: Node = await _scene(key)
			story.get_node("ScreenLayout").preview_compact = compact
			story.get_node("ScreenLayout").refresh()
			for index: int in range(story.beats.size()):
				story._complete_text()
				await process_frame
				_check(
					story.dialogue_text.get_content_height() <= story.dialogue_text.size.y + 1,
					(
						"El texto de %s, momento %d, cabe en perfil %s"
						% [key, index, "compacto" if compact else "escritorio"]
					)
				)
				if index + 1 < story.beats.size():
					story._next_beat()
