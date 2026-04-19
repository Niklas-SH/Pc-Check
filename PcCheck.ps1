<#
PcCheck.ps1 - Single-file bootstrap (DE)

Diese Datei ist eine einsatzbereite Single-File-Version des PC-Checks. Sie kann
direkt per Raw-GitHub-URL ausgeführt werden, z.B.:

iex (irm 'https://raw.githubusercontent.com/<GITHUB_USER>/<REPO>/main/PcCheck.ps1')

Ersetze <GITHUB_USER> und <REPO> nachdem du das Repository auf GitHub angelegt und
hochgeladen hast.
#>

param(
    [string]$OutFile = ""
)

# Der folgende Inhalt ist identisch mit pc_check.ps1, damit dieses File alleine lauffähig ist.

function Show-Banner {
    param([switch]$Colored)

    # Bestimme Skriptordner robust: PSScriptRoot wenn verfügbar, sonst MyInvocation
    $scriptRoot = $PSScriptRoot
    if (-not $scriptRoot -or $scriptRoot -eq '') { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition }

    $candidates = @('banner.txt','banner.asc','ascii-banner.txt','pc-banner.txt')
    $bannerLines = $null

    foreach ($f in $candidates) {
        if (-not $scriptRoot -or $scriptRoot -eq '') { break }
        $p = Join-Path $scriptRoot $f
        if (-not (Test-Path $p)) { continue }

        # Versuche mehrere Encodings (UTF8, Default, OEM 437) um Anzeige-Probleme zu vermeiden
        $encodings = @([System.Text.Encoding]::UTF8, [System.Text.Encoding]::Default)
        try { $encodings += [System.Text.Encoding]::GetEncoding(437) } catch {}

        foreach ($enc in $encodings) {
            try {
                $raw = [System.IO.File]::ReadAllText($p, $enc)
                if ($raw -and $raw.Trim().Length -gt 0) {
                    $bannerLines = $raw -split "`r?`n"
                    break
                }
            } catch { }
        }
        if ($bannerLines) { break }
    }

if (-not $bannerLines) {
    $banner = @'
 ███████████     █████████      █████████  █████   █████ ██████████   █████████  █████   ████ ██████████ ███████████  
▒▒███▒▒▒▒▒███   ███▒▒▒▒▒███    ███▒▒▒▒▒███▒▒███   ▒▒███ ▒▒███▒▒▒▒▒█  ███▒▒▒▒▒███▒▒███   ███▒ ▒▒███▒▒▒▒▒█▒▒███▒▒▒▒▒███ 
 ▒███    ▒███  ███     ▒▒▒    ███     ▒▒▒  ▒███    ▒███  ▒███  █ ▒  ███     ▒▒▒  ▒███  ███    ▒███  █ ▒  ▒███    ▒███ 
 ▒██████████  ▒███           ▒███          ▒███████████  ▒██████   ▒███          ▒███████     ▒██████    ▒██████████  
 ▒███▒▒▒▒▒▒   ▒███           ▒███          ▒███▒▒▒▒▒███  ▒███▒▒█   ▒███          ▒███▒▒███    ▒███▒▒█    ▒███▒▒▒▒▒███ 
 ▒███         ▒▒███     ███  ▒▒███     ███ ▒███    ▒███  ▒███ ▒   █▒▒███     ███ ▒███ ▒▒███   ▒███ ▒   █ ▒███    ▒███ 
 █████         ▒▒█████████    ▒▒█████████  █████   █████ ██████████ ▒▒█████████  █████ ▒▒████ ██████████ █████   █████
▒▒▒▒▒           ▒▒▒▒▒▒▒▒▒      ▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒   ▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒   ▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒   ▒▒▒▒▒  
'@

    $bannerLines = $banner -split "`n"
    # Stelle Console-Ausgabe-Encoding auf UTF8, falls möglich
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

    foreach ($l in $bannerLines) {
        if ($Colored) { Write-Host $l -ForegroundColor Red } else { Write-Host $l }
        if ($OutFile -ne "") { $l | Out-File -FilePath $OutFile -Append -Encoding UTF8 }
    }
    Write-Host ""
function Log {
    param(
        [string]$Text,
        [string]$Color = 'Default',
        [switch]$NoConsole
    )
    if ($null -eq $Text) { $Text = "" }
    if ($OutFile -ne "") {
        $Text | Out-File -FilePath $OutFile -Append -Encoding UTF8
    }
    if ($global:LiveLogPath -and ($global:LiveLogPath -ne '')) {
        try { $Text | Out-File -FilePath $global:LiveLogPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
    }
    if (-not $NoConsole) {
        switch ($Color.ToLower()) {
            'green'  { Write-Host $Text -ForegroundColor Green }
            'yellow' { Write-Host $Text -ForegroundColor Yellow }
            'red'    { Write-Host $Text -ForegroundColor Red }
            'cyan'   { Write-Host $Text -ForegroundColor Cyan }
            'magenta'{ Write-Host $Text -ForegroundColor Magenta }
            'white'  { Write-Host $Text -ForegroundColor White }
            default  { Write-Host $Text }
        }
    }
}

# Live-Logger: öffnet eine Logdatei in Downloads und (optional) Notepad für schnelle Sicht
function Start-LiveLogger {
    param([switch]$OpenNotepad)
    try {
        $dl = Join-Path $env:USERPROFILE 'Downloads'
    } catch { $dl = $env:TEMP }
    if (-not (Test-Path $dl)) { New-Item -ItemType Directory -Path $dl -Force | Out-Null }
    $global:LiveLogPath = Join-Path $dl 'PcCheck_live_log.txt'
    try { Remove-Item -Path $global:LiveLogPath -Force -ErrorAction SilentlyContinue } catch {}
    "" | Out-File -FilePath $global:LiveLogPath -Encoding UTF8
    if ($OpenNotepad) {
        try { Start-Process -FilePath 'notepad.exe' -ArgumentList $global:LiveLogPath -WindowStyle Normal } catch {}
    }
    Log("Live-Log-Datei: $global:LiveLogPath", 'white')
}

# Liefert globale Pfade zum Scannen wenn keine spezifischen Installationspfade vorhanden sind
function Get-GlobalScanRoots {
    $roots = @()
    $possible = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA, $env:APPDATA, $env:USERPROFILE)
    foreach ($p in $possible) { if ($p -and (Test-Path $p)) { $roots += $p } }
    return $roots | Select-Object -Unique
}

# Kopiert Inhalte des Papierkorbs in Downloads, kategorisiert nach Typen
function Copy-RecycleToDownloads {
    Write-Status "Kopiere Papierkorb-Inhalte in Downloads (kategorisiert)..." 'start'
    try {
        $shell = New-Object -ComObject Shell.Application
        $rb = $shell.Namespace(0xA)
        if (-not $rb) { Log("Papierkorb nicht verfügbar.", 'yellow'); Write-Status "Papierkorb-Kopie übersprungen." 'info'; return }
        $downloads = Join-Path $env:USERPROFILE 'Downloads'
        $base = Join-Path $downloads 'PcCheck_Recycle'
        $categories = @{
            'Games' = @('steam','epic','ubisoft','riot','origin','gog')
            'Installers' = @('.exe','.msi','setup','installer')
            'Images' = @('.jpg','.jpeg','.png','.bmp','.gif','.webp')
            'Documents' = @('.pdf','.doc','.docx','.txt','.rtf','.odt','.xlsx','.xls','.ppt','.pptx')
            'Archives' = @('.zip','.rar','.7z','.tar','.gz')
            'AudioVideo' = @('.mp3','.wav','.ogg','.mp4','.mkv','.avi')
        }
        foreach ($k in $categories.Keys) { $d = Join-Path $base $k ; if (-not (Test-Path $d)) { New-Item -Path $d -ItemType Directory -Force | Out-Null } }
        $other = Join-Path $base 'Other' ; if (-not (Test-Path $other)) { New-Item -Path $other -ItemType Directory -Force | Out-Null }
        $items = $rb.Items()
        if ($items.Count -eq 0) { Log("Papierkorb ist leer. Keine Dateien kopiert.", 'yellow'); Write-Status "Papierkorb-Kopie abgeschlossen." 'done' ; return }
        foreach ($it in $items) {
            $name = $it.Name
            $orig = $rb.GetDetailsOf($it,1)
            $ext = [IO.Path]::GetExtension($name)
            $category = 'Other'
            if ($ext) {
                foreach ($k in $categories.Keys) { if ($categories[$k] -contains $ext.ToLower()) { $category = $k ; break } }
            }
            if ($category -eq 'Other') {
                $lowerName = $name.ToLower()
                foreach ($k in $categories.Keys) {
                    foreach ($term in $categories[$k]) {
                        if ($lowerName -like "*${term}*") { $category = $k ; break }
                    }
                    if ($category -ne 'Other') { break }
                }
            }
            $destFolder = Join-Path $base $category
            try {
                $destNS = $shell.Namespace($destFolder)
                if ($destNS) { $destNS.CopyHere($it) ; Log("Kopiert: $name -> $destFolder") } else { Log("Fehler beim Zugriff auf Zielordner: $destFolder", 'red') }
            } catch { Log(("Fehler beim Kopieren von {0}: {1}" -f $name, $_), 'red') }
        }
        Write-Status "Papierkorb-Kopie abgeschlossen." 'done'
    } catch {
        Log("Fehler beim Kopieren des Papierkorbs: $_", 'red')
        Write-Status "Papierkorb-Kopie fehlgeschlagen." 'error'
    }
}

# Initialisiere Ausgabe-Datei
if ($OutFile -ne "") {
    try {
        if (Test-Path $OutFile) { Remove-Item -Path $OutFile -Force -ErrorAction SilentlyContinue }
        "" | Out-File -FilePath $OutFile -Encoding UTF8
    } catch {
        Write-Warning "Konnte Ausgabedatei nicht vorbereiten: $_"
    }
}

# Banner anzeigen
Show-Banner -Colored
Start-LiveLogger -OpenNotepad

Log("PC Check Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
Log("")

function Section {
    param([string]$Title)
    Log("------------------------------------------------------------------","white")
    Log($Title,"magenta")
    Log("------------------------------------------------------------------","white")
}

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('start','done','info','warn','error')][string]$State = 'info'
    )
    switch ($State) {
        'start' { $prefix='[-]'; $color='green' }
        'done'  { $prefix='[+]'; $color='green' }
        'info'  { $prefix='[ ]'; $color='yellow' }
        'warn'  { $prefix='[!]'; $color='yellow' }
        'error' { $prefix='[-]'; $color='red' }
    }
    $text = "{0} {1}" -f $prefix, $Message
    Log $text $color
}

