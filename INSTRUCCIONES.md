# Kalin y el Libro de los Portales — Guía técnica

Esta guía explica cómo abrir, ejecutar y mantener el repositorio. La presentación general y el estado del contenido están en [README.md](README.md); las decisiones lingüísticas se registran en [VOCABULARIO.md](VOCABULARIO.md).

## Requisitos

- Godot **4.6**.
- Un sistema capaz de ejecutar el renderer configurado por el proyecto.
- No se requieren paquetes externos.

## Abrir y ejecutar

1. Abre el administrador de proyectos de Godot.
2. Selecciona **Importar** y elige el archivo `project.godot` de este repositorio.
3. Espera a que Godot importe los SVG y las escenas.
4. Pulsa **F5** para ejecutar el juego completo.

La escena principal es `res://scenes/MainMenu.tscn`. **Jugar** abre una introducción breve, seguida del huracán y la exploración; **Continuar** recupera el punto guardado. **Saltar intro** pasa a la exploración de la isla.

## Configuración esencial

El proyecto incluye los siguientes autoloads:

```ini
[autoload]
WindowManager="*res://scripts/autoloads/WindowManager.gd"
GameManager="*res://scenes/components/GameManager.tscn"
AccessibilityManager="*res://scenes/components/AccessibilityManager.tscn"
PauseMenu="*res://scenes/components/PauseMenu.tscn"
```

`GameManager` conserva el catálogo canónico de vocabulario, el orden de los niveles, las palabras aprendidas, los puntos mágicos y el guardado local.

