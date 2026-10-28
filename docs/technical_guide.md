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

La escena principal es `res://scenes/ui/main_menu/main_menu.tscn`. **Jugar** abre una introducción breve, seguida del huracán y la exploración; **Continuar** recupera el punto guardado. **Saltar intro** pasa a la exploración de la isla.

## Configuración esencial

El proyecto incluye los siguientes autoloads:

```ini
[autoload]
WindowManager="*res://scripts/autoloads/window_manager.gd"
GameManager="*res://scenes/autoloads/game_manager.tscn"
AccessibilityManager="*res://scenes/autoloads/accessibility_manager.tscn"
PauseMenu="*res://scenes/autoloads/pause_menu.tscn"
AudioManager="*res://scenes/autoloads/audio_manager.tscn"
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
4. Mundo 4, nivel 1: *In k'a'at* en fases guiada y de recuerdo.
5. Mundo 4, nivel 2: números del uno al cinco (ver [Las piedras que cuentan](#las-piedras-que-cuentan)).
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
| `MayaNumeral` (`scripts/features/counting/`) | Reglas puras de puntos y barras: un punto vale 1, una barra 5 y cinco puntos se reúnen en una barra. |
| `CountingSession` | Ronda, tablilla, canasta, respuesta, intento y checkpoint validado. Sin nodos ni autoloads. |
| `CountingRound` / `CountingSet` | Contenido de autor en `data/exercises/world4_counting.tres`; se edita en el Inspector y avisa si falta algo. |
| `NumeralView` | Dibuja un numeral con las texturas de cacao y varita elegidas en el Inspector. |
| `counting_exercise.gd` (`scripts/worlds/world4/`) | Presenta cada fase y conecta la entrada; usa `RecallPanel`, `LearningGuide` y `MissionProgress`. |

Fases de `CountingRound.kind`: `STELE` (conocer los numerales de la estela),
`BUILD` (formar el número con granos y varitas), `MARKET` (llenar la canasta con
la cantidad pedida; cosas con `-p'éel`), `FRIENDS` (contar animales; `-túul`) y
`RECALL` (escribir número con clasificador y lo contado). Las frases completas son
texto de autor: el código no construye la morfología maya. Las opciones se
ofrecen en número par y se barajan con la semilla de la partida.

Los números del vocabulario tienen `value` y `book_category = 6`: el Libro de
Hechizos los muestra en la pestaña **Números**, ordenados por valor. Su
ilustración es el numeral de puntos y barras (`Arte/numeros/`, en el catálogo
visual). El arte se genera con `python tools/build_counting_art.py`: amate,
líneas rojas de códice, contorno negro, azul maya y ocre, sin `rgba()`.

## Capítulos de historia

Los capítulos heredan `res://scenes/features/story/story_scene.tscn` y no necesitan
script propio. En el Inspector se configuran:

- `chapter_title`: título visible del capítulo.
- `next_scene_key`: escena que se abre al terminar o al pulsar **Saltar historia**.
- `beats`: lista de recursos `StoryBeat`, uno por momento.

Cada `StoryBeat` define:

La revisión visual incorpora también `kind = EXPLORAR`, `visual_scene` (vacío,
`camino`, `casa`, `tamano`, `hambre` o `portal`) y `visual_solved`. En EXPLORAR,
la escena representa el problema automáticamente en un bucle continuo; Continuar
está disponible sin tocar la animación. Los
checkpoints narrativos guardan `revision = 2` y migran las posiciones de los
capítulos abreviados. `PauseMenu` es el autoload que gestiona `Esc` sin saltar
capítulos. Ver [REVISION_UX_VISUAL.md](learning_and_missions.md) para los componentes
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
| `celebrate_page` | Muestra la animación "¡Página recuperada!", lanza páginas y chispas y hace saltar a Kalin. |

Las propiedades de la categoría **Animación** convierten un capítulo en una
cinemática. Todas son opcionales y, salvo `mood`, valen solo para su momento:

