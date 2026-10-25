# Auditoría técnica del proyecto

> Documento histórico: describe el estado anterior a la limpieza. Consultar
> [cambios aplicados y validación](cleanup_2026-10-24.md) y la
> [arquitectura vigente](../architecture.md). Las rutas de evidencia pueden corresponder al árbol anterior.

Fecha: 24 de octubre de 2026. Motor utilizado: Godot 4.6.3.stable.official.7d41c59c4.

## Dictamen

El proyecto tiene una base funcional y varias decisiones acertadas, pero la separación de responsabilidades es parcial. Ya conviene hacer una pausa de mantenimiento: las dependencias globales, los flujos repetidos y las reglas que dependen de rutas aumentan el costo de cualquier cambio nuevo.

La distribución actual de carpetas es válida en Godot. El principal problema no es su apariencia: es que varios módulos conocen demasiado del estado, la estructura y las decisiones de otros. Mover archivos sin resolver esos contratos conservaría los problemas y añadiría riesgo de regresiones.

No recomiendo una reescritura, introducir un framework de arquitectura ni convertir cada función en una clase. Recomiendo refactorizaciones pequeñas, con límites explícitos y comprobación de partidas existentes.

## Alcance y evidencias

- Inventario de 83 scripts en `scripts/`, con 11 604 líneas físicas; el catálogo GDScript de diálogos está adicionalmente en `data/dialogue/`.
- 75 escenas y 24 suites `validate_*.gd`.
- Lectura dirigida de servicios globales, persistencia, controladores de niveles, tablero, exploración, historia, ejercicios, recursos, libro, herramientas y pruebas. El inventario cubre todo el árbol; no implica revisión exhaustiva de cada línea.
- Comprobación de 514 referencias explícitas `path="res://..."` en escenas y recursos de `scenes/`, `data/` y `themes/`: ninguna ruta ausente ni diferencia de capitalización encontrada. No comprende todas las rutas construidas durante la ejecución.
- Ejecución de `tools/validate.ps1` con su aislamiento de datos. El comando se detuvo en la novena suite, `validate_inspector.gd`, después de ocho suites aprobadas. Las quince suites posteriores se ejecutaron aparte, con datos aislados, para completar la evaluación.
- Pruebas de diagnóstico adicionales, alojadas en `.ui-review/`, que reproducen tipos inválidos en guardados, comportamiento dependiente de la ruta del recurso y snapshots que comparten colecciones.
- Consulta de documentación oficial de Godot 4.6. Las propuestas arquitectónicas son juicio aplicado a este proyecto; no se presentan como una estructura obligatoria del motor.

No se evaluaron gameplay, calidad artística, comprensión pedagógica, rendimiento de exportaciones ni comportamiento en dispositivos físicos. No se cambió código de producción durante esta revisión.

## Problemas con prioridad alta

### 1. La carga de guardados no valida todos los tipos antes de convertirlos

**Evidencia:** `scripts/data/SaveRepository.gd:62` convierte `version` con `int()`. `scripts/autoloads/GameManager.gd:306` hace lo mismo con `magic_points`.

Se reprodujeron estas entradas JSON válidas sintácticamente:

```json
{"version": {}, "magic_points": 10}
```

```json
{"version": 5, "magic_points": {}, "completed_levels": ["w1_l1"]}
```

Ambas generan `SCRIPT ERROR: Invalid call. Nonexistent 'int' constructor.`. En el primer caso, la carga regresó un diccionario vacío sin `_load_error`. En el segundo, `load_failed` quedó en `false`, sin mensaje, y no se restauraron los niveles.

**Impacto:** una partida con estructura inválida puede confundirse con ausencia de progreso o dejar la restauración incompleta. El bloqueo de sobrescritura basado en `load_failed` no protege ese caso. No se demostró pérdida de una partida real; sí se confirmó que esa protección queda desactivada.

**Recomendación:** validar la estructura completa antes de modificar el estado de la sesión; comprobar tipo, finitud y rango antes de convertir números. Devolver un resultado explícito de carga y aplicar la recuperación de respaldo también a errores de esquema. Añadir regresiones con JSON correcto que tenga tipos incorrectos, junto con casos de migración y respaldo.

### 2. La validación actual falla porque hay dos responsables de la distribución

**Evidencia:** `tests/validate_inspector.gd:85` modifica posiciones antes de montar las escenas para comprobar que se conservan. El fallo real es:

```text
ERROR: world4_level1 sobrescribe la posición de UI/ChoicesPanel
```

