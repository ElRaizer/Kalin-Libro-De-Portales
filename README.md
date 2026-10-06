# Kalin y el Libro de los Portales

Videojuego educativo desarrollado en Godot para practicar vocabulario y estructuras básicas de maya yucateco. El proyecto forma parte del Servicio Social prestado a la UMT.

## Estado del proyecto

- Motor: **Godot 4.6**.
- Resolución de diseño: **1280 × 720**.
- Ventana redimensionable entre **960 × 540** y **1920 × 1080**, con escalado proporcional 16:9.
- Escena principal: `res://scenes/Intro.tscn`.
- Progreso local con guardado automático.
- Ocho escenas jugables distribuidas en cinco mundos.
- Nueve capítulos de historia animados y tres cinemáticas que acompañan toda la aventura, desde la noche del huracán hasta el regreso de Kalin.
- Los audios de pronunciación están planeados, pero todavía no han sido grabados.

El proyecto es un prototipo funcional en desarrollo. La navegación principal, el libro de hechizos y el guardado están implementados; todavía quedan mecánicas y contenido narrativo por ampliar.

## Organización jugable

Cada **mundo** representa una mecánica. Los **niveles** de un mismo mundo reutilizan esa mecánica y cambian vocabulario, ambientación u otros factores.

| Mundo | Nivel | Escena | Contenido |
|---:|---:|---|---|
| 1 | 1 | Los Caminos Blancos | Animales: Peek', Miis y Kaax |
| 1 | 2 | Los Animales del Bosque | Kéej, K'éek'en y Ma'ax |
| 1 | 3 | Los Guardianes del Monte | Báalam, Kuuts y T'u'ul |
| 1 | 4 | Agua y Cielo | Kay, Ch'íich' y Áak |
| 2 | 1 | La Casa Maya | Selección del hechizo correcto para objetos del hogar |
| 3 | 1 | Hechizos de Adjetivos | Construcción de frases con sustantivo y adjetivo en dos fases |
| 4 | 1 | Yo Quiero | Estructura *In k'a'at* y alimentos |
| 5 | 1 | El Portal de Regreso | Recapitulación, cortesía y despedida |

El orden de progreso es Mundo 1 completo → Mundo 2 → Mundo 3 → Mundo 4 → Mundo 5. El último mundo recupera los fragmentos finales del libro y cierra la aventura con el portal de regreso.

Los puntos mágicos son una puntuación acumulativa de desempeño: se obtienen al aprender vocabulario nuevo y completar niveles. No se consumen ni bloquean el avance.

Los cuatro niveles del Mundo 1 usan tableros de 12 columnas y presentan una
progresión propia: tutorial abierto, planificación de rutas sin cruces, memoria
de obstáculos y recuerdo de destinos sin pistas textuales.

## Historia

Entre los niveles se presentan capítulos cortos de historia. En ellos Kalin
conversa con los animales, que entran con animaciones y se presentan con
*In k'aaba'e' ___*. El jugador participa de cuatro maneras: avanza los
diálogos, toca a cada animal para escuchar su nombre, adivina quién es quién y
elige la palabra maya que le pide un animal. Si elige mal, el botón muestra el
significado de esa palabra para que el error también enseñe. Cada capítulo
repasa lo aprendido en el nivel anterior y presenta lo del siguiente.

| Capítulo | Momento | Repasa | Presenta |
|---:|---|---|---|
| 1 | Después de la introducción | — | Peek', Miis y Kaax |
| 2 | Después del Mundo 1 · Nivel 1 | Peek', Miis y Kaax | Kéej, K'éek'en y Ma'ax |
| 3 | Después del Mundo 1 · Nivel 2 | Kéej, K'éek'en y Ma'ax | Báalam, Kuuts y T'u'ul |
| 4 | Después del Mundo 1 · Nivel 3 | Báalam, Kuuts y T'u'ul | Kay, Ch'íich' y Áak |
| 5 | Después del Mundo 1 · Nivel 4 | Los doce animales | La fiesta y la Casa Maya vacía (cinemática) |
| 6 | Después del Mundo 2 | mayak, lak y ch'áak | Las cualidades, empezando por *nojoch* |
| 7 | Después del Mundo 3 | *In mayake' nojoch* y otras frases con adjetivos | *In k'a'at* y *ja'* |
| 8 | Después del Mundo 4 | *In k'a'at ja'as mejen*, *In k'a'at K'úum nojoch* e *In k'a'at pak'al* | El portal de regreso, *Bix a beel* y *Yuum bo'otik* |
| 9 | Después del Mundo 5 (epílogo) | Animales y frases de cortesía | Despedida y regreso de Kalin a casa (cinemática final) |

