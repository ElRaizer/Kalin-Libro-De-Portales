extends Node2D
class_name VillageHome

## Composición de la aldea. La sesión conserva economía y muebles; cada modal conserva su pausa.
@export
var neighbour_profile: VillageNeighbourProfile = preload("res://data/village/neighbours.tres")
@export var visit_profile: VillageVisitProfile = preload("res://data/village_visit_profile.tres")
@export var rest_profile: RestCornerProfile = preload("res://data/village/rest_corner.tres")
@export var challenge_profile: ChallengeProfile = preload("res://data/village/challenges.tres")
@export var garden_profile: GardenProfile = preload("res://data/village/garden.tres")
@export var snack_profile: SnackProfile = preload("res://data/village/snack.tres")
@export var expansion_profile: ExpansionProfile = preload("res://data/village/expansion.tres")
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
var _talk_points: Dictionary[String, Vector2] = {}
var _neighbourhood: VillageNeighbourhood = VillageNeighbourhood.new()
var _neighbour_panel: VillageNeighbourPanel
var _reading_encounter: bool = false
var _residents: Node2D
var _return_scene: String = "main_menu"
var _destination: String = ""
var _pending_destination: String = ""
var _map: VillageMap
var _map_button: Button
var _keyboard_cue: KeyboardCue
var _arrival_point: Vector2 = Vector2.ZERO
var _visit: VillageVisitPresentation
var _visit_panel: VillageVisitPanel
var _resident_views: Dictionary[String, Sprite2D] = {}
var _rest_button: Button
var _rest_panel: RestCornerPanel
var _garland: Sprite2D
var _garden_identity: GardenIdentityView
var _identity_panel: GardenIdentityPanel
var _storage_panel: GardenStoragePanel
var _snack_button: Button
var _snack_panel: SnackPanel
var _practice: VillagePractice
var _expansion_button: Button
var _expansion_panel: ExpansionPanel
var _expansion_gathering: ExpansionGathering
var _album_button: Button
var _album: PersonalAlbumPanel
var _recent_invitation: Dictionary = {}
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
		if not VillageGround.blocked(
			location,
			GameManager.session.garden,
			district,
			_space(),
			GameManager.session.village_expansion.complete
		):
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
	_neighbourhood.restore(saved.get("neighbourhood"), GameManager.session, neighbour_profile)
	_build_ui()
	_album = PersonalAlbumPanel.new()
	_album.garden_profile = garden_profile
	_album.rest_profile = rest_profile
	_album.snack_profile = snack_profile
	_album.expansion_profile = expansion_profile
	_album.blocking_layer = $LibroHechizos
	add_child(_album)
	_album.layout_changed.connect(func() -> void: $ScreenLayout.register_controls(_album.controls))
	_visit = VillageVisitPresentation.new()
	_visit.session = GameManager.session
	$World.add_child(_visit)
	_visit.ended.connect(_on_visit_ended)
	_visit_panel = VillageVisitPanel.new()
	_visit_panel.profile = visit_profile
	_visit_panel.blocking_layer = $LibroHechizos
	add_child(_visit_panel)
	_visit_panel.invitation_requested.connect(invite_guest)
	_visit_panel.dismissal_requested.connect(dismiss_visit)
	_visit_panel.moment_requested.connect(_compose_moment.bind("visit"))
	_rest_panel = RestCornerPanel.new()
	_rest_panel.profile = rest_profile
	add_child(_rest_panel)
	_rest_panel.changed.connect(_on_rest_changed)
	_rest_panel.completed.connect(_refresh_rest_entry)
	_rest_panel.designs_requested.connect(show_project)
	_rest_panel.moment_requested.connect(_compose_moment.bind("rest"))
	_keyboard_cue = KeyboardCue.new()
	$UI.add_child(_keyboard_cue)
	_map = VillageMap.new()
	add_child(_map)
	_map.travel_requested.connect(change_district)
	_map.opportunity_requested.connect(_follow_opportunity)
	_neighbour_panel = VillageNeighbourPanel.new()
	_neighbour_panel.blocking_layer = $LibroHechizos
	add_child(_neighbour_panel)
	_neighbour_panel.layout_changed.connect(
		func() -> void: $ScreenLayout.register_controls(_neighbour_panel.controls)
	)
	_neighbour_panel.next_requested.connect(_advance_neighbour)
	_neighbour_panel.activity_requested.connect(_accept_encounter_activity)
	editor = GardenEditor.new()
	$UI/Controls.add_child(editor)
	_garden_identity = GardenIdentityView.new()
	$World.add_child(_garden_identity)
	_identity_panel = GardenIdentityPanel.new()
	_identity_panel.profile = garden_profile
	add_child(_identity_panel)
	_identity_panel.layout_changed.connect(
		func() -> void: $ScreenLayout.register_controls(_identity_panel.controls)
	)
	_identity_panel.changed.connect(_refresh_garden)
	_storage_panel = GardenStoragePanel.new()
	_storage_panel.profile = garden_profile
	_storage_panel.editor = editor
	add_child(_storage_panel)
	_storage_panel.layout_changed.connect(
		func() -> void: $ScreenLayout.register_controls(_storage_panel.controls)
	)
	editor.identity_requested.connect(
		func(origin: Control) -> void: _identity_panel.open_identity(district, origin)
	)
	editor.storage_requested.connect(_storage_panel.open_storage)
	editor.changed.connect(_refresh_garden)
	editor.visibility_changed.connect(
		func() -> void:
			if editor.visible:
				dismiss_visit()
			_hint.visible = not editor.visible
			_action.visible = not editor.visible
			_map_button.visible = not editor.visible
			return_button.visible = not editor.visible
			_refresh_rest_entry()
			queue_redraw()
	)
	editor.selection_changed.connect(_show_garden_selection)
	editor.closed.connect(
		func() -> void:
			_action.show()
			_refresh_garden()
			_action.grab_focus()
	)
	room = ChallengeRoom.new()
	room.profile = challenge_profile
	add_child(room)
	room.layout_changed.connect(func() -> void: $ScreenLayout.register_controls(room.controls))
	room.project_delivery_requested.connect(_deliver_challenge_to_rest)
	room.changed.connect(func() -> void: GameManager.checkpoint(self))
	$LibroHechizos.layer = 20
	_snack_panel = SnackPanel.new()
	_snack_panel.profile = snack_profile
	_snack_panel.blocking_layer = $LibroHechizos
	add_child(_snack_panel)
	_snack_panel.changed.connect(_refresh_expansion)
	_snack_panel.layout_changed.connect(
		func() -> void: $ScreenLayout.register_controls(_snack_panel.controls)
	)
	_snack_panel.book_requested.connect(_open_activity_book)
	_snack_panel.moment_requested.connect(
		func(guests: Array[String]) -> void: _compose_moment("snack", guests)
	)
	_practice = VillagePractice.new()
	_practice.room = room
	_practice.blocking_layer = $LibroHechizos
	add_child(_practice)
	_practice.changed.connect(func() -> void: GameManager.checkpoint(self))
	_practice.layout_changed.connect(
		func(controls: Control) -> void: $ScreenLayout.register_controls(controls)
	)
	_practice.book_requested.connect(_open_activity_book)
	_expansion_gathering = ExpansionGathering.new()
	$World.add_child(_expansion_gathering)
	_expansion_panel = ExpansionPanel.new()
	_expansion_panel.profile = expansion_profile
	_expansion_panel.blocking_layer = $LibroHechizos
	add_child(_expansion_panel)
	_expansion_panel.layout_changed.connect(
		func() -> void: $ScreenLayout.register_controls(_expansion_panel.controls)
	)
	_expansion_panel.changed.connect(_refresh_expansion)
	_expansion_panel.book_requested.connect(_open_activity_book)
	_expansion_panel.moment_requested.connect(_compose_moment.bind("expansion"))
	$SpellLaboratory.opened.connect(GameManager.mark_learning_support)
	$SpellLaboratory.placement_requested.connect(_place_laboratory_result)
	if saved.get("challenge_room") is Dictionary:
		room.restore(saved.challenge_room)
	if saved.get("practice") is Dictionary:
		_practice.restore(saved.practice)
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
	_title = _label(controls, TITLES[district], Vector2(24, 12), Vector2(500, 50))
	_title.name = "Title"
	_album_button = _button(controls, "Álbum", Vector2(530, 8), open_album)
	_album_button.name = "PersonalAlbum"
	_album_button.hide()
	_rest_button = _button(controls, rest_profile.title, Vector2(24, 78), open_rest_project)
	_rest_button.name = "RestProject"
	_rest_button.custom_minimum_size = Vector2(350, 54)
	_rest_button.hide()
	_snack_button = _button(
		controls, "Merienda junto al estanque", Vector2(24, 78), open_snack_project
	)
	_snack_button.name = "SnackProject"
	_snack_button.custom_minimum_size = Vector2(440, 54)
	_snack_button.hide()
	_expansion_button = _button(
		controls, expansion_profile.title, Vector2(550, 78), open_expansion_project
	)
	_expansion_button.name = "ExpansionProject"
	_expansion_button.custom_minimum_size = Vector2(550, 54)
	_expansion_button.hide()
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
	if district == "shore" and GameManager.session.village_expansion.complete:
		draw_rect(_space().extension_entry, Color("dec498"))
		draw_rect(_space().extension_plot, expansion_profile.ground_color)
		draw_rect(_space().extension_plot, Color("537857"), false, 3)
		if GameManager.session.village_expansion.purpose == "snack":
			draw_texture_rect(
				expansion_profile.border,
				Rect2(
					_space().extension_plot.position, Vector2(_space().extension_plot.size.x, 36)
				),
				false
			)
	draw_rect(Rect2(0, 0, 1280, 64), Color("fff3d7"))
	draw_rect(Rect2(0, 604, 1280, 116), Color("fff3d7"))
	if editor != null and editor.visible:
		for plot: Rect2 in _space().plots(GameManager.session.village_expansion.complete):
			draw_rect(plot, Color("537857"), false, 3)
		return
	var font: Font = ThemeDB.fallback_font
	for title: String in _available_spots():
		var location: Vector2 = _spot(title)
		var text: String = _place_name(title)
		draw_rect(Rect2(location + Vector2(-4, -18), Vector2(8, 26)), Color("92704b"))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("f7dc9b") if title == "Encuentro" else Color("fff0c9")
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
	if title == "El claro":
		return _space().extension_anchor
	if title == "Encuentro":
		return _neighbourhood.encounter().location
	return {
		"← Patio": Vector2(95, 550),
		"Mesa de trazos": Vector2(400, 340),
		"Sala de retos": Vector2(760, 340),
		"Mi jardín": Vector2(860, 535),
		"Orilla →": Vector2(760, 450) if district == "shore" else Vector2(1180, 550)
	}[title]


