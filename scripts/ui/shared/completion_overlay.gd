extends Control
class_name CompletionOverlay

signal next_pressed
signal replay_pressed
signal menu_pressed

@onready var panel: Panel = $Shade/Panel
@onready var title_label: Label = $Shade/Panel/Content/TitleLabel
@onready var summary_label: Label = $Shade/Panel/Content/SummaryLabel
@onready var score_label: Label = $Shade/Panel/Content/ScoreLabel
@onready var next_button: Button = $Shade/Panel/Content/NextButton
var _panel_scale: Vector2
var _panel_alpha: float
var _show_tween: Tween


func _ready() -> void:
	_panel_scale = panel.scale
	_panel_alpha = panel.modulate.a
	$Shade/Panel/Content/NextButton.pressed.connect(next_pressed.emit)
	$Shade/Panel/Content/ReplayButton.pressed.connect(replay_pressed.emit)
	$Shade/Panel/Content/MenuButton.pressed.connect(menu_pressed.emit)
	hide_overlay()


func show_completion(title: String, summary: String, next_text: String = "Continuar") -> void:
	# Cubrir también la casa y los controles añadidos al preparar cada nivel.
	get_parent().move_child(self, -1)
	title_label.text = title
	summary_label.text = summary
	var manager: Node = get_node("/root/GameManager")
	score_label.text = "%d páginas recuperadas" % manager.get_recovered_word_count()
	next_button.text = next_text
	visible = true
	panel.modulate.a = 0.0
	panel.scale = _panel_scale * 0.96
	panel.pivot_offset = panel.size * 0.5
	if _show_tween:
		_show_tween.kill()
	_show_tween = create_tween().set_parallel(true)
	_show_tween.tween_property(panel, "modulate:a", _panel_alpha, 0.25)
	_show_tween.tween_property(panel, "scale", _panel_scale, 0.25).set_trans(Tween.TRANS_BACK)
	next_button.grab_focus()


func hide_overlay() -> void:
	visible = false
