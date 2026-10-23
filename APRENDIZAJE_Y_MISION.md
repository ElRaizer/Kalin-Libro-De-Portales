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

Abrir el libro, pedir ayuda, ver las tarjetas, necesitar corrección de acentos o acertar después de un error conserva el progreso narrativo y se registra como práctica apoyada. Las ayudas siguen disponibles; no hay pérdida de páginas, vidas ni bloqueo por equivocarse.

## Cambios por actividad

- **Historias:** conocer a un animal descubre su palabra. Identificarlo entre imágenes es práctica. Los personajes se reordenan al pasar a adivinar y las respuestas escritas cambian de posición. Eso no se confunde con recuerdo libre.
- **Caminos:** el primer tablero conserva la demostración. Desde el segundo, las casas estándar tienen color neutro y texto en español. Al llegar se recupera el nombre maya por escrito; las etiquetas del tablero se ocultan durante esa respuesta. Consultar la palabra sigue siendo posible.
- **Casa:** la primera vuelta presenta y practica los objetos. En recuerdo se escribe a partir del significado en español, sin opciones ni dibujos de solución. Las opciones de práctica se reproducen al continuar la partida.
- **Taller:** se recuperan objeto y cualidad por separado. No se muestra una previsualización que permita probar palabras y comparar imágenes antes de responder. El símbolo de selección ya no se presenta como acierto.
- **Comida:** se escribe el alimento y, cuando procede, su cualidad. Se retira el dibujo objetivo durante el recuerdo. Las tarjetas se reordenan entre rondas, no mientras se está decidiendo.
- **Portal:** los cuatro retos de recapitulación empiezan con respuesta escrita. Las cortesías que aún se introducen se consideran práctica, no recuerdo de algo que nunca se enseñó.

Las respuestas admiten mayúsculas y apóstrofos tipográficos. Si solo faltan acentos, se permite continuar mostrando la grafía canónica, pero el intento se considera apoyado. Los apóstrofos no se eliminan. Las teclas adicionales de vocales acentuadas y cierre glotal permanecen ocultas por decisión del autor, pendientes de consulta con el profesor; se conserva la entrada mediante teclado.

## Misión: Los encargos de la aldea

La historia 8 conduce a `world4_mission1`, antes del portal. También puede abrirse `scenes/world4/Mision_EncargosAldea.tscn` con F6.

1. Kalin camina y pregunta a sus amigos qué necesitan.
2. El taller permite crear un objeto o alimento y una cualidad opcional.
3. Kalin lleva el resultado por el mundo, incluso si se equivocó de objeto.
4. La entrega solo se completa cerca del personaje que pidió ese resultado.
5. Los objetos entregados quedan junto a sus destinatarios y, tras tres encargos, se puede seguir al portal.

Hay seis encargos de autor y se seleccionan tres, uno por personaje. Se da prioridad a vocabulario con menos recuerdos registrados; los empates y las posiciones de los personajes varían con una semilla guardada. No se cambia el encargo a mitad del intento.

Una entrega incorrecta explica de nuevo la necesidad y permite volver al taller. El libro y las tarjetas están disponibles. La evidencia independiente se registra al entregar, no al pulsar Crear: cuenta tanto el lenguaje como su uso con un destinatario. Se guardan encargos, posiciones, entregas, apoyo y el objeto que Kalin lleva.

## Implementación y comprobación

- `LearningProgress.gd`: evidencia por palabra y textos del libro.
- `LearningAttempt.gd`: apoyo y errores que sobreviven al checkpoint.
- `RecallPanel.tscn`: entrada escrita y vuelta voluntaria a práctica.
- `VillageTask.gd`: encargos editables en el Inspector.
- `VillageMission.gd`: creación, transporte, comprobación y entrega.
- Guardado formato 3 con archivo temporal y respaldo `.bak`.
- `tests/validate_learning_evidence.gd`: regresiones de aprendizaje, migración, ayuda, texto parcial, posiciones, entregas y teclado de intro.

Ejecutar `tools/validate.ps1`. Para capturar la misión y la recuperación con renderer real, ejecutar la prueba anterior con `--capture=<carpeta absoluta>` después de `--`. No utilizar `--headless` al capturar.

Las pronunciaciones continúan pendientes. La lectura de palabras escritas no evalúa comprensión oral; esa parte se deberá incorporar cuando existan audios revisados. La comodidad de escribir y el ritmo de los encargos deben probarse con el público objetivo.
