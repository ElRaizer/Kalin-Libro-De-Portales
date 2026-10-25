extends PanelContainer
class_name RecallPanel

signal submitted
signal practice_requested
signal support_used
signal answer_changed
@export var external_submit := false
@export var preferred_size := Vector2.ZERO
@export var fragment_scene: PackedScene = preload("res://scenes/components/RecallFragment.tscn")
enum Mode { WRITE, CLOZE, BLOCKS }
var mode: int = Mode.WRITE
var expected: Array[String] = []
var _fragments: Array[String] = []
var _used: Array[int] = []
var _history: Array[Dictionary] = []
var _setting_up := false
var _slots: Array[Array] = []
var _slot_rows: Array[HFlowContainer] = []
var _selected := Vector2i(-1, -1)
var _block_width := 92.0
var _showing_result := false
var _empty_style: StyleBoxFlat
var _workspace_kind := ""

@onready var first: LineEdit = $Margin/Content/Fields/First/Input
@onready var second: LineEdit = $Margin/Content/Fields/Second/Input
@onready var second_box: VBoxContainer = $Margin/Content/Fields/Second
@onready var caption: Label = $Margin/Content/Hint
var _active: LineEdit

## Mantiene el modo actual y envía los campos por la validación habitual.
func debug_fill(answers: Array) -> void:
	if not OS.is_debug_build():
		return
	first.text = str(answers[0]) if not answers.is_empty() else ""
	second.text = str(answers[1]) if answers.size() > 1 else ""
	if mode == Mode.BLOCKS:
		_fill_solution(answers)
	answer_changed.emit()

func _ready() -> void:
	$Margin/Content/Workspace.panel = self
	answer_changed.connect(_refresh_workspace)
	_empty_style = StyleBoxFlat.new()
	_empty_style.bg_color = Color("ede1bd")
	_empty_style.border_color = Color("7b6b48")
	_empty_style.set_border_width_all(2)
	_empty_style.set_corner_radius_all(8)
	first.text_submitted.connect(func(_text: String):
		if second_box.visible:
			second.grab_focus()
		else:
			submitted.emit()
	)
	second.text_submitted.connect(func(_text: String): submitted.emit())
	first.focus_entered.connect(func(): _active = first)
	second.focus_entered.connect(func(): _active = second)
	first.text_changed.connect(func(_value: String):
		_refresh_workspace()
		if not _setting_up:
			answer_changed.emit()
	)
	second.text_changed.connect(func(_value: String):
		_refresh_workspace()
		if not _setting_up:
			answer_changed.emit()
	)
	$Margin/Content/Modes.hide()
	for field: LineEdit in [first, second]:
		var row := HFlowContainer.new()
		row.name = "BlockSlots"
		row.add_theme_constant_override("h_separation", 8)
		row.add_theme_constant_override("v_separation", 8)
		field.get_parent().add_child(row)
		_slot_rows.append(row)
	$Margin/Content/Blocks/Bank.panel = self
	$Margin/Content/Blocks/Undo.pressed.connect(_undo_fragment)
	$Margin/Content/Actions/Practice.pressed.connect(practice_requested.emit)
	$Margin/Content/Actions/Submit.visible = not external_submit
	$Margin/Content/Actions/Submit.pressed.connect(submitted.emit)
	for button: Button in $Margin/Content/Letters.get_children():
		button.pressed.connect(_insert_letter.bind(button.text))
	call_deferred("_settle_size")

func _settle_size() -> void:
	# Los contenedores ocultos pueden calcular primero el texto con ancho cero.
	# Esperar a la distribución real evita conservar esa altura provisional.
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if is_zero_approx(anchor_right - anchor_left) and preferred_size != Vector2.ZERO:
		size = get_meta("layout_size", preferred_size)
	elif not is_zero_approx(anchor_right - anchor_left):
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		offset_left = 8
		offset_top = 8
		offset_right = -8
		offset_bottom = -8