`scripts/world4/W4_Level1.gd:259` aplica coordenadas fijas en `apply_screen_layout()`: asigna `choices_panel.position.y = 250 if compact else 258`. `scripts/components/ScreenLayout.gd` ya captura y restaura geometría desde perfiles; además, `ExerciseRecallFlow.expand_for_recall()` modifica el mismo panel durante los cambios de fase.

**Impacto:** una edición válida desde el Inspector se pierde al iniciar. Es un incumplimiento del contrato de autoría, independientemente de si la pantalla predeterminada se ve bien.

**Recomendación:** definir un único propietario de la geometría. Mantener la base y las variantes en escenas/perfiles; el flujo solicita un estado de presentación. Si alguna transformación debe calcularse en código, debe partir de la geometría de autor y restaurarla de forma consistente. Recuperar esta prueba antes de reorganizar archivos.

### 3. Una ruta de archivo decide una regla de funcionamiento

**Evidencia:** `scripts/data/CombinationVariation.gd:19` sólo genera variaciones si `content.resource_path` coincide exactamente con `res://data/exercises/world%d.tres`.

Se comparó el recurso original del mundo 3 con una copia profunda sin cambios de contenido: el original produjo una sesión de variación y la copia devolvió `{}`.

**Impacto:** duplicar un recurso o moverlo durante la limpieza puede cambiar silenciosamente el funcionamiento. La intención de preservar contenido personalizado es razonable; usar la ubicación para detectarlo vuelve frágil la organización.

**Recomendación:** expresar esa política con datos explícitos: por ejemplo, un modo de variación y un identificador estable de catálogo. Migrar los recursos existentes conservando su comportamiento. Probar que mover un recurso no cambie su semántica y que el contenido personalizado conserve las reglas previstas.

## Problemas de arquitectura y mantenimiento

### 4. `GameManager` sigue siendo un centro de responsabilidades demasiado amplio

**Evidencia:** `scripts/autoloads/GameManager.gd` tiene 431 líneas y administra vocabulario, normalización, ilustraciones, nombres de audio, textos de progreso, recompensas, evidencias de aprendizaje, navegación, visitas específicas a la aldea, checkpoints, migraciones y cierre de aplicación. El inventario encontró 292 referencias textuales a `GameManager.` en 19 scripts de producción; este conteo describe dependencia, no mide por sí solo gravedad.

Extraer `GameContent` y `SaveRepository` fue un avance real. Sin embargo, `GameManager` todavía conoce la estructura de las escenas y excepciones concretas de contenido, como cuántas entregas completan una visita.

**Impacto:** cambios de presentación, contenido, guardado y navegación convergen en el mismo archivo. Las pruebas de reglas dependen de más infraestructura de la necesaria.

**Recomendación:** conservar inicialmente su API como fachada y trasladar propiedad y decisiones a pocos colaboradores concretos: sesión/progreso, navegación/checkpoints y catálogo de vocabulario. La presentación del texto y la selección de arte pueden vivir en sus consumidores o servicios enfocados. Estos colaboradores no necesitan convertirse todos en autoloads.

### 5. Algunos archivos separados conservan acoplamiento directo con los internos de su dueño

**Evidencia:** `scripts/components/GridPathController.gd:7` recibe el tablero como `Node2D`, lee y modifica `paths`, `connected`, `grid_state`, `tile_owner` y `active_index`, llama métodos con prefijo `_` y actualiza presentación. `GridBoardRenderer` y `GridObstacleHints` también cruzan esos detalles internos.

Además, `scripts/components/ExplorationScene.gd:507` conoce al componente especializado `VillageDialogue`. Los controladores de ejercicios consultan `RecallPanel._setting_up` y `_showing_result`, y manejan directamente sus campos de texto.

**Impacto:** dividir un archivo no ha producido límites de sustitución claros. Cambiar un detalle interno requiere coordinar varios archivos. El tipado amplio como `Node2D` o `RefCounted` deja parte del contrato para la ejecución.

**Recomendación:** dar al estado del tablero un propietario explícito y separar decisiones de recorrido de sus efectos visuales. Exponer operaciones y consultas pequeñas. En `RecallPanel`, ofrecer lectura/restauración de respuestas y consultas de estado; sus consumidores no deberían depender de banderas internas. La especialización de aldea puede ampliar el checkpoint mediante un punto de extensión, sin que la exploración base conozca esa especialización.

### 6. Los mundos 3 y 4 repiten el ciclo principal de ejercicios

