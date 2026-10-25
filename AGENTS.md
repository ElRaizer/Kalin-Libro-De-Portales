# Guía de trabajo del proyecto

Estas instrucciones se aplican a todo el repositorio. Cada cambio debe mantener
la base única vigente, con responsabilidades claras, tipos explícitos y pruebas
proporcionales a su impacto. La limpieza forma parte del cambio que introduce
una funcionalidad; no se pospone a una auditoría futura.

## Antes de modificar

1. Leer [Arquitectura](docs/architecture.md) y
   [Mantenimiento](docs/maintenance.md). Consultar la
   [guía de autoría](docs/technical_guide.md) al cambiar escenas, recursos o UI.
2. Revisar el estado de Git y los consumidores del código afectado. Conservar
   los cambios existentes del usuario y entender el contrato antes de sustituirlo.
3. Buscar una implementación o configuración vigente que ya resuelva la necesidad.
   Elegir el propietario y la carpeta del cambio antes de agregar archivos.
4. Usar el motor fijado en `.godot-version` y las herramientas de
   `requirements-dev.txt`. No actualizar versiones como efecto secundario de otra tarea.

Las referencias vigentes son los documentos anteriores y el código actual.
`docs/reviews/` conserva decisiones históricas; sus árboles, cifras y ejemplos
no sustituyen la arquitectura actual.

## Organización y responsabilidad

- `scripts/core/`: reglas y estado compartidos. El dominio recibe datos y devuelve
  resultados o eventos; no consulta autoloads, nodos, UI ni archivos. La navegación
  y la persistencia tienen sus propias dependencias, descritas en Arquitectura.
- `scripts/features/`: componentes de una función, reutilizables por varios mundos.
  `scripts/worlds/`: composición y comportamiento específico de cada mundo.
- `scripts/ui/`: presentación de uso general. Organizar `scenes/` por las mismas
  familias. La configuración editable pertenece a `data/`; los estilos, a `themes/`.
  Mantener el arte compartido en `Arte/`.
- `GameSession` posee el progreso mutable. `GameManager` coordina servicios y señales;
  no acumular allí reglas de escenas, catálogos, acceso a disco ni campos que
  repliquen el estado de la sesión.
- Reutilizar `SceneNavigator`, `SaveRepository`, los esquemas y los modelos de
  dominio existentes para sus responsabilidades. Cada dato mutable debe tener
  un propietario; las vistas consumen ese estado sin mantener una segunda fuente.
- Usar APIs públicas y señales con contratos claros. No llamar métodos privados
  de otro componente desde código de ejecución ni recorrer su árbol interno
  para modificar su estado. Las pruebas pueden inspeccionar detalles para verificar
  un comportamiento que no expone la API pública.
- Separar reglas, entrada y presentación cuando tengan motivos distintos para
  cambiar. Evitar controladores que concentren responsabilidades y abstracciones
  creadas para necesidades hipotéticas. Un archivo compartido pertenece a su
  función, no al primer mundo que lo utilizó ni a una carpeta genérica de utilidades.
- Al reemplazar un sistema, actualizar sus consumidores y retirar lo que quedó
  sin uso. No dejar copias `_old`, `_backup`, `_v2`, alias retirados o rutas alternativas
  por precaución. La recuperación de código corresponde al historial de Git.

## GDScript y recursos

- Declarar tipos explícitos en variables, bucles, parámetros, señales y retornos
  de funciones nombradas. Usar colecciones tipadas cuando el contrato sea homogéneo.
  `var value := ...` no cumple la política de variables del proyecto.
- Reservar `Variant` y las colecciones heterogéneas para fronteras que lo necesitan,
  como JSON y ciertas APIs de Godot. Validar allí los datos y trabajar después
  con contratos concretos; no usar conversiones o supresiones para ocultar errores.
- Archivos y carpetas en `snake_case`; clases y nodos en `PascalCase`.
  Identificadores técnicos nuevos en inglés; textos visibles y documentación en español.
- Seguir `.editorconfig` y `tools/format.ps1`: UTF-8, LF, tabulaciones en GDScript
  y ancho de 100. Usar nombres descriptivos y comentarios que expliquen decisiones.
- Los `Resource` compartidos son configuración. Duplicar los datos que una sesión
  vaya a modificar; no alterar el recurso canónico al preparar una partida.
  Conservar las personalizaciones editables del Inspector.
