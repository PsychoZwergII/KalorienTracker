# Flutter SDK Auto-Installation Script

Write-Host "Flutter SDK Installation startet..." -ForegroundColor Cyan

# Config
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip"
$downloadPath = "$env:USERPROFILE\Downloads\flutter_sdk.zip"
$extractPath = "C:\flutter"
$flutterBin = "C:\flutter\bin"

# 1. Download
Write-Host "[1/5] Downloading Flutter SDK (400MB)..." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $flutterUrl -OutFile $downloadPath -UseBasicParsing
Write-Host "Download complete!" -ForegroundColor Green

# 2. Extract
Write-Host "[2/5] Extracting to C:\flutter..." -ForegroundColor Yellow
if (Test-Path $extractPath) {
    Remove-Item -Path $extractPath -Recurse -Force
}
Expand-Archive -Path $downloadPath -DestinationPath "C:\" -Force
Write-Host "Extracted!" -ForegroundColor Green

# 3. Set PATH
Write-Host "[3/5] Setting PATH variable..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$flutterBin", "User")
    Write-Host "PATH updated!" -ForegroundColor Green
}
$env:Path += ";$flutterBin"

# 4. Initialize Flutter
Write-Host "[4/5] Initializing Flutter..." -ForegroundColor Yellow
& "$flutterBin\flutter.bat" --version

# 5. Cleanup
Write-Host "[5/5] Cleanup..." -ForegroundColor Yellow
Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Close this terminal" -ForegroundColor White
Write-Host "  2. Open NEW PowerShell" -ForegroundColor White
Write-Host "  3. Run: flutter doctor" -ForegroundColor White
