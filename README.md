# Kalin y el Libro de los Portales

Videojuego educativo desarrollado en Godot para practicar vocabulario y estructuras básicas de maya yucateco. El proyecto forma parte del Servicio Social prestado a la UMT.

## Estado del proyecto

- Motor oficial: **Godot 4.6.3**.
- Resolución de diseño: **1280 × 720**.
- Ventana redimensionable entre **960 × 540** y **1920 × 1080**, con escalado proporcional 16:9.
- Escena principal: `res://scenes/MainMenu.tscn`, con mapa de cinco lugares.
- Progreso local con guardado automático de escena, ronda, selección y caminos parciales.
- Ocho niveles distribuidos en cinco mundos y una misión de encargos en la aldea.
- Nueve capítulos de historia animados y tres cinemáticas que acompañan toda la aventura, desde la noche del huracán hasta el regreso de Kalin.
- Una exploración libre de la isla antes del primer capítulo: el jugador camina con Kalin por la orilla, examina objetos y llega a la aldea de los animales.
- Dos paseos por la aldea después de casa y taller, con seis necesidades que se resuelven eligiendo hechizos sobre el escenario y cambios que permanecen guardados.
- Descansos con salida a caminar y regreso a la petición pendiente; visitas independientes a la aldea después del Mundo 4.
- Opciones de lectura y movimiento desde **A tu ritmo** en el mapa o la pausa.
- Los audios de pronunciación están planeados, pero todavía no han sido grabados.

El proyecto es un prototipo funcional en desarrollo. La navegación principal, el libro de hechizos y el guardado están implementados; todavía quedan mecánicas y contenido narrativo por ampliar.

La [revisión visual](APRENDIZAJE_Y_MISION.md) añade una introducción más corta,
peticiones y tarjetas grandes, pistas graduales, bloques de tres peticiones en
taller y comida, reacciones visuales a las elecciones y cinco situaciones
narrativas que se animan solas en ciclos continuos. El libro tiene pestañas ilustradas y `Esc`
abre la pausa. Las pruebas y capturas verifican la implementación; la prueba
con niños sigue pendiente.

## Aprendizaje y misión de encargos

Las páginas cuentan descubrimientos. El libro distingue además práctica, primer recuerdo y recuperaciones sin ayuda en situaciones separadas. La segunda vuelta de casa, taller y comida usa respuestas escritas sin dibujos de solución. Siempre se puede volver a las tarjetas; consultar el libro, pedir pistas o corregir errores se registra como práctica apoyada. Las posiciones se guardan por intento y varían entre rondas.

Tras la historia del portal, **Los encargos de la aldea** permite caminar, recibir peticiones, crear objetos, transportarlos y entregarlos a sus destinatarios. Hay seis encargos de autor; cada partida selecciona tres y prioriza palabras con menos evidencia de recuerdo. También se puede abrir `scenes/world4/Mision_EncargosAldea.tscn` con F6.

El vocabulario fue cotejado documentalmente con la UADY; las fuentes por entrada y los cambios se detallan en [VOCABULARIO.md](VOCABULARIO.md). Las frases completas y pronunciaciones siguen pendientes de revisión con personas hablantes. El diseño de aprendizaje, la misión y la migración del guardado se explican en [APRENDIZAJE_Y_MISION.md](APRENDIZAJE_Y_MISION.md).

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

La interfaz muestra páginas recuperadas. Los puntos mágicos se conservan en el guardado como puntuación acumulativa; no se consumen ni bloquean el avance.

Los cuatro niveles del Mundo 1 usan tableros de 12 columnas y presentan una
progresión propia: un primer camino corto con demostración visual, planificación
de rutas sin cruces, memoria de obstáculos y recuerdo de destinos. El jugador
decide cuándo ocultar las pistas y puede volver a consultarlas. Cada tablero
termina con una celebración; el reconocimiento de palabras y animales queda
en la historia siguiente para evitar dos pruebas consecutivas.

Las ayudas con una mano animada se pueden repetir con **Ayuda**. Al acertar,
los animales recorren su camino, los muebles permanecen en la casa y los
alimentos se entregan. Las frases recuperadas esperan a **Continuar**; tras
cuatro segundos sin interacción, la mano señala el botón. El
Libro de Hechizos pausa el ejercicio y usa las mismas ilustraciones SVG que
las peticiones; en el repaso se retiran los dibujos de las respuestas.

El libro viaja desde su botón hasta el centro, se abre y regresa al cerrarse.
Las páginas y las categorías cambian con una transición breve; las flechas
del teclado permiten hojearlo y `Esc` lo cierra. Cada entrada muestra su
estado de aprendizaje y el botón de pronunciación. Mientras falta la grabación,
el botón muestra un aviso y permanece en silencio.

## Historia

Entre los niveles se presentan capítulos cortos de historia. En ellos Kalin
conversa con los animales, que entran con animaciones y se presentan con
*In k'aaba'e' ___*. El jugador participa de cinco maneras: avanza los
diálogos, toca a cada animal para escuchar su nombre, adivina quién es quién y
elige la palabra maya que le pide un animal y explora pequeñas situaciones visuales. Si elige mal, el botón muestra el
significado de esa palabra para que el error también enseñe. Cada capítulo
repasa lo aprendido en el nivel anterior y presenta lo del siguiente.

