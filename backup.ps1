# Als Administrator ausführen!
Set-Location $PSScriptRoot

Write-Host "1. Starte grundlegende Bereinigung..." -ForegroundColor Cyan

# Downloads-Ordner leeren
$downloadsPath = "$env:USERPROFILE\Downloads"
if (Test-Path $downloadsPath) {
    Remove-Item "$downloadsPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "-> Downloads-Ordner geleert." -ForegroundColor Green
}

# Papierkorb leeren
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "-> Papierkorb geleert." -ForegroundColor Green

# Temporäre Dateien löschen
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "-> Temp-Ordner bereinigt." -ForegroundColor Green


Write-Host "2. Lese Programmliste aus und deinstalliere Drittanbieter-Bloatware..." -ForegroundColor Cyan
$listPath = ".\blocked_apps.txt"

if (Test-Path $listPath) {
    $unwantedApps = Get-Content $listPath | Where-Object { $_ -and -not $_.StartsWith("#") }
    $installedProducts = Get-WmiObject -Class Win32_Product | Select-Object Name, IdentifyingNumber

    foreach ($app in $unwantedApps) {
        foreach ($product in $installedProducts) {
            if ($product.Name -like "*$app*") {
                Write-Host "-> Gefunden und wird deinstalliert: $($product.Name)" -ForegroundColor Yellow
                try {
                    $product.Uninstall() | Out-Null
                } catch {
                    Write-Host "   Konnte $($product.Name) nicht automatisch deinstallieren." -ForegroundColor DarkYellow
                }
            }
        }
    }
} else {
    Write-Host "-> Info: 'blocked_apps.txt' nicht gefunden (optional). Überspringe diese Liste." -ForegroundColor DarkYellow
}


Write-Host "3. Scanne nach Windows-App-Bloatware und entferne sie..." -ForegroundColor Cyan

$bloatApps = @(
    "Microsoft.3DBuilder", "Microsoft.BingWeather", "Microsoft.GetHelp", "Microsoft.Getstarted",
    "Microsoft.Messaging", "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection", "Microsoft.NetworkSpeedTest", "Microsoft.News",
    "Microsoft.Office.OneNote", "Microsoft.People", "Microsoft.Print3D", "Microsoft.SkypeApp",
    "Microsoft.Wallet", "Microsoft.WindowsAlarms", "Microsoft.WindowsCamera", "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps", "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI", "Microsoft.XboxApp", "Microsoft.XboxGameOverlay", "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay", "Microsoft.YourPhone",
    "Microsoft.ZuneMusic", "Microsoft.ZuneVideo"
)

foreach ($app in $bloatApps) {
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app} | Remove-ProvisionedAppxPackage -Online -ErrorAction SilentlyContinue
}
Write-Host "-> Windows-Bloatware-Apps entfernt." -ForegroundColor Green


Write-Host "3b. Bereinige Windows-Komponentenspeicher..." -ForegroundColor Cyan
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase


Write-Host "4. Erstelle komprimiertes WIM-Image von C: auf dem Desktop..." -ForegroundColor Cyan

$desktopPath = [Environment]::GetFolderPath("Desktop")
$backupFilePath = Join-Path $desktopPath "windows_backup.wim"

# Falls eine alte Datei auf dem Desktop liegt, vorab löschen
if (Test-Path $backupFilePath) {
    Remove-Item $backupFilePath -Force
    Write-Host "-> Alte Backup-Datei auf dem Desktop entfernt." -ForegroundColor Yellow
}

dism /Capture-Image /ImageFile:$backupFilePath /CaptureDir:C:\ /Name:"Windows abgespeckt Backup" /Compress:max /EA

if ($LASTEXITCODE -eq 0) {
    Write-Host "-> ERFOLG: Das Backup wurde fehlerfrei auf deinem Desktop erstellt!" -ForegroundColor Green
    Write-Host "Die Datei 'windows_backup.wim' ist da. Es wurde absolut nichts gelöscht." -ForegroundColor Cyan
} else {
    Write-Host "-> FEHLER beim Erstellen des Backups!" -ForegroundColor Red
}

Pause
