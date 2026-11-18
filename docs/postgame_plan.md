# Plan de desarrollo del posjuego: una aldea para volver

Plan solicitado el 14 de noviembre de 2026 a partir de la revisión del posjuego.
**PG0–PG9 están implementados y validados.** Este documento
es la referencia del alcance de aldea, proyectos, convivencia y práctica
opcional. El [plan general](development_plan.md) conserva el historial de entregas.
Los contratos implementados siguen en [Arquitectura](architecture.md), la
[guía de autoría](technical_guide.md) y [Mantenimiento](maintenance.md).

## 1. Resultado que buscamos

Después de regresar a casa, Kalin puede volver voluntariamente a la aldea. El
jugador encuentra un proyecto comprensible, crea un espacio propio, invita a sus
amigos y ve una consecuencia que permanece. También puede entrar únicamente a
pasear, decorar o practicar. La despedida de la aventura mantiene su significado.

La promesa es: **«Las palabras que aprendí sirven para construir un lugar al que
mis amigos y yo queremos volver»**.

Se conserva el público previsto de 10–12 años, lectura autónoma, PC con ratón y
teclado y el estilo SVG actual. El perfil compacto se comprueba durante el trabajo;
eso no certifica una exportación móvil. Las visitas de 5–10 minutos son un objetivo
inicial de ritmo, no una duración medida ni una obligación.

Una visita deseable tiene este recorrido:

1. Encontrar una invitación breve o retomar algo pendiente.
2. Elegir entre colaborar, crear, visitar o practicar.
3. Tomar al menos una decisión propia con efecto visible.
4. Observar una reacción, guardar el resultado y salir cuando se desee.

Habrá contenido de autor con un cierre amable y actividades que se puedan repetir.
El juego no necesita producir encargos infinitos para justificar otra visita.

## 2. Base disponible y problemas que resolver

La revisión local encontró barrios de patio, taller y orilla, doce habitantes,
jardín persistente, compra de diseños, copias gratuitas, almacén, laboratorio,
sala de retos y un recuerdo de despedida. La sala usa tandas de hasta tres retos.
La economía limita la acreditación por palabra y el primer proyecto aporta una
preparación única. Estos sistemas se reutilizan.

| Problema observado | Respuesta del plan | Entrega principal |
|---|---|---|
| Pocas consecuencias de decorar | Vecinos invitados utilizan muebles compatibles | PG1 |
| Después del primer rincón falta dirección | Proyectos opcionales con decisiones y continuidad | PG2, PG5, PG6 |
| Las conversaciones rotan, pero apenas evolucionan | Reacciones a experiencias concretas y pequeños arcos | PG2, PG8 |
| Sala con contexto principalmente escrito y asociaciones repetidas | Situaciones representadas y selección de combinaciones con historial | PG3 |
| Los puntos dejan de motivar al alcanzar máximos | Consecuencias comunitarias separadas de la evidencia lingüística | PG2, PG3 |
| El laboratorio termina en una demostración aislada | Favoritos y paso directo a construir diseños disponibles | PG4 |
| Poca identidad personal y expansión espacial | Nombre de rincón, composiciones, álbum y una ampliación funcional | PG4, PG6, PG7 |
| Caminatas que sirven principalmente para abrir paneles | Encuentros breves y accesos claros, sin alargar trayectos | PG8 |

Las pruebas ejecutadas en el análisis previo fueron `validate_village_home`,
`validate_challenge_planner`, `validate_magic_economy` y `validate_garden_layout`,
mediante el ejecutor aislado con Godot 4.6.3. Pasaron en esa base. No validan las
funciones futuras de este plan ni certifican diversión o aprendizaje.

## 3. Decisiones de alcance

- Conservar la campaña, su regreso a casa y el recuerdo de despedida. El posjuego
  amplía las visitas, sin añadir otro examen para considerar terminada la historia.
- Mantener los accesos actuales durante la aventura. Los proyectos posteriores
  se habilitan tras confirmar el cierre narrativo, no sólo por completar niveles.
- Mantener los diseños comprados una sola vez y las copias gratuitas. No añadir
  monedas, materiales consumibles ni cobros por mover, invitar o volver a visitar.
- Conservar los máximos de puntos lingüísticos. Completar con apoyo puede avanzar
  un proyecto y obtener su consecuencia comunitaria sin simular recuerdo libre.
- Ofrecer varias soluciones válidas en las actividades creativas. Las preguntas
  que evalúan una expresión concreta conservan su respuesta y sus ayudas.
- Usar vocabulario, combinaciones, numeración y arte vigentes. Las nuevas líneas
  en español no incorporarán gramática maya inferida. Cualquier ampliación
  lingüística requiere su revisión y sus fuentes canónicas.
- Desarrollar tres proyectos nuevos, además del rincón inicial, con acciones
  diferentes. Comenzar por uno completo y ampliar después de comprobarlo.
- Dar continuidad a un reparto pequeño antes de extender invitaciones a los doce
  animales. No exigir una campaña exclusiva para cada habitante.
- Mantener acceso libre a retos y actividades aunque todos los premios estén
  acreditados o todos los proyectos hayan terminado.
- No introducir rachas, deterioro por ausencia, hambre, culpa, relojes de espera,
  clasificaciones competitivas ni tareas diarias obligatorias.

Quedan fuera de esta entrega el multijugador, servicios en línea, viviendas con
interiores completos, horarios autónomos complejos, generación infinita de misiones
y un sistema de vestuario de Kalin. Se pueden reconsiderar después del cierre del
alcance principal; no son dependencias del posjuego.

## 4. Organización de las entregas

Cada unidad incluye comportamiento, presentación, contenido y comprobaciones
proporcionales. No se acumulará toda la programación para dejar las actuaciones,
la interfaz o el guardado hasta el final. Una unidad demasiado grande se divide
en un resultado menor que se pueda jugar y revisar.

Los identificadores `PGx.y` permiten continuar en otra sesión sin depender del
historial del chat. Las casillas de cada hito son el seguimiento de sus tareas.
Sólo se marcan al implementar y verificar; el documento no las da por realizadas.

| Hito | Entrega visible | Depende de | Salida jugable |
|---|---|---|---|
| PG0 | Contratos y escenario de prueba del posjuego | Base actual | Preparación |
| PG1 | Invitar y ver a un vecino utilizar un rincón | PG0 | A: aldea reactiva |
| PG2 | Regreso narrativo y proyecto «Un lugar para descansar» | PG1 | B: primer ciclo completo |
| PG3 | Retos representados, variados y conectados con proyectos | PG2 | B ampliada |
| PG4 | Laboratorio conectado y personalización del jardín | PG2 | C: creación propia |
| PG5 | Proyecto «Una merienda junto al estanque» y numeración | PG3, PG4 | D: convivencia variada |
| PG6 | Proyecto «La aldea que imaginamos» y ampliación | PG4, PG5 | E: espacio que crece |
| PG7 | Álbum y composiciones personales | PG4, PG5 | E ampliada |
| PG8 | Continuidad de vecinos, encuentros y ritmo de retorno | PG3, PG6, PG7 | F: conjunto completo |
| PG9 | Ajuste de ritmo, revisión visual y entrega | PG8 | Versión lista para entregar |

Orden predeterminado: PG0 → PG1 → PG2 → PG3 → PG4 → PG5 → PG6 → PG7 → PG8 → PG9.
Las dependencias permiten mover PG4 antes de PG3 si una limitación concreta lo
aconseja. Se termina la unidad activa antes de abrir otra. Los hitos tienen tamaños
distintos: no representan sesiones ni plazos equivalentes.

### PG0. Contratos y preparación

Objetivo: poder agregar progreso y visitas sin perder el cierre de la campaña ni
crear fuentes duplicadas de estado. Reutilizar las pruebas y perfiles aislados.

