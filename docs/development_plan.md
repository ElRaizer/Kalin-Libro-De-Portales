# Mejoras de experiencia y mantenimiento

Especificación acordada el 27 de octubre de 2026. Este documento registra el
alcance, orden, aceptación y trabajo pendiente; Arquitectura, Mantenimiento y la
guía técnica siguen definiendo los contratos vigentes.

**Estado actual:** implementación y correcciones aceptadas por supervisión el
28 de octubre de 2026. Se contrastaron el registro completo de validación y las
nuevas capturas del motor; los defectos devueltos quedaron corregidos. El alcance
local acordado queda cerrado, con las limitaciones externas indicadas abajo.
Las decisiones más recientes están
en **Decisiones vigentes: puntos mágicos, diseños y composición**. Se eligieron
aldea por barrios, parcela de jardín, mesa de trazos con sello sin figura, movimiento
en dos ejes y almacén. Los puntos se gastan una vez por desbloqueo; las copias son
gratuitas. Se acordaron premios de 10/6/4 según apoyo y precios de 10 por objeto o
cualidad. Se confirmó un máximo de 10 por objetivo de palabra, la compra global
de cualidades y 12 puntos fijos por preparar el primer proyecto. Estas decisiones
reemplazan los materiales y el ejemplo anterior de 6+4. Los estudios
HTML y SVG orientaron la implementación; la aceptación corresponde a las capturas
y secuencias de la base integrada en Godot.

**Cierre del alcance narrativo y de contenido:** se conserva la historia vigente,
con necesidades variables del catálogo y cobertura de todo el vocabulario activo.
El acceso a secciones nuevas depende del desbloqueo de mundos, no de comprar
diseños ni de resolver sin ayuda. Se incorpora una sala de retos opcional en la
aldea para práctica dirigida por la evidencia registrada. El apartado final
«Cierre del plan: historia vigente, variedad y sala de retos» sustituye la exigencia
anterior de escribir un argumento y un proyecto exclusivo para cada animal.

## Ejecución autorizada del nuevo plan — cierre aceptado por supervisión

Sesión local iniciada el 27 de octubre y continuada el 28 de octubre de 2026,
conservando la base de trabajo existente. No se han creado commits ni publicado cambios.

| Hito | Estado y comprobaciones reales |
|---|---|
| Economía y persistencia | Política única 10/6/4 por palabra, diferencia posterior, preparación de 12 y compras permanentes. `validate_magic_economy` aprobada con Godot 4.6.3. Formato 9 sin migraciones. |
| Parcela y almacén | Colocación, cuatro vistas de silla/mesa, apoyo plato/mesa, traslado de conjuntos, almacén, cancelación y deshacer. `validate_garden_layout` aprobada; el ciclo de integración y sus capturas también. |
| Primer ciclo y barrios | Compras desde el libro, construcción y reanudación JSON aprobadas en `validate_village_home`. Patio, taller, orilla y secciones por mundo integrados. Correcciones visuales de profundidad, plato y márgenes revisadas independientemente. |
| Recorrido y sala | Marcha en dos ejes, obstáculos, profundidad, continuación y diario aprobados en `validate_village_roaming`. Tandas locales con apoyos persistentes; `validate_challenge_planner` aprobada. Retiradas las elecciones obligatorias de acomodo de las misiones. |
| Actuaciones y magia | Corregidas: picos de perfil en contacto con la abertura dibujada, alimento servido en cuencos apoyados, mano y palma visibles de Ma’ax, aroma junto a la porción y pies plantados también en reproducción continua. Secuencias ampliadas de mirada, acercamiento, contacto y regreso revisadas por especie. |
| Cierre | Correcciones funcionales y visuales verificadas. Godot 4.6.3: 35/35 suites descubiertas aprobadas sin errores ni advertencias después del último cambio de ejecución/arte. Estructura, tipos, herramientas, catálogos, formato y espacios aprobados. Supervisión contrastó el registro y las nuevas capturas; cierre aceptado el 28 de octubre de 2026. |

Evidencia vigente de supervisión en `.ui-review/supervision_2026_10_28/`:
`actions_v7/` contiene tarjetas, libro, atlas y secuencias ampliadas; `home/` conserva
la orientación completa en escritorio y compacto. El registro completo final es
`.ui-review/supervision_full_final.log`. Las carpetas `new_plan/` y las iteraciones
anteriores documentan el trabajo previo y no sustituyen esta evidencia.

Se mantienen economía, historia e identidades del vocabulario. Los iconos usan una
sola figura con regla neutra y coinciden con el ejemplo canónico; fuerte muestra
un mueble reforzado. Se retiró el recurso antiguo de piedra. La prueba de contacto
contrasta píxeles del pico con la abertura dibujada del vaso; la aceptación visual
incluye las fases ampliadas y no se deduce sólo de anclas numéricas.

La supervisión de este chat contrastó patio, taller, orilla, proyecto, construcción,
mesa de trazos, sala, misiones y perfiles de escritorio y compacto. Devolvió cuatro
observaciones antes de aceptar: iconos antiguos de tamaño, contacto real del pico,
porciones flotantes y orientación recortada. La evidencia nueva muestra iconos sin
copias fantasma ni palomitas, ejemplos coherentes, picos en la abertura del vaso,
alimento servido y mano visible de Ma’ax. Se revisaron fases discretas de las doce
especies y se comprobó que el registro completo y las capturas clave no cambiaron
entre la revisión y el cierre. No se volvió a ejecutar el motor desde supervisión.

El seguimiento automático se retira al aceptar esta entrega. Continúan pendientes
la revisión con mayahablantes, audios, pruebas con niños y exportaciones en
dispositivos. Esta aceptación no certifica aprendizaje ni esas pruebas externas.
El guardado vigente es formato 9: las partidas de otra versión requieren reinicio
explícito y no se convierten ni sobrescriben automáticamente.

## Refinamiento de paseo y aldea solicitado el 28 de octubre

El usuario pidió conservar los saltitos característicos en todas las escenas y
mejorar orientación, atractivo y densidad visual de la aldea final, reduciendo
saturación de controles. Este ajuste se realiza en la conversación supervisora,
sobre la misma base; no abre otra sesión ni modifica economía o guardado.

- El recorte completo de Kalin salta también al caminar en dos ejes, con sombra y
  profundidad estables; parado y con movimiento reducido vuelve a su base.
- Mapa accesible con botón y M, con ubicación actual, destinos y bloqueos por mundo.
  Abrirlo conserva pausa y foco. Esc sigue dando acceso a pausa durante el paseo.
- Un clic en un letrero inicia la ruta y entra al destino al llegar. El patio ya
  no ofrece una salida hacia sí mismo; las flechas mantienen los destinos correctos.
- Nuevos fondos SVG de patio, taller y orilla: vegetación, senderos, detalles propios,
  sala, banco, herramientas y muelle, manteniendo libre el espacio para construir.
  Casas, vecinos y Kalin usan escalas menores. Los cuatro vecinos conocidos se
  distribuyen sin superposición; sólo Áak y Miis se reúnen junto a la mesa del proyecto.
- Editor con selección de objeto antes de variante, catálogo oculto al colocar,
  herramientas contextuales y controles de viaje ocultos mientras se decora.
- Estado: implementado y verificado con Godot 4.6.3. La última ejecución completa
  aprobó las 35 suites descubiertas sin errores ni advertencias. Pasaron también
  política de tipos, estructura, herramientas, catálogos, formato y espacios.
  Las capturas de escritorio y compacto se revisaron después de corregir vecinos
  superpuestos y nombres de acceso incoherentes. La regresión antigua de pies
  alternos se actualizó al salto completo pedido por el usuario, conservando la
  comprobación de identidad, parada y movimiento reducido.
  Evidencia: `.ui-review/village_polish_2026_10_28/final/`; registro completo vigente:
  `.ui-review/village_polish_full.log`.

## Criterios comunes

- Conservar el estilo de recortes SVG, formas planas, paleta y personajes actuales.
  Los bocetos orientan la distribución, no sustituyen el arte por fondos pintados.
- Reutilizar únicamente palabras y combinaciones canónicas. La confirmación con
  mayahablantes y los audios siguen pendientes; no ampliar la gramática por inferencia.
- Las pruebas con niños se realizarán después de terminar el producto, según la
  dinámica del profesor. No bloquean esta implementación.
- Distribuir mejor la práctica existente antes de añadir ejercicios obligatorios.
- Mantener teclado, toque, foco, pausa, movimiento reducido y continuación.
- La evidencia describe acciones observadas; no certifica dominio ni retención.

## Orden y aceptación

| Orden | Trabajo | Criterio de aceptación | Estado |
|---|---|---|---|
| 1 | Mantenimiento | Estado de encargos y plan de preguntas separados; API pública del arte | Implementado y validado |
| 2 | Evidencia y libro | Ayuda de manejo separada de pistas; reconocer, reconstruir, escribir y usar diferenciados; detalle accesible sin hover; JSON sin duplicar resultados | Implementado y validado |
| 3 | Taller y comida | Petición estable a la izquierda, respuesta a la derecha; composición compacta; conservar práctica y recuerdo sin revelar soluciones | Implementado |
| 4 | Interpretar pedidos | Fichas conocidas, traducción como apoyo y respuesta visual; reconocimiento separado de escritura | Implementado con fichas canónicas |
| 5 | Animación | Recepción, acomodo, ritmos por personaje y poses apoyadas; pausa y accesibilidad | Implementado y validado |
| 6 | Culminación común | Tres personajes utilizan sus encargos juntos; restaurar no duplica recompensas | Implementado |
| 7 | Experimentación | Rincón opcional con combinaciones permitidas y aprendidas; resultados visibles; nunca acredita recuerdo independiente | Implementado |
| 8 | Ritmo por episodios | Alternar modalidades preservando cobertura y sin sumar rondas obligatorias | Implementado y validado (P1) |

