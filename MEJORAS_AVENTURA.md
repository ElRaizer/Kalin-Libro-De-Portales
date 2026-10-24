# Revisión de aventura, interacción y comodidad

Implementación del 22 de octubre de 2026. Las decisiones de ritmo y comprensión
son hipótesis de diseño: todavía no se han observado sesiones con niños.

## Paseos jugables

- **La casa cobra vida**, después del Mundo 2: visitar a Miis, Kaax y Peek',
  interpretar para qué necesitan un objeto y elegir un hechizo sobre el escenario.
- **Una aldea a su medida**, después del Mundo 3: resolver necesidades de espacio,
  resistencia y decoración con las cualidades ya practicadas.
- Cada paseo tiene tres encuentros opcionales. Se puede seguir el sendero hasta
  la salida sin resolverlos todos. Una elección distinta permite volver a intentar;
  al resolverla, el objeto queda junto al personaje y se guarda.
- Los hechizos muestran palabras e ilustraciones: se registran como **práctica
  apoyada**, nunca como recuerdo libre ni como una prueba de retención.
- En el descanso entre práctica y recuerdo de casa, taller y comida aparece
  **Salir a caminar por la aldea**. Al volver se conserva la petición pendiente.
- La salida posterior a un nivel vuelve a su capítulo correspondiente, incluso
  si antes se usó ese mismo paseo como descanso.

Los encuentros se editan desde recursos `VillageEncounter` y `VillageTask` en
las dos escenas de paseo. El contenido no introduce nuevas frases en maya.

## Volver a practicar

Tras completar el Mundo 4, el mapa ofrece **Visitar la aldea**. Abre una visita
independiente con tres encargos, seleccionados con el criterio de evidencia que
ya utiliza la misión. Conserva sus entregas y borradores al interrumpirla.
Volver al mapa recupera el destino de la aventura principal. Una visita terminada
permite iniciar otra, conservando los descubrimientos y la evidencia existente.

Esto no equivale a un sistema de repetición espaciada entre días: no se afirma
que dos usos durante una partida demuestren retención a largo plazo.

## Correcciones

- Los cuatro tableros empiezan sin el panel de escritura superpuesto.
- Pedir práctica antes de que exista una pregunta no muestra una respuesta ajena.
- El taller conserva borradores por destinatario, tanto escritos como con tarjetas,
  y restaura el panel abierto al continuar desde el archivo de progreso.
- La ayuda diferida de exploración no transforma un borrador restaurado en tarjetas.
- `Esc` cierra primero el taller o las elecciones del paseo; después permite pausar.
- Volver a tarjetas actualiza las etiquetas y guarda el cambio de modalidad.
- El resultado del taller utiliza el total de peticiones, sin mezclarlo con bloques de tres.
- Los errores al guardar tienen un aviso visible y una acción de reintento. Si la
  partida no pudo leerse, reintentar vuelve a leerla y no escribe datos vacíos encima.

Las teclas de vocales acentuadas y apóstrofo **permanecen ocultas por decisión
del autor**, pendientes de consulta con el profesor. No deben volver a contarse
como un fallo accidental de interfaz. Se conserva la entrada mediante teclado.

## Presentación y comodidad

- Caminata con la ilustración original, saltitos y balanceo de recorte, conservando
  la identidad visual elegida por el autor. Reducir movimiento suaviza estos saltitos.
- Fondos de aldea de 5120 × 720, con margen después del sendero, cielo ampliado y
  límites de cámara calculados desde el dibujo para evitar cortes en los extremos.
- El paseo final tiene un claro al atardecer, plataforma de piedra y un portal
  luminoso propio. Las visitas de práctica conservan la salida al mapa junto a las casas.
- Menos partículas sobre Kalin para mantener visibles su cara y los objetos.
- Menú nuevo sin la acción de reinicio cuando aún no existe progreso.
- **A tu ritmo**, accesible desde el mapa y la pausa: reducir movimiento,
  evitar destellos de pantalla y mostrar el texto completo. Las preferencias se
  conservan aparte de la partida. Reducir movimiento elimina el vuelo del libro,
  el balanceo de exploración y la sacudida de pantalla; ralentiza las viñetas.
- Renderer Compatibility para este proyecto 2D, comprobado con OpenGL en el equipo
  de desarrollo. No se atribuye una mejora de rendimiento sin mediciones comparables.

## Gestos de las ayudas

- Los objetos de exploración, caminar, personajes, respuestas y botones muestran
  una pulsación en el lugar, con un pequeño anillo y sin recorrido de arrastre.
- Las tarjetas de objeto, cualidad, alimento y tamaño se arrastran desde la tarjeta
  hasta el hueco que acepta su categoría. Los extremos siguen a los controles.
- En los tableros, la manita recorre casillas adyacentes y evita rocas, fichas y
  caminos ocupados. Los niveles avanzados muestran sólo dos pasos; un camino
  parcial se retoma desde su punta. Si no hay ruta, se invita a rehacer el camino.
- Las ayudas siguen las transformaciones de la cámara y se retiran al ocultar
  el objetivo o salir de las elecciones del paseo.

## Verificación

`tools/validate.ps1` incluye una suite adicional,
`tests/validate_adventure_polish.gd`, con pulsaciones, clics y escritura mediante
eventos de entrada. Comprueba paseos y consecuencias, retorno desde descansos,
borradores desde JSON, tarjetas, visita independiente, preferencias y cobertura del
paisaje en los extremos de cinco exploraciones. Puede generar
capturas con renderer real:

```powershell
godot_console.exe --path . --script res://tests/validate_adventure_polish.gd -- --capture=C:/ruta/a/capturas
```

`tests/validate_tutorial_gestures.gd` comprueba clics sin desplazamiento, posiciones
con cámara, trayectorias y caminos parciales de los cuatro tableros, los cuatro
tipos de tarjeta, personajes y acciones de continuar. Admite el mismo argumento
`--capture` y forma parte de las 17 suites de `tools/validate.ps1`.

La variación desde la primera partida, los bancos de preguntas y los 48 tableros
con solución comprobada se documentan en [REJUGABILIDAD.md](REJUGABILIDAD.md).

## Pendiente de validar o decidir

- Comprensión y duración real de las actividades con el público objetivo.
- Revisión de enunciados y contexto cultural con personas hablantes.
- Decisión del profesor sobre las teclas adicionales de escritura.
- Tamaño de texto ajustable: requiere recomponer y comprobar las pantallas actuales.
- Exportaciones finales y mediciones en dispositivos objetivo; el equipo no tiene
  instalada la plantilla de exportación de Godot 4.6.3.
- Ampliar gradualmente las situaciones del mundo y las animaciones de uso de cada
  objeto. Las pantallas de práctica y recuerdo siguen disponibles.
