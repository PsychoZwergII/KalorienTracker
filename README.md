# 🍽️ KalorienTracker - KI-gestützte Android App

Eine vollständig funktionsfähige **kostenlose** Android-App (Kotlin/Jetpack Compose) für Kalorientracking mit:
- **Kostenlose KI-Bildanalyse**: Google Gemini-1.5-Flash
- **Kostenloser Barcode-Scanner**: ML Kit (on-device) + Open Food Facts API
- **Smart Goal Engine**: Automatische Kalorienanpassung basierend auf Gewichtsverlauf (Mifflin-St Jeor)
- **Lokale Datenbank**: Room DB für Favoriten & Verlauf (spart API-Calls)

---

## 📋 Anforderungen

- **Android SDK 24+** (Android 7.0+)
- **Kotlin 1.9.10+**
- **Gradle 8.0+**
- **Google Konto** (für Gemini API Free Tier)

---

## 🚀 Schnellstart

### 1. Projekt klonen & öffnen

```bash
cd KalorienTracker
# Öffne in Android Studio
```

### 2. Gemini API Key einrichten

#### Option A: Environment Variable (Empfohlen für Sicherheit)
```bash
# PowerShell (Windows)
$env:KALORIEN_GEMINI_API_KEY="AIzaSy..." 

# Bash (Mac/Linux)
export KALORIEN_GEMINI_API_KEY="AIzaSy..."
```

#### Option B: gradle.properties (Lokal, NICHT in Git einchecken!)
Bearbeite `gradle.properties`:
```properties
KALORIEN_GEMINI_API_KEY=AIzaSy_DEIN_API_KEY_HIER
```

⚠️ **WICHTIG**: Füge `gradle.properties` zu `.gitignore` hinzu!

### 3. Android Studio Sync & Build
```bash
./gradlew clean build
```

### 4. App auf Emulator/Device starten
```bash
./gradlew installDebug
```

---

## 📱 Wie bekommst du einen kostenlosen API Key?

### Google Generative AI (Gemini) - **100% Kostenlos für Entwickler**

1. **Konto erstellen**: https://makersuite.google.com/app/apikey
2. **"Create API Key" klicken** → Ein neuer API Key wird generiert
3. **Key kopieren** und in `gradle.properties` oder als Umgebungsvariable setzen

**Kostenloses Kontingent** (Stand 2024):
- Bis zu **60 Anfragen pro Minute**
- **1500 Anfragen pro Tag**
- Völlig kostenlos (keine Kreditkarte nötig)

Weitere Infos: https://ai.google.dev/docs/gemini_api_pricing

### Open Food Facts - **Völlig kostenlos, Open Source**
- Keine Anmeldung nötig
- API-Endpoint: `https://world.openfoodfacts.org/api/v0/product/{barcode}.json`
- Öffentliche Datenbank mit Millionen Produkten

---

## 🏗️ Projekt-Struktur

```
KalorienTracker/
├── app/
│   ├── src/main/
│   │   ├── java/com/example/kalorientracker/
│   │   │   ├── data/
│   │   │   │   ├── db/              # Room Datenbank
│   │   │   │   │   ├── AppDatabase.kt
│   │   │   │   │   ├── FoodEntity.kt
│   │   │   │   │   └── FoodDao.kt
│   │   │   │   ├── network/         # API-Integration
│   │   │   │   │   ├── GeminiRepository.kt
│   │   │   │   │   ├── OpenFoodFactsRepository.kt
│   │   │   │   │   └── retrofit/
│   │   │   │   │       ├── ApiInterfaces.kt
│   │   │   │   │       └── RetrofitModule.kt
│   │   │   │   └── repository/      # Fascade
│   │   │   │       └── FoodRepository.kt
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── Nutrients.kt
│   │   │   │   │   └── FoodItem.kt
│   │   │   │   └── SmartGoalEngine.kt (Mifflin-St Jeor)
│   │   │   ├── ui/
│   │   │   │   ├── compose/         # UI-Screens (Material3)
│   │   │   │   │   ├── HomeScreen.kt
│   │   │   │   │   ├── ScannerScreen.kt
│   │   │   │   │   ├── FavoritesScreen.kt
│   │   │   │   │   ├── SettingsScreen.kt
│   │   │   │   │   └── Theme.kt
│   │   │   │   └── viewmodel/       # MVVM ViewModels
│   │   │   │       ├── MainViewModel.kt
│   │   │   │       ├── ScannerViewModel.kt
│   │   │   │       ├── FavoritesViewModel.kt
│   │   │   │       └── SettingsViewModel.kt
│   │   │   ├── ml/
│   │   │   │   └── BarcodeAnalyzer.kt (ML Kit, on-device)
│   │   │   ├── util/
│   │   │   │   ├── Base64Utils.kt
│   │   │   │   └── ImageUtils.kt
│   │   │   └── MainActivity.kt
│   │   ├── res/
│   │   │   ├── values/strings.xml
│   │   │   └── xml/
│   │   │       ├── file_paths.xml
│   │   │       ├── backup_rules.xml
│   │   │       └── data_extraction_rules.xml
│   │   └── AndroidManifest.xml
│   ├── build.gradle
│   └── proguard-rules.pro
├── build.gradle
├── settings.gradle
├── gradle.properties
└── README.md (dieses File)
```

