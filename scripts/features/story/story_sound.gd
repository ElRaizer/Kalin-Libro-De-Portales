extends RefCounted
class_name StorySound

## Subsistema sonoro de StoryScene. Hace sonar lo que cada StoryBeat ya muestra
## (trueno con el destello y la sacudida, caracol con el cartel de mundo nuevo,
## viento con las hojas, pasos cuando Kalin entra...), así los capítulos y las
## cinemáticas suenan sin configurar nada. Un momento puede pedir además su
## propio sonido o cambiar la música desde la categoría «Sonido» del Inspector.

const EFFECT_SOUNDS := {
	StoryBeat.Effect.HOJAS: "hojas_viento",
	StoryBeat.Effect.MUEBLES: "muebles_volando",
	StoryBeat.Effect.PAGINAS: "paginas_revolotear",
	StoryBeat.Effect.CHISPAS: "chispas_magia",
}
const WALK_STEPS := 4
const JUMP_SECONDS := 0.4

var _previous_effects: int = 0
var _raining: bool = false


## `waking` indica que Kalin estaba dormido y se levanta en este momento.
func play_beat(beat: StoryBeat, motion: StoryBeat.KalinMotion, waking: bool) -> void:
	if beat.music != null:
		AudioManager.play_music(beat.music)
	_update_rain((beat.effects & StoryBeat.Effect.LLUVIA) != 0)
	for flag: int in EFFECT_SOUNDS:
		if (beat.effects & flag) != 0 and (_previous_effects & flag) == 0:
			AudioManager.play_sfx(EFFECT_SOUNDS[flag])
	_previous_effects = beat.effects
	if beat.flash and beat.screen_shake:
		AudioManager.play_sfx("trueno")
	elif beat.flash:
		AudioManager.play_sfx("destello")
	elif beat.screen_shake:
		AudioManager.play_sfx("retumbo")
	if beat.title != "":
		AudioManager.play_sfx("cartel_caracol")
	if beat.celebrate_page:
		AudioManager.play_sfx("pagina_recuperada")
	_play_motion(motion, waking)
	if beat.sound != null:
		AudioManager.play_stream(beat.sound)


func _update_rain(raining: bool) -> void:
	if raining == _raining:
		return
	_raining = raining
	if raining:
		AudioManager.play_ambience(AudioManager.catalog.rain_ambience)
	else:
		AudioManager.restore_scene_ambience()


func _play_motion(motion: StoryBeat.KalinMotion, waking: bool) -> void:
	if waking:
		AudioManager.play_sfx("despertar")
	match motion:
		StoryBeat.KalinMotion.ENTRA:
			for step: int in range(WALK_STEPS):
				_play_later("pasos_tierra", StoryAnimator.WALK_SECONDS * step / WALK_STEPS)
		StoryBeat.KalinMotion.SALTA:
			for jump: int in range(StoryAnimator.JUMP_COUNT):
				_play_later("salto", JUMP_SECONDS * jump)
		StoryBeat.KalinMotion.CRUZA:
			AudioManager.play_sfx("portal_cruzar")


func _play_later(key: String, delay: float) -> void:
	AudioManager.play_sfx_later(key, delay)
