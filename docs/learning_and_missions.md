# Descubrimiento, práctica y recuerdo

## Criterio implementado

Las páginas representan palabras descubiertas. No son una puntuación de dominio. El Libro de Hechizos muestra por entrada su estado de uso:

| Estado | Evidencia |
|---|---|
| Descubierta | Se presentó su relación entre palabra y significado. |
| En práctica | Se utilizó en un ejercicio con tarjetas, apoyos o correcciones. |
| Primer recuerdo | Se escribió correctamente sin consultar ayuda durante ese intento. |
| Recordada sin ayuda | Hay al menos dos recuperaciones en contextos distintos, separadas por otros ejercicios. |

El umbral es una regla de diseño del prototipo, no una prueba psicométrica ni una certificación de aprendizaje. La retención a días o semanas necesita observación posterior con jugadores; no se infiere de completar la aventura.

Se registran localmente contextos, prácticas, errores, apoyos y un contador de ejercicios. Para añadir una segunda evidencia deben haber transcurrido al menos tres resultados distintos desde la anterior (al menos dos ejercicios intermedios). Reemitir, restaurar o repetir el mismo resultado guardado no avanza ese contador ni multiplica aciertos. Volver a jugar cambia la disposición, pero un mismo contexto semántico no acredita dos recuerdos.

Abrir el libro, recibir pistas de contenido, ver las tarjetas, necesitar corrección de acentos o acertar después de un error conserva el progreso narrativo y se registra como práctica apoyada. Las ayudas siguen disponibles; no hay pérdida de páginas, vidas ni bloqueo por equivocarse.

## Actualización del 24 de octubre

Cada ronda de recuerdo empieza por escribir. Un primer fallo activa **Completar** y un segundo activa **Bloques**, sin selector manual. Se conserva cada parte correcta de una frase; los campos vacíos y los tableros incompletos no cuentan como errores. Completar y Bloques se registran como reconstrucción apoyada; la escritura acertada a la primera se contabiliza por separado. Los contextos usan actividad, destinatario y contenido en lugar de posición de ronda. El formato vigente conserva las evidencias por contexto semántico, sin convertir datos de sistemas retirados. Ver [docs/adventure.md](adventure.md) para el recorrido, el guardado de posiciones y las verificaciones.

## Cambios por actividad

- **Historias:** conocer a un animal descubre su palabra. Identificarlo entre imágenes es práctica. Los personajes se reordenan al pasar a adivinar y las respuestas escritas cambian de posición. Eso no se confunde con recuerdo libre.
- **Caminos:** el primer tablero conserva la demostración. Desde el segundo, las casas estándar tienen color neutro y texto en español. Al llegar se recupera el nombre maya por escrito; las etiquetas del tablero se ocultan durante esa respuesta. Consultar la palabra sigue siendo posible.
- **Casa:** la primera vuelta presenta y practica los objetos. En recuerdo se escribe a partir del significado en español, sin opciones ni dibujos de solución. Las opciones de práctica se reproducen al continuar la partida.
- **Taller:** se recuperan objeto y cualidad por separado. No se muestra una previsualización que permita probar palabras y comparar imágenes antes de responder. El símbolo de selección ya no se presenta como acierto.
- **Comida:** se escribe el alimento y, cuando procede, su cualidad. Se retira el dibujo objetivo durante el recuerdo. Las tarjetas se reordenan entre rondas, no mientras se está decidiendo.
- **Portal:** los cuatro retos de recapitulación empiezan con respuesta escrita. Las cortesías que aún se introducen se consideran práctica, no recuerdo de algo que nunca se enseñó.

Taller y Comida presentan las palabras nuevas y proponen una recuperación por reto
en situaciones de sus destinatarios. Si sus palabras ya fueron presentadas en la
historia, no se obliga a copiarlas otra vez antes de intentar el pedido. El plan
completo queda guardado; aprender durante la actividad no elimina sus pasos.
La salida final conduce directamente a la misión del capítulo, sin acumular otro
paseo equivalente. Las visitas intermedias siguen siendo opcionales.

Las respuestas admiten mayúsculas y apóstrofos tipográficos. Si solo faltan acentos, se permite continuar mostrando la grafía canónica, pero el intento se considera apoyado. Los apóstrofos no se eliminan. Las teclas adicionales de vocales acentuadas y cierre glotal permanecen ocultas por decisión del autor, pendientes de consulta con el profesor; se conserva la entrada mediante teclado.

## Misión: Los encargos de la aldea

La historia 8 conduce a `world4_mission1`, antes del portal. También puede abrirse `scenes/worlds/world4/mision_encargos_aldea.tscn` con F6.

1. Kalin elige a quién ayudar. Puede caminar o usar los accesos directos con toque o teclado.
2. El taller permite crear un objeto o alimento y una cualidad opcional.
3. Kalin lleva la creación confirmada a la plaza común.
4. Casa permite elegir dónde colocar; Fiesta, ajustar el acomodo con una barra; Comida, servir al destinatario.
5. Los objetos entregados quedan junto a sus destinatarios y, tras tres encargos, se puede seguir al portal.

Las plantillas de autor conservan seis huecos; cada visita nueva selecciona tres necesidades del catálogo permitido para su capítulo, con objetos distintos y un destinatario por necesidad. Se da prioridad a vocabulario con menos recuerdos registrados; los empates y las posiciones de los personajes varían con una semilla guardada. No se cambia el encargo a mitad del intento.

