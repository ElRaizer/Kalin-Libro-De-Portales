# Arquitectura y propiedad del código

Esta es la referencia vigente después de la limpieza del 25 de octubre de 2026.
Las auditorías conservan sus conclusiones históricas y el árbol que revisaron.

## Organización

Se mantienen los árboles `scripts/` y `scenes/`, agrupados por función. Los
mundos componen esas funciones y configuran su contenido. Los recursos de autor
viven en `data/`; el arte compartido permanece en `Arte/` para conservar sus
rutas e importaciones existentes.

```text
scripts/
  autoloads/              Fachadas y servicios de aplicación
  core/
    content/             Vocabulario y combinaciones canónicas
    navigation/          Transiciones y captura de checkpoints
    persistence/         Archivo, esquema y decodificación vigente
    replay/              Selección determinista común
    session/             Progreso, intentos y contextos de aprendizaje
  features/
    grid_paths/          Reglas, presentación y autoría del tablero
    story/               Momentos e interpretación de historia
    exploration/         Recorrido e interacción general
    counting/            Numeración maya de dos pisos y rondas del tianguis
    exercises/           Ejercicios, respuestas y controles de construcción
      domain/            Sesión compartida de frases
    village/             Encargos, habitantes, paseos y despedida
    spellbook/           Libro y movimiento de sus páginas
  ui/
    main_menu/           Menú e introducción
    shared/              Controles usados por varias funciones
    data/                Recursos de presentación
  worlds/                Controladores de composición propios de cada mundo
scenes/
  autoloads/
  features/              Las mismas familias funcionales que scripts/
  ui/
  worlds/
data/
  exercises/             ExerciseSet editables
  layouts/               Perfiles de distribución
  combinations/          Manifiesto de combinaciones revisadas
  dialogue/              Banco de diálogos revisados
  grid_variants/         Geometrías y soluciones revisadas
tests/
  unit/                  Reglas y límites de arquitectura
  support/               Soporte compartido de pruebas
  tooling/               Pruebas del análisis de código
  validate_*.gd          Suites de integración y autoría
```

Las suites de integración se encuentran en `tests/validate_*.gd`; las reglas
aisladas, en `tests/unit/`, y las pruebas de herramientas, en `tests/tooling/`. El ejecutor
descubre todas las suites `validate_*.gd` recursivamente.

## Propietarios y contratos

| Módulo | Responsabilidad | Límite |
|---|---|---|
| `GameManager` | Señales, sesión y coordinación de servicios | Delega almacenamiento, navegación, consultas y restauración |
| `GameSession` | Dueño del progreso mutable; snapshots y aplicación del estado restaurado | No conoce archivos ni SceneTree |
| `SaveRepository` | JSON, archivo temporal, respaldo y errores de acceso | No decide qué significa una ronda o un encargo |
| `SaveSchema` | Validación del contenedor, versión y tipos antes de convertir números | No modifica la sesión |
| `SessionCodec` | Decodificación y saneamiento del único formato vigente | Produce datos completos antes de aplicarlos |
| `SceneStateSchema` | Normalización común de checkpoints actuales | Los componentes validan además sus índices y contenido anidado |
| `SceneNavigator` | Cambios de escena, continuación, repetición y captura inmediata o diferida | Conserva snapshots profundos; recibe la sesión y la escritura como dependencias |
| `VocabularyCatalog` / `WordMatcher` | Consultas y comparación de palabras | Devuelven resultados independientes del catálogo original |
| `GridPathController` | Dueño del estado y reglas de caminos | RefCounted sin referencia a GridBoard, nodos ni presentación |
| `GridBoard` | Entrada y coordinación de presentación | Traduce eventos de las reglas a señales y efectos del tablero |
| `PhraseExerciseSession` | Ronda, plan, respuestas, intento y transiciones de mundos 3 y 4 | No conoce controles, GameManager ni archivos |
| `RecallPanel` | Edición de respuestas, apoyos y bloques | Expone consultas de estado y restauración; los consumidores no consultan banderas privadas |
| `CountingSession` | Números sorteados, tablilla y errores del nivel de números | Recibe `CountingSet`; no conoce nodos, autoloads ni archivos. Sortea con la semilla guardada. Reglas de puntos, barras, concha y veintenas en `MayaNumeral` |
| `AudioManager` | Música y ambiente por escena, efectos por nombre y volumen persistente | Lee `AudioCatalog`; no decide reglas de juego. Ver [Música y efectos](audio.md) |
| `ScreenLayout` | Base de distribución y perfil compacto | Reaplica la transformación de fase sobre esa base; los controladores no fijan coordenadas del panel |