La configuración de contenido, arte, controles y plantillas se explica en
[Configuración desde el editor](INSTRUCCIONES.md#configuración-esencial). Los ejercicios de los mundos
2–5 usan recursos `ExerciseSet` en `data/exercises/`; las ilustraciones y
expresiones se asignan en `data/visual_catalog.tres`.

`project.godot` también define tres acciones de entrada para las exploraciones (**Proyecto → Configuración del proyecto → Mapa de entrada**):

| Acción | Teclas |
|---|---|
| `kalin_izquierda` | `←`, `A` |
| `kalin_derecha` | `→`, `D` |
| `kalin_interactuar` | `E`, `Espacio`, `Enter`, `Enter` del teclado numérico |

## Estructura actual

```text
Kalin-Libro-De-Portales/
├── project.godot
├── README.md
├── INSTRUCCIONES.md
├── VOCABULARIO.md
├── themes/
│   └── kalin_theme.tres
├── Arte/
│   ├── audio/
│   │   └── README.md
│   ├── backgrounds/
│   ├── efectos/
│   ├── exploracion/
│   ├── sprites/
│   └── tiles/
├── scenes/
│   ├── Intro.tscn
│   ├── MainMenu.tscn
│   ├── components/
│   │   ├── GridBoard.tscn
│   │   ├── LevelHeader.tscn
│   │   ├── CompletionOverlay.tscn
│   │   ├── ExplorationScene.tscn
│   │   ├── ExplorationSpot.tscn
│   │   └── StoryScene.tscn
│   ├── ui/
│   │   └── LibroHechizos.tscn
│   ├── world1/
│   │   ├── Level1_CaminosBlancos.tscn
│   │   ├── Level2_AnimalesBosque.tscn
│   │   ├── Level3_GuardianesMonte.tscn
│   │   ├── Level4_AguaYCielo.tscn
│   │   ├── Historia1_IslaAnimales.tscn ... Historia5_FiestaIsla.tscn
│   │   ├── Exploracion1_OrillaIsla.tscn
│   │   ├── Cine1_NocheHuracan.tscn
│   │   └── Cine2_CasaMayaVacia.tscn
│   ├── world2/
│   │   └── Level2_ConstruyendoPalabras.tscn
│   ├── world3/
│   │   └── Level3_HechizosAdjetivos.tscn
│   ├── world4/
│   │   └── Level4_YoQuiero.tscn
│   └── world5/
│       ├── Level5_PortalDeRegreso.tscn
│       ├── Historia9_Despedida.tscn
│       └── Cine3_RegresoACasa.tscn
└── scripts/
	├── Intro.gd
	├── autoloads/
	│   └── GameManager.gd
	├── components/
	│   ├── GridAnimalData.gd
	│   ├── GridBoard.gd
	│   ├── GridWordData.gd
	│   ├── ExplorationScene.gd
	│   ├── ExplorationSpot.gd
	│   ├── StoryBeat.gd
	│   └── StoryScene.gd
	├── ui/
	│   ├── LibroHechizos.gd
	│   └── MainMenu.gd
	├── world1/
	│   ├── GridPathLevel.gd
	│   └── W1_Level1.gd ... W1_Level4.gd
	├── world2/
	│   └── W2_Level1.gd
	├── world3/
	│   └── W3_Level1.gd
	├── world4/
	│   └── W4_Level1.gd
	└── world5/
		└── W5_Level1.gd
```

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

El orden oficial vive en `GameManager.LEVEL_ORDER`:

1. Mundo 1, niveles 1–4: caminos de animales.
2. Mundo 2, nivel 1: lanzamiento del hechizo correcto.
3. Mundo 3, nivel 1: adjetivos.
4. Mundo 4, nivel 1: *In k'a'at* en fases guiada y de recuerdo.
5. Mundo 5, nivel 1: recapitulación, cortesía y portal de regreso.

Cada nivel debe llamar `GameManager.complete_level(mundo, nivel)` con su identidad real. **Continuar** usa `resume_scene_key` y el checkpoint de la escena. Para partidas antiguas sin checkpoint, consulta el primer elemento incompleto de `LEVEL_ORDER`.

Para agregar un nivel:

1. Crea su escena y script en las carpetas del mundo correspondiente.
2. Agrega una clave a `GameManager.SCENE_PATHS`.
3. Inserta sus datos en la posición correcta de `GameManager.LEVEL_ORDER`.
4. Configura la escena siguiente.
5. Registra su vocabulario en `GameManager.VOCABULARY`.
6. Prueba comenzar, terminar, salir al menú y usar **Continuar** con una partida nueva y una existente.

## Capítulos de historia

Los capítulos heredan `res://scenes/components/StoryScene.tscn` y no necesitan
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
capítulos. Ver [REVISION_UX_VISUAL.md](APRENDIZAJE_Y_MISION.md) para los componentes
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
| `effects` | Casillas `Hojas`, `Lluvia`, `Muebles`, `Páginas` y `Chispas`. Se pueden combinar. Son nodos `CPUParticles2D` dentro de `Effects` en `StoryScene.tscn`, así que su cantidad, velocidad y textura se ajustan en el Inspector. |
| `kalin_motion` | `QUIETO`, `ENTRA` (camina desde la izquierda), `SALTA`, `TIEMBLA`, `DORMIDO` (acostado; en el siguiente momento se levanta) o `CRUZA` (camina hacia el portal de `bg_portal_isla.svg` y desaparece). |
| `screen_shake` | Sacude la pantalla, como un trueno. |
| `flash` | Destello blanco, como un relámpago o la luz del portal. |
| `title`, `subtitle` | Cartel central, por ejemplo "Mundo 3" y "Hechizos de Adjetivos". |
| `auto_advance` | Segundos que espera, después de escribirse el texto, antes de avanzar solo. Con 0 espera al jugador. El clic, `Espacio` o `Enter` lo adelantan. |

Cuando `background` cambia, el fondo nuevo entra con un fundido.

Los capítulos 6 a 9 viven en `scenes/world2/` a `scenes/world5/` y usan a los
seis animales de la aldea que también aparecen en los mundos 2, 3 y 4, con sus
mismas peticiones. El capítulo 9 es el epílogo: se abre desde **Cerrar la
aventura** al terminar el Mundo 5 y continúa con la cinemática de regreso a
casa, que termina en el menú principal.

Los animales se identifican por su palabra maya. La ilustración, la frase
*In k'aaba'e' ___* y su traducción se leen de `GameManager`, así que un
animal nuevo solo necesita estar en `VOCABULARY` y en `BOOK_ILLUSTRATIONS`.

Las cinemáticas son escenas que heredan `StoryScene.tscn`, usan solo momentos
`DIALOGO` con `auto_advance` y cambian el texto del nodo `UI/SkipButton` a
**Saltar cinemática ▶▶**. Se registran con claves `worldN_cineM`:

| Clave | Escena | Va después de | Continúa hacia |
|---|---|---|---|
| `world1_cine1` | `Cine1_NocheHuracan.tscn` | Introducción | `world1_explore1` |
| `world1_cine2` | `Cine2_CasaMayaVacia.tscn` | Capítulo 5 | `world2_level1` |
| `world5_cine1` | `Cine3_RegresoACasa.tscn` | Capítulo 9 | `main_menu` |

El último momento de una cinemática puede omitir `auto_advance` para esperar al
jugador antes de cambiar de escena.

Fondos y efectos nuevos (`Arte/backgrounds/` y `Arte/efectos/`) mantienen el
estilo del proyecto: SVG de 1280 × 720, formas planas, degradados suaves y una
viñeta ligera. Los fondos dejan libre la parte baja, donde va el cuadro de
diálogo, y la zona izquierda, donde está Kalin.

Para agregar un capítulo:

1. Duplica un capítulo existente de `scenes/worldN/`.
2. Edita sus momentos en el Inspector.
3. Registra la escena en `GameManager.SCENE_PATHS` con una clave `worldN_storyM`.
4. Cambia el `next_scene_key` del nivel anterior para que apunte al capítulo.
5. Agrega `story_key` al nivel siguiente en `LEVEL_ORDER` para que **Continuar** lo muestre.

## Exploraciones

Una exploración deja que el jugador camine con Kalin por un sendero lineal
antes de un capítulo. La plantilla es `res://scenes/components/ExplorationScene.tscn`
(script `ExplorationScene.gd`) y cada exploración la hereda sin script propio.
La primera es `scenes/world1/Exploracion1_OrillaIsla.tscn` (clave
`world1_explore1`): va entre `world1_cine1` y `world1_story1`.

Estructura de la plantilla:

| Nodo | Uso |
|---|---|
| `Cielo` (`Parallax2D`) | Cielo y mar lejanos; con `scroll_scale` 0.15 se mueven más despacio que el terreno. |
| `Terreno` (`Sprite2D`) | Dibujo ancho por el que camina Kalin (`bg_isla_sendero.svg`, 3840 × 720). |
| `Sendero` (`Path2D`) | Línea por la que van los pies de Kalin. Sus extremos marcan dónde empieza y termina el recorrido. Si cambias el terreno, mueve sus puntos en el editor para que sigan el camino dibujado. |
| `Animales` | `Sprite2D` decorativos que saltan suavemente (por ejemplo, los animales que esperan en la meta). |
| `Spots` | Instancias de `ExplorationSpot.tscn`, una por objeto. |
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

El dibujo va en el nodo hijo `Sprite` de cada instancia (activa **Hijos
editables**); su `offset` debe dejar la base del objeto en el origen para que
se apoye en el sendero. Los objetos sin examinar brillan con el nodo `Brillo`.

Para agregar una exploración:

1. Crea una escena heredada de `ExplorationScene.tscn` en `scenes/worldN/` (o
   duplica `Exploracion1_OrillaIsla.tscn`).
2. Cambia las texturas de `Cielo/Imagen` y `Terreno`, y ajusta `Sendero`.
3. Agrega instancias de `ExplorationSpot.tscn` dentro de `Spots`, con una meta al final.
4. Regístrala en `GameManager.SCENE_PATHS` con una clave `worldN_exploreM`.
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

`GameManager.VOCABULARY` es la fuente única para traducción, emoji, estructura, mundo y nivel. Los scripts deben consultar `get_vocabulary_entry()` y `has_learned_word()` en lugar de comparar directamente las claves guardadas.

El cargador migra variantes antiguas —por ejemplo, `K'uum`— a la clave canónica `K'úum`, evitando entradas duplicadas en el libro. Las decisiones y excepciones provenientes del GDD están documentadas en [VOCABULARIO.md](VOCABULARIO.md).

## Guardado

El progreso se guarda automáticamente como `user://kalin_save.json`. Incluye:

- versión del formato;
- puntos mágicos;
- palabras aprendidas;
- identificadores `w<numero>_l<numero>` de los niveles completados;
- escena pendiente, estado de cada escena y tutoriales ya practicados (formato 3).

**Volver a empezar** pide confirmación antes de eliminar la partida. Los datos inválidos se descartan y un JSON dañado genera una advertencia sin impedir que el juego inicie. `SaveRepository.CURRENT_VERSION` es la versión canónica. El formato 1 conserva palabras, puntos y niveles; sólo el formato 0 infiere niveles desde vocabulario antiguo.

Para una escena nueva, implementar `get_checkpoint_state() -> Dictionary` y restaurar con `GameManager.get_scene_state(self)`. Guardar tras acciones completas mediante `GameManager.checkpoint(self)`. La navegación y el cierre de ventana capturan también el estado actual. Usar `GameManager.replay_scene()` para repetir desde el principio sin borrar los logros. El libro usa `PROCESS_MODE_ALWAYS` mientras pausa el árbol; los temporizadores de un ejercicio deben respetar esa pausa.

## Audio pendiente

La presentación del libro se controla desde `scripts/ui/BookMotion.gd`:
apertura de 0.49 s y cierre de 0.44 s. `LibroHechizos.gd` anima páginas
y pestañas en 0.25 s, administra el foco y conserva la pausa hasta terminar
el cierre. Al abrirlo desde una interfaz nueva, pasar el botón real con
`libro.show_book(boton)` para que el viaje de ida y vuelta use su posición.
Los efectos visuales no se guardan como progreso.

Los audios todavía no están grabados. Cuando estén disponibles, colócalos en `Arte/audio/` como archivos OGG. Los nombres técnicos eliminan acentos, apóstrofes y espacios para que sean portables entre sistemas. La tabla completa está en [Arte/audio/README.md](Arte/audio/README.md).

El botón permanece disponible: sin archivo muestra un aviso silencioso; con
archivo reproduce la grabación. Cambiar de página o cerrar detiene la voz.
La prueba `tests/validate_book.gd` comprueba pausa, foco, interrupciones,
botones de origen, numeración y audio pendiente. Acepta
`-- --capture=<carpeta absoluta>` con renderer real para guardar capturas.

## Comprobación antes de integrar cambios

La validación automática de catálogo, rutas, escenas, tableros, alias y nombres de audio se ejecuta desde la raíz con:

```powershell
godot_console.exe --headless --path . --script res://tests/validate_project.gd
godot_console.exe --headless --path . --script res://tests/validate_learning_flow.gd
godot_console.exe --headless --path . --script res://tests/validate_main_menu.gd
godot_console.exe --headless --path . --script res://tests/validate_intro.gd
godot_console.exe --headless --path . --script res://tests/validate_ux.gd
godot_console.exe --headless --path . --script res://tests/validate_adventure.gd
godot_console.exe --headless --path . --script res://tests/validate_visual_flow.gd
godot_console.exe --headless --path . --script res://tests/validate_answer_layout.gd
godot_console.exe --headless --path . --script res://tests/validate_animation_loops.gd
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
`RecallPanel` usa una plantilla `RecallFragment.tscn` para los bloques variables.

Los encargos tempranos heredan `Mision_EncargosAldea.tscn`: se editan seis recursos
`VillageTask`, agrupados en tres parejas por destinatario. Los encargos comienzan
por escritura y activan completar y bloques después de los errores. Se reutilizan las combinaciones ya
registradas en el vocabulario. La despedida se configura con tres `ExerciseEntry`
en `Despedida_LosRecuerdos.tscn`.

Ejecutar `tools/validate.ps1` antes de integrar cambios. El detalle del recorrido,
los contextos semánticos y la migración al guardado 5 están en
[MEJORAS_AVENTURA.md](MEJORAS_AVENTURA.md).

## Ayuda de depuración para contestar

`DebugAnswer` es un autoload con un botón flotante y el atajo F4. Consulta los
métodos `debug_can_answer()` y `debug_answer()` de la escena actual. Cada escena
usa sus respuestas de contenido (incluidas las variantes barajadas), marca el
intento como apoyado y llama al mismo envío que utiliza el jugador. No cambia
de nivel ni adelanta el resultado. `RecallPanel.debug_fill()` conserva el modo
de escritura, completar o bloques.

Para añadir ejercicios, implementar ambos métodos y bloquearlos con
`OS.is_debug_build()`. El autoload vuelve a comprobar disponibilidad al pulsar;
rechaza escenas en transición y la pausa, que también usa el libro. En Release
se elimina antes de crear interfaz; en exportaciones Debug permanece activo.
`tests/validate_debug_answer.gd` comprueba F4, botón, todas las familias de
actividad y que estas respuestas no generen evidencia de recuerdo sin ayuda.

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
opcional del guardado 5; una partida antigua conserva los dueños de sus encargos.
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

El banco de `data/dialogue/VillageDialogueCatalog.gd` organiza los textos por nombre
del animal. `greetings` contiene sus cinco saludos. `tasks` usa la clave
`objeto|cualidad` (por ejemplo, `mayak|nojoch`); cada entrada contiene dos peticiones
alternativas y el agradecimiento al completar el encargo. Mantener las dos variantes
igualmente claras sobre el objeto y la cualidad, sin añadir palabras mayas nuevas.

`VillageDialogue.personalize()` aplica el texto a las copias del recurso en paseos
y misiones. La semilla, escena, animal y pedido fijan la variante durante la visita.
No modificar el texto desde el diálogo o el diario: ambos leen el mismo `VillageTask`.
Para añadir un pedido, cubrirlo para todos los habitantes y ejecutar
`validate_village_dialogue.gd`; la prueba detecta combinaciones sin personalizar.

El nodo `VillageDialogue`, instalado por `VillageResidents`, rota los saludos al
cerrar la conversación. `ExplorationScene` guarda sus contadores por animal en
`greeting_visits`. Los amigos que ya recibieron su encargo también cambian de saludo,
manteniendo después el agradecimiento por el mismo resultado. Los amigos de la
despedida conservan sus peticiones narrativas; sus vecinos sí utilizan este banco.

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

Editar la lista cerrada de `scripts/data/CombinationCatalog.gd`, no formar parejas
arbitrarias. Actualmente incluye 28 combinaciones y nueve peticiones simples.
`CombinationVariation` selecciona seis retos de taller/comida y tres necesidades
por visita, conservadas como claves semánticas en el checkpoint. El Inspector de
Taller y Yo quiero permite desactivar `vary_combinations`; los recursos alternativos
de ejercicios conservan sus retos de autor.

Para una combinación nueva, añadir o revisar sus textos para los doce animales en
`data/dialogue/VillageDialogueCatalog.gd` y su representación en `VillageUseArt`.
`python tools/build_combination_dialogue.py` conserva las frases existentes y añade
las ausentes a partir de los contextos propios de cada animal y objeto; revisar el
resultado editorialmente. El catálogo contiene 888 peticiones, 444 agradecimientos
y 60 saludos. Ejecutar `tools/validate.ps1` y revisar el atlas renderizado después de
cambiar textos, cualidades o SVG. Los guardados pendientes anteriores no se sustituyen.