function Check-ValTracker {
    # Same detection/extraction logic as pc_check.ps1 - return Found/Installs/Accounts
    Write-Status "Suche nach VAL Tracker..." 'start'
    $foundInstalls = @()
    $usernames = @()
    try {
        $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)valtracker|val-tracker|valtr|val.*tracker' }
        foreach ($p in $procs) { if ($p.ExecutablePath) { $foundInstalls += (Split-Path -Parent $p.ExecutablePath) } else { $foundInstalls += $p.Name } }
    } catch { }

    $uninstallRoots = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
    foreach ($root in $uninstallRoots) {
        try {
            $items = Get-ItemProperty -Path ($root + '\*') -ErrorAction SilentlyContinue
            foreach ($it in $items) {
                if ($it.DisplayName -and ((($it.DisplayName -match '(?i)val') -and ($it.DisplayName -match '(?i)track')) -or ($it.DisplayName -match '(?i)valtracker'))) {
                    if ($it.InstallLocation) { $foundInstalls += $it.InstallLocation } elseif ($it.UninstallString) { $foundInstalls += $it.UninstallString } else { $foundInstalls += $it.DisplayName }
                }
            }
        } catch { }
    }

    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA, $env:APPDATA) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
    foreach ($r in $roots) {
        try {
            $dirs = Get-ChildItem -Path $r -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)val.*track' -or $_.Name -match '(?i)valtracker' }
            foreach ($d in $dirs) { $foundInstalls += $d.FullName }
        } catch { }
    }

    $foundInstalls = $foundInstalls | Select-Object -Unique
    if (-not $foundInstalls -or $foundInstalls.Count -eq 0) { Write-Status "VAL Tracker nicht gefunden." 'info'; return @{ Found = $false; Installs = @(); Accounts = @() } }

    foreach ($path in $foundInstalls) {
        if (-not (Test-Path $path)) { continue }
        try {
            $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)account|user|login|profile' }
            foreach ($f in $files) {
                try {
                    $raw = Get-Content -Raw -Path $f.FullName -ErrorAction SilentlyContinue
                    if (-not $raw) { continue }
                    $regexes = @('(?i)"username"\s*:\s*"([^"\\]+)"','(?i)"user"\s*:\s*"([^"\\]+)"','(?i)"displayname"\s*:\s*"([^"\\]+)"','(?i)"login"\s*:\s*"([^"\\]+)"','(?i)(?<=\b)(?:user(?:name)?|login|displayname|account)\b\s*[:=]\s*"?([^"\s,\}]+)')
                    foreach ($rx in $regexes) { foreach ($m in [regex]::Matches($raw,$rx)) { if ($m.Groups.Count -ge 2) { $usernames += $m.Groups[1].Value } } }
                    foreach ($ln in $raw -split "`r?`n") { if ($ln -match '(?i)(user(name)?|login|account|displayname)\s*[:=]\s*(\S+)') { $usernames += $matches[3] } }
                } catch { }
            }
        } catch { }
    }

    $usernames = $usernames | Where-Object { $_ -and $_.Trim().Length -gt 0 } | Select-Object -Unique
    Write-Status "VAL Tracker Prüfung beendet." 'done'
    return @{ Found = $true; Installs = $foundInstalls; Accounts = $usernames }
}