El renderizador y las pistas de obstáculos siguen siendo colaboradores de
presentación del tablero. Su anfitrión tiene tipo `GridBoard`; las reglas de
caminos no dependen de ellos.

`GameManager.session` contiene el progreso vivo de `GameSession`; no hay
propiedades duplicadas en la fachada. Los catálogos se consultan en `GameContent`
y `VocabularyCatalog`. Para leer copias aisladas están `learned_words()`,
`learning_record()`, `saved_scene_state()` y `has_scene_state()`.

## Persistencia

Existe un solo formato de partida: **9**, definido en `SaveSchema.CURRENT_VERSION`.
Se rechazan los formatos anteriores y futuros sin convertirlos ni sobrescribirlos.
El menú permite reiniciar explícitamente una partida rechazada. No se infieren
niveles desde palabras ni se traducen identificadores retirados del prototipo.

Una carga valida primero el contenedor y decodifica datos separados. Sólo después
modifica la sesión. Los errores de lectura o esquema pueden recuperar un respaldo
del formato vigente. El archivo `.bak` y la escritura temporal protegen los datos
actuales ante corrupción; no contienen sistemas o implementaciones alternativas.

Un checkpoint es una instantánea independiente al producirlo, capturarlo y leerlo.
Contiene datos JSON, nunca nodos o recursos. Los dos ejercicios de frases guardan
el mismo plan: una lista de objetos `challenge` / `guided`. No hay un segundo
formato basado en índices sueltos.

En intentos nuevos, `PhraseExerciseSession` conserva una recuperación por reto y
presenta primero únicamente las combinaciones cuyas palabras aún no se conocen.
La cantidad de pasos depende del contenido presentado; ya no hay una cuota fija
de doce respuestas. El orden determinista se guarda completo y no se recalcula
al aprender palabras o reanudar. `ExerciseProgress` valida índices, cobertura y
modalidades únicas. Los recursos personalizados del Inspector conservan sus retos.

El dominio expone los límites y contadores de modalidad del plan real. Las escenas
presentan esos cambios mediante `MissionBreak`; el paseo opcional queda entre
episodios y regresa a la ronda pendiente, sin añadir ejercicios al plan.

La navegación captura el origen antes de solicitar un cambio de escena y actualiza
el destino de continuación sólo cuando el motor acepta la transición. El retorno
de una visita también se conserva si la apertura falla.

Las especializaciones de exploración agregan datos con `checkpoint_extension()`.
La exploración base no conoce a `VillageDialogue`.

`ExplorationRoaming` posee la entrada vertical, la marcha articulada y la ruta del
suelo libre. La escena aporta límites y obstáculos; `VillageGround` calcula rutas
sin nodos. La posición del pie decide la profundidad. Los checkpoints conservan
ambos ejes y el destino pendiente. El diario detiene el desplazamiento mientras se consulta.

`VillageHabitat` mantiene a Kay dentro del estanque antes de recibir un encargo.
`VillageUseMotion` toma temporalmente su presentación durante el uso y la devuelve
al terminar. `SpeciesActionRig` articula piezas excluyentes del arte existente:
los pies permanecen en el suelo mientras torso y cabeza alcanzan el recipiente.
La comida de mamíferos y aves permanece servida en un cuenco apoyado. Ma’ax
transporta su porción con la mano; Kay recibe alimento que cae al agua. La vista
mantiene el aroma junto a la porción. Los puntos de boca corresponden al viewBox
de la pieza dibujada y las pruebas contrastan el pico rasterizado con la abertura
del vaso, además de revisar las fases ampliadas en el motor.
Las referencias transitorias a actores se liberan con su propietario.

