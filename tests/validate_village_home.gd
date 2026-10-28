extends ProjectTest

var manager: Node
var capture_directory: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_directory = argument.trim_prefix("--capture=")
	manager = root.get_node("GameManager")
	var roaming_script: Script = (
		load("res://scripts/features/exploration/exploration_roaming.gd") as Script
	)
	var exploration_script: Script = (
		load("res://scripts/features/exploration/exploration_scene.gd") as Script
	)
	if not roaming_script.can_instantiate() or not exploration_script.can_instantiate():
		check(false, "La locomoción debe compilar")
		finish("Carga de locomoción")
		return
	var room_script: Script = load("res://scripts/features/village/challenge_room.gd") as Script
	if room_script == null or not room_script.can_instantiate():
		check(false, "La sala debe compilar antes de montar la aldea")
		finish("Carga de la aldea")
		return
	manager.use_save_repository(repository_for("village_home"))
	manager.reset_save()
	for word: String in ["Áak", "Miis", "mayak", "chich"]:
		manager.record_learning([word], "practice", "presentation/" + word, true)
	for level: Dictionary in GameContent.LEVEL_ORDER:
		if int(level.world) < 3:
			manager.complete_level(level.world, level.level)
	change_scene_to_file(GameContent.SCENE_PATHS.village_home)
	await scene_changed
	await process_frame
	var home: Node = current_scene
	check(home != null, "Aldea accesible durante la historia")
	await _check_wayfinding(home)
	_check_context_text(home)
	await _capture("01_patio")
	home.show_project()
	check(
		MagicEconomy.FIRST_PROJECT in manager.session.economy.preparations,
		"Preparación antes de comprar"
	)
	home._project.hide()
	var book: Node = home.get_node("LibroHechizos")
	book.show_book(home.return_button)
	book.show_project()
	book.get_node("BG/Book/Project/Table").pressed.emit()
	book.get_node("BG/Book/Project/Strong").pressed.emit()
	check(manager.session.economy.designs.size() == 2, "Dos compras desde el libro")
	book.hide_book()
	await create_timer(0.5).timeout
	home.show_project()
	check(not manager.purchase_design("lak"), "Presupuesto inicial protegido")
	await _capture("02_proyecto")
	home._project.hide()
	# El editor confirma desde la misma API usada por ratón y teclado.
	home.editor.open_editor("patio")
	home.editor.new_copy("mayak|chich")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = true
	var initial_preview: Vector2 = home.editor.preview
	root.push_input(key)
	await process_frame
	check(
		home.editor.preview.x == initial_preview.x + 12,
		"Las flechas colocan con foco en las fichas"
	)
	home.editor.preview = Vector2(600, 440)
	check(not home.editor._shelf.visible, "Colocar oculta el catálogo para despejar el jardín")
	home.editor.commit()
	check(manager.session.economy.built, "Construir confirma el primer proyecto")
	check(manager.session.garden.objects.size() == 1, "Una copia persistente")
	await _capture("03_mesa_en_parcela")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(manager.session.snapshot()))
	check(manager.session.restore(snapshot), "Ciclo completo vuelve del guardado")
	check(
		manager.session.garden.objects.size() == 1 and manager.session.economy.built,
		"No pierde muebles ni repite preparación"
	)
	home.editor.hide()
	_check_hops(home.walker)
	home.change_district("workshop")
	await create_timer(0.6).timeout
	await _capture("04_taller")
	var lab: Node = home.get_node("SpellLaboratory")
	lab.open_lab(home.editor)
	check(not lab.result.visible, "El sello no revela el objeto")
	await _capture("05_sello")
	await _capture_compact("05_sello_compacto")
	lab.create_spell()
	await create_timer(0.65).timeout
	check(lab.result.visible, "Crear revela la transformación")
	await _capture("06_magia")
	await _capture_compact("06_magia_compacto")
	lab.close_lab()
	for word: String in VocabularyCatalog.learnable_keys():
		manager.learn_word(word)
	home.room.restore({"visit": 0.5})
	check(home.room.visit == 0, "La sala rechaza contadores de visitas fraccionarios")
	home.room.open_room(home.editor)
	check(
		not home.room.words.is_empty() and home.room.words.size() <= 3,
		"Tanda corta sólo de conocidos"
	)
	await _capture("07_reto_sin_respuesta")
	var word: String = home.room.words[home.room.index]
	home.room.recall.advance_support()
	var supported: Dictionary = home.room.snapshot()
	home.room.close_room()
	home.room.restore(JSON.parse_string(JSON.stringify(supported)))
	home.room.open_room(home.editor)
	check(home.room.recall.mode == RecallPanel.Mode.CLOZE, "Retomar conserva la pista")
	home.room.recall.first.text = word
	home.room.submit()
	var points: int = manager.session.magic_points
	var state: Dictionary = home.room.snapshot()
	home.room.close_room()
	home.room.restore(JSON.parse_string(JSON.stringify(state)))
	check(manager.session.magic_points == points, "Restaurar el resultado no vuelve a pagar")
	check(
		not (
			VillageGround
			. route(Vector2(100, 560), Vector2(1100, 560), manager.session.garden, "patio")
			. is_empty()
		),
		"Sendero transitable con muebles"
	)
	await _garden_views(home)
	finish("Aldea, primer proyecto, magia y sala de retos")


