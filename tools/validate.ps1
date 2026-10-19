param(
    [string]$GodotPath = "C:\herramientas\Godot\V_4.6\godot_console.exe"
)

$ErrorActionPreference = "Stop"
$expectedVersion = "4.6.3"
$projectRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "No se encontró Godot 4.6 en '$GodotPath'. Usa -GodotPath para indicar godot_console.exe."
}

$actualVersion = (& $GodotPath --version | Select-Object -First 1).Trim()
if (-not $actualVersion.StartsWith($expectedVersion)) {
    throw "Este proyecto requiere Godot $expectedVersion; se encontró $actualVersion."
}

$tests = @(
    "res://tests/validate_project.gd",
    "res://tests/validate_main_menu.gd",
    "res://tests/validate_intro.gd",
    "res://tests/validate_learning_flow.gd"
)

Push-Location $projectRoot
try {
    foreach ($test in $tests) {
        Write-Host "Ejecutando $test con Godot $actualVersion"
        $testOutput = & $GodotPath --headless --path . --script $test 2>&1
        $testOutput | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0 -or ($testOutput -join "`n") -match "SCRIPT ERROR:") {
            throw "Falló $test con código $LASTEXITCODE."
        }
    }
}
finally {
    Pop-Location
}

Write-Host "Todas las validaciones finalizaron correctamente."