**Evidencia:** `scripts/world3/W3_Level1.gd` tiene 518 líneas y `scripts/world4/W4_Level1.gd`, 545. Ambos restauran intento y apoyos, preparan combinaciones y rondas, conectan `RecallPanel`, gestionan dos elecciones, validan respuestas, registran aprendizaje, presentan el resultado y serializan estados casi paralelos. `PhraseBuilderController` y `ExerciseRecallFlow` comparten partes, pero el ciclo completo permanece duplicado.

**Impacto:** una corrección de restauración, ayudas o transición debe aplicarse en varios controladores. También hay diferencias pequeñas difíciles de distinguir de desviaciones accidentales.

**Recomendación:** extraer por composición una sesión de ejercicio que gestione ronda, fase, intento y resultado. Los controladores conservan sus diferencias de contenido y presentación. Empezar con mundos 3 y 4; incorporar mundos 2 y 5 sólo cuando el contrato común esté demostrado. Evitar una clase base con numerosas condiciones por mundo.

### 7. El esquema de guardado está repartido entre infraestructura y escenas

**Evidencia:** `scripts/data/SaveRepository.gd:88` enumera campos de muchos tipos de escena, como `farewell_choice`, `combination_animals`, `task_indices` y `scaffold`. Las migraciones adicionales están en `GameManager._load_save()`, `StoryScene._ready()` y varios restauradores especializados. `ReplayVariation.replay_state()` mantiene otra lista de claves de esos mismos sistemas.

**Impacto:** añadir una propiedad persistente puede exigir cambios en archivos de infraestructura, repetición y escena. No hay una frontera única entre formato externo, estado válido y estado en ejecución. La sanitización global tampoco valida por completo las estructuras anidadas.

**Recomendación:** dejar a `SaveRepository` la lectura/escritura y recuperación del contenedor. Definir migraciones del formato y contratos de estado por familia de actividad. Validar cada estado antes de aplicarlo. Los diccionarios son apropiados en la frontera JSON; dentro del dominio pueden sustituirse gradualmente por objetos tipados donde exista una estructura estable.

### 8. Varios checkpoints comparten colecciones mutables con la escena

**Evidencia:** `scripts/autoloads/GameManager.gd:380` guarda directamente el diccionario que devuelve la escena. `StoryScene.gd:732` incluye `_known_words` y `_met_words` por referencia; los checkpoints de los ejercicios incluyen planes y marcadores de forma similar.

Se tomó un checkpoint de una historia y después se añadió `Miis` a `_known_words`: el checkpoint ya obtenido cambió sin volver a capturarlo.

**Impacto:** el estado conservado en memoria no siempre representa una instantánea. La escritura inmediata reduce parte del efecto sobre el archivo, pero futuras escrituras pueden serializar mutaciones ajenas a una captura explícita.

**Recomendación:** establecer que un checkpoint debe estar separado del estado vivo y comprobarlo. Una copia profunda en la frontera de captura puede resolver los diccionarios actuales; para recursos y objetos se requiere una política explícita de serialización, no asumir que toda copia profunda los independiza.

### 9. Las carpetas genéricas ocultan las familias funcionales

**Evidencia:** `scripts/components/` agrupa 43 scripts: reglas del tablero, presentación, historia, recursos de configuración, ejercicios, aprendizaje y aldea. `scripts/data/` combina recursos de autor, catálogos, persistencia y algoritmos de variación. El catálogo ejecutable de diálogos vive aparte en `data/dialogue/`. `VillageMission` está en `world4/`, aunque lo usan escenas de mundos 2 y 3.

**Impacto:** cuesta saber dónde añadir o buscar una responsabilidad. Los nombres de ubicación sugieren un alcance que no corresponde al uso real. Separar todas las escenas de todos los scripts también obliga a recorrer dos árboles para trabajar en una misma función.

**Recomendación:** adoptar módulos por función de forma gradual, conservando recursos compartidos en un lugar inequívoco. Una alternativa válida es mantener `scenes/` y `scripts/` y reflejar subcarpetas funcionales en ambos; no es obligatorio unificar todo. El objetivo es que la ubicación indique propiedad, no sólo extensión.

### 10. Falta una herramienta necesaria para reproducir contenido generado

**Evidencia:** `scripts/data/GridVariantCatalog.gd:1` dice que fue generado por `tools/build_grid_variants.py` y que no debe editarse a mano. `REJUGABILIDAD.md:65` indica ejecutar ese comando. El archivo no está presente en `tools/` ni aparece en el inventario versionado actual.

**Impacto:** un colaborador nuevo puede usar los tableros existentes, pero no seguir el procedimiento documentado para regenerarlos. No hay un recorrido reproducible completo para ese catálogo.

