extends CanvasLayer
class_name SpellLaboratory

signal opened
signal placement_requested(id: String)

## Práctica opcional: sólo combinaciones canónicas cuyas palabras ya se conocen.
@export var profile: LaboratoryProfile = preload("res://data/village/laboratory.tres")
var _ids: Array[String] = []
var _previous_focus: WeakRef
var _was_paused: bool = false
var _visit_seed: int = 1
var _magic: Tween
var _casting: bool = false
var _result_id: String = ""
var _comparison_id: String = ""
var _purchase_id: String = ""
@onready var nouns: WordChipSelector = $Shade/Panel/Content/Browse/Body/NounScroll/Noun
@onready var qualities: WordChipSelector = $Shade/Panel/Content/Browse/Body/QualityScroll/Quality
@onready var result: MeaningIllustration = $Shade/Panel/Content/Browse/Body/Stage/Result
@onready var description: Label = $Shade/Panel/Content/Browse/Body/Description
@onready var create_button: Button = $Shade/Panel/Content/Actions/Create
@onready var _body: VBoxContainer = $Shade/Panel/Content/Browse/Body
@onready var _favorite: Button = $Shade/Panel/Content/Browse/Body/Ideas/Favorite
@onready var _compare: Button = $Shade/Panel/Content/Browse/Body/Ideas/Compare
@onready var _place: Button = $Shade/Panel/Content/Actions/Place
@onready var _availability: Label = $Shade/Panel/Content/Browse/Body/Availability
@onready var _purchase: HBoxContainer = $Shade/Panel/Content/Browse/Body/Purchase
@onready var _confirm: Button = $Shade/Panel/Content/Browse/Body/Purchase/Confirm
@onready var _favorites: HBoxContainer = $Shade/Panel/Content/Browse/Body/FavoritesScroll/Favorites


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	nouns.item_selected.connect(_select_noun)
	qualities.item_selected.connect(_clear_result)
	create_button.pressed.connect(create_spell)
	$Shade/Panel/Content/Actions/Close.pressed.connect(close_lab)
	_favorite.pressed.connect(toggle_favorite)
	_compare.pressed.connect(compare_result)
	_place.pressed.connect(request_placement)
	_confirm.pressed.connect(confirm_purchase)
	_purchase.get_node("Back").pressed.connect(cancel_purchase)


func open_lab(origin: Control) -> void:
	if visible or get_tree().paused:
		return
	_ids.clear()
	_comparison_id = ""
	nouns.clear()
	var known: Dictionary = GameManager.learned_words()
	var used: Array[String] = []
	for id: String in CombinationCatalog.targets():
		if not LaboratoryState.known_combination(id, known):
			continue
		var parts: PackedStringArray = id.split("|")
		_ids.append(id)
		if parts[0] not in used:
			used.append(parts[0])
			nouns.add_item(parts[0] + " · " + str(VocabularyCatalog.entry(parts[0]).spanish))
			nouns.set_item_metadata(nouns.item_count - 1, parts[0])
			nouns.set_item_icon(nouns.item_count - 1, VillageUseArt.object_texture(parts[0], ""))
	_previous_focus = weakref(origin)
	_was_paused = get_tree().paused
	_visit_seed = randi_range(1, 2000000000)
	get_tree().paused = true
	show()
	opened.emit()
	_select_noun(0)
	_refresh_favorites()
	if nouns.item_count > 0:
		nouns.focus_selected()
	else:
		$Shade/Panel/Content/Actions/Close.grab_focus()


func _select_noun(index: int) -> void:
	qualities.clear()
	if index >= 0 and index < nouns.item_count:
		var word: String = str(nouns.get_item_metadata(index))
		for id: String in _ids:
			var parts: PackedStringArray = id.split("|")
			if parts[0] != word:
				continue
			qualities.add_item(
				(
					"Sin cualidad"
					if parts[1].is_empty()
					else parts[1] + " · " + str(VocabularyCatalog.entry(parts[1]).spanish)
				)
			)
			qualities.set_item_metadata(qualities.item_count - 1, id)
	create_button.disabled = qualities.item_count == 0
	$ScreenLayout.register_controls($Shade/Panel/Content)
	_clear_result()