- [x] **PG0.1 — Escenarios y reglas.** Preparar casos reproducibles de aventura
  incompleta, final narrativo confirmado, rincón construido y economía saturada.
  Concretar los estados mínimos de invitación y distinguir el rincón vigente de
  los proyectos de PG2, con condiciones de inicio e interrupción. Comprobar cómo
  el checkpoint final
  conserva `complete`, también durante una repetición; no usar saldo o ausencia de
  continuación como sustituto del cierre narrativo.
- [x] **PG0.2 — Persistencia del primer incremento.** Definir e implementar sólo
  el estado que necesitará PG1, su validación anidada y las operaciones públicas
  de sesión. Aplicar la política de versión descrita en el apartado 10. Probar
  carga fallida, datos independientes y confirmaciones que no se duplican.

Propiedad: `GameSession`, esquemas y codec existentes; reglas puras en
`scripts/core/session/`; soporte de integración en `tests/`. No crear un gestor
genérico de todas las actividades ni campos vacíos para funciones futuras.

Aceptación: los escenarios se preparan sin modificar la partida personal; el
estado puede restaurarse sin acreditar resultados; la aventura sigue su flujo.
PG0.2 se integra junto al consumidor PG1 para no dejar infraestructura sin uso.
Contrato implementado: `{}` representa ausencia de visita; `animal`, `object_id`
y `remaining` describen una invitación activa. Llegada, uso y salida son
presentación reconstruible. El rincón previo conserva `economy.built`; los estados
de proyectos nuevos se concretan con sus consumidores en PG2.

### PG1. Una invitación que hace vivir el rincón

Objetivo: demostrar la mejora más importante con la mesa existente, Áak y Miis.
Primera entrega deliberadamente acotada: un invitado activo y una interacción de
mesa por vez. El resto de habitantes conserva su conversación habitual.
El usuario eligió una visita que termina sola y permite volver a invitar; la
duración inicial es de 18 segundos activos, configurable en el recurso de autor.

- [x] **PG1.1 — Invitar, utilizar y despedir.** Desde un mueble compatible ofrecer
  «Invitar a un amigo», mostrar destinatarios válidos y representar llegada,
  acomodación, mirada, uso y salida. Dar una respuesta breve propia de cada amigo.
  Reutilizar `VillageUseMotion` y los puntos de contacto existentes. La invitación
  es gratuita y no confirma por sí sola una entrega educativa.
- [x] **PG1.2 — Edición e interrupciones.** Al empezar a mover o almacenar el
  soporte, cerrar la actuación de forma segura. Al girar o reubicar, recalcular
  anclas; no guardar posiciones de actores como una segunda copia del jardín.
  Conservar pausa, foco y movimiento reducido. Reanudar repone el estado estable
  compatible, sin repetir una entrada, un premio o un evento de proyecto.
- [x] **PG1.3 — Presentación y revisión.** Añadir la indicación contextual y el
  estado de ocupación sin cubrir el objeto. Revisar mesa, plato, orientación,
  profundidad, contacto, escalas y senderos. Capturar escritorio, compacto,
  movimiento reducido y secuencia interrumpida, además de la secuencia completa.

Propiedad: composición en `VillageHome`; reglas de compatibilidad dentro de la
función de aldea y datos en `data/`; actuación en los colaboradores existentes.
Un componente específico puede poseer la actuación si evita ampliar el controlador.

Aceptación: el jugador invita sin escribir ni pagar, ve una reacción al mobiliario
que eligió y puede cambiar de idea. No se exige un diseño exacto de decoración.
La versión A termina aquí y ya debe aportar una mejora visible a la base actual.

### PG2. Primer proyecto y entrada al posjuego

Objetivo: convertir una reacción aislada en una actividad con principio, elección
y consecuencia. Proyecto nuevo: **«Un lugar para descansar»**.
La recompensa elegida por el usuario el 15 de noviembre es una guirnalda de
bienvenida. Las tres alternativas usan las ilustraciones completas del libro en
sus botones y las capas físicas de los muebles sólo dentro de la actuación.

- [x] **PG2.1 — Volver después de casa.** Tras el final, presentar una invitación
  breve: el libro permite visitar a los amigos y seguir creando juntos. El menú
  destaca «Volver a mi aldea» y un proyecto disponible o pendiente. No relanza la
  despedida ni interrumpe automáticamente la siguiente entrada. Antes del final
  se conserva el acceso de visita vigente y su retorno a la aventura.
- [x] **PG2.2 — Proyecto con elección.** Áak y Miis proponen un rincón para
  descansar o compartir. El jugador elige una solución compatible entre mesa,
  silla o hamaca según el propósito revisado de cada alternativa. Puede probar
  temporalmente una solución sin comprar, verla utilizada y confirmar su aporte.
  La decoración permanente requiere sus diseños; la colaboración puede terminar
  sin comprarlos. No se consumen sus muebles ni se impone una distribución exacta.
- [x] **PG2.3 — Resultado y continuidad.** Confirmar una vez el proyecto, su
  reacción y un adorno fijo de autor o posibilidad de invitación. Un paso resuelto
  con apoyo cuenta como colaboración. Mostrar qué cambió y permitir repetir la
  visita sin repagar ni volver a completar la misma etapa. Retirar posteriormente
  un mueble cambia el uso actual, pero no borra una experiencia ya vivida.
- [x] **PG2.4 — Historia y actuación.** Escribir propuesta, alternativas,
  reacción específica y conversación posterior, con intervenciones breves y
  avanzables manualmente. La elección se reconoce al regresar. No extender todavía
  este arco a los doce habitantes ni añadir una barra de amistad.

Propiedad: definiciones de proyecto editables en `data/`; reglas puras de progreso
en `scripts/core/session/`; presentación en `scripts/features/village/`; estado
persistente en `GameSession`. Los saludos generales siguen en su fuente vigente.

Aceptación: con cero puntos, con ayudas y con máximos ya acreditados se puede vivir
el proyecto. Se distinguen prueba temporal y objeto propio. Guardar durante una
elección, el uso o el resultado permite continuar sin perderla ni duplicarla.
La versión B debe poder disfrutarse antes de añadir los otros proyectos.

### PG3. Sala de retos con contexto y variedad

Objetivo: mantener la práctica directa y conectarla con pequeñas situaciones de
aldea, sin convertir cada acceso al jardín en un examen.

- [x] **PG3.1 — Elegir situaciones, no siempre la primera pareja.** Revisar la
  selección de `ChallengePlanner` para distribuir combinaciones válidas conocidas
  según prioridad y recencia de su contenido. Guardar el plan concreto; cargar,
  consultar o cambiar de barrio no lo sortea otra vez. Conservar la identidad
  semántica de animales, fórmulas completas y combinaciones, con pocos candidatos.
- [x] **PG3.2 — Representar las peticiones.** Incorporar un visitante o escena
  breve para saludar, identificar un animal y preparar un objeto o alimento.
  En recuperación independiente, la escena no muestra la palabra esperada ni una
  pista que equivalga a la solución. El resultado aparece tras confirmar; las
  ayudas siguen disponibles y persisten fuera de la sala.
- [x] **PG3.3 — Progreso y cierre de tanda.** Mostrar la aportación o la práctica
  realizada antes del saldo. Mantener los máximos económicos y la distinción de
  evidencia. Una tanda compatible puede satisfacer un paso concreto del proyecto
  activo, una sola vez y con apoyo. El jugador puede elegir otras vías de
  colaboración y entrar a practicar sin aceptar ningún proyecto.

Propiedad: `ChallengePlanner`, `ChallengeRoom`, `LearningAttempt` y composición
de aldea. El proyecto recibe un resultado público; no inspecciona el árbol del
panel ni métodos privados. Los estados de las actividades conservan un propietario.

Aceptación: se distribuyen alternativas cuando existen, el plan es estable al
reanudar y nunca aparece contenido no presentado. Completar con apoyo produce una
consecuencia legítima sin registrarse como recuerdo libre. Acertar con máximos
saturados no crea puntos adicionales. La recencia por actividades no se presenta
como evidencia de retención entre días; no se añade un reloj obligatorio.