**Recomendación:** recuperar el generador junto con sus entradas, versión/formato y comando de comprobación. Si el contenido debe ser mantenido manualmente, declararlo y retirar las instrucciones que dependen de la herramienta ausente.

Como mejora adicional, `tools/build_combination_dialogue.py:158` extrae constantes GDScript mediante `split()` y las interpreta como JSON. Conviene que el dato fuente tenga un formato explícito o que se documente y pruebe esa restricción; un cambio de formato del código puede romper el generador aunque el catálogo siga siendo GDScript válido.

### 11. Hay cobertura útil, pero falta convertirla en una garantía reproducible del repositorio

**Evidencia:** existen 24 suites con interacciones reales, persistencia y regresiones del Inspector. Muchas preparan estado mediante campos públicos y llamadas privadas como `_load_save()` o `_show_round()`. `tools/validate.ps1` mantiene una lista manual, una ruta predeterminada de Godot específica de esta máquina y carece de límites de tiempo por suite. No se encontró configuración de CI ni configuración versionada de lint/formato en el árbol revisado.

**Impacto:** cambios internos disparan cambios de pruebas; una suite nueva puede quedar fuera de la lista; un bloqueo puede impedir completar el comando. Que el equipo tenga herramientas instaladas no establece una política compartida.

**Recomendación:** conservar las pruebas de comportamiento actuales y añadir un soporte común de montaje, liberación y aislamiento. Agregar pruebas pequeñas para reglas sin escenas cuando se extraigan. Hacer reproducible la resolución de Godot 4.6.3, comprobar que el inventario de suites coincide con el ejecutor y establecer tiempos máximos. Integrar la validación en CI cuando el entorno de integración esté definido. Fijar una versión compatible de las herramientas de formato antes de hacerlas obligatorias.

### 12. Convenciones y documentación necesitan una política, no un cambio masivo de nombres

**Evidencia:** conviven `Arte`, nombres españoles e ingleses, PascalCase en archivos y nombres poco descriptivos como `W3_Level1.gd`. La auditoría previa califica como cumplidas la separación global y la persistencia, y presenta el respeto del Inspector como una garantía; los hallazgos actuales muestran límites concretos de esas afirmaciones. En `W4_Level1.gd:191` hay además una asignación condicional de texto seguida inmediatamente por otra que la reemplaza.

**Impacto:** el lector no puede confiar plenamente en los nombres, comentarios y estado documentado. Los detalles redundantes hacen más difícil reconocer la intención vigente.

**Recomendación:** acordar un idioma técnico para identificadores y usar `snake_case` para archivos nuevos; clases y nodos conservan PascalCase. Migrar nombres históricos por módulos y actualizar referencias. Consolidar documentación técnica en `docs/` con estado, fecha y verificaciones reales. Mantener alias de compatibilidad mientras se conozcan consumidores externos; no eliminar archivos sólo porque sean pequeños o no aparezcan en una búsqueda local.

## Decisiones que conviene conservar

- Recursos tipados como `StoryBeat`, `GridWordData` y los catálogos visuales permiten autoría desde el editor y validaciones útiles.
- El tablero comunica eventos mediante señales y los niveles gestionan consecuencias. Ese límite ya existe y merece fortalecerse.
- `SaveRepository` separa el acceso a archivos y tiene archivo temporal y respaldo; el problema encontrado está en la validación del contenido, no en la elección de JSON.
- Los recursos de historia se duplican para preparar preguntas de sesión, evitando modificar directamente la configuración compartida.
- `.editorconfig`, `.gitattributes`, `.godot-version`, UIDs versionados y exclusión de `.godot/` aportan reproducibilidad.
- El tipado de retornos y nodos está muy extendido. La mejora principal es precisar contratos entre módulos y datos estructurados, no añadir anotaciones indiscriminadamente.
- Las pruebas del Inspector verifican ajustes de autor modificados antes de iniciar, y no sólo que la pantalla predeterminada coincida con constantes. El fallo encontrado demuestra su utilidad.

## Estructura objetivo propuesta

Es una propuesta para este juego, no un requisito de Godot ni una migración aplicada:

