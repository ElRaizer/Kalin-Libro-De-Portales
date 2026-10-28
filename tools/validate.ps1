param(
    [string]$GodotPath = $env:GODOT_BIN,
    [ValidateRange(10, 1800)][int]$TimeoutSeconds = 180,
    [string]$Suite = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$expectedVersion = (Get-Content -LiteralPath (Join-Path $projectRoot ".godot-version") -Raw).Trim()

function Invoke-Godot {
    param([string[]]$Arguments, [int]$LimitSeconds = $TimeoutSeconds)
    $process = [Diagnostics.Process]::new()
    $process.StartInfo.FileName = $script:GodotPath
    # Argumentos separados, sin shell intermedio. El fallback mantiene
    # compatibilidad con Windows PowerShell 5.1 y rutas con espacios.
    if ($process.StartInfo.PSObject.Properties.Name -contains 'ArgumentList') {
        foreach ($argument in $Arguments) { $process.StartInfo.ArgumentList.Add($argument) }
    }
    else {
        $process.StartInfo.Arguments = ($Arguments | ForEach-Object {
            '"' + ($_ -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
        }) -join ' '
    }
    $process.StartInfo.WorkingDirectory = $projectRoot
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    try {
        $null = $process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($LimitSeconds * 1000)) {
            $process.Kill()
            $process.WaitForExit()
            throw "Godot excedió $LimitSeconds segundos: $($Arguments -join ' ')"
        }
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
        }
    }
    finally { $process.Dispose() }
}

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    foreach ($name in @("godot_console", "godot")) {
        $candidate = Get-Command $name -ErrorAction SilentlyContinue
        if ($candidate) {
            $GodotPath = $candidate.Source
            $version = Invoke-Godot -Arguments @("--version") -LimitSeconds 10
            if ($version.Output.Trim() -match ("^" + [regex]::Escape($expectedVersion) + '(\.|$)')) { break }
            $GodotPath = ""
        }
    }
}
if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Indica Godot $expectedVersion con -GodotPath o GODOT_BIN; también se admite la versión fijada en PATH."
}
$GodotPath = (Resolve-Path -LiteralPath $GodotPath).Path
$version = Invoke-Godot -Arguments @("--version") -LimitSeconds 10
$actualVersion = $version.Output.Trim()
if ($version.ExitCode -ne 0 -or $actualVersion -notmatch ("^" + [regex]::Escape($expectedVersion) + '(\.|$)')) {
    throw "Este proyecto requiere Godot $expectedVersion; se encontró $actualVersion."
}
$tests = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot "tests") -Recurse -File -Filter 'validate_*.gd' |
    Sort-Object @{Expression = { if ($_.Name -eq 'validate_project.gd') { 0 } else { 1 } }}, FullName |
    ForEach-Object { "res://" + $_.FullName.Substring($projectRoot.Length + 1).Replace('\', '/') })
if ($Suite) {
    $tests = @($tests | Where-Object { [IO.Path]::GetFileNameWithoutExtension($_) -eq $Suite })
}
if ($tests.Count -eq 0) { throw "No se encontraron suites para '$Suite'." }

$validationPreviousAppData = $env:APPDATA
$validationPreviousLocalAppData = $env:LOCALAPPDATA
$validationTempRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".godot"))
$validationRuntime = Join-Path $validationTempRoot ("Kalin-validation-" + [Guid]::NewGuid().ToString("N"))
$env:APPDATA = Join-Path $validationRuntime "Roaming"
$env:LOCALAPPDATA = Join-Path $validationRuntime "Local"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null

Push-Location $projectRoot
try {
    $importResult = Invoke-Godot -Arguments @("--headless", "--path", ".", "--editor", "--quit")
    $importOutput = $importResult.Output
    $importOutput | ForEach-Object { Write-Host $_ }
    if ($importResult.ExitCode -ne 0 -or ($importOutput -join "`n") -match "(?m)^(SCRIPT ERROR:|ERROR:|WARNING:)") {
        throw "Falló la carga del proyecto en el editor."
    }
    foreach ($test in $tests) {
        Write-Host "Ejecutando $test con Godot $actualVersion"
        $testResult = Invoke-Godot -Arguments @("--headless", "--path", ".", "--script", $test)
        $testOutput = $testResult.Output
        $testOutput | ForEach-Object { Write-Host $_ }
        if ($testResult.ExitCode -ne 0 -or ($testOutput -join "`n") -match "(?m)^(SCRIPT ERROR:|ERROR:|WARNING:)") {
            throw "Falló $test con código $($testResult.ExitCode)."
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

Write-Host "Validación completada: $($tests.Count)/$($tests.Count) suites aprobadas."
