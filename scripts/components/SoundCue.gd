extends RefCounted
class_name SoundCue

## Atajo para que los componentes reutilizables pidan un efecto sin nombrar al
## autoload AudioManager. Las pruebas cargan algunos de esos componentes como
## tipos antes de que existan los autoloads; buscar el nodo por su ruta evita
## el error de compilación «Identifier not found».

const AUDIO_MANAGER_PATH := ^"/root/AudioManager"

static func play(from: Node, key: String, pitch_scale: float = 1.0) -> void:
	if from == null or not from.is_inside_tree():
		return
	var audio := from.get_node_or_null(AUDIO_MANAGER_PATH)
	if audio != null:
		audio.play_sfx(key, pitch_scale)
