# Música y efectos de sonido

Todo el audio del juego se **genera por síntesis** con los scripts de
`tools/generar_audio/`: no hay grabaciones ni muestras de terceros, así que no
tiene derechos de autor de nadie más y se puede distribuir con el juego.

La paleta sonora imita instrumentos de la península de Yucatán: marimba, flauta
de carrizo, ocarina de barro, jarana (cuerdas rasgueadas), clarinete de banda
jaranera, tunkul (tambor de tronco), sonajas, caparazón de tortuga y caracol.
Las melodías usan escalas mayores y pentatónicas para que suenen amables con
niños de alrededor de 10 años.

Los audios de **pronunciación** del vocabulario maya no se generan: deben
grabarse con una persona hablante (ver [Arte/audio/README.md](../Arte/audio/README.md)).

## Propietarios

| Pieza | Responsabilidad |
|---|---|
| `AudioManager` (`scenes/autoloads/audio_manager.tscn`) | Cambia la música y el ambiente al cambiar de escena con un fundido cruzado, reproduce los efectos por nombre, baja la música mientras suena una fanfarria y guarda el volumen en `user://ajustes_audio.cfg`. Los reproductores son nodos de la escena. |
| `AudioCatalog` (`data/audio_catalog.tres`) | Qué suena en cada lugar. Se edita en el Inspector: música y ambiente por clave de `GameContent.SCENE_PATHS`, ambiente de lluvia y efectos por nombre. |
| `default_bus_layout.tres` | Buses `Musica`, `Ambiente`, `Efectos` y `Voces`; este último es el del reproductor de pronunciaciones del libro. |
| `StorySound` (`scripts/features/story/`) | Hace sonar lo que cada `StoryBeat` ya muestra: trueno con el destello y la sacudida, caracol con el cartel de mundo nuevo, viento con las hojas, lluvia con el efecto «Lluvia», pasos cuando Kalin entra, saltos y el cruce del portal. |
| `SoundCue` (`scripts/ui/shared/`) | Atajo para que los componentes reutilizables pidan un efecto sin nombrar al autoload, para que también compilen cuando una prueba los carga como tipos. |
| `VolumeControls` / `SoundToggle` (`scenes/ui/shared/`) | Deslizadores «Música» y «Sonidos» de la pausa y botón «Sonido: sí / no» del menú principal. |

Reglas automáticas:

- **Todos los botones** suenan al pulsarlos (`boton_clic`) y al pasar el ratón
  (`boton_pasar`). Un botón que ya tiene su propio sonido se agrega al grupo
  `sin_sonido_clic` desde el Inspector (pestaña **Nodo → Grupos**).
- **Aprender una palabra** (`GameManager.word_learned`) suena la campanita del
  libro y **completar un nivel** (`GameManager.level_completed`) la fanfarria.
- Si una escena no tiene música en el catálogo, sigue la anterior; si dos
  escenas seguidas comparten pieza, la música **no se reinicia**.
- Los efectos con retraso se procesan en una cola del autoload, sin
  temporizadores que queden pendientes al cerrar el juego.
- En las pruebas con `--headless` no hay tarjeta de sonido: `AudioManager` sólo
  registra en `effect_history` lo que sonaría.

## Música por escena