## Detalle funcional

### Aprendizaje

La orientación explica controles y no revela palabras. La pista lingüística,
consulta del libro, corrección de grafía, reconstrucción y errores pertenecen al
intento y sobreviven a reanudar. En respuestas de varias palabras se conservará
la evidencia independiente de las partes correctas cuando el apoyo de otra parte
no las revele. El libro mostrará el estado breve y un detalle visible por toque o
teclado, con contadores diferenciados. La consulta de ese detalle no debe robar el
foco al cerrar el libro. Los formatos incompatibles se rechazan sin borrarlos;
se documentará la versión nueva y el reinicio requerido, sin migraciones.

### Presentación

Taller y comida conservarán una estructura común entre tarjetas y escritura. La
petición y el personaje permanecen visibles. Las tarjetas tendrán espacios de
destino contenidos y alineados. Durante la escritura habrá una sola representación
editable de la respuesta, sin una segunda mesa que repita las mismas palabras.
El resultado visual se mostrará después de confirmar; durante el recuerdo no
aparecerá la ilustración esperada. Los cambios de geometría compacta pertenecerán
a los perfiles de distribución. Este criterio incorpora la revisión del usuario
posterior a P1 y sustituye la decisión inicial de reflejar lo escrito en otra franja.

### Aldea y animación

Los pedidos interpretados usarán expresiones ya enseñadas. La traducción disponible
se registra como apoyo de contenido. Los resultados compartidos aprovecharán las
misiones existentes: rincones, fiesta y comida. Las entregas mostrarán recepción,
acomodo y uso; los habitantes conservarán sus diferencias y Kay su orilla. Los
brillos deben identificar interacción o magia, evitando competir continuamente.

El rincón de experimentación será opcional, con salida inmediata y sólo contenido
conocido. Una creación experimental no completará un encargo ni contará como
escritura o recuerdo. No habrá combinaciones arbitrarias fuera del catálogo.

## Validación y pendientes

Cada entrega registrará aquí qué se implementó y qué falta, con archivos o suites
relevantes. La aceptación requiere las comprobaciones de Mantenimiento, suites
afectadas, validación completa y revisión visual de escritorio y compacto. Una
captura de escritorio no confirma una exportación móvil ni el teclado del aparato.

Pendientes externos: revisión lingüística, audio, observación con niños y pruebas
de exportación en dispositivos objetivo. No se darán por aprobados por las suites.

## Primera entrega (registro anterior a la continuación)

- Formato 7: `LearningAttempt` conserva orientación y evidencia por palabra;
  `LearningProgress` diferencia reconocimiento, reconstrucción, escritura, uso,
  grafía y experimentación. El libro incorpora **Ver mi práctica**. La parte correcta
  de una respuesta se conserva antes y después de JSON; la consulta de contenido
  sí marca apoyo. No hay conversión de partidas antiguas.
- Los campos de respuesta son verticales. Taller y comida conservan sus fondos y
  personajes; dos SVG planos nuevos aportan el globo y la escena de celebración.
  Los perfiles permiten alturas de recuerdo de una o dos palabras. Aquella entrega
  reflejaba lo escrito en una franja; R1 retiró esa duplicación.
- Los paseos existentes ahora permiten interpretar fichas; la traducción es opcional
  y queda registrada. Se sustituyó la modalidad de esos encuentros, sin añadir
  rondas obligatorias. Reanudar orienta sobre la petición, sin señalar la solución.
- **Probar hechizos** abre el laboratorio opcional en las misiones. Se filtran las
  combinaciones por palabras descubiertas. La práctica se registra una vez por
  combinación y visita; no se crean entregas ni recuerdo independiente. Consultarlo
  durante un encargo marca apoyo para ese encargo.
- Al terminar los tres encargos aparece una celebración con los destinatarios y
  sus objetos. `gathering_seen` se confirma al cerrar. La recepción se reproduce
  sólo en una entrega nueva; restaurar mantiene las poses. Áak y Ma'ax tienen
  ritmos distintos; los alimentos provocan una inclinación hacia el objeto y Kay
  conserva la orilla. Los brillos de exploración se concentran cerca de Kalin.
- `VillageMissionState` posee el progreso y su restauración. `StoryQuestionPlan`
  prepara copias deterministas. `VillageGathering` y `SpellLaboratory` poseen su
  presentación. El animador usa la API pública del arte y no busca a Kalin en
  ancestros ajenos. Las escenas conservan los datos editables del Inspector.

## Trabajo posterior concreto

### P1. Redistribuir las rondas en episodios — completado y validado

`PhraseExerciseSession` alterna grupos de hasta tres retos: práctica, recuperación
del grupo y siguiente episodio. Los seis retos actuales conservan doce rondas,
con una presentación anterior a cada recuperación y el primer ejemplo sencillo.
La semilla determina el plan completo; repetir cambia el orden posterior al ejemplo.

`MissionBreak` anuncia **Recordar** o **Practicar**, conserva el foco y deja el paseo
opcional entre episodios. Volver del paseo conserva la ronda, sin agregar copias de
ejercicios. El contador de modalidad consulta el plan real. Los planes completos ya
iniciados conservan su orden en el formato 7, sin migración ni reinicio adicional.

Se actualizaron los fixtures que suponían una única mitad guiada. La suite
`validate_phrase_episodes` comprueba cobertura por reto, determinismo, planes
anidados inválidos, JSON desde cada ronda, finalización, repetición, evidencia,
apoyos y borradores en ambos episodios, foco y retorno del paseo. Las regresiones
existentes mantienen la cobertura de libro, transacciones y accesibilidad.

### P2. Animaciones específicas de mirada, manos y consumo — completado y validado

`VisualCatalog` contiene tres poses por cada uno de los doce animales. La secuencia
mira el encargo, alcanza con pata/mano/ala/aleta y lleva una porción o gota a boca o
pico; las aves inclinan la cabeza al picotear. Áak y Ma'ax conservan ritmos distintos.
`VillageUseMotion` mantiene suelo, capas de hamaca y orilla de Kay, y detiene el
movimiento con pausa o movimiento reducido. La recepción inicial sólo se lanza en
una entrega nueva. Atlas y secuencias en contexto se incluyen en la revisión final.

### P3. Separar las interacciones de historia — completado y validado

`StoryInteraction` posee presentación, entrada, selección, conocidos, saludos,
intento y resolución de conocer/adivinar/elegir. Expone eventos públicos, snapshots,
bloqueo, foco y restauración. `StoryScene` conserva momentos, texto y navegación;
los controles y propiedades del Inspector permanecen editables. `StoryQuestionPlan`
sigue siendo el único preparador del plan. Restaurar un acierto repone la vista sin
registrar otro reconocimiento; su regresión se añadió a la suite de interacción.

### P4. Frases completas y repaso diferido

Después de confirmar el contenido con mayahablantes, evaluar reemplazar algunas
fichas por peticiones completas ya revisadas. El modo actual no declara que
`objeto · cualidad` sea una oración. El repaso a días distintos y sus datos de fecha
no están implementados; los intervalos de recuerdo siguen medidos en ejercicios.

## Comprobaciones de esta entrega

`validate_product_improvements` cubre orientación, evidencia por palabra, JSON,
rechazo de datos anidados, persistencia de traducción, laboratorio, celebración,
libro y composición de escritura/bloques en escritorio y compacto. El ejecutor
admite `-CaptureDirectory` conservando el aislamiento de partida y preferencias.
Las capturas de revisión quedan en `.ui-review/implementation/` (no versionadas).

Comprobaciones ejecutadas con Godot 4.6.3 y las herramientas fijadas del proyecto:

- Validación completa: todas las suites descubiertas aprobadas, sin errores ni
  advertencias del motor. Incluye el atlas de animales y encargos, checkpoints,
  transacciones, accesibilidad y las regresiones de esta entrega.
- Revisión con renderer real y capturas de taller, comida, interpretación,
  laboratorio, celebración y libro; perfiles de respuesta de escritorio y compacto.
- Estructura, política de tipos y dependencias, formato y `git diff --check`.
- Pruebas de herramientas y comprobación de los tres catálogos generados.

Aquella entrega usaba el formato 7; la continuación R4 lo sustituye por el 8. Las partidas de versiones anteriores se
rechazan sin sobrescribirlas; para empezar con esta entrega se debe usar el
reinicio explícito del menú. Las pruebas aisladas no modificaron la partida personal.

## Validación de la continuación P1

Comprobaciones ejecutadas el 27 de octubre de 2026, con Godot 4.6.3 y
gdtoolkit 4.5.0, conservando los cambios de trabajo anteriores:

- `tools/validate.ps1`: todas las suites descubiertas aprobadas, sin errores ni
  advertencias del motor. Incluye la nueva
  [suite de episodios](../tests/validate_phrase_episodes.gd), aprendizaje por palabra,
  checkpoints, transacciones, repetición, teclado, libro y accesibilidad.
- La suite de episodios pasó también con renderer real mediante
  `-Suite validate_phrase_episodes -CaptureDirectory`. Se revisaron las pausas y
  las modalidades de Taller y Comida en escritorio y compacto. Las capturas están
  en `.ui-review/episodes/`, sin versionar.
- Estructura y enlaces, política de tipos y dependencias, pruebas de herramientas,
  formato y `git diff --check`: aprobados.
- Comprobación `--check` de combinaciones, tableros y diálogos: aprobada, sin cambiar
  catálogos, contenido lingüístico ni firmas de recursos.

La cobertura nueva comprueba una presentación y una recuperación por reto, JSON
desde cada ronda, evidencia sin duplicar al reabrir resultados, borradores y apoyos
en ambos episodios y regreso del paseo. El foco diferido de `MissionBreak` se
descarta cuando la UI ya salió del árbol; hay una regresión para ese ciclo de vida.
Se mantienen los planes completos ya iniciados y el formato 7, sin migración ni
reinicio adicional por P1. Las pruebas usaron los perfiles aislados del ejecutor.

