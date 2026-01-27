# 🗂️ DATEI-INDEX - Schnelle Referenz

Diese Datei hilft dir, alle Komponenten schnell zu finden!

---

## 📄 DOKUMENTATION (Start hier!)

| Datei                         | Inhalt                      | Wann lesen       |
| ----------------------------- | --------------------------- | ---------------- |
| **QUICK_START.txt**           | 5-Minuten Übersicht         | Zuerst!          |
| **README.md**                 | Vollständige Dokumentation  | Für Details      |
| **API_KEY_SETUP.md**          | Gemini API-Key Anleitung    | Für API-Setup    |
| **IMPLEMENTATION_SUMMARY.md** | Was wurde implementiert     | Für Übersicht    |
| **COMPLETION_CHECKLIST.md**   | Projekt-Status & Checkliste | Zur Kontrolle    |
| **.gitignore**                | Git-Exclude Regeln          | Secrets schützen |

---

## 🔧 KONFIGURATION

| Datei                    | Zweck                          | Ändern?                    |
| ------------------------ | ------------------------------ | -------------------------- |
| `build.gradle` (Root)    | Plugin Versions                | Nur bei Updates            |
| `app/build.gradle`       | Module + Dependencies          | Nur bei Library-Updates    |
| `settings.gradle`        | Module Setup                   | Nicht ändern               |
| `gradle.properties`      | API Key, Env Vars              | **JA - API Key hier!**     |
| `local.properties`       | SDK Path (auto-generated)      | Nicht ändern               |
| `AndroidManifest.xml`    | Permissions, App-Einstellungen | Nur bei Permission-Changes |
| `app/proguard-rules.pro` | Code Shrinking                 | Nur bei Release-Build      |

---

## 📁 SOURCE CODE STRUKTUR

### **data/** - Datenbank & Netzwerk

#### db/ (Room Database)

| Datei            | Zeilen | Zweck                      |
| ---------------- | ------ | -------------------------- |
| `AppDatabase.kt` | 25     | Singleton, databaseBuilder |
| `FoodEntity.kt`  | 15     | @Entity (Lebensmittel)     |
| `FoodDao.kt`     | 60     | @Dao (CRUD + Queries)      |

#### network/ (APIs)

| Datei                        | Zeilen | Zweck                           |
| ---------------------------- | ------ | ------------------------------- |
| `GeminiRepository.kt`        | 150    | Bildanalyse (Upload → JSON)     |
| `OpenFoodFactsRepository.kt` | 45     | Barcode-Lookup                  |
| `retrofit/ApiInterfaces.kt`  | 50     | Retrofit Service Interfaces     |
| `retrofit/RetrofitModule.kt` | 40     | Retrofit Config (OkHttp, Moshi) |

#### repository/ (Facades)

| Datei               | Zeilen | Zweck                   |
| ------------------- | ------ | ----------------------- |
| `FoodRepository.kt` | 180    | Koordinator (DB + APIs) |

---

### **domain/** - Business Logic

#### models/

| Datei          | Zeilen | Zweck                           |
| -------------- | ------ | ------------------------------- |
| `Nutrients.kt` | 10     | Data Class (Kcal, Protein, etc) |
| `FoodItem.kt`  | 15     | Data Class (mit ID, Timestamp)  |

#### Root

| Datei                | Zeilen | Zweck                               |
| -------------------- | ------ | ----------------------------------- |
| `SmartGoalEngine.kt` | 80     | Mifflin-St Jeor + Kalorienanpassung |

---

### **ui/** - Compose UI + ViewModels

#### compose/ (Material Design 3 Screens)

| Datei                | Zeilen | Zweck                          |
| -------------------- | ------ | ------------------------------ |
| `HomeScreen.kt`      | 180    | Tagesübersicht + Stats         |
| `ScannerScreen.kt`   | 130    | Barcode/Foto + Ergebnisse      |
| `FavoritesScreen.kt` | 120    | Favoriten-Liste                |
| `SettingsScreen.kt`  | 150    | Profil + Smart Goals           |
| `Theme.kt`           | 50     | Material3 Theming (Dark/Light) |

#### viewmodel/ (MVVM State Management)

| Datei                   | Zeilen | Zweck                     |
| ----------------------- | ------ | ------------------------- |
| `MainViewModel.kt`      | 85     | Home State + Tagesdata    |
| `ScannerViewModel.kt`   | 75     | Scan-Results State        |
| `FavoritesViewModel.kt` | 60     | Favoriten State           |
| `SettingsViewModel.kt`  | 85     | Profil State + SmartGoals |

---

### **ml/** - Machine Learning

| Datei                | Zeilen | Zweck                      |
| -------------------- | ------ | -------------------------- |
| `BarcodeAnalyzer.kt` | 50     | ML Kit Scanner (on-device) |

---

### **util/** - Helper Functions

| Datei            | Zweck                             |
| ---------------- | --------------------------------- |
| `Base64Utils.kt` | Bitmap ↔ Base64 Conversion        |
| `ImageUtils.kt`  | Scaling, FileProvider, Temp-Files |

---