```text
project.godot
core/
  session/            # Estado de partida y progreso
  navigation/         # Cambios de escena y coordinación de checkpoints
  persistence/        # Repositorio y migraciones del contenedor
features/
  grid_paths/         # Escena, estado del tablero, entrada y presentación
  story/              # Historia, momentos, presentación y animación
  exploration/        # Recorrido e interacción general
  exercises/          # Sesión compartida y vistas de ejercicios
  village/            # Encargos, habitantes, paseos y diálogos
  spellbook/          # Libro y presentación de entradas
ui/
  main_menu/
  pause/
  shared/             # Sólo controles usados por varias funciones
content/
  vocabulary/
  exercises/
  dialogue/
  worlds/             # Composición y datos propios de cada mundo
assets/               # Arte/audio compartidos
themes/
tests/
  unit/
  integration/
  authoring/
  support/
tools/
docs/
```

Reglas de propiedad recomendadas:

1. El contenido configura comportamientos mediante IDs y políticas explícitas, no mediante su ruta física.
2. La lógica de reglas recibe estado y datos; no necesita conocer nodos concretos del menú o del libro.
3. Las vistas traducen estado y resultados a nodos; no escriben directamente el formato de guardado.
4. Un controlador de escena coordina sus componentes y entrega dependencias; los componentes emiten resultados mediante señales o devuelven valores.
5. Cada estado mutable tiene un dueño; las consultas y los checkpoints entregan copias o vistas con contratos claros.
6. Un módulo compartido vive fuera del mundo particular que lo originó.
7. Los recursos compartidos se distinguen de las copias de sesión; los cambios de sesión no alteran el contenido de autor.

## Orden de limpieza recomendado

| Etapa | Trabajo | Criterio de salida |
|---|---|---|
| 1. Recuperar confianza | Resolver los fallos de carga y del Inspector, con regresiones de tipos y autoría. | Las 24 suites pasan; las entradas inválidas tienen una respuesta controlada. |
| 2. Estabilizar contratos | Sustituir identidad por ruta; separar snapshots; recuperar el generador ausente. | Copiar/mover recursos conserva las reglas previstas y se puede regenerar el catálogo. |
| 3. Extraer responsabilidades | Sesión compartida de ejercicios; propiedad del estado del tablero; reducir funciones de `GameManager`. | Las reglas extraídas pueden probarse sin montar todo el juego y las escenas conservan su comportamiento. |
| 4. Reorganizar por módulos | Mover un módulo por cambio y normalizar sus nombres. | Referencias/UIDs correctos, importación limpia y validaciones aprobadas en cada paso. |
| 5. Mantener el estándar | Documentación, soporte de pruebas, ejecutor portable y automatización. | Un clon nuevo puede ejecutar la validación con instrucciones suficientes y versiones definidas. |

Para movimientos de archivos: usar el editor o un procedimiento que actualice referencias, conservar UIDs, revisar las rutas construidas por código y las usadas como semillas, y verificar los checkpoints existentes. Los IDs persistidos de escenas y contenido deben mantenerse estables o tener migración explícita. Evitar combinar movimientos, renombrados y cambios de comportamiento en un mismo lote.

## Resultado de las comprobaciones

La importación del editor fue correcta. Las primeras ocho suites aprobaron. La novena, `validate_inspector.gd`, falló por la posición de `UI/ChoicesPanel` en el mundo 4. Las quince suites posteriores aprobaron al ejecutarlas por separado, con código de salida 0 y sin mensajes `SCRIPT ERROR:`, `ERROR:` ni `WARNING:`. Resultado total: **23 suites aprobadas y una fallida**. El comando oficial completo sigue fallando hasta corregir esa regresión.

Las pruebas adicionales confirmaron tres límites específicos: manejo incompleto de tipos JSON, variación dependiente de la ruta del recurso y snapshots con colecciones compartidas. Se ejecutaron con datos de diagnóstico, sin utilizar ni modificar la partida personal.

Los registros completos de la sesión están en `.ui-review/auditoria-validacion.log`, `.ui-review/audit-remaining-summary.log`, `.ui-review/audit-remaining.log` y `.ui-review/audit-probe.log`. Son evidencia local ignorada por Git; las conclusiones y reproducciones necesarias están descritas en este informe.

## Referencias profesionales consultadas

- [Organización de proyectos, Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/best_practices/project_organization.html): favorece cercanía de recursos y escenas, nombres `snake_case` y atención a mayúsculas. No exige una jerarquía única.
- [Organización de escenas, Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/best_practices/scene_organization.html): recomienda responsabilidades enfocadas, bajo acoplamiento e inicialización de dependencias desde el contexto superior.
- [Estilo GDScript, Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/gdscript_styleguide.html): orienta convenciones y prioriza consistencia; sus reglas no sustituyen el juicio arquitectónico.
- [Tipado estático, Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/static_typing.html): explica cómo los tipos concretos permiten detectar más errores antes de ejecutar.
