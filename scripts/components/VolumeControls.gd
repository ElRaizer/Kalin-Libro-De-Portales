extends GridContainer
class_name VolumeControls

## Deslizadores de volumen para la música y los sonidos (efectos y ambientes).
## Los valores viven en AudioManager, que los recuerda entre partidas.

## Efecto que suena al mover el deslizador de sonidos, para oír el nivel elegido.
@export var preview_effect: String = "acierto"

@onready var music_slider: HSlider = $MusicSlider
@onready var effects_slider: HSlider = $EffectsSlider

func _ready() -> void:
	_refresh()
	music_slider.value_changed.connect(AudioManager.set_music_volume)
	effects_slider.value_changed.connect(AudioManager.set_effects_volume)
	effects_slider.drag_ended.connect(_on_effects_drag_ended)
	AudioManager.volume_changed.connect(_refresh)
	visibility_changed.connect(_refresh)

func _refresh() -> void:
	music_slider.set_value_no_signal(AudioManager.music_volume)
	effects_slider.set_value_no_signal(AudioManager.effects_volume)

func _on_effects_drag_ended(value_changed: bool) -> void:
	if value_changed:
		AudioManager.play_sfx(preview_effect)
