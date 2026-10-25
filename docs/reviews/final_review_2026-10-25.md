# Revisión final de regresiones — 25 de octubre de 2026

Se revisaron persistencia, reinicio, evidencia de aprendizaje, restauración de
checkpoints, tipos, referencias y posibles implementaciones en desuso. Los cambios
se limitaron a errores reproducidos y a las pruebas que los cubren.

## Errores corregidos

1. **Reinicio fallido que vaciaba la sesión.** `GameManager.reset_save()` borraba
   primero la memoria y avisaba a las vistas antes de comprobar la eliminación del
   archivo. Ahora conserva la sesión si falla el borrado; al tener éxito actualiza
   los indicadores de error antes de emitir señales. El repositorio elimina el
   archivo principal al final para conservarlo si falla la eliminación de auxiliares.
2. **Único respaldo ilegible ignorado.** Si faltaba el archivo principal y el `.bak`
   era incompatible o estaba dañado, se devolvía una partida ausente. Ahora se
   informa el error del único archivo disponible, conservando la protección contra
   guardados vacíos. No se agregaron migraciones ni formatos alternativos.
3. **Acreditación duplicada después de 128 intentos.** La normalización conservaba
   los primeros contextos y descartaba los nuevos. Se conserva una ventana de los
   128 contextos más recientes, tanto en memoria como al cargar JSON, para reconocer
   el último resultado y evitar contarlo de nuevo.
4. **Bloqueo de una misión con campos anidados dañados.** El contador de errores del
   objeto transportado y el modo de respuesta de un borrador podían convertirse a
   entero desde un objeto JSON. El esquema valida esos campos antes de que los
   consuma la escena, sin modificar el diccionario de origen. Un indicador de apoyo
   inválido se trata como apoyo, y un objeto transportado vacío permanece vacío.
5. **Bloqueo del portal con un índice de variación dañado.** La variación previa
   convertía su valor a entero sin validarlo. Los índices actuales y anteriores
   requieren ahora un número finito, entero y dentro del intervalo permitido.

Las reproducciones de persistencia e historial fallaron antes de las correcciones.
También se reprodujeron los errores de conversión al inicializar la misión y el
portal. La suite de [arquitectura](../../tests/unit/validate_architecture.gd) cubre
los nuevos casos, incluida la inicialización real de una misión con checkpoint
dañado y la restauración del historial desde JSON.

## Sistemas antiguos

No se detectaron nuevos scripts huérfanos, alias de compatibilidad, migraciones ni
copias de sistemas retirados en los árboles de código y recursos revisados.
Las únicas entradas sin referencia directa del inventario son `_validate_property`
y el botón de actualización del tablero: Godot las invoca desde el editor.

Se conserva el formato vigente 6. El respaldo y el archivo temporal protegen datos
actuales; no mantienen una versión anterior del juego. El historial de auditorías
documenta decisiones y no contiene implementaciones ejecutables de respaldo.

## Alcance de la validación

Las comprobaciones usan Godot 4.6.3 y perfiles temporales que no modifican la
partida personal. La importación sin caché comprueba además arquitectura y firmas.
La ejecución remota del workflow y las exportaciones a dispositivos quedan fuera
de esta revisión local.

Resultados finales:

- **25/25 suites de Godot aprobadas en una ejecución completa**, sin errores ni
  advertencias reportadas por el ejecutor.
- **6/6 pruebas de herramientas aprobadas**.
- **123 scripts** comprobados por la política de tipos y dependencias.
- **652 referencias y 122 UID** comprobados.
- Formato, `git diff --check`, importación sin caché, arquitectura y firmas:
  **aprobados**.
- Catálogos: **28 combinaciones, 48 tableros y 1392 textos** verificados.
