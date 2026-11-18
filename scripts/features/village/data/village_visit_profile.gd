extends Resource
class_name VillageVisitProfile

## Tiempo activo: abrir un panel o pausar detiene la visita.
@export_range(8.0, 120.0, 1.0) var duration: float = 18.0
@export_multiline var aak_reaction: String = "Aquí puedo hacer una pausa contigo."
@export_multiline var miis_reaction: String = "Me gusta este rincón que preparaste para compartir."

@export var table_reactions: Dictionary[String, String] = {
	"Peek'": "¡Qué buen lugar para hacer un alto en el camino!",
	"K'éek'en": "Desde esta mesa caben el plato y las historias.",
	"Ma'ax": "Me sentaré un rato. Tengo ideas para compartir.",
	"Báalam": "Aquí podemos conversar con calma.",
	"Kuuts": "Desde aquí se ve quién viene por el sendero.",
	"Kaax": "Me gusta esta mesa para reunirnos un ratito.",
	"Ch'íich'": "¡Encontré un buen sitio junto a tu mesa!",
	"Kéej": "Después de caminar, agradezco una pausa aquí.",
	"T'u'ul": "Este rincón tiene sitio hasta para mis orejas."
}


func reaction_for(animal: String) -> String:
	match animal:
		"Áak":
			return aak_reaction
		"Miis":
			return miis_reaction
	return table_reactions.get(animal, "Me alegra que me hayas invitado.")