Write-Status "Starte System-Übersicht..." 'start'
Section "System-Übersicht"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $totalMemoryGB = if ($cs.TotalPhysicalMemory) { [math]::Round($cs.TotalPhysicalMemory/1GB,2) } else { "n/a" }

    # Sicheres Parsen der LastBootUpTime (kann leer/ungültig sein)
    $bootTime = $null
    try {
        if ($os.LastBootUpTime) {
            $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
        }
    } catch {
        $bootTime = $null
    }

    Log("Computer: $($env:COMPUTERNAME)")
    Log("Benutzer: $($env:USERNAME)")
    Log("OS: $($os.Caption) (Version $($os.Version)) Build $($os.BuildNumber)")
    if ($bootTime) {
        $uptime = (Get-Date) - $bootTime
        Log("Letzter Neustart: $bootTime")
        Log("Uptime: {0} Tage, {1} Stunden, {2} Minuten" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
    } else {
        Log("Letzter Neustart: n/a")
        Log("Uptime: n/a")
    }

    if ($cpu) { Log("CPU: $($cpu.Name) / Cores: $($cpu.NumberOfCores) / Logical: $($cpu.NumberOfLogicalProcessors)") }
    Log("Physischer RAM: $totalMemoryGB GB")
    Write-Status "System-Übersicht abgeschlossen." 'done'
} catch {
    Log("Fehler beim Auslesen der Systeminformationen: $_")
    Write-Status "System-Übersicht fehlgeschlagen." 'error'
}

