<#
package.ps1 - Erzeugt ein ZIP-Paket des `pc-check`-Ordners zur Verteilung.
Usage:
  .\package.ps1            # erstellt dist\pc-check.zip
  .\package.ps1 -Output .\my.zip -Force
#>

param(
    [string]$Output = "",
    [switch]$Force
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Das Skript liegt bereits im `pc-check` Ordner, daher ist die Quelle das Verzeichnis selbst
$sourceDir = $scriptRoot
if (-not (Test-Path $sourceDir)) {
    Write-Error "Quellordner nicht gefunden: $sourceDir"
    exit 1
}

if (-not $Output) {
    $distDir = Join-Path $scriptRoot 'dist'
    if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
    $Output = Join-Path $distDir 'pc-check.zip'
} else {
    if (-not [System.IO.Path]::IsPathRooted($Output)) {
        $Output = Join-Path $scriptRoot $Output
    }
    $outDir = Split-Path -Parent $Output
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
}

if ((Test-Path $Output) -and (-not $Force)) {
    Write-Host "Output existiert bereits: $Output. Nutze -Force um zu überschreiben."
    exit 1
}

Compress-Archive -Path (Join-Path $sourceDir '*') -DestinationPath $Output -Force
Write-Host "Paket erstellt: $Output"
