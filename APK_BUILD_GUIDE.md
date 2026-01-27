# APK Build & Installation Guide

# So bekommst du die App auf dein Handy

## Option 1: Lokaler Build (nachdem Flutter installiert ist)

### Voraussetzungen

1. Flutter SDK installiert (läuft gerade)
2. Android Studio installiert (für Android SDK)
3. Firebase konfiguriert

### Schritte:

#### 1. Android Studio installieren

```powershell
# Via winget
winget install --id Google.AndroidStudio -e

# Oder manuell von:
# https://developer.android.com/studio
```

#### 2. Firebase Setup

```powershell
# Firebase CLI installieren
npm install -g firebase-tools

# Login
firebase login

# FlutterFire CLI
dart pub global activate flutterfire_cli

# Im Projekt-Ordner
cd flutter_app
flutterfire configure --project=dein-firebase-projekt-id
```

#### 3. APK bauen

```powershell
cd flutter_app

# Debug APK (für Tests, schneller)
flutter build apk --debug

# Release APK (für echte Nutzung, optimiert)
flutter build apk --release

# APK findet sich dann hier:
# flutter_app\build\app\outputs\flutter-apk\app-release.apk
```

#### 4. APK auf Handy installieren

**Methode A: USB Kabel**

```powershell
# USB Debugging am Handy aktivieren
# Dann:
flutter install

# Oder manuell:
adb install build\app\outputs\flutter-apk\app-release.apk
```

**Methode B: Datei kopieren**

1. APK-Datei per USB/Cloud/Email auf Handy kopieren
2. "Aus unbekannten Quellen installieren" aktivieren
3. APK-Datei am Handy öffnen → Installieren

---

## Option 2: GitHub Actions (Automatischer Build - EMPFOHLEN!)

### Vorteile:

- ✅ Kein Flutter auf deinem PC nötig
- ✅ Automatisch bei jedem Git Push
- ✅ APK wird automatisch gebaut
- ✅ Download direkt von GitHub

### Setup:

#### 1. GitHub Actions Workflow erstellen

Datei: `.github/workflows/build-apk.yml`

```yaml
name: Build Android APK

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: "zulu"
          java-version: "17"

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.19.0"
          channel: "stable"

      - name: Install dependencies
        run: |
          cd flutter_app
          flutter pub get

      - name: Build APK
        run: |
          cd flutter_app
          flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release
          path: flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

#### 2. Firebase Secrets in GitHub setzen

GitHub Repository → Settings → Secrets → New repository secret

Benötigte Secrets:

- `FIREBASE_OPTIONS` (Inhalt von firebase_options.dart)
- `GOOGLE_SERVICES_JSON` (Inhalt von google-services.json)

#### 3. Push zu GitHub

```powershell
git add .
git commit -m "Add GitHub Actions APK build"
git push
```

#### 4. APK herunterladen

1. Gehe zu GitHub → Actions
2. Wähle neuesten Workflow Run
3. Download APK unter "Artifacts"
4. APK auf Handy installieren

---

## Option 3: Firebase App Distribution (BESTE OPTION!)

### Vorteile:

- ✅ Automatische Updates
- ✅ Beta-Tester einladen
- ✅ Crash Reports
- ✅ Direkter Download-Link fürs Handy

### Setup:

#### 1. Firebase App Distribution aktivieren

```powershell
# APK bauen
cd flutter_app
flutter build apk --release

# Zu Firebase hochladen
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers"
```

#### 2. Am Handy:

1. Firebase App Tester App installieren
2. Mit deinem Google Account anmelden
3. App erscheint automatisch → Installieren

---

## Was du JETZT tun solltest:

### Kurzfristig (heute):

1. ✅ Warte bis Flutter-Installation fertig ist (~5 Min)
2. Installiere Android Studio
3. Konfiguriere Firebase
4. Baue erste APK

### Mittelfristig (morgen):

1. Setup GitHub Actions für automatische Builds
2. Pushe Code zu GitHub
3. Lade APK von GitHub Actions herunter

### Langfristig (Produktion):

1. Firebase App Distribution für Beta-Tester
2. Google Play Store für öffentliche Releases

---

## Schnellstart nach Flutter-Installation:

```powershell
# 1. Android Studio installieren
winget install Google.AndroidStudio -e

# 2. Flutter doctor (zeigt was fehlt)
flutter doctor

# 3. Firebase konfigurieren
cd flutter_app
flutterfire configure

# 4. APK bauen
flutter build apk --release

# 5. APK findet sich hier:
explorer build\app\outputs\flutter-apk\

# 6. app-release.apk auf Handy kopieren & installieren!
```

---

## Checkliste vor dem Build:

- [ ] Flutter installiert (`flutter --version`)
- [ ] Android Studio installiert
- [ ] Android SDK akzeptiert (`flutter doctor --android-licenses`)
- [ ] Firebase Projekt erstellt
- [ ] `google-services.json` heruntergeladen
- [ ] `firebase_options.dart` generiert
- [ ] `flutter pub get` ausgeführt
- [ ] APK gebaut (`flutter build apk --release`)
- [ ] APK auf Handy kopiert
- [ ] "Unbekannte Quellen" aktiviert
- [ ] APK installiert ✅

---

## Troubleshooting:

### "Installation blockiert"

→ Settings → Security → "Install unknown apps" aktivieren

### "App beschädigt"

→ APK neu bauen mit `flutter clean` vorher

### "Firebase Fehler"

→ `google-services.json` richtig platziert?

### "Cloud Functions nicht erreichbar"

→ Cloud Functions müssen deployed sein

---

## Größe der fertigen APK:

- Debug APK: ~50-80 MB
- Release APK: ~20-40 MB (optimiert)

---

Willst du Option 1 (Lokal bauen) oder Option 2 (GitHub Actions) verwenden?
