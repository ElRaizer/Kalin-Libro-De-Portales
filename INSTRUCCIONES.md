# Kalin y el Libro de los Portales — Instrucciones de instalación

## ¿Qué hace este paquete?

Implementa la base del juego según el GDD:
- **GameManager** (autoload): vocabulario maya completo, puntos mágicos, guardado automático.
- **Menú Principal**: botones de jugar/continuar, libro de hechizos, reiniciar.
- **Nivel 1 — Los Caminos Blancos**: puzzle estilo "Flow Free" donde conectas animales con sus casas usando rutas. Al conectar cada animal, dice su nombre en maya (*In k'aaba'e' Peek'*).
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

Una vez que el Nivel 1 funciona, los siguientes archivos a crear son:
- `Level2_ConstruyendoPalabras.tscn` / `.gd` — hechizos de sustantivos
- `Level3_HechizosAdjetivos.tscn` / `.gd` — sustantivo + adjetivo
- `Level4_YoQuiero.tscn` / `.gd` — peticiones con *In k'a'at*

---

## Estado actual del juego (v9 — julio 2026)

### Mapa de niveles del Mundo 1

| # | Nivel | Tema | Hechizo | Palabras |
|---|-------|------|---------|----------|
| 1 | Los Caminos Blancos | Animales | *In k'aaba'e'* (Me llamo) | Peek', Miis, Kaax |
| 2 | Construyendo Palabras | Objetos del hogar | Sustantivos | mayak, lak, chan |
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
- Los niveles 1, 2, 3, 5, 6 y 7 comparten `GridBoard`, `GridWordData` y
  `GridPathLevel`; cada escena configura sus palabras, fichas y obstáculos.
- Paneles de diálogo/instrucciones con estilo consistente de alto contraste:
  crema con borde café (texto oscuro) y barra de instrucciones oscura
  semitransparente (texto claro), aplicados desde el sistema común de grid.

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