Write-Status "Starte Prozessliste (Top 25)..." 'start'
Section "Laufende Prozesse"
try {
    $procCim = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    $procMap = @{}
    foreach ($p in $procCim) { $procMap[$p.ProcessId] = $p }
    $procList = Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
        $p = $_
        $exe = $null
        $cmd = $null
        if ($procMap.ContainsKey($p.Id)) {
            $exe = $procMap[$p.Id].ExecutablePath
            $cmd = $procMap[$p.Id].CommandLine
        }
        [PSCustomObject]@{
            Name = $p.ProcessName
            Id = $p.Id
            CPU = if ($p.CPU) { [math]::Round($p.CPU,2) } else { 0 }
            MemoryMB = if ($p.WorkingSet) { [math]::Round($p.WorkingSet/1MB,2) } else { 0 }
            StartTime = ($p | Select-Object -ExpandProperty StartTime -ErrorAction SilentlyContinue)
            Path = $exe
            CommandLine = $cmd
        }
    } | Sort-Object -Property CPU -Descending

    $top = $procList | Select-Object -First 25
    foreach ($pp in $top) {
        Log("{0,-25} PID:{1,6} CPU:{2,7} Mem(MB):{3,8} Path:{4}" -f $pp.Name, $pp.Id, $pp.CPU, $pp.MemoryMB, ($pp.Path -replace '\\','\\'))
    }
    Write-Status "Prozessliste abgeschlossen." 'done'
} catch {
    Log("Fehler beim Auslesen der Prozesse: $_")
    Write-Status "Prozessliste fehlgeschlagen." 'error'
}

