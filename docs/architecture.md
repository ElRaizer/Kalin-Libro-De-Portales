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
| `SpellingCorrection` / `SpellingField` | Alineación de grafías y presentación de huecos | El modelo confirma progreso y valida sus snapshots; la vista conserva foco e inserción de símbolos |
| `CountingSession` | Plan numérico progresivo, tablilla y errores del nivel de números | Recibe `CountingSet`; no conoce nodos, autoloads ni archivos. Genera con la semilla y conserva el plan en el checkpoint. Reglas de puntos, barras, concha y veintenas en `MayaNumeral` |
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

La repetición conserva `replay_run` en los checkpoints del recorrido. Una transición
aceptada renueva una sola vez cada capítulo o nivel visitado en ese recorrido;
volver del menú o de una visita no reinicia los resultados pendientes. No borra
descubrimientos, economía ni logros generales. Los huecos usan el campo opcional
`scaffold.corrections` del contrato vigente y validan sus posiciones y letras
contra la respuesta del recurso antes de restaurarse.

Las especializaciones de exploración agregan datos con `checkpoint_extension()`.
La exploración base no conoce a `VillageDialogue`.

`ExplorationRoaming` posee la entrada vertical, la marcha articulada y la ruta del
suelo libre. La escena aporta límites y obstáculos; `VillageGround` calcula rutas
sin nodos. La posición del pie decide la profundidad. Los checkpoints conservan
ambos ejes y el destino pendiente. Consultar las tarjetas del taller detiene el desplazamiento.

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
previa no confirma posición ni orientación; cancelar descarta la copia provisional.
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
  `StoryBeat` configura gestos y página protagonista como presentación, sin añadir
  progreso. `AccessibilityManager` conserva `manual_cinematics` con los ajustes de
  comodidad. `StoryScene` detiene o programa su temporizador al cambiar la
  preferencia, sin avanzar el momento.
- `LearningAttempt` posee orientación, apoyo de contenido y evidencia por palabra;
  `LearningProgress` calcula los contadores. `GameSession` confirma resultados.
- `SpellLaboratory` presenta práctica opcional de contenido conocido; conserva su
  propia pausa y foco. Compara una referencia temporal con el ensayo y consulta los
  favoritos de sesión. Emite `placement_requested` para que `VillageHome` abra el
  editor de la parcela visitada. No modifica encargos ni acredita recuerdo.
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

`HomecomingMemory` también presenta el camino añadido al dibujo de casa y el
libro sobre el escritorio en el último momento. La escena le proporciona la vista
`completed_drawing`; reconstruye su visibilidad desde el momento narrativo, sin
otro campo persistido. Su transición respeta pausa, movimiento reducido y opacidad
de autor. `StoryVignette.finish_reveal()` reconstruye el resultado de la mesa al
restaurar una historia; el plato se mantiene servido sin repetir la transformación.
Con movimiento reducido, la mesa utiliza una única fase de pose, también al
cambiar la preferencia a mitad del ciclo; actor y platos permanecen estables.

`VillageMemory.delivered_moments()` valida destinatarios, combinaciones y marcadores
de entrega antes de producir recuerdos; `for_animal()` consulta los vividos por un
habitante. `PortalFarewell` los presenta con un texto de autor como alternativa
cuando no hay una entrega confirmada para ese amigo. Elegir una expresión en esta
despedida es práctica apoyada, sin respuesta obligatoria; no cambia la evaluación
previa del portal ni añade campos al checkpoint.

`CountingProvision` presenta las semillas de una cantidad confirmada del tianguis.
Se reconstruye desde `CountingSession.waiting` y su objetivo; no posee contadores
de entregas ni añade recompensas. Su transición pertenece al control y respeta la
pausa y el movimiento reducido.