P1 no tiene pendientes de implementación o validación local. P2 y P3 se realizaron
en la continuación descrita más abajo.
P4 conserva su dependencia de revisión lingüística y la evaluación del repaso
diferido. Los audios y la revisión con niños y mayahablantes siguen siendo
pendientes externos; también faltan las pruebas de exportación en dispositivos
objetivo. Las capturas de escritorio no sustituyen esas comprobaciones.

## Continuación autónoma acordada después de P1

El usuario pidió una sola sesión que continúe entre etapas sin esperar una orden
por cada pendiente, con un crítico visual independiente antes del cierre. También
aprobó implementar tres encargos conectados con una meta visible y recorridos
cortos, y sustituir el emparejamiento final de etiquetas por una despedida donde
una elección cambie el recuerdo que Kalin lleva a casa.

Las capturas aportadas evidencian fallos pendientes pese a la validación funcional:
espacios de composición fuera de su caja, respuesta escrita repetida, cola del
globo alejada del personaje y una culminación basada en emparejar etiquetas
idénticas. La revisión anterior no basta para aceptar esos aspectos visuales.
Las referencias locales se conservan en `.ui-review/references/feedback_2026_10_27/`.

### Orden de ejecución y aceptación

| Orden | Trabajo | Aceptación | Estado |
|---|---|---|---|
| R1 | Corregir Taller y Comida | Tarjetas y destinos dentro de sus cajas; una sola respuesta durante escritura; globo asociado visualmente al animal; resultado después de confirmar | Completado y validado |
| R2 | Contextualizar peticiones | Motivo y voz del personaje en español junto a las fichas canónicas; contexto sin traducir automáticamente el objetivo; traducción explícita conserva su registro de apoyo | Completado y validado |
| R3 | Dar propósito y variedad a la aldea | Tres aportes a un resultado compartido visible, acciones diferentes y orden elegible; recorridos cortos con navegación directa accesible; sin sumar rondas obligatorias | Completado y validado |
| P2 | Actuaciones de los personajes | Mirada, alcance y consumo distinguibles; apoyo físico y profundidad correctos; compatibilidad con pausa y movimiento reducido | Completado y validado |
| R4 | Cierre con una decisión significativa | Se retira el emparejamiento de etiquetas; elegir un recuerdo produce un cambio visible en el regreso a casa; no hay respuesta personal incorrecta ni evidencia educativa ficticia | Completado y validado |
| P3 | Separar interacciones de historia | Colaborador propio para presentación y entrada; escena conserva composición y navegación; foco y reanudación comprobados | Completado y validado |
| R5 | Revisión final independiente | Crítico inspecciona capturas y secuencias del último estado; observaciones bloqueantes corregidas y verificadas, además de la validación funcional completa | Completado y validado |

### Dirección de la aldea

Cada visita debe construir una situación, no sólo acumular tres conversaciones y
tres entregas. En Casa, los objetos forman un rincón que los habitantes utilizan;
en Fiesta, sus cualidades se aplican al preparar un espacio común; en Comida,
los pedidos desembocan en una mesa compartida. El resultado de una acción debe
estar presente en la siguiente y poder verse al terminar.

Variar la acción mediante elegir un lugar pertinente, colocar o ajustar un objeto
y servir a un destinatario, utilizando el contenido canónico y la cobertura actual.
No convertir cada encargo en tres ejercicios adicionales ni exigir precisión
motora para avanzar: toque y teclado deben tener una alternativa equivalente.
El jugador podrá elegir el orden de los aportes. Una plaza compacta con zonas de
actividad y acceso directo opcional evita desplazamientos repetidos de extremo
a extremo. Ajustar únicamente la velocidad no resuelve la repetición.

Las peticiones pueden empezar con una situación breve en español y terminar con
las fichas mayas conocidas. No inventar oraciones mayas ni copiar automáticamente
la traducción del objeto dentro del contexto cuando se evalúa interpretación.
Reutilizar la personalidad y fuentes de diálogo existentes; editar sus fuentes,
no los módulos generados, cuando sea necesario ampliar el contexto.

### Dirección de la despedida

Conservar el significado de despedirse y volver a casa. Retirar la tarea de
arrastrar Caminos/Hogar/Amistad sobre otras etiquetas idénticas. Tras la despedida,
el niño elige qué recuerdo quiere llevar: una imagen o breve escena recupera
algo que sí vivió en la aventura. La selección se ve durante el cierre y al llegar
a casa, y tiene una confirmación clara para cruzar el portal. No añadir otro
cuestionario ni puntuar esa preferencia como acierto. Retirar los consumidores y
estado que dejen de tener uso, respetando el contrato vigente de guardado o
versionándolo si cambia de forma incompatible.

### Criterio del crítico

El crítico será un subagente distinto del implementador, con función de revisión
sin editar los mismos archivos. Debe ver imágenes reales del renderer, no decidir
sólo por el código, por coordenadas esperadas o por el resultado de las suites.
Revisará escritorio, la proporción de ventana aportada por el usuario y compacto;
tarjetas, escritura, ayuda, acierto, contexto de aldea, uso de objetos y cierre.
Las animaciones requieren secuencias de instantes significativos, no una sola pose.

Comprobar contención, legibilidad, foco visible, ausencia de texto duplicado,
relación globo/personaje, apoyo de pies y muebles, capas y propósito de cada acción.
Las capturas definitivas se tomarán después de la última corrección. Registrar aquí
las observaciones concretas, qué se corrigió y la evidencia usada para aceptarlo.
Si no se puede observar el resultado, la revisión visual queda pendiente. La
aceptación interna no sustituye la observación futura con niños.

La sesión continuará por los trabajos independientes si aparece una dependencia
externa. Audio y confirmación lingüística permanecen fuera de alcance. El repaso
entre días sigue como diseño pendiente de P4; no debe confundirse con esa revisión
lingüística ni declararse implementado al cerrar esta etapa.

### Implementación y aceptación final de la continuación

- R1: se retiraron `RecallWorkbench`, sus recursos y consumidores. Las alturas de
  escritura y bloques proceden de perfiles. Los destinos caben en su caja; la cola
  del globo apunta al animal. La creación se revela al confirmar el acierto.
- R2: `purpose` en la fuente de diálogos añade motivo y personalidad sin copiar la
  traducción del objetivo. Se regeneró el catálogo; pedir traducción conserva apoyo.
- R3: una plaza compacta conserva los tres aportes; el orden es elegible y hay
  accesos directos por toque y teclado. Casa elige lugar, Fiesta ajusta el acomodo
  con una barra y Comida sirve al destinatario. No se añadieron rondas lingüísticas.
- R4: se retiraron páginas/destinos idénticos y símbolos sin consumidores. El niño
  elige un momento de una visita completada o de la cortesía que acaba de compartir.
  La imagen elegida aparece junto al portal y en casa; no hay respuesta incorrecta
  ni evidencia educativa. El formato único ahora es **8** y rechaza el 7 sin
  sobrescribirlo; requiere reinicio explícito. P1 conserva su distribución de rondas.
- P2/P3: implementados como se describe arriba. F3 hace optativo el overlay DEBUG;
  F4 sigue disponible y el juego normal empieza sin controles de depuración encima.

El crítico independiente inspeccionó referencias, capturas reales y secuencias.
Encontró y se corrigieron: texto sin margen, avisos bajo paneles, Kalin cubierto
por el selector, ausencia de picoteo, recuerdo de comida fuera de su tarjeta y
controles compactos sobre las consecuencias. Se añadieron etiqueta de acomodo,
franja inferior propia de misiones y capturas compactas de acciones y petición.
La revisión independiente final de las recapturas no encontró bloqueantes. Incluyó
1280×720, la ventana 1280×684 de la referencia y 640×360; tarjetas, escritura,
ayuda, error, acierto, foco, peticiones, acciones de la plaza, portal y regreso.
Las secuencias de comer y beber muestran mirada, alcance, consumo y reposo en
0,2; 1,1; 1,7 y 3 segundos, con los doce animales y con Ma'ax, Kaax y Kay en la plaza.
El crítico también inspeccionó el caso canónico de mobiliario en Comida: los
muebles permanecen en el suelo y el modal distingue colocar de servir. Este
dictamen no implica una inspección individual de las 444 composiciones del atlas.

### Evidencia final de la continuación

- `validate_revision_outcomes` pasó con renderer real y capturas finales en
  `.ui-review/final/`. Comprueba respuesta única y resultado tras confirmar,
  orden elegido de aportes, acceso con Enter, acomodo con flechas, JSON antes y
  después de confirmar, uso acreditado una sola vez, traducción como apoyo y
  dos recuerdos distintos que reaparecen en casa sin producir evidencia educativa.
  También comprueba pausa, movimiento reducido y trabajo diferido descartado al
  retirar una interacción o distribución del árbol.
- `validate_visual_flow` comprueba que un error conserva las tarjetas para
  corregir sin ilustración y que el acierto confirmado sí muestra la creación;
  se retiró la expectativa anterior de previsualizar una respuesta incorrecta.
- `validate_village_composition` pasó con renderer real: 444 composiciones.
  Las capturas finales del atlas están en `.ui-review/final_atlas/`.
- El crítico aceptó las capturas y secuencias del último estado, incluidas
  `mesa_con_mobiliario`, `colocar_mueble_en_mesa` y sus variantes compactas;
  reconfirmó el regreso, el pedido largo y el consumo en compacto.
- Política de tipos y dependencias, estructura, formato y `git diff --check`:
  aprobados. Las 10 pruebas de herramientas y los tres catálogos generados pasaron.