---

## 🎯 Hauptfunktionen

### 1️⃣ **Barcode-Scanner (ML Kit)**
- **On-Device Processing** → 100% kostenlos, schnell
- Unterstützt: UPC-A, UPC-E, EAN-8, EAN-13, Code128, QR-Codes
- Integration mit Open Food Facts für Produktdaten
- Nährwerte automatisch abgerufen

### 2️⃣ **KI-Bildanalyse (Gemini-1.5-Flash)**
- Fotografiere ein Essen → Gemini erkennt Lebensmittel
- JSON-Antwort mit: Kalorien, Protein, Fett, Carbs, Ballaststoffe
- Ergebnis wird lokal cacht (spart Kosten)

### 3️⃣ **Smart Goal Engine**
```kotlin
// Mifflin-St Jeor Formel für BMR:
// Männer: BMR = 10*kg + 6.25*cm - 5*age + 5
// Frauen: BMR = 10*kg + 6.25*cm - 5*age - 161

// TDEE = BMR × Activity Factor (1.2–1.725)

// Auto-Anpassung: Wenn Gewicht ± X kg → 
// Kalorieziel um ±(7700 kcal per kg / days) anpassen
```

### 4️⃣ **Lokale Datenbank (Room)**
- Speichert Favoriten, Verlauf, Nährwerte
- Offline-Zugriff
- Caching für häufig gegessene Items → API-Calls sparen

### 5️⃣ **MVVM Architektur**
- **Model**: Room DB + API Responses
- **ViewModel**: State Management (StateFlow)
- **View**: Jetpack Compose + Material Design 3

---

## 🔧 Kern-Implementierungen

### GeminiRepository (Bild-Analyse)
[GeminiRepository.kt](app/src/main/java/com/example/kalorientracker/data/network/GeminiRepository.kt)

```kotlin
suspend fun analyzeFoodImage(bitmap: Bitmap): Result<Nutrients>
// → Sendet Bild als Base64-JPEG
// → Wartet auf Gemini JSON-Response
// → Parsed Nährstoffe (Kalorien, Protein, Fett, Carbs, Fiber)
```

### BarcodeAnalyzer (ML Kit)
[BarcodeAnalyzer.kt](app/src/main/java/com/example/kalorientracker/ml/BarcodeAnalyzer.kt)

```kotlin
class BarcodeAnalyzer : ImageAnalysis.Analyzer
// → Läuft on-device (0 Kosten)
// → Ruft onBarcodeDetected auf → OpenFoodFacts Lookup
```

### SmartGoalEngine (Automatische Anpassung)
[SmartGoalEngine.kt](app/src/main/java/com/example/kalorientracker/domain/SmartGoalEngine.kt)

```kotlin
fun calculateSmartCalories(
    weightKg, heightCm, ageYears, isMale, activityFactor, 
    previousWeightKg, daysSinceLast
): SmartCalorieResult
// → BMR (Mifflin-St Jeor)
// → TDEE (mit Activity Factor)
// → Auto-Anpassung bei Gewichtschange
```

### FoodRepository (Fascade)
[FoodRepository.kt](app/src/main/java/com/example/kalorientracker/data/repository/FoodRepository.kt)

Koordiniert:
1. Lokale DB Abfrage
2. Barcode-Lookup (OpenFoodFacts)
3. Bild-Analyse (Gemini)
4. Speichern & Caching

---

## 📊 Datenfluss

```
┌─────────────────────────────────────────────────────────┐
│  UI (Compose)                                           │
│  ├─ HomeScreen (Tagesübersicht)                        │
│  ├─ ScannerScreen (Barcode + Foto)                     │
│  ├─ FavoritesScreen (gespeicherte Items)               │
│  └─ SettingsScreen (Profil + Smart Goals)              │
└─────────────────────────────────────────────────────────┘
              ↓ (ViewModels)
┌─────────────────────────────────────────────────────────┐
│  MVVM ViewModels (State Management)                    │
│  ├─ MainViewModel (Tagesdata, Makros)                  │
│  ├─ ScannerViewModel (Scan-Ergebnisse)                 │
│  ├─ FavoritesViewModel (Favoriten)                     │
│  └─ SettingsViewModel (Profil + Smart Goals)           │
└─────────────────────────────────────────────────────────┘
              ↓ (Flow, suspend fun)
┌─────────────────────────────────────────────────────────┐
│  Repository Layer                                       │
│  └─ FoodRepository (Fascade)                            │
│     ├─ Lokale DB (Room)                                │
│     ├─ GeminiRepository (Bild → JSON)                  │
│     └─ OpenFoodFactsRepository (Barcode → Daten)       │
└─────────────────────────────────────────────────────────┘
         ↙          ↓           ↘
    ┌────────┐ ┌──────────┐ ┌──────────────┐
    │ Room   │ │ Gemini   │ │ OpenFoodFacts│
    │ (Local)│ │ (Cloud)  │ │ (Cloud)      │
    └────────┘ └──────────┘ └──────────────┘
```

