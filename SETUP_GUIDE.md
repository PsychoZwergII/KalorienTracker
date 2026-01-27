# Flutter KalorienTracker - Complete Setup Guide

## 🎯 Project Overview

**KalorienTracker** ist eine cross-platform (Android + iPhone) Kalorienzähler-App mit:

- ✅ KI-gestützte Bildanalyse via Google Gemini
- ✅ Barcode-Scanning via ML Kit + Open Food Facts
- ✅ Multi-User Support (Google Sign-In)
- ✅ Cloud-Datenspeicherung (Firestore)
- ✅ **KOSTENLOS** ($0/Monat)

## 📋 Prerequisites

### Software Installation

```bash
# 1. Flutter SDK installieren (ab Version 3.0)
# Download: https://flutter.dev/docs/get-started/install

# 2. Überprüfen, dass alles installiert ist:
flutter --version
flutter doctor

# 3. Xcode (für iOS) - nur auf macOS
# App Store: Xcode (oder Xcode Command Line Tools)

# 4. Android Studio (optional, aber empfohlen)
# Download: https://developer.android.com/studio
```

### Google Cloud Project Setup

#### Schritt 1: Firebase Project erstellen

```
1. Gehen Sie zu: https://console.firebase.google.com/
2. Klicken Sie auf "Create Project"
3. Projekt Name: "KalorienTracker"
4. Region: Europe (Belgien/Niederlande)
5. Firestore Datenbank erstellen (im Projekt-Dashboard)
```

#### Schritt 2: Google Sign-In aktivieren

```
1. Im Firebase Dashboard → Authentication
2. Sign-in method → Google
3. E-Mail Adresse für Projekt-Benachrichtigungen eingeben
4. Speichern
```

#### Schritt 3: Gemini API Key erstellen

```
1. Google Cloud Console: https://console.cloud.google.com/
2. Projekt wählen: "KalorienTracker"
3. API & Services → Enable APIs and Services
4. Suchen: "Generative Language API"
5. Enable klicken
6. Credentials → Create API Key
7. API Key kopieren (wird später benötigt)
```

#### Schritt 4: Android App in Firebase registrieren

```
1. Firebase Dashboard → Project Settings
2. Tab: "Your apps" → Add app → Android
3. Package Name: com.example.kalorientracker (oder Ihren Custom Name)
4. Google Play App Signing Certificate SHA-1 (optional für App Store)
5. google-services.json downloadladen
6. In: flutter_app/android/app/google-services.json platzieren
```

#### Schritt 5: iOS App in Firebase registrieren

```
1. Firebase Dashboard → Project Settings
2. Tab: "Your apps" → Add app → iOS
3. Bundle ID: com.example.kalorientracker
4. GoogleService-Info.plist downloadladen
5. In Xcode: flutter_app → ios → Runner
6. GoogleService-Info.plist hinzufügen (Add files to Runner)
```

## 🚀 Project-Setup

### 1. Flutter Project initialisieren

```bash
cd flutter_app
flutter pub get
```

### 2. Cloud Functions Setup

```bash
# Node.js und npm installieren (falls nicht vorhanden)
# Download: https://nodejs.org/ (LTS version)

# Firebase CLI installieren
npm install -g firebase-tools

# Login mit Google Account
firebase login

# In Cloud Functions Verzeichnis:
cd firebase/functions
npm install
```

### 3. Environment Variables konfigurieren

Erstelle eine `.env` Datei im `firebase/functions` Verzeichnis:

```bash
GEMINI_API_KEY=your_gemini_api_key_here
```

Oder als Cloud Function Secret (empfohlen für Production):

```bash
# Firebase Secrets Setup (für größere Deployments)
firebase functions:secrets:set GEMINI_API_KEY
# -> Ihr API Key eingeben
```

### 4. Firebase Konfiguration in App

Datei: `flutter_app/lib/firebase_options.dart`

Hier müssen die Firebase Config-Werte eingefügt werden (aus `google-services.json` und `GoogleService-Info.plist`):

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: 'YOUR_IOS_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  iosBundleId: 'com.example.kalorientracker',
);
```

## 📱 Android Konfiguration

### Manifest Permissions

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Build Konfiguration

`android/app/build.gradle`:

```gradle
android {
  compileSdkVersion 33
  minSdkVersion 21
  targetSdkVersion 33
}

dependencies {
  // Firebase
  implementation platform('com.google.firebase:firebase-bom:32.0.0')
  implementation 'com.google.firebase:firebase-auth'
  implementation 'com.google.firebase:firebase-firestore'
  implementation 'com.google.firebase:firebase-storage'

  // Google Sign-In
  implementation 'com.google.android.gms:play-services-auth:20.5.0'
}
```

## 🍎 iOS Konfiguration

### Pod Dependencies

Nach `flutter pub get` automatisch konfiguriert über `pubspec.yaml`.

### Permissions

`ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Kamera wird zum Fotografieren von Lebensmitteln benötigt</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Zugriff auf Fotobibliothek für Lebensmittelfotos</string>
<key>NSPhotoLibraryAddOnlyUsageDescription</key>
<string>Fotos speichern</string>
```

### iOS Deployment Target

`ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

## ☁️ Cloud Functions Deployment

### Lokal testen (Emulator)

```bash
cd firebase/functions
firebase emulators:start --only functions
```

Die Funktionen sind dann verfügbar unter:

