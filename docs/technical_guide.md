# Kalin y el Libro de los Portales — Guía técnica

Esta guía explica cómo abrir, ejecutar y mantener el repositorio. La presentación general y el estado del contenido están en [README.md](../README.md); las decisiones lingüísticas se registran en [docs/vocabulary.md](vocabulary.md).

## Requisitos

- Godot **4.6.3** (versión fijada en `.godot-version`).
- Un sistema capaz de ejecutar el renderer configurado por el proyecto.
- No se requieren paquetes externos.

## Abrir y ejecutar

1. Abre el administrador de proyectos de Godot.
2. Selecciona **Importar** y elige el archivo `project.godot` de este repositorio.
3. Espera a que Godot importe los SVG y las escenas.
4. Pulsa **F5** para ejecutar el juego completo.

La escena principal es `res://scenes/ui/main_menu/main_menu.tscn`. **Jugar** abre una introducción breve, seguida del huracán y la exploración; **Continuar** recupera el punto guardado. **Saltar intro** sólo aparece al repetir una introducción terminada y continúa con el huracán.

## Configuración esencial

El proyecto incluye los siguientes autoloads:

```ini
[autoload]
WindowManager="*res://scripts/autoloads/window_manager.gd"
GameManager="*res://scenes/autoloads/game_manager.tscn"
AccessibilityManager="*res://scenes/autoloads/accessibility_manager.tscn"
PauseMenu="*res://scenes/autoloads/pause_menu.tscn"
AudioManager="*res://scenes/autoloads/audio_manager.tscn"
DebugAnswer="*res://scripts/autoloads/debug_answer.gd"
```

`AudioManager` cambia la música y el ambiente de cada escena según
`data/audio_catalog.tres`, reproduce los efectos por nombre y guarda el volumen.
Ver [Música y efectos](audio.md).

`GameManager` coordina los servicios y las señales de aplicación.
`GameSession` posee el progreso; `SceneNavigator` coordina transiciones y
checkpoints; `SaveSchema`, `SessionCodec` y `SaveRepository` validan, decodifican y
persisten. `GameContent` y `VocabularyCatalog` contienen las consultas canónicas.