Write-Status "Prüfe kürzlich beendete Prozesse..." 'start'
Section "Kürzlich beendete Prozesse"
$since = (Get-Date).AddDays(-1)
$found = $false
try {
    $events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4689; StartTime=$since} -ErrorAction Stop
    if ($events -and $events.Count -gt 0) {
        $found = $true
        foreach ($e in $events | Select-Object -First 50) {
            Log("Time: $($e.TimeCreated) - EventID: $($e.Id)")
            Log($e.Message)
            Log("")
        }
    }
} catch {
    # Fallback: Sysmon (EventID 5 = Process Terminated)
    try {
        $events = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Sysmon/Operational'; Id=5; StartTime=$since} -ErrorAction Stop
        if ($events -and $events.Count -gt 0) {
            $found = $true
            foreach ($e in $events | Select-Object -First 50) {
                Log("Time: $($e.TimeCreated) - Sysmon EventID 5")
                Log($e.Message)
                Log("")
            }
        }
    } catch {
        # ignore
    }
}
if (-not $found) {
    Log("Keine Informationen zu beendeten Prozessen gefunden. (Event-Logging möglicherweise nicht aktiviert oder fehlende Berechtigungen)")
    Write-Status "Keine Informationen zu beendeten Prozessen gefunden." 'warn'
} else {
    Write-Status "Kürzlich beendete Prozesse verarbeitet." 'done'
}

Write-Status "Prüfe Papierkorb (gelöschte Dateien)..." 'start'
Section "Gelöschte Dateien (Recycle Bin)"
try {
    $shell = New-Object -ComObject Shell.Application
    $rb = $shell.Namespace(0xA)
    if ($rb -ne $null) {
        $items = $rb.Items()
        if ($items.Count -eq 0) {
            Log("Papierkorb ist leer.")
        } else {
            foreach ($it in $items) {
                $name = $it.Name
                $orig = $rb.GetDetailsOf($it,1)
                if (-not $orig) { $orig = $rb.GetDetailsOf($it,2) }
                $date = $rb.GetDetailsOf($it,2)
                $size = $rb.GetDetailsOf($it,3)
                Log("Name: $name")
                Log("Original: $orig")
                if ($date) { Log("Gelöscht am: $date") }
                if ($size) { Log("Größe: $size") }
                Log("")
            }
        }
    } else {
        Log("Papierkorb-Zugriff nicht möglich.")
    }
    # Kopiere Inhalte aus dem Papierkorb in Downloads, kategorisiert
    Copy-RecycleToDownloads
    Write-Status "Papierkorb geprüft." 'done'
} catch {
    Log("Fehler beim Auslesen des Papierkorbs: $_")
    Write-Status "Papierkorb-Prüfung fehlgeschlagen." 'error'
}

