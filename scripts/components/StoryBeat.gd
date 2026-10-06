@tool
extends Resource
class_name StoryBeat

## Momento editable de una escena de historia. Cada capítulo es una lista de
## StoryBeat configurada desde el Inspector, sin escribir código.
## Los animales se nombran por su palabra maya: la traducción, la frase y la
## ilustración se consultan en GameManager para no duplicar vocabulario.

enum Kind {
	DIALOGO,   ## Alguien habla; se avanza con clic, Espacio o Enter.
	CONOCER,   ## El jugador toca a cada animal para escuchar su nombre.
	ADIVINAR,  ## El jugador elige al animal que se nombra en maya.
	ELEGIR,    ## El jugador elige una palabra maya entre opciones escritas.
}

enum KalinPose { NORMAL, SORPRENDIDO, OCULTO }

## Ambiente de color de la escena. SIN_CAMBIO conserva el del momento anterior.
enum Mood { SIN_CAMBIO, DIA, ATARDECER, NOCHE, TORMENTA, AMANECER }

## Movimiento de Kalin al empezar el momento (vuelve a su sitio en el siguiente).
enum KalinMotion {
	QUIETO,    ## Solo respira.
	ENTRA,     ## Camina desde el borde izquierdo de la pantalla.
	SALTA,     ## Da dos saltos de alegría.
	TIEMBLA,   ## Tiembla de susto o de frío.
	DORMIDO,   ## Está acostado y respira despacio.
	CRUZA,     ## Camina hacia el portal, se hace pequeño y desaparece.
}

## Bits de `effects`; el orden debe coincidir con las etiquetas de `@export_flags`.
enum Effect {
	HOJAS = 1,
	LLUVIA = 2,
	MUEBLES = 4,
	PAGINAS = 8,
	CHISPAS = 16,
}

@export var kind: Kind = Kind.DIALOGO

@export_category("Diálogo")
## "Kalin", "Narrador" o la palabra maya del animal que habla.
@export var speaker: String = "Narrador"
@export_multiline var text: String = ""

@export_category("Escena")
## Si se deja vacío se conserva el fondo del momento anterior.
@export var background: Texture2D
@export var kalin_pose: KalinPose = KalinPose.NORMAL
## Palabras mayas de los animales en escena (máximo 4).
@export var actors: Array[String] = []

@export_category("Interacción")
## Respuesta correcta en ADIVINAR (un animal) o en ELEGIR (una palabra).
@export var target_word: String = ""
## Palabras mayas que se ofrecen como botones en un momento ELEGIR.
@export var options: Array[String] = []
## Frase y traducción que se muestran al acertar en ELEGIR. Si quedan vacías
## se usan la estructura y la traducción de GameManager.VOCABULARY.
@export var reveal_phrase: String = ""
@export var reveal_translation: String = ""
## Muestra la celebración "¡Página recuperada!".
@export var celebrate_page: bool = false

@export_category("Animación")
## Color ambiental de la escena; el cambio se hace con una transición suave.
@export var mood: Mood = Mood.SIN_CAMBIO
## Efectos que caen o flotan durante este momento (no se heredan del anterior).
@export_flags("Hojas", "Lluvia", "Muebles", "Páginas", "Chispas") var effects: int = 0
@export var kalin_motion: KalinMotion = KalinMotion.QUIETO
## Sacude la pantalla, como un trueno o un golpe de viento.
@export var screen_shake: bool = false
## Destello blanco, como un relámpago o la luz del portal.
@export var flash: bool = false
## Cartel grande al centro (por ejemplo, el nombre de un mundo nuevo).
@export var title: String = ""
@export var subtitle: String = ""
## Si es mayor que 0, el momento avanza solo tras estos segundos (cinemática).
## El jugador puede adelantarlo con clic, Espacio o Enter.
@export_range(0.0, 10.0, 0.1) var auto_advance: float = 0.0