### PG4. Crear, personalizar y administrar el jardín

Objetivo: unir experimentación y construcción, y permitir expresar preferencias
sin que el jugador tenga que entender varios menús desconectados.

- [x] **PG4.1 — Del ensayo a la colocación.** Guardar favoritos del laboratorio,
  comparar dos variantes conocidas y ofrecer «Colocar en mi jardín» cuando se
  dispone de diseños. Si falta alguno, mostrar cuál y su coste, manteniendo el
  ensayo gratuito. Una compra se confirma explícitamente una vez; volver atrás
  no gasta puntos. No se crean muebles persistentes por sólo mirar una prueba.
- [x] **PG4.2 — Identidad del rincón.** Permitir nombre visible y una selección
  pequeña de adornos de autor con identidad propia: letrero, borde y detalle de
  reunión. El nombre no cambia claves semánticas ni vocabulario. Los adornos
  proceden de proyectos, sin otra tienda ni puntuación estética obligatoria.
- [x] **PG4.3 — Almacén y composiciones.** Hacer comprensible el límite global de
  copias y permitir eliminar una copia sobrante con deshacer. Proteger conjuntos
  con objetos apoyados y referencias de invitados. Guardar inicialmente dos
  composiciones por parcela como referencias de colocación sobre muebles propios,
  sin fabricar copias gratis al restaurarlas. Si falta una pieza, informar y
  conservar la distribución actual; ninguna aplicación parcial es silenciosa.

Propiedad: `SpellLaboratory`, `GardenEditor`, `GardenLayout`, vistas existentes y
estado de sesión. Los límites de favoritos y composiciones son configuración
acotada, no listas ilimitadas; los recursos canónicos no se modifican en ejecución.

Aceptación: comparar, cancelar, comprar, colocar, guardar y restaurar tienen efectos
claros. Las composiciones conservan identidades, orientaciones y superficies. Las
operaciones inválidas no cobran ni borran el acomodo previo. Eliminar una copia
libera capacidad real sin borrar un diseño comprado o un recuerdo histórico.

### PG5. Merienda junto al estanque y variedad de acciones

Objetivo: incorporar numeración y convivencia con una estructura distinta a la
del descanso. Proyecto: **«Una merienda junto al estanque»**.

- [x] **PG5.1 — Elegir invitados y preparar cantidades.** El jugador elige un
  pequeño grupo y una opción de merienda del catálogo. Prepara la provisión con
  `CountingSession`, `MayaNumeral` y la presentación de semillas existentes,
  ajustados a un plan breve y guardado. Los apoyos permiten terminar; no se exige
  superar una marca de velocidad ni pagar por alimento.
- [x] **PG5.2 — Reunirse en el escenario.** Integrar a Kay desde el agua y a un
  ave con su pose propia; ampliar a varios invitados sólo tras revisar contactos y
  ocupación. Diferenciar objetos de provisión temporales y muebles del jardín.
  La comida temporal no consume copias del almacén ni genera un sistema de hambre.
  Elegir con qué decorar cambia la reunión y el recuerdo resultante.
- [x] **PG5.3 — Práctica elegible de varias familias.** Ofrecer desde la sala
  accesos breves a palabras, cantidades y caminos revisados. Los caminos reutilizan
  `GridPathController` y variantes existentes, con una finalidad comprensible de
  visita o conexión. El modo mixto alterna familias cuando hay contenido válido;
  no exige jugar las tres. Cada familia conserva su borrador y registra únicamente
  el resultado que su contrato permite, sin inventar evidencia lingüística.

Propiedad: modelos de numeración y caminos vigentes; componentes compartidos por
función; la aldea compone su uso. Si abrir una actividad cambia de escena, usar
`SceneNavigator` y un retorno público al proyecto, sin duplicar sus controladores.

Aceptación: la cantidad tiene relación visible con la reunión. Salir, abrir el libro,
volver a la aldea y cargar conservan el plan y sus ayudas. Repetir es gratuito,
sin multiplicar provisiones, premios o resultados. Kay permanece en su hábitat.
PG5 conserva una vía de práctica tranquila y de libre elección.

### PG6. Una aldea que puede crecer

Objetivo: ofrecer una ampliación espacial pequeña, funcional y coherente con las
elecciones previas. Proyecto: **«La aldea que imaginamos»**.

- [x] **PG6.1 — Una elección de propósito.** Preparar una zona que pueda destinarse
  a descanso compartido o reunión de merienda. El jugador prueba ambas opciones,
  elige la inicial y decide a quién invitar a estrenarla. La otra opción sigue
  disponible después mediante redecoración; no se pierden historias por elegir.
- [x] **PG6.2 — Ampliación física.** Añadir una extensión a un barrio existente,
  con terreno, límites, entrada y una interacción propia. Expresar las parcelas y
  anclas de uso mediante configuración de autor; sustituir la regla global de
  parcela donde corresponda, sin conservar una ruta alternativa antigua. Comprobar
  obstáculos, mapas, puntos de llegada, profundidad y movimiento de conjuntos.
- [x] **PG6.3 — Inauguración y uso posterior.** Representar una escena breve con
  el grupo elegido y dejar disponible ese lugar para nuevas visitas. La ampliación
  no depende de un saldo mínimo ni compra acceso a mundos de la aventura. Una
  vez inaugurada, no exige repetir preparativos en cada entrada.

Propiedad: configuración espacial y arte en sus carpetas vigentes; reglas de
parcela en `GardenLayout` y de rutas en `VillageGround`; composición en la aldea.

Aceptación: la zona aporta una posibilidad de convivencia y decoración. La ruta es
segura con objetos colocados; la llegada nunca aparece dentro de un obstáculo.
La elección altera el resultado visible y se puede cambiar sin penalización.
No se construye un cuarto barrio vacío para anunciar expansión futura.

### PG7. Álbum de momentos y representación personal

Objetivo: conservar experiencias elegidas por el jugador y mostrar por qué esta
aldea es suya. El recuerdo final de la campaña permanece intacto.

- [x] **PG7.1 — Guardar y volver a mirar.** Tras una reunión o invitación, ofrecer
  guardar un momento con título breve. Comenzar con una capacidad acotada de doce
  recuerdos personales; permitir sustituir y borrar. Conservar una copia JSON del
  encuadre, decoración y participantes, independiente del jardín actual, con sus
  claves validadas. No guarda nodos, recursos ni otro archivo completo de partida.
- [x] **PG7.2 — Componer y capturar.** Añadir cámara de encuadre sencillo, pausa
  de poses y ocultación de controles. Permitir elegir entre poses y participantes
  compatibles. La galería interna funciona sin exportar archivos. Como mejora
  subordinada, exportar PNG con una acción explícita y destino elegido; un fallo
  de exportación conserva el recuerdo y el progreso y permite reintentar.

Propiedad: representación de recuerdos de aldea reutilizando el patrón de
`VillageMemory` y `MemoryMoment` cuando sus contratos encajen. El recuerdo
narrativo y el álbum personal tienen significados distintos y no se sobrescriben.

Aceptación: cambiar o retirar el mueble original no altera una fotografía guardada.
Guardar una captura no acredita aprendizaje. La galería es legible por teclado y
en compacto; borrar o sustituir falla sin dañar los otros momentos. La exportación
puede aplazarse si el álbum interno ya está completo y probado.

### PG8. Vecinos, encuentros y motivos de regreso

Objetivo: dar continuidad al conjunto y extender las invitaciones a los doce
habitantes en los usos compatibles, sin convertirlos en doce campañas paralelas.

- [x] **PG8.1 — Relaciones a partir de lo vivido.** Cada habitante conserva su
  voz y reconoce las experiencias confirmadas en las que participó. Ampliar los
  papeles de anfitrión, visitante y colaborador por grupos y compatibilidad de
  especie. Cerrar una invitación genérica no aumenta una barra de amistad.
