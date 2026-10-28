# Mantenimiento y validación

Antes de agregar o modificar código, consultar las reglas de trabajo de
[AGENTS.md](../AGENTS.md). La arquitectura y este documento mantienen los contratos
y los comandos vigentes; las revisiones históricas registran decisiones anteriores.

## Preparación

El motor requerido está en `.godot-version` (**4.6.3**). El juego no necesita
Python ni paquetes externos para ejecutarse. Python y gdtoolkit se usan en
desarrollo para generar catálogos y mantener el formato.

```powershell
python -m pip install -r requirements-dev.txt
$env:GODOT_BIN = "C:\ruta\a\godot_console.exe"
```

También se puede pasar `-GodotPath` al ejecutor. Si no se especifica ni la
variable ni el argumento, busca la versión fijada en `PATH`; no usa una versión
más nueva automáticamente. Las herramientas funcionan desde cualquier carpeta.

## Comprobaciones antes de integrar

Desde la raíz:

```powershell
python tools/check_structure.py
python tools/check_code_policy.py
python -m unittest discover -s tests/tooling -v
python tools/build_combination_catalog.py --check
python tools/build_grid_variants.py --check
python tools/build_combination_dialogue.py --check
.\tools\format.ps1 -Check
.\tools\validate.ps1
```

El ejecutor importa el proyecto y descubre recursivamente las suites
`validate_*.gd`. Cada suite tiene un límite predeterminado de 180 segundos,
configurable con `-TimeoutSeconds`. Los errores de script y las advertencias
también hacen fallar la ejecución, incluso si el proceso devuelve código 0.
Los datos temporales quedan aislados de la partida personal y se eliminan al
terminar. No lanzar suites directamente contra una sesión personal para evitar
que los autoloads lean sus preferencias o progreso.

Para una comprobación puntual:

```powershell
.\tools\validate.ps1 -Suite validate_architecture
```

Para aplicar el formato:

```powershell
.\tools\format.ps1
```

El formateador se fija en `gdtoolkit==4.5.0`, con tabulaciones y ancho de 100.
Godot sigue siendo la autoridad para analizar y ejecutar GDScript 4.6.3.

## Editar contenido

Los `ExerciseSet` y perfiles se editan en el Inspector. Si una edición del
catálogo canónico debe conservar la variación, revisar primero su significado,
opciones y retratos, y después confirmar su firma:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tools/sign_exercises.gd -- --check
& $env:GODOT_BIN --headless --path . --script res://tools/sign_exercises.gd -- --write
```

Esta herramienta sólo revisa o escribe firmas de recursos; no monta escenas ni
recorre niveles. Para el flujo aislado de pruebas utilizar `tools/validate.ps1`.
No confirmar una firma para ocultar una diferencia inesperada: la firma protege
las personalizaciones de autor.

Para editar combinaciones, diálogos o tableros, modificar su manifiesto revisado
y regenerar sin `--check`. Los bancos de diálogo existentes se preservan; el
generador agrega únicamente las combinaciones faltantes. Las herramientas no
interpretan constantes GDScript mediante divisiones de texto.

## Mover archivos y cambiar contratos

1. Preservar UID y actualizar referencias físicas en escenas, recursos,
   configuración, pruebas y documentación.
2. Mantener las claves semánticas de escena y vocabulario al cambiar rutas físicas.
3. Si cambia un contrato persistido, actualizar `SaveSchema.CURRENT_VERSION` y
   documentar el reinicio requerido; esta base no mantiene migraciones históricas.
4. Verificar una partida nueva y una reanudada, además del contrato del
   Inspector, teclado, apoyos y entradas/salidas de la actividad.

El contenedor se valida en `SaveSchema` y se decodifica en `SessionCodec`.
Las escenas validan los detalles de su familia de estado. Sólo se admite el
formato vigente, tanto al leer como al escribir. Los contratos se prueban en `tests/unit/validate_architecture.gd`
y en las suites de integración existentes.
La matriz de reanudación está en `tests/validate_checkpoint_integrity.gd`; los
rechazos de escritura y transición se prueban en
`tests/unit/validate_state_transactions.gd`.

## Integración continua

`.github/workflows/validate.yml` instala el motor fijado, comprueba estructura, tipado, dependencias, catálogos y
formato, e importa y ejecuta las suites en Windows. Se activa en pull requests,
publicaciones a `main`/`master` y de forma manual. Su ejecución remota debe
comprobarse después de publicar estos cambios; crear el archivo no confirma que
GitHub lo haya ejecutado.

## Capturas con el mismo aislamiento

El ejecutor permite usar renderer real y pasar el destino de las capturas a una
suite que lo admita. Seleccionar una sola suite es obligatorio para este modo:

```powershell
.\tools\validate.ps1 -GodotPath $env:GODOT_BIN -Suite validate_product_improvements -CaptureDirectory "$PWD/.ui-review/implementation"
```

La partida y las preferencias siguen aisladas. Los errores y advertencias del motor
mantienen los mismos criterios de fallo que la validación headless.
