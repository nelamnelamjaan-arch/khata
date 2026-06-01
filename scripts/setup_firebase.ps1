# Firebase setup — run in PowerShell (NOT inside Cursor agent)
# Step 1 opens browser for Google login — must be done by you.

$ErrorActionPreference = "Stop"

$env:Path = "$env:APPDATA\npm;C:\Users\AL FATEH\flutter\bin;C:\pub-cache\bin;" + $env:Path
$env:PUB_CACHE = "C:\pub-cache"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host ""
Write-Host "=== Smart Khata Manager — Firebase Setup ===" -ForegroundColor Cyan
Write-Host "Project: khata-manager-ccf3a" -ForegroundColor Cyan
Write-Host ""

# ── 1. Firebase login ───────────────────────────────────────────────────────
Write-Host "[1/3] Firebase login (browser will open)..." -ForegroundColor Yellow
firebase login:list
$loginList = firebase login:list 2>&1 | Out-String
if ($loginList -match "No authorized accounts") {
    firebase login
} else {
    Write-Host "Already logged in." -ForegroundColor Green
}

# ── 2. FlutterFire CLI ──────────────────────────────────────────────────────
Write-Host "[2/3] FlutterFire CLI..." -ForegroundColor Yellow
dart pub global activate flutterfire_cli

# ── 3. Generate firebase_options.dart ───────────────────────────────────────
Write-Host "[3/3] flutterfire configure..." -ForegroundColor Yellow
flutterfire configure `
    --project=khata-manager-ccf3a `
    --platforms=web `
    --yes `
    --overwrite-firebase-options

Write-Host ""
Write-Host "Deploying Firestore rules..." -ForegroundColor Yellow
firebase deploy --only firestore:rules --project=khata-manager-ccf3a

Write-Host ""
Write-Host "Done! firebase_options.dart updated." -ForegroundColor Green
Write-Host "Restart app: flutter run -d edge --web-port=7360" -ForegroundColor Green
Write-Host ""
