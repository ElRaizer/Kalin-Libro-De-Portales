extends ProjectTest

const SAVE_PATH: String = "user://validation_postgame_delivery.json"
const PHOTO_TITLE: String = "Encuentro junto al estanque"
const WORD_DRAFT: String = "mi respuesta"
var manager: Node
var comfort: Node
var audio_manager: Node
var repository: SaveRepository
var home: Node
var captures: String = ""
var recording: AudioEffectRecord


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	manager = root.get_node("GameManager")
	comfort = root.get_node("AccessibilityManager")
	audio_manager = root.get_node("AudioManager")
	repository = SaveRepository.new(SAVE_PATH)
	comfort.reduced_motion = true
	comfort.reduced_flashes = true
	comfort.instant_text = true
	comfort.manual_cinematics = true
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--resume" in arguments:
		await _resume()
		return
	for argument: String in arguments:
		if argument.begins_with("--capture="):
			captures = argument.trim_prefix("--capture=")
	check(repository.delete_progress() == OK, "Perfil de prueba vacío")
	check(
		repository.save_progress(PostgameFixture.at_ending().snapshot()) == OK,
		"Escenario antes del cierre"
	)
	manager.use_save_repository(repository)
	await _from_ending()
	await _complete_projects()
	await _check_free_creation()
	await _leave_practice_in_progress()
	_cold_start()
	check(repository.delete_progress() == OK, "Retira el archivo de prueba")
	finish("PG9: recorrido integrado y reanudación en otro proceso")


func _enter(key: String) -> void:
	change_scene_to_file(GameContent.SCENE_PATHS[key])
	await scene_changed
	await process_frame
	await process_frame


func _from_ending() -> void:
	await _enter("main_menu")
	check(
		not manager.session.has_finished_adventure(), "Completar niveles aún no habilita el regreso"
	)
	check(
		current_scene.next_stop.text == "Continuar: Regreso a casa",
		"El menú señala el cierre antes de anunciar la aventura completa"
	)
	current_scene.play_btn.pressed.emit()
	await scene_changed
	await process_frame
	var finale: Node = current_scene
	check(manager.scene_key_for(finale) == "world5_cine1", "Continuar abre el cierre de campaña")
	_start_recording()
	if recording != null:
		await create_timer(1.0).timeout
	for _beat: int in range(finale.beats.size()):
		finale.continue_button.pressed.emit()
		await process_frame
	await process_frame
	check(manager.scene_key_for(current_scene) == "main_menu", "El cierre vuelve al menú")
	check(manager.session.has_finished_adventure(), "La cinemática confirma el regreso real")
	var visit: Button = current_scene.get_node("UI/VisitButton")
	check(root.gui_get_focus_owner() == visit, "El regreso tiene prioridad en el teclado")
	check(
		current_scene.play_btn.text == "Repetir la aventura",
		"Repetir y volver tienen entradas claras"
	)
	await _capture("01_regreso")
	if recording != null:
		await create_timer(0.8).timeout
	visit.pressed.emit()
	await scene_changed
	await process_frame
	home = current_scene
	check(not paused and not home._rest_panel.visible, "El paseo sigue siendo voluntario")
	check(
		(
			audio_manager.current_music == audio_manager.catalog.music_for("village_home")
			and audio_manager.current_ambience == audio_manager.catalog.ambience_for("village_home")
		),
		"La transición usa música y ambiente de la aldea"
	)
	if recording != null:
		await create_timer(4.0).timeout
	_save_recording()


func _complete_projects() -> void:
	var baseline: Dictionary = manager.session.snapshot()
	home._rest_button.pressed.emit()
	var rest: Node = home._rest_panel
	await _capture("02_invitacion", rest)
	rest._skip_intro.pressed.emit()
	check(
		rest._choices.visible and not manager.session.rest_corner.complete,
		"El atajo muestra opciones sin confirmar"
	)
	check(root.gui_get_focus_owner() in rest._option_buttons, "El atajo enfoca la primera opción")
	for index: int in range(rest._option_buttons.size()):
		rest._option_buttons[index].pressed.emit()
		check(rest.preview.motion != null, "Representa mesa, silla y hamaca")
	await _capture("03_hamaca", rest)
	rest._primary.pressed.emit()
	check(
		manager.session.rest_corner.choice == "k'áan" and manager.session.rest_corner.complete,
		"Confirma la elección al pulsar"
	)
	_press(KEY_ESCAPE)
	await process_frame
	check(
		not paused and root.gui_get_focus_owner() == home._rest_button, "Esc devuelve pausa y foco"
	)

	await home.change_district("shore")
	home._snack_button.pressed.emit()
	var snack: Node = home._snack_panel
	snack._guests["Kay"].button_pressed = true
	snack._guests["Ch'íich'"].button_pressed = true
	snack._decoration.select(1)
	snack.start_preparation()
	_finish_amounts(snack.workbench)
	snack._confirm.pressed.emit()
	check(manager.session.snack_project.complete, "La merienda completa ambas cantidades con apoyo")
	await _book(snack._book, snack)
	await _capture("04_merienda", snack)
	snack._photo.pressed.emit()
	var album: Node = home._album
	album._title.text = PHOTO_TITLE
	album._save_button.pressed.emit()
	check(manager.session.personal_moments().size() == 1, "La reunión queda en el álbum")
	album.close_panel()

	home._expansion_button.pressed.emit()
	var expansion: Node = home._expansion_panel
	expansion._trials.rest.pressed.emit()
	expansion._trials.snack.pressed.emit()
	expansion._guests["Ma'ax"].button_pressed = true
	expansion._guests["Miis"].button_pressed = true
	expansion._confirm.pressed.emit()
	check(manager.session.village_expansion.complete, "El claro abre después de probar los usos")
	check(expansion.gathering.actors.size() == 2, "Representa dos participantes en el claro")
	await _capture("05_claro", expansion)
	expansion._replay.pressed.emit()
	expansion.close_panel()
	check(
		(
			manager.session.magic_points == 0
			and manager.session.economy == baseline.economy
			and manager.session.garden == baseline.garden
			and manager.session.learning_progress == baseline.learning_progress
		),
		"Probar y confirmar proyectos no gasta, fabrica ni vuelve a acreditar"
	)


