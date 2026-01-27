# GitHub Setup Script
# Pusht dein Projekt zu GitHub und aktiviert automatische APK Builds

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "GitHub Repository Setup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check Git
Write-Host "[1/5] Checking Git installation..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git not found! Installing..." -ForegroundColor Yellow
    winget install --id Git.Git -e
    Write-Host "Please restart terminal after Git installation!" -ForegroundColor Red
    exit 1
}

# Initialize Git
Write-Host ""
Write-Host "[2/5] Initializing Git repository..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    git init
    Write-Host "Git repository initialized!" -ForegroundColor Green
} else {
    Write-Host "Git repository already exists!" -ForegroundColor Green
}

# Create .gitignore (if not exists)
Write-Host ""
Write-Host "[3/5] Checking .gitignore..." -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    Write-Host ".gitignore already exists!" -ForegroundColor Green
} else {
    Write-Host ".gitignore not found! Please make sure it exists!" -ForegroundColor Red
}

# Add all files
Write-Host ""
Write-Host "[4/5] Adding files to Git..." -ForegroundColor Yellow
git add .
Write-Host "Files added!" -ForegroundColor Green

# Commit
Write-Host ""
Write-Host "[5/5] Creating initial commit..." -ForegroundColor Yellow
git commit -m "Initial commit: KalorienTracker Flutter App"
Write-Host "Commit created!" -ForegroundColor Green

# Instructions
Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "Git Setup Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Create GitHub Repository:" -ForegroundColor Yellow
Write-Host "   → Go to: https://github.com/new" -ForegroundColor White
Write-Host "   → Name: KalorienTracker" -ForegroundColor White
Write-Host "   → Public or Private (your choice)" -ForegroundColor White
Write-Host "   → DO NOT add README, .gitignore, or license" -ForegroundColor White
Write-Host "   → Click 'Create repository'" -ForegroundColor White
Write-Host ""
Write-Host "2. Connect to GitHub:" -ForegroundColor Yellow
Write-Host "   Run these commands (replace YOUR_USERNAME):" -ForegroundColor White
Write-Host ""
Write-Host "   git remote add origin https://github.com/YOUR_USERNAME/KalorienTracker.git" -ForegroundColor Cyan
Write-Host "   git branch -M main" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Add Firebase Secrets to GitHub:" -ForegroundColor Yellow
Write-Host "   → Go to: https://github.com/YOUR_USERNAME/KalorienTracker/settings/secrets/actions" -ForegroundColor White
Write-Host "   → Click 'New repository secret'" -ForegroundColor White
Write-Host "   → Name: GOOGLE_SERVICES_JSON" -ForegroundColor White
Write-Host "   → Value: (paste content of google-services.json)" -ForegroundColor White
Write-Host "   → Click 'Add secret'" -ForegroundColor White
Write-Host ""
Write-Host "4. Trigger APK Build:" -ForegroundColor Yellow
Write-Host "   → Go to: https://github.com/YOUR_USERNAME/KalorienTracker/actions" -ForegroundColor White
Write-Host "   → Click 'Build Android APK' workflow" -ForegroundColor White
Write-Host "   → Click 'Run workflow' → 'Run workflow'" -ForegroundColor White
Write-Host "   → Wait 5-10 minutes..." -ForegroundColor White
Write-Host ""
Write-Host "5. Download APK:" -ForegroundColor Yellow
Write-Host "   → Click on the completed workflow run" -ForegroundColor White
Write-Host "   → Scroll down to 'Artifacts'" -ForegroundColor White
Write-Host "   → Download 'kalorientracker-app.zip'" -ForegroundColor White
Write-Host "   → Extract app-release.apk" -ForegroundColor White
Write-Host "   → Copy to phone and install!" -ForegroundColor White
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
