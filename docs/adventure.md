# Revisión de aventura, interacción y comodidad

## Ampliación del 24 de octubre de 2026

El objetivo es aumentar las decisiones y las consecuencias dentro del mundo,
conservar el estilo de recortes y los saltitos al caminar, y facilitar la
interacción en teléfono horizontal. La comprensión y el ritmo con niños quedan
pendientes hasta que el equipo pueda realizar esas sesiones.

### Recorrido

- Casa → paseo → **Rincones para compartir** → historia 6. Tres entregas entre
  seis necesidades para preparar lugares de descanso, vigilancia y merienda.
- Taller → paseo → **Una fiesta a la medida** → historia 7. Tres entregas con
  combinaciones de objeto y cualidad que ya existen en los ejercicios.
- Comida → historia 8 → encargos de la aldea → repaso del portal → **Los recuerdos
  que llevamos** → despedida narrativa → regreso a casa.
- En la despedida se camina hasta tres amigos, se utilizan expresiones conocidas,
  se reúnen recuerdos y se colocan tres páginas en el portal. Las páginas aceptan
  arrastre o selección seguida de toque. El cierre narrativo conserva la emoción
  de la despedida y deja de repetir los cuestionarios.
- **Mis encargos** permite consultar las peticiones conocidas y seleccionar cuál
  preparar. No revela palabras mayas. Las entregas conservan una pose de uso:
  descansar en la hamaca, sentarse, utilizar una mesa o compartir comida.

Las partidas en curso conservan su punto de continuación. Para revisar los tramos
nuevos sin reiniciar la partida, se pueden abrir sus escenas directamente con F6
o repetir el nivel anterior desde el mapa.

### Recordar, reconstruir y escribir

`RecallPanel` comienza por escritura libre en cada ronda de recuerdo y encargo.
El primer error activa Completar; el segundo activa Bloques. No hay selector ni
botón de tarjetas durante el recuerdo. Se conservan las partes correctas de una
frase. Una respuesta vacía o unas casillas incompletas no consumen un intento.
El libro continúa disponible, y consultarlo mantiene la marca de apoyo.
Los fallos al escribir un encargo se conservan al cerrar el taller y se incorporan
a la evidencia de la entrega, junto con los apoyos utilizados.

Los bloques usan piezas y casillas de igual tamaño, sin campos de texto visibles.
Conservan fondo y borde durante el arrastre y después de colocarse. Se pueden
intercambiar, mover entre palabras o devolver al banco. Con toques o teclado se
selecciona una casilla y luego el destino. Las piezas colocadas conservan una referencia
atenuada en su posición del banco: tocarla o arrastrar la pieza hasta el banco la devuelve.
La vista previa queda centrada bajo el cursor. Deshacer restaura la última disposición. El guardado conserva
las casillas vacías, el orden, el apoyo alcanzado y hasta veinte acciones de historial;
los borradores anteriores con bloques se migran al nuevo tablero.

Completar y Bloques registran reconstrucción apoyada. Las escrituras correctas
sin ayuda se cuentan aparte; sólo recuperaciones en situaciones semánticas
diferentes pueden aumentar el número de situaciones del libro. Las cifras de
reconstrucción y escritura se incluyen en la descripción del estado del libro.
Los bloques son fragmentos gráficos, no una segmentación lingüística en sílabas.
Las teclas adicionales de acentos y cierre glotal conservan la decisión del autor.

### Presentación y teléfonos

- Durante la escritura de Taller y Yo quiero, una mesa de composición muestra sólo
  el texto que el jugador ha escrito. Tocar sus tablillas vuelve al campo respectivo.
  No consulta las respuestas ni valida palabras antes de confirmar; conserva la
  dificultad y la evidencia de recuerdo. Con una palabra, la tablilla queda centrada.
- Se mantiene el diseño 1280 × 720 con escalado proporcional. La ventana de
  escritorio admite 640 × 360 a 1920 × 1080. La exportación móvil usa horizontal
  con giro entre sus dos orientaciones horizontales.
- `ScreenLayout` y los perfiles editables de `data/layouts/` activan una composición
  compacta hasta 1024 píxeles de ancho y en dispositivos táctiles/móviles. Aumentan
  texto y controles, reorganizan el mapa y reducen indicaciones duplicadas.