func _check_free_creation() -> void:
	await home.change_district("workshop")
	var lab: Node = home.get_node("SpellLaboratory")
	var map: Button = home._map_button
	lab.open_lab(map)
	lab.try_favorite("mayak|nojoch")
	lab.toggle_favorite()
	lab.request_placement()
	check(
		lab._purchase.visible and lab._confirm.disabled,
		"El ensayo sigue abierto con saldo insuficiente"
	)
	check(
		lab._availability.text.contains("Grande") and manager.session.magic_points == 0,
		"Muestra el diseño que falta sin cobrar"
	)
	await _capture("06_saldo_cero")
	_press(KEY_ESCAPE)
	await process_frame
	check(
		lab.visible and paused and not lab._purchase.visible,
		"El primer Esc cierra sólo la confirmación"
	)
	_press(KEY_ESCAPE)
	await process_frame
	check(
		not paused and root.gui_get_focus_owner() == map,
		"El segundo Esc vuelve a la aldea con foco"
	)
	await home.change_district("patio")
	var table: int = int(manager.session.garden.objects[0].id)
	check(home.invite_guest("Ch'íich'", table), "La mesa girada admite una visita terrestre")
	check(home._visit.ground_point().is_finite(), "El invitado tiene apoyo junto a la mesa")
	check(int(manager.session.garden.objects[1].support) == table, "El plato conserva su apoyo")
	home.dismiss_visit()


func _leave_practice_in_progress() -> void:
	var before: Dictionary = manager.session.learning_progress.duplicate(true)
	var practice: Node = home._practice
	practice.open_hub(home._action)
	practice.hub.choose("numbers")
	var numbers: Node = practice.numbers
	_finish_amounts(numbers.workbench)
	numbers.finish_practice()
	practice.open_hub(home._action)
	practice.hub.choose("mixed")
	var paths: Node = practice.paths
	var route: Array[Vector2i] = _route_for(paths)
	paths.show_hint()
	for index: int in range(1, route.size()):
		paths.press_cell(route[index])
	paths.finish_practice()
	check(home.room.visible, "Mixto continúa de cantidades a caminos y palabras")
	home.room.recall.first.text = WORD_DRAFT
	_press(KEY_ESCAPE)
	await process_frame
	practice.open_hub(home._action)
	practice.hub.choose("numbers")
	numbers.repeat_practice()
	numbers.workbench.use_help()
	numbers.workbench.edit("dot")
	numbers.close_panel()
	practice.open_hub(home._action)
	practice.hub.choose("paths")
	paths.restart()
	paths.show_hint()
	paths.press_cell(route[1])
	await _capture("07_camino_en_curso", paths)
	# El cierre de ventana captura el borrador aunque el panel siga abierto.
	manager.checkpoint_current_scene()
	paths.close_panel()
	check(manager.session.resume_scene_key == "village_home", "La partida apunta a la aldea")
	check(
		manager.session.learning_progress == before,
		"Los apoyos de cantidad y ruta no son evidencia lingüística"
	)


func _finish_amounts(workbench: Node) -> void:
	for _round: int in range(2):
		if workbench.activity.finished():
			break
		workbench.use_help()
		workbench.use_help()
		workbench.submit()
		workbench.submit()


func _route_for(paths: Node) -> Array[Vector2i]:
	return GridReplayLayouts.cells(PathPracticeState.layout(paths.activity.variant).solution[0])


func _book(button: Button, panel: Node) -> void:
	button.grab_focus()
	button.pressed.emit()
	await process_frame
	check(
		home.get_node("LibroHechizos").visible and panel.visible and paused, "El libro se superpone"
	)
	_press(KEY_ESCAPE)
	await create_timer(0.55).timeout
	check(
		panel.visible and paused and not home.get_node("LibroHechizos").visible,
		"Esc conserva la actividad debajo"
	)
	check(root.gui_get_focus_owner() == button, "Cerrar el libro devuelve el foco")


