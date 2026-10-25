param([switch]$Check)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$formatter = Get-Command gdformat -ErrorAction SilentlyContinue
if (-not $formatter) { throw "Instala python -m pip install -r requirements-dev.txt." }
$version = & $formatter.Source --version
if ($version -notmatch '\b4\.5\.0\b') { throw "Se requiere gdtoolkit 4.5.0; se encontró $version." }
$generated = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'generated-files.txt'))
$files = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'scripts'),(Join-Path $projectRoot 'tests') -Recurse -Filter '*.gd' -File |
    Where-Object { $_.FullName.Substring($projectRoot.Length + 1).Replace('\','/') -notin $generated } |
    Select-Object -ExpandProperty FullName)
$arguments = @('--line-length=100')
if ($Check) { $arguments += '--check' }
& $formatter.Source @arguments @files
if ($LASTEXITCODE -ne 0) { throw "El formato GDScript requiere correcciones. Ejecuta tools/format.ps1." }
if (-not $Check) {
    $encoding = [Text.UTF8Encoding]::new($false)
    foreach ($file in $files) {
        $text = [IO.File]::ReadAllText($file)
        if ($text.Contains("`r`n")) {
            [IO.File]::WriteAllText($file, $text.Replace("`r`n", "`n"), $encoding)
        }
    }
}