| Pieza | Carácter | Escenas |
|---|---|---|
| `musica_menu_principal` | Tema de Kalin, cálido (Re mayor, 92 bpm) | Menú principal |
| `musica_intro_libro` | El libro de los portales, misterio suave (Si menor, 72 bpm) | Introducción |
| `musica_huracan` | Tambores graves y cadencia dramática (Re menor, 84 bpm) | Cinemática del huracán |
| `musica_orilla_isla` | Descubrimiento tranquilo (La mayor, 84 bpm) | Exploración de la orilla, Capítulo 1 |
| `musica_sak_beh` | Rompecabezas con ritmo (Sol mayor, 108 bpm) | Mundo 1 · niveles 1 a 4 |
| `musica_aldea_animales` | Juguetón y saltarín (Fa mayor, 100 bpm) | Capítulos 2 a 5 y 7, paseo Una aldea a su medida, encargos y práctica de la aldea |
| `musica_camino_solar` | Vals tranquilo al atardecer (Do mayor, 3/4) | Exploración del camino a la Casa Maya |
| `musica_casa_vacia` | Melancolía (La menor, 64 bpm) | Cinemática de la casa vacía |
| `musica_jarana_casa_maya` | Estilo jarana yucateca en 3/4 (Sol mayor, 138 bpm) | Mundo 2, paseo La casa cobra vida, Rincones para compartir, Capítulo 6 |
| `musica_taller_adjetivos` | Taller juguetón (Do mayor, 104 bpm) | Mundo 3, Una fiesta a la medida |
| `musica_milpa_manana` | Mañana luminosa en 6/8 (Re mayor) | Exploración de la milpa |
| `musica_cocina_aldea` | Fiesta de la comida (Fa mayor, 116 bpm) | Mundo 4 · Yo Quiero |
| `musica_tianguis` | Tianguis alegre; el motivo sube de uno en uno, como quien cuenta (Sol mayor, 104 bpm) | El tianguis, Las piedras que cuentan |
| `musica_camino_portal` | Asombro y amanecer (Mi lidio, 80 bpm) | Capítulo 8, exploración del camino al portal |
| `musica_portal_regreso` | Magia con determinación (Re menor, 96 bpm) | Mundo 5 |
| `musica_despedida` | Tema de Kalin, tierno (Sol mayor, 72 bpm) | Los recuerdos que llevamos, Capítulo 9 |
| `musica_regreso_casa` | El tema de Kalin como canción de cuna (Re mayor, 66 bpm) | Cinemática final |

## Ambientes

| Ambiente | Escenas |
|---|---|
| `ambiente_lluvia_tormenta` | Cinemática del huracán y cualquier momento de historia con el efecto «Lluvia» |
| `ambiente_olas_mar` | Orilla de la isla, Capítulos 1 y 4, Mundo 1 · nivel 4 |
| `ambiente_selva_pajaros` | Mundo 1 · niveles 1 a 3, Capítulos 2 y 3 |
| `ambiente_grillos_atardecer` | Camino a la Casa Maya, regreso a casa |
| `ambiente_viento_suave` | Casa maya vacía |
| `ambiente_aldea_dia` | Capítulos 5 a 7, mundos 2, 3 y 4 (incluido el tianguis), paseos, misiones y práctica de la aldea |
| `ambiente_milpa_manana` | La milpa |
| `ambiente_portal_zumbido` | Camino al portal, Capítulos 8 y 9, Mundo 5, despedida |

El menú y la introducción no tienen ambiente.

## Efectos