- La pasada completa final de `tools/validate.ps1` aprobó **30/30 suites** con
  Godot 4.6.3, sin errores ni advertencias del motor. Registro local:
  `.ui-review/full_validation.log`. R1–R5, P2 y P3 quedan completados y validados
  el 27 de octubre de 2026; P1 conserva su cobertura y comportamiento.

Los perfiles del ejecutor mantuvieron aisladas la partida y las preferencias
personales. Las capturas y registros de `.ui-review/` son evidencia local sin
versionar. Audio, revisión lingüística, observación con niños, exportaciones en
dispositivos objetivo y P4 permanecen fuera de esta aceptación.

## Revisión de diseño posterior: aldea, creación y actuaciones

Estado al comenzar esta revisión: **diseño y prototipos**. La autorización posterior
del 27 de octubre permite implementar el alcance acordado en una nueva sesión.
El usuario pidió resolver las decisiones, probar bocetos y movimientos, registrar
lo acordado y sólo después abrir otra sesión de implementación. La aceptación
funcional anterior describe la entrega anterior; no cierra las observaciones
visuales y jugables nuevas.

### Decisiones confirmadas por el usuario

- Público de 10 a 12 años, con lectura autónoma y lenguaje sencillo.
- Computadora con ratón y teclado como dispositivo prioritario.
- Se puede reemplazar la estructura fija de doce preguntas, conservando vocabulario
  y oportunidades de aprender. No es necesario conservar esa cantidad como cuota.
- Historia principal de 30–60 minutos como objetivo de diseño, aún sin medición
  con niños. Se desea contenido posterior capaz de sostener varias horas.
- El centro del contenido posterior será construir y personalizar una aldea que
  crece. Los relatos, descubrimientos y retos pueden acompañar ese crecimiento.
- Actuaciones propias de cada especie: Ma'ax puede sujetar un vaso; las aves acercan
  el pico; Kay permanece en el agua. No convertir a todos en el mismo humanoide.
- Mantener el estilo gráfico actual y resolver versiones de arte inconsistentes.
  Audio y confirmación de contenido con mayahablantes continúan pendientes.

### Diagnóstico comprobado

- La plaza concentra tres destinatarios, tres vecinos, casas, aportes, Kalin y
  controles de varias tareas. El espacio disponible y las escalas no sostienen
  todas esas presencias en primer plano sin ocultaciones.
- `VillageActivity` ofrece elecciones de ubicación pero la vista previa sólo
  cambia entre desplazamientos de -28, 0 y 28. La composición de la misión añade
  36 píxeles por posición. No hay una consecuencia de uso distinta que justifique
  presentar cada ajuste como una nueva decisión obligatoria.
- `MeaningIllustration` usa representaciones distintas según `world_object`:
  el contexto normal añade `prop_peso` a fuerte; el mundo usa muebles reforzados
  de `VillageUseArt`. Las ilustraciones de tamaño contienen otra mesa translúcida
  y una marca de acierto dibujada en el propio recurso.
- `SpellLaboratory` muestra objeto en maya y español, pero cualidad sólo en maya;
  los selectores son `OptionButton` y sus listas abiertas no conservan el diseño.
- `VillageWalk._request_text()` concatena propósito, salto de línea y fichas: no
  integra el pedido dentro de una intervención continua del personaje.
- `VillageUseMotion` cambia poses, pero comparte fases y trayectoria de una porción
  que viaja del objeto a la boca; para agua utiliza una gota. Algunas poses de
  alcance agregan una extremidad sin retirar la pieza original. Se revisaron el
  código, los SVG y las secuencias reales de comer y beber de la entrega anterior.

Las capturas aportadas por el usuario se conservarán como referencia local en
`.ui-review/design_review_2026_10_27/`. Son evidencia de problemas, no diseños
aprobados ni instrucciones incrustadas.

### Propuestas de espacio y navegación — pendientes de elección

| Boceto | Interacción | Ventaja | Coste o límite |
|---|---|---|---|
| Aldea por barrios | Caminar y pasar entre patio, orilla y taller; interacción directa con el animal | Mantiene aventura y espacio para ampliar la aldea | Requiere composición y cámara por zona; evitar trayectos vacíos |
| Mapa y acercamiento | Elegir un lugar ilustrado y entrar en una escena cercana | Acceso rápido y separación clara de actividades | Menor sensación de recorrer un mundo continuo |
| Escena del encargo | Una situación concreta con pocos personajes y una consecuencia visible | Foco claro y pocas acciones simultáneas | Menos libertad durante la misión; puede combinarse con exploración libre |

Recomendación provisional: barrios para el mundo persistente, escenas cercanas al
interactuar y mapa como acceso rápido opcional. No son tres sistemas obligatorios:
se elegirá cuánto de cada uno aporta valor después de comparar los bocetos.
Las variantes ilustran escala, espacio e interacción; no contienen el juego ni
constituyen validación de usabilidad con niños.

### Interfaz y decisiones de ubicación

Propuesta: dejar Libro y Pausa como controles generales. La ayuda aparece dentro
de la acción que la necesita; el resumen de encargos se consulta desde el libro.
Los nombres sobre los animales sirven para identificarlos, no forman otra barra
de navegación permanente. Un solo control contextual ofrece conversar, crear,
entregar o continuar según lo que pueda hacerse en ese momento. El taller se abre
desde su lugar físico, no desde un botón inferior permanente en todas las escenas.
Conservar controles visibles por teclado y señales de qué es interactuable.

Retirar del recorrido obligatorio las elecciones de ubicación sin efecto. En una
misión, el objeto puede aparecer directamente en el lugar funcional y el animal
lo utiliza. Si se diseña una decisión espacial, las alternativas deben cambiar de
forma visible y persistente el uso, el recorrido o la composición, con anticipación
clara y posibilidad de corregir. No inventar tres respuestas sólo para añadir clics.

El acomodo libre sí tiene un lugar coherente en la personalización posterior:
construir un rincón propio. Habrá que elegir entre colocación libre con zonas
válidas y composiciones amplias predefinidas. Evitar un menú obligatorio de ajuste
por cada objeto creado y no puntuar una preferencia estética como acierto.

### Recorrido principal — propuesta pendiente de validar

Sustituir la suma de ejercicios, paseo opcional y otra misión de encargos por una
única necesidad narrativa que atraviesa aprendizaje y uso. Secuencia propuesta:

1. Conocer un problema de un personaje en el lugar donde ocurre.
2. Descubrir o practicar las palabras necesarias con apoyos disponibles.
3. Resolver otro momento usando esas palabras, con recuperación separada cuando
   sea posible, sin revelar la solución por la propia decoración de la pantalla.
4. Ver la consecuencia en la aldea y continuar con otra situación o explorar.

No habrá dos visitas equivalentes seguidas como deuda por saltar un paseo opcional.
La exploración libre permite conversar, investigar y crear, sin acumular rondas
obligatorias atrasadas. Variar reconocimiento, construcción y recuperación por su
función en la situación; no pedir elegir, escribir y entregar siempre la misma
respuesta en tres pruebas seguidas. Definir antes de programar una matriz de
cobertura por palabra y situación, manteniendo la distinción de evidencia.

El presupuesto temporal orientativo para la historia es: llegada 3–5 minutos,
caminos y animales 10–15, casa 5–8, fiesta 6–10, comida 6–10 y cierre 3–6. Son
objetivos de ritmo, no tiempos comprobados. La longitud final requiere recorrido
completo y observación posterior con niños.

### Creación y arte — dos bocetos y un contrato común

- **Mesa de trazos:** Kalin crea en un claro o mesa visible del mundo. Fichas de
  objeto y cualidad con dibujo y traducción; trazo, aparición y transformación.
- **Libro que transforma:** las selecciones viven en una página; la otra muestra
  cómo las palabras dan forma al objeto. Es más compacto y conserva el libro como
  centro de la aventura.

Ambos bocetos sustituyen las listas nativas por fichas del mismo sistema visual.
En práctica libre, objeto y cualidad tienen maya y español de forma consistente.
Los apoyos en situaciones de recuperación conservan sus reglas propias. El mensaje
técnico sobre cómo se acredita la evidencia no ocupará la instrucción del niño;
el detalle permanece en la vista de práctica del libro.

Propuesta de secuencia: anticipación breve de Kalin, trazado, materialización del
objeto, cambio de cualidad y reposo. No reproducir todo el gesto al recorrer opciones
ni usar destellos continuos. Poder repetir y ofrecer un estado inmediato con
movimiento reducido. En los bocetos puede ajustarse la duración para comparar.

Unificar el significado visual en un propietario de arte canónico: cartas, libro,
laboratorio, peticiones, escena y recuerdos deben representar la misma versión
de cada combinación. Las diferencias de encuadre y oclusión no deben cambiar su
identidad. Fuerte se muestra con estructura reforzada, sin volver a la piedra.

Para pequeño/grande, se propone un solo objeto que cambia de escala respecto de
un personaje o referencia estable, manteniendo suelo y cámara. Una comparación
de dos objetos sólidos sólo se usaría en una demostración explícita y separada.
Retirar las copias fantasma y las palomitas de la ilustración permanente; reservar
el acierto para la respuesta a una acción. Las combinaciones permitidas siguen
dependiendo del catálogo; no prometer cualquier unión de objeto y cualidad.

### Pedidos integrados

Propuesta de intervención: «Para reunirnos necesito “mayak chich”. ¿Me ayudas,
Kalin?». El objetivo aparece dentro de la intervención, destacado visualmente,
no como una etiqueta suelta después del contexto. Variar inicio, medio y cierre
mediante plantillas revisadas que conservan la personalidad del animal.

Esto es español de apoyo con vocabulario maya citado, no una oración maya nueva.
Las frases íntegramente mayas esperan la revisión con hablantes. La traducción
explícita sigue registrándose como apoyo. Las necesidades tendrán coherencia con
el lugar y la especie; no usar todo el catálogo aleatorio como si cualquier objeto
se sirviera o utilizara del mismo modo en cualquier situación.

