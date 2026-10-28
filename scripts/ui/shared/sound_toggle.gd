extends Button
class_name SoundToggle

## Botón para silenciar o activar todo el sonido del juego.

@export var on_text: String = "Sonido: sí"
@export var off_text: String = "Sonido: no"


func _ready() -> void:
	toggle_mode = true
	_refresh()
	toggled.connect(_on_toggled)
	AudioManager.volume_changed.connect(_refresh)


func _refresh() -> void:
	set_pressed_no_signal(not AudioManager.muted)
	text = on_text if not AudioManager.muted else off_text
	tooltip_text = "Silenciar el juego" if not AudioManager.muted else "Activar el sonido"


func _on_toggled(sound_on: bool) -> void:
	AudioManager.set_muted(not sound_on)