La configuración de contenido, arte, controles y plantillas se explica en
[Configuración desde el editor](technical_guide.md#configuración-esencial). Los ejercicios de los mundos
2–5 usan recursos `ExerciseSet` en `data/exercises/`; las ilustraciones y
expresiones se asignan en `data/visual_catalog.tres`.

`project.godot` también define tres acciones de entrada para las exploraciones (**Proyecto → Configuración del proyecto → Mapa de entrada**):

| Acción | Teclas |
|---|---|
| `kalin_izquierda` | `←`, `A` |
| `kalin_derecha` | `→`, `D` |
| `kalin_interactuar` | `E`, `Espacio`, `Enter`, `Enter` del teclado numérico |

En la aldea y las misiones con suelo libre, `↑`/`W` y `↓`/`S` controlan la
profundidad. Un clic calcula una ruta alrededor de muebles y estanques. Los encargos
se consultan en las tarjetas del taller; los habitantes y letreros conservan su
botón de interacción por teclado. Decorar cambia a
un modo explícito: flechas mueven la vista previa, Enter confirma y Escape cancela
o sale. Las orientaciones de sillas y mesas usan vistas SVG distintas, sin girar el dibujo plano.

## Estructura y responsabilidades

La estructura vigente y los contratos de cada sistema están en
[Arquitectura](architecture.md). Las escenas y scripts se agrupan por función
en `features/`, por interfaz en `ui/` y por composición en `worlds/`.
`core/` contiene sesión, navegación, persistencia y catálogos.

La referencia para comandos reproducibles, formato y catálogos es
[Mantenimiento y validación](maintenance.md). El ejecutor usa `-GodotPath`,
`GODOT_BIN` o una versión compatible en `PATH`; no depende de una ruta de esta máquina.

## Sistema visual compartido

Los estilos estáticos viven en `res://themes/kalin_theme.tres`. Este recurso se
puede abrir y modificar desde el Inspector de Godot y contiene variaciones con
nombres semánticos, entre ellas:

- `KalinCreamPanel`, `KalinDialoguePanel` y `KalinCompletionPanel` para paneles.
- `KalinPrimaryButton`, `KalinNounButton` y `KalinAdjectiveButton` para botones.
- `KalinNounSlot` y `KalinAdjectiveSlot` para los espacios de construcción de frases.
- `KalinBookCard` para las páginas y `KalinSecondaryButton` para su pronunciación.

Al crear una interfaz nueva, asigna `kalin_theme.tres` al `Control` superior y
elige la variante adecuada en **Theme Type Variation**. Conserva en los scripts
solamente los cambios que dependan del estado del juego, como colores asociados
a una respuesta concreta, selección, acierto, error o bloqueo.

## Progresión por mundos

El orden oficial vive en `GameContent.LEVEL_ORDER`:

1. Mundo 1, niveles 1–4: caminos de animales.
2. Mundo 2, nivel 1: lanzamiento del hechizo correcto.
3. Mundo 3, nivel 1: adjetivos.
4. Mundo 4, nivel 1: *In k'a'at* en episodios de práctica y recuerdo.
5. Mundo 4, nivel 2: números mayas del 1 al 50 (ver [Las piedras que cuentan](#las-piedras-que-cuentan)).
6. Mundo 5, nivel 1: recapitulación, cortesía y portal de regreso.

Cada nivel debe llamar `GameManager.complete_level(mundo, nivel)` con su identidad real. **Continuar** usa `resume_scene_key` y el checkpoint de la escena. Si la sesión actual no tiene checkpoint, consulta el primer elemento incompleto de `LEVEL_ORDER`.

Para agregar un nivel:

1. Crea su escena y script en las carpetas del mundo correspondiente.
2. Agrega una clave a `GameContent.SCENE_PATHS`.
3. Inserta sus datos en la posición correcta de `GameContent.LEVEL_ORDER`.
4. Configura la escena siguiente.
5. Registra su vocabulario en `GameContent.VOCABULARY`.
6. Prueba comenzar, terminar, salir al menú y usar **Continuar** con una partida nueva y una existente.

## Las piedras que cuentan

Mundo 4 · Nivel 2 (`world4_level2`, escena `scenes/worlds/world4/level4_piedras_que_cuentan.tscn`).
Va después de la comida: `world4_level1` → capítulo **El tianguis** (`world4_story2`,
`historia_tianguis.tscn`) → nivel → `world4_story1` (El portal despierta).

| Pieza | Responsabilidad |
|---|---|
| `MayaNumeral` (`scripts/features/counting/`) | Reglas puras de la numeración de dos pisos: punto 1, barra 5, base 20 (veintenas arriba) y concha del cero cuando un número sólo tiene veintenas. |
| `CountingSession` | Números sorteados con la semilla, tablilla (`twenties`, `units`, `shell`, piso elegido), errores y checkpoint validado. Sin nodos ni autoloads. |
| `CountingSet` | Configuración en `data/exercises/world4_counting.tres`: cantidad de rondas, rango (1 a 50), rondas guiadas y animales que piden. Avisa en el Inspector si el rango no alcanza. |
| `NumeralView` | Dibuja un piso con las texturas de cacao, varita y concha elegidas en el Inspector. |
| `counting_exercise.gd` (`scripts/worlds/world4/`) | Presenta la ronda, los dos pisos y las piezas; usa `LearningGuide`, `MissionProgress` y `CompletionOverlay`. |

Sólo hay una actividad: formar el número pedido con clics. Se elige un piso de la
tablilla y se ponen granos, varitas o la concha. Cinco granos se juntan en una
varita y veinte unidades suben como un grano al piso de arriba, dejando la concha
si abajo no sobra nada. Un numeral es correcto cuando vale el número y, si sólo
tiene veintenas, lleva la concha. Los números no se repiten en una partida.
Los planes nuevos progresan por bandas
de cantidades pequeñas a grandes y garantizan una concha inferior cuando el rango
la admite. Se derivan de `layout_seed` y se guardan completos: continuar conserva
el plan y la tablilla; **Repetir** prepara otro plan dentro de la misma curva.
El nivel no registra vocabulario ni evidencia de aprendizaje.

El arte se genera con `python tools/build_counting_art.py`: amate, líneas rojas de
códice, contorno negro, azul maya y ocre, sin `rgba()`.

## Capítulos de historia

Los capítulos heredan `res://scenes/features/story/story_scene.tscn` y no necesitan
script propio. En el Inspector se configuran:

- `chapter_title`: título visible del capítulo.
- `next_scene_key`: escena que se abre al terminar o al pulsar **Saltar historia**.
- `beats`: lista de recursos `StoryBeat`, uno por momento.

Cada `StoryBeat` define:

Los gestos `PROTECT_BOOK`, `THINK_HOME` y `FAREWELL` de `kalin_motion` mantienen
recortes SVG editables. `gesture_texture` permite personalizar su dibujo desde el
Inspector. `page_motion` (`NONE`, `SCATTER`, `RECOVER`) configura la página
protagonista; `page_word` debe pertenecer al contenido ya vivido en ese momento.
La transformación de la mesa muestra el espacio que necesitan dos platos.

La despedida comienza con el libro abrazado y después levanta la mano. Para
mantener la vacilación durante todo un diálogo, asigna
`Arte/sprites/kalin_farewell_hesitate.svg` a `gesture_texture`; la frase sobre la
dificultad de partir ya lo configura así. `CRUZA` incluye pasos, una mirada atrás y
desaparición al atravesar la luz, conservando la escala relativa del Inspector.
`THINK_HOME` utiliza una mirada baja y el libro entre los brazos. El último momento
del regreso personaliza ese gesto con `kalin_home_rest.svg`, sin libro: el único
ejemplar queda visible en el escritorio junto al dibujo terminado.

La mesa compartida crece en ancho sobre el mismo apoyo. El `TableArm` editable de
la viñeta une la mano de Áak con el segundo plato; la colocación empieza después
de ampliar la mesa. `StoryScene` solicita `finish_reveal()` al restaurar un momento
guardado. El resultado accesible es estable y no vuelve a representar la entrega.

El dibujo sin terminar pertenece al fondo del cuarto compartido por introducción
y regreso. `HomecomingMemory.completed_drawing` recibe desde la escena la capa
transparente con el camino hacia la aldea y el libro sobre el escritorio. Sólo
aparece en `drawing_beat`; reanudar muestra su estado final, sin nuevos campos de
partida ni evidencia de aprendizaje. El recuerdo elegido se conserva en los
momentos anteriores y deja libre el dibujo al cerrar.

Las cinemáticas esperan al lector de forma predeterminada. **A tu ritmo → Avanzar
cinemáticas al pulsar** conserva esa preferencia fuera del guardado. Desactivarla
habilita `auto_advance`, que espera la escritura del texto y el intervalo de autor.
Cambiar la preferencia durante la pausa no salta el momento actual.

La revisión visual incorpora también `kind = EXPLORAR`, `visual_scene` (vacío,
`camino`, `casa`, `tamano`, `hambre` o `portal`) y `visual_solved`. En EXPLORAR,
la escena representa el problema automáticamente en un bucle continuo; Continuar
está disponible sin tocar la animación. Los checkpoints narrativos conservan el
momento, el plan de preguntas y el estado de la interacción en el formato vigente,
sin migrar posiciones de capítulos anteriores. `PauseMenu` es el autoload que
gestiona `Esc` sin saltar capítulos. Ver [Aprendizaje y misiones](learning_and_missions.md) para los componentes
compartidos de presentación y ayuda.

| Propiedad | Uso |
|---|---|
| `kind` | `DIALOGO` (se avanza con clic, Espacio o Enter), `CONOCER` (tocar a cada animal), `ADIVINAR` (elegir al animal nombrado) o `ELEGIR` (elegir una palabra maya entre botones). |
| `speaker` | `Kalin`, `Narrador` o la palabra maya del animal que habla. |
| `text` | Texto del diálogo. |
| `background` | Fondo; si queda vacío se conserva el anterior. |
| `kalin_pose` | `NORMAL`, `SORPRENDIDO` u `OCULTO`. |
| `actors` | Palabras mayas de los animales en escena (máximo 4). |
| `target_word` | Respuesta correcta en `ADIVINAR` o `ELEGIR`. En `ADIVINAR` no debe coincidir con `speaker`, porque su nombre en español delataría la respuesta. |
| `options` | Palabras mayas que se ofrecen en `ELEGIR`; deben incluir `target_word`. |
| `reveal_phrase`, `reveal_translation` | Frase completa que se muestra al acertar en `ELEGIR`. Es obligatoria para los adjetivos, cuya estructura en `VOCABULARY` usa el marcador `[sust.]`. |
| `celebrate_page` | Muestra "¡Página recuperada!" y la página protagonista. Kalin salta si no se configuró otro gesto. |

Las propiedades de la categoría **Animación** convierten un capítulo en una
cinemática. Todas son opcionales y, salvo `mood`, valen solo para su momento:

| Propiedad | Uso |
|---|---|
| `mood` | Color ambiental: `DIA`, `ATARDECER`, `NOCHE`, `TORMENTA` o `AMANECER`. Cambia con una transición suave; `SIN_CAMBIO` conserva el anterior. Los colores están en `StoryScene.AMBIENT_COLORS`. |
| `effects` | Casillas `Hojas`, `Lluvia`, `Muebles`, `Páginas` y `Chispas`. Se pueden combinar. Son nodos `CPUParticles2D` dentro de `Effects` en `story_scene.tscn`, así que su cantidad, velocidad y textura se ajustan en el Inspector. |
| `kalin_motion` | `QUIETO`, `ENTRA`, `SALTA`, `TIEMBLA`, `DORMIDO`, `CRUZA`, `PROTECT_BOOK`, `THINK_HOME` o `FAREWELL`. Los tres últimos usan los recortes de gesto descritos arriba. |
| `screen_shake` | Sacude la pantalla, como un trueno. |
| `flash` | Destello blanco, como un relámpago o la luz del portal. |
| `title`, `subtitle` | Cartel central, por ejemplo "Mundo 3" y "Hechizos de Adjetivos". |
| `auto_advance` | Segundos que espera, después de escribirse el texto, antes de avanzar solo. Con 0 espera al jugador. El clic, `Espacio` o `Enter` lo adelantan. |

Cuando `background` cambia, el fondo nuevo entra con un fundido.

Los capítulos 6 a 9 viven en `scenes/worlds/world2/` a `scenes/worlds/world5/` y usan a los
seis animales de la aldea que también aparecen en los mundos 2, 3 y 4, con sus
mismas peticiones. Tras completar el Mundo 5, **Preparar mi despedida** abre el
paseo para hablar con los amigos y elegir un recuerdo. Después se presenta el
capítulo 9 y la cinemática de regreso a casa, que termina en el menú principal.

Los animales se identifican por su palabra maya. La ilustración, la frase
*In k'aaba'e' ___* y su traducción se leen de `GameManager`, así que un
animal nuevo solo necesita estar en `VOCABULARY` y en `BOOK_ILLUSTRATIONS`.

Las cinemáticas son escenas que heredan `story_scene.tscn`, usan solo momentos
`DIALOGO` con `auto_advance` y cambian el texto del nodo `UI/SkipButton` a
**Saltar cinemática ▶▶**. Se registran con claves `worldN_cineM`:

| Clave | Escena | Va después de | Continúa hacia |
|---|---|---|---|
| `world1_cine1` | `cine1_noche_huracan.tscn` | Introducción | `world1_explore1` |
| `world1_cine2` | `cine2_casa_maya_vacia.tscn` | Exploración 2 (camino a la Casa Maya) | `world2_level1` |
| `world5_cine1` | `cine3_regreso_a_casa.tscn` | Capítulo 9 | `main_menu` |

El último momento de una cinemática puede omitir `auto_advance` para esperar al
jugador antes de cambiar de escena.

Fondos y efectos nuevos (`Arte/backgrounds/` y `Arte/efectos/`) mantienen el
estilo del proyecto: SVG de 1280 × 720, formas planas, degradados suaves y una
viñeta ligera. Los fondos dejan libre la parte baja, donde va el cuadro de
diálogo, y la zona izquierda, donde está Kalin.

Para agregar un capítulo:

1. Duplica un capítulo existente de `scenes/worldN/`.
2. Edita sus momentos en el Inspector.
3. Registra la escena en `GameContent.SCENE_PATHS` con una clave `worldN_storyM`.
4. Cambia el `next_scene_key` del nivel anterior para que apunte al capítulo.
5. Agrega `story_key` al nivel siguiente en `LEVEL_ORDER` para que **Continuar** lo muestre.

## Exploraciones

Una exploración deja que el jugador camine con Kalin por un sendero lineal
antes de un capítulo. La plantilla es `res://scenes/features/exploration/exploration_scene.tscn`
(script `exploration_scene.gd`) y cada exploración la hereda sin script propio.
La primera es `scenes/worlds/world1/exploracion1_orilla_isla.tscn` (clave
`world1_explore1`): va entre `world1_cine1` y `world1_story1`.

Otras tres exploraciones repasan vocabulario maya con los mismos componentes.
Cada objeto con `vocabulary_word` añade al final de su diálogo la palabra, su
significado y la frase modelo, y el contador muestra «Palabras mayas: n / total».
Sólo repasan: no llaman a `learn_word` ni otorgan magia.

| Clave | Escena | Va entre | Palabras | Suelo |
|---|---|---|---|---|
| `world1_explore2` | `world1/exploracion2_camino_casa_maya.tscn` | Capítulo 5 y `world1_cine2` | `mayak`, `lak`, `k'áan`, `k'áanche'`, `janal` | tierra |
| `world3_explore2` | `world3/exploracion3_la_milpa.tscn` | Capítulo 7 y `world4_level1` | `ja'`, `ja'as`, `ich`, `K'úum` | pasto |
| `world4_explore1` | `world4/exploracion4_camino_portal.tscn` | `world4_mission1` y `world5_level1` | `Bix a beel`, `Yuum bo'otik`, `Ka xi'ik tech jats'uts`, `Tak ti' uláak' k'iin` | piedra |

`world3_explore1` es el paseo **Una aldea a su medida**; la milpa usa
`world3_explore2` para no compartir la clave semántica.

Estructura de la plantilla:

| Nodo | Uso |
|---|---|
| `Cielo` (`Parallax2D`) | Cielo y mar lejanos; con `scroll_scale` 0.15 se mueven más despacio que el terreno. |
| `Terreno` (`Sprite2D`) | Dibujo ancho por el que camina Kalin (`bg_isla_sendero.svg`, 3840 × 720). |
| `Sendero` (`Path2D`) | Línea por la que van los pies de Kalin. Sus extremos marcan dónde empieza y termina el recorrido. Si cambias el terreno, mueve sus puntos en el editor para que sigan el camino dibujado. |
| `Animales` | `Sprite2D` decorativos que saltan suavemente (por ejemplo, los animales que esperan en la meta). |
| `Spots` | Instancias de `exploration_spot.tscn`, una por objeto. |
| `Kalin` | Kalin con su `Camera2D` (los límites se calculan con el sendero) y las chispas de su magia. |
| `UI` | Título, botón para saltar, panel de objetivo con contador de descubrimientos, ayuda de controles, botón flotante «E · Examinar», flecha que indica el camino y cuadro de diálogo (arriba, para no tapar el sendero). |

En el Inspector de la exploración se configuran `chapter_title`,
`next_scene_key`, `objective_text`, `walk_speed` y, en **Entrada**, el diálogo
opcional con el que empieza (`intro_speaker`, `intro_lines`,
`intro_surprised`).

Cada `ExplorationSpot` define:

| Propiedad | Uso |
|---|---|
| `prompt` | Texto del botón: «Examinar», «Recoger», «Mover con magia», «Saludar»... |
| `speaker` | `Kalin`, `Narrador` o la palabra maya de un animal. |
| `lines` | Líneas de diálogo; cada una es un globo. |
| `surprised` | Kalin pone cara de sorpresa mientras habla. |
| `reach_radius` | Distancia horizontal desde la que se puede examinar. |
| `blocks_path` | Kalin no puede pasar hasta examinarlo. Debe usar la reacción `APARTAR`. |
| `is_goal` | Al terminar su diálogo la exploración continúa hacia `next_scene_key`. Debe haber exactamente una meta y ser el último punto del sendero. |
| `auto_trigger` | El diálogo se abre solo al llegar (útil para la meta). |
| `reaction` | `NINGUNA` (deja de brillar), `APARTAR` (la magia lo levanta y lo quita) o `RECOGER` (vuela hacia Kalin). |
| `vocabulary_word` | Clave del vocabulario canónico que Kalin anota al terminar el diálogo. Avisa en el editor si la palabra no existe. |

La exploración define además `footstep_surface` (categoría **Sonido**): `arena`,
`tierra`, `pasto` o `piedra` eligen los pasos de Kalin.

El dibujo va en el nodo hijo `Sprite` de cada instancia (activa **Hijos
editables**); su `offset` debe dejar la base del objeto en el origen para que
se apoye en el sendero. Los objetos sin examinar brillan con el nodo `Brillo`.

Para agregar una exploración:

1. Crea una escena heredada de `exploration_scene.tscn` en `scenes/worldN/` (o
   duplica `exploracion1_orilla_isla.tscn`).
2. Cambia las texturas de `Cielo/Imagen` y `Terreno`, y ajusta `Sendero`.
3. Agrega instancias de `exploration_spot.tscn` dentro de `Spots`, con una meta al final.
4. Regístrala en `GameContent.SCENE_PATHS` con una clave `worldN_exploreM`.
5. Cambia el `next_scene_key` de la escena anterior para que apunte a ella.

Arte de las exploraciones: el cielo (`bg_isla_cielo.svg`, 2560 × 720) debe ser
más ancho que la pantalla para el parallax; el terreno deja transparente la
parte alta para que se vea el cielo; los objetos viven en `Arte/exploracion/`.
Los fondos de aldea (`bg_aldea_encargos.svg` y `bg_aldea_portal.svg`) tienen
5120 × 720, con margen después del sendero. La cámara obtiene sus límites
horizontales del terreno, salvo que se hayan configurado explícitamente en el
Inspector. El fondo del portal se usa en la misión final; la visita de práctica
conserva la aldea habitual. Kalin se desplaza con saltitos usando su dibujo original.
Se mantiene el estilo de formas planas y degradados suaves. Para sombras y
transparencias usa `fill-opacity` en lugar de colores `rgba(...)`: el
importador SVG de Godot dibuja `rgba(...)` como negro sólido.

## Vocabulario

`GameContent.VOCABULARY` es la fuente única para traducción, emoji, estructura, mundo y nivel. Los scripts deben consultar `VocabularyCatalog.entry()` y `GameManager.has_learned_word()` en lugar de comparar directamente las claves guardadas.

El guardado acepta sólo las claves canónicas del catálogo vigente. Las consultas toleran mayúsculas y acentos; no mantienen equivalencias con identificadores retirados. Las decisiones y excepciones provenientes del GDD están documentadas en [docs/vocabulary.md](vocabulary.md).

## Guardado

El progreso se guarda automáticamente como `user://kalin_save.json`. Incluye:

- versión del formato;
- puntos mágicos;
- palabras aprendidas;
- identificadores `w<numero>_l<numero>` de los niveles completados;
- escena pendiente, estado de cada escena y tutoriales ya practicados.

**Volver a empezar** pide confirmación antes de eliminar la partida. `SaveSchema.CURRENT_VERSION` fija el único formato admitido (**9**). Los formatos anteriores o futuros se rechazan sin sobrescribir el archivo; el menú permite reiniciarlo. Un archivo dañado puede recuperar el respaldo del formato vigente. No hay migraciones ni inferencia de niveles desde vocabulario.

Para una escena nueva, implementar `get_checkpoint_state() -> Dictionary` y restaurar con `GameManager.get_scene_state(self)`. Guardar tras acciones completas mediante `GameManager.checkpoint(self)`. La navegación y el cierre de ventana capturan también el estado actual. Usar `GameManager.replay_scene()` para repetir desde el principio sin borrar los logros. El libro usa `PROCESS_MODE_ALWAYS` mientras pausa el árbol; los temporizadores de un ejercicio deben respetar esa pausa.

Taller y Comida usan `PhraseExerciseSession`: cada episodio nuevo presenta hasta
tres retos y luego pide su recuerdo. La cantidad de rondas sigue siendo dos por
reto. El checkpoint guarda el plan completo `challenge` / `guided`; no se deben
inferir modalidades a partir de la mitad del nivel ni reordenar un plan ya iniciado.
Los límites de modalidad y el contador del episodio se consultan al dominio.

## Libro y pronunciaciones pendientes

La presentación del libro se controla desde `scripts/features/spellbook/book_motion.gd`:
apertura de 0.49 s y cierre de 0.44 s. `libro_hechizos.gd` anima páginas
y pestañas en 0.25 s, administra el foco y conserva la pausa hasta terminar
el cierre. Al abrirlo desde una interfaz nueva, pasar el botón real con
`libro.show_book(boton)` para que el viaje de ida y vuelta use su posición.
Los efectos visuales no se guardan como progreso.

La música, los ambientes y los efectos ya están integrados (ver
[Música y efectos](audio.md)). Las pronunciaciones todavía no están grabadas; el
reproductor del libro usa el bus `Voces`. Cuando estén disponibles, colócalos en `Arte/audio/` como archivos OGG. Los nombres técnicos eliminan acentos, apóstrofes y espacios para que sean portables entre sistemas. La tabla completa está en [Arte/audio/README.md](../Arte/audio/README.md).

El botón permanece disponible: sin archivo muestra un aviso silencioso; con
archivo reproduce la grabación. Cambiar de página o cerrar detiene la voz.
La prueba `tests/validate_book.gd` comprueba pausa, foco, interrupciones,
botones de origen, numeración y audio pendiente. Acepta
`-- --capture=<carpeta absoluta>` con renderer real para guardar capturas.

## Comprobación antes de integrar cambios

La validación automática de catálogo, rutas, escenas, tableros, alias y nombres de audio se ejecuta desde la raíz con:

```powershell
.\tools\validate.ps1 -GodotPath "C:\ruta\a\godot_console.exe"
# Opcional: ejecutar una sola suite con el mismo aislamiento.
.\tools\validate.ps1 -GodotPath "C:\ruta\a\godot_console.exe" -Suite validate_project
```

`validate_project.gd` revisa también que cada exploración tenga sendero, objetos
con diálogo y dibujo, una sola meta al final y las acciones de entrada.
`validate_learning_flow.gd` recorre la exploración de la orilla: el diálogo de
entrada detiene a Kalin, el tronco no deja pasar hasta examinarlo y llegar a la
aldea lleva al Capítulo 1.

1. Abrir el proyecto con Godot 4.6 y comprobar que no existan errores de análisis.
2. Completar la introducción y comprobar que **Saltar intro** sólo aparece al repetirla.
3. Recorrer la exploración de la orilla con teclado y con clic, y comprobar que termina en el Capítulo 1.
4. Completar al menos un nivel de cada mundo.
5. Volver al menú entre niveles y comprobar **Continuar**.
6. Cerrar y abrir el juego para verificar el guardado.
7. Repetir el Mundo 4 con las palabras ya aprendidas.
8. Completar el Mundo 5 y confirmar que el portal llegue al 100 %.
9. Abrir el libro y comprobar ilustraciones, pausa del ejercicio y navegación por páginas.


## Interfaz compacta y ampliación de la aventura

Los perfiles de `data/layouts/` ajustan rectángulos y tipografía al modo compacto
sin sustituir los nodos guardados en las escenas. El componente `ScreenLayout`
permite activar `preview_compact` al ejecutar para comprobar esta composición.
La tarjeta de los animales hereda su distribución de `grid_path_level_base.tscn`:
ilustración a la izquierda, frase y traducción a la derecha, y Continuar debajo.
El rectángulo compacto de ese botón en `data/layouts/grid.tres` es relativo a la
tarjeta. `validate_grid_dialogue_layout` comprueba las zonas después de escribir
cada nombre y al alternar los perfiles; admite capturas mediante el ejecutor.
`RecallPanel` usa una plantilla `recall_fragment.tscn` para los bloques variables.

Los controles creados después de montar una interfaz se registran mediante
`ScreenLayout.register_controls(contenedor)`. Así las fichas y los botones dinámicos
reciben la tipografía y el tamaño mínimo del mismo perfil, conservando su base de escritorio.

Los encargos tempranos heredan `mision_encargos_aldea.tscn`: se editan seis recursos
`VillageTask`, agrupados en tres parejas por destinatario. Los encargos comienzan
por escritura y activan completar y bloques después de los errores. Se reutilizan las combinaciones ya
registradas en el vocabulario. La despedida se configura con tres `ExerciseEntry`
en `despedida_los_recuerdos.tscn`.

Sus opciones conocidas muestran significado y permiten elegir qué expresar, sin
otra respuesta obligatoria después del portal. Los recuerdos de cada amigo se
derivan de las entregas confirmadas mediante `VillageMemory`; el texto `translation`
del recurso es la alternativa cuando no hay una entrega suya. Evitar que esa
alternativa afirme objetos, cualidades o destinatarios que pueden variar.

Ejecutar `tools/validate.ps1` antes de integrar cambios. El detalle del recorrido,
los contextos semánticos y el guardado vigente están en
[docs/adventure.md](adventure.md).

## Ayuda de depuración para contestar

`DebugAnswer` conserva F4 para responder. F3 muestra u oculta su botón flotante;
empieza oculto para no cubrir los controles durante el juego. Consulta los
métodos `debug_can_answer()` y `debug_answer()` de la escena actual. Cada escena
usa sus respuestas de contenido (incluidas las variantes barajadas), marca el
intento como apoyado y llama al mismo envío que utiliza el jugador. No cambia
de nivel ni adelanta el resultado. En Las piedras que cuentan forma el número
sorteado en la tablilla y lo comprueba. `RecallPanel.debug_fill()` conserva el modo
de escritura, completar o bloques.

Para añadir ejercicios, implementar ambos métodos y bloquearlos con
`OS.is_debug_build()`. El autoload vuelve a comprobar disponibilidad al pulsar;
rechaza escenas en transición y la pausa, que también usa el libro. En Release
se elimina antes de crear interfaz; en exportaciones Debug permanece activo.
`tests/validate_debug_answer.gd` comprueba F4, botón, todas las familias de
actividad y que estas respuestas no generen evidencia de recuerdo sin ayuda.

## Casillas y apoyos automáticos

`RecallPanel.advance_support()` pasa de escritura a huecos que conservan lo acertado.
`SpellingCorrection` alinea letras, omisiones y sobrantes; `SpellingField` presenta sólo
las partes editables. Cada comprobación que corrige al menos una parte mantiene
los huecos; sin progreso nuevo pasa a bloques. El foco vuelve a la primera parte
pendiente. `scaffold.corrections` conserva valores, posiciones y partes protegidas,
validados contra la respuesta actual. `ready_to_submit()` evita evaluar respuestas
completamente vacías o bloques incompletos.
Los controladores llaman estos métodos en su validación habitual; no hay cambio de
modalidad accesible al jugador. Las tarjetas de presentación inicial se mantienen.

`RecallFragment` representa piezas y casillas. Cada fragmento tiene un identificador
estable, incluso si dos textos son iguales. `move_fragment()` intercambia posiciones,
`return_fragment()` devuelve al banco y `RecallBlockBank` admite arrastres de retorno.
El estado guarda matrices de identificadores y huecos (-1), validadas para impedir
duplicaciones o índices inválidos. `show_result()` reutiliza el panel para el acierto.
Los bloques utilizados quedan atenuados en el banco, conservando su sitio; pulsarlos
los devuelve. La vista previa de arrastre usa un contenedor con la pieza centrada.
`validate_block_interactions.gd` comprueba las transiciones, entrada nativa de arrastre,
intercambio, devolución, guardado, evidencia independiente, peticiones y profundidad.

`VillageTaskVariation.distinct()` compara las combinaciones de las tres parejas de
necesidades. Prioriza objetos distintos y después conserva las preferencias de azar
o aprendizaje. Las peticiones abiertas, conocidas y resueltas no se modifican al cargar.
Si el contenido futuro no ofrece tres objetos distintos, selecciona la combinación
con menos repeticiones, sin bucles de reintento.

Las misiones tempranas sobrescriben `Spots/Salida` para representar el siguiente
destino de la historia: entrada al taller tras Rincones para compartir y la casa
del escenario tras la fiesta. El portal de la misión base sólo corresponde al
tramo posterior a la comida. `completion_objective` configura el aviso al terminar
los tres encargos, independientemente del diálogo y la ruta de salida.

## Mesa de composición y habitantes

`RecallPanel` muestra una sola representación editable de cada respuesta.
Las tarjetas usan destinos contenidos en su franja; el resultado ilustrado aparece
después de confirmar. El modo de bloques conserva su tablero independiente.

`VillageResidents` selecciona tres destinatarios entre los doce animales presentados
y añade tres vecinos para saludar. Instalarlo antes de `ExplorationScene._ready()`
permite restaurar también las conversaciones de esos vecinos. `residents` es un campo
del guardado vigente; reanudar conserva los dueños de sus encargos.
La despedida mantiene sus tres amigos narrativos y añade vecinos del mismo catálogo.

Las viviendas de `Arte/aldea/` y los fondos sin casas incrustadas son SVG editables
y no dependen de servicios externos. Añadir un animal requiere su ilustración, saludo y casa en `VillageResidents`;
el vocabulario marcado como futuro queda excluido.

`MeaningIllustration.world_object` separa el mobiliario del mundo de los ejemplos de
comparación. `picture_rect()` devuelve el área real de la textura ajustada; las poses
de `VillageUseMotion` utilizan esa área para centrar y escalar al ocupante. No se debe
volver a animar la escala del mueble durante la celebración, pues separaría su pose.
`validate_village_life.gd` verifica estos contratos y genera capturas con
`-- --capture=<carpeta absoluta>` sin `--headless`.

## Editar las frases de la aldea

Editar `data/dialogue/village_dialogue.json` y regenerar con
`python tools/build_combination_dialogue.py`; no editar el módulo generado
`scripts/features/village/data/village_dialogue_catalog.gd`. El banco organiza los textos por nombre
del animal. `greetings` contiene sus quince saludos y `after_help`, diez comentarios
para conversaciones posteriores a resolver su encargo. Ambos bancos contienen frases
propias del habitante, únicas, completas y de hasta 160 caracteres. Los comentarios
no suponen un objeto concreto ni acontecimientos futuros: se comparten entre sus pedidos.
`tasks` usa la clave `objeto|cualidad` (por ejemplo, `mayak|nojoch`); cada entrada
contiene dos bancos explícitos: `requests`, con tres peticiones, y `thanks`, con dos
agradecimientos. Cada frase debe aportar un motivo o resultado propio del habitante;
mantener las tres peticiones igualmente claras sobre el objeto y la cualidad, sin
añadir palabras mayas nuevas. El generador rechaza bancos incompletos, duplicados,
campos inesperados, textos vacíos o de más de 160 caracteres y pedidos fuera del
catálogo cerrado. Las nuevas combinaciones generadas requieren revisión editorial.

`VillageDialogue.personalize()` aplica el texto a las copias del recurso en paseos
y misiones. La semilla, escena, animal y pedido fijan las variantes durante la visita.
Peticiones y agradecimientos usan claves de selección independientes: las tres
peticiones pueden combinarse con cualquiera de los dos agradecimientos. Consultar
el encargo otra vez, fallar una respuesta o reanudar no vuelve a elegir sus textos.
Ambos se reconstruyen desde la semilla guardada; los bancos son configuración y no
añaden campos al formato de partida ni cambian la respuesta esperada del encargo.
No modificar el texto desde el diálogo o las tarjetas del taller: ambos leen el mismo `VillageTask`.
Para añadir un pedido, cubrirlo para todos los habitantes y ejecutar
`validate_village_dialogue.gd`; la prueba detecta combinaciones sin personalizar.

El nodo `VillageDialogue`, instalado por `VillageResidents`, rota los saludos al
cerrar la conversación. `ExplorationScene` guarda sus contadores por animal en
`greeting_visits`. Los vecinos muestran un saludo; los amigos que ya recibieron
su encargo muestran un saludo y un comentario de `after_help`, sin repetir siempre
el agradecimiento de la entrega. Cada banco se baraja con una semilla propia y se
recorre completo antes de repetir. El contador se acota al producto de los tamaños
de ambos bancos para no interrumpir sus ciclos cuando tienen longitudes distintas.
Abrir o reanudar una conversación no avanza el contador; continuar conserva sus dos
textos y la línea abierta. Se mantiene el campo numérico vigente del guardado.
Las peticiones pendientes y el agradecimiento de la entrega conservan su texto.
Los amigos de la despedida conservan sus peticiones narrativas; sus vecinos sí
utilizan este banco.

Las 37 combinaciones por doce habitantes cuentan con tres peticiones y dos
agradecimientos cada una. Se conservan las frases previas y se añaden 888 textos:
una petición y un agradecimiento por pareja de habitante y pedido. Las nuevas
peticiones proponen usos distintos, como dibujar, ordenar hojas o escuchar cuentos;
Kay mantiene los muebles y la merienda en tierra para sus visitas de la orilla.
Para futuras ampliaciones, priorizar nuevos motivos frente a reformular la misma
petición cambiando sólo su orden. La suite recorre todas las variantes, sus seis
emparejamientos, la reanudación y el ajuste de los textos en escritorio y compacto.

## Poses y capas de los resultados

`VillageUseArt` referencia los SVG editables de `Arte/aldea/uso/`. Las nueve variantes
del catálogo ampliado se regeneran con `python tools/build_combination_art.py`. El arte original del catálogo se conserva
para los ejercicios. En el escenario, `MeaningIllustration` representa la hamaca
con fondo y frente separados; utiliza adornos propios para bonita/fuerte y aroma
para deliciosa. `VillageUseMotion` coloca al ocupante entre esas capas o al lado
del objeto y calcula su apoyo a partir del área visible de la textura.

En cada grupo, el respaldo queda detrás del animal y el tejido frontal de la
hamaca delante. El conjunto usa la profundidad de su apoyo en el suelo para
intercalarse con Kalin. Kay conserva su estanque. Durante el consumo terrestre,
el recipiente y su soporte sustituyen el tapete; la porción permanece servida
o se une a la mano de Ma’ax. `WorldMat` conserva el apoyo de los objetos mostrados
fuera de ese gesto; `WorldFront` sólo aparece con la hamaca.

Los iconos de tamaño usan una sola figura y una regla neutra, sin copias tenues
ni señales de acierto. La figura debe coincidir con el ejemplo canónico del libro.
Fuerte muestra el mueble reforzado, sin añadirle una piedra.

`validate_village_composition.gd` revisa todas las combinaciones y el regreso desde
JSON. Ejecutarla con `-- --capture=<carpeta absoluta>` y renderer real para revisar
las 37 láminas del atlas y las capturas en contexto después de cambiar un SVG.

## Ampliar las combinaciones permitidas

Editar la lista cerrada de `scripts/core/content/combination_catalog.gd`, no formar parejas
arbitrarias. Actualmente incluye 28 combinaciones y nueve peticiones simples.
`CombinationVariation` selecciona seis retos de taller/comida y tres necesidades
por visita, conservadas como claves semánticas en el checkpoint. El Inspector de
Taller y Yo quiero permite desactivar `vary_combinations`; los recursos alternativos
de ejercicios conservan sus retos de autor.

Para una combinación nueva, añadir o revisar sus textos para los doce animales en
`data/dialogue/village_dialogue.json` y su representación en `VillageUseArt`.
`python tools/build_combination_dialogue.py` conserva las frases existentes y añade
las ausentes a partir de los contextos propios de cada animal y objeto; revisar el
resultado editorialmente. El catálogo contiene 1.332 peticiones, 888 agradecimientos,
180 saludos y 120 comentarios posteriores a ayudar. Ejecutar `tools/validate.ps1` y
revisar el atlas renderizado después de cambiar textos, cualidades o SVG. Los
guardados pendientes anteriores no se sustituyen.

## Interfaz y actividades de la aldea

`Arte/ui/request_stage.svg` proporciona el globo de la petición sobre los fondos
actuales. Taller y comida usan campos verticales y composición compacta; los perfiles
de distribución mantienen sus posiciones por fase. El libro mantiene el ejemplo, sellos ilustrados en sus bordes y pronunciación circular. El detalle de práctica se conserva en el registro, sin un botón dentro de las páginas infantiles.

`VillageWalk.interpret_requests` activa las fichas mayas y la traducción opcional.
Las respuestas conservan significado e ilustración. Las fichas representan contenido
canónico conocido, sin añadir ni validar una gramática nueva.

El acceso **Mi aldea** lleva al espacio persistente. La mesa de trazos del taller
permite experimentar con combinaciones aprendidas. `gathering_title` configura
la celebración conjunta de cada misión. El SVG
`Arte/ui/village_gathering.svg` y los tres personajes reutilizan el arte plano del
juego. Cerrar confirma `gathering_seen`; reanudar una celebración pendiente puede
volver a mostrarla, sin acreditar de nuevo las entregas. La recepción se anima sólo
al entregar; restaurar carga directamente las poses de uso.

## Autoría de la continuación

### Favoritos y colocación desde la mesa de trazos

Tras probar un hechizo conocido, **Guardar favorito** conserva esa combinación para
ensayarla de nuevo. **Comparar con esta** fija una referencia ilustrada mientras se
elige y prueba otra variante; **Dejar de comparar** la retira. Sólo los favoritos
se guardan entre visitas. Estas acciones no acreditan recuerdo ni puntos.

`SpellLaboratory.profile` permite sustituir
[laboratory.tres](../data/village/laboratory.tres). `favorite_limit` ofrece inicialmente
seis espacios, entre uno y doce; reducirlo no borra favoritos guardados. Retirar uno
sigue disponible aunque la capacidad esté llena. No modificar el recurso compartido
en ejecución ni añadir parejas fuera del catálogo para crear preferencias.

**Colocar en mi jardín** abre directamente la vista previa del editor en el barrio
visitado si ya se tienen los diseños. Si falta alguno, **Revisar compra…** muestra
qué falta, el precio individual, el total y el saldo. **Confirmar compra** adquiere
una sola vez todos los diseños faltantes; **Volver al ensayo** o Esc cancela la
confirmación. El ensayo sigue gratis con saldo insuficiente. Antes del primer
rincón se conserva la preparación de Mesa y Fuerte y la protección de su presupuesto.

La compra no fabrica muebles. Enter o **Colocar** confirma una posición válida;
Esc descarta la vista previa y **Deshacer** retira la copia confirmada, conservando
los diseños. El límite global incluye jardín y almacén. Guardar o cerrar con una
copia provisional no la añade al archivo; reabrir permite elegirla de nuevo.
Un fallo al guardar la compra o un favorito conserva saldo y preferencias anteriores.

El cuerpo del laboratorio tiene desplazamiento con seguimiento del foco y mantiene
sus acciones principales visibles. El perfil
[spell_laboratory.tres](../data/layouts/spell_laboratory.tres) conserva los ajustes
compactos. `validate_laboratory_state` comprueba datos y operaciones atómicas;
`validate_spell_laboratory` recorre interfaz, fallos, continuación y ambos perfiles,
y admite capturas mediante el ejecutor aislado con `-CaptureDirectory`.

### Nombre, adornos, almacén y acomodos

Desde **Mi jardín**, **Nombre y adornos** abre un borrador del nombre de esa parcela
y de sus detalles. **Guardar mi rincón** confirma; volver o Esc descarta el borrador.
El nombre admite hasta 32 caracteres, no cambia claves del juego y puede elegirse
antes de terminar un proyecto. Su presentación en el mundo admite dos líneas y
el campo de edición conserva el texto completo.

Terminar **Un lugar para descansar** habilita letrero de bienvenida, borde de flores
y guirnalda de reunión. Se eligen gratuitamente y por parcela, sin otra tienda ni
premios por decorar. La guirnalda original aparece al confirmar el proyecto aunque
el patio ya tuviera nombre; después puede retirarse sin borrar el proyecto vivido.

`VillageHome.garden_profile` permite sustituir
[garden.tres](../data/village/garden.tres). Configura los títulos, las texturas del
letrero y del borde, sus rectángulos y el rectángulo del nombre. Los SVG editables
están en `Arte/aldea/garden_sign.svg` y `Arte/aldea/garden_border.svg`; la guirnalda
mantiene la configuración de `rest_profile`. `configuration_issues()` revisa campos
obligatorios y límites. Los adornos son presentación y no añaden obstáculos al suelo.

**Acomodos y copias** explica el límite de 80 copias compartido por los tres jardines
y el almacén. Mover o guardar no libera capacidad. La lista identifica cada copia
por número, variante y ubicación. **Eliminar copia** exige confirmación y conserva
el diseño comprado. Una mesa con plato requiere retirar primero el plato; el dominio
también protege las referencias de invitados. Entrar a editar conserva el cierre
seguro de las visitas vigente.

Cada parcela ofrece dos espacios de acomodo. **Guardar aquí** pide confirmación
antes de guardar o sustituir el espacio: sólo incluye muebles colocados, con sus
IDs, giros y superficies. **Restaurar** reutiliza esas mismas copias y lleva al
almacén las que sobren en esa parcela. Si una pieza falta, tiene otra clave o una
mesa mantiene un plato ajeno, se muestra el motivo y no se aplica ningún cambio.
Los acomodos históricos permanecen al eliminar una pieza; deshacer la eliminación
puede volver a habilitarlos. No se busca otra copia parecida para sustituirla.

`composition_slots` ofrece entre uno y dos espacios. Reducirlo no borra los ya
guardados: permite restaurarlos, pero sólo guardar en los espacios ofrecidos.
**Deshacer última edición** recupera el jardín anterior durante la visita actual;
no se conserva al cerrar el programa o cambiar de escena. Fallar una escritura
conserva también esa posibilidad de reintento. Los IDs emitidos no se reutilizan
al deshacer, para que un acomodo no termine apuntando a una copia distinta.

`garden_identity` y `garden_compositions` son campos opcionales del formato 9.
`validate_garden_designs` verifica su validación anidada, conjuntos y límites;
`validate_garden_personalization` recorre la interfaz, fallos de guardado, foco,
pausa, carga y ambos perfiles. Admite capturas con el ejecutor aislado y
`-CaptureDirectory`, como las demás suites de presentación.

### Invitaciones al rincón

Una mesa colocada en el patio ofrece **Invitar a un amigo** al acercarse por
teclado o al pulsarla. Durante la aventura se puede invitar a Áak o Miis si ya se conocen.
La visita es gratuita, termina sola y se puede repetir. También se puede despedir
antes; editar el jardín o cambiar de barrio la termina de forma segura.

El recurso [village_visit_profile.tres](../data/village_visit_profile.tres) configura
la duración activa (18 segundos inicialmente, entre 8 y 120 en el Inspector) y
una reacción por invitado. Puede personalizarse desde `VillageHome.visit_profile`
sin modificar el recurso compartido durante una sesión. Pausa, mapa, libro y
paneles detienen el reloj. Reanudar conserva el tiempo restante y muestra el uso
estable, sin volver a representar la llegada ni acreditar aprendizaje.

La compatibilidad es una mesa de cualquier variante canónica en el patio, con
lateral y ruta libres. Tras el regreso narrativo, el panel agrupa por barrio a los
once vecinos terrestres conocidos. Kay recibe su merienda desde el estanque.
Los diseños y las copias conservan sus reglas vigentes. Ampliar tipos de soporte
requiere revisar la ruta, la pose, el apoyo y su validación.

`validate_village_visit_state` comprueba estado, referencias y tiempo;
`validate_village_visits` recorre la interfaz, las actuaciones y la continuación.
La segunda admite capturas con el ejecutor aislado:

```powershell
.\tools\validate.ps1 -GodotPath $env:GODOT_BIN -Suite validate_village_visits -CaptureDirectory "$PWD/.ui-review/village_visits"
```

### Proyecto posterior al regreso

Después de confirmar el regreso a casa, el menú ofrece **Volver a mi aldea** y
anuncia **Un lugar para descansar**. En el patio, su botón o hablar con Áak o Miis
abre la invitación. No se abre automáticamente al entrar. Repetir la aventura
conserva el permiso de visita obtenido al vivir el cierre.

El recurso [rest_corner.tres](../data/village/rest_corner.tres) se puede sustituir
desde `VillageHome.rest_profile`. Incluye tres momentos de invitación, alternativas
de mesa/silla/hamaca, sus descripciones y reacciones de Áak y Miis, una conversación
posterior y la posición de la guirnalda. `configuration_issues()` comprueba cobertura
y textos breves. Las identidades de objeto proceden del vocabulario vigente; no
se editan para introducir una cuarta alternativa sin sus reglas y pruebas.

**Ir a las opciones** permite probar de inmediato y enfoca la primera opción
disponible. **Continuar** mantiene el avance de la invitación línea por línea.
Probar es gratuito y temporal; confirmar no compra muebles ni acredita escritura.
La decoración propia sigue usando diseños y el presupuesto protegido del rincón
inicial. Los diálogos avanzan manualmente. Cerrar con Esc o salir conserva el
momento y la elección. Las reacciones pendientes de lectura se retoman al abrir;
volver a disfrutar del resultado no lo acredita otra vez.

La guirnalda de `Arte/aldea/corner_garland.svg` aparece en el patio al confirmar y
su visibilidad se reconstruye desde el proyecto, sin otra bandera de recompensa.
El recuerdo elegido en la despedida de la aventura mantiene su contrato propio.

`validate_rest_corner_state` verifica el cierre real, alternativas, apoyos,
economía saturada y rechazo atómico de cargas. `validate_rest_corner` recorre menú,
lectura, prueba, confirmación, edición, retorno y perfiles de distribución. Admite:

```powershell
.\tools\validate.ps1 -GodotPath $env:GODOT_BIN -Suite validate_rest_corner -CaptureDirectory "$PWD/.ui-review/postgame_pg2"
```

### Peticiones de la sala de retos

`VillageHome.challenge_profile` permite sustituir
[challenges.tres](../data/village/challenges.tres). Sus textos describen la bienvenida
y las consecuencias de identificar un animal, conversar, preparar un pedido o
describir una cualidad. El vocabulario y las parejas proceden de los catálogos
vigentes; el perfil no incorpora otro catálogo de respuestas.

La tanda conserva las parejas y los visitantes concretos. Áak y Miis sólo aparecen
si ya se conocen y no son la respuesta esperada; en los demás casos acompaña Kalin.
Antes de responder se ve al interlocutor, sin el objeto o animal que resolvería
la petición. Tras confirmar aparece el resultado, también al usar ayudas o tener
el premio saturado. Esc y **Salir y guardar** conservan borrador, bloques y apoyos.
El área de respuesta admite desplazamiento con seguimiento del foco para que
las frases largas y sus piezas sigan accesibles en el perfil compacto.

**Llevar al rincón** aparece únicamente si el resultado confirmado corresponde
al mueble ya elegido para el proyecto pendiente. Se puede colaborar con apoyo;
confirmar sigue siendo voluntario y la vía directa del proyecto permanece libre.
No es una entrega de un mueble propio ni añade otra recompensa lingüística.

`validate_challenge_planner` cubre distribución e identidad semántica.
`validate_challenge_room` comprueba continuidad, apoyos, resultados, colaboración
y límites económicos, y admite capturas con el ejecutor aislado:

```powershell
.\tools\validate.ps1 -GodotPath $env:GODOT_BIN -Suite validate_challenge_room -CaptureDirectory "$PWD/.ui-review/postgame_pg3"
```

### Merienda junto al estanque

Tras el regreso narrativo, la orilla ofrece **Merienda junto al estanque**.
Elige a Kay, a Ch'íich' o a ambos si ya se conocen, una merienda presentada y un
rincón sencillo o con flores. **Preparar estas cantidades** fija la selección.
Antes de iniciarla, cerrar descarta el borrador sin coste; si falla una escritura,
se conserva la elección o preparación ya confirmada y se puede reintentar.

El plan pide una ración de cinco bocados por invitado: primero una o dos raciones,
después cinco o diez bocados. La tablilla reutiliza puntos, barras, concha y dos
pisos. **Pista** explica el reparto; pedir más apoyo prepara el numeral para que el
jugador lo confirme. No exige velocidad ni escritura independiente. Los apoyos,
errores, cantidades y respuestas confirmadas se conservan al salir y cargar.

**Reunirnos** confirma el proyecto después de preparar ambas cantidades. Kay come
desde el agua y Ch'íich' utiliza su cuenco; la provisión es temporal y funciona con
saldo cero y almacén lleno. El adorno cambia la escena y los datos de su recuerdo.
**Volver a reunirnos** representa la misma elección gratuitamente, sin repetir
premios, añadir muebles o alterar el registro de palabras.

`VillageHome.snack_profile` permite sustituir
[snack.tres](../data/village/snack.tres): título, invitación, reacciones, borde de flores
y tamaño de la composición. El reparto y las meriendas pertenecen a los catálogos
cerrados de `SnackState`; no añadir otro invitado sin su actuación y validación.
`configuration_issues()` comprueba los textos y el arte necesarios. El campo opcional
`snack_project` mantiene compatibilidad dentro del formato 9, sin migraciones.

### Familias de práctica y modo mixto

La **Sala de retos** abre una selección voluntaria de palabras, cantidades,
caminos o mixto. Palabras conserva las peticiones y apoyos existentes. Cantidades
se habilita tras **Las piedras que cuentan** y ofrece dos números; su recurso
[practice_counting.tres](../data/village/practice_counting.tres) configura la tanda.
Repetir es gratuito y presenta el plan en el otro orden.

Caminos propone ayudar a un animal conocido a venir a la merienda. Toca casillas
vecinas desde su ficha hasta la estrella, o mueve el foco con flechas y pulsa Enter.
Las cruces son rocas. Volver a la casilla anterior recorta; tocar la ficha reinicia.
**Mostrar ruta de apoyo** dibuja círculos sobre una solución revisada, sin resolver
el tablero por el jugador. Los borradores guardan variante, animal, cursor, trazo,
llegada y uso del apoyo. No se generan geometrías nuevas fuera del catálogo.

Mixto alterna las familias disponibles al confirmar el cierre de una tanda o camino.
Salir conserva la siguiente familia; no obliga a realizar las tres. Cada actividad
mantiene su propio borrador. Las cantidades y caminos no acreditan evidencia de
palabras ni puntos lingüísticos; palabras conserva sus contratos de aprendizaje.

El libro está disponible durante las actividades. Al cerrarlo se conserva la pausa
y el foco del panel de origen. **Salir y guardar** o Esc regresa a la aldea; con el
libro abierto, Esc cierra primero el libro. Los botones de comprobar, continuar y
apoyo permanecen visibles mientras el contenido central admite desplazamiento.

`validate_snack_state` verifica planes, límites, datos anidados, confirmación,
recuerdos y restauración de caminos. `validate_postgame_snack` recorre preparación,
reunión, contactos, libro, carga real y alternancia de familias; admite capturas con
el ejecutor aislado y `-CaptureDirectory` en escritorio y compacto.

### La aldea que imaginamos

Después de terminar el descanso y la merienda, la orilla ofrece **La aldea que
imaginamos**. Prueba **Descanso compartido** y **Reunión de merienda**; cada botón
representa la alternativa y la deja elegida. Marca uno o dos invitados entre
Ma'ax, Áak y Miis, si se conocen. **Inaugurar el claro** confirma el estreno y abre
el terreno seco conectado a la orilla. Si hay muebles bloqueando su entrada, hay
que apartarlos desde el editor antes de inaugurar; la decisión permanece guardada.

El claro tiene su propio letrero, accesible a pie o con clic, y aparece en la
tarjeta de la orilla del mapa. Al volver no hay que preparar cantidades otra vez.
**Cambiar a…** redecora gratuitamente; las casillas permiten invitar a otro grupo
y **Reunirnos otra vez** representa su uso. El recuerdo del estreno conserva el
propósito y los participantes originales. Los asientos y alimentos de la reunión
son temporales, independientes de tus muebles; funciona con saldo cero y almacén
lleno. Libro, Esc, teclado, movimiento reducido y los dos perfiles siguen disponibles.

Autoría espacial en [spaces.tres](../data/village/spaces.tres), mediante recursos
`VillageSpaces` / `VillageSpace`. Editar por barrio `floor_bounds`, `plot`,
`obstacles` y `arrival`; en la orilla, `extension_plot`, `extension_entry`,
`extension_anchor`, `guest_anchors` y `use_clearance`. La entrada debe solaparse con
el suelo y la ampliación. Los invitados deben quedar dentro de la parcela nueva;
la interacción puede situarse en la entrada. Todas las anclas necesitan rutas
libres. El editor comprueba la huella entera; protege el espacio de
uso y rechaza cambios que cierren el acceso. Los platos se desplazan con su mesa.
`configuration_issues()` comprueba la geometría y la suite verifica las rutas.
Cambiar geometría exige revisar también los jardines persistidos y sus acomodos;
no editar sólo el dibujo del terreno.

`VillageHome.expansion_profile` permite sustituir
[expansion.tres](../data/village/expansion.tres): título, invitación, objeto de
descanso, nombres y descripciones de propósitos, reacciones, color y borde. La
comida procede de la merienda confirmada. Los actores usan las mismas poses y
contactos de la aventura; ampliar el reparto exige revisar su actuación.

`village_expansion` es opcional en el formato 9. Guarda pruebas, propósito, grupo,
confirmación y `opening`, sin nodos ni tiempos de animación. Las decisiones se
persisten antes de anunciar éxito; si falla una escritura, el panel restaura la
elección anterior. Cargar no inaugura ni entrega premios. `validate_village_expansion`
cubre estado, rutas, capacidad, parcelas y recuerdos; `validate_postgame_expansion`
recorre libro, teclado, estreno, visitas posteriores, rediseño, mapa y carga real,
con capturas de escritorio y compacto mediante el ejecutor aislado.

### Álbum personal y composición de fotos

Después de una invitación a la mesa o de confirmar el descanso, la merienda o
el estreno del claro, usa **Componer foto**. En la barra de aldea, **Álbum**
permite volver a las fotos guardadas o componer la última invitación de esta
visita aunque ya se haya despedido el invitado. El álbum aparece después del
regreso narrativo y también al invitar a alguien durante una visita anterior al
regreso. El borrador se descarta al cerrar.

Escribe un título breve de hasta 32 caracteres, elige un encuadre abierto o
cercano y quién de los invitados compatibles sale. **Saludo** y **Compartiendo**
fijan poses. Con movimiento normal, **Ver movimiento** permite recorrer la
actuación y desmarcar la opción para congelar el instante visible. Con movimiento
reducido se puede elegir directamente una pose. **Vista limpia** amplía el
mismo encuadre. Pulsa Esc, Enter o toca la imagen para volver a los controles.

**Guardar foto** agrega la composición al álbum. Si los doce espacios están
ocupados, elige qué foto quieres sustituir y confirma. También puedes elegir
**Sustituir…** con espacios disponibles. **Borrar foto…** pide su
propia confirmación. Después de un error de escritura, se puede reintentar la
operación con el álbum anterior disponible. La galería y sus acciones admiten
teclado; al cerrar vuelve el foco a la entrada del álbum o del proyecto.

La presentación reusa los perfiles de jardín, descanso, merienda y ampliación
de `VillageHome`, con recursos y catálogo vigentes. `validate_personal_album`
comprueba capacidad, copias y rechazo de datos anidados.
`validate_postgame_album` recorre las cuatro fuentes, reanudación, cambios del
jardín, teclado, movimiento reducido, fallos y confirmaciones. La suite admite
capturas de escritorio y compacto con el ejecutor aislado y `-CaptureDirectory`.

### Vecinos, encuentros y regreso libre

La entrada de aldea y el **Mapa** presentan una oportunidad breve. Puedes seguir
caminando, entrar al jardín o usar cualquier otro acceso. Acércate al letrero
**Encuentro** para conversar, o abre el destino desde el mapa. Cada línea avanza
con **Continuar**. La última permite terminar o aceptar la actividad propuesta.
**Seguir paseando** y Esc conservan la línea disponible para retomarla. Volver a
cargar la aldea conserva la selección y no abre una ventana.

`VillageHome.neighbour_profile` permite sustituir
[neighbours.tres](../data/village/neighbours.tres). Cada `PostgameEncounter` define
una clave estable, barrio, ubicación transitable, título, condición, interlocutor
por línea y acceso opcional. Las condiciones vigentes consultan el regreso, el
descanso, la merienda, el estreno o una invitación concreta. El orden del recurso
prioriza las propuestas disponibles. Mantener las líneas verdaderas si el proyecto
se completa antes de volver al encuentro ya elegido. Los saludos generales y los
comentarios por entregas siguen en el banco editable de `VillageDialogue`.

Tras una merienda confirmada sin Kay, **Invitar a Kay al estanque** sirve la
comida conocida en el agua. El álbum registra a quien aparece en esa reunión.
**Reunirnos otra vez** en el claro registra su grupo actual y conserva el grupo
original del estreno. Mover muebles, cambiar visitantes y elegir otro propósito
conservan las experiencias anteriores. La aldea mantiene jardín, álbum, práctica,
mesa de trazos, invitaciones y reuniones accesibles al completar los proyectos.

`validate_neighbourhood` comprueba reparto, condiciones, experiencias, edición
de autor y checkpoints. `validate_postgame_neighbours` recorre las rutas, la
orientación, teclado, reanudación y regreso libre, y admite capturas de escritorio
y compacto mediante el ejecutor aislado.

### Misiones de la aventura

`mission_kind` en la misión selecciona `home`, `party` o `meal` para sus objetivos.
Los objetos se colocan al entregar y se utilizan sin otro menú obligatorio.
Los SVG de plaza,
mesa compartida y poses viven en `Arte/`; los recursos de ejercicio y las fichas
mayas conservan su identidad. Los motivos de interpretación se editan en `purpose`
de `data/dialogue/village_dialogue.json` y se regeneran con el generador existente.
No deben contener la traducción exacta de un pedido que se evalúa por interpretación.

Los perfiles de Taller y Comida distinguen altura de escritura y de reconstrucción;
`ScreenLayout` aplica la base y `ExerciseRecallFlow` la modalidad. `RecallWorkbench`
ya no existe. `StoryInteraction` recibe los controles editables de la escena y posee
su progreso; sus APIs públicas gestionan entrada, bloqueo, foco y reanudación. No
se reubican los nodos de autoría ni se duplican las preguntas de `StoryQuestionPlan`.

El formato 9 requiere reiniciar explícitamente las partidas de otro formato. Se
conservan escritura temporal y respaldo, sin migraciones ni acreditación al reanudar.

## Pulido de interacción y capas

Los botones creados durante la partida heredan el tema compartido. `SelectionButton`
distingue el marrón de la presión física del dorado de selección; las tarjetas de
palabras y de encargos utilizan el mismo contrato. `QualityCue` proporciona símbolos
neutros de cualidades para las opciones, sin cambiar los ejemplos del libro.

Los huecos avanzan a la siguiente casilla vacía, incluso entre palabras. Retroceso
desde una casilla vacía borra la anterior editable. `RecallPanel` coordina ese foco;
`SpellingField` conserva la edición de cada palabra. La recepción y el resaltado de
`WordDropSlot` comparten una tolerancia de 6 píxeles laterales y 28 verticales.

`MeaningIllustration` ajusta todas sus capas al rectángulo de las tarjetas. Los
objetos de escenario activan `world_object` para conservar sus dimensiones físicas.
`MissionTaskPreview` reutiliza las poses de uso al consultar un encargo entregado;
los desconocidos muestran una interrogación sin revelar su habitante ni su pedido.
La pose de transporte de `KalinWalker` expone `carry_anchor()` para mantener el objeto
sobre su mano, delante del cuerpo. La milpa separa su primera fila de maíces en
`bg_explora_milpa_front.svg`; esta capa comparte coordenadas con el terreno.

En la tablilla, **Borrar** retira un grano, o una varita si no quedan granos, del piso
seleccionado. El otro piso y la selección se conservan. `clear_numeral()` sigue
reservado para iniciar una ronda. El portal presenta «Quiero…» cuando espera
`In k'a'at…`, conservando las descripciones simples en las demás preguntas.

Los saltos de introducción, historia y exploración requieren una visita terminada.
El checkpoint usa `complete` y la repetición conserva ese dato en
`previous_variation`; guardar y reanudar no habilita saltos de escenas desconocidas.
Las ayudas de `LearningGuide` se retiran al actuar, abrir respuestas o pausar el
juego. La suite `validate_playtest_polish` cubre estos comportamientos y admite
capturas con el ejecutor aislado.