func configure(labels: Array, answers: Array = [], initial_mode: int = Mode.WRITE) -> void:
	_setting_up = true
	_showing_result = false
	$Margin/Content/Result.hide()
	for child: Control in $Margin/Content.get_children():
		if child.name not in [&"Modes", &"Result"]:
			child.show()
	expected.assign(answers)
	$Margin/Content/Fields/First/Name.text = labels[0]
	second_box.visible = labels.size() > 1
	if second_box.visible:
		$Margin/Content/Fields/Second/Name.text = labels[1]
	first.clear()
	second.clear()
	_active = first
	set_mode(initial_mode, false)
	_setting_up = false
	show()
	call_deferred("_focus_first")
	call_deferred("_settle_size")
	call_deferred("_refresh_workspace")

func apply_compact(enabled: bool) -> void:
	caption.visible = not enabled
	for button: Button in $Margin/Content/Modes.get_children():
		button.custom_minimum_size.y = 56 if enabled else 44
		button.add_theme_font_size_override("font_size", 26 if enabled else 20)
	$Margin/Content/Actions/Practice.custom_minimum_size.y = 56 if enabled else 40
	$Margin/Content/Actions/Submit.custom_minimum_size.y = 56 if enabled else 40
	$Margin/Content/Workspace.custom_minimum_size.y = 158 if enabled else 188

func set_workspace(kind: String) -> void:
	_workspace_kind = kind
	$Margin/Content/Workspace.kind = kind
	_refresh_workspace()

func _refresh_workspace() -> void:
	if not is_inside_tree():
		return
	var workspace := $Margin/Content/Workspace as Control
	workspace.visible = not _workspace_kind.is_empty() and mode != Mode.BLOCKS and not _showing_result
	workspace.refresh()

func set_mode(value: int, announce := true) -> void:
	mode = clampi(value, Mode.WRITE, Mode.BLOCKS)
	first.clear()
	second.clear()
	first.editable = mode != Mode.BLOCKS
	second.editable = mode != Mode.BLOCKS
	first.virtual_keyboard_enabled = mode != Mode.BLOCKS
	second.virtual_keyboard_enabled = mode != Mode.BLOCKS
	$Margin/Content/Modes.hide()
	$Margin/Content/Actions/Practice.hide()
	$Margin/Content/Blocks.visible = mode == Mode.BLOCKS
	first.visible = mode != Mode.BLOCKS
	second.visible = mode != Mode.BLOCKS
	for row: HFlowContainer in _slot_rows:
		row.visible = mode == Mode.BLOCKS
	for index: int in range(3):
		($Margin/Content/Modes.get_child(index) as Button).set_pressed_no_signal(mode == index)
	caption.text = ["Escribe la palabra en maya. Puedes pedir apoyo.", "Completa las palabras que empezamos.", "Toca los bloques o arrástralos a los huecos."][mode]
	_used.clear()
	_history.clear()
	if mode == Mode.CLOZE:
		for index: int in range(mini(expected.size(), 2)):
			var field := first if index == 0 else second
			field.text = expected[index].substr(0, maxi(1, expected[index].length() / 3)) if not expected[index].is_empty() else ""
			field.caret_column = field.text.length()
	if mode == Mode.BLOCKS:
		_build_fragments()
	if announce:
		if mode != Mode.WRITE:
			support_used.emit()
		answer_changed.emit()
	_active = first
	_refresh_workspace()
	call_deferred("_focus_first")
	call_deferred("_settle_size")

func advance_support() -> void:
	var previous := values()
	if mode < Mode.BLOCKS:
		set_mode(mode + 1)
		# Una parte ya correcta permanece resuelta al recibir apoyo en la otra.
		for index: int in range(expected.size()):
			if match_word(previous[index], expected[index]).correct:
				if mode == Mode.BLOCKS:
					_fill_field(index, expected[index])
				else:
					(first if index == 0 else second).text = expected[index]
		if mode == Mode.BLOCKS:
			_sync_blocks()
	caption.text = ["Escribe la palabra en maya.", "Probemos con una pista. Completa lo que falta.", "Ahora usa las piezas. Puedes cambiarlas de lugar o devolverlas al banco."][mode]
	answer_changed.emit()

