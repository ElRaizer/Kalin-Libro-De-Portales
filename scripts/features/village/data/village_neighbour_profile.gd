extends Resource
class_name VillageNeighbourProfile

@export var encounters: Array[PostgameEncounter] = []
@export var visit_memories: Dictionary[String, String] = {
	"Áak":
	"Me alegró que me invitaras a tu rincón. Las pausas en compañía me hacen sentir en casa.",
	"Miis": "Todavía me acuerdo de tu invitación. Me hace ilusión pasar otro rato en el patio.",
	"Peek'": "Cuando salgo a pasear, me acuerdo de que me invitaste a hacer un alto en el patio.",
	"K'éek'en": "Tu invitación me recordó que alrededor de una mesa siempre cabe una historia.",
	"Ma'ax": "Desde que me invitaste a tu mesa, se me ocurren más cosas para hacer juntos.",
	"Báalam": "Me gustó que me invitaras a conversar lejos del ruido del taller.",
	"Kuuts": "Al invitarme al patio me diste un motivo para salir a mirar el sendero.",
	"Kaax": "Tu invitación me recordó lo bien que se está cuando nos reunimos.",
	"Kay": "Gracias por venir a compartir una merienda conmigo en el agua.",
	"Ch'íich'":
	"Me gustó tu invitación al patio. Tal vez otro día podamos compartir algo en la orilla.",
	"Kéej": "Después de caminar tanto, me alegró tu invitación a hacer una pausa en el patio.",
	"T'u'ul":
	"Recuerdo tu invitación al patio. Cuando volvamos a vernos, llevaré las orejas bien atentas."
}

@export var clearing_memories: Dictionary[String, String] = {
	"Ma'ax": "Me quedé con ganas de traer otra idea para reunirnos junto al sendero.",
	"Áak": "En el claro encontré otro lugar para hacer una pausa juntos.",
	"Miis": "Me gusta que en el claro podamos sentarnos y ver quién va llegando."
}


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	var ids: Array[String] = []
	for entry: PostgameEncounter in encounters:
		if entry == null:
			issues.append("Hay un encuentro sin configurar.")
			continue
		issues.append_array(entry.configuration_issues())
		if entry.id in ids:
			issues.append("Cada encuentro necesita una clave propia.")
		ids.append(entry.id)
	for district: String in VillageNeighbours.DISTRICTS:
		for animal: String in VillageNeighbours.RESIDENTS[district]:
			var line: String = visit_memories.get(animal, "")
			if line.strip_edges().is_empty() or line.length() > 160:
				issues.append("Falta un recuerdo breve de visita para " + animal + ".")
	for guest: String in VillageExpansion.GUESTS:
		var line: String = clearing_memories.get(guest, "")
		if line.strip_edges().is_empty() or line.length() > 106:
			issues.append("Falta un recuerdo breve del claro para " + guest + ".")
	return issues