- Durante la escritura del taller y comida se utiliza un único panel: desaparecen
  los huecos de construcción que repetían los campos. El contador de comida usa
  siempre el total de la actividad.
- Al acertar, ese panel muestra una ilustración amplia, la frase maya y su significado.
  Se mantiene hasta Continuar y se restaura al reanudar. La casa también utiliza el
  total completo de peticiones en su celebración.
- Los paseos conservan la petición en una tarjeta visible durante la elección. Las
  tres opciones quedan dentro de pantalla incluso en los extremos de la cámara.
  La ayuda busca la respuesta correcta en el orden barajado. Kalin, los animales y
  los objetos entregados usan capas coherentes: el personaje pasa delante del conjunto.
- Paseos y encargos seleccionan sus tres necesidades en conjunto para evitar repetir
  objetos. Al continuar se conservan las peticiones conocidas o resueltas; si un checkpoint dañado
  repite objetos, sólo se cambian las necesidades que todavía no se han presentado.
- En teléfono, el libro muestra una entrada amplia por página. Conserva categorías,
  navegación, ejemplo y significado. En escritorio mantiene las dos páginas.
- El teclado virtual tiene controles de confirmar y cerrar y se procura mantener
  visible el campo activo. Este comportamiento debe verificarse en los dispositivos
  y exportaciones finales; las capturas de escritorio no certifican un teléfono real.

### Correcciones y consolidación

- La aldea utiliza los doce animales ya presentados: tres destinatarios variables
  y tres vecinos adicionales con conversaciones breves. Cada especie tiene su propia
  casa SVG. La selección se guarda y se conserva al reanudar; los encargos ya iniciados
  mantienen sus dueños. El vocabulario futuro queda fuera del reparto.
- Los fondos nuevos conservan el paisaje y retiran las casas incrustadas de los
  destinatarios. Paseos, misiones, visita libre y despedida comparten la instalación
  de viviendas mediante `VillageResidents`. Los encargos se duplican antes de cambiar
  de destinatario para respetar los recursos de autor.
- Los muebles entregados usan una composición física independiente de los ejemplos
  didácticos. Ya no muestran la copia tenue utilizada para comparar tamaños. La pose
  se ajusta al rectángulo real de la imagen, incluida la hamaca pequeña; la celebración
  conserva la escala del mueble y su ocupante.
- El contexto de aprendizaje utiliza actividad, destinatario y contenido; la semilla
  identifica sólo el intento. Reordenar una petición deja de simular otra situación.
- Guardado versión 6: conserva páginas, práctica, encargos y progreso del contrato
  vigente. Los formatos retirados se rechazan sin convertir sus datos.
- Reducir movimiento retira los rebotes de llegada y de diálogo, las sacudidas y los
  pulsos de los controles afectados. La caminata habitual mantiene sus saltitos.
- `LearningContext` define la identidad de los intentos. `ExerciseRecallFlow`
  comparte modalidades, presentación y tipo de resultado entre ejercicios. `VillageUseMotion` comparte las acciones de uso.
- Los borradores se guardan tras 350 ms sin escribir. Cambiar de escena, pausar o
  salir sigue produciendo un checkpoint inmediato.

### Verificación

`tools/validate.ps1` ejecuta 25 suites, incluidas `validate_game_expansion.gd`,
`validate_debug_answer.gd`, `validate_block_interactions.gd`, `validate_village_life.gd`,
`validate_village_dialogue.gd` y `validate_village_composition.gd`.
La prueba nueva comprueba el contexto semántico, reconstrucción con arrastre,
restauración desde JSON, encargos, páginas parciales del portal, movimiento y
controles dentro de pantalla. El recorrido completo incluye las misiones nuevas.
La suite de vida en la aldea comprueba composición sin respuestas, restauración del
borrador, ajuste de las hamacas para los doce animales, casas, diversidad del reparto
y persistencia de habitantes y conversaciones.
La suite de diálogos recorre las 444 combinaciones de animal y pedido, comprueba
las tres peticiones y dos agradecimientos, los quince saludos y diez comentarios tras
ayudar por animal, sus ciclos sin repeticiones y la reanudación de conversaciones
con vecinos y amigos ayudados, también desde el segundo globo.

### Voces de los habitantes