func ready_to_submit() -> bool:
	if mode == Mode.BLOCKS:
		for row: Array in _slots:
			if -1 in row:
				caption.text = "Faltan piezas: llena las casillas antes de confirmar."
				return false
	elif first.text.strip_edges().is_empty() or second_box.visible and second.text.strip_edges().is_empty():
		caption.text = "Escribe tu respuesta antes de confirmar."
		return false
	return true

func explain_support() -> void:
	caption.text = "Escribe lo que recuerdes. Si hace falta, aparecerá una pista." if mode == Mode.WRITE else ("Completa las palabras que empezamos." if mode == Mode.CLOZE else "Toca una pieza y una casilla. Puedes intercambiar piezas o devolverlas al banco.")
	caption.show()

static func split_word(word: String) -> PackedStringArray:
	if word.contains(" ") or word.contains("·"):
		return word.replace(" · ", " ").split(" ", false)
	var pieces := PackedStringArray()
	var step := maxi(2, ceili(float(word.length()) / 3.0))
	for start: int in range(0, word.length(), step):
		pieces.append(word.substr(start, step))
	return pieces

func _build_fragments() -> void:
	var bank := $Margin/Content/Blocks/Bank as HFlowContainer
	for child: Node in bank.get_children():
		bank.remove_child(child)
		child.queue_free()
	_fragments.clear()
	_slots.clear()
	_selected = Vector2i(-1, -1)
	for word: String in expected:
		var pieces := split_word(word)
		_fragments.append_array(pieces)
		var slots: Array = []
		slots.resize(pieces.size())
		slots.fill(-1)
		_slots.append(slots)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("|".join(expected))
	for index: int in range(_fragments.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := _fragments[index]
		_fragments[index] = _fragments[other]
		_fragments[other] = swap
	_block_width = 76
	for fragment: String in _fragments:
		_block_width = maxf(_block_width, first.get_theme_font("font").get_string_size(fragment, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 24)
	for field_index: int in range(_slot_rows.size()):
		var row := _slot_rows[field_index]
		for child: Node in row.get_children():
			row.remove_child(child)
			child.queue_free()
		if field_index >= _slots.size():
			continue
		for slot_index: int in range(_slots[field_index].size()):
			var slot := fragment_scene.instantiate() as Button
			slot.set("panel", self)
			slot.set("field_index", field_index)
			slot.set("slot_index", slot_index)
			slot.custom_minimum_size = Vector2(_block_width, 56)
			slot.pressed.connect(_slot_pressed.bind(field_index, slot_index))
			row.add_child(slot)
	for index: int in range(_fragments.size()):
		var button := fragment_scene.instantiate() as Button
		button.text = _fragments[index]
		button.set("panel", self)
		button.set("fragment_index", index)
		button.custom_minimum_size = Vector2(_block_width, 56)
		button.pressed.connect(_bank_pressed.bind(index))
		bank.add_child(button)
	_sync_blocks()

func place_fragment(index: int, target: LineEdit = null) -> void:
	if mode != Mode.BLOCKS or index < 0 or index >= _fragments.size() or index in _used:
		return
	var field: LineEdit = target if target != null else _active
	if field != first and field != second or field == second and not second_box.visible:
		return
	var field_index := 0 if field == first else 1
	if _selected.x >= 0:
		move_fragment(index, _selected.x, _selected.y)
		return
	var slot_index := _slots[field_index].find(-1)
	if slot_index >= 0:
		move_fragment(index, field_index, slot_index)
	if -1 not in _slots[field_index] and second_box.visible:
		_active = second

func accepts_fragment(data: Variant) -> bool:
	return mode == Mode.BLOCKS and not _showing_result and data is Dictionary and data.get("kind") == "recall_fragment" and data.get("panel") == self and data.get("index") is int and data.index >= 0 and data.index < _fragments.size()

func move_fragment(index: int, field_index: int, slot_index: int) -> void:
	if mode != Mode.BLOCKS or _showing_result or index < 0 or index >= _fragments.size() or field_index < 0 or field_index >= _slots.size() or slot_index < 0 or slot_index >= _slots[field_index].size():
		return
	var source := _find_piece(index)
	if source == Vector2i(field_index, slot_index):
		return
	_history.append({"slots": _slots.duplicate(true)})
	var replaced: int = _slots[field_index][slot_index]
	if source.x >= 0:
		_slots[source.x][source.y] = replaced
	_slots[field_index][slot_index] = index
	_selected = Vector2i(-1, -1)
	_sync_blocks()
	answer_changed.emit()

func _find_piece(index: int) -> Vector2i:
	for field_index: int in range(_slots.size()):
		var slot_index := _slots[field_index].find(index)
		if slot_index >= 0:
			return Vector2i(field_index, slot_index)
	return Vector2i(-1, -1)

func return_fragment(index: int) -> void:
	var source := _find_piece(index)
	if mode != Mode.BLOCKS or source.x < 0 or _showing_result:
		return
	_history.append({"slots": _slots.duplicate(true)})
	_slots[source.x][source.y] = -1
	_selected = Vector2i(-1, -1)
	_sync_blocks()
	answer_changed.emit()

func _bank_pressed(index: int) -> void:
	if index in _used:
		return_fragment(index)
	else:
		place_fragment(index)

func _slot_pressed(field_index: int, slot_index: int) -> void:
	var target := Vector2i(field_index, slot_index)
	if _selected.x >= 0 and _selected != target and _slots[_selected.x][_selected.y] >= 0:
		move_fragment(_slots[_selected.x][_selected.y], field_index, slot_index)
		return
	_selected = Vector2i(-1, -1) if _selected == target else target
	_active = first if field_index == 0 else second
	_sync_blocks()

func _sync_blocks() -> void:
	_used.clear()
	for field_index: int in range(_slots.size()):
		var texts: Array[String] = []
		for slot_index: int in range(_slots[field_index].size()):
			var index: int = _slots[field_index][slot_index]
			var slot := _slot_rows[field_index].get_child(slot_index) as Button
			slot.set("fragment_index", index)
			slot.text = _fragments[index] if index >= 0 else "·"
			slot.theme_type_variation = &"KalinNounButton" if index >= 0 else &"KalinSecondaryButton"
			for state: String in ["normal", "hover", "pressed"]:
				if index < 0:
					slot.add_theme_stylebox_override(state, _empty_style)
				else:
					slot.remove_theme_stylebox_override(state)
			slot.add_theme_color_override("font_color", Color("746449") if index < 0 else Color.WHITE)
			slot.modulate = Color("ffdc75") if _selected == Vector2i(field_index, slot_index) else Color.WHITE
			slot.tooltip_text = "Mover o intercambiar esta pieza" if index >= 0 else "Coloca una pieza aquí"
			if index >= 0:
				_used.append(index)
				texts.append(_fragments[index])
		var separator := " " if expected[field_index].contains(" ") or expected[field_index].contains("·") else ""
		(first if field_index == 0 else second).text = separator.join(texts)
	for index: int in range(_fragments.size()):
		var button := $Margin/Content/Blocks/Bank.get_child(index) as Button
		button.show()
		button.modulate.a = 0.3 if index in _used else 1.0
		button.tooltip_text = "Toca aquí o arrastra la pieza para devolverla" if index in _used else "Colocar esta pieza"

func _fill_field(field_index: int, word: String) -> void:
	var parts := split_word(word)
	for slot_index: int in range(mini(parts.size(), _slots[field_index].size())):
		for index: int in range(_fragments.size()):
			if _find_piece(index).x < 0 and _fragments[index] == parts[slot_index]:
				_slots[field_index][slot_index] = index
				break

func _fill_solution(answers: Array) -> void:
	for row: Array in _slots:
		row.fill(-1)
	for field_index: int in range(mini(answers.size(), _slots.size())):
		_fill_field(field_index, str(answers[field_index]))
	_sync_blocks()

func _undo_fragment() -> void:
	if _history.is_empty():
		return
	var entry: Dictionary = _history.pop_back()
	if entry.get("slots") is Array:
		_restore_slots(entry.slots)
	_selected = Vector2i(-1, -1)
	_sync_blocks()
	answer_changed.emit()

func scaffold_state() -> Dictionary:
	return {"mode": mode, "slots": _slots.duplicate(true), "history": _history.slice(-20).duplicate(true)}

func restore_scaffold(saved: Dictionary) -> void:
	if mode != Mode.BLOCKS:
		return
	if saved.get("slots") is Array:
		_restore_slots(saved.slots)
	elif saved.get("history") is Array:
		# Migrar el antiguo banco de texto conservando sus piezas en orden.
		for entry: Variant in saved.history:
			if entry is Dictionary and entry.get("field") in [0, 1] and (entry.get("index") is float or entry.get("index") is int):
				var field_index := int(entry.field)
				var index := int(entry.index)
				if field_index < _slots.size() and index >= 0 and index < _fragments.size() and _find_piece(index).x < 0:
					var empty := _slots[field_index].find(-1)
					if empty >= 0:
						_slots[field_index][empty] = index
	_history.clear()
	if saved.get("history") is Array:
		for entry: Variant in saved.history:
			if entry is Dictionary and entry.get("slots") is Array and _history.size() < 20:
				_history.append({"slots": entry.slots})
	_sync_blocks()

func _restore_slots(saved: Array) -> void:
	var used: Array[int] = []
	for field_index: int in range(_slots.size()):
		_slots[field_index].fill(-1)
		if field_index >= saved.size() or saved[field_index] is not Array:
			continue
		for slot_index: int in range(mini(saved[field_index].size(), _slots[field_index].size())):
			var value: Variant = saved[field_index][slot_index]
			if (value is int or value is float) and value == int(value) and int(value) >= 0 and int(value) < _fragments.size() and int(value) not in used:
				_slots[field_index][slot_index] = int(value)
				used.append(int(value))

func show_result(word: String, quality: String, phrase: String, translation: String) -> void:
	_showing_result = true
	for child: Control in $Margin/Content.get_children():
		child.hide()
	var result := $Margin/Content/Result as HBoxContainer
	result.show()
	(result.get_node("Art") as MeaningIllustration).show_meaning(word, quality)
	result.get_node("Words/Title").text = "¡Lo lograste!"
	result.get_node("Words/Phrase").text = phrase
	result.get_node("Words/Translation").text = translation
	show()
	call_deferred("_settle_size")

func _focus_first() -> void:
	if not is_inside_tree() or _showing_result:
		return
	if mode == Mode.BLOCKS and not _slot_rows.is_empty() and _slot_rows[0].get_child_count() > 0:
		(_slot_rows[0].get_child(0) as Button).grab_focus()
	elif is_inside_tree() and first.is_visible_in_tree():
		first.grab_focus()

func values() -> Array[String]:
	return [first.text.strip_edges(), second.text.strip_edges()]

func _insert_letter(letter: String) -> void:
	if not is_instance_valid(_active):
		_active = first
	_active.insert_text_at_caret(letter)
	_active.grab_focus()

## La grafía sin acentos permite continuar, con la corrección visible y marcada
## como práctica apoyada. Nunca cuenta como recuerdo independiente.
static func match_word(typed: String, expected: String) -> Dictionary:
	var actual := " ".join(typed.strip_edges().replace("’", "'").replace("·", " ").to_lower().split(" ", false))
	var wanted := " ".join(expected.replace("·", " ").to_lower().split(" ", false))
	if actual == wanted:
		return {"correct": true, "supported": false, "word": expected}
	var normalized := actual
	var normalized_expected := wanted
	for pair: Array in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"]]:
		normalized = normalized.replace(pair[0], pair[1])
		normalized_expected = normalized_expected.replace(pair[0], pair[1])
	return {"correct": normalized == normalized_expected, "supported": normalized == normalized_expected, "word": expected if normalized == normalized_expected else typed}