func _press(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)


func _cold_start() -> void:
	var output: Array = []
	var arguments: PackedStringArray = [
		"--headless",
		"--path",
		ProjectSettings.globalize_path("res://"),
		"--script",
		"res://tests/validate_postgame_delivery.gd",
		"--",
		"--resume"
	]
	var status: int = OS.execute(OS.get_executable_path(), arguments, output, true)
	var transcript: String = "\n".join(output)
	var errors: RegEx = RegEx.create_from_string("(?m)^(?:(?:SCRIPT )?ERROR|WARNING):")
	check(
		status == 0 and errors.search(transcript) == null, "Arranque independiente: " + transcript
	)
	print(transcript.strip_edges())


func _resume() -> void:
	var expected: GameSession = GameSession.new()
	check(expected.restore(repository.load_progress()), "El archivo del proceso anterior es válido")
	manager.use_save_repository(repository)
	await _enter("main_menu")
	check(not manager.load_failed, "Carga el archivo del proceso anterior")
	current_scene.play_btn.pressed.emit()
	await scene_changed
	await process_frame
	home = current_scene
	check(manager.scene_key_for(home) == "village_home", "Continuar regresa a la aldea")
	check(not paused, "Reanuda el paseo sin abrir una actividad")
	var practice: Node = home._practice
	check(home.room.recall.first.text == WORD_DRAFT, "Reanuda el borrador de palabras")
	check(practice.numbers.workbench.activity.supports[0] > 0, "Reanuda la tablilla y su pista")
	check(practice.paths.activity.supported, "Reanuda el apoyo del camino")
	check(practice.paths.activity.controller.paths[0].size() == 1, "Reanuda un camino parcial")
	check(practice.snapshot().mode == "paths", "Se conserva la última familia")
	check(
		(
			manager.session.village_expansion.complete
			and manager.session.snack_project.complete
			and manager.session.rest_corner.complete
		),
		"Reanuda los tres proyectos confirmados"
	)
	check(manager.session.laboratory_favorites == ["mayak|nojoch"], "Recupera la idea no comprada")
	home._album_button.pressed.emit()
	check(
		home._album._moments.get_item_text(0) == PHOTO_TITLE,
		"La galería recupera la foto desde el menú"
	)
	home._album.close_panel()
	check(
		(
			VillageMemory.from_checkpoint(manager.saved_scene_state("world5_farewell"))
			== PostgameFixture.NARRATIVE
		),
		"La despedida conserva su recuerdo"
	)
	check(
		(
			manager.session.magic_points == expected.magic_points
			and manager.session.learning_progress == expected.learning_progress
		),
		"Cargar no vuelve a acreditar"
	)
	home.return_button.pressed.emit()
	await scene_changed
	await process_frame
	check(
		current_scene.get_node("UI/VisitButton").visible,
		"Se puede salir y volver sin perder el acceso"
	)
	finish("PG9: nuevo proceso recupera actividades, ayudas, foto y regreso libre")


func _capture(label: String, panel: Node = null) -> void:
	var layout: ScreenLayout = current_scene.get_node_or_null("ScreenLayout")
	for compact: bool in [false, true]:
		if is_instance_valid(layout):
			layout.preview_compact = compact
			layout.refresh()
		if not captures.is_empty():
			root.size = Vector2i(960, 540) if compact else Vector2i(1280, 720)
		await process_frame
		await process_frame
		if panel != null and panel is VillagePanel:
			var outer: Control = panel.controls.get_child(0)
			check(
				outer.get_global_rect().encloses(panel.footer.get_global_rect()),
				"Acciones visibles: " + label
			)
		if not captures.is_empty():
			await RenderingServer.frame_post_draw
			var suffix: String = "_compacto" if compact else ""
			check(
				(
					root.get_texture().get_image().save_png(
						captures.path_join(label + suffix + ".png")
					)
					== OK
				),
				"Captura " + label
			)
	if is_instance_valid(layout):
		layout.preview_compact = false
		layout.refresh()
	if not captures.is_empty():
		root.size = Vector2i(1280, 720)


func _start_recording() -> void:
	if captures.is_empty() or AudioServer.get_driver_name() == "Dummy":
		return
	recording = AudioEffectRecord.new()
	recording.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recording)
	recording.set_recording_active(true)


func _save_recording() -> void:
	if recording == null:
		if not captures.is_empty():
			print("Audio: el controlador Dummy no produce mezcla audible.")
		return
	recording.set_recording_active(false)
	var sample: AudioStreamWAV = recording.get_recording()
	check(
		sample != null and sample.get_length() > 1.0,
		"La transición produjo una grabación de mezcla real"
	)
	if sample != null and sample.get_length() > 1.0:
		check(
			sample.save_to_wav(captures.path_join("mezcla_regreso.wav")) == OK,
			"Guarda la mezcla para revisión"
		)
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	recording = null