func _clear_result(_index: int = 0) -> void:
	_cancel_magic()
	_result_id = ""
	_purchase_id = ""
	result.hide()
	$Shade/Panel/Content/Browse/Body/Stage/Seal.show()
	description.text = "Elige palabras conocidas y observa lo que crean."
	if _ids.is_empty():
		description.text = "Primero descubre un objeto durante la aventura."
	_refresh_result_actions()


func create_spell() -> void:
	if not visible or _casting or qualities.item_count == 0 or qualities.selected < 0:
		return
	var id: String = str(qualities.get_item_metadata(qualities.selected))
	if id not in _ids:
		return
	_casting = true
	create_button.disabled = true
	_result_id = ""
	_purchase_id = ""
	_refresh_result_actions()
	if not AccessibilityManager.reduced_motion:
		_magic = create_tween()
		_magic.tween_property($Shade/Panel/Content/Browse/Body/Stage/Kalin, "rotation", -0.08, 0.2)
		_magic.parallel().tween_method(_trace_magic, 0.0, 1.0, 0.2)
		_magic.tween_callback(_reveal_base.bind(id))
		_magic.tween_property($Shade/Panel/Content/Browse/Body/Stage/Trace, "modulate:a", 0.0, 0.25)
		_magic.tween_callback(_finish_magic.bind(id))
	else:
		_finish_magic(id)


