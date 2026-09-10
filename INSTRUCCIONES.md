# Kalin y el Libro de los Portales — Instrucciones de instalación

## ¿Qué hace este paquete?

Implementa la base del juego según el GDD:
- **GameManager** (autoload): vocabulario maya completo, puntos mágicos, guardado automático.
- **Menú Principal**: botones de jugar/continuar, libro de hechizos, reiniciar.
- **Nivel 1 — Los Caminos Blancos**: puzzle estilo "Flow Free" donde conectas animales con sus casas usando rutas. Al conectar cada animal, dice su nombre en maya (*In k'aaba'e' Peek'*).
- **Nivel 2 — La Casa Maya**: mecánica propia de "lanzar el hechizo correcto" (ya no reutiliza el puzzle de caminos del Nivel 1). Cada animal pide un objeto para su casa; el jugador elige el sustantivo maya correcto entre varias opciones. Tiene dos fases, tal como pide el GDD: primero con imagen + palabra visible, y luego solo con la imagen, sin apoyo escrito.
- **Libro de Hechizos**: inventario visual de todas las palabras aprendidas con emoji, nombre maya, traducción y estructura gramatical.

---

## Instalación

### 1. Copiar archivos
Copia **todas las carpetas** de este paquete dentro de tu proyecto Godot (la raíz donde está tu `project.godot` actual).

Si ya tienes un `project.godot`, **no lo reemplaces** — en su lugar agrega manualmente estas líneas en la sección `[autoload]`:

```ini
[autoload]
GameManager="*res://scripts/autoloads/GameManager.gd"
```

Si tu proyecto está vacío, puedes usar el `project.godot` incluido.

### 2. Agregar el autoload en Godot Editor
Abre el proyecto en Godot → **Proyecto → Configuración del Proyecto → Autoload**:
- Nombre: `GameManager`
- Ruta: `res://scripts/autoloads/GameManager.gd`
- ✅ Activar singleton

### 3. Definir escena principal
En **Proyecto → Configuración del Proyecto → Aplicación → Ejecutar**:
- Escena principal: `res://scenes/MainMenu.tscn`

---

## Estructura de carpetas

```
kalin-libro-de-portales/
├── project.godot
├── scripts/
│   ├── autoloads/
│   │   └── GameManager.gd        ← singleton global
│   ├── ui/
│   │   ├── MainMenu.gd
│   │   └── LibroHechizos.gd
│   └── world1/
│       └── Level1.gd             ← puzzle de caminos
├── scenes/
│   ├── MainMenu.tscn
│   ├── ui/
│   │   └── LibroHechizos.tscn
│   └── world1/
│       └── Level1_CaminosBlancos.tscn
└── Arte/                         ← tu carpeta de arte existente
```

---

## Cómo jugar el Nivel 1

1. Haz clic en un animal (🐶, 🐱 o 🐔) para empezar a trazar.
2. Arrastra el cursor por las celdas vacías hasta llegar a la casa con el nombre maya correcto.
3. Cuando el camino llega a la casa, el animal pronuncia: *In k'aaba'e' [nombre]*
4. Conecta los 3 animales para completar el nivel.
5. Las palabras aprendidas aparecen en el 📖 Libro de Hechizos.

---

## Siguiente paso

Todos los niveles del Mundo 1 (1-7) ya existen. El trabajo pendiente es de
**calidad de mecánica**, no de niveles faltantes:
- `Level3.gd` — hoy usa el mismo puzzle de caminos que el Nivel 1; el GDD pide
  construir la frase sustantivo+adjetivo de verdad (arrastrar/combinar tarjetas).
- Un Nivel 5 real del GDD (frases de despedida + cierre narrativo, portal de
  regreso) — no existe todavía; los "Niveles 5-7" actuales son contenido extra
  de animales con la mecánica del Nivel 1.

---

## Estado actual del juego (v10 — septiembre 2026)

### Novedades de esta actualización
- **Nivel 2 rediseñado.** Antes reutilizaba el mismo puzzle de caminos del Nivel 1 (solo cambiaban las palabras); ahora tiene su propia mecánica de "lanzar el hechizo correcto" con selección de sustantivos y progresión de dificultad (imagen+palabra → solo imagen), como describe el GDD. Además ahora enseña las 5 palabras del nivel (antes solo 3): mayak, lak, ch'áak, chan, janal.
- Pendiente para las próximas iteraciones: la misma revisión para el Nivel 3 (construcción real de frase sustantivo+adjetivo, en vez de conectar caminos) y el Nivel 5 real del GDD (frases de despedida + cierre narrativo abriendo el portal), que hoy no existe — los "Niveles 5-7" actuales son contenido extra de animales, no ese cierre.

### Mapa de niveles del Mundo 1

| # | Nivel | Tema | Hechizo | Palabras |
|---|-------|------|---------|----------|
| 1 | Los Caminos Blancos | Animales | *In k'aaba'e'* (Me llamo) | Peek', Miis, Kaax |
| 2 | La Casa Maya | Objetos del hogar | Selección de sustantivo (2 fases) | mayak, lak, ch'áak, chan, janal |
| 3 | Hechizos de Adjetivos | Descripciones | Sustantivo + adjetivo | mejen, nojoch, ki' |
| 4 | Yo Quiero | Comida | *In k'a'at* (Yo quiero) | ja', Ja'as, pak'al, K'úum |
| 5 | Los Animales del Bosque | Animales | *In k'aaba'e'* | Kéej, K'éek'en, Ma'ax |
| 6 | Los Guardianes del Monte | Animales | *In k'aaba'e'* | Báalam, Kuuts, T'u'ul |
| 7 | Agua y Cielo | Animales | *In k'aaba'e'* | Kay, Ch'íich', Áak |

### Identidad visual
- Sprites kawaii propios (SVG) para los 12 animales, mismo estilo en toda la familia.
- Fondos temáticos por nivel con colores suaves y desaturados para que las
  fichas de colores vivos nunca se pierdan: `bg_level1` (caminos),
  `bg_level_monte` (niveles 5-6), `bg_level_agua` (nivel 7).
- Paneles de diálogo/instrucciones con estilo consistente de alto contraste:
  crema con borde café (texto oscuro) y barra de instrucciones oscura
  semitransparente (texto claro), aplicados desde `WordPathLevel`.

### Flujo de navegación
Intro → Menú Principal → Niveles 1-7 en cadena → Menú.
Todos los niveles tienen botón "← Menú" (barra superior) y
"Volver al Menú" (pantalla de nivel completado). El botón "Continuar"
del menú lleva al primer nivel no completado.

### Guion sugerido de demo (5 min)
1. Intro y menú (mostrar "Continuar" con progreso guardado).
2. Nivel 1: mecánica de caminos + diálogo *In k'aaba'e' Peek'*.
3. Libro de Hechizos: vocabulario acumulado con estructura gramatical.
4. Saltar a Nivel 6 (guardianes con sprites de jaguar/pavo/conejo).
5. Cerrar con Nivel 7 y regreso al menú (bucle completo).