| Propiedad | Uso |
|---|---|
| `mood` | Color ambiental: `DIA`, `ATARDECER`, `NOCHE`, `TORMENTA` o `AMANECER`. Cambia con una transición suave; `SIN_CAMBIO` conserva el anterior. Los colores están en `StoryScene.AMBIENT_COLORS`. |
| `effects` | Casillas `Hojas`, `Lluvia`, `Muebles`, `Páginas` y `Chispas`. Se pueden combinar. Son nodos `CPUParticles2D` dentro de `Effects` en `story_scene.tscn`, así que su cantidad, velocidad y textura se ajustan en el Inspector. |
| `kalin_motion` | `QUIETO`, `ENTRA` (camina desde la izquierda), `SALTA`, `TIEMBLA`, `DORMIDO` (acostado; en el siguiente momento se levanta) o `CRUZA` (camina hacia el portal de `bg_portal_isla.svg` y desaparece). |
| `screen_shake` | Sacude la pantalla, como un trueno. |
| `flash` | Destello blanco, como un relámpago o la luz del portal. |
| `title`, `subtitle` | Cartel central, por ejemplo "Mundo 3" y "Hechizos de Adjetivos". |
| `auto_advance` | Segundos que espera, después de escribirse el texto, antes de avanzar solo. Con 0 espera al jugador. El clic, `Espacio` o `Enter` lo adelantan. |

Cuando `background` cambia, el fondo nuevo entra con un fundido.

Los capítulos 6 a 9 viven en `scenes/worlds/world2/` a `scenes/worlds/world5/` y usan a los
seis animales de la aldea que también aparecen en los mundos 2, 3 y 4, con sus
mismas peticiones. El capítulo 9 es el epílogo: se abre desde **Cerrar la
aventura** al terminar el Mundo 5 y continúa con la cinemática de regreso a
casa, que termina en el menú principal.

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

**Volver a empezar** pide confirmación antes de eliminar la partida. `SaveSchema.CURRENT_VERSION` fija el único formato admitido (**6**). Los formatos anteriores o futuros se rechazan sin sobrescribir el archivo; el menú permite reiniciarlo. Un archivo dañado puede recuperar el respaldo del formato vigente. No hay migraciones ni inferencia de niveles desde vocabulario.

Para una escena nueva, implementar `get_checkpoint_state() -> Dictionary` y restaurar con `GameManager.get_scene_state(self)`. Guardar tras acciones completas mediante `GameManager.checkpoint(self)`. La navegación y el cierre de ventana capturan también el estado actual. Usar `GameManager.replay_scene()` para repetir desde el principio sin borrar los logros. El libro usa `PROCESS_MODE_ALWAYS` mientras pausa el árbol; los temporizadores de un ejercicio deben respetar esa pausa.

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
2. Ejecutar la introducción y probar **Saltar intro**.
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
`RecallPanel` usa una plantilla `recall_fragment.tscn` para los bloques variables.

Los encargos tempranos heredan `mision_encargos_aldea.tscn`: se editan seis recursos
`VillageTask`, agrupados en tres parejas por destinatario. Los encargos comienzan
por escritura y activan completar y bloques después de los errores. Se reutilizan las combinaciones ya
registradas en el vocabulario. La despedida se configura con tres `ExerciseEntry`
en `despedida_los_recuerdos.tscn`.

Ejecutar `tools/validate.ps1` antes de integrar cambios. El detalle del recorrido,
los contextos semánticos y el guardado vigente están en
[docs/adventure.md](adventure.md).

## Casillas y apoyos automáticos

`RecallPanel.advance_support()` conserva las partes correctas y avanza escritura →
completar → bloques. `ready_to_submit()` evita evaluar campos vacíos o piezas pendientes.
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

`RecallPanel.set_workspace("taller")` y `set_workspace("comida")` activan
`RecallWorkbench`. Sólo refleja lo escrito; no debe recibir las soluciones ni
interpretar aciertos. Las tablillas permiten volver al campo con toque o teclado.
El modo de bloques conserva su tablero independiente.

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
No modificar el texto desde el diálogo o el diario: ambos leen el mismo `VillageTask`.
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

Capas efectivas: casas 0, mueble 1, animal 2, tejido frontal 3, Kalin 4, opciones 6.
Mantener esta relación en paseos y misiones, cuyos contenedores antes tenían
profundidades diferentes. Kay usa la orilla con el mueble al lado. `WorldMat` apoya
platos, alimentos y agua; `WorldFront` sólo aparece con la hamaca.

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