- Preservar los `.gd.uid` al mover scripts y versionar los de archivos nuevos.
  Actualizar referencias físicas con su capitalización exacta y conservar las
  identidades semánticas de escenas y vocabulario al cambiar rutas.

## UI, tipografías y ciclo de vida

- Reutilizar `themes/kalin_theme.tres` y sus variaciones para fuentes, colores y
  estilos compartidos. Los ajustes de distribución y tipografía compacta pertenecen
  a los perfiles de `data/layouts/` y a `ScreenLayout`. Evitar replicarlos en cada
  controlador; una excepción local debe expresar una necesidad concreta del componente.
- Mantener la navegación por teclado, el foco, las preferencias de accesibilidad
  y la pausa al extender controles existentes. Verificar los perfiles de escritorio
  y compacto cuando el cambio afecte a su distribución.
- Asociar señales, tweens y trabajo diferido al ciclo de vida de sus propietarios.
  Comprobar las referencias que pueden sobrevivir a controles destruidos y retirar
  esas referencias de las cachés. Las transiciones y el cierre de una UI deben
  conservar correctamente la pausa y el estado del ejercicio.

## Persistencia y contenido canónico

- Mantener un único formato vigente, definido por `SaveSchema.CURRENT_VERSION`.
  No reintroducir migraciones, alias ni recuperación de sistemas históricos.
  Un cambio incompatible requiere actualizar el contrato, su versión y la documentación.
- Validar también los campos anidados: tipo antes de comparar o convertir, y
  números finitos, enteros cuando corresponda y dentro del rango permitido.
  Contrastar indicadores de finalización con el estado real de la actividad.
- Los checkpoints contienen datos JSON y copias profundas, nunca nodos ni recursos.
  Probar que reanudar conserve las respuestas, los apoyos y el progreso sin acreditar
  resultados otra vez. Una carga fallida debe conservar la sesión anterior.
- Actualizar el estado y notificar a las vistas después de confirmar la operación
  que lo justifica. Si falla un borrado o una transición, conservar el progreso y
  la continuación anteriores. Respetar la escritura temporal, el respaldo de datos
  actuales y el rechazo de archivos de otra versión.
- Editar las fuentes de los catálogos y ejecutar sus generadores. No editar a mano
  las salidas de `tools/generated-files.txt` ni crear catálogos paralelos.
  Revisar los cambios de contenido antes de actualizar firmas de ejercicios;
  nunca regenerar una firma sólo para hacer pasar una comprobación.

## Validación y cierre de cada cambio

- Para documentación únicamente, comprobar enlaces con
  `python tools/check_structure.py` y espacios con `git diff --check`.
- Para código, ejecutar política de tipos y dependencias, estructura y formato.
  Usar los comandos de [Mantenimiento](docs/maintenance.md), que son la referencia
  del proceso, y revisar el diff antes de terminar.
- Para cambios de ejecución, escenas o recursos, ejecutar las suites afectadas
  durante el trabajo y la validación completa con `tools/validate.ps1` antes de
  dar el cambio por listo para integrar. Comprobar también los catálogos según
  Mantenimiento. No fijar cantidades de pruebas en instrucciones: el ejecutor
  descubre las suites vigentes.
- Ejecutar las pruebas mediante ese ejecutor y sus perfiles aislados. No lanzar
  suites contra la partida personal. Errores de script, errores del motor y
  advertencias hacen fallar la validación, aunque el proceso termine con código cero.
- Al corregir un bug, agregar una regresión que compruebe el comportamiento cuando
  aporte cobertura nueva. Para cambios de estado, considerar inicio, reanudación,
  finalización, repetición y fallo de la operación según el flujo afectado.
  No agregar pruebas que sólo reproduzcan la implementación ni debilitar controles
  para aceptar una regresión; si cambia el contrato, justificar y actualizar su cobertura.
- Actualizar los documentos canónicos cuando cambien contratos o responsabilidades.
  No crear una auditoría nueva por cada tarea ni duplicar las reglas en varios documentos.
- Al entregar, explicar qué cambió, qué comprobaciones se ejecutaron y cualquier
  limitación o fallo pendiente. No afirmar que una prueba pasó si no se ejecutó.