### Actuaciones por personaje — propuesta de producción

Las pruebas de esta fase son estudios aislados con piezas SVG del arte actual;
no modifican Godot. Se prepararon Ma'ax/vaso, Kaax/borde y Miis/recipiente con avance
manual, reproducción y un instante de contacto. Todavía no son una biblioteca
de actuaciones terminada. Las doce direcciones propuestas son:

| Animal | Tratamiento propio |
|---|---|
| Peek' | Olfatear, acercar el hocico y beber de un recipiente apoyado; reacción de cola |
| Miis | Apoyo estable, acercamiento corto y lamido; cola independiente |
| Kaax | Pico al borde y cabeza arriba para tragar; alas recogidas |
| Áak | Cuello y cabeza lentos; caparazón y apoyos estables; recipiente bajo |
| Kéej | Bajar el cuello sin atravesar el recipiente; astas conservan separación |
| K'éek'en | Hocico y olfateo; contacto bajo, reacción breve de orejas |
| Ma'ax | Mano que alcanza y sostiene, vaso unido al agarre, devolución al apoyo |
| Kuuts | Picoteo y deglución distintos de Kaax; cola abierta condiciona el espacio |
| Báalam | Apoyo de patas y acercamiento del hocico, gesto más pausado que Miis |
| T'u'ul | Orejas y nariz activas, mordiscos cortos; apoyo de patas identificable |
| Kay | Sigue en el agua; alimento a la superficie y reacción bajo ella; no sujeta vaso |
| Ch'íich' | Pico y pequeños cambios de apoyo; consumo más ligero que las otras aves |

Usar piezas que sustituyen las extremidades originales, no dibujos añadidos sobre
brazos o patas existentes. Definir por animal pivotes, contactos, apoyos, oclusión,
anticipación y pausas. Compartir el control del ciclo de vida y las utilidades de
animación es compatible con trayectorias y actuaciones individuales; no implica
repetir el mismo gesto con otra velocidad.

No generar una animación exclusiva para cada combinación cartesiana de animal y
objeto. Diseñar familias de acción con contacto por animal y diferencias del prop:
beber, comer, sentarse, descansar, observar/recibir. Validar la anatomía y el alcance
en cada caso. En beber, el contenido y el recipiente permanecen unidos; se elimina
la gota que viaja desde la mesa a la boca. El movimiento reducido conserva la
consecuencia y una pose de contacto comprensible.

### Contenido posterior centrado en construir

Propuesta: desbloquear parcelas o rincones, elegir proyectos y dejar cambios
persistentes que los personajes usen. Ejemplos por concretar: merendero de la
orilla, patio de reunión, sendero entre casas y jardín de descanso. Cada proyecto
necesita una situación, una mecánica o decisión y una escena de uso propias.
Las palabras ya conocidas permiten hacer cosas nuevas, sin exigir vocabulario
que aún no ha sido validado.

Combinar proyectos diseñados con pequeños encargos variables y decoración libre.
No contar permutaciones de los mismos pedidos como si fueran horas de contenido
nuevo. Evitar esperas reales, cuota diaria o acumulación de recursos sin finalidad.
Las historias cortas de animales y secretos pueden abrir nuevos proyectos y dar
sentido al crecimiento. Queda por elegir el grado de libertad de colocación,
el alcance inicial de proyectos y sus condiciones de desbloqueo.

### Estado de decisiones y siguiente revisión

Confirmados público, dispositivo, libertad para cambiar las doce preguntas,
objetivos de duración, construcción como centro posterior y gestos por especie.
En la siguiente revisión el usuario eligió aldea por barrios, mesa de trazos y
construcción libre desde la historia, con materiales obtenidos principalmente
mediante retos de lenguaje. Los detalles vigentes se registran abajo. Continúan
pendientes el terreno concreto, la anticipación de magia, el balance y alcance de
los proyectos y la aceptación de las actuaciones refinadas.

Los prototipos locales se entregan en esta conversación y se conservan junto a sus
referencias en `.ui-review/design_review_2026_10_27/`. Se comprueban carga de arte,
controles y encuadre; esto no equivale a validar el juego ni esas mecánicas en Godot.
No se abrirá una sesión de implementación por el mero hecho de registrar este diseño.

Comprobación local de estos bocetos: las ocho variantes se abrieron a 1100, 736
y 360 píxeles de ancho, sin imágenes ausentes ni desbordamiento horizontal. Se
comprobaron navegación entre variantes, acercamiento desde el mapa, consecuencia
de un aporte, cambio de tamaño, creación por fases y movimiento reducido. Las
pruebas de actuación permiten detener y recorrer el instante de contacto; se
revisaron los tres estudios visualmente. No hubo errores JavaScript. Se guardan
capturas y `comprobacion-prototipos.json` junto a las referencias. Pasaron estructura
y `git diff --check`; no se ejecutaron suites de Godot porque esta fase no modificó
código, escenas, recursos ni arte del juego.

## Afinación elegida: barrios, construcción con materiales y revelación

Esta revisión sigue siendo de diseño. El usuario no ha solicitado abrir la
sesión de implementación. No se confunden prototipos locales con escenas terminadas
del juego ni se da el conjunto de decisiones por cerrado.

### Elecciones confirmadas

- Aldea por barrios con transiciones suaves, composición espaciosa y exploración.
  Kalin podrá moverse por el suelo en dos ejes, acercándose y alejándose.
- Mesa de trazos con Kalin como protagonista y magia visible. El resultado completo
  no debe revelarse sólo por pulsar las opciones de objeto y cualidad.
- Construcción libre, accesible durante la historia y ampliada progresivamente.
- La construcción consume materiales, obtenidos principalmente resolviendo retos
  de lenguaje. La exploración y los relatos conservan su función de ambientación,
  descubrimiento y acceso a proyectos.
- El ensayo en la mesa es gratuito. Los materiales se gastan al construir para
  la aldea; mover un objeto existente no vuelve a consumirlos.
- Refinar las actuaciones con atención a continuidad anatómica, apoyos y contacto.
  En concreto, se rechaza el desplazamiento aislado de la cabeza de Miis del primer
  estudio porque parecía separarse del cuello.

### Barrios y transición — propuesta refinada

Patio, orilla y taller tienen siluetas e identidad propias, caminos conectados y
suelo suficiente para caminar y colocar objetos. Limitar los personajes activos
del primer plano; distribuir las demás viviendas entre barrios y distancia, sin
reducir a todos para encajarlos en una sola pantalla. Reservar separación entre
viviendas, accesos, vegetación y habitantes. El agua y los accesos necesarios no
son terrenos de construcción.

Se propone continuidad de camino y desplazamiento suave de cámara, con fondo que
se mueve más lentamente. El estudio permite ajustar la duración entre 0,6 y 1,4
segundos; el valor inicial de 0,9 segundos es una prueba, no un tiempo aprobado.
Mantener a Kalin localizado y conservar el sentido de avance. Evitar encadenar un
fundido negro en cada paso. Durante el cambio no aceptar solicitudes duplicadas;
al llegar, devolver el control. Con movimiento reducido, usar una transición
inmediata o breve sin un desplazamiento amplio.

La exploración final necesita navegación por teclado y ratón, zonas transitables,
colisiones y profundidad compartida entre personaje y mobiliario. El estudio
actual ilustra espacio, cámara y destino al tocar el suelo; no contiene un ciclo
de marcha terminado ni sustituye ese trabajo de locomoción en Godot.

### Dos terrenos libres — pendientes de elegir

| Estudio | Alcance | Límite |
|---|---|---|
| Parcela de jardín | Suelo amplio con profundidad, junto al barrio y separado del sendero | Requiere resolver bien orden de capas, contacto y espacio entre objetos |
| Rincón junto al sendero | Franja más familiar a la composición lateral, con colocación libre | Menos profundidad y capacidad para composiciones grandes |

En ambos casos los límites aparecen al decorar, no durante todo el recorrido.
No son casillas de destino obligatorio. Elegir una pieza muestra una previsualización
de colocación; hacer clic en suelo válido la construye allí. Flechas y Enter dan
una alternativa al ajuste con el ratón. Un mueble ya construido se puede arrastrar
sin coste. Esc o Cancelar conserva materiales y posición anteriores.

La previsualización de colocación es distinta de la anticipación del hechizo:
al decorar ya se sabe qué objeto se va a incorporar. Señalar con texto y forma
cuándo falta espacio, faltan materiales o se invade el camino; no depender sólo
del color. Respetar el punto de agarre al arrastrar para que la pieza no salte.
Conservar las colocaciones en cada barrio al ir a otro. Guardar sólo posiciones
válidas después de confirmar la operación.

Los valores del estudio (8 de madera, 6 de fibras; mesa 3, silla 2 y hamaca 3)
son ilustrativos. No constituyen todavía un balance de recetas o recompensas.
La parcela de la orilla usa únicamente terreno seco. El diseño final tendrá que
comprobar accesos y usos de los personajes, además de evitar solapamientos.
Las orientaciones de muebles sólo se ofrecerán cuando existan vistas coherentes;
girar un dibujo plano no sustituye dibujar otra vista.

### Qué mostrar antes de crear — pendientes de elegir

- **Sello sin figura**, recomendado: señal mágica neutra que es igual para todas
  las combinaciones. Mantiene el resultado visual reservado al acto de crear.
- **Silueta del objeto base**: reconoce el sustantivo ya elegido, pero no anticipa
  refuerzos, tamaño ni decoración. Conserva tamaño neutro hasta la creación.