---

## 🔐 Datenschutz & Sicherheit

### ✅ Was ist sicher:
- **API Keys** nie in VCS einchecken (use `gradle.properties` + `.gitignore`)
- **Lokal verarbeitete Daten**: Barcode-Scanning läuft 100% on-device
- **Verschlüsselt übertragen**: HTTPS zu Gemini & OpenFoodFacts
- **Room DB lokal**: Deine Nährwertdaten verlassen das Handy nicht

### ⚠️ Was wird übertragen:
- Foto-Inhalte → Google Gemini (zur Analyse)
- Barcode-Nummer → OpenFoodFacts (öffentliche API)

---

## 🚀 Deployment & Testing

### Lokal testen:
```bash
# Build & Run Debug
./gradlew installDebug

# Mit Logs
./gradlew installDebug && adb logcat | grep "KalorienTracker\|GeminiRepository\|BarcodeAnalyzer"
```

### Release Build:
```bash
# Signierter APK
./gradlew bundleRelease  # → Google Play App Bundle
./gradlew assembleRelease # → APK

# Keystore erstellen (erste Signierung):
keytool -genkey -v -keystore kalorientracker.jks -keyalg RSA -keysize 2048 -validity 10000
```

### Kosten überwachen:
1. Google Cloud Console: https://console.cloud.google.com/
2. **API & Services → Quotas**
3. Überprüfe "Generative AI API" Nutzung
4. Alert setzen (0 € Kosten!)

---

## 🎓 Architektur-Highlights

### MVVM Pattern
```kotlin
// ViewModel hält State
data class MainUiState(
    val todaysTotalCalories: Double = 0.0,
    val recentFoods: List<FoodItem> = emptyList()
)

class MainViewModel(foodRepository: FoodRepository) : ViewModel {
    private val _uiState = MutableStateFlow(MainUiState())
    val uiState = _uiState.asStateFlow()
    
    fun selectDate(date: LocalDateTime) { ... }
}

// Composable observiert StateFlow
@Composable
fun HomeScreen(viewModel: MainViewModel) {
    val state by viewModel.uiState.collectAsState()
    // Recompose only wenn state ändert
}
```

### Coroutine-basiertes Networking
```kotlin
// Suspend fun → non-blocking
suspend fun analyzeFoodImage(bitmap: Bitmap): Result<Nutrients> {
    withContext(Dispatchers.IO) {
        val response = api.analyzeImage(...)
        // Automatisch Thread-Pool verwaltet
    }
}

// Flow für Datenbank-Streams
fun getFavorites(): Flow<List<FoodItem>> {
    return foodDao.getFavorites().map { toFoodItems() }
}
```

### Dependency Injection (manuell)
```kotlin
// In MainActivity:
val db = AppDatabase.getDatabase(this)
val geminiApi = RetrofitModule.createGeminiApi()
val geminiRepository = GeminiRepository(geminiApi)
val foodRepository = FoodRepository(db, geminiRepository, ...)

val mainViewModel = MainViewModel(foodRepository)
```

---

## 📈 Kalkulierte Kosten: **$0.00**

| Funktion | Basis | Kostenloses Kontingent | Limit |
|----------|-------|----------------------|-------|
| **Gemini API** | $0.05 pro 1K Tokens | ✅ 60 req/min, 1500/day | Mittig überwachen |
| **ML Kit Barcode** | $0 | ✅ 100% kostenlos (on-device) | Keine |
| **Open Food Facts** | $0 | ✅ 100% kostenlos (öffentlich) | Keine |
| **Room Database** | $0 | ✅ Lokal gespeichert | Keine |

---

## 🤝 Contributing

Fehler gefunden? Neue Feature-Idee?
1. Fork dieses Repo
2. Feature-Branch: `git checkout -b feature/deine-feature`
3. Commit: `git commit -am 'Addedeine-feature'`
4. Push: `git push origin feature/deine-feature`
5. Pull Request öffnen

---

## 📜 Lizenz

MIT License - Frei verwendbar für private & kommerzielle Projekte.

---

## 🎉 Nächste Schritte

- [ ] Kamera-Integration via CameraX (Photo Capture für Gemini)
- [ ] Barcode-Scanner UI (Preview + Focus)
- [ ] Persönliche Statistiken & Grafiken
- [ ] Weekly/Monthly Reports
- [ ] Cloud-Backup (Firebase optional)
- [ ] Offline-Modus Verbesserung
- [ ] Widget für Homescreen

---

## 📞 Support

Fragen?
- 📧 E-Mail Support: [deine-email@example.com]
- 🐛 Bug Reports: Issues im Repo öffnen
- 💬 Diskussionen: Discussions-Tab

---

**Viel Spaß mit KalorienTracker! 🍎📊**

Gebaut mit ❤️ in Kotlin & Jetpack Compose
