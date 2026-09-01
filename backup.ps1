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
    Write-Host "-> Warnung: 'blocked_apps.txt' nicht gefunden! Überspringe diese Liste." -ForegroundColor DarkYellow
}


Write-Host "3. Scanne nach Windows-App-Bloatware und entferne sie..." -ForegroundColor Cyan

$bloatApps = @(
    "Microsoft.3DBuilder",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.NetworkSpeedTest",
    "Microsoft.News",
    "Microsoft.Office.OneNote",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCamera",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

foreach ($app in $bloatApps) {
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app} | Remove-ProvisionedAppxPackage -Online -ErrorAction SilentlyContinue
}
Write-Host "-> Windows-Bloatware-Apps entfernt." -ForegroundColor Green


Write-Host "4. Erstelle komprimiertes WIM-Image von C: auf dem Ventoy-Stick..." -ForegroundColor Cyan

# WICHTIG: Passe D:\ an den echten Laufwerksbuchstaben deines Ventoy-Sticks an!
$usbBackupPath = "D:\windows_backup.wim"

dism /Capture-Image /ImageFile:$usbBackupPath /CaptureDir:C:\ /Name:"Windows abgespeckt Backup" /Compress:max /EA

Write-Host "Fertig! Das Backup liegt jetzt sicher auf deinem Ventoy-Stick." -ForegroundColor Green
Pause