| Capítulo | Momento | Repasa | Presenta |
|---:|---|---|---|
| 1 | Después de la exploración de la orilla | — | Peek', Miis y Kaax |
| 2 | Después del Mundo 1 · Nivel 1 | Peek', Miis y Kaax | Kéej, K'éek'en y Ma'ax |
| 3 | Después del Mundo 1 · Nivel 2 | Kéej, K'éek'en y Ma'ax | Báalam, Kuuts y T'u'ul |
| 4 | Después del Mundo 1 · Nivel 3 | Báalam, Kuuts y T'u'ul | Kay, Ch'íich' y Áak |
| 5 | Después del Mundo 1 · Nivel 4 | Los doce animales | La fiesta y la Casa Maya vacía (cinemática) |
| 6 | Después del Mundo 2 | La casa amueblada, mediante una escena | Las cualidades, empezando por *nojoch* |
| 7 | Después del Mundo 3 | Los objetos a la medida, mediante una escena | *In k'a'at* y *ja'* |
| 8 | Después del Mundo 4 | Los amigos alimentados, mediante una escena | El portal de regreso, *Bix a beel* y *Yuum bo'otik* |
| 9 | Después del Mundo 5 (epílogo) | Animales y frases de cortesía | Despedida y regreso de Kalin a casa (cinemática final) |

El hilo narrativo sigue el GDD: el huracán borró los caminos (Mundo 1) y se
llevó los muebles de la aldea (Mundo 2). Los animales piden después objetos a
su medida (Mundo 3) y comida (Mundo 4). Por último, las palabras amables
completan el libro y abren el portal (Mundo 5). Con cada capítulo Kalin
recupera páginas de su Libro de Hechizos.

Los capítulos se pueden saltar con **Saltar historia**. `Esc` abre la pausa. **Continuar**
retoma la escena y el momento guardados. En partidas antiguas sin punto de
continuación, presenta la historia del siguiente nivel pendiente.

### Exploración de la isla

Antes de conocer a los animales, el jugador recorre la isla con Kalin. La
exploración **La orilla de la isla** va entre la cinemática del huracán y el
Capítulo 1, y es lineal: el sendero empieza en la playa donde Kalin despertó,
cruza el palmar y el Sak Beh roto y termina en la aldea.

- La cámara sigue a Kalin y el cielo se mueve más despacio (parallax).
- Los objetos que brillan se pueden examinar: una concha, una página en blanco
  del Libro de Hechizos (Kalin la recoge), una piedra del Sak Beh y huellas de
  animales. El panel inferior cuenta los descubrimientos.
- Una palmera caída bloquea el camino; Kalin la aparta con un hechizo.
- Al llegar a la aldea, Kaax, Peek' y Miis esperan junto a las casas y empieza
  el Capítulo 1.

La exploración se puede saltar con **Saltar exploración**. `Esc` abre la pausa.

### Cinemáticas y animaciones

Además de los capítulos, tres cinemáticas cortas avanzan solas (un clic las
adelanta y **Saltar cinemática** las omite):

| Cinemática | Momento | Qué muestra |
|---|---|---|
| Prólogo · La noche del huracán | Entre la introducción y la exploración de la orilla | El huracán con lluvia, viento y relámpagos; las páginas del libro caen como estrellas; Kalin despierta dormido en la orilla |
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
- Exploración: `←` `→` o `A` `D` para caminar; clic o toque para ir a un punto (o a un objeto, que se examina al llegar); `E`, `Espacio` o `Enter` para examinar y avanzar el diálogo; `Esc` para pausar.
- Mundo 1: clic y arrastre, o flechas para mover el cursor del tablero. `Enter` / `Espacio` inicia el camino; las flechas lo trazan y `Esc` lo cancela.
- Mundos 2, 3, 4 y 5: `Tab` / flechas para elegir una palabra o respuesta y `Enter` / `Espacio` para confirmarla.
- Libro de hechizos: flechas izquierda/derecha para cambiar de página y `Esc` para cerrarlo. Al cerrar, el foco vuelve al control que abrió el libro.
- `Esc` pausa la aventura; si el libro está abierto, lo cierra primero. Si hay un trazo activo, detiene ese trazo. La pausa permite seguir jugando o volver al mapa.

## Documentación

- [MEJORAS_AVENTURA.md](MEJORAS_AVENTURA.md): paseos, descansos, borradores, comodidad y decisiones pendientes de validación.

- [INSTRUCCIONES.md](INSTRUCCIONES.md): instalación, estructura técnica y mantenimiento.
- [AUDITORIA_BUENAS_PRACTICAS.md](AUDITORIA_BUENAS_PRACTICAS.md): cumplimiento, correcciones y pendientes de diseño.
- [VOCABULARIO.md](VOCABULARIO.md): inventario completo para revisión con mayahablantes, palabras y frases con su significado en español, variantes, dudas y hoja de correcciones.
- [APRENDIZAJE_Y_MISION.md](APRENDIZAJE_Y_MISION.md): evidencia por palabra, recuerdo sin ayuda, encargos y pruebas.
- [Arte/audio/README.md](Arte/audio/README.md): preparación y nombres de los audios pendientes.

## Trabajo pendiente

- Grabar, revisar e integrar las pronunciaciones.
- Diseñar más niveles para los mundos 2, 3 y 4.
- Ampliar las variaciones y la dificultad de los mundos 2, 3 y 4.
- Validar las frases de cortesía del Mundo 5 con una persona hablante o especialista.
- Validar textos y pronunciaciones con una persona hablante o especialista en maya yucateco.
- Observar a niños de alrededor de 10 años jugando sin explicación inicial y ajustar las ayudas según los resultados.
- Ampliar pruebas de accesibilidad, relaciones de aspecto y exportaciones objetivo.
- Ampliar la validación automática hasta cubrir interacción, navegación y migraciones completas del guardado.
