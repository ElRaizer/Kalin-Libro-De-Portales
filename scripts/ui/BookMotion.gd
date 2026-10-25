## Presentación del libro. Los tweens siguen activos mientras el mundo está pausado.
extends Node

signal opened
signal closed

@onready var book: Control = $"../BG/Book"
@onready var shade: ColorRect = $"../BG"
@onready var cover: Control = $"../FlyingCover"
var busy := false
var closing := false
var _tween: Tween
var _shade_alpha := 0.88

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shade_alpha = shade.color.a
	book.pivot_offset = book.size * 0.5
	cover.pivot_offset = cover.size * 0.5
	cover.hide()

func open_from(origin: Rect2) -> void:
	_stop()
	if get_node("/root/AccessibilityManager").reduced_motion:
		book.scale = Vector2.ONE
		book.modulate.a = 1.0
		shade.color.a = _shade_alpha
		cover.hide()
		busy = true
		closing = false
		_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_callback(_finish_soft_open)
		return
	busy = true
	closing = false
	var center := book.position + book.size * 0.5
	cover.position = origin.get_center() - cover.pivot_offset
	var small := _button_scale(origin)
	cover.scale = Vector2.ONE * small
	cover.rotation = -0.12
	cover.modulate.a = 1.0
	cover.show()
	book.modulate.a = 0.0
	book.scale = Vector2(0.54, 0.94)
	shade.color.a = 0.0
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(cover, "position", center - cover.pivot_offset, 0.26)
	_tween.tween_property(cover, "scale", Vector2.ONE, 0.26)
	_tween.tween_property(cover, "rotation", 0.0, 0.26)
	_tween.tween_property(shade, "color:a", _shade_alpha, 0.26)
	_tween.chain().tween_property(cover, "scale:x", 0.04, 0.23)
	_tween.parallel().tween_property(cover, "modulate:a", 0.0, 0.18).set_delay(0.05)
	_tween.parallel().tween_property(book, "scale", Vector2.ONE, 0.23)
	_tween.parallel().tween_property(book, "modulate:a", 1.0, 0.20)
	_tween.chain().tween_callback(func():
		cover.hide()
		busy = false
		opened.emit()
	)

func close_to(destination: Rect2) -> void:
	_stop()
	if get_node("/root/AccessibilityManager").reduced_motion:
		cover.hide()
		shade.color.a = 0.0
		busy = true
		closing = true
		_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_callback(_finish_soft_close)
		return
	busy = true
	closing = true
	# Conservar los valores actuales permite cerrar incluso durante la apertura.
	cover.show()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(book, "scale", Vector2(0.54, 0.94), 0.18)
	_tween.tween_property(book, "modulate:a", 0.0, 0.16)
	_tween.tween_property(cover, "scale", Vector2.ONE, 0.18)
	_tween.tween_property(cover, "modulate:a", 1.0, 0.14)
	_tween.chain().tween_property(cover, "position", destination.get_center() - cover.pivot_offset, 0.26)
	_tween.parallel().tween_property(cover, "scale", Vector2.ONE * _button_scale(destination), 0.26)
	_tween.parallel().tween_property(cover, "rotation", -0.12, 0.26)
	_tween.parallel().tween_property(shade, "color:a", 0.0, 0.26)
	_tween.chain().tween_callback(func():
		cover.hide()
		busy = false
		closing = false
		closed.emit()
	)

func _button_scale(rect: Rect2) -> float:
	return clampf(minf(rect.size.x / cover.size.x, rect.size.y / cover.size.y), 0.04, 0.25)

func _finish_soft_open() -> void:
	busy = false
	opened.emit()

func _finish_soft_close() -> void:
	busy = false
	closing = false
	closed.emit()

func _stop() -> void:
	if _tween:
		_tween.kill()
