extends Node2D
class_name VillageHome

## Composición de la aldea. La sesión conserva economía y muebles; cada modal conserva su pausa.
var district: String = "patio"
var walker: KalinWalker
var editor: GardenEditor
var room: ChallengeRoom
var return_button: Button
var _route: PackedVector2Array = PackedVector2Array()
var _transition: Tween
var _changing: bool = false
var _hint: Label
var _title: Label
var _action: Button
var _book: Button
var _project: PanelContainer
var _project_content: VBoxContainer
var _furniture: Node2D
var _homes: Node2D
var _dialogue: VillageDialogue
var _talk_points: Dictionary = {}
var _residents: Node2D
var _return_scene: String = "main_menu"
var _destination: String = ""
var _pending_destination: String = ""
var _map: VillageMap
var _map_button: Button
var _arrival_point: Vector2 = Vector2.ZERO
const LANDSCAPES: Dictionary = {
	"patio": preload("res://Arte/backgrounds/bg_village_patio.svg"),
	"workshop": preload("res://Arte/backgrounds/bg_village_workshop.svg"),
	"shore": preload("res://Arte/backgrounds/bg_village_shore.svg")
}
const TITLES: Dictionary = {
	"patio": "El patio · un rincón para compartir",
	"workshop": "El taller · palabras que transforman",
	"shore": "La orilla · junto al estanque"
}
const RESIDENTS: Dictionary = {
	"patio": ["Áak", "Miis", "Peek'", "K'éek'en"],
	"workshop": ["Ma'ax", "Báalam", "Kuuts", "Kaax"],
	"shore": ["Kay", "Ch'íich'", "Kéej", "T'u'ul"]
}


func _ready() -> void:
	var saved: Dictionary = GameManager.get_scene_state(self)
	if saved.get("district") is String and saved.district in TITLES:
		district = saved.district
	_return_scene = str(saved.get("return_scene", "main_menu"))
	if _return_scene not in GameContent.SCENE_PATHS or _return_scene == "village_home":
		_return_scene = "main_menu"
	walker = KalinWalker.new()
	$World.add_child(walker)
	walker.scale = Vector2.ONE * 0.82
	walker.position = Vector2(640, 570)
	if SaveSchema.is_number(saved.get("x")) and SaveSchema.is_number(saved.get("y")):
		var location: Vector2 = Vector2(float(saved.x), float(saved.y))
		if not VillageGround.blocked(location, GameManager.session.garden, district):
			walker.position = location
	_furniture = Node2D.new()
	$World.add_child(_furniture)
	_residents = Node2D.new()
	$World.add_child(_residents)
	_homes = Node2D.new()
	$World.add_child(_homes)
	_dialogue = VillageDialogue.new()
	add_child(_dialogue)
	_dialogue.restore(saved, 1741)
	_build_ui()
	_map = VillageMap.new()
	add_child(_map)
	_map.travel_requested.connect(change_district)
	editor = GardenEditor.new()
	$UI/Controls.add_child(editor)
	editor.changed.connect(_refresh_garden)
	editor.visibility_changed.connect(
		func() -> void:
			_hint.visible = not editor.visible
			_action.visible = not editor.visible
			_map_button.visible = not editor.visible
			return_button.visible = not editor.visible
			queue_redraw()
	)
	editor.selection_changed.connect(_show_garden_selection)
	editor.closed.connect(
		func() -> void:
			_action.show()
			_refresh_garden()
	)
	room = ChallengeRoom.new()
	add_child(room)
	room.changed.connect(func() -> void: GameManager.checkpoint(self))
	$SpellLaboratory.opened.connect(GameManager.mark_learning_support)
	if saved.get("challenge_room") is Dictionary:
		room.restore(saved.challenge_room)
	_refresh_garden()
	_title.text = TITLES[district]
	_action.grab_focus()
	queue_redraw()