- [x] **PG8.2 — Encuentros del paseo.** Añadir pequeños eventos de autor: alguien
  preparando una visita, dos vecinos comentando un rincón o un objeto que inicia
  una propuesta. Seleccionar al entrar según proyectos y experiencias; conservar
  la selección durante la visita y al cargar. El mero reinicio de escena no avanza
  una historia, sortea premios ni permite acumular novedades sin jugar.
- [x] **PG8.3 — Orientación y cierre libre.** El mapa y la entrada muestran una
  oportunidad concreta, con acceso a lo pendiente y opción de ignorarla. Evitar
  iconos sobre todos los vecinos y avisos reiterados. Tras completar los proyectos,
  quedan invitaciones, creación, álbum, práctica y reuniones repetibles. Despedirse
  no deja tareas vencidas ni empeora la aldea.

Propiedad: recursos de eventos y proyectos para sus momentos específicos;
`VillageDialogue` y su fuente vigente para saludos y comentarios generales.
No copiar el banco generado ni crear otro catálogo lingüístico. Usar experiencias
confirmadas como condición en vez de un contador general que haga agradecer ayudas
no vividas por ese animal.

Aceptación: las conversaciones corresponden a lo ocurrido, no anuncian resultados
falsos y mantienen su línea al reanudar. Al menos una oportunidad se entiende sin
leer un diario extenso. No se cambian arbitrariamente actividades abiertas. Una
visita de decoración libre no obliga a resolver un encuentro.

### PG9. Ajuste, comprobación y entrega

Objetivo: comprobar el conjunto integrado y dejarlo mantenible, con alcance real
de las verificaciones y sin funciones a medio conectar.

- [x] **PG9.1 — Recorrido y ajuste editorial.** Jugar el flujo desde el final de
  campaña y desde una partida de posjuego reanudada. Revisar alternativas,
  economía, ayudas, actividades mixtas, proyectos terminados y repetición libre.
  Recortar pasos, diálogos o avisos que no aporten una decisión o consecuencia.
- [x] **PG9.2 — Revisión audiovisual y comodidad.** Comprobar las especies y
  compatibilidades habilitadas, incluidos extremos de tamaño, orientaciones,
  superficies, agua y varios participantes. Revisar mezcla de música y ambiente,
  transiciones, foco, pausa, movimiento reducido y texto completo. Añadir sólo los
  efectos necesarios; ninguna información importante depende de sonido o color.
- [x] **PG9.3 — Entrega técnica y guion de observación.** Ejecutar los controles
  vigentes de Mantenimiento, preparar escenarios aislados de demostración y
  actualizar documentación de responsabilidades y autoría. Registrar pendientes
  externos, recorridos comprobados y capturas. Preparar el guion de observación
  del apartado 12 sin presentar sus resultados como si ya se hubieran obtenido.

Aceptación: se puede entrar, jugar, salir, cerrar el programa y continuar cada
familia de actividad. La entrega no contiene infraestructura sin consumidor,
rutas de ejecución retiradas ni bloqueantes conocidos de su alcance. Las pruebas
con niños y exportaciones pendientes se declaran con su estado real.

## 5. Historia: continuidad sin repetir la aventura

Los proyectos desarrollan tres temas distintos: elegir cómo compartir el descanso,
organizar una reunión teniendo en cuenta a los participantes y decidir qué lugar
quiere construir el jugador. La progresión narrativa se apoya en estas elecciones.

Cada proyecto necesita una ficha de autor con propuesta, propósito, participantes,
alternativas válidas, reacción por alternativa, línea de regreso y condición de
cierre. Evitar prometer en un diálogo un objeto o invitado que pueda ser diferente.
Las decisiones estéticas no se califican como errores.

Primer reparto: Áak y Miis en PG1–PG2; Kay y Ch'íich' en PG5; Ma'ax y un anfitrión
del taller en PG6; extensión al resto en PG8. Los papeles concretos se ajustan a
los diálogos ya escritos y a las actuaciones disponibles. Todos los habitantes
conocidos conservan acceso y saludo mientras se desarrolla su participación nueva.

No se exige leer una exposición sobre las reglas del posjuego. La primera visita
presenta una invitación y deja probarla. Las líneas nuevas de español serán breves;
las expresiones mayas proceden del catálogo y su revisión pendiente se mantiene.

## 6. Progreso, recompensas y ausencia de bloqueos

Se distinguen tres resultados con propietarios y mensajes claros:

| Resultado | Qué lo produce | Qué habilita | Qué no demuestra |
|---|---|---|---|
| Evidencia de aprendizaje | Respuestas y apoyos reales de cada actividad | Selección de práctica y registro vigente | Dominio o retención duradera |
| Colaboración confirmada | Terminar un paso válido de proyecto, también con apoyo | Reacción, adorno o ampliación fija de ese proyecto | Escritura independiente |
| Elección personal | Decorar, invitar o guardar un momento | Identidad y posibilidades de uso | Mejor rendimiento académico |

La colaboración no se transforma en otra moneda. Cada paso tiene identidad estable
y se acredita una vez; repetir su escena es gratuito. No pagar puntos por invitar,
mirar, fotografiar, cambiar de semilla o reabrir una respuesta confirmada.

Antes de exigir una compra, verificar el presupuesto real con objetivos previos,
apoyos y diseños opcionales. Si una actividad necesita un objeto no comprado, usar
un ensayo temporal con datos separados del jardín. El jugador puede terminar la
colaboración y dejar la construcción permanente para después. Los adornos de
proyecto no son atajos para introducir palabras nuevas sin presentación.

Los mensajes reconocen lo logrado: «Tu amigo ya puede probar el rincón» o «Seguimos
practicando esta palabra». La explicación del saldo queda disponible, sin convertir
«+0» en el centro de cada resultado ni ocultar el coste de una compra.

## 7. Dirección visual, animación y audio

Conservar paleta, SVG editables, recortes de personajes, saltitos de Kalin, escalas
y tema actuales. Toda ampliación respeta suelo, tránsito y profundidad. No cambiar
el estilo de arte entre barrios ni introducir ilustraciones que parezcan de otro
juego para señalar que el posjuego es nuevo.

Cada interacción se revisa en tres estados: disponible, en uso y resultado estable.
La mirada anticipa el objeto; la pose utiliza apoyos reales; el regreso deja el
escenario legible. Una versión con movimiento reducido conserva las mismas
decisiones y resultados. No usar partículas para tapar contactos incorrectos.

La sala prioriza visitante, petición y respuesta, reduciendo espacio vacío sin
saturar la pantalla. Durante recuperación independiente, el decorado no revela
las palabras objetivo. Los controles comparten tema y perfiles de distribución.

El audio reutiliza `AudioManager` y `AudioCatalog`: señales breves de invitación,
confirmación, reunión y creación, sin otra capa de reproducción local. Las nuevas
pronunciaciones dependen de su grabación y revisión; las escenas deben funcionar
mientras sigan pendientes. Escuchar la mezcla en el motor y revisar que los efectos
no se acumulen al reanudar o repetir una actuación.

## 8. Propiedad técnica y reutilización

