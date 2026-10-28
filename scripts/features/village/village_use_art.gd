extends RefCounted
class_name VillageUseArt

const ACTORS := {
	"Peek'": preload("res://Arte/aldea/uso/peek_sin_sombra.svg"),
	"Miis": preload("res://Arte/aldea/uso/miis_sin_sombra.svg"),
	"Kaax": preload("res://Arte/aldea/uso/kaax_sin_sombra.svg"),
	"Áak": preload("res://Arte/aldea/uso/aak_sin_sombra.svg"),
	"Kéej": preload("res://Arte/aldea/uso/keej_sin_sombra.svg"),
	"K'éek'en": preload("res://Arte/aldea/uso/keek_en_sin_sombra.svg"),
	"Ma'ax": preload("res://Arte/aldea/uso/maax_sin_sombra.svg"),
	"Kuuts": preload("res://Arte/aldea/uso/kuuts_sin_sombra.svg"),
	"Báalam": preload("res://Arte/aldea/uso/baalam_sin_sombra.svg"),
	"T'u'ul": preload("res://Arte/aldea/uso/tuul_sin_sombra.svg"),
	"Kay": preload("res://Arte/aldea/uso/kay_sin_sombra.svg"),
	"Ch'íich'": preload("res://Arte/aldea/uso/chiich_sin_sombra.svg"),
}
const OBJECTS := {
	"k'áanche'|": preload("res://Arte/aldea/uso/silla.svg"),
	"k'áanche'|chich": preload("res://Arte/aldea/uso/silla_fuerte.svg"),
	"k'áanche'|Jats'uts": preload("res://Arte/aldea/uso/silla_bonita.svg"),
	"mayak|": preload("res://Arte/aldea/uso/mesa.svg"),
	"mayak|chich": preload("res://Arte/aldea/uso/mesa_fuerte.svg"),
	"mayak|Jats'uts": preload("res://Arte/aldea/uso/mesa_bonita.svg"),
	"lak|": preload("res://Arte/aldea/uso/plato.svg"),
	"lak|Jats'uts": preload("res://Arte/aldea/uso/plato_bonito.svg"),
	"janal|": preload("res://Arte/aldea/uso/comida.svg"),
	"ja'|": preload("res://Arte/aldea/uso/agua.svg"),
	"k'áan|": preload("res://Arte/aldea/uso/hamaca_fondo.svg"),
	"k'áan|chich": preload("res://Arte/aldea/uso/hamaca_fuerte.svg"),
	"k'áan|Jats'uts": preload("res://Arte/aldea/uso/hamaca_bonita.svg"),
	"ja'as|": preload("res://Arte/aldea/uso/platano.svg"),
	"ich|": preload("res://Arte/aldea/uso/fruta.svg"),
	"K'úum|": preload("res://Arte/aldea/uso/calabaza.svg"),
}
const HAMMOCK_FRONTS := {
	"chich": preload("res://Arte/aldea/uso/hamaca_frente_fuerte.svg"),
	"Jats'uts": preload("res://Arte/aldea/uso/hamaca_frente_bonita.svg"),
}
const HAMMOCK_FRONT = preload("res://Arte/aldea/uso/hamaca_frente.svg")
const MAT = preload("res://Arte/aldea/uso/petate.svg")
const POND = preload("res://Arte/aldea/uso/agua_orilla.svg")


static func object_texture(word: String, quality: String) -> Texture2D:
	return OBJECTS.get(word + "|" + quality, OBJECTS.get(word + "|"))