func _button(parent: Control, text: String, location: Vector2, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = location
	button.custom_minimum_size = Vector2(140, 48)
	button.theme_type_variation = &"KalinSecondaryButton"
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _label(parent: Control, text: String, location: Vector2, extent: Vector2) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = location
	label.size = extent
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("164b48"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _build_ui() -> void:
	var controls: Control = $UI/Controls
	_title = _label(controls, TITLES[district], Vector2(24, 12), Vector2(760, 50))
	_title.name = "Title"
	_book = _button(
		controls, "Libro", Vector2(830, 10), func() -> void: $LibroHechizos.show_book(_book)
	)
	_book.name = "Book"
	_map_button = _button(controls, "Mapa", Vector2(980, 10), open_map)
	_map_button.name = "Map"
	return_button = _button(
		controls,
		"Volver",
		Vector2(1130, 10),
		func() -> void: GameManager.go_to_scene(_return_scene)
	)
	return_button.name = "Return"
	_hint = _label(
		controls,
		"Haz clic en un letrero para ir. M abre el mapa; Esc abre la pausa.",
		Vector2(24, 616),
		Vector2(920, 85)
	)
	_hint.name = "Hint"
	_action = _button(controls, "Conversar", Vector2(990, 640), interact)
	_action.custom_minimum_size = Vector2(268, 56)
	_action.name = "Context"
	_project = PanelContainer.new()
	_project.name = "Project"
	_project.position = Vector2(230, 115)
	_project.size = Vector2(820, 480)
	_project.theme_type_variation = &"KalinCreamPanel"
	controls.add_child(_project)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	_project.add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_project_content = VBoxContainer.new()
	_project_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_project_content.add_theme_constant_override("separation", 16)
	scroll.add_child(_project_content)
	_project.hide()


func _draw() -> void:
	draw_texture(LANDSCAPES[district], Vector2.ZERO)
	draw_rect(Rect2(0, 0, 1280, 64), Color("fff3d7"))
	draw_rect(Rect2(0, 604, 1280, 116), Color("fff3d7"))
	if editor != null and editor.visible:
		draw_rect(GardenLayout.PLOT, Color("537857"), false, 3)
		return
	var font: Font = ThemeDB.fallback_font
	for title: String in _available_spots():
		var location: Vector2 = _spot(title)
		var text: String = _place_name(title)
		draw_rect(Rect2(location + Vector2(-4, -18), Vector2(8, 26)), Color("92704b"))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("fff0c9")
		style.border_color = Color("9b7647")
		style.set_border_width_all(2)
		style.set_corner_radius_all(9)
		draw_style_box(style, Rect2(location - Vector2(86, 56), Vector2(172, 42)))
		draw_string(
			font,
			location - Vector2(78, 27),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			160,
			20,
			Color("164b48")
		)
		if _pending_destination == title:
			draw_arc(location, 17, 0, TAU, 24, Color("e4aa27"), 3)


func _place_name(title: String) -> String:
	if title == "Orilla →":
		return (
			"Taller →" if district == "patio" else ("Recuerdos →" if district == "shore" else title)
		)
	if title == "← Patio" and district == "shore":
		return "← Taller"
	return title


func _spot(title: String) -> Vector2:
	return {
		"← Patio": Vector2(95, 550),
		"Mesa de trazos": Vector2(400, 340),
		"Sala de retos": Vector2(760, 340),
		"Mi jardín": Vector2(860, 535),
		"Orilla →": Vector2(760, 450) if district == "shore" else Vector2(1180, 550)
	}[title]


func _process(delta: float) -> void:
	_hint.visible = not editor.visible
	if _changing or editor.visible or _project.visible or get_tree().paused:
		walker.step(Vector2.ZERO, 0, AccessibilityManager.reduced_motion)
		return
	var direction: Vector2 = Vector2(
		(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
			- float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		),
		(
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
			- float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		)
	)
	if direction != Vector2.ZERO:
		_route.clear()
		_pending_destination = ""
	elif not _route.is_empty():
		if walker.position.distance_to(_route[0]) < 5:
			_route.remove_at(0)
		if not _route.is_empty():
			direction = walker.position.direction_to(_route[0])
	var velocity: Vector2 = direction.normalized() * 220
	var next: Vector2 = walker.position + velocity * delta
	if not VillageGround.blocked(next, GameManager.session.garden, district):
		walker.position = next
	else:
		velocity = Vector2.ZERO
	walker.step(velocity, delta, AccessibilityManager.reduced_motion)
	var closest: String = ""
	var distance: float = INF
	for word: String in _talk_points:
		var current: float = walker.position.distance_to(_talk_points[word])
		if current < distance:
			distance = current
			closest = "talk:" + word
	for title: String in _available_spots():
		var current: float = walker.position.distance_to(_spot(title))
		if current < distance:
			distance = current
			closest = title
	_destination = closest if distance < 150 else ""
	_action.visible = not _destination.is_empty()
	_action.disabled = _destination.is_empty()
	_action.text = (
		(
			"Hablar con " + _destination.trim_prefix("talk:")
			if _destination.begins_with("talk:")
			else _place_name(_destination)
		)
		if not _destination.is_empty()
		else "Acércate a un lugar"
	)
	queue_redraw()
	if not _pending_destination.is_empty():
		if walker.position.distance_to(_arrival_point) < 25:
			_destination = _pending_destination
			_pending_destination = ""
			_route.clear()
			interact()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or editor.visible or _project.visible or _changing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = get_global_mouse_position()
		for title: String in _available_spots():
			if Rect2(_spot(title) - Vector2(90, 60), Vector2(180, 80)).has_point(point):
				go_to_place(title)
				get_viewport().set_input_as_handled()
				return
		_pending_destination = ""
		_route = VillageGround.route(walker.position, point, GameManager.session.garden, district)
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		open_map()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode in [KEY_E, KEY_ENTER]:
		interact()
		get_viewport().set_input_as_handled()


func go_to_place(title: String) -> void:
	if title not in _available_spots() or _changing or get_tree().paused:
		return
	_route = VillageGround.route(
		walker.position, _spot(title), GameManager.session.garden, district
	)
	# Un mueble puede ocupar el punto del letrero; se busca también un acceso cercano.
	if _route.is_empty():
		for offset: Vector2 in [Vector2(0, 44), Vector2(-60, 44), Vector2(60, 44)]:
			_route = VillageGround.route(
				walker.position, _spot(title) + offset, GameManager.session.garden, district
			)
			if not _route.is_empty():
				break
	_pending_destination = title if not _route.is_empty() else ""
	if not _route.is_empty():
		_arrival_point = _route[-1]
	_hint.text = "Vamos a " + _place_name(title).replace("←", "").replace("→", "").strip_edges()


func open_map() -> void:
	if editor.visible or _project.visible or _changing:
		return
	_route.clear()
	_pending_destination = ""
	walker.step(Vector2.ZERO, 0, AccessibilityManager.reduced_motion)
	_map.open_map(district, GameManager.session.unlocked_village_world(), _map_button)


func interact() -> void:
	walker.step(Vector2.ZERO, 0, AccessibilityManager.reduced_motion)
	if _destination.begins_with("talk:"):
		var animal: String = _destination.trim_prefix("talk:")
		if animal in ["Áak", "Miis"]:
			show_project()
		else:
			_hint.text = (
				animal
				+ ": "
				+ " ".join(_dialogue.lines_for(animal, GameManager.session.economy.built))
			)
			_dialogue.finish_animal(animal)
			GameManager.checkpoint(self)
		return
	match _destination:
		"Mi jardín":
			if GameManager.session.unlocked_village_world() < 2:
				_hint.text = "El jardín se abre al llegar al mundo de la casa."
			else:
				editor.open_editor(district)
				_action.hide()
				queue_redraw()
		"Sala de retos":
			room.open_room(_action)
		"Mesa de trazos":
			if GameManager.session.unlocked_village_world() < 3:
				_hint.text = "El taller se abrirá con el mundo de las cualidades."
			else:
				$SpellLaboratory.open_lab(_action)
		"← Patio":
			change_district("workshop" if district == "shore" else "patio")
		"Orilla →":
			if district == "shore":
				show_memory()
			else:
				change_district("shore" if district == "workshop" else "workshop")
		"Áak y Miis":
			show_project()
		"Conversar":
			_hint.text = "Los vecinos cuidan este barrio. Puedes seguir explorando."


func show_project() -> void:
	for child: Node in _project_content.get_children():
		_project_content.remove_child(child)
		child.queue_free()
	GameManager.prepare_sharing_corner()
	var title: Label = _label(
		_project_content, "Un rincón para compartir · Áak y Miis", Vector2.ZERO, Vector2(700, 70)
	)
	title.custom_minimum_size = Vector2(700, 70)
	var session: GameSession = GameManager.session
	var ready: bool = MagicEconomy.FIRST_PROJECT in session.economy.preparations
	var message: Label = _label(_project_content, "", Vector2.ZERO, Vector2(700, 100))
	message.custom_minimum_size = Vector2(700, 110)
	message.text = (
		"Queremos reunirnos en el patio. Primero conoce y practica Mesa y Fuerte en la aventura."
		if not ready
		else (
			"La preparación aportó 12 puntos. Abre Mesa y Fuerte, y coloca una mesa fuerte en el jardín. Saldo: %d."
			% session.magic_points
		)
	)
	if session.economy.built:
		message.text = (
			"¡Nuestro rincón está listo! Puedes acomodarlo, guardar los muebles y crear copias gratis. Saldo: %d."
			% session.magic_points
		)
	for word: String in MagicEconomy.design_words():
		if (
			word not in session.words_learned
			or (not session.economy.built and word not in MagicEconomy.FIRST_DESIGNS)
		):
			continue
		var button: Button = _button(
			_project_content,
			(
				("Abierto · " if word in session.economy.designs else "Abrir · 10 puntos · ")
				+ str(VocabularyCatalog.entry(word).spanish)
			),
			Vector2.ZERO,
			_purchase.bind(word)
		)
		button.disabled = not MagicEconomy.can_purchase(
			session.economy, word, session.words_learned, session.magic_points
		)
	_button(
		_project_content,
		"Volver al patio",
		Vector2.ZERO,
		func() -> void:
			_project.hide()
			_action.grab_focus()
	)
	_project.show()
	$ScreenLayout.register_controls(_project)
	(_project_content.get_child(_project_content.get_child_count() - 1) as Button).grab_focus()
	GameManager.checkpoint(self)


func show_memory() -> void:
	if GameManager.session.unlocked_village_world() < 5:
		_hint.text = "El jardín de recuerdos se abrirá con el mundo del portal."
		return
	for child: Node in _project_content.get_children():
		_project_content.remove_child(child)
		child.queue_free()
	var title: Label = _label(
		_project_content, "El jardín de recuerdos", Vector2.ZERO, Vector2(700, 60)
	)
	title.custom_minimum_size = Vector2(700, 60)
	var memory: Dictionary = VillageMemory.normalize(
		GameManager.saved_scene_state("world5_farewell").get("memory", {})
	)
	if memory.is_empty():
		var message: Label = _label(
			_project_content,
			"Junto al portal guardaremos el momento que elijas al despedirte de tus amigos.",
			Vector2.ZERO,
			Vector2(700, 160)
		)
		message.custom_minimum_size = Vector2(700, 160)
	else:
		var moment: MemoryMoment = (
			preload("res://scenes/features/village/memory_moment.tscn").instantiate()
			as MemoryMoment
		)
		moment.custom_minimum_size = Vector2(700, 280)
		_project_content.add_child(moment)
		moment.show_memory(memory)
	_button(
		_project_content,
		"Seguir explorando",
		Vector2.ZERO,
		func() -> void:
			_project.hide()
			_action.grab_focus()
	)
	_project.show()
	$ScreenLayout.register_controls(_project)
	(_project_content.get_child(_project_content.get_child_count() - 1) as Button).grab_focus()


func _purchase(word: String) -> void:
	GameManager.purchase_design(word)
	show_project()


func change_district(area: String) -> void:
	if _changing or area == district:
		return
	var required: int = 4 if area == "shore" else (3 if area == "workshop" else 1)
	if GameManager.session.unlocked_village_world() < required:
		_hint.text = (
			"Esta conexión se abrirá con el mundo %d. Sigue la aventura; entrar será gratis."
			% required
		)
		return
	_changing = true
	_route.clear()
	_pending_destination = ""
	if not AccessibilityManager.reduced_motion:
		_transition = create_tween()
		_transition.tween_property($World, "position:x", -80.0, 0.25)
		_transition.parallel().tween_property($World, "modulate:a", 0.2, 0.25)
		await _transition.finished
		if not is_inside_tree():
			return
	district = area
	walker.position = Vector2(640, 570)
	$World.position.x = 0
	$World.modulate.a = 1
	_title.text = TITLES[district]
	_changing = false
	_refresh_garden()
	queue_redraw()


func _refresh_garden() -> void:
	for child: Node in _furniture.get_children():
		_furniture.remove_child(child)
		child.queue_free()
	for object: Dictionary in GameManager.session.garden.objects:
		if object.stored or object.district != district:
			continue
		var view: GardenObject = GardenObject.new()
		_furniture.add_child(view)
		var table: Dictionary = GardenLayout.object_by_id(
			GameManager.session.garden, int(object.support)
		)
		view.configure(object, false, int(table.get("orientation", 0)))
	_refresh_residents()
	$ScreenLayout.register_controls(editor)
	_hint.text = (
		"Haz clic en los letreros para explorar. M abre el mapa."
		if GameManager.session.economy.built
		else "Áak te espera junto al jardín. Para explorar otros barrios, abre el mapa."
	)
	queue_redraw()
	GameManager.checkpoint(self)


func _show_garden_selection(id: int) -> void:
	for child: Node in _furniture.get_children():
		if child is GardenObject:
			var object: Dictionary = GardenLayout.object_by_id(
				GameManager.session.garden, child.object_id
			)
			child.visible = (
				child.object_id != id and (id == 0 or int(object.get("support", 0)) != id)
			)


func mark_learning_help() -> void:
	room.mark_content_help()


func _available_spots() -> Array[String]:
	var places: Array[String] = ["Mi jardín", "Orilla →"]
	if district != "patio":
		places.append("← Patio")
	if district == "patio":
		places.append("Sala de retos")
	elif district == "workshop":
		places.append("Mesa de trazos")
	return places


func _refresh_residents() -> void:
	_talk_points.clear()
	for child: Node in _homes.get_children():
		_homes.remove_child(child)
		child.queue_free()
	if district == "shore" and GameManager.session.unlocked_village_world() >= 5:
		var portal: Sprite2D = Sprite2D.new()
		portal.texture = preload("res://Arte/exploracion/portal_aldea.svg")
		portal.scale = Vector2.ONE * 0.45
		portal.position = Vector2(760, 270)
		_homes.add_child(portal)
	for index: int in range(RESIDENTS[district].size()):
		var word: String = RESIDENTS[district][index]
		var home: Sprite2D = Sprite2D.new()
		home.texture = VillageResidents.HOMES[word]
		home.scale = Vector2.ONE * (0.43 if index < 2 else 0.34)
		var location: Vector2 = [
			Vector2(120, 310), Vector2(1140, 310), Vector2(310, 270), Vector2(980, 250)
		][index]
		if district == "shore" and index == 1:
			location.y = 245
		home.position = location - Vector2(0, 80)
		_homes.add_child(home)
		if GameManager.has_learned_word(word):
			_talk_points[word] = Vector2(location.x, maxf(335, location.y + 30))
	for child: Node in _residents.get_children():
		_residents.remove_child(child)
		child.queue_free()
	var table: Dictionary = {}
	for object: Dictionary in GameManager.session.garden.objects:
		if not object.stored and object.district == "patio" and object.key == "mayak|chich":
			table = object
			break
	for index: int in range(RESIDENTS[district].size()):
		var word: String = RESIDENTS[district][index]
		if not GameManager.has_learned_word(word):
			continue
		var actor: Sprite2D = Sprite2D.new()
		actor.texture = VillageUseArt.ACTORS.get(word)
		actor.scale = Vector2.ONE * (0.7 if index < 2 else 0.58)
		actor.position = [
			Vector2(120, 430), Vector2(1140, 430), Vector2(310, 340), Vector2(980, 325)
		][index]
		if district == "shore" and word == "Kay":
			actor.position = Vector2(1080, 360)
		elif district == "shore" and index == 3:
			actor.position = Vector2(860, 340)
		elif district == "patio" and index < 2 and not table.is_empty():
			actor.position = GardenLayout.point(table) + Vector2(-130 if index == 0 else 130, -45)
		actor.z_index = int(actor.position.y + 50)
		_residents.add_child(actor)
		if word == "Kay":
			var habitat: VillageHabitat = VillageHabitat.new()
			habitat.position = Vector2(1080, 420)
			habitat.z_index = actor.z_index - 1
			_residents.add_child(habitat)
			habitat.configure(actor)
		_talk_points[word] = actor.position + Vector2(0, 40)


func get_checkpoint_state() -> Dictionary:
	var state: Dictionary = {
		"district": district,
		"x": walker.position.x,
		"y": walker.position.y,
		"return_scene": _return_scene,
		"challenge_room":
		room.snapshot() if is_instance_valid(room) and room.is_node_ready() else {}
	}

	state.merge(_dialogue.checkpoint_extension())
	return state