func _garden_views(home: Node) -> void:
	home.room.close_room()
	home.change_district("patio")
	await create_timer(0.5).timeout
	manager.record_learning(["lak", "k'áanche'"], "recall", "later_garden")
	check(manager.purchase_design("lak"), "Compra un plato sin volver a pagar Fuerte")
	check(manager.purchase_design("k'áanche'"), "Abre silla después del primer proyecto")
	home.editor.open_editor("patio")
	home.editor.new_copy("lak|")
	home.editor.support_selected()
	await _capture("08_plato_sobre_mesa")
	await _capture_compact("08_editor_compacto")
	var neighbors: Array[Vector2] = []
	for child: Node in home._residents.get_children():
		if child is Sprite2D:
			for location: Vector2 in neighbors:
				check(
					child.position.distance_to(location) > 55, "Los cuatro vecinos no se superponen"
				)
			neighbors.append(child.position)
	home.get_node("ScreenLayout").preview_compact = true
	home.get_node("ScreenLayout").refresh()
	check(
		home.editor._inventory.get_child(0).get_theme_font_size("font_size") >= 26,
		"Las copias dinámicas usan la tipografía compacta del perfil"
	)
	home.get_node("ScreenLayout").preview_compact = false
	home.get_node("ScreenLayout").refresh()
	var plate: Dictionary = manager.session.garden.objects[1]
	var table_id: int = int(plate.support)
	for orientation: int in range(4):
		home.editor.select_object(table_id)
		home.editor.rotate_selected()
		home.editor.commit()
		check(int(plate.support) == table_id, "El plato conserva su superficie al girar")
		await _capture("08_mesa_girada_%d" % orientation)
	home.editor.new_copy("k'áanche'|chich")
	home.editor.preview = Vector2(820, 460)
	home.editor.commit()
	for orientation: int in range(4):
		home.editor.select_object(home.editor.selected_id)
		home.editor.rotate_selected()
		home.editor.commit()
		await _capture("09_silla_vista_%d" % orientation)
	var before: Dictionary = manager.session.garden.duplicate(true)
	home.editor.select_object(home.editor.selected_id)
	home.editor.rotate_selected()
	home.editor.cancel()
	check(manager.session.garden == before, "Cancelar tampoco confirma el giro")
	home.editor.new_copy("k'áanche'|chich")
	home.editor.cancel()
	check(manager.session.garden == before, "Cancelar una copia no deja objetos almacenados")
	home.editor.hide()
	for direction: Vector2 in [Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		home.walker.step(direction * 100, 0.1, false)
		await _capture("10_paso_%s" % str(direction))
	for level: Dictionary in GameContent.LEVEL_ORDER:
		if int(level.world) < 5:
			manager.complete_level(level.world, level.level)
	home.change_district("shore")
	await create_timer(0.5).timeout
	await _capture("11_orilla")
	root.size = Vector2i(640, 360)
	await process_frame
	await _capture("12_compacto_orilla")
	_check_context_text(home)
	home.room.open_room(home.return_button)
	await _capture("13_compacto_reto")
	home.room.close_room()
	root.size = Vector2i(1280, 720)
	home.change_district("patio")
	await create_timer(0.6).timeout
	await _capture("14_patio_exploracion")
	home.open_map()
	await _capture("15_mapa_abierto")
	home._map.close_map()


func _check_context_text(home: Node) -> void:
	var button: Button = home._action
	var font: Font = button.get_theme_font("font")
	var text_width: float = (
		font
		. get_string_size(
			button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")
		)
		. x
	)
	var margins: float = button.get_theme_stylebox("normal").get_minimum_size().x
	check(
		text_width + margins <= button.size.x, "La orientación completa cabe en el botón contextual"
	)


func _check_wayfinding(home: Node) -> void:
	check("← Patio" not in home._available_spots(), "El patio no ofrece una salida a sí mismo")
	var origin: Vector2 = home.walker.position
	home.walker.position = home._spot("Orilla →") - Vector2(30, 0)
	home._process(0)
	check(home._action.text == "Taller →", "El botón y el letrero indican el mismo barrio")
	home.walker.position = origin
	home._process(0)
	home.open_map()
	check(paused and home._map.visible, "El mapa pausa el paseo")
	check(not home._map._places[1].disabled, "El taller conocido aparece accesible")
	check(home._map._places[2].disabled, "La orilla conserva su bloqueo narrativo")
	await _capture("00_mapa")
	await _capture_compact("00_mapa_compacto")
	home._map.close_map()
	check(not paused, "Cerrar el mapa devuelve el control")
	home.set_process(false)
	home.go_to_place("Orilla →")
	check(not home._route.is_empty(), "El letrero inicia un recorrido")
	for frame: int in range(250):
		home._process(0.02)
		if home._changing:
			break
	await create_timer(0.6).timeout
	check(home.district == "workshop", "Llegar al letrero cambia de barrio sin otra confirmación")
	home.change_district("patio")
	await create_timer(0.6).timeout
	home.set_process(true)


func _check_hops(walker: KalinWalker) -> void:
	var ground: Vector2 = walker.position
	for direction: Vector2 in [Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		walker._phase = 0
		walker.step(direction * 200, KalinWalker.STEP_LENGTH / 400, false)
		check(walker._body.position.y < -10, "Todo el recorte salta en cada dirección")
		check(walker.position == ground, "El salto no altera el suelo ni la profundidad")
		check(walker._left.position.y == walker._right.position.y, "Los pies saltan juntos")
	walker.step(Vector2.ZERO, 0, false)
	check(walker._body.position.y == 0, "Detenerse devuelve a Kalin al suelo")
	walker.step(Vector2.RIGHT * 200, 0.1, true)
	check(walker._body.position.y == 0, "Movimiento reducido conserva una marcha estable")


func _capture_compact(name: String) -> void:
	if capture_directory.is_empty():
		return
	var original_size: Vector2i = root.size
	root.size = Vector2i(640, 360)
	await _capture(name)
	root.size = original_size
	await process_frame


func _capture(name: String) -> void:
	await process_frame
	await process_frame
	if capture_directory.is_empty():
		return
	await RenderingServer.frame_post_draw
	check(
		root.get_texture().get_image().save_png(capture_directory.path_join(name + ".png")) == OK,
		"Captura de " + name
	)
