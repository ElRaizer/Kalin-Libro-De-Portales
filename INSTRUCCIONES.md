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

La escena principal es `res://scenes/Intro.tscn`. No es necesario cambiarla a `MainMenu.tscn`: la introducción forma parte del flujo oficial. El botón **Saltar intro** sí lleva directamente al menú.

## Configuración esencial

El proyecto ya incluye el autoload requerido:

```ini
[autoload]
GameManager="*res://scripts/autoloads/GameManager.gd"
```

`GameManager` conserva el catálogo canónico de vocabulario, el orden de los niveles, las palabras aprendidas, los puntos mágicos y el guardado local.

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
│   ├── World2/
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
- `KalinBookCard` y `KalinAudioButton` para el Libro de Hechizos.

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

Cada nivel debe llamar `GameManager.complete_level(mundo, nivel)` con su identidad real. El botón **Continuar** consulta el primer elemento incompleto de `LEVEL_ORDER`; no construye nombres de escena suponiendo que todos pertenecen al Mundo 1.

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

Arte de las exploraciones: el cielo (`bg_isla_cielo.svg`, 1700 × 720) debe ser
más ancho que la pantalla para el parallax; el terreno deja transparente la
parte alta para que se vea el cielo; los objetos viven en `Arte/exploracion/`.
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
- identificadores `w<numero>_l<numero>` de los niveles completados.

El botón **Reiniciar progreso** elimina ese archivo. Los datos inválidos se descartan y un JSON dañado genera una advertencia sin impedir que el juego inicie. Al modificar el formato de guardado, incrementa `SAVE_VERSION` y conserva una migración para las partidas existentes.

## Audio pendiente

Los audios todavía no están grabados. Cuando estén disponibles, colócalos en `Arte/audio/` como archivos OGG. Los nombres técnicos eliminan acentos, apóstrofes y espacios para que sean portables entre sistemas. La tabla completa está en [Arte/audio/README.md](Arte/audio/README.md).

## Comprobación antes de integrar cambios

La validación automática de catálogo, rutas, escenas, tableros, alias y nombres de audio se ejecuta desde la raíz con:

```powershell
godot_console.exe --headless --path . --script res://tests/validate_project.gd
godot_console.exe --headless --path . --script res://tests/validate_learning_flow.gd
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
9. Abrir el libro y comprobar ilustraciones, marcadores futuros y navegación por páginas.