Write-Status "Ermittle USB-Geräte und PnP-Informationen..." 'start'
Section "USB-Geräte"
try {
    $usbDrives = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceType -eq 'USB' }
    if ($usbDrives -and $usbDrives.Count -gt 0) {
        foreach ($d in $usbDrives) {
            Log("Model: $($d.Model) DeviceID: $($d.DeviceID)")
            Log("PNPDeviceID: $($d.PNPDeviceID)")
            Log("")
        }
    } else {
        Log("Keine USB-Datenträger erkannt.")
    }

    # Allgemeine USB/PnP-Geräte
    if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) {
        $p = Get-PnpDevice -PresentOnly | Where-Object { ($_.FriendlyName -like '*USB*') -or ($_.Class -eq 'USB') } -ErrorAction SilentlyContinue
        if ($p) {
            foreach ($x in $p) {
                Log("PNP: $($x.InstanceId) - $($x.FriendlyName) - Status: $($x.Status)")
            }
        } else {
            Log("Keine weiteren USB PnP-Geräte gefunden.")
        }
    } else {
        $p = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*USB*' }
        if ($p) {
            foreach ($x in $p) {
                Log("PNP: $($x.DeviceID) - $($x.Name)")
            }
        } else {
            Log("Keine PnP-Informationen für USB gefunden.")
        }
    }
    Write-Status "USB-Geräte geprüft." 'done'
} catch {
    Log("Fehler beim Auslesen der USB-Geräte: $_")
    Write-Status "USB-Geräte-Prüfung fehlgeschlagen." 'error'
}

# Prüfe VAL Tracker (nur Account-Namen anzeigen)
Write-Status "Überprüfe VAL Tracker auf Accounts..." 'start'
$val = Check-ValTracker
if ($val.Found) {
    Section "VAL Tracker (Accounts)"
    if ($val.Accounts -and $val.Accounts.Count -gt 0) {
        foreach ($u in $val.Accounts) { Log("- $u", 'green') }
    } else {
        Log("VAL Tracker ist installiert, aber keine Accounts gefunden.", 'yellow')
    }
} else {
    Log("VAL Tracker nicht installiert.", 'cyan')
}
Write-Status "VAL Tracker Prüfung abgeschlossen." 'done'

