extends CanvasLayer

## Herramienta de QA. No crea interfaz ni procesa entradas en builds release.
var toolbar: PanelContainer
var answer_button: Button
var _dragging := false
var _drag_offset := Vector2.ZERO
var _placed := false

func _ready() -> void:
	set_process(false)
	set_process_input(false)
	if not OS.is_debug_build() or Engine.is_editor_hint():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	toolbar = PanelContainer.new()
	toolbar.name = "DebugAnswerToolbar"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202d3d")
	style.set_corner_radius_all(8)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	toolbar.add_theme_stylebox_override("panel", style)
	add_child(toolbar)
	var row := HBoxContainer.new()
	toolbar.add_child(row)
	var grip := Label.new()
	grip.text = "⠿"
	grip.custom_minimum_size = Vector2(28, 40)
	grip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grip.mouse_filter = Control.MOUSE_FILTER_STOP
	grip.mouse_default_cursor_shape = Control.CURSOR_MOVE
	grip.tooltip_text = "Arrastra para mover la ayuda de depuración."
	grip.gui_input.connect(_grip_input)
	row.add_child(grip)
	answer_button = Button.new()
	answer_button.text = "DEBUG · Responder (F4)"
	answer_button.custom_minimum_size = Vector2(238, 40)
	answer_button.add_theme_font_size_override("font_size", 18)
	answer_button.focus_mode = Control.FOCUS_NONE
	answer_button.tooltip_text = "Responde correctamente esta actividad. Solo depuración; cuenta como ayuda."
	answer_button.pressed.connect(answer_current)
	row.add_child(answer_button)
	toolbar.hide()
	set_process(true)
	set_process_input(true)

func _process(_delta: float) -> void:
	toolbar.visible = can_answer()
	if toolbar.visible and not _placed:
		toolbar.position = Vector2(get_viewport().get_visible_rect().size.x - toolbar.size.x - 16, 76)
		_placed = true
	_clamp_position()

func can_answer() -> bool:
	if not OS.is_debug_build() or get_tree().paused:
		return false
	var scene := get_tree().current_scene
	if scene == null or scene.is_queued_for_deletion() or not scene.has_method("debug_can_answer"):
		return false
	return scene.debug_can_answer()

func answer_current() -> void:
	# El clic y el atajo consultan de nuevo la escena: nunca usar una referencia
	# guardada entre rondas ni contestar detrás del libro o de la pausa.
	if can_answer():
		get_tree().current_scene.debug_answer()
		toolbar.hide()

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		if not event.alt_pressed and not event.ctrl_pressed and not event.meta_pressed and can_answer():
			get_viewport().set_input_as_handled()
			answer_current()
	elif _dragging and event is InputEventMouseMotion:
		toolbar.position = toolbar.get_global_mouse_position() - _drag_offset
		_clamp_position()
	elif event is InputEventMouseButton and not event.pressed:
		_dragging = false

func _grip_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_drag_offset = toolbar.get_global_mouse_position() - toolbar.position
		toolbar.accept_event()

func _clamp_position() -> void:
	var limit := get_viewport().get_visible_rect().size - toolbar.size - Vector2(8, 8)
	toolbar.position = toolbar.position.clamp(Vector2(8, 8), limit.max(Vector2(8, 8)))