La entrega coloca el objeto en su lugar funcional y registra el uso una sola vez.
Restaurar repone sus datos e imagen. El acomodo libre pertenece al jardín; las
misiones no añaden elecciones de ubicación ni barras de ajuste obligatorias.
`VisualCatalog` conserva la pose editable `activity_look` de cada animal. Alcanzar
y consumir utilizan las piezas y puntos de contacto de `SpeciesActionRig`; sus
recortes completos no son propiedades de las actuaciones vigentes.
`VillageUseMotion` compone la secuencia, porción, apoyos y profundidad; el trabajo
vive y se pausa con el resultado del mundo.


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
Las copias nuevas se previsualizan fuera de `GameSession.garden` y sólo entran al
confirmar suelo o superficie válidos mediante `place_new_garden_object()`. Guardar
o cerrar durante la vista previa conserva únicamente el jardín confirmado.

`GameSession.laboratory_favorites` conserva una lista ordenada de combinaciones
canónicas conocidas, sin diseños ni muebles implícitos. `LaboratoryState` valida
tipos, unicidad, contenido presentado y el máximo persistido de doce. El recurso
`data/village/laboratory.tres` configura la capacidad ofrecida (seis inicialmente);
reducirla impide añadir, sin borrar preferencias existentes. El campo opcional del
formato 9 ausente equivale a lista vacía y no requiere reiniciar partidas vigentes.

`MagicEconomy.missing_designs()` identifica diseños compartidos ya disponibles.
`GameSession.purchase_combination_designs()` comprueba el conjunto completo antes
de aplicar saldo y diseños, respetando la preparación del primer rincón.
`GameManager` persiste compras y favoritos antes de confirmar éxito; un fallo
revierte la operación y no emite cambios de saldo. El laboratorio muestra precios
individuales, total y saldo; revisar o cancelar nunca compra. Comprar habilita
colocación gratuita, sin crear una copia por sí mismo.

`GameSession.garden_identity` contiene por parcela un nombre de hasta 32 caracteres
y las selecciones `sign`, `border` y `gathering`. `GardenIdentity` valida texto,
unicidad y el proyecto de origen: los adornos requieren el descanso confirmado.
El nombre puede elegirse antes. Confirmar ese proyecto incorpora una vez la
guirnalda del patio, también si ya tenía nombre; retirarla después es una elección
personal. Sin entrada explícita se conserva la guirnalda de las partidas vigentes.

`GameSession.garden_compositions` guarda hasta dos espacios por parcela, con copias
JSON de los muebles colocados: ID, clave, posición, orientación y superficie. Un
espacio vacío no contiene una composición; una composición con `objects: []`
representa una parcela vacía. `GardenCompositions` valida cada conjunto sin nodos,
incluidos sus apoyos, capacidad y números anidados. Las referencias pueden sobrevivir
a una copia eliminada; su identidad debe haberse emitido antes de `garden.next_id`.
Los IDs no se reutilizan, tampoco al deshacer la creación de una copia.

Restaurar comprueba que cada copia referenciada todavía existe con la misma clave,
prepara un candidato y aplica todo a la vez. Los muebles sobrantes de la parcela
van al almacén; un plato ajeno apoyado en una mesa referenciada impide la operación.
No se fabrican muebles ni se sustituyen IDs por copias parecidas. Eliminar una mesa
con un plato se rechaza. Una superficie admite un solo plato, también al cargar.
Una visita activa protege el mueble y sus objetos apoyados frente a estas operaciones.

`GardenEditor` posee el deshacer de la última edición del jardín durante la visita,
incluidas eliminación y restauración. `GameManager` confirma la escritura antes de
dar por hechas estas operaciones, el guardado de composiciones o la identidad; un
fallo conserva el estado anterior y la posibilidad de reintentar o deshacer.
El diseño comprado y los recuerdos de proyectos no se eliminan al retirar una copia.

`GardenIdentityPanel` y `GardenStoragePanel` usan `VillagePanel` para pausa, foco y
disposición del modal. El editor emite solicitudes públicas; `VillageHome` compone
los paneles y `GardenIdentityView` presenta el nombre y los adornos sin colisiones
nuevas. Texturas, rectángulos, títulos y capacidad ofrecida se editan en
`data/village/garden.tres`. La guirnalda conserva el arte y posición de `RestCornerProfile`.
Los campos opcionales `garden_identity` y `garden_compositions` amplían el formato 9;
su ausencia equivale a diccionarios vacíos, sin migraciones ni reinicio de partidas.

### Merienda y práctica elegible

