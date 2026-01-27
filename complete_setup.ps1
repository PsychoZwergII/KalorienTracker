# Komplettes Setup Script
# Nach Flutter Installation ausfuehren

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Flutter App Setup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# 1. Flutter Dependencies
Write-Host ""
Write-Host "[1/4] Installing Flutter dependencies..." -ForegroundColor Yellow
cd flutter_app
flutter pub get

# 2. Node.js pruefen
Write-Host ""
Write-Host "[2/4] Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js not found! Installing..." -ForegroundColor Yellow
    winget install --id OpenJS.NodeJS -e --silent
}

# 3. Firebase CLI installieren
Write-Host ""
Write-Host "[3/4] Installing Firebase CLI..." -ForegroundColor Yellow
npm install -g firebase-tools

# 4. Firebase Functions Dependencies
Write-Host ""
Write-Host "[4/4] Installing Firebase Functions dependencies..." -ForegroundColor Yellow
cd ..\firebase\functions
npm install

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. firebase login" -ForegroundColor White
Write-Host "2. flutterfire configure" -ForegroundColor White
Write-Host "3. cd flutter_app" -ForegroundColor White
Write-Host "4. flutter run -d chrome" -ForegroundColor White