El hilo narrativo sigue el GDD: el huracán borró los caminos (Mundo 1) y se
llevó los muebles de la aldea (Mundo 2). Los animales piden después objetos a
su medida (Mundo 3) y comida (Mundo 4). Por último, las palabras amables
completan el libro y abren el portal (Mundo 5). Con cada capítulo Kalin
recupera páginas de su Libro de Hechizos.

Los capítulos se pueden saltar con **Saltar historia** o `Esc`. **Continuar**
en el menú muestra el capítulo que antecede al nivel pendiente.

### Cinemáticas y animaciones

Además de los capítulos, tres cinemáticas cortas avanzan solas (un clic las
adelanta y **Saltar cinemática** las omite):

| Cinemática | Momento | Qué muestra |
|---|---|---|
| Prólogo · La noche del huracán | Entre la introducción y el Capítulo 1 | El huracán con lluvia, viento y relámpagos; las páginas del libro caen como estrellas; Kalin despierta dormido en la orilla |
| Intermedio · La Casa Maya vacía | Entre el Capítulo 5 y el Mundo 2 | Kalin y sus amigos caminan al atardecer hasta la Casa Maya, la encuentran sin muebles y Kalin abre su libro |
| Epílogo · Regreso a casa | Entre el Capítulo 9 y el menú | Kalin cruza el portal, las páginas vuelven al libro y despierta en su cuarto |

Los capítulos también usan estas animaciones: fondos nuevos con fundido
(noche del huracán, Casa Maya por dentro, atardecer en la aldea, milpa y portal
sobre la isla), hojas, lluvia, muebles, páginas y chispas que flotan, cambios
de color según la hora del día, Kalin que camina, salta, tiembla, duerme o cruza
el portal, temblores de pantalla, destellos y carteles al llegar a un mundo
nuevo. Cada vez que Kalin recupera una página salta de alegría y estallan
páginas y chispas.

## Ejecutar el proyecto

1. Instala Godot 4.6.
2. Importa la carpeta del repositorio desde el administrador de proyectos de Godot.
3. Abre `project.godot`.
4. Pulsa **F6** para probar una escena o **F5** para iniciar desde la introducción.

No se requieren complementos ni dependencias externas.

## Controles

- En todos los menús: `Tab` / `Shift+Tab` o flechas para mover el foco; `Enter` o `Espacio` para activar la opción resaltada.
- Introducción: clic izquierdo, `Espacio` o `Enter` para avanzar; el botón permite saltarla con teclado.
- Mundo 1: clic y arrastre, o flechas para mover el cursor del tablero. `Enter` / `Espacio` inicia el camino; las flechas lo trazan y `Esc` lo cancela.
- Mundos 2, 3, 4 y 5: `Tab` / flechas para elegir una palabra o respuesta y `Enter` / `Espacio` para confirmarla.
- Libro de hechizos: flechas izquierda/derecha para cambiar de página y `Esc` para cerrarlo. Al cerrar, el foco vuelve al control que abrió el libro.

## Documentación

- [INSTRUCCIONES.md](INSTRUCCIONES.md): instalación, estructura técnica y mantenimiento.
- [AUDITORIA_BUENAS_PRACTICAS.md](AUDITORIA_BUENAS_PRACTICAS.md): cumplimiento, correcciones y pendientes de diseño.
- [VOCABULARIO.md](VOCABULARIO.md): grafías adoptadas, normalizaciones y decisiones del GDD.
- [Arte/audio/README.md](Arte/audio/README.md): preparación y nombres de los audios pendientes.

## Trabajo pendiente

- Grabar, revisar e integrar las pronunciaciones.
- Diseñar más niveles para los mundos 2, 3 y 4.
- Ampliar las variaciones y la dificultad de los mundos 2, 3 y 4.
- Validar las frases de cortesía del Mundo 5 con una persona hablante o especialista.
- Validar textos y pronunciaciones con una persona hablante o especialista en maya yucateco.
- Realizar pruebas de accesibilidad, teclado, pantallas distintas a 1280 × 720 y exportaciones objetivo.
- Ampliar la validación automática hasta cubrir interacción, navegación y migraciones completas del guardado.