`GameSession.snack_project` conserva grupo, merienda, adorno, preparación y
confirmación. `SnackState` admite uno o dos invitados conocidos, Kay y Ch'íich', y
comida básica del catálogo ya presentada. El grupo determina dos cantidades: una
ración y cinco bocados por invitado. La selección se fija al iniciar la preparación.
`CountingActivity` compone `CountingSession` y `MayaNumeral` con apoyos por ronda y
cantidades confirmadas; valida tipos, rangos, plan y coherencia del resultado antes
de restaurar. La finalización del proyecto exige ambas cantidades confirmadas.

`CountingWorkbench` presenta esa misma actividad en el proyecto y en la práctica
libre. Su candidato local se sincroniza con la sesión después de cada operación
confirmada; fallar la escritura del proyecto conserva la preparación anterior.
`GameManager` coordina estas transacciones, sin decidir cantidades ni recompensas.
`snack_project` es opcional en formato 9; ausencia equivale a proyecto sin iniciar.

`SnackPanel` representa la invitación, la preparación y la reunión. `SnackGathering`
reutiliza `VillageUseMotion`, `SpeciesActionRig` y los anclajes existentes con un
actor y porción propios por invitado. Kay permanece en agua; el ave conserva su
cuenco y apoyo. `use_shared_provision()` separa el alimento común de las porciones
animadas. No se crean objetos del jardín ni se modifica el almacén. El recuerdo
JSON independiente de `SnackState.memory()` conserva grupo, comida, adorno y
cantidades; volver a representar la reunión no vuelve a confirmar ni pagar.

`VillagePractice` compone la selección de palabras, cantidades, caminos y mixto.
`ChallengeRoom` sigue poseyendo la tanda de palabras; `batch_completed` permite
alternar sólo al terminar, sin transformar una salida temprana en resultado.
`NumberPracticePanel` y `PathPracticePanel` conservan sus modelos independientes.
El checkpoint de aldea añade `practice` con modalidad, siguiente familia y ambos
borradores, sin duplicar el estado de palabras de `challenge_room`.

Los caminos usan una ruta de una variante revisada del catálogo vigente, un animal
conocido y `GridPathController` para trazado, retroceso y llegada. Su vista de
casillas admite clic y foco con flechas/Enter; el apoyo muestra el testigo revisado.
La restauración reproduce cada paso mediante las mismas reglas y rechaza un final
que no alcanza el destino. Cantidades y caminos no llaman al registro lingüístico.
El modo mixto salta familias no disponibles y conserva su siguiente actividad al salir.
Cantidades se habilita tras completar el nivel de numeración; palabras y caminos
requieren contenido conocido. No hay obligación de terminar las tres familias.

`VillagePanel` es la base modal compartida de jardín, merienda y prácticas; conserva
el UID de la antigua base de jardín. El libro se superpone a las actividades, detiene
sus controles y actuaciones y devuelve su pausa, sin cerrar ni reiniciar el borrador.
`KalinActivityLabel` y `ScreenLayout` mantienen contraste, tipografía y perfiles.
Textos y presentación de la merienda viven en `data/village/snack.tres`; la tanda
numérica libre usa `data/village/practice_counting.tres`.

### Ampliación de la orilla

`GameSession.village_expansion` posee las pruebas de ambos propósitos, la elección
actual, uno o dos invitados y una inauguración confirmada. `VillageExpansion`
valida estos datos contra el contenido conocido y los proyectos de descanso y
merienda terminados. `opening` conserva una copia de la elección y del grupo del
estreno; redecorar o cambiar invitados no la sustituye. El campo es opcional en
formato 9: su ausencia mantiene el terreno cerrado, sin migraciones.

`GameManager` confirma la escritura de cada decisión antes de anunciarla; un fallo
restaura el estado anterior y `ExpansionPanel` reconstruye esa selección. Probar,
inaugurar y volver a reunirse son acciones diferentes. No se cobran puntos, crean
copias del jardín ni acreditan resultados lingüísticos. La merienda reutiliza la
comida del proyecto previo; las entradas posteriores no repiten su preparación.

