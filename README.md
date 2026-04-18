# PC Check Tool

Dieses PowerShell-Skript sammelt Systeminformationen, listet laufende Prozesse, kürzlich beendete Prozesse (sofern geloggt), gelöschte Dateien aus dem Papierkorb und angeschlossene USB-Geräte.

## Benutzung

- Öffne PowerShell im Ordner des Projekts.
- (Optional) Temporär Skriptausführung erlauben:

  `Set-ExecutionPolicy Bypass -Scope Process -Force`

- Skript ausführen (Konsole):

  `.\pc-check\pc_check.ps1`

- Skript ausführen und Ergebnis in Datei speichern:

  `.\pc-check\pc_check.ps1 -OutFile .\pc-check\pc_check-report.txt`

## Hinweise

- Für das Auslesen von Event-Logs (Security 4689) sind Administratorrechte erforderlich.
- Der Papierkorb zeigt nur Dateien, die noch im Recycle Bin liegen.
- Wenn Sysmon installiert ist, werden Prozess-Beendigungen aus Sysmon verwendet.

Bei Fragen oder Erweiterungswünschen gerne Bescheid geben.

## Remote-Ausführung / Verteilung

Du kannst das Tool jetzt einfach auf entfernten Rechnern ausführen und die Reports lokal sammeln. Dazu wurde `pc_check_runner.ps1` hinzugefügt.

- Voraussetzungen:
  - PowerShell-Remoting (WinRM) auf den Zielrechnern aktiviert (`Enable-PSRemoting` auf Ziel-Gerät)
  - Benutzerkonto mit Administrator-Rechten auf Zielgerät
  - Netzwerkzugriff / Firewall-Regeln erlaubt PowerShell-Remoting

- Beispiele:

  - Lokal ausführen (auf dem aktuellen PC):

    `.\pc_check\pc_check_runner.ps1`

  - Entfernte Rechner per Remoting prüfen und Reports herunterladen:

    `.\pc_check\pc_check_runner.ps1 -Targets pc1,pc2 -Credential (Get-Credential) -OutDir .\pc-check\reports`

  Dabei werden temporär `pc_check.ps1` und der Report im Temp-Ordner des Zielrechners erstellt, ausgeführt und der Report anschließend in den lokalen `-OutDir` kopiert. Temporäre Dateien werden danach bereinigt.

- Wichtiger Hinweis: Führe Remote-Checks nur auf Rechnern aus, für die du berechtigt bist. Das Skript setzt Admin-Berechtigungen und Remoting voraus.

## Packaging für Verteilung

Du kannst das gesamte Tool in ein ZIP-Paket packen, um es z.B. auf einem USB-Stick zu verteilen oder an andere Admins weiterzugeben.

- Paket erstellen (lokal):

  `.\pc-check\package.ps1`

- Das Skript erzeugt `dist\pc-check.zip` im Projektordner. Kopiere das ZIP auf den Zielrechner, entpacke und führe `pc_check_runner.ps1` oder direkt `pc_check.ps1` aus.

Beispiel (auf Zielrechner lokal):

  `powershell -ExecutionPolicy Bypass -File .\pc-check\pc_check.ps1 -OutFile .\pc-check-report.txt`

## Auf GitHub veröffentlichen (einfacher one-liner)

1) Erstelle ein neues Repository auf GitHub mit dem Namen `pc-check` (oder einem anderen Namen deiner Wahl).

2) Alternativ kannst du das Repo mit der `gh` CLI erstellen und pushen:

  ```powershell
  cd .\pc-check
  gh repo create <GITHUB_USER>/pc-check --public --source=. --remote=origin --push
  ```

  Oder manuell (HTTPS):

  ```powershell
  cd .\pc-check
  git init
  git branch -M main
  git remote add origin https://github.com/<GITHUB_USER>/pc-check.git
  git add .
  git commit -m "Initial commit: pc-check tool"
  git push -u origin main
  ```

3) Nachdem das Repo gepusht ist, kannst du das Skript direkt per Raw-GitHub-URL ausführen. Beispiel-One-Liner:

  ```powershell
  iex (irm 'https://raw.githubusercontent.com/<GITHUB_USER>/pc-check/main/PcCheck.ps1')
  ```

  - Ersetze `<GITHUB_USER>` durch deinen GitHub-Benutzernamen.
  - `PcCheck.ps1` ist die Single-File-Version, die direkt ausgeführt werden kann.

4) Optional: Parameter/Reportdatei lokal setzen und ausführen:

  ```powershell
  $env:PC_CHECK_OUTFILE = 'C:\temp\pccheck-report.txt'
  iex (irm 'https://raw.githubusercontent.com/<GITHUB_USER>/pc-check/main/PcCheck.ps1')
  ```

Hinweis: Führe Remote-Checks nur auf Rechnern aus, für die du berechtigt bist. Remote-Ausführung (PowerShell-Remoting) benötigt Admin-Rechte und entsprechende Netzwerk-/Firewall-Regeln.
