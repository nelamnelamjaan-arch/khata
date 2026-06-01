# Opens in YOUR desktop — browser login works here
$env:Path = "$env:APPDATA\npm;C:\Users\AL FATEH\flutter\bin;C:\pub-cache\bin;" + $env:Path
$env:PUB_CACHE = "C:\pub-cache"
Set-Location "C:\Users\AL FATEH\Desktop\khaaty"

Write-Host ""
Write-Host "=== Firebase Setup ===" -ForegroundColor Cyan
Write-Host "Step 1: Browser khulega — Google se login karein" -ForegroundColor Yellow
Write-Host ""

firebase login

if ($LASTEXITCODE -ne 0) {
    Write-Host "Login fail. Dobara try karein." -ForegroundColor Red
    Read-Host "Enter dabao band karne ke liye"
    exit 1
}

Write-Host ""
Write-Host "Step 2: flutterfire configure..." -ForegroundColor Yellow
dart pub global activate flutterfire_cli
flutterfire configure --project=khata-manager-ccf3a --platforms=web --yes --overwrite-firebase-options

Write-Host ""
Write-Host "Step 3: Firestore rules deploy..." -ForegroundColor Yellow
firebase deploy --only firestore:rules --project=khata-manager-ccf3a

Write-Host ""
Write-Host "=== DONE! ===" -ForegroundColor Green
Write-Host "Ab Cursor mein app restart karein: flutter run -d edge --web-port=7360" -ForegroundColor Green
Write-Host ""
Read-Host "Enter dabao band karne ke liye"
