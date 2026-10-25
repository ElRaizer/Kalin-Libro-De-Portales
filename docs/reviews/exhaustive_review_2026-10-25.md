# Verificación ampliada de la base única — 25 de octubre de 2026

Esta revisión amplía la anterior con una matriz de restauración de todas las
escenas que producen checkpoints, pruebas de límites del dominio y fallos de
transición. También revisa referencias, propiedad del estado, dependencias,
tipado explícito e implementaciones sin consumidores. No modifica el contenido
ni las mecánicas del juego.

## Correcciones adicionales

| Caso | Corrección y cobertura |
|---|---|
| Listas en indicadores de ayuda, tarjetas o preferencias | Se comprueba el tipo booleano antes de consumir el valor. Se cubren intentos, sesiones de frases, borradores, apoyo por encargo y configuración de accesibilidad. |
| Ejercicio de alimentos restaurado al final del plan | El cambio de distribución no intenta consultar una ronda posterior a la última. La matriz restaura también contadores extremos que terminan normalizados al final del ejercicio. |
| Botones de bloques destruidos al pasar a otro ejercicio | `ScreenLayout` descarta las referencias liberadas o retiradas de la escena antes de aplicar tamaños y fuentes. Se prueba restaurar bloques, reconstruir las casillas y alternar ambos perfiles. |
| Finalización guardada con caminos incompletos | El tablero exige que sus conexiones estén completas antes de restaurar la celebración y bloquea la interacción al restaurar una finalización válida. |
| Destino de continuación actualizado antes de aceptar una transición | `SceneNavigator` captura el origen y sólo actualiza el destino después de recibir `OK`. Una visita rechazada también conserva el retorno anterior. Las pruebas inyectan el rechazo y comprueban las escrituras realizadas. |
| Escritura directa sobre un archivo de otra versión | `SaveRepository` rechaza la escritura antes de crear temporales, incluso cuando sólo existe el respaldo incompatible. Se comprueba que ambos archivos permanezcan intactos. |
| Palabras o niveles inexistentes aceptados por la sesión | `GameSession` valida los identificadores contra los catálogos actuales antes de agregar progreso o puntos. |
| Finalizar un camino contra una casilla propia distinta del destino | La regla de conexión exige la celda de destino de la palabra. Se prueban el inicio, una casilla del camino y el destino válido. |
| Otros valores anidados o arrastres con tipos incorrectos | Se protege la fase del objeto transportado y se validan la clase de arrastre y el panel de origen antes de compararlos. |

## Cobertura permanente añadida

- `tests/validate_checkpoint_integrity.gd`: para cada escena restaura un checkpoint
  válido, contenedores incorrectos, listas heterogéneas, datos anidados dañados,
  números extremos positivos y negativos, indicadores de finalización incoherentes,
  booleanos sustituidos por listas y hojas anidadas sustituidas por listas.
- La misma suite compara el contenido JSON antes y después de reanudar, además
  de comprobar que no se acrediten puntos nuevos. Los mapas dispersos de apoyo y
  errores se comparan con sus valores por defecto: una entrada ausente equivale
  a `false` o `0`, respectivamente.
- Se cubren el ciclo de controles dinámicos, los arrastres mal formados y la
  lectura de preferencias con campos de tipos incorrectos.
- `tests/unit/validate_state_transactions.gd`: rechazo de identificadores ajenos
  al catálogo, booleanos, reglas de conexión, barrera de escritura de versiones
  y continuidad del estado ante una transición fallida.

La validación utiliza perfiles temporales aislados. El ejecutor considera fallos
los errores de script, los errores del motor y las advertencias, aunque el proceso
devuelva código cero. La prueba de transición silencia únicamente el mensaje de
error esperado durante el rechazo que ella misma inyecta.

## Estado de la organización

Se mantiene una sola implementación activa por responsabilidad y el formato de
partida **6**. No se encontraron nuevos módulos huérfanos, alias de sistemas
retirados, migraciones históricas ni archivos de respaldo de código en el árbol
activo. El inventario sólo deja sin referencia textual directa el callback
`_validate_property` y el botón de actualización del tablero, que invoca Godot.

Los catálogos generados, los perfiles de presentación y las configuraciones de
autor son contenido vigente. El archivo `.bak` protege datos de partida actuales;
no es una implementación alternativa. Las auditorías anteriores son documentos
históricos. Las cachés y los archivos de comprobación locales están excluidos del
control de versiones y no forman parte de las escenas del juego.

## Resultados

- Godot **4.6.3**: **27/27 suites aprobadas en una ejecución completa**.
- Matriz ampliada, incluida la comparación de reanudación: **293 cargas y ciclo
  de controles aprobados**, en una ejecución adicional sin errores ni advertencias.
- Herramientas: **6/6 pruebas aprobadas**.
- Política de código: **125 scripts**, con tipos explícitos y límites de dependencias.
- Estructura: **653 referencias y 124 UID** comprobados.
- Catálogos: **28 combinaciones, 48 tableros y 1392 textos** comprobados.
- Importación desde una copia sin caché, arquitectura y firmas de ejercicios:
  **aprobadas**.
- Formato y `git diff --check`: **aprobados**.

La revisión comprueba la base local y sus flujos automatizados. No constituye una
ejecución remota del workflow ni una validación de exportaciones en dispositivos.