| Grupo | Efectos | Dónde suenan |
|---|---|---|
| Interfaz | `boton_clic`, `boton_pasar`, `pausa_abrir`, `pausa_cerrar`, `panel_abrir`, `panel_cerrar`, `mapa_seleccionar` | Todos los botones, pausa, confirmación de «Volver a empezar», cierre de los descansos de misión, mapa de mundos |
| Aciertos | `acierto`, `error_suave`, `palabra_aprendida`, `nivel_completado`, `mision_pausa` | Respuestas de los mundos 2–5, capítulos (`ADIVINAR`, `ELEGIR`), paseos, encargos y despedida; palabra nueva; nivel terminado; descansos de misión |
| Libro | `libro_abrir`, `libro_cerrar`, `pagina_pasar`, `pagina_recuperada` | Libro de hechizos, introducción, Kalin recupera una página, recuerdos de la despedida |
| Pasos | `pasos_arena`, `pasos_tierra`, `pasos_pasto`, `pasos_piedra` (4 variantes cada uno) | Kalin en exploraciones, paseos y misiones (cada escena elige su suelo), animales que llegan a casa por el Sak Beh, Kalin entra en la historia |
| Exploración | `examinar_objeto`, `animal_tocar`, `magia_apartar`, `recoger_objeto`, `palabra_anotada`, `camino_bloqueado`, `meta_alcanzada` | Objetos, habitantes de la aldea, obstáculos, palabras anotadas y meta |
| Historia | `dialogo_avanzar`, `trueno`, `retumbo`, `destello`, `cartel_caracol`, `hojas_viento`, `muebles_volando`, `paginas_revolotear`, `chispas_magia`, `despertar`, `salto`, `portal_cruzar` | Automáticos según cada `StoryBeat` |
| Mundo 1 | `camino_trazo`, `camino_borrar`, `camino_conectado` | Cada casilla del camino sube una nota de la escala pentatónica; borrar y conectar |
| Construir frases | `palabra_tomar`, `palabra_soltar`, `palabra_regresar` | Arrastrar palabras y bloques de recuerdo |
| Hechizos | `hechizo_lanzar`, `comida_servir`, `portal_energia`, `portal_abrir` | Taller, paseos y encargos; comida servida; cada frase y página que carga el portal; portal abierto |

Los pasos, el trueno, los clics y otros efectos frecuentes son
`AudioStreamRandomizer`: cambian un poco de tono y volumen cada vez para no
cansar.

## Configurar desde el Inspector

- **Cambiar la música de una escena:** abre `data/audio_catalog.tres`, despliega
  `Scene Music` y arrastra otro `.ogg` de `Audio/musica/` sobre la clave.
- **Escena nueva:** agrega su clave semántica en `Scene Music` y, si quiere
  ambiente, en `Scene Ambience`. `tests/validate_audio.gd` falla si una escena
  registrada no tiene música.
- **Un momento de historia especial:** en el `StoryBeat`, categoría **Sonido**,
  `sound` añade un efecto y `music` cambia la pieza desde ese momento.
- **Suelo de una exploración:** propiedad `footstep_surface` (categoría **Sonido**).
- **Efecto nuevo:** agrega el archivo a `Audio/efectos/` y una entrada en
  `Effects` con su nombre en español; en el código se pide con
  `AudioManager.play_sfx("nombre")`, o con `SoundCue.play(self, "nombre")` en
  componentes que las pruebas cargan como tipos.

## Nombres de archivo

En español, minúsculas, sin acentos ni espacios: `musica_*.ogg`,
`ambiente_*.ogg` y efectos con su nombre directo. La música y los ambientes se
importan con **Loop** activado; los efectos, sin él. La prueba revisa la
convención, que ningún archivo quede sin usar y que todo efecto pedido en el
código exista en el catálogo.

## Regenerar o ajustar el audio

Sólo hace falta para cambiar un sonido; el juego no necesita Python.

```powershell
python -m pip install numpy scipy   # también se necesita ffmpeg con libvorbis
python tools/generar_audio/generar.py                         # todo (≈ 1 minuto)
python tools/generar_audio/generar.py efectos                 # una carpeta
python tools/generar_audio/generar.py musica_sak_beh acierto  # archivos sueltos
```

| Archivo | Contenido |
|---|---|
| `sintesis.py` | Instrumentos, filtros, reverberación y exportación a OGG |
| `musica.py` | Las 17 piezas. Melodías escritas por grados (`"1:1.5 2:.5 3:1"`), acordes por grado y patrones de acompañamiento |
| `ambientes.py` | Los 8 ambientes en bucle |
| `efectos.py` | Los efectos y su sonoridad objetivo (`EFECTOS`) |

Cada pieza y ambiente se cierra en bucle sumando su cola al principio, así no
hay cortes al repetirse. Los efectos se igualan por sonoridad para que ninguno
destaque de más.