`VillageSpace` y `VillageSpaces` describen las tres geometrías de autor en
`data/village/spaces.tres`, expuestas por `GameContent.VILLAGE_SPACES`. Cada barrio
define suelo, parcela, obstáculos y llegada. La orilla añade una parcela seca,
entrada conectada, ancla de interacción, dos anclas de invitados y espacio libre
para su uso. La ampliación forma parte de ese barrio y de su tarjeta del mapa.
`GardenLayout` recibe esta configuración al validar, colocar y mover conjuntos;
`GardenCompositions` la utiliza al restaurar. Se retiraron los rectángulos globales
de parcela y suelo: editor, rutas, profundidad y presentación usan estos recursos.

`VillageGround` calcula rutas sobre la unión de regiones transitables y los
obstáculos configurados, junto con las huellas de los muebles. Busca una llegada
libre al entrar o cargar una posición ocupada. Inaugurar exige una ruta hasta
cada ancla; los cambios del jardín posteriores conservan esos accesos y el espacio
de uso. Un movimiento rechazado conserva también la orientación y los platos
apoyados. Los acomodos anteriores siguen usando las mismas coordenadas e IDs.

`ExpansionPanel` comparte pausa, libro y foco de `VillagePanel`. `ExpansionGathering`
compone actores y objetos temporales independientes con `VillageUseMotion`; la
aldea muestra el mismo uso sobre las anclas del claro. El letrero permite llegar
caminando y abrir otra visita. Propósitos, reacciones y presentación viven en
`data/village/expansion.tres`; `KalinGuestChoice` mantiene el contraste de los
selectores con el tema común.

Los fondos SVG de los tres barrios pertenecen a `Arte/backgrounds/`; su terreno
decorativo respeta el suelo transitable y la parcela. El editor agrupa copias por
objeto base y oculta catálogo y herramientas ajenas a la acción durante la colocación.

`ChallengePlanner` selecciona contenido presentado usando ocasiones, apoyo reciente
y recencia. Las parejas canónicas conocidas menos practicadas tienen prioridad;
el orden del historial deshace empates de recencia sin añadir fechas por pareja.
Antes de reducir a una palabra, busca otra pareja que no repita contenido de la tanda.
`ChallengeRoom` posee la tanda, borrador e intento, guardados en el checkpoint de
la aldea. Conserva `targets` y los `visitors` opcionales concretos al reanudar;
un interlocutor nunca es el animal que se debe recordar. Si no hay otro conocido,
la presentación usa a Kalin. La sala no acredita contenido nuevo por cambiar una semilla.
El libro y el ensayo conservan la marca de solución durante un reto. Las fórmulas
de cortesía mantienen la identidad completa del catálogo.

`ChallengePreview` representa al interlocutor antes de responder y el encuentro
o uso del objeto sólo después de confirmar. `ChallengeProfile` contiene textos
editables en `data/village/challenges.tres`, expuesto por `VillageHome`.
El resultado y el cierre de tanda muestran primero la aportación y distinguen
apoyo, ensayo reciente y escritura independiente; los máximos económicos siguen
perteneciendo a `MagicEconomy`. La recencia de cualquiera de las dos palabras
convierte la pareja en ensayo, sin inventar evidencia de separación.

Una respuesta confirmada compatible con la elección pendiente de descanso ofrece
**Llevar al rincón**. Es una acción voluntaria: `ChallengeRoom` emite una solicitud
pública y `VillageHome` confirma mediante `GameSession.confirm_rest_corner()`.
La alternativa directa del proyecto sigue disponible. La confirmación única no
compra muebles, no vuelve a pagar ni cambia el apoyo registrado en el intento.
Las reacciones se leen en el panel del proyecto y la sala conserva su resultado.

El formato 9 rechaza el 8 y cualquier otra versión sin sobrescribirlos. Requiere
reinicio explícito; no convierte saldos ni vuelve a pagar objetivos históricos.

### Invitaciones breves al rincón

`GameSession.village_visit` posee la invitación activa y su tiempo restante. Es
un objeto JSON opcional del formato 9: ausencia o `{}` significa sin visita. Una
visita contiene `animal`, `object_id` y `remaining`; `VillageVisitState` valida el
habitante conocido, una mesa colocada en el patio y tiempo positivo, finito y
acotado. La extensión es compatible con partidas del formato vigente sin ese
campo; no incorpora migraciones ni cambia los puntos o el registro de aprendizaje.