`data/dialogue/village_dialogue.json` es la fuente revisada del catálogo generado
`scripts/features/village/data/village_dialogue_catalog.gd`. Contiene 2.520 textos españoles
para la aldea: 1.332 peticiones, 888 agradecimientos, 180 saludos y 120 comentarios tras
ayudar. Cada combinación
de los doce animales con los 37 tipos de pedido tiene sus propios textos. Se
personalizan las copias de los encargos después de elegir sus destinatarios; sus
respuestas mayas y sus cualidades no cambian. El caparazón sólo aparece en la voz
de Áak. Kay prepara los muebles para sus visitas de la orilla.

Cada pedido contiene los bancos `requests` (tres peticiones) y `thanks` (dos
agradecimientos). Se eligen por separado según la semilla, la escena, el habitante
y el pedido; las seis parejas de textos pueden aparecer. Ambas variantes permanecen
estables durante la visita y al reanudar, también en las opciones, el diario, la
mesa y los avisos de error. No se modifican las respuestas ni el formato de guardado.
Los vecinos y los amigos ya
ayudados rotan quince saludos propios sin repetir hasta completar el banco. Los
amigos ayudados añaden uno de sus diez comentarios sobre la ayuda y su vida en
la aldea, en lugar de repetir el agradecimiento de entrega. Los vecinos no usan
estos comentarios, pues no han recibido un encargo. La conversación avanza su
contador al terminar, no al abrirla, y guarda su posición
en el campo opcional `greeting_visits` del formato vigente. Al continuar un diálogo
abierto se conserva la frase y la línea, incluso tras saludar varias veces.

### Revisión de las 444 composiciones de resultados

Se generó y revisó un atlas de 37 resultados por doce habitantes. Las sillas
quedan detrás del animal, las mesas y alimentos a su lado y la hamaca utiliza
postes traseros y tejido frontal independientes. Los tamaños mantienen su
diferencia; los adornos, refuerzos y aroma identifican las cualidades del pedido.
Los platos, comida y agua descansan sobre un petate. Kay permanece junto al agua
y recibe el mobiliario para sus visitas, como indican sus diálogos.

`VillageUseArt` reúne 33 SVG de uso en el escenario, derivados sin modificar las
ilustraciones originales. Se retiraron las sombras pegadas a los personajes para
que no giren con ellos dentro de la hamaca. El punto de apoyo de cada animal usa
los píxeles visibles de su ilustración. Las capas son: casas 0, muebles 1, animales
2, tejido de hamaca 3, Kalin 4 y opciones 6. El rótulo de transporte sólo aparece
cuando se lleva un objeto y se sitúa sobre el paisaje, debajo de la cabecera.

`validate_village_composition.gd` comprueba las 444 combinaciones en tres posiciones
de la animación, profundidad, caras despejadas, cualidades visibles y reanudación
en los seis paseos/misiones. Con renderer real exporta el atlas y capturas dentro
de la aldea, incluyendo escritorio y teléfono horizontal:

```powershell
godot_console.exe --path . --script res://tests/validate_village_composition.gd -- --capture=C:/ruta/a/capturas
```

Las nueve variantes SVG añadidas al catálogo ampliado se regeneran con `python tools/build_combination_art.py`; los demás SVG permanecen editables en `Arte/aldea/uso/`.

Para generar capturas actuales con un renderizador real:

```powershell
godot_console.exe --path . --script res://tests/validate_game_expansion.gd -- --capture=C:/ruta/a/capturas
```

Se revisan composiciones a 1920 × 1080, 1280 × 720, 960 × 540 y 640 × 360.
Las pruebas de niños, exportación móvil y teclado en hardware real siguen pendientes.

## Registro anterior

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
`--capture` y forma parte de las 25 suites de `tools/validate.ps1`.

La variación desde la primera partida, los bancos de preguntas y los 48 tableros
con solución comprobada se documentan en [docs/replayability.md](replayability.md).

## Pendiente de validar o decidir

- Comprensión y duración real de las actividades con el público objetivo.
- Revisión de enunciados y contexto cultural con personas hablantes.
- Decisión del profesor sobre las teclas adicionales de escritura.
- Tamaño de texto ajustable: requiere recomponer y comprobar las pantallas actuales.
- Exportaciones finales y mediciones en dispositivos objetivo; el equipo no tiene
  instalada la plantilla de exportación de Godot 4.6.3.
- Ampliar gradualmente las situaciones del mundo y las animaciones de uso de cada
  objeto. Las pantallas de práctica y recuerdo siguen disponibles.
