# Als Administrator ausführen!
# Stellt sicher, dass das Skript im selben Ordner ausgeführt wird wie die Textdatei
Set-Location $PSScriptRoot

Write-Host "1. Starte Bereinigung..." -ForegroundColor Cyan

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

Write-Host "2. Lese Programmliste und deinstalliere Bloatware..." -ForegroundColor Cyan

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
    Write-Host "-> Warnung: 'blocked_apps.txt' nicht gefunden! Überspringe Deinstallation." -ForegroundColor DarkYellow
}

Write-Host "3. Erstelle komprimiertes WIM-Image von C: auf dem Ventoy-Stick..." -ForegroundColor Cyan

# WICHTIG: Passe D:\ an den echten Laufwerksbuchstaben deines Ventoy-Sticks an!
$usbBackupPath = "D:\windows_backup.wim"

# DISM packt das System maximal komprimiert auf den Stick
dism /Capture-Image /ImageFile:$usbBackupPath /CaptureDir:C:\ /Name:"Windows abgespeckt Backup" /Compress:max /EA

Write-Host "Fertig! Das Backup liegt jetzt auf deinem Ventoy-Stick." -ForegroundColor Green
Pause
