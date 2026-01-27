# Cleanup Script für KalorienTracker Projekt
# Führe dieses Script aus um alte Dateien zu löschen

# Windows PowerShell
# Copy & Paste in PowerShell (Run as Administrator nicht nötig)

# Navigiere zum Projektverzeichnis
Set-Location "c:\Users\Leon\OneDrive - ipso! Bildung\Dokumente\KalorienTracker"

# Alte Dokumentation löschen
Write-Host "Lösche alte Dokumentationsdateien..." -ForegroundColor Yellow
Remove-Item API_KEY_SETUP.md -Force -ErrorAction SilentlyContinue
Remove-Item COMPLETION_CHECKLIST.md -Force -ErrorAction SilentlyContinue
Remove-Item FILE_INDEX.md -Force -ErrorAction SilentlyContinue
Remove-Item FILE_STRUCTURE.md -Force -ErrorAction SilentlyContinue
Remove-Item IMPLEMENTATION_SUMMARY.md -Force -ErrorAction SilentlyContinue
Remove-Item IMPLEMENTATION_COMPLETE.md -Force -ErrorAction SilentlyContinue
Remove-Item ARCHITECTURE.md -Force -ErrorAction SilentlyContinue
Remove-Item QUICKSTART.md -Force -ErrorAction SilentlyContinue
Remove-Item QUICK_START.txt -Force -ErrorAction SilentlyContinue
Remove-Item EMAIL_AUTH_UPDATE.md -Force -ErrorAction SilentlyContinue
Write-Host "✅ Alte Dokumentation gelöscht" -ForegroundColor Green

# Alte Android App löschen (optional)
# Uncomment zum Ausführen
# Write-Host "Lösche alte Android App..." -ForegroundColor Yellow
# Remove-Item -Recurse -Force app -ErrorAction SilentlyContinue
# Remove-Item build.gradle -Force -ErrorAction SilentlyContinue
# Remove-Item gradle.properties -Force -ErrorAction SilentlyContinue
# Remove-Item settings.gradle -Force -ErrorAction SilentlyContinue
# Remove-Item local.properties -Force -ErrorAction SilentlyContinue
# Write-Host "✅ Alte Android App gelöscht" -ForegroundColor Green

# Zeige neue Projektstruktur
Write-Host "`n📂 Neue Projektstruktur:" -ForegroundColor Cyan
Get-ChildItem -Path . -Depth 1 | Select-Object Name, @{Name="Type"; Expression={if ($_.PSIsContainer) {"📁 Ordner"} else {"📄 Datei"}}} | Format-Table

Write-Host "`n✅ Cleanup abgeschlossen!" -ForegroundColor Green
Write-Host "👉 Nächste Schritte: Lies START_HERE.md" -ForegroundColor Blue
