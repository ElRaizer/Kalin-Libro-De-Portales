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

Existe un solo formato de partida: **6**, definido en `SaveSchema.CURRENT_VERSION`.
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

La navegación captura el origen antes de solicitar un cambio de escena y actualiza
el destino de continuación sólo cuando el motor acepta la transición. El retorno
de una visita también se conserva si la apertura falla.

Las especializaciones de exploración agregan datos con `checkpoint_extension()`.
La exploración base no conoce a `VillageDialogue`.

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