`VillageVisitPlacement` busca un lateral libre; `VillageVisitPresentation` usa la
ruta del suelo y reconstruye los apoyos desde la mesa. No serializa actores,
anclas ni tiempos de tweens. `VillageUseMotion.attach()` admite un apoyo fijo
opcional para utilizar muebles sin desplazar sus vistas. Las entregas y sus
previsualizaciones conservan su comportamiento anterior.

La visita termina sola tras el tiempo activo configurado. Pausa y paneles detienen
su reloj; reanudar repone el uso estable y conserva el tiempo restante. Editar el
jardín, despedir o cambiar a otro barrio termina la visita. Una edición de soporte
rechazada por la sesión conserva la invitación; una edición confirmada la retira.
La presentación se libera antes de reconstruir las vistas del jardín y el vecino
original sólo se oculta mientras su representación invitada está activa.

`VillageVisitPanel` posee pausa y foco de la elección. Los textos y duración
pertenecen a `data/village_visit_profile.tres`; las reglas y el guardado no cargan
ese recurso. El patio mantiene las mesas como soporte de las invitaciones
físicas. Áak y Miis están disponibles durante la aventura, y el regreso abre el
resto del reparto terrestre conocido. El proyecto narrativo de descanso utiliza
su propia presentación temporal.

La presentación de encargos terminados pertenece a `MissionTaskPreview`, que
reutiliza `VillageUseMotion` sin confirmar entregas ni resultados educativos.
`KalinWalker` expone el anclaje de la pose de transporte; la misión posee el objeto
transportado y lo presenta delante de ese anclaje. Los resultados de UI ajustan las
capas de `MeaningIllustration` a su espacio; el modo `world_object` conserva la escala
de los muebles físicos. `SelectionButton` comparte el estado de presión temporal.

Los checkpoints narrativos confirman `complete` al terminar. `SceneNavigator`
conserva los metadatos de `previous_variation` al guardar una repetición, incluido
el permiso de omitir una escena ya terminada. No se habilita el salto por reanudar
ni por pertenecer a una cadena de repetición. Son campos opcionales del formato
vigente y no sustituyen su estado de avance.

### Regreso voluntario y proyecto de descanso

`GameSession.has_finished_adventure()` consulta el cierre confirmado de
`world5_cine1`, incluido su `previous_variation.complete` booleano al repetir.
Completar niveles, recuperar palabras o vaciar la continuación no sustituye esa
evidencia narrativa. Menú y aldea usan la misma consulta pública.

`RestCornerState` valida el objeto opcional `rest_corner` del formato 9: `intro`
(momento de invitación), `choice` (objeto conocido), `complete` y `result` (reacción
leída). Las etapas son enteros acotados y se contrastan con el cierre, la elección
y la confirmación. El campo ausente significa proyecto sin iniciar. Es una
extensión compatible del formato vigente; una carga inválida conserva la sesión.

`GameSession` confirma estas operaciones sin modificar economía, jardín ni
aprendizaje. El resultado es único y las vistas derivan la guirnalda de `complete`,
sin otro premio o contador persistido. Retirar muebles no borra esta experiencia.

`RestCornerPanel` posee pausa, foco y avance manual de los diálogos. Sus elecciones
reconstruyen una prueba temporal mediante `RestCornerPreview` y `VillageUseMotion`;
no crean muebles ni mutan recursos compartidos. Cerrar y cargar conservan la etapa
y la elección; reabrir representa el uso estable sin repetir la llegada. El acceso
a diseños continúa en la UI existente y no condiciona la confirmación del proyecto.
El acceso directo a las opciones registra el final de la invitación en
`RestCornerState` y enfoca la primera elección disponible. La confirmación del
rincón sigue siendo una acción independiente.

La configuración editable vive en `data/village/rest_corner.tres`, con tres
`RestCornerOption`, textos breves y la guirnalda SVG. Sus momentos específicos no
duplican el banco de saludos general. `VillageHome` compone el acceso, las señales
y el adorno físico del patio; la consulta de progreso pertenece a la sesión.

