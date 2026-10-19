extends RefCounted
class_name DialoguePresenter

var host: Node
var panel: Control
var speaker_label: Label
var text_label: RichTextLabel
var hint_label: Label
var speaker_resolver: Callable
var pose_callback: Callable
var finished_callback: Callable
var reveal_seconds: float
var lines: Array[String] = []
var line_index := -1
var opened := false
var text_tween: Tween

func _init(owner: Node, dialogue_panel: Control, speaker: Label, body: RichTextLabel, hint: Label, resolver: Callable, pose: Callable, finished: Callable, seconds_per_character: float = 0.022) -> void:
	host = owner
	panel = dialogue_panel
	speaker_label = speaker
	text_label = body
	hint_label = hint
	speaker_resolver = resolver
	pose_callback = pose
	finished_callback = finished
	reveal_seconds = seconds_per_character

func start(speaker: String, dialogue_lines: Array[String], surprised: bool = false) -> void:
	opened = true
	lines = dialogue_lines
	line_index = -1
	pose_callback.call(surprised)
	speaker_label.text = speaker_resolver.call(speaker)
	speaker_label.visible = speaker_label.text != ""
	hint_label.text = "▶ Continuar"
	panel.show()
	_next_line()

func advance() -> void:
	if not opened:
		return
	if text_tween != null and text_tween.is_running():
		text_tween.kill()
		text_label.visible_ratio = 1.0
		return
	_next_line()

func is_open() -> bool:
	return opened

func close() -> void:
	if not opened:
		return
	opened = false
	if text_tween and text_tween.is_valid():
		text_tween.kill()
	panel.hide()
	pose_callback.call(false)
	finished_callback.call()

func _next_line() -> void:
	line_index += 1
	if line_index >= lines.size():
		close()
		return
	var value: String = lines[line_index]
	if text_tween and text_tween.is_valid():
		text_tween.kill()
	text_label.text = value
	text_label.visible_ratio = 0.0
	text_tween = host.create_tween()
	text_tween.tween_property(text_label, "visible_ratio", 1.0, value.length() * reveal_seconds)
