# Kalin y el Libro de los Portales — Guía técnica

Esta guía explica cómo abrir, ejecutar y mantener el repositorio. La presentación general y el estado del contenido están en [README.md](README.md); las decisiones lingüísticas se registran en [VOCABULARIO.md](VOCABULARIO.md).

## Requisitos

- Godot **4.6**.
- Un sistema capaz de ejecutar el renderer configurado por el proyecto.
- No se requieren paquetes externos.

## Abrir y ejecutar

1. Abre el administrador de proyectos de Godot.
2. Selecciona **Importar** y elige el archivo `project.godot` de este repositorio.
3. Espera a que Godot importe los SVG y las escenas.
4. Pulsa **F5** para ejecutar el juego completo.

La escena principal es `res://scenes/Intro.tscn`. No es necesario cambiarla a `MainMenu.tscn`: la introducción forma parte del flujo oficial. El botón **Saltar intro** sí lleva directamente al menú.

## Configuración esencial

El proyecto ya incluye el autoload requerido:

```ini
[autoload]
GameManager="*res://scripts/autoloads/GameManager.gd"
```

`GameManager` conserva el catálogo canónico de vocabulario, el orden de los niveles, las palabras aprendidas, los puntos mágicos y el guardado local.

## Estructura actual

```text
Kalin-Libro-De-Portales/
├── project.godot
├── README.md
├── INSTRUCCIONES.md
├── VOCABULARIO.md
├── Arte/
│   ├── audio/
│   │   └── README.md
│   ├── backgrounds/
│   ├── sprites/
│   └── tiles/
├── scenes/
│   ├── Intro.tscn
│   ├── MainMenu.tscn
│   ├── components/
│   │   └── GridBoard.tscn
│   ├── ui/
│   │   └── LibroHechizos.tscn
│   ├── world1/
│   │   ├── Level1_CaminosBlancos.tscn
│   │   ├── Level2_AnimalesBosque.tscn
│   │   ├── Level3_GuardianesMonte.tscn
│   │   └── Level4_AguaYCielo.tscn
│   ├── World2/
│   │   └── Level2_ConstruyendoPalabras.tscn
│   ├── world3/
│   │   └── Level3_HechizosAdjetivos.tscn
│   └── world4/
│       └── Level4_YoQuiero.tscn
└── scripts/
    ├── Intro.gd
    ├── autoloads/
    │   └── GameManager.gd
    ├── components/
    │   ├── GridAnimalData.gd
    │   ├── GridBoard.gd
    │   └── GridWordData.gd
    ├── ui/
    │   ├── LibroHechizos.gd
    │   └── MainMenu.gd
    ├── world1/
    │   ├── GridPathLevel.gd
    │   └── W1_Level1.gd ... W1_Level4.gd
    ├── world2/
    │   └── W2_Level1.gd
    ├── world3/
    │   └── W3_Level1.gd
    └── world4/
        └── W4_Level1.gd
```

La carpeta `World2` conserva por ahora una mayúscula inicial; las rutas deben respetar exactamente ese nombre, especialmente al trabajar en Linux.

## Progresión por mundos

El orden oficial vive en `GameManager.LEVEL_ORDER`:

1. Mundo 1, niveles 1–4: caminos de animales.
2. Mundo 2, nivel 1: lanzamiento del hechizo correcto.
3. Mundo 3, nivel 1: adjetivos.
4. Mundo 4, nivel 1: *In k'a'at*.

Cada nivel debe llamar `GameManager.complete_level(mundo, nivel)` con su identidad real. El botón **Continuar** consulta el primer elemento incompleto de `LEVEL_ORDER`; no construye nombres de escena suponiendo que todos pertenecen al Mundo 1.

Para agregar un nivel:

1. Crea su escena y script en las carpetas del mundo correspondiente.
2. Agrega una clave a `GameManager.SCENE_PATHS`.
3. Inserta sus datos en la posición correcta de `GameManager.LEVEL_ORDER`.
4. Configura la escena siguiente.
5. Registra su vocabulario en `GameManager.VOCABULARY`.
6. Prueba comenzar, terminar, salir al menú y usar **Continuar** con una partida nueva y una existente.

## Vocabulario

`GameManager.VOCABULARY` es la fuente única para traducción, emoji, estructura, mundo y nivel. Los scripts deben consultar `get_vocabulary_entry()` y `has_learned_word()` en lugar de comparar directamente las claves guardadas.

El cargador migra variantes antiguas —por ejemplo, `K'uum`— a la clave canónica `K'úum`, evitando entradas duplicadas en el libro. Las decisiones y excepciones provenientes del GDD están documentadas en [VOCABULARIO.md](VOCABULARIO.md).

## Guardado

El progreso se guarda automáticamente como `user://kalin_save.json`. Incluye:

- puntos mágicos;
- palabras aprendidas;
- identificadores `w<numero>_l<numero>` de los niveles completados.

El botón **Reiniciar progreso** elimina ese archivo. Al modificar el formato de guardado, se debe conservar una migración para las partidas existentes.

## Audio pendiente

Los audios todavía no están grabados. Cuando estén disponibles, colócalos en `Arte/audio/` como archivos OGG. Los nombres técnicos eliminan acentos, apóstrofes y espacios para que sean portables entre sistemas. La tabla completa está en [Arte/audio/README.md](Arte/audio/README.md).

## Comprobación antes de integrar cambios

La validación automática de catálogo, rutas, alias y nombres de audio se ejecuta desde la raíz con:

```powershell
godot_console.exe --headless --path . --script res://tests/validate_project.gd
```

1. Abrir el proyecto con Godot 4.6 y comprobar que no existan errores de análisis.
2. Ejecutar la introducción y probar **Saltar intro**.
3. Completar al menos un nivel de cada mundo.
4. Volver al menú entre niveles y comprobar **Continuar**.
5. Cerrar y abrir el juego para verificar el guardado.
6. Repetir el Mundo 4 con las palabras ya aprendidas.
7. Abrir el libro y comprobar la agrupación por mundo y nivel.