### Álbum de aldea

`GameSession` posee hasta doce momentos personales. `PersonalAlbum` valida cada
título, encuadre, instante de pose, participantes y datos del lugar según la
clase de reunión. El campo `personal_album` es opcional en formato 9. El codec
normaliza IDs, apoyos y giros del jardín histórico. La foto de una invitación
conserva sus propias copias de los muebles, el apoyo del plato, el nombre y los
adornos del patio, junto con el ancla del invitado. Para las reuniones se guardan
las claves de comida, mueble o adorno aplicables. La restauración no consulta las
copias actuales ni exige que sigan colocadas o disponibles en el almacén.

`VillageHome` entrega a `PersonalAlbumPanel` el contexto de una invitación válida
o una reunión confirmada. El panel posee el borrador, selección y confirmaciones,
y reusa la pausa y el foco de `VillagePanel`. `PersonalMomentView` reconstruye la
escena en un viewport aislado con el arte y las actuaciones vigentes. El encuadre
recorta sólo esa escena. Las poses usan instantes reproducibles de
`VillageUseMotion`; el álbum congela el instante elegido y no serializa texturas,
nodos, recursos ni el archivo completo de partida.

`GameManager` escribe una copia candidata mediante `SaveRepository` antes de
aplicar el álbum en memoria. Agregar, sustituir y borrar mantienen intacto el
progreso si falla la operación y permiten reintentar. El recuerdo narrativo sigue
en `world5_farewell.memory` y se representa con `MemoryMoment`; las fotos no
alteran esa elección ni el registro de aprendizaje o la economía.

### Vecinos y oportunidades de regreso

`VillageNeighbours` define el reparto por barrio y la compatibilidad de las
invitaciones al patio. `VillageVisitPlacement` y `VillageVisitPresentation` aplican
las mismas rutas y apoyos a las llegadas desde otras zonas. Kay usa la
representación acuática de `SnackGathering`. Si la primera merienda no lo incluyó,
`SnackPanel` ofrece invitarlo con la misma comida y conserva intacta la preparación
confirmada. El grupo que aparece es el que recibe el álbum.

`GameSession.village_experiences` conserva listas acotadas de participantes en
invitaciones válidas y reuniones confirmadas tras el estreno del claro. Incluye
también a quienes recibieron entregas que se archivaron al repetir la campaña. Es un campo opcional del
formato 9. Las entregas de los checkpoints y los grupos de los proyectos
confirmados siguen siendo sus propias fuentes. Seleccionar el grupo del claro no
registra una reunión. `GameManager` revierte una experiencia nueva si falla su
escritura. Ninguna operación modifica la economía ni la evidencia de aprendizaje.

`VillageNeighbourhood` consulta esos hechos para fijar los temas de una charla.
`VillageDialogue` conserva los saludos y la rotación de sus bancos. El comentario
posterior a una entrega exige que el interlocutor haya recibido su propio encargo.
Los textos específicos de las visitas, reuniones y encuentros se configuran en
`VillageNeighbourProfile` y los perfiles vigentes del proyecto.

El checkpoint `neighbourhood` de `village_home` conserva el encuentro seleccionado,
su línea, las claves ya oídas y la charla de vecino pendiente. Cada entrada selecciona
el primer encuentro válido del perfil cuando ya no queda uno vigente. Leer, cerrar
un panel o cambiar de barrio conserva las líneas que corresponden. Terminar
explícitamente registra el encuentro oído. El panel no vuelve a abrirse al cargar.
El mapa y la indicación de entrada comparten una única oportunidad contextual
y existe un acceso por letrero dentro del barrio. Las actividades siguen teniendo
sus accesos habituales.

## Recuperación de navegación y cierre

`GameManager.go_to_scene()` conserva el resultado booleano de `SceneNavigator`.
Los propietarios que bloquean controles o funden la pantalla revierten su
presentación si el destino se rechaza, conservando checkpoint y continuación.
El cierre normal sólo se solicita tras un guardado correcto; un error mantiene
la sesión abierta y el aviso de reintento. No se sobrescribe una partida rechazada
por versión para permitir el cierre.
