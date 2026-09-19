# Auditoría de buenas prácticas

Revisión realizada sobre Godot 4.6.3. El criterio principal es la documentación
oficial de Godot sobre organización de proyectos y escenas, estilo GDScript,
autoloads, recursos y persistencia.

## Resumen

| Área | Estado | Resultado |
|---|---|---|
| Organización por funciones | Cumple | `scenes/`, `scripts/`, `themes/`, `tests/` y arte están separados; los mundos están agrupados. |
| Escenas reutilizables | Cumple | `GridBoard` y `LibroHechizos` son escenas autocontenidas y reutilizadas. |
| Datos separados de la lógica | Cumple | `GridWordData` configura cada tablero desde el Inspector y el vocabulario tiene una fuente única. |
| Estado global | Cumple | `GameManager` concentra progreso, guardado y navegación; no contiene lógica visual de niveles. |
| Señales y acoplamiento | Cumple | El tablero comunica selección y conexión mediante señales; los niveles deciden narrativa y recompensas. |
| Tipado de GDScript | Cumple parcialmente | La API principal y los nodos están tipados. Se corrigieron estados y colecciones importantes; algunos diccionarios de contenido siguen siendo dinámicos por diseño. |
| Entrada y UI | Corregido | La entrada global pasó a `_unhandled_input()`, evitando que un clic en un botón también avance o cierre otra interfaz. |
| Persistencia | Corregido | El guardado ahora tiene versión, comprueba errores de apertura/escritura, informa JSON dañado y descarta niveles inválidos o duplicados. |
| Configuración de componentes | Corregido | `GridBoard` muestra advertencias en el editor por texturas faltantes, palabras vacías, celdas fuera de rango, duplicados y solapamientos. |
| Portabilidad | Corregido | Git registra `scenes/world2` con la misma capitalización usada por las rutas. Se añadieron reglas de fin de línea y editor. |
| Carga de recursos | Mejorado | Se eliminaron cargas redundantes de fondos ya configurados en escenas y los recursos fijos del Mundo 4 usan `preload`. |
| Pruebas automáticas | Mejorado | La validación comprueba todas las escenas registradas, las instancia y revisa la configuración de cada tablero. |
| Estilo GDScript | Mejorado | Se separaron varias instrucciones por línea, se sustituyeron cierres innecesarios por métodos/bind y se retiró estado muerto. |

## Decisiones que conviene conservar

- Un autoload pequeño para progreso y navegación es apropiado en este proyecto.
- Las escenas del Mundo 1 heredan un controlador común y contienen sus datos en
  recursos: evita duplicar la mecánica.
- `GameManager.VOCABULARY` funciona como fuente única. No deben duplicarse
  traducciones o metadatos en nuevos controladores.
- JSON es suficiente para el estado actual, que es pequeño y solo contiene
  tipos compatibles. Si el guardado incorpora recursos, vectores u objetos,
  habrá que migrar el formato.

## Pendientes que requieren una decisión de producto

- **Accesibilidad y teclado:** los niveles 2–4 dependen principalmente del
  ratón. Hay que definir navegación por foco, contraste objetivo y tamaños
  mínimos con pruebas de usuarios.
- **Diseño adaptable:** la interfaz fue compuesta para 1280 × 720. Antes de
  publicar en móvil o web se deben definir relaciones de aspecto objetivo y
  probar escalado, áreas seguras y texto largo.
- **Localización:** los textos están incrustados en escenas y scripts. Si habrá
  más idiomas, deben migrarse a claves de traducción y archivos de catálogo.
- **Contenido lingüístico:** grafías, traducciones y pronunciaciones necesitan
  validación de una persona especialista en maya yucateco.
- **Nombres históricos:** escenas y scripts existentes usan PascalCase o
  prefijos como `W1_`. La guía recomienda `snake_case`, pero un renombrado total
  modifica todas las rutas y enlaces externos. Debe hacerse en una migración
  aislada cuando el equipo confirme que no hay material externo que dependa de
  esos nombres.
- **Cobertura:** la prueba actual es de estructura y una interacción del Mundo
  3. Faltan pruebas end-to-end de entrada, navegación, reinicio y migraciones de
  partidas reales.

## Regla para cambios futuros

Antes de integrar un cambio, ejecutar:

```powershell
godot_console.exe --headless --path . --editor --quit
godot_console.exe --headless --path . --script res://tests/validate_project.gd
```

Después, probar manualmente la escena modificada y al menos una transición de
entrada y salida. No deben ignorarse advertencias nuevas del editor.

## Referencias oficiales

- [Organización de proyectos](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
- [Organización y acoplamiento de escenas](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)
- [Guía de estilo de GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Guardado de partidas](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)
