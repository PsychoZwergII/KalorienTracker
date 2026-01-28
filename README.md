# 🥗 KalorienTracker

**AI-powered Multi-User Calorie Tracker für Android & iOS - Komplett kostenlos ($0/Monat)**

Analysiere Essen per Foto mit Google Gemini AI, scanne Barcodes, tracke Nährwerte in Echtzeit. Multi-User Support mit Google Sign-In oder Email/Passwort.

---

## 📋 Inhaltsverzeichnis

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Entwickler Setup](#-entwickler-setup)
- [APK Build & Installation](#-apk-build--installation)
- [GitHub Actions Setup](#-github-actions-setup)
- [Projektstruktur](#-projektstruktur)
- [API Dokumentation](#-api-dokumentation)
- [Deployment](#-deployment)
- [Kosten & Skalierung](#-kosten--skalierung)
- [Troubleshooting](#-troubleshooting)

---

## ✨ Features

### Hauptfunktionen
- 🤖 **AI Bildanalyse** - Foto → Gemini 1.5 Flash → Automatische Nährwert-Extraktion
- 📊 **Barcode Scanner** - EAN/UPC Codes scannen für Instant-Produktdaten
- 📱 **Cross-Platform** - Android & iOS aus einer Flutter-Codebase
- 👥 **Multi-User Support** - Jeder Nutzer hat eigene Daten
- 🔐 **Dual Authentication** - Google Sign-In oder Email/Passwort
- ☁️ **Cloud Sync** - Firestore-backed, sync über alle Geräte
- ⭐ **Favoriten System** - Häufig gegessene Lebensmittel speichern
- 📈 **Echtzeit Dashboard** - Live-Update der Tagesziele
- 💰 **Free Forever** - $0/Monat durch Free-Tier APIs
- 🔒 **Privacy First** - Kein Tracking, keine Ads, kein Datenverkauf

### Technische Features
- On-Device Barcode-Scanning (ML Kit)
- Server-Side AI Processing (sicher, keine API-Keys im Client)
- Firestore Security Rules (User-Data Isolation)
- Optimierte Icon Tree-Shaking (99.8% Size Reduction)
- Firebase Cloud Functions Backend

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.19+** - Cross-platform UI framework
- **Dart 3.0+** - Programming language
- **Provider/Riverpod** - State Management

### Backend
- **Firebase Cloud Functions** (Node.js 20)
- **Firebase Authentication** (Google + Email)
- **Cloud Firestore** - NoSQL Database
- **Firebase Storage** - File/Image Storage

### AI & ML
- **Google Gemini 1.5 Flash** - Food image analysis
- **Google ML Kit** - On-device barcode scanning
- **OpenFoodFacts API** - Product database

### Build & CI/CD
- **GitHub Actions** - Automated APK builds
- **Gradle 8.1** - Android build system
- **Kotlin 2.1.0** - Android runtime

---

## 🚀 Quick Start

### Option 1: Automatischer APK Build (Empfohlen, kein Flutter nötig!)

1. **Fork/Clone Repo**
   ```bash
   git clone https://github.com/YOUR_USERNAME/KalorienTracker.git
   cd KalorienTracker
   ```

2. **Firebase Setup** (5 min)
   - Erstelle Firebase Projekt: https://console.firebase.google.com
   - Aktiviere: Firestore, Authentication (Google + Email)
   - Registriere Android App mit Package Name: `com.KalorienTracker`
   - Download `google-services.json`

3. **GitHub Secret einrichten**
   - GitHub Repo → Settings → Secrets → New secret
   - Name: `GOOGLE_SERVICES_JSON`
   - Value: Kompletter Inhalt von `google-services.json`

4. **APK bauen**
   - GitHub Actions startet automatisch bei Push
   - Oder: Actions → "Build Android APK" → Run workflow
   - APK Download unter "Artifacts"

5. **APK installieren**
   - APK auf Handy kopieren
   - "Installation aus unbekannten Quellen" erlauben
   - APK öffnen → Installieren

### Option 2: Lokaler Build (für Entwickler)

Siehe [Entwickler Setup](#-entwickler-setup)

---

## 👨‍💻 Entwickler Setup

### 1. Prerequisites

**Software:**
```bash
# Flutter SDK (3.19+)
# https://flutter.dev/docs/get-started/install
flutter --version

# Android Studio (für Android SDK)
# https://developer.android.com/studio

# Node.js 20+ (für Cloud Functions)
node --version
npm --version

# Firebase CLI
npm install -g firebase-tools
firebase login
```

**Accounts:**
- Firebase Account (https://console.firebase.google.com)
- Google Cloud Account (https://console.cloud.google.com)

### 2. Firebase Projekt Setup

#### 2.1 Firebase Console
1. Projekt erstellen: `KalorienTracker`
2. Region: `europe-west1` (Belgien)
3. Firestore Datenbank erstellen (im Test-Modus starten)

#### 2.2 Authentication aktivieren
```
Firebase Console → Authentication → Sign-in method
- Google: Enable
- Email/Password: Enable
```

#### 2.3 Android App registrieren
```
Projekteinstellungen → Your apps → Android App hinzufügen
- Package Name: com.KalorienTracker
- google-services.json downloaden → flutter_app/android/app/
```

#### 2.4 iOS App registrieren (optional)
```
Projekteinstellungen → Your apps → iOS App hinzufügen
- Bundle ID: com.KalorienTracker
- GoogleService-Info.plist downloaden → flutter_app/ios/Runner/
```

### 3. Gemini API Key

```bash
# Google Cloud Console
1. https://console.cloud.google.com/
2. Projekt wählen: KalorienTracker
3. APIs & Services → Enable APIs
4. Suche: "Generative Language API" → Enable
5. Credentials → Create API Key → Kopieren
```

### 4. Projekt konfigurieren

```bash
# Flutter Dependencies
cd flutter_app
flutter pub get

# Code generieren (für Modelle)
flutter pub run build_runner build --delete-conflicting-outputs

# Firebase Options generieren
flutterfire configure --project=YOUR_PROJECT_ID
```

### 5. Cloud Functions deployen

```bash
cd firebase/functions
npm install

# Gemini API Key als Secret setzen
firebase functions:secrets:set GEMINI_API_KEY
# (Paste your API key when prompted)

# Functions deployen
firebase deploy --only functions

# URLs notieren - werden in CloudFunctionService benötigt
```

### 6. App starten

```bash
cd flutter_app

# Android Emulator/Device
flutter run

# iOS Simulator (nur macOS)
flutter run -d ios
```

---

## 📱 APK Build & Installation

### Lokaler Build

#### Debug APK (für Tests)
```powershell
cd flutter_app
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release APK (für Production)
```powershell
cd flutter_app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Installation auf Gerät

**Via USB:**
```powershell
# USB Debugging aktivieren am Gerät
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Via Datei-Transfer:**
1. APK auf Handy kopieren (USB/Cloud/Email)
2. Einstellungen → Sicherheit → "Unbekannte Quellen" erlauben
3. APK Datei öffnen → Installieren

### PowerShell Build Script

```powershell
# Automatischer Build
.\build_apk.ps1
```

---

## 🤖 GitHub Actions Setup

### Workflow bereits konfiguriert!

Die GitHub Actions Workflow-Datei ist bereits vorhanden: `.github/workflows/build-apk.yml`

### Was der Workflow macht:

1. ✅ Flutter 3.19.0 installieren
2. ✅ Android SDK Setup (Build-Tools 33.0.1, Platform 29+31)
3. ✅ Dependencies installieren (`flutter pub get`)
4. ✅ Code generieren (`build_runner`)
5. ✅ `firebase_options.dart` erstellen (Template)
6. ✅ `google-services.json` aus Secret laden
7. ✅ APK bauen (Debug bei PRs, Release bei Push)
8. ✅ APK als Artifact hochladen

### Secrets einrichten

**Erforderlich:**
```
GOOGLE_SERVICES_JSON - Inhalt deiner google-services.json
```

**Setup:**
1. GitHub Repo → Settings → Secrets and variables → Actions
2. New repository secret
3. Name: `GOOGLE_SERVICES_JSON`
4. Value: Kompletter JSON-Inhalt
5. Add secret

### Workflow starten

**Automatisch:**
```bash
git add .
git commit -m "Update"
git push
# → Build startet automatisch
```

**Manuell:**
1. GitHub → Actions Tab
2. "Build Android APK" Workflow
3. "Run workflow" → Branch wählen → Run

### APK herunterladen

1. GitHub → Actions Tab
2. Letzten erfolgreichen Workflow Run öffnen
3. Scrolle runter zu "Artifacts"
4. Download: `kalorientracker-app`
5. ZIP entpacken → APK installieren

---

## 📁 Projektstruktur

```
KalorienTracker/
├── flutter_app/                    # Flutter App
│   ├── lib/
│   │   ├── main.dart              # App Entry Point
│   │   ├── models/                # Data Models
│   │   │   ├── food_item.dart     # Food Item Model
│   │   │   ├── food_item.g.dart   # Generated JSON Code
│   │   │   ├── nutrients.dart     # Nutrients Model
│   │   │   └── nutrients.g.dart   # Generated JSON Code
│   │   ├── screens/               # UI Screens
│   │   │   ├── home_screen.dart   # Dashboard
│   │   │   ├── login_screen.dart  # Login UI
│   │   │   ├── signup_screen.dart # Sign Up UI
│   │   │   ├── scanner_screen.dart # Barcode Scanner
│   │   │   ├── favorites_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── services/              # Business Logic
│   │       ├── firebase_auth_service.dart    # Auth
│   │       ├── firestore_service.dart        # DB
│   │       └── cloud_function_service.dart   # API
│   ├── android/                   # Android Config
│   │   ├── app/
│   │   │   ├── build.gradle       # App Config
│   │   │   └── src/main/
│   │   │       ├── AndroidManifest.xml
│   │   │       ├── res/           # Resources
│   │   │       └── kotlin/com/KalorienTracker/
│   │   │           └── MainActivity.kt
│   │   ├── build.gradle           # Project Config
│   │   └── settings.gradle        # Gradle Settings
│   ├── ios/                       # iOS Config
│   └── pubspec.yaml               # Dependencies
│
├── firebase/                       # Backend
│   ├── functions/
│   │   ├── index.js               # Cloud Functions
│   │   └── package.json           # Node Dependencies
│   ├── firestore.rules            # Security Rules
│   └── firebase.json              # Firebase Config
│
├── .github/
│   └── workflows/
│       └── build-apk.yml          # CI/CD Pipeline
│
├── build_apk.ps1                  # Local Build Script
└── README.md                       # Diese Datei
```

---

## 🔌 API Dokumentation

### Cloud Functions

Base URL: `https://europe-west1-YOUR_PROJECT_ID.cloudfunctions.net`

#### 1. Analyze Food Image

**Endpoint:** `POST /analyzeFood`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <FIREBASE_ID_TOKEN>"
}
```

**Request Body:**
```json
{
  "image": "base64_encoded_image_string"
}
```

**Response:**
```json
{
  "nutrients": {
    "label": "Pizza Margherita",
    "calories": 266,
    "protein": 11,
    "fat": 10,
    "carbs": 33,
    "fiber": 2.5
  }
}
```

#### 2. Get Barcode Data

**Endpoint:** `POST /getBarcodeData`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <FIREBASE_ID_TOKEN>"
}
```

**Request Body:**
```json
{
  "barcode": "8711327324602"
}
```

**Response:**
```json
{
  "nutrients": {
    "label": "Product Name",
    "calories": 350,
    "protein": 12,
    "fat": 15,
    "carbs": 40,
    "fiber": 3
  }
}
```

### Firestore Collections

#### `/users/{userId}/foodItems`

**Document Structure:**
```json
{
  "id": "auto_generated",
  "barcode": "optional_barcode",
  "label": "Food name",
  "calories": 250,
  "protein": 10,
  "fat": 8,
  "carbs": 30,
  "fiber": 2,
  "timestamp": "2026-01-28T10:00:00Z",
  "isFavorite": false,
  "source": "gemini|openfoodfacts|manual"
}
```

**Security Rules:**
- User kann nur eigene Daten lesen/schreiben
- Keine Cross-User Zugriffe

---

## 🚀 Deployment

### Cloud Functions deployen

```bash
cd firebase/functions

# Secrets setzen
firebase functions:secrets:set GEMINI_API_KEY

# Deployen
firebase deploy --only functions

# Nur spezifische Function
firebase deploy --only functions:analyzeFood

# Mit Log-Ausgabe
firebase deploy --only functions --debug
```

### Firestore Rules deployen

```bash
firebase deploy --only firestore:rules
```

### Komplettes Firebase Deployment

```bash
firebase deploy
```

### Production Checklist

- [ ] Firebase Projekt in Production Mode
- [ ] Firestore Security Rules aktiviert
- [ ] Cloud Functions deployed
- [ ] API Keys als Secrets gesetzt
- [ ] `google-services.json` in App integriert
- [ ] Release APK signiert (falls Play Store)
- [ ] Domain für Cloud Functions (optional)
- [ ] Monitoring aktiviert

---

## 💰 Kosten & Skalierung

### Free Tier (0-1000 User)

**Monatliche Kosten: $0**

- Gemini 1.5 Flash: 1500 Requests/Tag gratis (1.5-15 RPM)
- Firestore: 50k reads, 20k writes, 1GB gratis
- Cloud Functions: 2M invocations, 400k GB-sec gratis
- Authentication: Unlimitiert gratis
- Hosting/Storage: 10GB gratis

**Realistisch:**
- ~100-500 aktive User = Free Tier ausreichend
- ~50 Gemini API Calls/Tag pro User möglich

### Paid Tier (1000+ User)

**Gemini API:**
- $0.075 / 1k Requests (1.5-15 RPM)
- $0.30 / 1M Tokens (15 RPM+)

**Geschätzte Kosten bei 10.000 Usern:**
- Gemini: ~$50-200/Monat
- Firestore: ~$10-50/Monat
- Functions: ~$5-20/Monat
- **Total: ~$65-270/Monat**

### Optimierungstipps

1. **Caching** - Häufige Produkte lokal speichern
2. **Batch Requests** - Mehrere Bilder zusammenfassen
3. **Fallback** - OpenFoodFacts nutzen wenn verfügbar
4. **Compression** - Bilder vor Upload komprimieren
5. **Rate Limiting** - User-Limits implementieren

---

## 🐛 Troubleshooting

### Build Errors

#### Kotlin Version Conflict
```
Error: Module was compiled with incompatible version of Kotlin
```
**Fix:**
```groovy
// android/build.gradle
ext.kotlin_version = '2.1.0'

// android/settings.gradle
id "org.jetbrains.kotlin.android" version "2.1.0"
```

#### Missing Generated Files
```
Error: 'food_item.g.dart' not found
```
**Fix:**
```bash
cd flutter_app
flutter pub run build_runner build --delete-conflicting-outputs
```

#### MinSdkVersion Error
```
Error: minSdkVersion cannot be smaller than 23
```
**Fix:**
```groovy
// android/app/build.gradle
defaultConfig {
    minSdkVersion 23
}
```

#### Missing Resources
```
Error: resource mipmap/ic_launcher not found
```
**Fix:**
```bash
# Resources existieren bereits in:
flutter_app/android/app/src/main/res/
# Falls nicht: Commit und pushe res/ Ordner
git add -f flutter_app/android/app/src/main/res/
```

### Runtime Errors

#### Firebase Not Initialized
```
Error: [core/no-app] No Firebase App
```
**Fix:**
```dart
// Stelle sicher, dass Firebase initialisiert wird:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

#### Google Services Missing
```
Error: google-services.json missing
```
**Fix:**
1. Download von Firebase Console
2. Platziere in: `flutter_app/android/app/google-services.json`
3. Package Name muss übereinstimmen: `com.KalorienTracker`

#### Permission Denied (Firestore)
```
Error: PERMISSION_DENIED
```
**Fix:**
```javascript
// firestore.rules - Prüfe Rules:
match /users/{userId}/foodItems/{itemId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### Cloud Functions Errors

#### API Key Not Found
```
Error: API key not configured
```
**Fix:**
```bash
firebase functions:secrets:set GEMINI_API_KEY
# Paste API key
firebase deploy --only functions
```

#### CORS Error
```
Error: CORS policy blocked
```
**Fix:** Bereits im Code enthalten:
```javascript
res.set("Access-Control-Allow-Origin", "*");
res.set("Access-Control-Allow-Methods", "POST");
res.set("Access-Control-Allow-Headers", "Content-Type,Authorization");
```

### GitHub Actions Errors

#### Package Name Mismatch
```
Error: No matching client found for package name
```
**Fix:**
1. Firebase Console: Registriere App mit `com.KalorienTracker`
2. Download neue `google-services.json`
3. Update GitHub Secret: `GOOGLE_SERVICES_JSON`

#### Build Timeout
```
Error: Job exceeded maximum time limit
```
**Fix:**
- Normal: Build dauert 5-10 Minuten
- Bei Timeout: Re-run workflow
- GitHub Actions hat 6 Stunden Limit

---

## 📝 Development Workflow

### Feature Development

```bash
# 1. Branch erstellen
git checkout -b feature/neue-funktion

# 2. Code ändern
# ... entwickeln ...

# 3. Testen
flutter test
flutter analyze

# 4. Commit
git add .
git commit -m "feat: Neue Funktion hinzugefügt"

# 5. Push
git push origin feature/neue-funktion

# 6. Pull Request erstellen
```

### Code Style

```dart
// Formatierung
flutter format .

// Linting
flutter analyze

// Tests ausführen
flutter test
```

### Git Konventionen

**Commit Messages:**
- `feat:` - Neue Features
- `fix:` - Bugfixes
- `docs:` - Dokumentation
- `style:` - Code-Formatierung
- `refactor:` - Code-Refactoring
- `test:` - Tests hinzufügen
- `chore:` - Build-Prozess, Dependencies

---

## 🔐 Security Best Practices

### API Keys
- ✅ Alle API Keys nur im Backend (Cloud Functions)
- ✅ Secrets via Firebase Secrets Manager
- ✅ Nie im Client-Code
- ✅ Nie in Git committen

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User kann nur eigene Daten lesen/schreiben
    match /users/{userId}/foodItems/{itemId} {
      allow read, write: if request.auth != null 
                        && request.auth.uid == userId;
    }
  }
}
```

### Authentication
- ✅ Firebase ID Tokens für alle API Calls
- ✅ Token-Validierung in Cloud Functions
- ✅ Automatic Token Refresh

---

## 🤝 Contributing

Contributions sind willkommen! Bitte:

1. Fork das Repo
2. Feature Branch erstellen
3. Code committen
4. Pull Request öffnen

---

## 📄 License

MIT License - Frei nutzbar für private und kommerzielle Projekte.

---

## 👤 Author

Entwickelt mit ❤️ und KI-Unterstützung

---

## 🔗 Links

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [OpenFoodFacts API](https://world.openfoodfacts.org/data)

---

## 📧 Support

Bei Problemen:
1. Checke [Troubleshooting](#-troubleshooting)
2. GitHub Issues erstellen
3. Firebase Console Logs prüfen

---

**Happy Coding! 🚀**