- `http://localhost:5001/kalorientracker/europe-west1/analyzeFood`
- `http://localhost:5001/kalorientracker/europe-west1/getBarcodeData`

### Zu Firebase deployen

```bash
firebase deploy --only functions

# Oder mit Secrets:
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions
```

Nach Deployment sind die Funktionen verfügbar unter:

- `https://europe-west1-kalorientracker.cloudfunctions.net/analyzeFood`
- `https://europe-west1-kalorientracker.cloudfunctions.net/getBarcodeData`

## 🏗️ Firestore Datenbank Setup

### Security Rules deployment

```bash
firebase deploy --only firestore:rules
```

Struktur nach Deployment:

```
Firestore Database
├── users/
│   ├── {userId}/
│   │   ├── foodItems/
│   │   │   ├── doc1 (FoodItem)
│   │   │   ├── doc2 (FoodItem)
│   │   │   └── ...
│   │   └── userProfile (Profil-Daten)
```

### Datenbank Indizes

Firestore erstellt Indizes automatisch auf Basis der Abfragen. Falls nötig, können diese manuell erstellt werden in: Firebase Console → Firestore Database → Indexes.

## 📱 App kompilieren und testen

### Android (Debug)

```bash
cd flutter_app
flutter run -d android

# oder spezifisch:
flutter run -d "device_name"
```

### iOS (Debug)

```bash
cd flutter_app
flutter run -d ios

# M1/M2 Mac (Apple Silicon):
cd ios && pod install --repo-update && cd ..
flutter run -d ios
```

### Web (zum Testen)

```bash
flutter run -d chrome
```

## 📦 Release Build

### Android APK

```bash
flutter build apk --release
# Datei: flutter_app/build/app/outputs/flutter-app.apk
```

### Android App Bundle (für Play Store)

```bash
flutter build appbundle --release
# Datei: flutter_app/build/app/outputs/bundle/release/app-release.aab
```

### iOS (für App Store)

```bash
flutter build ios --release
# Mit Xcode Build:
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -config Release -derivedDataPath build
```

## 🔒 Sicherheit & Best Practices

### ✅ Was ist sicher:

- ✅ API Keys sind auf Cloud Functions Backend
- ✅ Firestore hat Security Rules (nur Nutzer-Daten)
- ✅ ID Tokens werden für Cloud Function Calls verwendet
- ✅ Open Food Facts ist kostenlos öffentlich

### ⚠️ Wichtig:

- ⚠️ Niemals API Keys in App-Code hardcodieren
- ⚠️ Nur HTTPS für API Calls
- ⚠️ Firestore Security Rules regelmäßig überprüfen
- ⚠️ Cloud Functions Rate Limiting konfigurieren (optional)

## 💰 Kostenanalyse (monatlich)

| Service         | Free Tier            | Unsere Nutzung   | Kosten |
| --------------- | -------------------- | ---------------- | ------ |
| Firebase Auth   | Unbegrenzt           | ~100 Users       | $0     |
| Cloud Firestore | 50k Reads/Tag        | ~5k Reads/Tag    | $0     |
| Cloud Functions | 2M Calls/Monat       | ~30k Calls/Monat | $0     |
| Cloud Storage   | 5GB                  | Keine            | $0     |
| Gemini API      | 60 req/min, 1500/day | ~50/day          | $0     |
| Open Food Facts | Kostenlos            | ~20/day          | $0     |
| **TOTAL**       |                      |                  | **$0** |

Selbst bei 10x Nutzung (10k Firestore Reads, 300k Function Calls) bleiben wir im kostenlosen Tier.

## 🐛 Troubleshooting

### "Flutter not found"

```bash
# Flutter zum PATH hinzufügen:
# Auf Windows:
setx PATH "%PATH%;C:\path\to\flutter\bin"

# Dann Terminal neu starten
```

### "google-services.json not found"

```bash
# Sicherstellen, dass die Datei im richtigen Ort ist:
flutter_app/android/app/google-services.json
```

### Cloud Functions API error

```bash
# API aktivieren:
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### iOS Pods Error

```bash
cd ios
rm -rf Pods
rm -rf Podfile.lock
pod install --repo-update
cd ..
```

### "Could not find Google Play services version"

In `android/build.gradle`:

```gradle
ext {
  googlePlayServicesVersion = "4.3.10"
  googlePlayServicesAuthVersion = "20.5.0"
}
```

## 📚 Weitere Ressourcen

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Docs](https://firebase.google.com/docs)
- [Google Generative AI](https://ai.google.dev/)
- [Open Food Facts API](https://world.openfoodfacts.org/api)
- [ML Kit](https://developers.google.com/ml-kit)

## 🎓 Nächste Schritte

1. ✅ Firebase Project erstellen und konfigurieren
2. ✅ google-services.json + GoogleService-Info.plist downloaden
3. ✅ Gemini API Key generieren
4. ✅ `firebase_options.dart` ausfüllen
5. ✅ Cloud Functions deployen
6. ✅ Android/iOS konfigurieren
7. ✅ App lokal testen (`flutter run`)
8. ✅ Release Build erstellen
9. ✅ Play Store / App Store einreichen

## 💬 Support

Bei Fragen oder Problemen:

- Flutter Docs: https://flutter.dev/
- Firebase Support: https://firebase.google.com/support
- Google AI Docs: https://ai.google.dev/docs
