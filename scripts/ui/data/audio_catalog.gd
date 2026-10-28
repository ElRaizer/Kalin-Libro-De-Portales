@tool
extends Resource
class_name AudioCatalog

## Qué suena en el juego. Todo se elige en el Inspector arrastrando archivos de
## res://Audio/: la música y el ambiente de cada escena (por su clave de
## GameContent.SCENE_PATHS) y los efectos por nombre. Un efecto puede ser un
## AudioStreamRandomizer para variar pasos, truenos o clics.

## Clave de escena → pieza en bucle. Si una escena no aparece, sigue la anterior.
@export var scene_music: Dictionary[String, AudioStream] = {}
## Clave de escena → ambiente en bucle. Si una escena no aparece, no hay ambiente.
@export var scene_ambience: Dictionary[String, AudioStream] = {}
## Ambiente que suena cuando un momento de historia activa el efecto «Lluvia».
@export var rain_ambience: AudioStream
## Nombre del efecto (en español) → sonido.
@export var effects: Dictionary[String, AudioStream] = {}


func music_for(scene_key: String) -> AudioStream:
	return scene_music.get(scene_key)


func has_music(scene_key: String) -> bool:
	return scene_music.has(scene_key)


func ambience_for(scene_key: String) -> AudioStream:
	return scene_ambience.get(scene_key)


func effect(key: String) -> AudioStream:
	return effects.get(key)


func has_effect(key: String) -> bool:
	return effects.has(key) and effects[key] != null
