<#
gh_publish.ps1 - Automatisiert: GitHub-Repo erzeugen und lokales Projekt pushen

Usage (interaktiv):
  .\gh_publish.ps1

Usage (non-interactive):
  .\gh_publish.ps1 -RepoName pc-check -GitHubUser <USER> -Private:$false

Hinweis: Das Skript benötigt `git` und `gh` (GitHub CLI). Wenn `gh` fehlt, versucht das Skript, es mit einem Paketmanager zu installieren (winget/choco/scoop). Falls keiner verfügbar ist, bekommst du eine Anleitung zum manuellen Download.
#>

param(
    [string]$RepoName = "",
    [string]$GitHubUser = "",
    [switch]$Private,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Require-Command {
    param($name)
    return (Get-Command $name -ErrorAction SilentlyContinue) -ne $null
}

if (-not (Require-Command git)) {
    Write-Error "Git ist nicht installiert. Bitte installiere Git (https://git-scm.com/) oder via winget: `winget install --id Git.Git -e`"
    exit 1
}

# Versuche gh zu installieren wenn nicht vorhanden
if (-not (Require-Command gh)) {
    Write-Host "GitHub CLI (gh) wurde nicht gefunden. Versuche automatische Installation..."
    if (Require-Command winget) {
        Write-Host "winget gefunden -> gh wird installiert (kann UAC erfordern)..."
        winget install --id GitHub.cli -e --source winget
    } elseif (Require-Command choco) {
        Write-Host "Chocolatey gefunden -> gh wird installiert (erfordert ggf. Admin)..."
        choco install gh -y
    } elseif (Require-Command scoop) {
        Write-Host "Scoop gefunden -> gh wird installiert..."
        scoop install gh
    } else {
        Write-Host "Kein Paketmanager gefunden. Bitte lade gh manuell herunter:";
        Write-Host "  https://github.com/cli/cli/releases/latest"
        Read-Host "Drücke Enter, nachdem du gh installiert hast (oder Abbrechen mit STRG+C)"
    }

    Start-Sleep -Seconds 2
    if (-not (Require-Command gh)) {
        Write-Warning "gh ist nach dem Installationsversuch nicht verfügbar. Beende.">
        exit 1
    }
}

# Prüfe Authentifizierung
$authOk = $false
try {
    gh auth status > $null 2>&1
    $authOk = $true
} catch {
    $authOk = $false
}
if (-not $authOk) {
    Write-Host "Bitte melde dich mit 'gh auth login' an. Falls du ein Token verwenden willst, wähle die entsprechende Option."
    gh auth login
}

# Bestimme Repo-Name
if (-not $RepoName -or $RepoName -eq "") {
    $RepoName = Split-Path -Leaf (Get-Location)
}
$fullName = if ($GitHubUser -and $GitHubUser -ne "") { "$GitHubUser/$RepoName" } else { $RepoName }

# Initialisiere lokales Repo falls nötig
if (-not (Test-Path .git)) {
    Write-Host "Initialisiere lokales Git-Repository..."
    git init
    git add -A
    try { git commit -m "Initial commit: pc-check" -q } catch { Write-Host "Commit fehlgeschlagen (evtl. keine Änderungen). Fortfahren..." }
}

$vis = if ($Private) { '--private' } else { '--public' }

try {
    Write-Host "Erstelle Repository auf GitHub und pushe (gh repo create $fullName $vis)"
    gh repo create $fullName $vis --source=. --remote=origin --push --confirm
    Write-Host "Fertig: Repository angelegt und gepusht."
} catch {
    Write-Warning "Fehler beim Erstellen/Pushing: $_"
    Write-Host "Du kannst folgenden Befehl manuell ausführen (nach Anmeldung):"
    Write-Host "gh repo create $fullName $vis --source=. --remote=origin --push --confirm"
}