Cambiar las palabras oculta el resultado anterior. La secuencia elegida sigue
siendo anticipación de Kalin, trazo, materialización, cualidad y reposo. No ejecutar
la creación al pasar el cursor ni al seleccionar otra ficha. El estudio revela el
objeto después de iniciar el trazo; sólo entonces aplica tamaño o arte de cualidad.
El movimiento reducido conserva un resultado inmediato legible. Este ensayo no
descuenta materiales ni acredita escritura independiente.

### Materiales y aprendizaje — reglas para concretar

La fuente principal elegida son los retos de lenguaje. Se propone organizarlos
como peticiones y proyectos con situaciones variadas, no como una lista fija de
preguntas que se repite cada vez que falta madera. Alternar interpretación,
construcción y recuperación, con la misma honestidad de evidencia del juego.
Los proyectos dan un motivo para obtener materiales y un resultado que permanece.

Recomendaciones aún por acordar: recompensa base al completar un reto incluso con
apoyo, sin pérdida de materiales por equivocarse en una palabra; cantidades según
tipo de actividad y receta; recuperación o almacenamiento de muebles retirados;
y un suministro de misión que impida bloquear la historia por decorar antes.
La entrega de materiales debe confirmarse una sola vez y sobrevivir a reanudar sin
duplicarse. Los apoyos siguen describiendo aprendizaje, aunque el niño obtenga una
recompensa. La economía no puede usarse para inferir dominio lingüístico.

Antes de implementar falta definir el primer conjunto de proyectos, sus recetas,
recompensas y desbloqueos. Probar un ciclo completo: necesidad, reto, materiales,
construcción y uso del lugar. El objetivo de varias horas posteriores requiere
variedad diseñada y comprobación de ritmo; no se acredita con el número de
combinaciones ni con el tiempo necesario para repetir retos.

### Refinamiento de actuaciones

El segundo estudio de Miis mantiene las patas apoyadas y hace acompañar el torso
a la cabeza. La cabeza gira en la unión con el cuerpo, sin traslación independiente;
el collar pertenece al torso. El lamido se calcula desde la boca transformada y
regresa a reposo con la misma unión conservada. Se revisa toda la secuencia, no
sólo el fotograma de contacto. Se ajustaron también las alturas de los soportes
de los vasos de Ma'ax y Kaax para apoyar los recipientes en reposo.

Estos tres estudios siguen siendo pruebas aisladas, pendientes de aceptación
visual del usuario. No equivalen a las actuaciones definitivas de los doce
personajes. Para la producción se requerirán poses de cada especie, contacto por
tipo de objeto y revisión de transiciones, apoyos, profundidad y movimiento reducido.

Los archivos de esta ronda son `barrios-y-construccion.html`,
`mesa-y-revelacion.html` y `gestos-refinados.html`, con referencias y comprobaciones
locales en `.ui-review/design_refinement_2026_10_27/`.

Comprobación de esta ronda: siete variantes abiertas a 1100, 736 y 360 píxeles,
sin arte ausente, desbordamiento horizontal ni errores JavaScript. Se probaron
colocación con ratón y teclado, rechazo de solapamiento sin gasto, cancelación,
arrastre conservando el agarre y sin coste, conservación al cambiar de barrio y
transición con movimiento reducido. La revelación queda oculta al cambiar palabras;
la silueta conserva el mismo tamaño y figura base al cambiar cualidad. En Miis se
muestrearon 51 instantes: el pivote de cuello coincide entre torso y cabeza durante
toda la secuencia. Esto comprueba continuidad geométrica; la naturalidad aún
necesita el juicio visual del usuario y la futura revisión en el motor.

Se guardan capturas y `comprobacion-refinamiento.json`. Pasaron estructura y
`git diff --check`. Esta ronda sólo cambia documentación y estudios aislados;
no modifica ejecución, escenas ni arte canónico de Godot.

## Decisiones vigentes: puntos mágicos, diseños y composición

Esta sección sustituye la economía de materiales de los estudios anteriores.
Madera y fibras fueron propuestas exploratorias y **ya no son el sistema elegido**.
Este diseño quedó autorizado para implementación en una nueva sesión supervisada.

### Confirmado con el usuario

- Parcela de jardín con colocación libre, barrios espaciosos y movimiento en dos
  ejes. Empezar con patio, orilla y taller, dejando preparada una expansión del mundo.
- Sello sin figura antes de crear. No revelar la apariencia de la combinación al
  seleccionar sus palabras.
- Mantener el tratamiento refinado de las actuaciones y extender su atención al
  detalle a los demás animales, respetando su lógica de especie.
- Al retirar muebles, almacenarlos para reutilizarlos.
- Los puntos mágicos se gastan **una vez al desbloquear un diseño**. Sus copias
  posteriores son gratuitas; colocar, girar, mover y guardar no cuestan puntos.
- Cada objeto cuesta 10 puntos al desbloquearlo. El usuario también fijó 10 por
  cualidad: esta decisión posterior sustituye el acceso automático a toda variante
  conocida del diseño base. La compra de una cualidad es global: se utiliza con todos
  los objetos compatibles sin cobrar cada combinación.
  Las combinaciones siempre requieren palabras conocidas y validez en el catálogo.
- Los retos de lenguaje continúan siendo la fuente principal de progreso y puntos.
  El usuario aceptó un máximo acumulado de 10, con 10 sin ayuda, 6 con pista de inicio
  y 4 con tarjetas para completar; se conserva recuperar posteriormente la diferencia.
- Se aceptó el circuito de «Un rincón para compartir» como primer proyecto. Su
  preparación entrega 12 puntos fijos, una vez y antes de comprar. Inicialmente se
  ofrecen Mesa y Fuerte para garantizar su construcción con todos los apoyos.

### Mundo y participación de los animales

Los tres barrios iniciales deben tener accesos definidos y admitir crecimiento
hacia otras zonas. Reservar senderos y conexiones arriba, abajo y a los lados del
mapa. Una futura ampliación puede incorporar bosque, huerto, mirador o recorridos
con puentes; no es necesario implementar todo ese mundo para verificar el primer
proyecto. Los desniveles transitables requieren su propio diseño de suelo y pasos.

Distribución de roles propuesta, aún editable:

| Barrio | Animales y participación |
|---|---|
| Patio | Áak: reunión y descanso; Miis: organización de rincones; Peek': recibir visitantes; K'éek'en: preparativos de merienda |
| Orilla | Kay: vida del estanque; Ch'íich': mensajes y descubrimientos; Kéej: rutas; T'u'ul: jardines |
| Taller | Ma'ax: experimentar; Báalam: comprobar estructuras; Kuuts: decoración; Kaax: coordinar preparativos |

Cada animal necesita una intervención propia y un proyecto o consecuencia que
justifique volver a visitarlo. No basta sustituir el destinatario de una petición
genérica. Esta distribución no significa mostrar cuatro animales juntos todo el
tiempo: separar viviendas, escenas cercanas y personajes activos.

### Puntos: regla aceptada y detalles por cerrar

El código actual guarda puntos en `GameSession.magic_points`: entrega 10 por una
palabra nueva y 50 por nivel, una sola vez. Todavía no hay gasto, compra de diseños
ni un registro de complementos recuperables. Se deberá definir una política única
de recompensas que no sume por accidente premios del sistema actual y del nuevo.

Recompensa total aceptada al completar correctamente el objetivo:

| Apoyo de contenido utilizado | Máximo acreditable |
|---|---:|
| Sin ayuda | 10 |
| Inicio de palabra | 6 |
| Tarjetas para completar | 4 |

La unidad aceptada es el objetivo canónico de una palabra, no cada aparición ni
cada encargo compuesto. Una frase con objeto y cualidad puede contener dos
objetivos, con evidencias y apoyos propios. Cada uno acumula como máximo 10.

Detalles recomendados, todavía por confirmar con el cierre de reglas:

- Si se usan varios apoyos para la misma palabra, cuenta el más revelador utilizado,
  aunque se cierre después. La ayuda de controles no es ayuda lingüística.
- Sólo acreditar al completar correctamente. Equivocarse no resta puntos ni añade
  un descuento por fallo. No exigir un intento libre de toda corrección.
- Conservar el máximo histórico acreditado y entregar sólo la diferencia positiva:
  4 con tarjetas; una ocasión posterior con inicio entrega 2 más; otra sin apoyo,
  4 más. Total 10. Un intento inferior o una repetición ya completa entrega 0.
- La práctica obligatoria que muestra tarjetas o ejemplos desde el inicio se marca
  como guiada; no cuenta como producción sin ayuda aunque no se pulse una pista.
- La evidencia de objeto y cualidad no se mezcla si cada componente usó otro apoyo.

El complemento exige una situación posterior apropiada, sin la respuesta visible;
no se obtiene ocultando una pista y pulsando reintentar inmediatamente. El registro
de aprendizaje mantiene sus propios intervalos y condiciones. No llamar dominio o
retención duradera a una recuperación dentro de una sesión.

La propuesta evita descontar una cantidad por cada fallo adicional. El niño ve
«Has completado tu aporte» y, más adelante, «Ahora lo recordaste», sin presentar una
deuda por haber pedido ayuda. La recompensa mínima y las asignaciones deben permitir
avanzar en la historia y sus construcciones necesarias; el complemento favorece
nuevas opciones.
La cantidad de puntos no se utiliza como medida de aprendizaje.

Cada objetivo remunerado necesita identidad estable, independiente del orden
aleatorio, la semilla o la reapertura de escena. Conservar lo máximo ya acreditado
y calcular únicamente la diferencia positiva. Gastar puntos no reinicia ese
registro. Confirmar compra, descuento y desbloqueo como una operación indivisible;
reanudar no duplica premios ni compras. Mantener su propiedad en la sesión y los
contratos de dominio/persistencia del proyecto.

