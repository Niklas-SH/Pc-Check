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
 ██▓███   ▄████▄      ▄████▄   ██░ ██ ▓█████ ▄████▄  ▀██ ▄█▀▓█████ ██▀███  
▓██░  ██ ▒██▀ ▀█     ▒██▀ ▀█ ▒▓██░ ██ ▓█   ▀▒██▀ ▀█   ██▄█▒ ▓█   ▀▓██ ▒ ██▒
▓██░ ██▓▒▒▓█    ▄    ▒▓█    ▄░▒██▀▀██ ▒███  ▒▓█    ▄ ▓███▄░ ▒███  ▓██ ░▄█ ▒
▒██▄█▓▒ ▒▒▓▓▄ ▄██    ▒▓▓▄ ▄██ ░▓█ ░██ ▒▓█  ▄▒▓▓▄ ▄██ ▓██ █▄ ▒▓█  ▄▒██▀▀█▄  
▒██▒ ░  ░▒ ▓███▀     ▒ ▓███▀  ░▓█▒░██▓░▒████▒ ▓███▀  ▒██▒ █▄░▒████░██▓ ▒██▒
▒▓▒░ ░  ░░ ░▒ ▒      ░ ░▒ ▒    ▒ ░░▒░▒░░ ▒░ ░ ░▒ ▒   ▒ ▒▒ ▓▒░░ ▒░ ░ ▒▓ ░▒▓░
░▒ ░       ░  ▒        ░  ▒    ▒ ░▒░ ░ ░ ░    ░  ▒   ░ ░▒ ▒░ ░ ░    ░▒ ░ ▒░
░░       ░           ░         ░  ░░ ░   ░  ░        ░ ░░ ░    ░     ░   ░ 
         ░ ░         ░ ░       ░  ░  ░   ░  ░ ░      ░  ░      ░     ░     
'@
        $bannerLines = $banner -split "`n"
    }

    # Stelle Console-Ausgabe-Encoding auf UTF8, falls möglich
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

    foreach ($l in $bannerLines) {
        if ($Colored) { Write-Host $l -ForegroundColor Cyan } else { Write-Host $l }
        if ($OutFile -ne "") { $l | Out-File -FilePath $OutFile -Append -Encoding UTF8 }
    }
    Write-Host ""
}

function Log {
    param([string]$Text)
    if ($null -eq $Text) { $Text = "" }
    if ($OutFile -ne "") {
        $Text | Out-File -FilePath $OutFile -Append -Encoding UTF8
    }
    Write-Output $Text
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

Log("PC Check Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
Log("")

function Section {
    param([string]$Title)
    Log("------------------------------------------------------------------")
    Log($Title)
    Log("------------------------------------------------------------------")
}

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
} catch {
    Log("Fehler beim Auslesen der Systeminformationen: $_")
}

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
} catch {
    Log("Fehler beim Auslesen der Prozesse: $_")
}

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
}

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
} catch {
    Log("Fehler beim Auslesen des Papierkorbs: $_")
}

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
} catch {
    Log("Fehler beim Auslesen der USB-Geräte: $_")
}

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
} catch {
    Log("Fehler beim allgemeinen PC-Check: $_")
}

Log("")
Log("Fertig. Hinweis: Einige Informationen (Event-Logs, PnP) benötigen Administrator-Rechte.")
if ($OutFile -ne "") { Log("Report gespeichert nach: $OutFile") }

# Ende
