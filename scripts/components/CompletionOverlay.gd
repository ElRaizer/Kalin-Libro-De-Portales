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

func _ready() -> void:
	$Shade/Panel/Content/NextButton.pressed.connect(next_pressed.emit)
	$Shade/Panel/Content/ReplayButton.pressed.connect(replay_pressed.emit)
	$Shade/Panel/Content/MenuButton.pressed.connect(menu_pressed.emit)
	hide_overlay()

func show_completion(title: String, summary: String, next_text: String = "Continuar") -> void:
	title_label.text = title
	summary_label.text = summary
	score_label.text = "Puntuación acumulada: %d puntos mágicos" % GameManager.magic_points
	next_button.text = next_text
	visible = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	next_button.grab_focus()

func hide_overlay() -> void:
	visible = false