`GardenEditor` separa copias gratuitas de muebles colocados y almacenados. La vista
previa no confirma posición ni orientación; cancelar restaura la copia provisional.
Deshacer conserva el estado anterior a la última edición confirmada. Las reglas de
huella, superficie y movimiento de conjuntos pertenecen a `GardenLayout`.

## Identidad y variaciones

`ExerciseSet.variation_policy` determina si se usa contenido de autor o el
catálogo de combinaciones. `catalog_id` identifica ese catálogo. La firma de
contenido conserva la protección de las ediciones de autor: cambiar una frase,
una opción o un retrato suspende la generación sobre ese recurso. Copiar o mover
el recurso sin cambiar sus datos conserva la variación.

`authored_signature` registra una base revisada. Si se modifica intencionalmente
el contenido canónico y debe seguir variando, se debe revisar y confirmar la
nueva firma mediante `tools/sign_exercises.gd`; no copiar una firma de otro
recurso. La política `AUTHORED` permite desactivar la generación explícitamente.

Las variaciones usan la clave semántica de escena que mantiene `GameContent`.
Mover un archivo no modifica esa identidad ni introduce rutas antiguas como semillas.

## Convenciones para cambios nuevos

- Archivos y carpetas: `snake_case`; identificadores técnicos nuevos en inglés.
- Clases y nodos: PascalCase. Texto visible y documentación: español.
- La ubicación expresa propiedad: una función usada por varios mundos vive en
  `features/` o `core/`, no en el primer mundo que la utilizó.
- Las reglas reciben datos y devuelven resultados o eventos; las vistas operan
  sobre sus propios nodos. Evitar llamadas a métodos `_privados` de otro objeto.
- Tipos explícitos en variables, bucles, parámetros, señales y retornos nombrados. Usar `Dictionary` en la frontera JSON y
  contratos tipados en las reglas estables. `Variant` se reserva para fronteras
  heterogéneas como JSON y APIs de Godot; no sustituye los tipos conocidos.
- Los recursos compartidos son configuración. Duplicar los datos de sesión
  antes de modificarlos.
- Los UID `.gd.uid` se versionan y se conservan al mover scripts.

## Catálogos generados

| Fuente revisada | Generador | Salida de ejecución |
|---|---|---|
| `data/grid_variants/catalog.json` | `tools/build_grid_variants.py` | `GridVariantCatalog` |
| `data/combinations/catalog.json` | `tools/build_combination_catalog.py` | `CombinationData` |
| `data/dialogue/village_dialogue.json` y combinaciones | `tools/build_combination_dialogue.py` | `VillageDialogueCatalog` |

Los manifiestos están versionados y excluidos del índice de Godot mediante
`.gdignore`; el juego utiliza sus módulos generados. `--check` comprueba que la
salida coincide, sin escribir archivos. El generador de tableros recuperado
compila las 48 variantes revisadas y valida sus soluciones y dificultad. No
reconstruye el algoritmo de búsqueda original que faltaba en el repositorio.

Las salidas generadas tienen su propio formato determinista y se enumeran en
`tools/generated-files.txt`. No se les aplica el formateador de código de autor.

`tools/check_code_policy.py` analiza la sintaxis para comprobar tipos explícitos,
nombres de archivo y límites entre dominio, aplicación, UI y persistencia.

Ver [mantenimiento y validación](maintenance.md) para los comandos.

## Responsabilidades de las mejoras de experiencia

- `VillageMissionState` posee conocidos, entregas, borradores, apoyos y objeto
  transportado; restaura y produce datos independientes sin acceder a nodos.
  `VillageMission` compone los recursos y presenta los resultados.
- `StoryQuestionPlan` prepara copias de los momentos y conserva las preguntas
  deterministas. `StoryInteraction` posee el progreso, la presentación y la entrada
  de conocer/adivinar/elegir; expone eventos y snapshots. `StoryScene` conserva los
  momentos, el texto y la navegación; la cinemática permanece en `StoryAnimator`.
