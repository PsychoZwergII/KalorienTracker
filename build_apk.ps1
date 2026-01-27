# Quick APK Build Script
# Baut APK sobald Flutter installiert ist

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Android APK Build" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Check Flutter
Write-Host ""
Write-Host "[1/6] Checking Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "Flutter found!" -ForegroundColor Green
} catch {
    Write-Host "Flutter not found! Run install_flutter.ps1 first!" -ForegroundColor Red
    exit 1
}

# Check Android Studio
Write-Host ""
Write-Host "[2/6] Checking Android Studio..." -ForegroundColor Yellow
if (-not (Test-Path "$env:LOCALAPPDATA\Android\Sdk")) {
    Write-Host "Android Studio not found! Installing..." -ForegroundColor Yellow
    winget install Google.AndroidStudio -e
    Write-Host "Please restart after Android Studio installation!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Android SDK found!" -ForegroundColor Green
}

# Accept Android licenses
Write-Host ""
Write-Host "[3/6] Accepting Android licenses..." -ForegroundColor Yellow
flutter doctor --android-licenses

# Get dependencies
Write-Host ""
Write-Host "[4/6] Getting Flutter dependencies..." -ForegroundColor Yellow
cd flutter_app
flutter pub get

# Clean previous builds
Write-Host ""
Write-Host "[5/6] Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Build APK
Write-Host ""
Write-Host "[6/6] Building Release APK..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes..." -ForegroundColor Gray
flutter build apk --release

# Show result
Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "APK Build Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "APK Location:" -ForegroundColor Cyan
Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
Write-Host ""
Write-Host "APK Size:" -ForegroundColor Cyan
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $size = (Get-Item $apkPath).Length / 1MB
    Write-Host "  $([math]::Round($size, 2)) MB" -ForegroundColor White
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Copy APK to your phone (USB/Cloud/Email)" -ForegroundColor White
Write-Host "  2. Enable 'Install from unknown sources' on phone" -ForegroundColor White
Write-Host "  3. Tap APK file to install" -ForegroundColor White
Write-Host "  4. Open app and enjoy!" -ForegroundColor White
Write-Host ""

# Open folder
explorer build\app\outputs\flutter-apk\