La recomendación de separar práctica apoyada y recuperación posterior toma como
referencia [IES: Organizing Instruction and Study to Improve Student Learning](https://ies.ed.gov/ncee/wwc/PracticeGuide/1).
El principio de feedback utilizable se contrasta con [EEF: Teacher Feedback to Improve Pupil Learning](https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/feedback).
Estas guías no validan los importes 10/6/4 ni la economía de Kalin; las cantidades
son una decisión de diseño que requiere balance y observación.

### Qué mostrar según la actividad — propuesta

| Situación | Información visible | Evidencia que permite |
|---|---|---|
| Ensayo libre o descubrimiento | Imagen base, maya y español; cualidades con significado accesible; resultado tras crear | Exploración/práctica apoyada |
| Práctica guiada | Ejemplo y fichas con apoyos ajustados a la actividad | Práctica guiada, no escritura independiente |
| Interpretar un pedido | Contexto con objetivo maya integrado; alternativas visuales sin copiar la respuesta maya como emparejamiento literal | Reconocimiento/interpretación |
| Reconstruir | Piezas o letras y apoyos correspondientes | Reconstrucción |
| Recuperación independiente | Situación o significado a expresar; entrada propia, sin las palabras de respuesta en el selector; ayuda disponible a petición | Recuperación según evidencia real del intento |
| Decoración e inventario | Identidad y vista del mueble ya conocido; sus herramientas de colocación | Personalización, sin recompensa lingüística automática |

La imagen base del selector de ensayo no es el resultado del hechizo: enseña el
sustantivo. Su presencia no requiere ocultar significado en todas partes. Lo que
debe evitarse es mostrar la respuesta y luego declarar que se recuperó sin ayuda.
El ensayo se mantiene gratuito y usa únicamente combinaciones canónicas conocidas.

### Girar, profundidad y superficies

Propuesta de controles para el niño: **Girar**, **Delante/detrás**, **Colocar encima**
y **Guardar**. No presentar valores numéricos de Z. El orden de dibujo no convierte
un plato en un objeto físicamente apoyado ni lo eleva sobre una mesa.

- La profundidad del suelo se calcula desde el punto de apoyo; acercar una silla
  hacia el frente cambia su relación con la mesa. Evitar una orden de render que
  la haga aparecer por encima de cualquier personaje de todo el mapa.
- Colocar un plato encima asigna una superficie válida de la mesa, con posición y
  apoyo propios. Al mover la mesa, el plato la acompaña. No apoyar mesas en platos
  ni permitir grupos de soporte circulares.
- Girar utiliza vistas dibujadas, con puntos de apoyo y superficies coherentes;
  no hace girar el dibujo entero en el plano de pantalla. El estudio de silla tiene
  frente, lateral, espalda y lateral opuesto.
- Guardar una mesa con un plato permite conservar el conjunto. El estudio los
  recupera juntos; también permite retirar el plato por separado, rompiendo su
  relación de apoyo. El inventario conserva el objeto, no cobra otra compra.

El estudio `colocar-girar-y-guardar.html` demuestra estas relaciones con herramientas
contextuales. Sus nuevas vistas son dibujos de prueba aislados, no arte canónico
añadido al juego. Quedan por aceptar herramientas, restricciones y acabado de vistas.

### Primer proyecto aceptado: un rincón para compartir

Áak y Miis preparan un patio de reunión. El objeto central es una mesa y se
introduce su cualidad fuerte con los refuerzos del arte vigente. Borrador del ciclo:

| Paso | Qué ocurre | Recompensa o desbloqueo propuesto |
|---|---|---|
| Necesidad | La situación muestra por qué falta un mueble, sin exigir aún escritura de algo no enseñado | Proyecto visible en el libro |
| Objeto | Descubrir/practicar mayak en una acción contextual | 4, 6 o 10 por su objetivo según apoyo; máximo acumulado de 10 |
| Cualidad | Practicar chich y observar qué cambia en la estructura | 4, 6 o 10 por su objetivo según apoyo; máximo acumulado de 10 |
| Presupuesto | Terminar la preparación lingüística del proyecto | 12 puntos fijos, una vez y antes de comprar |
| Diseño | Abrir Mesa y Fuerte en el libro y confirmar sus desbloqueos | 10 por objeto y 10 por cualidad; compras permanentes |
| Creación | Probar la combinación con sello y magia de Kalin | Sin gasto por ensayo; sin premio educativo automático |
| Construcción | Colocar y acomodar la mesa en el patio; los personajes usan el rincón | Primera parcela y copias gratuitas del diseño conocido |
| Recuperación posterior | Otra situación requiere expresar las palabras sin verlas; ayudas siguen disponibles | Diferencia hasta el máximo de 10 ya acreditado por objetivo |

Los precios, las recompensas según apoyo y la asignación del proyecto están
aceptados: dos objetivos con tarjetas suman 8 y las dos compras cuestan 20. Los
12 de preparación cubren ese mínimo. Entregarlos antes de exigir la compra evita
que el premio dependa de una construcción inaccesible. Ofrecer inicialmente sólo
esas dos compras hasta construir el rincón conserva ese presupuesto. Para
los proyectos siguientes se debe verificar también el gasto opcional previo;
no asumir que haber ganado puntos equivale a conservar saldo suficiente.

No regalar estos diseños iniciales: se eligió financiar su compra con la recompensa
de preparación. Definir los objetivos canónicos concretos antes de programar;
el aprendizaje o puntuación anterior de una palabra no puede acreditarse otra vez
como si fuera un descubrimiento nuevo. La evidencia conserva su identidad propia.

### Locomoción de Kalin

Se llama locomoción al conjunto de moverse y representarlo: caminar, detenerse,
mirar hacia el destino, dar pasos con los pies apoyados, rodear obstáculos y ser
seguido por la cámara. Incluye teclado/flechas y desplazamiento a un destino con
ratón. No significa añadir saltos o plataformas por defecto.

El movimiento actual sólo desplaza X, ajusta el suelo y balancea el dibujo entero.
La exploración elegida necesita dos ejes, rutas transitables entre muebles y agua,
orden de profundidad y vistas o poses de movimiento coherentes con la dirección.
Parar un diálogo o una transición conserva el destino y control que corresponda.
El estudio anterior de cámara no prueba todavía esas animaciones de marcha.

### Kay: actuar dentro del agua

El estudio `kay-en-el-estanque.html` separa cola y aletas existentes, permite
seguir el alimento mientras cae al agua, acercarse nadando, tomarlo bajo la
superficie, girar y volver al rincón sin nadar hacia atrás de forma rígida. No
añade patas, manos ni un vaso para que Kay beba. Una futura acción con agua puede
mejorar o llenar su estanque, en vez de imitar la bebida de los mamíferos.

La vista lateral del estudio permite revisar contactos y nado; no es el diseño
definitivo de la orilla. La adaptación a cámara y profundidad del barrio sigue
pendiente. El usuario acepta el nivel de detalle de los estudios previos; la
biblioteca final de actuaciones mantiene revisión individual de cada especie.

### Control de alcance antes de implementar

Las decisiones de economía quedaron confirmadas. La última aclaración conserva la
historia y los pedidos variables: ya no exige redactar todos los proyectos de una
nueva historia antes de implementar. La sala de retos cubre la práctica dirigida,
sin eliminar las oportunidades de aprendizaje dentro del recorrido principal.
La selección y cobertura se derivan de los catálogos vigentes, no de listas paralelas.
La distribución concreta y el acabado visual se comprobarán con las referencias
de diseño en el motor. Las ampliaciones posteriores conservan conexiones previstas;
el mapa ampliable no promete contenido ilimitado.

La aceptación de implementación debe comprobar presupuesto con todos los apoyos,
saldo tras gastos opcionales, ausencia de premios duplicados, interrupción y
reanudación, retirada de muebles con objetos apoyados, senderos transitables y
revisión visual de actuaciones y contactos en el motor. La evidencia lingüística
permanece independiente de comprar, gastar o experimentar.

### Orden de la primera implementación y recomendaciones de cierre

Esta conversación supervisa la implementación autorizada en una nueva sesión.
El primer hito recomendado es
un ciclo completo de «Un rincón para compartir», desde una partida nueva hasta
guardar y reabrir el patio construido. El alcance global conserva los tres barrios,
pero la validación inicial de economía y construcción se concentra en ese proyecto.

| Orden | Entrega | Aceptación |
|---|---|---|
| 1 | Dominio de objetivos, saldo, compras y preparación | Máximos 10/6/4, diferencia recuperable, 12 una vez, compras globales y sin duplicación al reanudar |
| 2 | Proyecto contextual de Áak y Miis | Enseñar objeto y cualidad antes de exigirlos; consecuencia visible y presupuesto suficiente con tarjetas |
| 3 | Mesa de trazos | Ensayo gratuito de palabras conocidas; sello sin resultado previo; transformación protagonizada por Kalin |
| 4 | Parcela y almacén | Colocación, vistas de giro, apoyo, mover conjuntos y recuperar objetos sin cobros nuevos |
| 5 | Paseo y actuación | Dos ejes y senderos libres; contacto y profundidad correctos; uso de la mesa por los personajes |
| 6 | Cierre de calidad | Reanudar ciclo, comprobar evidencias y economía, revisar capturas y animaciones en el motor y ejecutar la validación vigente |

Las herramientas y reglas de colocación siguen siendo propuestas de los estudios.
Como ajustes predeterminados recomendados: distinguir modo caminar de modo decorar;
mostrar sólo las herramientas del objeto seleccionado; permitir cancelar y deshacer
la última edición; impedir bloquear accesos; y explicar visualmente superficies
válidas. No añadir controles numéricos de profundidad ni perder muebles al retirarlos.

Descubrir una palabra y comprar un diseño son estados distintos. El ensayo gratuito
no exige comprar diseños; el desbloqueo pagado habilita construir copias permanentes
en la aldea. Comprar, copiar, decorar o reproducir una animación no acreditan objetivos
lingüísticos. Una compra de cualidad no permite combinaciones fuera del catálogo.

En el primer proyecto, con saldo inicial cero y los dos objetivos sin acreditar,
la recompensa total antes de compras queda entre 20 y 32: 8–20 por palabras más
12 de preparación. Tras gastar 20 quedan 0–12; recuperar después hasta 10 por
palabra puede completar la diferencia. No trasladar este cálculo automáticamente
a partidas con objetivos previos ni a otros proyectos: requieren presupuesto propio.

Mantener la revisión crítica visual solicitada como condición de aceptación de la
implementación: comprobar zonas despejadas, foco de interacción, superposiciones,
uniones de cabeza y cuerpo, número de extremidades y contacto con recipientes,
asientos y agua. Los errores visibles encontrados se corrigen antes de cerrar el
hito; registrar cualquier pendiente real. Los prototipos HTML no sustituyen esta
revisión en Godot. La historia vigente y la práctica posterior conservan cobertura
y conexiones previstas; las ampliaciones de contenido son posteriores a esta entrega.

### Cierre del plan: historia vigente, variedad y sala de retos

#### Decisiones del usuario

- Conservar por ahora el argumento, los capítulos y el cierre existentes. No
  introducir una nueva campaña ni exigir una historia individual por animal.
- Conservar necesidades aleatorias como las actuales, filtradas por contenido
  conocido y válido. El proyecto inicial acordado sigue siendo una introducción
  controlada a economía y construcción, no una campaña nueva de proyectos.
- Utilizar todo el vocabulario disponible de la aventura. Se toma como fuente la
  API del catálogo activo; no incorporar automáticamente entradas reservadas ni
  enseñar contenido futuro antes de su presentación en el recorrido.
- Progreso mediante puntos mágicos y secciones del mundo: desbloquear un mundo
  desbloquea una sección nueva. Las construcciones no compran acceso a la historia.
- Añadir en la aldea un lugar de retos que seleccione qué practicar a partir de
  los resultados del niño y lo reutilice en combinaciones permitidas.

#### Selección aleatoria y cobertura

Mantener variedad de destinatarios y pedidos sin depender del azar para enseñar
todas las palabras. El plan de presentación garantiza cobertura de las entradas
activas y sus modalidades necesarias antes de repetir contenido por conveniencia.
La repetición apoyada y la recuperación posterior siguen siendo oportunidades
intencionadas. La aleatoriedad decide entre candidatos equivalentes válidos y se
guarda; no cambia un pedido activo ni su destinatario al reanudar.

La cobertura incluye animales, objetos, cualidades, alimentos y cortesías; no se
reduce a pares de objeto y cualidad. Las fórmulas de varias palabras conservan su
identidad de entrada del catálogo, sin convertir cada fragmento en una recompensa.
Las expresiones y la gramática continúan pendientes de revisión con hablantes.
El ejemplo Mesa/Fuerte se integra cuando ambas entradas hayan sido presentadas:
conservar el orden actual impide exigir Fuerte antes del mundo de cualidades.
Su prueba inicial aislada no adelanta por sí sola esas palabras en la aventura.

#### Qué significa variedad en esta entrega

Se refiere a variar la acción y su consecuencia con el vocabulario existente:

| Situación | Acción y resultado |
|---|---|
| Interpretar una necesidad | Comprender una petición y elegir un objeto que sirva |
| Preparar algo con magia | Expresar objeto o cualidad; Kalin transforma el sello al confirmar |
| Entregar | El animal utiliza el objeto con una actuación propia de su especie |
| Decorar | Acomodar muebles y superficies con un cambio persistente en la parcela |
| Recuperar en la sala | Recordar palabras en otra actividad sin ver previamente la respuesta |

Cambiar sólo de animal, pulsar otra ubicación sin efecto o barajar las mismas
tarjetas no constituye una actividad distinta. No se requieren nuevos minijuegos
para esta entrega ni se añaden pasos obligatorios para aparentar variedad.
Se conserva la sustitución de la secuencia rígida de doce preguntas y se evita
acumular dos visitas consecutivas al final; preservar la historia no restaura ese
flujo de ejercicios. La sala opcional no absorbe toda la recuperación de la aventura.

#### Secciones por mundo y catálogo inicial

Los barrios patio, taller y orilla siguen siendo la organización espacial inicial.
Una sección desbloqueada puede ampliar uno de ellos; no obliga a crear cinco
barrios completos. Distribución recomendada, ajustable al plano:

| Mundo accesible | Sección disponible |
|---|---|
| 1 | Sendero de bienvenida y zona inicial del patio |
| 2 | Parcela de jardín y ampliación del patio |
| 3 | Barrio del taller y espacio de magia |
| 4 | Barrio de la orilla y entorno del estanque |
| 5 | Jardín de recuerdos junto al portal |

Cada sección se habilita al desbloquear su mundo, una sola vez, sin coste. Una
conexión visible anuncia la siguiente zona. Conservar transiciones suaves, puntos
de llegada seguros, orden de profundidad y opción de movimiento reducido.

El catálogo inicial reutiliza las nueve bases y cinco cualidades del manifiesto
vigente y sus combinaciones permitidas; la implementación no fija esas cantidades
como constantes ni crea otro catálogo. Los nombres de animales y cortesías no son
planos de construcción. Muebles admiten vistas de orientación y objetos compatibles
admiten superficies; alimentos y agua usan recipientes y gestos propios, no se giran
como muebles. Los hitos y premios vigentes se revisan como una política única para
no sumar por accidente los antiguos 10 por descubrimiento y 50 por nivel.

El presupuesto de toda la aventura debe verificarse con apoyos, compras opcionales
y objetivos acreditados antes del proyecto. Los 12 iniciales no justifican por sí
solos un saldo suficiente en cualquier partida. Ningún acceso de mundo dependerá de
saldo o de un recuerdo independiente. La construcción opcional puede esperar; los
objetos necesarios para superar un reto se pueden ensayar gratuitamente.

#### Sala de retos: comportamiento recomendado

Entrada física identificable en la aldea, gratuita y voluntaria, disponible al
tener vocabulario presentado. Propuesta inicial: tandas de tres retos, con opción
de salir y guardar entre ellos. No requiere diagnóstico automático ni un servicio
externo; las reglas consultan la evidencia local que ya registra el juego.

1. Filtrar las entradas presentadas, con contenido y recursos válidos. Las nuevas
   palabras se enseñan primero dentro del recorrido, no se califican sin exposición.
2. Dar prioridad a entradas practicadas sólo con apoyo, sin recuperación posterior
   independiente o con dificultades recientes. Contemplar cuántas oportunidades
   hubo y cuándo; los errores acumulados por sí solos no indican prioridad.
3. Mezclar hasta dos objetivos prioritarios con uno de consolidación, variando
   modalidades y contenido cuando haya candidatos. Si hay pocos, reducir la tanda;
   no repetir la misma palabra inmediatamente sólo para completar tres casillas.
4. Usar contextos y combinaciones canónicas: un sustantivo difícil puede combinarse
   con una cualidad conocida compatible. Animales y cortesías disponen de situaciones
   propias; no forzar un producto cartesiano de todas las palabras.
5. Empezar la ocasión de recuperación sin las respuestas visibles. Mantener ayudas
   accesibles y su registro por palabra; al necesitar apoyo, ofrecer práctica útil
   y programar otra ocasión posterior, no una repetición inmediata que simule recuerdo.
6. Conservar los criterios de separación y contexto del libro. Cambiar una semilla,
   barajar opciones o reabrir el mismo checkpoint no crea evidencia nueva. Cualquier
   ventana de resultados recientes necesaria pertenece al modelo de aprendizaje,
   no a una segunda puntuación de la vista.
7. Entregar sólo la mejora hasta 10 por objetivo; no pagar puntos fijos nuevos por
   cada tanda. Cuando todos estén acreditados, la sala sigue disponible para jugar
   y practicar, con una explicación honesta de que ese objetivo ya entregó sus puntos.

El niño ve mensajes de práctica y progreso, sin etiquetas como «palabras malas» ni
una supuesta medición de su conocimiento real. Salir no pierde saldo ni bloquea la
historia. El acceso a la sala y las rondas se conservan al continuar la partida.
Como cierre recomendado de apoyos, consultar una respuesta completa en el libro o
en el ensayo durante un reto se trata como apoyo de solución, equivalente al nivel
de tarjetas para esa palabra. No permitir que cambiar de escena limpie esa marca.

#### Continuidad para la próxima sesión

Este alcance permite pasar a implementación sin exigir otra decisión narrativa.
Los valores de tanda, distribución de secciones y reglas de editor arriba indicados
son recomendaciones predeterminadas revisables; no se presentan como nuevas
respuestas expresas del usuario. Conservar las decisiones confirmadas y las
referencias visuales. El usuario pidió explícitamente crear y supervisar la nueva
sesión el 27 de octubre de 2026; esa petición autoriza iniciar el trabajo.
La siguiente sesión debe ejecutar los hitos en orden, continuar entre ellos y
cerrar cada uno con las comprobaciones del repositorio y la revisión visual crítica.

### Comprobación de los estudios aislados

Se comprobaron ambos prototipos en navegador a tres anchuras, sin desbordamientos,
imágenes ausentes ni errores de JavaScript. La silla ofrece cuatro vistas distintas;
el plato acompaña a su mesa y el conjunto se guarda y recupera. El estudio de Kay
comprobó el contacto del alimento con la boca y la alternativa de movimiento reducido.
Estas comprobaciones corresponden a los prototipos, no validan ejecución en Godot.

La entrega local de continuidad está en
`.ui-review/design_points_and_assembly_2026_10_27/`, con fragmentos, vistas de prueba,
generador, capturas y resultados. Es una carpeta ignorada de revisión visual.
La documentación pasó `python tools/check_structure.py` y `git diff --check`.