El taller comprueba la escritura del encargo y activa los apoyos automáticamente si falla. El libro continúa disponible. Una entrega incorrecta, por ejemplo con un objeto de un guardado anterior, explica de nuevo la necesidad y permite volver al taller. La evidencia independiente se registra al entregar, no al pulsar Crear: cuenta tanto el lenguaje como su uso con un destinatario. Se guardan encargos, posiciones, entregas, errores, apoyo y el objeto que Kalin lleva.

## Implementación y comprobación

- `learning_progress.gd`: evidencia por palabra y textos del libro.
- `learning_attempt.gd`: apoyo y errores que sobreviven al checkpoint.
- `recall_panel.tscn`: entrada escrita y vuelta voluntaria a práctica.
- `village_task.gd`: encargos editables en el Inspector.
- `village_mission.gd`: creación, transporte, comprobación y entrega.
- Guardado formato 9 con archivo temporal y respaldo `.bak`.
- `tests/validate_learning_evidence.gd`: regresiones de aprendizaje, persistencia, ayuda, texto parcial, posiciones, entregas y teclado de intro.

Ejecutar `tools/validate.ps1`. Para capturar la misión y la recuperación con renderer real, ejecutar la prueba anterior con `--capture=<carpeta absoluta>` después de `--`. No utilizar `--headless` al capturar.

Las pronunciaciones continúan pendientes. La lectura de palabras escritas no evalúa comprensión oral; esa parte se deberá incorporar cuando existan audios revisados. La comodidad de escribir y el ritmo de los encargos deben probarse con el público objetivo.

Taller y Yo quiero muestran una sola respuesta editable. Se retiró la mesa que
duplicaba lo escrito. Los destinos de tarjetas caben en su caja y el resultado
ilustrado aparece al confirmar el acierto, sin anticiparlo durante la selección. Los destinatarios de las visitas varían entre los doce
animales presentados; su identidad se conserva durante toda la visita y al reanudar.
Saludar a los vecinos adicionales no acredita recuerdo ni añade encargos obligatorios.

## Evidencia diferenciada del formato 9

**Ver mi práctica** abre un detalle dentro de cada página, mediante toque o teclado.
Muestra reconocimiento, reconstrucción, escritura independiente, usos en entregas,
orientación de controles, correcciones de grafía, apoyo, errores y experimentación.
Estos contadores describen resultados del juego y no certifican retención diferida.

La explicación de controles durante la escritura activa `guidance`, sin marcar
pistas de contenido. Consultar el libro o pedir una solución conserva `content_help`.
`LearningAttempt` mantiene observaciones por palabra: una parte acertada antes del
apoyo de otra conserva su evidencia, incluso después de JSON. Un error posterior en
esa misma palabra sí impide acreditarla como independiente. La evidencia se confirma
al resolver el ejercicio o entregar el encargo, nunca al editar un campo.

Los paseos interpretan fichas canónicas en maya y ofrecen opciones visuales con su
significado español. **Ver la petición en español** conserva su marca al continuar.
Reconocer una opción nunca acredita escritura. Copiar una palabra mostrada se
registra como práctica apoyada, sin sumarla al contador de reconocimiento. La orientación automática al reabrir
sólo destaca la petición; la pista que indica una respuesta requiere pedir Ayuda.

El laboratorio sólo ofrece combinaciones permitidas cuyas palabras se conocen.
Consultar el laboratorio durante un encargo también marca apoyo de contenido en ese
encargo. Crear registra `experiment`, siempre apoyado; repetir la misma combinación durante
la visita no multiplica resultados. No crea un objeto transportable ni resuelve un
encargo. Sus elecciones y animaciones son transitorias; sus prácticas se guardan.

El formato vigente 9 añade economía por palabra y jardín persistente al recuerdo
personal y a la evidencia de aprendizaje. Las partidas de otro formato se rechazan sin escribir
sobre ellas. El reinicio es explícito desde el menú, conforme a Mantenimiento.

## Recuerdo personal al volver

Después de las tres cortesías, el niño elige un recuerdo de una visita completada.
Si no realizó esas visitas opcionales, puede recordar una cortesía que acaba de
compartir. La elección cambia la imagen que se ve junto al portal y en el cuarto de
Kalin. Puede cambiarla antes de confirmar el cruce; no hay opción incorrecta,
puntos ni resultados de aprendizaje. El formato 9 conserva la imagen elegida al
reanudar y rechaza el formato anterior sin sobrescribir la partida.


## Puntos y construcción

Cada objetivo canónico de palabra acumula como máximo 10 puntos: sin apoyo de
contenido, 10; inicio de palabra, 6; tarjetas o solución consultada, 4. Los errores
no añaden descuentos. Una ocasión posterior sólo paga la diferencia positiva.
Las ayudas de manejo no rebajan el premio. La evidencia educativa conserva sus
criterios propios y no se interpreta a partir del saldo.

Mesa y Fuerte se practican en sus mundos antes del primer proyecto. Su preparación
aporta 12 una vez y permite comprar ambas por 10 cada una. La cualidad se compra
globalmente; copias y ensayos conocidos son gratuitos. Comprar, gastar y decorar
no acreditan recuerdo. El acceso a mundos y barrios nunca depende del saldo.