### **Root** (app/src/main/java)

| Datei             | Zeilen | Zweck                      |
| ----------------- | ------ | -------------------------- |
| `MainActivity.kt` | 100    | Entry Point, DI, App-Setup |

---

## 📦 RESOURCES (res/)

| Pfad                            | Zweck                      |
| ------------------------------- | -------------------------- |
| `values/strings.xml`            | String Resources           |
| `xml/file_paths.xml`            | FileProvider Konfiguration |
| `xml/backup_rules.xml`          | Backup-Konfiguration       |
| `xml/data_extraction_rules.xml` | Data Extraction Rules      |

---

## 🔍 NACH FUNKTIONALITÄT SUCHEN

### "Ich brauche den Barcode-Scanner"

→ `ml/BarcodeAnalyzer.kt`
→ `data/network/OpenFoodFactsRepository.kt`

### "Ich brauche die Bildanalyse"

→ `data/network/GeminiRepository.kt`
→ `util/Base64Utils.kt`

### "Ich brauche die Smart Goal Berechnung"

→ `domain/SmartGoalEngine.kt`
→ `ui/viewmodel/SettingsViewModel.kt`

### "Ich brauche Datenbank-Operationen"

→ `data/db/FoodDao.kt`
→ `data/repository/FoodRepository.kt`

### "Ich brauche die UI"

→ `ui/compose/*.kt` (4 Screens)
→ `ui/viewmodel/*.kt` (4 ViewModels)

### "Ich brauche die APIs"

→ `data/network/retrofit/ApiInterfaces.kt`
→ `data/network/retrofit/RetrofitModule.kt`

---

## 📊 CODE-METRIKEN

| Metrik                 | Wert  |
| ---------------------- | ----- |
| **Gesamt Zeilen Code** | ~2000 |
| **Gesamt Zeilen Doku** | ~1000 |
| **Anzahl Dateien**     | 40+   |
| **Hauptklassen**       | 10+   |
| **ViewModels**         | 4     |
| **UI-Screens**         | 4     |
| **Datenbank-Entities** | 1     |
| **APIs integriert**    | 2     |
| **Dependencies**       | 25+   |

---

## 🔐 SICHERHEITS-FOKUS

**API-Keys Sicherheit:**

- ✅ Nie in Git: gradle.properties in .gitignore
- ✅ Env Var: `$env:KALORIEN_GEMINI_API_KEY`
- ✅ BuildConfig: Automatisch von Gradle injiziert

**Datenschutz:**

- ✅ Daten lokal: Room Database auf Handy
- ✅ HTTPS: Retrofit nutzt verschlüsselte Verbindungen
- ✅ On-Device: ML Kit Barcode läuft 100% lokal

---

## 🚀 COMPILATION & DEPLOYMENT

| Task              | Befehl                      |
| ----------------- | --------------------------- |
| **Clean Build**   | `./gradlew clean build`     |
| **Debug Install** | `./gradlew installDebug`    |
| **Release APK**   | `./gradlew assembleRelease` |
| **App Bundle**    | `./gradlew bundleRelease`   |
| **Run Tests**     | `./gradlew test`            |

---

## 🎯 EMPFOHLENE LESE-REIHENFOLGE

1. **QUICK_START.txt** (diese Datei) - 2 Min
2. **API_KEY_SETUP.md** - API Key einrichten - 5 Min
3. **README.md** - Features & Architektur - 10 Min
4. **IMPLEMENTATION_SUMMARY.md** - Was wurde gemacht - 5 Min
5. **Code durchlesen:**
   - `MainActivity.kt` (Entry Point)
   - `data/repository/FoodRepository.kt` (Koordinator)
   - `ui/viewmodel/MainViewModel.kt` (State Management)
   - `ui/compose/HomeScreen.kt` (UI)

---

## 📞 HÄUFIGE FRAGEN

**Q: Wo setze ich den API Key?**
A: `gradle.properties` oder Umgebungsvariable `KALORIEN_GEMINI_API_KEY`

**Q: Warum wird der API Key nicht gefunden?**
A: Android Studio Terminal neustarten + ./gradlew clean build

**Q: Wo ist der Barcode-Scanner implementiert?**
A: `ml/BarcodeAnalyzer.kt` (ML Kit) + `data/network/OpenFoodFactsRepository.kt` (Lookup)

**Q: Wie funktioniert Bildanalyse?**
A: `data/network/GeminiRepository.kt` → Base64-Encode → Gemini API → JSON-Parse

**Q: Wo sind die Nährwert-Daten gespeichert?**
A: `data/db/` (Room Database, lokal auf Handy)

**Q: Kostet die App wirklich nichts?**
A: Ja! Alle Services nutzen Free Tiers (Gemini, ML Kit, OpenFoodFacts)

---

## ✅ PROJEKT STATUS

- ✅ Alle Dateien implementiert
- ✅ Alle Features codiert
- ✅ Dokumentation komplett
- ✅ Sicherheit geprüft
- ✅ Production-ready

**Status: 🟢 READY TO BUILD & RUN**

---

**Viel Erfolg! 🍎📊**