func _process(delta: float) -> void:
	_visit.suspended = _changing or editor.visible or _project.visible
	walker.apply_depth(
		walker.position.y,
		Vector2(
			(
				VillageGround
				. bounds(_space(), GameManager.session.village_expansion.complete)
				. position
				. y
			),
			_space().floor_bounds.end.y
		)
	)
	_hint.visible = not editor.visible
	if _changing or editor.visible or _project.visible or get_tree().paused:
		_keyboard_cue.update_cue(walker.position, false, false, false, true, delta)
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
	if not VillageGround.blocked(
		next,
		GameManager.session.garden,
		district,
		_space(),
		GameManager.session.village_expansion.complete
	):
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
	if district == "patio":
		for object: Dictionary in GameManager.session.garden.objects:
			if not VillageVisitState.usable_table(object):
				continue
			var current: float = walker.position.distance_to(
				GardenLayout.point(object) + Vector2(0, 55)
			)
			if current < distance:
				distance = current
				closest = "visit:" + str(object.id)
	_destination = closest if distance < 150 else ""
	_action.visible = not _destination.is_empty()
	_action.disabled = _destination.is_empty()
	_keyboard_cue.update_cue(
		walker.head_position(),
		true,
		velocity.length_squared() > 0,
		not _destination.is_empty(),
		true,
		delta
	)
	_action.text = (
		(
			"Hablar con " + _destination.trim_prefix("talk:")
			if _destination.begins_with("talk:")
			else (
				("Ver la visita" if _visit.active() else "Invitar a un amigo")
				if _destination.begins_with("visit:")
				else _place_name(_destination)
			)
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
		for child: Node in _furniture.get_children():
			if child is GardenObject and child.hit_area.has_point(point):
				var object: Dictionary = GardenLayout.object_by_id(
					GameManager.session.garden, child.object_id
				)
				if VillageVisitState.usable_table(object):
					_destination = "visit:" + str(child.object_id)
					interact()
					get_viewport().set_input_as_handled()
					return
		_pending_destination = ""
		_route = VillageGround.route(
			walker.position,
			point,
			GameManager.session.garden,
			district,
			_space(),
			GameManager.session.village_expansion.complete
		)
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
		walker.position,
		_spot(title),
		GameManager.session.garden,
		district,
		_space(),
		GameManager.session.village_expansion.complete
	)
	# Un mueble puede ocupar el punto del letrero; se busca también un acceso cercano.
	if _route.is_empty():
		for offset: Vector2 in [Vector2(0, 44), Vector2(-60, 44), Vector2(60, 44)]:
			_route = VillageGround.route(
				walker.position,
				_spot(title) + offset,
				GameManager.session.garden,
				district,
				_space(),
				GameManager.session.village_expansion.complete
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
	_map.open_map(
		district,
		GameManager.session.unlocked_village_world(),
		_map_button,
		_neighbourhood.opportunity()
	)
	$ScreenLayout.register_controls(_map.controls)


func close_transient_ui() -> bool:
	for panel: VillagePanel in [
		_neighbour_panel, _album, _snack_panel, _identity_panel, _storage_panel, _expansion_panel
	]:
		if panel.visible:
			panel.close_panel()
			return true
	if _practice.close_active():
		return true
	if room.visible:
		room.close_room()
		return true
	if _rest_panel.visible:
		_rest_panel.close_panel()
		return true
	if _visit_panel.visible:
		_visit_panel.close_panel()
		return true
	return false


func interact() -> void:
	walker.step(Vector2.ZERO, 0, AccessibilityManager.reduced_motion)
	if _destination.begins_with("visit:"):
		_route.clear()
		_pending_destination = ""
		_visit_panel.open_for(_destination.trim_prefix("visit:").to_int(), _action)
		$ScreenLayout.register_controls(_visit_panel.controls)
		return
	if _destination.begins_with("talk:"):
		var animal: String = _destination.trim_prefix("talk:")
		if animal in RestCornerState.GUESTS and not GameManager.session.has_finished_adventure():
			show_project()
		elif animal in RestCornerState.GUESTS and not GameManager.session.rest_corner.complete:
			open_rest_project(_action)
		else:
			_open_neighbour(_action, animal)
		return
	match _destination:
		"Encuentro":
			_open_neighbour(_action)
		"El claro":
			open_expansion_project()
		"Mi jardín":
			if GameManager.session.unlocked_village_world() < 2:
				_hint.text = "El jardín se abre al llegar al mundo de la casa."
			else:
				editor.open_editor(district)
				_action.hide()
				queue_redraw()
		"Sala de retos":
			_practice.open_hub(_action)
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
		"Queremos reunirnos en el patio. Practica Mesa y Fuerte; después podrás guardar sus diseños para tu jardín."
		if not ready
		else (
			"Ya sabes crear con estas palabras. Guarda los diseños Mesa y Fuerte para construir en tu jardín. La preparación aportó 12 puntos. Saldo: %d."
			% session.magic_points
		)
	)
	if session.economy.built:
		message.text = (
			"¡Nuestro rincón está listo! Los diseños guardados permiten crear copias gratis en tu jardín. Saldo: %d."
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
				(
					"Diseño guardado · "
					if word in session.economy.designs
					else "Diseño · 10 puntos · "
				)
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


func _place_laboratory_result(id: String) -> void:
	if _changing or get_tree().paused:
		return
	_route.clear()
	_pending_destination = ""
	editor.open_editor(district)
	editor.new_copy(id)
	$ScreenLayout.register_controls(editor)
	queue_redraw()


func change_district(area: String) -> void:
	if _changing or area == district or area not in TITLES:
		return
	var required: int = 4 if area == "shore" else (3 if area == "workshop" else 1)
	if GameManager.session.unlocked_village_world() < required:
		_hint.text = (
			"Esta conexión se abrirá con el mundo %d. Sigue la aventura; entrar será gratis."
			% required
		)
		return
	dismiss_visit()
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
	walker.position = VillageGround.safe_arrival(
		_space().arrival,
		GameManager.session.garden,
		district,
		_space(),
		GameManager.session.village_expansion.complete
	)
	$World.position.x = 0
	$World.modulate.a = 1
	_title.text = TITLES[district]
	_changing = false
	_refresh_garden()
	queue_redraw()


func _refresh_garden() -> void:
	_visit.clear()
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
	_refresh_rest_entry()
	walker.position = VillageGround.safe_arrival(
		walker.position,
		GameManager.session.garden,
		district,
		_space(),
		GameManager.session.village_expansion.complete
	)
	_present_visit(false)
	$ScreenLayout.register_controls(editor)
	_hint.text = (
		"Acércate a tu mesa para invitar a un amigo. M abre el mapa."
		if GameManager.session.economy.built
		else "Áak te espera junto al jardín. Para explorar otros barrios, abre el mapa."
	)
	if _visit.active():
		_show_visit_hint()
	elif GameManager.session.has_finished_adventure():
		_show_entry_opportunity()
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
	if district == "shore" and GameManager.session.village_expansion.complete:
		places.append("El claro")
	var encounter: PostgameEncounter = _neighbourhood.encounter()
	if encounter != null and encounter.district == district:
		places.append("Encuentro")
	return places


func _refresh_residents() -> void:
	_talk_points.clear()
	_resident_views.clear()
	for child: Node in _homes.get_children():
		_homes.remove_child(child)
		child.queue_free()
	if district == "shore" and GameManager.session.unlocked_village_world() >= 5:
		var portal: Sprite2D = Sprite2D.new()
		portal.texture = preload("res://Arte/exploracion/portal_aldea.svg")
		portal.scale = Vector2.ONE * 0.45
		portal.position = Vector2(760, 270)
		_homes.add_child(portal)
	for index: int in range(VillageNeighbours.RESIDENTS[district].size()):
		var word: String = VillageNeighbours.RESIDENTS[district][index]
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
	for index: int in range(VillageNeighbours.RESIDENTS[district].size()):
		var word: String = VillageNeighbours.RESIDENTS[district][index]
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
		actor.z_index = int(actor.position.y + 50)
		_residents.add_child(actor)
		_resident_views[word] = actor
		if word == "Kay":
			var habitat: VillageHabitat = VillageHabitat.new()
			habitat.position = Vector2(1080, 420)
			habitat.z_index = actor.z_index - 1
			_residents.add_child(habitat)
			habitat.configure(actor)
		_talk_points[word] = actor.position + Vector2(0, 40)


func invite_guest(animal: String, object_id: int) -> bool:
	if district != "patio" or editor.visible or get_tree().paused:
		return false
	if not GameManager.session.begin_village_visit(animal, object_id, visit_profile.duration):
		return false
	if not _present_visit(true):
		GameManager.session.end_village_visit()
		_hint.text = "Deja espacio junto a la mesa para que tu amigo pueda acercarse."
		return false
	if not GameManager.confirm_village_guest(animal):
		GameManager.session.end_village_visit()
		_visit.clear()
		_refresh_residents()
		_hint.text = "No se pudo guardar la invitación. Puedes reintentar desde la mesa."
		return false
	_remember_invitation(GameManager.session.village_visit)
	_show_visit_hint()
	GameManager.checkpoint(self)
	return true


func open_rest_project(origin: Control = null) -> void:
	if editor.visible or _project.visible or _changing:
		return
	_route.clear()
	_pending_destination = ""
	_rest_panel.open_project(origin if is_instance_valid(origin) else _rest_button)
	$ScreenLayout.register_controls(_rest_panel.controls)


func open_snack_project() -> void:
	if editor.visible or _changing or _project.visible:
		return
	_route.clear()
	_pending_destination = ""
	_snack_panel.open_project(_snack_button)


func _space() -> VillageSpace:
	return GameContent.VILLAGE_SPACES.space(district)


func open_expansion_project() -> void:
	if editor.visible or _changing or _project.visible or district != "shore":
		return
	_route.clear()
	_pending_destination = ""
	_expansion_panel.open_project(_expansion_button)


func _refresh_expansion() -> void:
	var state: Dictionary = GameManager.session.village_expansion
	_expansion_button.visible = (
		district == "shore" and GameManager.session.expansion_ready() and not editor.visible
	)
	_expansion_button.text = (
		"Nuestro claro · cambiar o invitar" if state.complete else expansion_profile.title
	)
	_expansion_gathering.clear()
	if district == "shore" and state.complete:
		var guests: Array[String] = []
		guests.assign(state.guests)
		_expansion_gathering.present(
			state.purpose,
			guests,
			_space().guest_anchors,
			GameManager.session.snack_project.food,
			expansion_profile,
			false,
			0.48
		)
	queue_redraw()
	GameManager.checkpoint(self)


func _open_activity_book(origin: Control) -> void:
	GameManager.checkpoint(self)
	$LibroHechizos.show_book(origin)


func _deliver_challenge_to_rest(word: String) -> void:
	if word != GameManager.session.rest_corner.choice:
		return
	if not GameManager.session.confirm_rest_corner():
		return
	room.close_room()
	_on_rest_changed()
	open_rest_project(_action)


func _refresh_rest_entry() -> void:
	var session: GameSession = GameManager.session
	_refresh_album_entry()
	_rest_button.visible = (
		session.has_finished_adventure() and district == "patio" and not editor.visible
	)
	_rest_button.text = "Nuestro rincón" if session.rest_corner.complete else rest_profile.title
	_snack_button.visible = (
		session.has_finished_adventure() and district == "shore" and not editor.visible
	)
	if is_instance_valid(_expansion_panel):
		_refresh_expansion()
	if not is_instance_valid(_garland):
		_garland = Sprite2D.new()
		$World.add_child(_garland)
	_garland.texture = rest_profile.garland
	_garland.position = rest_profile.garland_position
	_garland.z_index = int(_garland.position.y + 50)
	var identity: Dictionary = GardenIdentity.entry_for(
		session.garden_identity, district, session.rest_corner.complete
	)
	_garland.visible = session.rest_corner.complete and "gathering" in identity.decorations
	_garden_identity.configure(garden_profile, identity)


func _on_rest_changed() -> void:
	_refresh_rest_entry()
	if GameManager.session.rest_corner.complete:
		_hint.text = rest_profile.option_for(GameManager.session.rest_corner.choice).return_line
	GameManager.checkpoint(self)


func dismiss_visit() -> void:
	if not GameManager.session.end_village_visit():
		return
	_visit.clear()
	_on_visit_ended()


func _present_visit(entering: bool) -> bool:
	var visit: Dictionary = GameManager.session.village_visit
	if visit.is_empty() or district != "patio":
		return false
	var resident: Sprite2D = _resident_views.get(visit.animal)
	var source: String = VillageNeighbours.district_for(visit.animal)
	var home: Vector2 = VillageGround.safe_arrival(
		Vector2(85 if source == "workshop" else 1195, 555),
		GameManager.session.garden,
		district,
		_space(),
		false
	)
	var avatar: Texture2D = VillageUseArt.ACTORS[visit.animal]
	var actor_scale: Vector2 = Vector2.ONE * 95.0 / avatar.get_image().get_used_rect().size.y
	if is_instance_valid(resident):
		home = resident.position + Vector2(0, 40)
		actor_scale = resident.scale
	for child: Node in _furniture.get_children():
		if child is GardenObject and child.object_id == int(visit.object_id):
			if _visit.present(child, home, actor_scale, entering):
				if is_instance_valid(resident):
					resident.hide()
					_talk_points.erase(visit.animal)
				if not entering:
					_remember_invitation(visit)
				return true
	GameManager.session.end_village_visit()
	return false


func _remember_invitation(visit: Dictionary) -> void:
	var session: GameSession = GameManager.session
	var table: Dictionary = GardenLayout.object_by_id(session.garden, int(visit.object_id))
	var point: Vector2 = VillageVisitPlacement.meeting_point(table, session.garden, _space())
	var setting: Dictionary = GardenCompositions.capture(session.garden, "patio")
	setting.table = int(visit.object_id)
	setting.guest_x = point.x
	setting.guest_y = point.y
	setting.identity = GardenIdentity.entry_for(
		session.garden_identity, "patio", session.rest_corner.complete
	)
	_recent_invitation = _moment("visit", "Una visita a mi rincón", [visit.animal], setting)
	_refresh_album_entry()


func _refresh_album_entry() -> void:
	var session: GameSession = GameManager.session
	_album_button.visible = (
		not editor.visible
		and (
			session.has_finished_adventure()
			or not _recent_invitation.is_empty()
			or session.personal_moment_count() > 0
		)
	)


func open_album() -> void:
	if editor.visible or _project.visible or _changing or get_tree().paused:
		return
	_route.clear()
	_pending_destination = ""
	walker.step(Vector2.ZERO, 0, AccessibilityManager.reduced_motion)
	_album.open_gallery(_album_button, _recent_invitation)


func _compose_moment(kind: String, guests_at_snack: Array[String] = []) -> void:
	var session: GameSession = GameManager.session
	var source: Dictionary = {}
	var origin: Control
	match kind:
		"visit":
			source = _recent_invitation
			origin = _action
			_visit_panel.close_panel()
		"rest":
			var guests: Array[String] = []
			for guest: String in RestCornerState.GUESTS:
				if guest in session.words_learned:
					guests.append(guest)
			source = _moment(
				"rest", rest_profile.title, guests, {"word": session.rest_corner.choice}
			)
			origin = _rest_button
			_rest_panel.close_panel()
		"snack":
			var snack: Dictionary = session.snack_project
			source = _moment(
				"snack",
				"Merienda en la orilla",
				guests_at_snack,
				{"food": snack.food, "decoration": snack.decoration}
			)
			origin = _snack_button
			_snack_panel.close_panel()
		"expansion":
			var state: Dictionary = session.village_expansion
			var setting: Dictionary = {"purpose": state.purpose}
			if state.purpose == "rest":
				setting.word = expansion_profile.rest_word
			else:
				setting.food = session.snack_project.food
			source = _moment("expansion", "Una reunión en el claro", state.guests, setting)
			origin = _expansion_button
			_expansion_panel.close_panel()
	if PersonalAlbum.valid_moment(source, session.words_learned):
		_album.open_composer(origin, source, _recent_invitation)


func _moment(kind: String, title: String, guests: Array, setting: Dictionary) -> Dictionary:
	return {
		"kind": kind,
		"title": title.substr(0, PersonalAlbum.TITLE_LENGTH).strip_edges(),
		"guests": guests,
		"setting": setting,
		"frame": "close" if kind == "expansion" else "wide",
		"pose": PersonalAlbum.PRESET_POSES[1]
	}


func _show_entry_opportunity() -> void:
	var suggestion: Dictionary = _neighbourhood.opportunity()
	if not suggestion.is_empty():
		_hint.text = "%s. Abre el mapa para ir o sigue paseando." % suggestion.title


func _follow_opportunity() -> void:
	var suggestion: Dictionary = _neighbourhood.opportunity()
	if suggestion.is_empty():
		return
	if district != suggestion.area:
		await change_district(suggestion.area)
	if not is_inside_tree() or district != suggestion.area:
		return
	_open_neighbour_activity(suggestion.action, _map_button)


func _open_neighbour_activity(action: String, origin: Control) -> void:
	match action:
		"encounter":
			_open_neighbour(origin)
		"rest":
			open_rest_project(origin)
		"snack":
			open_snack_project()
		"expansion":
			open_expansion_project()
		"laboratory":
			$SpellLaboratory.open_lab(origin)
		"album":
			open_album()


func _open_neighbour(origin: Control, animal: String = "") -> void:
	if get_tree().paused or editor.visible or _project.visible or _changing:
		return
	_reading_encounter = animal.is_empty()
	if _reading_encounter and _neighbourhood.encounter() == null:
		return
	_route.clear()
	_pending_destination = ""
	if not _reading_encounter:
		_neighbourhood.begin_talk(animal)
	_render_neighbour()
	if _neighbour_panel.open_panel(origin):
		_neighbour_panel.focus_line()
		GameManager.checkpoint(self)


func _encounter_activity_label(action: String) -> String:
	match action:
		"rest":
			return "Ver el rincón"
		"snack":
			return "Abrir la merienda"
		"expansion":
			return "Ver la propuesta del claro"
		"laboratory":
			return "Abrir la mesa de trazos"
		"album":
			return "Abrir mi álbum"
	return ""


func _resident_lines() -> Array[String]:
	var animal: String = _neighbourhood.talk_animal
	var topics: Array[String] = _neighbourhood.talk_topics
	var lines: Array[String] = _dialogue.lines_for(animal, "mission" in topics)
	var session: GameSession = GameManager.session
	for topic: String in topics:
		match topic:
			"visit":
				lines.append(
					neighbour_profile.visit_memories.get(animal, "Recuerdo nuestra visita.")
				)
			"rest":
				var option: RestCornerOption = rest_profile.option_for(session.rest_corner.choice)
				lines.append(option.aak_reaction if animal == "Áak" else option.miis_reaction)
			"snack":
				lines.append(snack_profile.guest_reactions[animal])
			"opening":
				lines.append(
					(
						"Recuerdo cuando inauguramos el claro. "
						+ neighbour_profile.clearing_memories[animal]
					)
				)
			"clearing":
				lines.append(neighbour_profile.clearing_memories[animal])
	return lines


func _render_neighbour() -> void:
	if _reading_encounter:
		var encounter: PostgameEncounter = _neighbourhood.encounter()
		var line: int = _neighbourhood.encounter_line
		_neighbour_panel.set_line(
			encounter.title,
			encounter.speakers[line],
			encounter.lines[line],
			line == encounter.lines.size() - 1,
			_encounter_activity_label(encounter.activity)
		)
	else:
		var lines: Array[String] = _resident_lines()
		var line: int = _neighbourhood.talk_line
		_neighbour_panel.set_line(
			"En el camino", _neighbourhood.talk_animal, lines[line], line == lines.size() - 1
		)


func _advance_neighbour() -> void:
	var continues: bool
	if _reading_encounter:
		continues = _neighbourhood.advance_encounter()
	else:
		continues = _neighbourhood.talk_line + 1 < _resident_lines().size()
		if continues:
			_neighbourhood.talk_line += 1
		else:
			_dialogue.finish_animal(_neighbourhood.talk_animal)
			_neighbourhood.finish_talk()
	if continues:
		_render_neighbour()
	else:
		_neighbour_panel.close_panel()
		if _reading_encounter:
			_show_entry_opportunity()
			queue_redraw()
	GameManager.checkpoint(self)


func _accept_encounter_activity() -> void:
	var encounter: PostgameEncounter = _neighbourhood.encounter()
	var action: String = encounter.activity
	_advance_neighbour()
	_open_neighbour_activity(action, _map_button)


func _show_visit_hint() -> void:
	var animal: String = GameManager.session.village_visit.animal
	_hint.text = (
		animal
		+ ": «"
		+ visit_profile.reaction_for(animal)
		+ "»\nLa visita termina sola. Puedes guardar el momento en Álbum."
	)


func _on_visit_ended() -> void:
	_refresh_residents()
	_hint.text = "La visita terminó. Puedes invitar de nuevo desde tu mesa."
	GameManager.checkpoint(self)


func get_checkpoint_state() -> Dictionary:
	var state: Dictionary = {
		"district": district,
		"x": walker.position.x,
		"y": walker.position.y,
		"return_scene": _return_scene,
		"challenge_room":
		room.snapshot() if is_instance_valid(room) and room.is_node_ready() else {},
		"practice":
		_practice.snapshot() if is_instance_valid(_practice) and _practice.is_node_ready() else {}
	}

	state.merge(_dialogue.checkpoint_extension())
	state.neighbourhood = _neighbourhood.snapshot()
	return state