func _trace_magic(progress: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in range(maxi(2, int(progress * 32) + 1)):
		var angle: float = TAU * float(step) / 32.0
		points.append(Vector2(cos(angle) * 100, sin(angle) * 45))
	$Shade/Panel/Content/Browse/Body/Stage/Trace.points = points
	$Shade/Panel/Content/Browse/Body/Stage/Seal.modulate.a = 1.0 - progress


func _reveal_base(id: String) -> void:
	result.show_meaning(id.get_slice("|", 0), "")
	result.show()
	$Shade/Panel/Content/Browse/Body/Stage/Seal.hide()


func _finish_magic(id: String) -> void:
	if not is_inside_tree() or not visible or not _casting:
		return
	var entry: ExerciseEntry = ExerciseEntry.new()
	CombinationCatalog.apply_entry(entry, id)
	result.show_meaning(entry.noun, entry.adjective)
	$Shade/Panel/Content/Browse/Body/Stage/Seal.hide()
	$Shade/Panel/Content/Browse/Body/Stage/Kalin.rotation = 0.0
	result.show()
	result.celebrate()
	_casting = false
	_result_id = id
	create_button.disabled = false
	description.text = entry.phrase + "\n" + entry.translation
	var words: Array[String] = [entry.noun]
	if not entry.adjective.is_empty():
		words.append(entry.adjective)
	GameManager.record_learning(words, "experiment", "laboratory:%s@%d" % [id, _visit_seed], true)
	_refresh_result_actions()
	$Shade/Panel/Content/Browse.call_deferred("ensure_control_visible", _body.get_node("Stage"))


func toggle_favorite() -> void:
	if _result_id.is_empty():
		return
	var enabled: bool = _result_id not in GameManager.session.laboratory_favorites
	if GameManager.set_laboratory_favorite(_result_id, enabled, profile.favorite_limit):
		_refresh_favorites()
		_refresh_result_actions()
	else:
		_availability.text = "No se pudo guardar el favorito. Conservamos tus favoritos anteriores."


func _refresh_favorites() -> void:
	for child: Node in _favorites.get_children():
		_favorites.remove_child(child)
		child.queue_free()
	for id: String in GameManager.session.laboratory_favorites:
		var button: Button = Button.new()
		button.text = str(CombinationCatalog.targets()[id])
		button.theme_type_variation = &"KalinSecondaryButton"
		button.pressed.connect(try_favorite.bind(id))
		_favorites.add_child(button)
	_body.get_node("FavoritesTitle").text = (
		"Mis favoritos · %d/%d%s"
		% [
			GameManager.session.laboratory_favorites.size(),
			profile.favorite_limit,
			(
				" · Guarda una idea para volver a probarla."
				if _favorites.get_child_count() == 0
				else ""
			)
		]
	)
	$ScreenLayout.register_controls($Shade/Panel/Content)
	_refresh_focus_chain()


func try_favorite(id: String) -> void:
	if not visible or id not in _ids:
		return
	for index: int in range(nouns.item_count):
		if nouns.get_item_metadata(index) == id.get_slice("|", 0):
			nouns.select(index)
			_select_noun(index)
			break
	for index: int in range(qualities.item_count):
		if qualities.get_item_metadata(index) == id:
			qualities.select(index)
			break
	create_spell()


func compare_result() -> void:
	if not _comparison_id.is_empty():
		_comparison_id = ""
	elif not _result_id.is_empty():
		_comparison_id = _result_id
	_refresh_result_actions()
	$Shade/Panel/Content/Browse.call_deferred("ensure_control_visible", _body.get_node("Stage"))


func _refresh_result_actions() -> void:
	var ready: bool = not _result_id.is_empty() and not _casting
	_favorite.disabled = not ready
	_favorite.text = (
		"Quitar favorito"
		if _result_id in GameManager.session.laboratory_favorites
		else "Guardar favorito"
	)
	if (
		ready
		and _result_id not in GameManager.session.laboratory_favorites
		and GameManager.session.laboratory_favorites.size() >= profile.favorite_limit
	):
		_favorite.disabled = true
		_favorite.text = "Favoritos llenos"
	_compare.disabled = not ready and _comparison_id.is_empty()
	_compare.text = "Dejar de comparar" if not _comparison_id.is_empty() else "Comparar con esta"
	var reference: MeaningIllustration = _body.get_node("Stage/Reference")
	var caption: Label = _body.get_node("Stage/ReferenceCaption")
	reference.visible = not _comparison_id.is_empty()
	caption.visible = reference.visible
	result.position.x = 650.0 if reference.visible else 450.0
	if reference.visible:
		reference.show_meaning(_comparison_id.get_slice("|", 0), _comparison_id.get_slice("|", 1))
		caption.text = "Referencia: " + str(CombinationCatalog.targets()[_comparison_id])
	_purchase.visible = not _purchase_id.is_empty()
	_place.disabled = not ready
	_place.text = "Colocar en mi jardín"
	_availability.text = "El ensayo es gratuito. Guardar favoritos no compra diseños."
	if ready:
		_refresh_availability()
	_refresh_focus_chain()


func _refresh_availability() -> void:
	var session: GameSession = GameManager.session
	var missing: Array[String] = MagicEconomy.missing_designs(session.economy, _result_id)
	var details: PackedStringArray = PackedStringArray()
	var allowed: bool = session.magic_points >= missing.size() * MagicEconomy.DESIGN_PRICE
	for word: String in missing:
		details.append(
			"%s (%d puntos)" % [VocabularyCatalog.entry(word).spanish, MagicEconomy.DESIGN_PRICE]
		)
		allowed = (
			allowed
			and MagicEconomy.can_purchase(
				session.economy, word, session.words_learned, session.magic_points
			)
		)
	_availability.text = (
		"Ya tienes estos diseños. Colocar copias es gratis; Esc cancela la vista previa."
		if missing.is_empty()
		else (
			"Faltan diseños: %s. Total: %d puntos. Saldo: %d. El ensayo sigue gratis."
			% [", ".join(details), missing.size() * MagicEconomy.DESIGN_PRICE, session.magic_points]
		)
	)
	_place.text = "Colocar en mi jardín" if missing.is_empty() else "Revisar compra…"
	_confirm.text = "Confirmar compra · %d puntos" % (missing.size() * MagicEconomy.DESIGN_PRICE)
	_confirm.disabled = not allowed or missing.is_empty()
	if not session.economy.built and _result_id != "mayak|chich":
		_place.disabled = true
		_availability.text += "\nConstruye primero el rincón de Mesa y Fuerte."
	elif not missing.is_empty() and not allowed:
		_availability.text += (
			"\nPrepara el rincón con Áak y Miis."
			if MagicEconomy.FIRST_PROJECT not in session.economy.preparations
			else "\nNecesitas saldo suficiente para confirmar todos los diseños faltantes."
		)
	if session.garden.objects.size() >= GardenLayout.MAX_OBJECTS:
		_place.disabled = true
		_availability.text += "\nJardín y almacén llenos: reutiliza un mueble desde Mi jardín."


func request_placement() -> void:
	if not visible or _result_id.is_empty() or _place.disabled:
		return
	if not MagicEconomy.missing_designs(GameManager.session.economy, _result_id).is_empty():
		_purchase_id = _result_id
		_refresh_result_actions()
		if not _confirm.disabled:
			_confirm.grab_focus()
		else:
			_purchase.get_node("Back").grab_focus()
		$Shade/Panel/Content/Browse.call_deferred("ensure_control_visible", _purchase)
		return
	var id: String = _result_id
	close_lab()
	placement_requested.emit(id)


func confirm_purchase() -> void:
	if not visible or _purchase_id.is_empty() or _purchase_id != _result_id:
		return
	if GameManager.purchase_combination_designs(_purchase_id):
		_purchase_id = ""
		_refresh_result_actions()
		_place.grab_focus()
	else:
		_refresh_result_actions()
		_availability.text += "\nCompra sin confirmar. Conservamos tus puntos y diseños; puedes reintentar."


func cancel_purchase() -> void:
	_purchase_id = ""
	_refresh_result_actions()
	_place.grab_focus()


func _refresh_focus_chain() -> void:
	var buttons: Array[Button] = []
	for control: Node in $Shade/Panel/Content.find_children("*", "Button", true, false):
		if control is Button and control.is_visible_in_tree() and not control.disabled:
			buttons.append(control)
	for index: int in range(buttons.size()):
		buttons[index].focus_next = buttons[index].get_path_to(
			buttons[(index + 1) % buttons.size()]
		)
		buttons[index].focus_previous = buttons[index].get_path_to(
			buttons[posmod(index - 1, buttons.size())]
		)


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _purchase_id.is_empty():
			close_lab()
		else:
			cancel_purchase()
		get_viewport().set_input_as_handled()


func close_lab() -> void:
	if not visible:
		return
	_cancel_magic()
	_purchase_id = ""
	hide()
	get_tree().paused = _was_paused
	var origin: Control = _previous_focus.get_ref() as Control if _previous_focus != null else null
	if is_instance_valid(origin) and origin.is_visible_in_tree():
		origin.grab_focus()
	_previous_focus = null


func _exit_tree() -> void:
	_cancel_magic()
	if visible:
		get_tree().paused = _was_paused


func _cancel_magic() -> void:
	if _magic and _magic.is_valid():
		_magic.kill()
	_magic = null
	_casting = false
	if is_node_ready():
		$Shade/Panel/Content/Browse/Body/Stage/Kalin.rotation = 0.0
		$Shade/Panel/Content/Browse/Body/Stage/Seal.modulate.a = 1.0
		$Shade/Panel/Content/Browse/Body/Stage/Trace.clear_points()
		$Shade/Panel/Content/Browse/Body/Stage/Trace.modulate.a = 1.0
		create_button.disabled = qualities.item_count == 0
