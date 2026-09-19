# Kalin y el Libro de los Portales

Videojuego educativo desarrollado en Godot para practicar vocabulario y estructuras básicas de maya yucateco. El proyecto forma parte del Servicio Social prestado a la UMT.

## Estado del proyecto

- Motor: **Godot 4.6**.
- Resolución de diseño: **1280 × 720**.
- Escena principal: `res://scenes/Intro.tscn`.
- Progreso local con guardado automático.
- Siete escenas jugables distribuidas en cuatro mundos.
- Los audios de pronunciación están planeados, pero todavía no han sido grabados.

El proyecto es un prototipo funcional en desarrollo. La navegación principal, el libro de hechizos y el guardado están implementados; todavía quedan mecánicas y contenido narrativo por ampliar.

## Organización jugable

Cada **mundo** representa una mecánica. Los **niveles** de un mismo mundo reutilizan esa mecánica y cambian vocabulario, ambientación u otros factores.

| Mundo | Nivel | Escena | Contenido |
|---:|---:|---|---|
| 1 | 1 | Los Caminos Blancos | Animales: Peek', Miis y Kaax |
| 1 | 2 | Los Animales del Bosque | Kéej, K'éek'en y Ma'ax |
| 1 | 3 | Los Guardianes del Monte | Báalam, Kuuts y T'u'ul |
| 1 | 4 | Agua y Cielo | Kay, Ch'íich' y Áak |
| 2 | 1 | La Casa Maya | Selección del hechizo correcto para objetos del hogar |
| 3 | 1 | Hechizos de Adjetivos | Construcción de frases con sustantivo y adjetivo en dos fases |
| 4 | 1 | Yo Quiero | Estructura *In k'a'at* y alimentos |

El orden de progreso es Mundo 1 completo → Mundo 2 → Mundo 3 → Mundo 4. Al terminar el contenido disponible, el juego regresa al menú principal.

## Ejecutar el proyecto

1. Instala Godot 4.6.
2. Importa la carpeta del repositorio desde el administrador de proyectos de Godot.
3. Abre `project.godot`.
4. Pulsa **F6** para probar una escena o **F5** para iniciar desde la introducción.

No se requieren complementos ni dependencias externas.

## Controles

- Introducción: clic izquierdo, `Espacio` o `Enter` para avanzar.
- Mundo 1: clic y arrastre para conectar fichas.
- Mundos 2, 3 y 4: clic para elegir palabras o respuestas.
- Libro de hechizos: botón de la interfaz; `Esc` para cerrarlo.

## Documentación

- [INSTRUCCIONES.md](INSTRUCCIONES.md): instalación, estructura técnica y mantenimiento.
- [AUDITORIA_BUENAS_PRACTICAS.md](AUDITORIA_BUENAS_PRACTICAS.md): cumplimiento, correcciones y pendientes de diseño.
- [VOCABULARIO.md](VOCABULARIO.md): grafías adoptadas, normalizaciones y decisiones del GDD.
- [Arte/audio/README.md](Arte/audio/README.md): preparación y nombres de los audios pendientes.

## Trabajo pendiente

- Grabar, revisar e integrar las pronunciaciones.
- Diseñar más niveles para los mundos 2, 3 y 4.
- Ampliar las variaciones y la dificultad de los mundos 2, 3 y 4.
- Crear el cierre narrativo y el portal de regreso planteados por el GDD.
- Validar textos y pronunciaciones con una persona hablante o especialista en maya yucateco.
- Realizar pruebas de accesibilidad, teclado, pantallas distintas a 1280 × 720 y exportaciones objetivo.
- Ampliar la validación automática hasta cubrir interacción, navegación y migraciones completas del guardado.
