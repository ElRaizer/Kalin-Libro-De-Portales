extends CanvasLayer
class_name SpellLaboratory

signal opened

## Práctica opcional: sólo combinaciones canónicas cuyas palabras ya se conocen.
var _ids: Array[String] = []
var _previous_focus: WeakRef
var _was_paused: bool = false
var _visit_seed: int = 1
var _magic: Tween
var _casting: bool = false
@onready var nouns: WordChipSelector = $Shade/Panel/Content/NounScroll/Noun
@onready var qualities: WordChipSelector = $Shade/Panel/Content/QualityScroll/Quality
@onready var result: MeaningIllustration = $Shade/Panel/Content/Stage/Result
@onready var description: Label = $Shade/Panel/Content/Description
@onready var create_button: Button = $Shade/Panel/Content/Actions/Create


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	nouns.item_selected.connect(_select_noun)
	qualities.item_selected.connect(_clear_result)
	create_button.pressed.connect(create_spell)
	$Shade/Panel/Content/Actions/Close.pressed.connect(close_lab)
	var controls: Array[Control] = [
		nouns, qualities, create_button, $Shade/Panel/Content/Actions/Close
	]
	for index: int in range(controls.size()):
		controls[index].focus_next = controls[index].get_path_to(
			controls[(index + 1) % controls.size()]
		)
		controls[index].focus_previous = controls[index].get_path_to(
			controls[posmod(index - 1, controls.size())]
		)


func open_lab(origin: Control) -> void:
	if visible or get_tree().paused:
		return
	_ids.clear()
	nouns.clear()
	var known: Dictionary = GameManager.learned_words()
	var used: Array[String] = []
	for id: String in CombinationCatalog.targets():
		var parts: PackedStringArray = id.split("|")
		if parts[0] not in known or (not parts[1].is_empty() and parts[1] not in known):
			continue
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
	result.hide()
	$Shade/Panel/Content/Stage/Seal.show()
	description.text = "Elige palabras conocidas y observa lo que crean."
	if _ids.is_empty():
		description.text = "Primero descubre un objeto durante la aventura."


func create_spell() -> void:
	if not visible or _casting or qualities.item_count == 0 or qualities.selected < 0:
		return
	var id: String = str(qualities.get_item_metadata(qualities.selected))
	if id not in _ids:
		return
	_casting = true
	create_button.disabled = true
	if not AccessibilityManager.reduced_motion:
		_magic = create_tween()
		_magic.tween_property($Shade/Panel/Content/Stage/Kalin, "rotation", -0.08, 0.2)
		_magic.parallel().tween_method(_trace_magic, 0.0, 1.0, 0.2)
		_magic.tween_callback(_reveal_base.bind(id))
		_magic.tween_property($Shade/Panel/Content/Stage/Trace, "modulate:a", 0.0, 0.25)
		_magic.tween_callback(_finish_magic.bind(id))
	else:
		_finish_magic(id)


func _trace_magic(progress: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in range(maxi(2, int(progress * 32) + 1)):
		var angle: float = TAU * float(step) / 32.0
		points.append(Vector2(cos(angle) * 100, sin(angle) * 45))
	$Shade/Panel/Content/Stage/Trace.points = points
	$Shade/Panel/Content/Stage/Seal.modulate.a = 1.0 - progress


func _reveal_base(id: String) -> void:
	result.show_meaning(id.get_slice("|", 0), "")
	result.show()
	$Shade/Panel/Content/Stage/Seal.hide()


func _finish_magic(id: String) -> void:
	if not is_inside_tree() or not visible or not _casting:
		return
	var entry: ExerciseEntry = ExerciseEntry.new()
	CombinationCatalog.apply_entry(entry, id)
	result.show_meaning(entry.noun, entry.adjective)
	$Shade/Panel/Content/Stage/Seal.hide()
	$Shade/Panel/Content/Stage/Kalin.rotation = 0.0
	result.show()
	result.celebrate()
	_casting = false
	create_button.disabled = false
	description.text = entry.phrase + "\n" + entry.translation
	var words: Array[String] = [entry.noun]
	if not entry.adjective.is_empty():
		words.append(entry.adjective)
	GameManager.record_learning(words, "experiment", "laboratory:%s@%d" % [id, _visit_seed], true)


func close_lab() -> void:
	if not visible:
		return
	_cancel_magic()
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
		$Shade/Panel/Content/Stage/Kalin.rotation = 0.0
		$Shade/Panel/Content/Stage/Seal.modulate.a = 1.0
		$Shade/Panel/Content/Stage/Trace.clear_points()
		$Shade/Panel/Content/Stage/Trace.modulate.a = 1.0
		create_button.disabled = qualities.item_count == 0