- `LearningAttempt` posee orientación, apoyo de contenido y evidencia por palabra;
  `LearningProgress` calcula los contadores. `GameSession` confirma resultados.
- `SpellLaboratory` presenta práctica opcional de contenido conocido; conserva su
  propia pausa y foco. No modifica encargos ni acredita recuerdo.
- `VillageGathering` representa juntos los tres resultados con el arte canónico.
  `gathering_seen` se confirma al cerrar; restaurar no duplica resultados educativos.
- `MeaningIllustration.set_world_object()` es la API pública de representación.
  La profundidad de Kalin pertenece a la escena de exploración, no al animador.

El formato 9 retira `pages`/`assembly_open` y conserva `memory`/`memory_open` en
la despedida. El recuerdo es una copia JSON validada de un momento vivido, sin
puntuación ni evidencia educativa. `VillageMemory` valida el dato y prepara opciones
con las visitas realizadas; `MemoryChoice` presenta la preferencia y `MemoryMoment`
representa la misma imagen al elegir y al regresar. `HomecomingMemory` escucha el
evento público `beat_presented` sólo en la cinemática de regreso. Los formatos
anteriores se rechazan y requieren reinicio explícito, sin conversión.

La entrega coloca el objeto en su lugar funcional y registra el uso una sola vez.
Restaurar repone sus datos e imagen. El acomodo libre pertenece al jardín; las
misiones no añaden elecciones de ubicación ni barras de ajuste obligatorias.
`VisualCatalog` conserva las poses editables `activity_look`, `activity_reach` y
`activity_consume` de cada animal. `VillageUseMotion` compone su secuencia, porción,
apoyos y profundidad; el trabajo vive y se pausa con el resultado del mundo.


## Aldea persistente y economía del formato 9

`GameSession` posee `economy` (máximos acreditados por palabra, diseños, preparación
y primer rincón construido) y `garden` (identidades, posiciones, orientación,
superficies y almacén). `MagicEconomy` calcula premios 10/6/4 y compras de 10;
`GardenLayout` valida y aplica colocaciones sin conocer nodos. Descubrir palabras
y completar niveles no añaden los antiguos premios. Ensayar no paga puntos.
Los 12 de preparación se confirman una vez después de practicar Mesa y Fuerte.
Las compras iniciales quedan limitadas a esas dos entradas hasta construir el rincón.

`VillageHome` compone barrios, llegada segura, lugares físicos y acceso voluntario.
`VillageGround` calcula rutas transitables. `KalinWalker` mantiene el salto del
recorte completo sobre un origen estable de suelo y sombra, también en dos ejes;
el movimiento reducido elimina ese salto. `VillageMap` presenta destinos y sus
bloqueos narrativos, conserva pausa y foco y solicita viajes a `VillageHome`.
Los letreros inician un recorrido y activan su destino al llegar, sin otra confirmación.
`GardenEditor` previsualiza una edición y confirma posiciones válidas; cancelar no
mueve el objeto. La retirada conserva los muebles en almacén. `GardenObject`
representa sus vistas y altura de superficie; la profundidad usa el apoyo del suelo.

Los fondos SVG de los tres barrios pertenecen a `Arte/backgrounds/`; su terreno
decorativo respeta el suelo transitable y la parcela. El editor agrupa copias por
objeto base y oculta catálogo y herramientas ajenas a la acción durante la colocación.

`ChallengePlanner` selecciona contenido presentado usando ocasiones, apoyo reciente
y recencia. `ChallengeRoom` posee la tanda, borrador e intento, guardados en el
checkpoint de la aldea. La sala no acredita contenido nuevo por cambiar una semilla.
El libro y el ensayo conservan la marca de solución durante un reto. Las fórmulas
de cortesía mantienen la identidad completa del catálogo.

El formato 9 rechaza el 8 y cualquier otra versión sin sobrescribirlos. Requiere
reinicio explícito; no convierte saldos ni vuelve a pagar objetivos históricos.
