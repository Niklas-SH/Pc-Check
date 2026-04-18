<#
pc_check_runner.ps1
Wrapper zum Ausführen von `pc_check.ps1` lokal oder auf entfernten Rechnern via PowerShell-Remoting.

Usage examples:
- Lokal:    .\pc_check_runner.ps1
- Remote:   .\pc_check_runner.ps1 -Targets host1,host2 -Credential (Get-Credential) -OutDir .\reports

Voraussetzungen für Remote-Lauf:
- PowerShell-Remoting (WinRM) auf Zielrechnern aktiviert
- Passende Anmeldeinformationen (Administratorkonto auf Ziel)
- Firewall/Netzwerk-Konnektivität
#>

param(
    [string[]]$Targets,
    [PSCredential]$Credential,
    [string]$OutDir = "",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$pcScript = Join-Path $scriptRoot 'pc_check.ps1'

if (-not (Test-Path $pcScript)) {
    Write-Error "pc_check.ps1 nicht gefunden in: $scriptRoot. Bitte stelle sicher, dass beide Skripte im selben Ordner liegen."
    exit 1
}

if (-not $OutDir) { $OutDir = Join-Path $scriptRoot 'reports' }
if (-not [System.IO.Path]::IsPathRooted($OutDir)) { $OutDir = Join-Path $scriptRoot $OutDir }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function Run-Local {
    param([string]$OutDir)
    $computer = $env:COMPUTERNAME
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $outfile = Join-Path $OutDir ("{0}-report-{1}.txt" -f $computer, $timestamp)
    Write-Host "[LOCAL] Running pc_check -> $outfile"
    try {
        & $pcScript -OutFile $outfile
        Write-Host "[LOCAL] Saved: $outfile"
    } catch {
        Write-Warning "[LOCAL] Fehler beim Check: $_"
    }
}

if (-not $Targets -or $Targets.Count -eq 0) {
    Run-Local -OutDir $OutDir
    exit 0
}

if (-not $Credential) {
    $Credential = Get-Credential -Message 'Enter credentials for remote hosts (use Admin account)'
}

foreach ($t in $Targets) {
    Write-Host "---- $t ----"
    if (-not (Test-Connection -ComputerName $t -Count 1 -Quiet)) {
        Write-Warning "$t nicht erreichbar (Ping fehlgeschlagen). Überspringe."
        continue
    }

    $session = $null
    try {
        $session = New-PSSession -ComputerName $t -Credential $Credential -ErrorAction Stop
        $remoteTempDir = Invoke-Command -Session $session -ScriptBlock { $env:TEMP } -ErrorAction Stop
        $guid = [guid]::NewGuid().ToString()
        $remoteScriptPath = Join-Path $remoteTempDir ("pc_check_${guid}.ps1")
        $remoteReportPath = Join-Path $remoteTempDir ("pc_check_report_${guid}.txt")

        Write-Host ("Kopiere Skript nach {0}:{1} ..." -f $t, $remoteScriptPath)
        $scriptContent = Get-Content -Path $pcScript -Raw -ErrorAction Stop
        Invoke-Command -Session $session -ScriptBlock {
            param($path,$content)
            Set-Content -Path $path -Value $content -Force -Encoding UTF8
        } -ArgumentList $remoteScriptPath,$scriptContent -ErrorAction Stop

        Write-Host "Starte Check auf $t (remote)..."
        Invoke-Command -Session $session -ScriptBlock {
            param($scriptPath,$outFile)
            & $scriptPath -OutFile $outFile
        } -ArgumentList $remoteScriptPath,$remoteReportPath -ErrorAction Stop

        Write-Host "Hole Report von $t ..."
        $remoteContent = Invoke-Command -Session $session -ScriptBlock { param($p) Get-Content -Path $p -Raw } -ArgumentList $remoteReportPath -ErrorAction Stop
        $localReportPath = Join-Path $OutDir ("{0}-{1}.txt" -f $t, (Get-Date -Format 'yyyyMMdd-HHmmss'))
        Set-Content -Path $localReportPath -Value $remoteContent -Encoding UTF8
        Write-Host "Report gespeichert: $localReportPath"

        Write-Host "Bereinige temporäre Dateien auf $t ..."
        Invoke-Command -Session $session -ScriptBlock { param($a,$b) Remove-Item -Path $a,$b -Force -ErrorAction SilentlyContinue } -ArgumentList $remoteScriptPath,$remoteReportPath -ErrorAction SilentlyContinue

        Remove-PSSession -Session $session
    } catch {
        Write-Warning ("Fehler bei {0}: {1}" -f $t, $_)
        if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
    }
}

Write-Host "Fertig. Alle Reports im Ordner: $OutDir"
