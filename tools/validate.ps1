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
    "res://tests/validate_learning_flow.gd",
    "res://tests/validate_ux.gd",
    "res://tests/validate_adventure.gd",
    "res://tests/validate_visual_flow.gd",
    "res://tests/validate_animation_loops.gd",
    "res://tests/validate_inspector.gd",
    "res://tests/validate_authoring.gd",
    "res://tests/validate_story_interaction.gd",
    "res://tests/validate_answer_layout.gd",
    "res://tests/validate_learning_evidence.gd",
    "res://tests/validate_book.gd",
    "res://tests/validate_adventure_polish.gd",
    "res://tests/validate_tutorial_gestures.gd",
    "res://tests/validate_replayability.gd",
    "res://tests/validate_game_expansion.gd",
    "res://tests/validate_debug_answer.gd",
    "res://tests/validate_block_interactions.gd",
    "res://tests/validate_village_life.gd",
    "res://tests/validate_village_dialogue.gd",
    "res://tests/validate_village_composition.gd",
    "res://tests/validate_combinations.gd"
)

$validationPreviousAppData = $env:APPDATA
$validationPreviousLocalAppData = $env:LOCALAPPDATA
$validationTempRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".godot"))
$validationRuntime = Join-Path $validationTempRoot ("Kalin-validation-" + [Guid]::NewGuid().ToString("N"))
$env:APPDATA = Join-Path $validationRuntime "Roaming"
$env:LOCALAPPDATA = Join-Path $validationRuntime "Local"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

Push-Location $projectRoot
try {
    $importOutput = & $GodotPath --headless --path . --editor --quit 2>&1
    $importOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or ($importOutput -join "`n") -match "(?m)^(SCRIPT ERROR:|ERROR:|WARNING:)") {
        throw "Falló la carga del proyecto en el editor."
    }
    foreach ($test in $tests) {
        Write-Host "Ejecutando $test con Godot $actualVersion"
        $testOutput = & $GodotPath --headless --path . --script $test 2>&1
        $testOutput | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0 -or ($testOutput -join "`n") -match "(?m)^(SCRIPT ERROR:|ERROR:|WARNING:)") {
            throw "Falló $test con código $LASTEXITCODE."
        }
    }
}
finally {
    Pop-Location
    $env:APPDATA = $validationPreviousAppData
    $env:LOCALAPPDATA = $validationPreviousLocalAppData
    $validationResolved = [IO.Path]::GetFullPath($validationRuntime)
    if ((Split-Path -Parent $validationResolved).TrimEnd('\') -ne $validationTempRoot.TrimEnd('\') -or
        (Split-Path -Leaf $validationResolved) -notmatch '^Kalin-validation-[a-f0-9]{32}$') {
        throw "La ruta temporal de validación no es válida para su limpieza."
    }
    if (Test-Path -LiteralPath $validationResolved) {
        Remove-Item -LiteralPath $validationResolved -Recurse -Force
    }
}

Write-Host "Todas las validaciones finalizaron correctamente."