| Área | Propietario | Regla de integración |
|---|---|---|
| Progreso mutable, elecciones y datos de álbum | `GameSession` | Una fuente; operaciones públicas y snapshots independientes |
| Reglas de proyectos y compatibilidad | Dominio de sesión o aldea según responsabilidad | Sin nodos, autoloads ni archivos; contratos concretos |
| Definiciones de proyectos, eventos y compatibilidades | Recursos de autor en `data/` | Identidades en inglés; texto visible en español; copias para datos mutables |
| Composición y entrada de aldea | `VillageHome` y componentes de función | Delegar actuaciones y paneles; evitar un controlador que lo concentre todo |
| Actuación, anclas y hábitats | Colaboradores vigentes de uso y especie | Reutilizar poses, contactos y ciclo de vida |
| Posición, superficie, capacidad y parcelas | `GardenLayout` / `VillageGround` | Aplicación atómica y rutas coherentes con la configuración |
| Práctica de palabras, números y caminos | Modelos existentes de cada familia | La aldea los compone sin copiar reglas o estados |
| Navegación, retorno y guardado | `SceneNavigator`, `SaveRepository` y esquemas | Conservar continuación y estado ante fallos |
| Presentación compartida | `themes/`, `data/layouts/`, `ScreenLayout` | Mantener teclado, foco y perfiles de escritorio y compacto |

Los nombres de clases nuevas se deciden al implementar la unidad que las necesita.
Este plan no obliga a crear un archivo por tarea ni un sistema extensible para
necesidades hipotéticas. Retirar el camino sustituido y actualizar sus consumidores.

## 9. Contratos de estado que hay que concretar

PG0 prepara las reglas mínimas; cada hito incorpora sólo sus datos necesarios.
Los contratos deben cubrir estas preguntas antes de implementar su consumidor:

- **Proyecto:** identidad, paso activo, elecciones válidas y resultados confirmados.
  El borrador no es una entrega. Confirmar y repetir son operaciones distintas.
- **Invitación:** visitante, soporte o lugar y fase estable reanudable. Los anclajes
  y poses se reconstruyen; no se serializan actores ni tiempos de tweens.
- **Jardín:** identidades y referencias de soportes se conservan. Editar o eliminar
  valida los dependientes antes de mutar. Cancelar no altera el estado confirmado.
- **Ensayo de proyecto:** objetos temporales separados de los poseídos; cerrar o
  cargar no los añade al almacén ni sustituye un mueble del jugador.
- **Álbum:** copia de un momento vivido con límites de tamaño, referencias válidas
  y capacidad finita. Borrar la fuente del jardín no borra la copia histórica.
- **Visita y eventos:** selección estable durante la sesión reanudada; una acción
  confirmada puede habilitar continuidad. Cargar no cuenta como colaboración nueva.

La matriz de restauración incluye inicio, selección sin confirmar, interacción en
curso, resultado confirmado, cambio de actividad, cierre y repetición. Para cada
operación sensible se revisan también fallo de guardado o transición y ausencia
del objeto referenciado. No se deduce un proyecto terminado únicamente del saldo,
la existencia de un mueble o un contador de clics.

## 10. Guardado y documentación de cambios

La base actual usa formato 9. PG0–PG1 agregan un campo opcional compatible y PG2
agrega `rest_corner`, también opcional. PG4.1 incorpora la lista opcional
`laboratory_favorites`. Mantienen esa versión; una partida vigente sin estos campos
conserva ausencia de visita, proyecto sin iniciar y favoritos vacíos.
PG4.2–PG4.3 agregan los campos opcionales `garden_identity` y `garden_compositions`:
sin ellos se conservan nombre y acomodos vacíos y la guirnalda del proyecto vigente.
PG5 agrega `snack_project`, opcional, y `practice` al checkpoint de la aldea.
El proyecto ausente no está iniciado; los borradores de práctica nuevos se preparan
con los modelos vigentes sin modificar palabras ni recompensas.
PG6 agrega `village_expansion`, opcional, con pruebas, propósito, invitados,
confirmación y una copia de la elección inicial en `opening`. Su ausencia conserva
cerrada la ampliación. La geometría previa de las tres parcelas mantiene sus
coordenadas; la ampliación de la orilla sólo admite muebles tras la inauguración.
PG7 agrega `personal_album`, opcional. Su ausencia deja el álbum vacío. Cada foto
contiene una composición histórica acotada y conserva sus propios muebles y apoyos.
PG8 agrega `village_experiences`, opcional, y `neighbourhood` al checkpoint de la
aldea. Recuerdos de visita, entregas archivadas y reuniones repetidas usan listas
acotadas. El encuentro seleccionado y las líneas pendientes se reconstruyen
desde el perfil y los hechos existentes.
Al implementar un cambio incompatible, actualizar `SaveSchema.CURRENT_VERSION`,
los validadores, el codec y los documentos canónicos en la misma entrega, según
las reglas del repositorio. Esa política requiere reinicio explícito de partidas
incompatibles; no hay migraciones ni conversión de saldos o logros históricos.

Revisar el contrato persistido de la unidad antes de escribirlo para reducir
cambios incompatibles sucesivos. No reservar un esquema enorme sin consumidores,
simular compatibilidad con alias ni escribir datos del posjuego en un guardado
paralelo para evitar versionar. Las fixtures de prueba preparan cualquier estado
necesario sin exigir una campaña manual nueva en cada iteración.

Al cerrar una unidad, actualizar Arquitectura si cambian propietarios, la guía
técnica si cambia autoría o UI y Aventura si cambia el recorrido. Este documento
registra estado, evidencia y próxima unidad; no duplica los comandos vigentes ni
se convierte en un registro de cada intento fallido.

## 11. Forma de trabajar en sesiones sucesivas

1. Leer la continuidad de este documento, el estado de Git y los contratos vigentes.
2. Elegir la primera tarea sin terminar cuyas dependencias estén resueltas.
3. Concretar su recorrido observable y casos de fallo antes de modificar el código.
4. Implementar la unidad completa, con contenido y presentación suficientes para
   revisarla en el motor. Mantener personalizaciones y trabajo existente.
5. Ejecutar suites afectadas y los controles de Mantenimiento. Para cambios de
   ejecución, escenas o recursos, completar `tools/validate.ps1` antes de dar la
   entrega por lista para integrar. Usar siempre los perfiles aislados.
6. Revisar capturas y secuencias reales; corregir los defectos de ese alcance.
   Una imagen fija no valida contacto, movimiento, pausa o reanudación por sí sola.
7. Revisar el diff, marcar sólo lo terminado y actualizar la continuidad inferior.
   Informar lo implementado, lo probado y la limitación que realmente permanezca.

No se requiere una aprobación entre cada tarea del plan por el mero hecho de
cambiar de sesión. El alcance de una petición futura sigue determinando qué se
ejecuta. Las casillas y el apartado de continuidad distinguen la planificación
de las funciones realmente implementadas y verificadas.
Si aparece una decisión que altera el alcance, preparar la opción concreta y su
consecuencia; continuar con trabajo que no dependa de ella.

No fijar cantidades de pruebas ni copiar aquí comandos que puedan divergir de
[Mantenimiento](maintenance.md). El ejecutor descubre las suites. El seguimiento
de validación registra la base y el alcance real, sin extrapolar un pase anterior.

## 12. Comprobar diversión, comprensión y viabilidad

La validación técnica se hace en cada unidad. El atractivo se observa primero en
el ciclo PG1–PG2 y se vuelve a evaluar con el conjunto. Según la organización actual
del proyecto, las sesiones infantiles pueden realizarse después de la primera
entrega; su disponibilidad no bloquea el desarrollo ni permite dar resultados
por supuestos. Mientras tanto se puede observar usabilidad con otras personas,
declarando quiénes participaron y las limitaciones de esa muestra.

Guion de observación sin explicación inicial extensa:

1. Abrir el escenario `regreso` de [Mantenimiento](maintenance.md#demostraciones-del-posjuego)
   y pedir que continúe desde donde está. Al acabar el epílogo, dejar que elija
   si quiere volver a la aldea y qué hacer allí.
2. Si elige el descanso, observar si prueba una alternativa, distingue la
   prueba del mueble propio y reconoce el cambio que queda al confirmarla. Si
   elige otra actividad, registrar su decisión y seguir su recorrido.
3. En una segunda visita, usar `reanudacion` si hace falta un punto de partida
   común. Pedir que retome algo que dejó pendiente o que elija otra actividad.
   Si abre Mixto, dejar que decida si usa la pista y cuánto avanza. Cuando
   quiera parar, cerrar la ventana y observar cómo retoma en la segunda sesión.

Durante cada sesión, anotar el escenario, el perfil de pantalla, la acción que
intentó, el tiempo y la ayuda que pidió o recibió. Dejar que descubra las
opciones antes de explicarlas. Si necesita intervención para seguir, registrar
qué información faltaba y qué hizo al recibirla.

- Después del final, ¿identifica cómo volver y elige algo que hacer?
- ¿Entiende la diferencia entre probar un objeto y poseer su diseño?
- ¿Invita a alguien y observa la reacción? ¿Modifica algo después por iniciativa propia?
- ¿Reconoce que una elección suya cambió el resultado o la conversación?
- ¿Pide ayuda con tranquilidad o cree que está perdiendo el derecho a avanzar?
- ¿Puede cerrar y retomar su intención sin reconstruir mentalmente toda la sesión?
- En una visita posterior, ¿qué quiere hacer y qué recuerda de su lugar?

Registrar recorridos, bloqueos, elecciones, ayudas del observador y duración real.
Preguntar al final qué le gustaría volver a hacer, sin interpretar esa respuesta
como regreso observado. No equiparar número de clics, saldo o tiempo conectado
con diversión, aprendizaje o retención.

Si la gente no entiende qué hacer, mejorar entrada y señales. Si entiende pero no
le interesa, revisar decisiones y consecuencias antes de fabricar más contenido.
Si disfruta de decorar e invitar, ampliar variantes alrededor de ese comportamiento.
Si las tareas se sienten escolares o repetitivas, reducir preparación obligatoria
y aumentar elección, interpretación o uso, conservando evidencia honesta.

## 13. Recortes si el alcance crece

La entrega mínima coherente es PG0–PG2: volver después del final, colaborar en un
proyecto, elegir una solución, invitar y guardar el resultado. Las demás entregas
amplían esa experiencia; no se dan por completadas al terminar la mínima.

Si el esfuerzo excede la capacidad disponible, recortar en este orden: exportación
PNG, más variaciones de adornos, más encuentros ambientales y más extensiones del
mapa. Mantener primero una ampliación funcional, los tres proyectos diferenciados,
los accesos a práctica y el ciclo de invitación. Si hay que reducir aún más,
registrar explícitamente el alcance aplazado en vez de dejar botones sin función.

No recortar guardado, retorno seguro, ayudas, teclado, movimiento reducido,
coherencia de personajes ni revisión de las actuaciones implementadas. El trabajo
de contenido debe crecer sobre funciones terminadas y utilizadas.

## 14. Continuidad de implementación

**Última actualización:** 17 de noviembre de 2026.

- **Terminado y validado:** PG0.1, PG0.2 y PG1.1–PG1.3. Estado opcional de visita,
  invitación desde una mesa, llegada y despedida automáticas, tiempo activo, reconstrucción estable,
  pausa, edición y ausencia de premios. La extensión del formato 9 es compatible
  con partidas de esa versión sin invitación; no requiere cambiar la versión.
- **Comprobaciones:** ejecutor completo con Godot 4.6.3 aprobado sin errores ni
  advertencias. Nuevas suites `validate_village_visit_state` y
  `validate_village_visits`, junto con regresiones existentes de jardín, economía,
  narrativa y checkpoints. Aprobados estructura, política de código, herramientas,
  catálogos, formato y espacios. Las herramientas Python se ejecutaron con el
  intérprete de la instalación existente de gdtoolkit 4.5.0, sin cambiar versiones.
- **Evidencia local:** `.ui-review/postgame_pg1_full.log` y capturas en
  `.ui-review/postgame_pg1/`. Revisados escritorio y compacto, iconos de invitados,
  llegada, uso, despedida, reanudación con movimiento reducido, plato y mesa girada.
  La observación con jugadores sigue pendiente; el pase técnico no prueba diversión.
- **PG2.1–PG2.4 terminados y validados:** acceso voluntario tras el cierre narrativo,
  invitación de tres momentos, pruebas gratuitas de mesa/silla/hamaca, confirmación
  única, dos reacciones manuales y una guirnalda de bienvenida persistente. El
  avance es independiente de puntos, compras y evidencia educativa. Las pruebas
  temporales y los muebles propios tienen contratos distintos.
- **Evidencia PG2:** `validate_rest_corner` aprobado con renderer real; capturas en
  `.ui-review/postgame_pg2/`, revisadas en escritorio y compacto. La guirnalda se
  apoya en el suelo de la presentación y permanece en el patio al regresar.
  Ejecutor completo con Godot 4.6.3 aprobado sin errores ni advertencias, incluidas
  las suites nuevas de estado e integración. Estructura, tipos, herramientas,
  catálogos, formato y espacios aprobados. Registro: `.ui-review/postgame_pg2_full.log`.
  Las miniaturas usan las ilustraciones completas del libro.
- **Corrección de estabilidad:** la revisión completa detectó una variación mínima
  de posición en la mesa compartida al activar movimiento reducido. La viñeta
  utiliza ahora una única fase de pose para esa mesa. La regresión conserva la
  igualdad exacta y comprueba el cambio desde varias fases, sin ampliar tolerancias.
- **PG3.1–PG3.3 terminados y validados:** parejas conocidas seleccionadas según
  frecuencia y orden del historial, plan e interlocutores persistidos, peticiones
  sin ilustración de solución, resultados de encuentro y uso, cierre de tanda y
  salida con Esc. Los apoyos, la corrección de grafía y el ensayo reciente conservan
  su distinción. Una pareja reciente por cualquiera de sus palabras sigue siendo
  ensayo. Una aportación compatible ofrece llevar voluntariamente la elección al
  rincón pendiente, con confirmación única y sin fabricar muebles ni premios.
- **Evidencia PG3:** `validate_challenge_planner` y `validate_challenge_room`
  aprobados; capturas con renderer real en `.ui-review/postgame_pg3/`, revisadas
  en escritorio y compacto para animales, conversación y comida. Verificados
  borradores, bloques, ayuda fuera del panel, reanudación del resultado, entrega
  al proyecto, foco, saldo cero y premio saturado. Ejecutor completo con Godot
  4.6.3 aprobado sin errores ni advertencias; registro en
  `.ui-review/postgame_pg3_full.log`. Estructura, política de código, herramientas,
  catálogos, formato y espacios aprobados. La observación con jugadores permanece
  pendiente y no se sustituye por las comprobaciones técnicas.
- **PG4.1 terminado y validado:** favoritos ordenados persistentes, capacidad
  editable (seis inicialmente, máximo doce) y comparación de dos ensayos conocidos.
  La mesa de trazos muestra diseños faltantes, precios, total y saldo; exige
  confirmación explícita y compra únicamente lo que falta, conservando la protección
  del rincón inicial. Un fallo de guardado revierte compras y favoritos sin anunciar
  otro saldo. Cancelar o volver al ensayo no cobra ni fabrica muebles.
- **Colocación PG4.1:** acceso directo al editor de la parcela visitada, con foco en
  Colocar, cancelación y deshacer. Las copias nuevas viven fuera de la sesión hasta
  confirmar suelo o superficie válidos; guardar durante la vista previa conserva
  sólo el jardín confirmado. El límite global informa y permite seguir ensayando.
- **Evidencia PG4.1:** `validate_laboratory_state` y `validate_spell_laboratory`
  aprobados, con regresiones de capacidad, saldo insuficiente, doble confirmación,
  fallos de guardado, primer rincón, reanudación, foco y cierre durante la magia.
  Capturas con renderer real en `.ui-review/postgame_pg4_1/`: comparación y
  confirmación revisadas en escritorio y compacto; colocación revisada en escritorio.
  Ejecutor completo con
  Godot 4.6.3 aprobado sin errores ni advertencias; registro en
  `.ui-review/postgame_pg4_1_full.log`. Estructura, política de código, herramientas,
  catálogos, formato y espacios aprobados. La observación con jugadores sigue pendiente.
- **PG4.2 terminado y validado:** nombre por parcela, borrador cancelable y tres
  adornos de autor obtenidos del proyecto de descanso: letrero, borde de flores y
  guirnalda de reunión. Nombrar antes del proyecto conserva la entrega inicial de
  la guirnalda; retirarla después no borra el proyecto. Sin compras ni premios por
  decorar. El nombre no cambia vocabulario ni claves de navegación.
- **PG4.3 terminado y validado:** contador global de copias de jardines y almacén,
  eliminación confirmada y deshacer durante la visita. Los diseños y acomodos
  históricos permanecen. Dos espacios por parcela conservan IDs, claves, giros y
  superficies; restaurar reutiliza copias propias y almacena los conjuntos sobrantes.
  Una pieza faltante, un plato ajeno o una referencia de invitado impide los cambios
  correspondientes sin aplicar un resultado parcial. Los IDs no se reutilizan al
  deshacer. Los fallos de escritura conservan el jardín, los espacios anteriores y
  la posibilidad de reintentar o deshacer.
- **Evidencia de cierre PG4:** `validate_garden_designs` y
  `validate_garden_personalization` aprobados, con cobertura de identidad anidada,
  capacidad, traslado entre parcelas, platos apoyados, invitados, copias eliminadas,
  reanudación, confirmación, cancelación y fallos de guardado y deshacer. Capturas
  con renderer real en `.ui-review/postgame_pg4/`, revisadas en escritorio y compacto
  para identidad, nombre y adornos, administración, pieza faltante y reanudación.
  Ejecutor completo con Godot 4.6.3 aprobado sin errores ni advertencias; registro
  en `.ui-review/postgame_pg4_full.log`. Estructura, política de código, herramientas,
  catálogos, formato y espacios aprobados. La observación con jugadores sigue pendiente.
- **PG5.1–PG5.2 terminados y validados:** merienda voluntaria de la orilla tras el
  regreso, con Kay y Ch'íich' juntos o por separado, comida conocida y dos adornos
  de reunión. Un plan de dos cantidades prepara una ración y cinco bocados por
  invitado; conserva tablilla, errores actuales, apoyos y resultados confirmados.
  La comida es temporal y la preparación funciona con saldo cero y almacén lleno.
  Confirmar y volver a representar son operaciones distintas; no se pagan premios,
  fabrican muebles ni acreditan palabras. Un fallo de escritura conserva el estado
  del proyecto anterior y permite reintentar.
- **Actuación PG5:** la composición conserva a Kay en el agua y a Ch'íich' con su
  pose, cuenco y apoyo propios. Cada invitado tiene porción y actuación independientes;
  la provisión común se presenta aparte. La selección de flores o rincón sencillo
  cambia la reunión y su recuerdo JSON independiente. Reanudar muestra el resultado
  estable y el libro detiene la actuación sin cerrar la actividad.
- **PG5.3 terminado y validado:** sala con selección de palabras, cantidades,
  caminos y mixto. Cada familia conserva su borrador; mixto alterna las disponibles
  y permite dejar cualquier tanda. Cantidades requiere haber terminado el nivel de
  numeración. Caminos utiliza un animal conocido, una ruta de una variante revisada
  y `GridPathController`, con clic, flechas/Enter, retroceso y apoyo visible.
  Cantidades y caminos no producen evidencia lingüística ni puntos. Palabras
  conserva su sesión y contratos vigentes.
- **Evidencia PG5:** `validate_snack_state` y `validate_postgame_snack` aprobados;
  verifican datos anidados, plan ligado al grupo, saldo cero, capacidad saturada,
  carga fallida, confirmación única, recuerdos independientes, caminos y modo mixto.
  Recorrido con renderer real que comprueba libro y carga; capturas en
  `.ui-review/postgame_pg5/`, revisadas en escritorio y compacto para selección,
  tablilla, reunión, contactos, reanudación, familias y camino parcial.
  El pico alcanza la abertura del cuenco
  y Kay permanece dentro del agua. Ejecutor completo con Godot 4.6.3 aprobado sin
  errores ni advertencias; registro en `.ui-review/postgame_pg5_full.log`.
  Estructura, política de código, herramientas, catálogos, formato y espacios
  aprobados. La observación con jugadores mantiene su estado pendiente.
- **PG6.1–PG6.3 terminados y validados:** tras los proyectos de
  descanso y merienda, la orilla ofrece un claro seco. Se prueban ambos propósitos,
  se elige el inicial y uno o dos invitados entre Ma'ax, Áak y Miis. La inauguración
  se confirma una sola vez, funciona con saldo cero y almacén lleno y no entrega
  premios ni evidencia lingüística. Redecorar y cambiar invitados son gratuitos;
  `opening` conserva una copia independiente de la elección y el grupo del estreno.
- **Espacio PG6:** configuración por barrio de suelo, parcela, obstáculos y llegada;
  la orilla agrega parcela seca, entrada, interacción y anclas de invitados. Se
  retiraron los rectángulos globales. Editor, colocación de conjuntos, acomodos,
  rutas, profundidad y llegada utilizan estos recursos. Los cambios posteriores
  conservan los accesos y el espacio de uso. El mapa mantiene tres barrios y
  reconoce el claro dentro de la orilla. Su letrero permite abrir otra reunión al
  llegar caminando; regresar no exige preparar cantidades otra vez.
- **Evidencia PG6:** `validate_village_expansion` y `validate_postgame_expansion`
  aprobados; verifican decisiones parciales, geometría de autor, capacidad saturada,
  saldo cero, fallos de escritura y reintento, recuerdo independiente, apertura
  única, apoyo de platos, movimiento de conjuntos, rutas y carga de una posición
  ocupada. Regresión de aldea aprobada con la firma espacial vigente.
  Capturas con renderer real en `.ui-review/postgame_pg6/`, revisadas en escritorio
  y compacto para propuesta, ambas actuaciones, contactos, estreno, terreno,
  redecoración, nueva visita y mapa. Libro y Escape conservan pausa y foco.
  Ejecutor completo con Godot 4.6.3 aprobado sin errores ni advertencias; registro
  en `.ui-review/postgame_pg6_full.log`. Estructura, tipos, herramientas, catálogos,
  formato y espacios aprobados.
  La observación con jugadores permanece pendiente.
- **PG7.1–PG7.2 terminados y validados:** las invitaciones a la mesa y las
  reuniones de descanso, merienda y ampliación permiten componer una foto con
  título, participantes compatibles, dos encuadres, una pose predefinida o un
  instante pausado y una vista limpia. El álbum conserva hasta doce fotos y
  permite sustituirlas o borrarlas con confirmación. El campo opcional
  `personal_album` mantiene compatibilidad con el formato 9. La foto de la
  invitación conserva muebles, giros, superficies, nombre y adornos del patio.
  Guardar, sustituir o borrar una foto conserva la economía, la evidencia de
  aprendizaje y el recuerdo narrativo de la despedida.
- **Evidencia PG7:** `validate_personal_album` y `validate_postgame_album` cubren
  datos anidados, capacidad, reanudación, las cuatro fuentes, teclado, pausa,
  movimiento reducido y fallos de escritura con reintento. Las capturas de
  escritorio y compacto en `.ui-review/postgame_pg7/` incluyen composición,
  vista limpia, galería, sustitución y las reuniones. La prueba con renderer
  real compara la imagen antes y después de borrar la mesa y su plato y recargar.
  El ejecutor completo con Godot 4.6.3 pasó sin errores ni advertencias.
  Los controles de estructura, tipos, herramientas, catálogos, formato y espacios
  también pasaron. Registro en `.ui-review/postgame_pg7_full_final.log`.
- **Alcance opcional aplazado:** exportar PNG desde el juego con destino elegido.
  El álbum interno queda disponible con el alcance completo de PG7.
- **PG8.1 terminado y validado.** El patio recibe a los once vecinos terrestres
  conocidos después del regreso. Kay tiene una visita repetible desde la merienda
  y conserva su actuación acuática. Cada vecino reconoce sus propias entregas,
  invitaciones y reuniones confirmadas. Completar una charla, cambiar invitados
  o reiniciar la escena no registra una visita o reunión. La convivencia conserva
  el saldo y el registro de aprendizaje.
- **PG8.2–PG8.3 terminados y validados.** Hay cinco encuentros de autor en los tres
  barrios, con una selección según proyectos y experiencias. Cargar conserva la
  selección y la línea sin abrir el panel. La entrada y el mapa señalan una
  oportunidad a la vez. El letrero y el mapa dan acceso a la conversación, que
  ofrece abrir la actividad correspondiente. Decorar, omitir y volver al menú
  preservan el progreso y dejan disponibles los accesos habituales.
- **Evidencia PG8.** `validate_neighbourhood` y `validate_postgame_neighbours`
  cubren compatibilidad, llegada desde otro barrio, Kay, participantes reales,
  fallos de guardado, reanudación de líneas, mapa, teclado y regreso libre.
  Revisadas capturas reales de escritorio y compacto en `.ui-review/postgame_pg8/`.
  El ejecutor completo de Godot 4.6.3 pasó sin errores ni advertencias. Pasaron
  también los controles de estructura, tipos, herramientas, catálogos, formato
  y espacios. Registro en `.ui-review/postgame_pg8_full.log`.
- **PG9.1.** Los dos escenarios aislados se recorrieron en el juego. Desde el
  epílogo se entró a la aldea, se abrió el descanso y se confirmó la hamaca.
  El menú ahora señala **Continuar: Regreso a casa** mientras ese cierre está
  pendiente. La invitación permite ir directo a las opciones y conserva el
  diálogo completo para quien quiera leerlo. La práctica mixta indica la
  familia que sigue. En la demostración reanudada, cerrar la ventana con un
  camino abierto y volver a **Mixto** recuperó tanto la casilla añadida como
  el apoyo. El recorrido automatizado cubre los tres proyectos, el ensayo con
  saldo cero, la invitación con plato sobre una mesa girada, el álbum y los
  borradores de palabras, cantidades y caminos en otro proceso.
- **PG9.2.** Las catorce capturas revisadas de escritorio y compacto en
  `.ui-review/postgame_pg9/` cubren el regreso, la invitación, el descanso,
  la merienda, el claro, el laboratorio con saldo cero y un camino en curso.
  La revisión de compatibilidad
  usa también las pruebas de visitas terrestres, Kay en agua, apoyos de platos,
  orientaciones y encuentros con dos participantes. Los controles se comprobaron
  con teclado, libro superpuesto, pausa y movimiento reducido. La mezcla
  grabada del regreso al menú y a la aldea duró 10,5 segundos, con un pico
  de −3,1 dBFS y sin muestras saturadas. `validate_audio` comprueba que los
  deslizadores y la atenuación conserven los niveles base de los buses.
- **PG9.3.** [Mantenimiento](maintenance.md#demostraciones-del-posjuego) documenta
  ambos escenarios, el arranque consecutivo y el comando de capturas. El guion
  del apartado 12 queda preparado para observación. El recorrido integrado con
  renderer real pasó en Godot 4.6.3. Su registro es
  `.ui-review/postgame_pg9_visual_final.log`. La validación completa aprobó 60
  suites sin errores ni advertencias, con registro en
  `.ui-review/postgame_pg9_full_final.log`. También pasaron estructura, tipos y
  dependencias, herramientas, catálogos, firmas de ejercicios, formato y
  espacios. Los registros de las dos demostraciones están en
  `.ui-review/postgame_pg9_demo_regreso.log` y
  `.ui-review/postgame_pg9_demo_recheck.log`.
- **Archivos principales:** `VillageVisitState`, `VillageVisitPlacement`,
  `VillageVisitPresentation`, `VillageVisitPanel`, `VillageHome`, sesión, esquema
  y codec; configuración en `data/village_visit_profile.tres`.
- **Archivos de PG2:** `RestCornerState`, `RestCornerPanel`, `RestCornerPreview`,
  perfiles y opciones de autor, menú y `VillageHome`; recurso en
  `data/village/rest_corner.tres` y arte en `Arte/aldea/corner_garland.svg`.
- **Archivos de PG3:** `ChallengePlanner`, `ChallengeRoom`, `ChallengePreview`,
  `ChallengeProfile`, `VillageHome` y sus suites; textos editables en
  `data/village/challenges.tres`. El campo opcional `visitors` conserva compatibilidad
  dentro del checkpoint vigente del formato 9.
- **Archivos de PG4.1:** `SpellLaboratory`, `LaboratoryState`, `LaboratoryProfile`,
  `GardenEditor`, `MagicEconomy`, sesión, fachada, esquema y codec. Capacidad en
  `data/village/laboratory.tres`; distribución en `data/layouts/spell_laboratory.tres`.
  `laboratory_favorites` es opcional y compatible dentro del formato 9.
- **Archivos de PG4.2–PG4.3:** `GardenIdentity`, `GardenCompositions`,
  `GardenIdentityView`, `GardenIdentityPanel`, `GardenStoragePanel`, base `VillagePanel`,
  `GardenEditor`, sesión, fachada, esquema y codec. Configuración en
  `data/village/garden.tres`; arte en `Arte/aldea/garden_sign.svg` y `garden_border.svg`.
  `GardenFixture` prepara los escenarios aislados. Los dos campos de sesión nuevos
  son opcionales y compatibles dentro del formato 9.
- **Archivos de PG5:** `SnackState`, `SnackPanel`, `SnackGathering`, `SnackProfile`,
  `CountingActivity`, `CountingWorkbench`, `VillagePractice`, `PracticeHub`,
  `NumberPracticePanel`, `PathPracticePanel` y `PathPracticeState`; integración en
  `VillageHome`, `ChallengeRoom`, sesión, fachada, esquemas y codec. La base compartida
  de modales se llama ahora `VillagePanel`, conservando su UID. Contenido en
  `data/village/snack.tres` y `data/village/practice_counting.tres`.
- **Archivos de PG6:** `VillageExpansion`, `ExpansionPanel`, `ExpansionGathering`,
  `ExpansionProfile`, `VillageSpace` y `VillageSpaces`; integración en `GardenLayout`,
  `GardenCompositions`, `VillageGround`, sesión, fachada, esquema, codec, aldea y mapa.
  Recursos en `data/village/spaces.tres` y `data/village/expansion.tres`. Las suites
  nuevas se ejecutan con los mismos perfiles aislados de Mantenimiento.
- **Archivos de PG7:** `PersonalAlbum`, `PersonalAlbumPanel`, `PersonalMomentView`,
  integración en aldea y paneles de reunión, sesión, fachada, esquema y codec.
  Se reutilizan `GardenObject`, `GardenIdentityView`, las vistas de reuniones
  y sus actuaciones, con el perfil vigente de distribución de la aldea.
- **Archivos de PG8.** `VillageNeighbours`, `VillageNeighbourhood`,
  `PostgameEncounter`, `VillageNeighbourPanel`, sesión, navegación y esquemas.
  Integración en `VillageHome`, `VillageMap` y los paneles de invitación, merienda
  y claro. Autoría de encuentros y recuerdos en `data/village/neighbours.tres`.
- **Dependencias externas:** revisión lingüística, pronunciaciones, observación con
  el público infantil y exportaciones en dispositivos objetivo mantienen su estado
  pendiente. Ninguna se presenta como aprobada por el análisis del código.

Al continuar, actualizar este apartado con última tarea verificada, siguiente ID,
archivos principales, pruebas y capturas revisadas, además de los bloqueos reales.
