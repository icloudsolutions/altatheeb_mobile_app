# Run Flutter in DEBUG on Android over Wi-Fi with verbose console logs.
# Phone and PC must be on the same Wi-Fi. Enable Developer options - Wireless debugging.
#
# Usage:
#   .\scripts\run_android_wifi_debug.ps1
#   .\scripts\run_android_wifi_debug.ps1 -PairIp "192.168.1.50" -PairPort 37123 -PairCode "123456"
#   .\scripts\run_android_wifi_debug.ps1 -ConnectIp "192.168.1.50" -ConnectPort 5555
#
# Set -BackendUrl to your PC LAN IP so the phone can reach the API (not localhost).

param(
    [string] $Adb = "",
    [string] $BackendUrl = "http://167.99.242.212:18080",
    [string] $PairIp = "",
    [int] $PairPort = 0,
    [string] $PairCode = "",
    [string] $ConnectIp = "",
    [int] $ConnectPort = 5555,
    # USB serial (e.g. R58T801YNMB) for `adb tcpip` when using Wi-Fi after USB pairing once.
    [string] $UsbSerial = "",
    # After `adb tcpip 5555`, connect with e.g. 192.168.1.50 — or pass full device id to flutter below.
    [string] $WifiDevice = ""
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

$candidates = @(
    $Adb,
    "G:\logiciel\platform-tools-latest-windows\platform-tools\adb.exe",
    (Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe")
) | Where-Object { $_ -and (Test-Path $_) }
if ($candidates.Count -eq 0) {
    $which = Get-Command adb -ErrorAction SilentlyContinue
    if ($which) { $Adb = $which.Source } else {
        Write-Host "adb not found. Install Android platform-tools or pass -Adb path." -ForegroundColor Red
        exit 1
    }
} else {
    $Adb = $candidates[0]
}

if ($UsbSerial -and $ConnectIp) {
    Write-Host "=== adb -s $UsbSerial tcpip $ConnectPort ===" -ForegroundColor Cyan
    & $Adb -s $UsbSerial tcpip $ConnectPort
    Start-Sleep -Seconds 2
    Write-Host "=== adb connect ${ConnectIp}:${ConnectPort} ===" -ForegroundColor Cyan
    & $Adb connect "${ConnectIp}:${ConnectPort}"
}

Write-Host "=== adb devices (before) ===" -ForegroundColor Cyan
& $Adb devices -l

if ($PairIp -and $PairPort -and $PairCode) {
    Write-Host "=== adb pair ${PairIp}:${PairPort} ===" -ForegroundColor Cyan
    $pairInput = "$PairCode`n"
    $pairInput | & $Adb pair "${PairIp}:${PairPort}"
}

if ($ConnectIp) {
    Write-Host "=== adb connect ${ConnectIp}:${ConnectPort} ===" -ForegroundColor Cyan
    & $Adb connect "${ConnectIp}:${ConnectPort}"
}

Write-Host "=== adb devices (after) ===" -ForegroundColor Cyan
& $Adb devices -l

$fd = flutter devices 2>&1 | Out-String
$hasAndroid = ($fd -match "android|sdk_gphone|samsung|SM-")
if (-not $hasAndroid) {
    Write-Host ""
    Write-Host "No Android device detected by Flutter." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Samsung (Android 11+), Wireless debugging:"
    Write-Host "  1) Settings - Developer options - Wireless debugging - ON"
    Write-Host "  2) Pair device with pairing code - note IP, port, code"
    Write-Host "  3) Run: .\scripts\run_android_wifi_debug.ps1 -PairIp IP -PairPort PORT -PairCode CODE"
    Write-Host "  4) Then use IP address and port from Wireless debugging screen:"
    Write-Host "     .\scripts\run_android_wifi_debug.ps1 -ConnectIp IP -ConnectPort ADB_PORT"
    Write-Host ""
    Write-Host "Alternative (USB once): adb tcpip 5555  then  adb connect PHONE_LAN_IP:5555"
    Write-Host ""
    exit 2
}

$deviceArg = @()
if ($WifiDevice) {
    $deviceArg = @("-d", $WifiDevice)
}

Write-Host "=== flutter run (debug, verbose) BACKEND_BASE_URL=$BackendUrl ===" -ForegroundColor Green
flutter run @deviceArg -v --debug --dart-define=BACKEND_BASE_URL=$BackendUrl