Write-Status "Starte allgemeinen PC-Check..." 'start'
Section "Allgemeiner PC-Check"
try {
    Log("Laufwerke:")
    $disks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -in 2,3 }
    foreach ($d in $disks) {
        $free = if ($d.FreeSpace) { [math]::Round($d.FreeSpace/1GB,2) } else { 'n/a' }
        $total = if ($d.Size) { [math]::Round($d.Size/1GB,2) } else { 'n/a' }
        Log("{0} - Label: {1} - Frei: {2}GB / Gesamt: {3}GB" -f $d.DeviceID, ($d.VolumeName -as [string]), $free, $total)
    }

    Log("")
    Log("Netzwerk (IP-Konfiguration):")
    if (Get-Command Get-NetIPConfiguration -ErrorAction SilentlyContinue) {
        Get-NetIPConfiguration | ForEach-Object {
            $ipv4 = ($_.IPv4Address | Select-Object -First 1).IPAddress
            $ipv6 = ($_.IPv6Address | Select-Object -First 1).IPAddress
            Log("Interface: $($_.InterfaceAlias) - IPv4: $ipv4 - IPv6: $ipv6")
        }
    } else {
        Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | ForEach-Object {
            Log("Adapter: $($_.Description) - IP: $($_.IPAddress -join ', ')")
        }
    }

    Log("")
    Log("Listening TCP-Ports (falls verfügbar):")
    try {
        $list = Get-NetTCPConnection -State Listen -ErrorAction Stop | Select-Object LocalAddress, LocalPort, OwningProcess
        foreach ($l in $list | Sort-Object LocalPort | Select-Object -First 50) {
            $proc = $null
            try { $proc = (Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch {}
            Log("$($l.LocalAddress):$($l.LocalPort) - PID $($l.OwningProcess) ($proc)")
        }
    } catch {
        Log("Keine Informationen zu Listening-Ports verfügbar.")
    }

    Log("")
    Log("Nicht laufende Dienste (Beispiel, nur gestoppte):")
    Get-Service | Where-Object { $_.Status -ne 'Running' } | Select-Object -First 20 | ForEach-Object {
        Log("$($_.Name) - Status: $($_.Status)")
    }
    Write-Status "Allgemeiner PC-Check abgeschlossen." 'done'
} catch {
    Log("Fehler beim allgemeinen PC-Check: $_")
    Write-Status "Allgemeiner PC-Check fehlgeschlagen." 'error'
}

Log("")
Log("Fertig. Hinweis: Einige Informationen (Event-Logs, PnP) benötigen Administrator-Rechte.")
if ($OutFile -ne "") { Log("Report gespeichert nach: $OutFile") }
Write-Status "Alle Prüfungen abgeschlossen." 'done'

# Cheat-Risiko Zusammenfassung: scannt gefundene Installationspfade und schätzt Anteil verdächtiger Dateien
function Summarize-CheatRisk {
    param(
        [string[]]$Installs
    )
    Write-Status "Erstelle Cheat-Risiko Zusammenfassung..." 'start'
    try {
        if (-not $Installs -or $Installs.Count -eq 0) {
            Log("Keine Installationspfade vorhanden; Cheat-Zusammenfassung übersprungen.", 'yellow')
            Write-Status "Cheat-Risiko Zusammenfassung übersprungen." 'info'
            return @{ Total = 0; Potential = 0; Percent = 0; Samples = @() }
        }

        $nameRx = '(?i)\b(cheat|cheats|cheater|aimbot|triggerbot|wallhack|esp|injector|inject|loader|cheatengine|trainer|hook|bypass|spoof|untrusted|modmenu|hack|hacks|rage|aim)\b'
        $contentRx = '(?i)\b(aimbot|triggerbot|wallhack|esp|cheatengine|injector|dllinject|anti[-_ ]?cheat|bypass|untrusted|hook|trainer|cheat)\b'

        $totalFiles = 0
        $suspicious = @()

        foreach ($root in $Installs) {
            if (-not $root) { continue }
            try {
                if (-not (Test-Path $root)) { continue }
                $files = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue
                if ($files) {
                    $totalFiles += $files.Count
                    $nameMatches = $files | Where-Object { $_.Name -match $nameRx }
                    if ($nameMatches) { $suspicious += $nameMatches }

                    $candidates = $files | Where-Object { $_.Length -lt 524288 -and -not ($_.Name -match $nameRx) }
                    foreach ($f in $candidates) {
                        try {
                            $raw = Get-Content -Raw -Path $f.FullName -ErrorAction SilentlyContinue -Encoding UTF8
                            if ($raw -and ($raw -match $contentRx)) { $suspicious += $f }
                        } catch { }
                    }
                }
            } catch { }
        }

        $suspiciousUnique = $suspicious | Select-Object -Unique
        $suspiciousCount = $suspiciousUnique.Count
        $percent = 0
        if ($totalFiles -gt 0) { $percent = [math]::Round(($suspiciousCount / $totalFiles) * 100, 2) }

        Section "Cheat-Risiko Zusammenfassung"
        Log("Gesamtdateien gescannt: $totalFiles")
        Log("Mögliche Cheat-Dateien: $suspiciousCount")
        Log("Geschätzter Cheat-Anteil: $percent %")
        if ($suspiciousCount -gt 0) {
            Log("Top verdächtige Dateien (Beispiel):", 'yellow')
            foreach ($f in $suspiciousUnique | Select-Object -First 10) { Log(" - $($f.FullName)", 'yellow') }
        }

        Write-Status "Cheat-Risiko Zusammenfassung abgeschlossen." 'done'
        return @{ Total = $totalFiles; Potential = $suspiciousCount; Percent = $percent; Samples = $suspiciousUnique }
    } catch {
        Write-Status "Cheat-Risiko Zusammenfassung fehlgeschlagen." 'error'
        return @{ Total = 0; Potential = 0; Percent = 0; Samples = @() }
    }
}

# Führe Zusammenfassung aus (verwende Installationspfade aus Check-ValTracker wenn vorhanden)
$insts = @()
try { if ($val -and $val.Installs -and $val.Installs.Count -gt 0) { $insts = $val.Installs } } catch { }
if (-not $insts -or $insts.Count -eq 0) { $insts = Get-GlobalScanRoots }
$cheatSummary = Summarize-CheatRisk -Installs $insts
Log("")
Log("Cheat-Summary: Dateien gescannt: $($cheatSummary.Total) | Mögliche Cheats: $($cheatSummary.Potential) | Anteil: $($cheatSummary.Percent)%", 'cyan')

# Ende
