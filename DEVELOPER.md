# 👨‍💻 KalorienTracker - Developer Guide

**Complete technical documentation for developers.**

---

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Project Setup](#project-setup)
3. [Code Structure](#code-structure)
4. [API Reference](#api-reference)
5. [Development Workflow](#development-workflow)
6. [Deployment](#deployment)
7. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture

### System Design

```
┌─────────────────────────────────────────┐
│      Flutter App (Android + iOS)        │
├─────────────────────────────────────────┤
│  UI Layers (Screens)                    │
│  ├─ LoginScreen                         │
│  ├─ SignUpScreen                        │
│  ├─ HomeScreen                          │
│  ├─ ScannerScreen                       │
│  ├─ FavoritesScreen                     │
│  └─ SettingsScreen                      │
├─────────────────────────────────────────┤
│  Service Layer                          │
│  ├─ FirebaseAuthService                 │
│  ├─ FirestoreService                    │
│  └─ CloudFunctionService                │
├─────────────────────────────────────────┤
│  Data Models                            │
│  ├─ Nutrients                           │
│  └─ FoodItem                            │
└─────────────────────────────────────────┘
              ↓ (Bearer Token)
┌─────────────────────────────────────────┐
│   Cloud Functions (Node.js Backend)     │
├─────────────────────────────────────────┤
│  analyzeFood()      ← Gemini API        │
│  getBarcodeData()   ← Open Food Facts   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│    Google Cloud Services                │
├─────────────────────────────────────────┤
│  Firebase Auth                          │
│  Cloud Firestore                        │
│  Google Generative AI (Gemini)          │
│  Open Food Facts API                    │
└─────────────────────────────────────────┘
```

### Key Principles

1. **Separation of Concerns**
   - UI ↔ Services ↔ External APIs
   - Services handle all Firebase calls
   - Models are pure data classes

2. **Security First**
   - API keys on backend only
   - Per-user data isolation
   - Firebase ID tokens for auth

3. **Real-time Sync**
   - Firestore Streams for live updates
   - StreamBuilders in UI
   - Automatic cloud sync

---

## 🚀 Project Setup

### 1. Clone & Install

```bash
# Clone repo
git clone https://github.com/yourusername/KalorienTracker.git
cd KalorienTracker

# Install Flutter dependencies
cd flutter_app
flutter pub get

# Install Cloud Functions dependencies
cd ../firebase/functions
npm install
```

### 2. Firebase Configuration

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Create Firebase project
# Visit: https://console.firebase.google.com
# - Create new project "KalorienTracker"
# - Enable Firestore Database
# - Enable Authentication (Google + Email/Password)
# - Create Gemini API key in Google Cloud Console
```

### 3. Environment Setup

**Download Firebase Config Files:**

1. **Android**: `google-services.json`

   ```bash
   # Firebase Console → Project Settings → Your Apps → google-services.json
   # Place in: flutter_app/android/app/google-services.json
   ```

2. **iOS**: `GoogleService-Info.plist`
   ```bash
   # Firebase Console → Project Settings → Your Apps → GoogleService-Info.plist
   # Place in: flutter_app/ios/Runner/GoogleService-Info.plist
   ```

**Configure App:**

Edit `flutter_app/lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'kalorientracker',
  storageBucket: 'kalorientracker.appspot.com',
);
```

### 4. Cloud Functions Setup

```bash
# Set Gemini API key
firebase functions:secrets:set GEMINI_API_KEY

# Deploy functions
firebase deploy --only functions

# Deploy Firestore Rules
firebase deploy --only firestore:rules
```

---

## 📁 Code Structure

### Models (`lib/models/`)

**nutrients.dart**

```dart
class Nutrients {
  final String label;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  // JSON serialization
  factory Nutrients.fromJson(Map<String, dynamic> json)
  Map<String, dynamic> toJson()
}
```

**food_item.dart**

```dart
class FoodItem {
  final String id;
  final String label;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final DateTime timestamp;
  final bool isFavorite;
  final String source;  // 'gemini' or 'openfoodfacts'

  // Firestore conversion
  factory FoodItem.fromFirestore(DocumentSnapshot doc)
  Map<String, dynamic> toFirestore()

  // JSON serialization
  factory FoodItem.fromJson(Map<String, dynamic> json)
  Map<String, dynamic> toJson()
}
```

### Services (`lib/services/`)

**firebase_auth_service.dart**

```dart
class FirebaseAuthService {
  // Google Sign-In
  Future<User?> signInWithGoogle()

  // Email/Password Auth
  Future<User?> signInWithEmail(String email, String password)
  Future<User?> createAccountWithEmail(String email, String password, String displayName)

  // Session Management
  Future<void> signOut()
  Future<String?> getIdToken()

  // User Info
  User? get currentUser
  String? getUserId()
  String? getUserEmail()
  Stream<User?> get authStateChanges
}
```

**firestore_service.dart**

```dart
class FirestoreService {
  // CRUD Operations
  Future<void> addFoodItem(String userId, FoodItem item)
  Future<void> updateFoodItem(String userId, FoodItem item)
  Future<void> deleteFoodItem(String userId, String foodId)

  // Queries
  Stream<List<FoodItem>> getTodaysFoods(String userId)
  Stream<List<FoodItem>> getFavoriteFoods(String userId)
  Future<double> getTotalCaloriesByDate(String userId, DateTime date)
  Future<Map<String, double>> getMacrosByDate(String userId, DateTime date)

  // Favorites
  Future<void> toggleFavorite(String userId, String foodId, bool isFavorite)

  // User Profile
  Future<void> saveUserProfile(String userId, Map<String, dynamic> profile)
  Future<Map<String, dynamic>?> getUserProfile(String userId)
}
```

**cloud_function_service.dart**

```dart
class CloudFunctionService {
  // Image Analysis via Gemini
  Future<Nutrients?> analyzeFoodImage(String base64Image, String idToken)

  // Barcode Lookup via Open Food Facts
  Future<Nutrients?> getBarcodeData(String barcode, String idToken)
}
```

### Screens (`lib/screens/`)

| Screen                  | Purpose        | Key Features                           |
| ----------------------- | -------------- | -------------------------------------- |
| `login_screen.dart`     | Authentication | Google Sign-In + Email/Password        |
| `signup_screen.dart`    | Registration   | New user account creation              |
| `home_screen.dart`      | Main Dashboard | Daily stats, food list, real-time sync |
| `scanner_screen.dart`   | Food Input     | Image analysis, barcode scanning       |
| `favorites_screen.dart` | Favorites      | Quick-add frequently eaten foods       |
| `settings_screen.dart`  | Profile        | User info, logout                      |

---

## 🔌 API Reference

### Cloud Functions

#### `POST /analyzeFood`

**Request Headers:**

```
Authorization: Bearer {firebase_id_token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "imageBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
}
```

**Response:**

```json
{
  "label": "Chicken Breast",
  "calories": 165,
  "protein": 31,
  "fat": 3.6,
  "carbs": 0,
  "fiber": 0
}
```

**Implementation:**

1. Verify Firebase ID token
2. Extract user ID from token
3. Call Gemini API with image
4. Parse JSON response
5. Return nutrients

#### `POST /getBarcodeData`

**Request Headers:**

```
Authorization: Bearer {firebase_id_token}
Content-Type: application/json
```

**Request Body:**

```json
{
  "barcode": "4006381333931"
}
```

**Response:**

```json
{
  "label": "Coca-Cola",
  "calories": 42,
  "protein": 0,
  "fat": 0,
  "carbs": 10.6,
  "fiber": 0
}
```

**Implementation:**

1. Verify Firebase ID token
2. Extract user ID from token
3. Call Open Food Facts API
4. Extract nutrition data
5. Return nutrients

---

## 🔄 Development Workflow

### Local Development

```bash
# Start Flutter app in debug mode
cd flutter_app
flutter run -d android

# In another terminal, start Cloud Functions emulator
cd firebase/functions
firebase emulators:start --only functions

# Update cloud_function_service.dart to use localhost
const String _functionUrl = 'http://localhost:5001/kalorientracker/europe-west1';
```

### Code Organization

1. **Models** - Pure data classes, no business logic
2. **Services** - All external API calls (Firebase, Cloud Functions)
3. **Screens** - UI only, use services for data
4. **Utils** - Helper functions

### Best Practices

- ✅ Use Streams for real-time data
- ✅ Handle errors explicitly
- ✅ Validate user input
- ✅ Use try-catch for all async calls
- ✅ Log important events
- ✅ Don't block UI with long operations

---

## 📦 Deployment

### Android Release

```bash
# Create release APK
flutter build apk --release

# Create App Bundle for Play Store
flutter build appbundle --release

# Files
# APK: build/app/outputs/flutter-app.apk
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

### iOS Release

```bash
# Create iOS release build
flutter build ios --release

# Archive in Xcode for App Store
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner -config Release \
  -derivedDataPath build
```

### Cloud Functions Deployment

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy with secrets
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions

# Check deployment
firebase functions:list
```

### Firestore Rules Deployment

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Check rules
firebase firestore:ruleset list
```

---

## 🗄️ Firestore Database Schema

### Collections

```
users/
├── {userId}/
│   ├── foodItems/                    # User's food log
│   │   ├── {docId}
│   │   │   ├── label: string
│   │   │   ├── calories: number
│   │   │   ├── protein: number
│   │   │   ├── fat: number
│   │   │   ├── carbs: number
│   │   │   ├── fiber: number
│   │   │   ├── timestamp: datetime
│   │   │   ├── isFavorite: boolean
│   │   │   └── source: string ('gemini' | 'openfoodfacts')
│   │
│   └── userProfile                  # User's metadata
│       ├── name: string
│       ├── email: string
│       ├── weight: number
│       ├── height: number
│       ├── dailyCalorieGoal: number
│       └── createdAt: datetime
```

### Security Rules

```firestore
match /users/{userId}/foodItems/{document=**} {
  allow read, write: if request.auth.uid == userId;
}

match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}
```

---

## 🐛 Troubleshooting

### Firebase Errors

| Error                            | Cause                | Solution                       |
| -------------------------------- | -------------------- | ------------------------------ |
| `google-services.json not found` | Missing config file  | Download from Firebase Console |
| `Unauthorized` Cloud Function    | Invalid ID token     | Check auth state in app        |
| `Permission denied` Firestore    | Wrong security rules | Verify userId matches auth.uid |

### Flutter Errors

| Error                 | Cause                | Solution                              |
| --------------------- | -------------------- | ------------------------------------- |
| `Plugin not found`    | Missing dependencies | Run `flutter pub get`                 |
| `iOS build fails`     | CocoaPods issue      | `cd ios && pod install --repo-update` |
| `Android build fails` | Gradle issue         | `cd android && ./gradlew clean`       |

### Debugging

```dart
// Enable Firebase logging
FirebaseAuth.instance.authStateChanges().listen((user) {
  print('Auth state: $user');
});

// Log Firestore operations
FirebaseFirestore.instance
  .collection('users')
  .snapshots()
  .listen((snapshot) {
    print('Firestore update: ${snapshot.docs.length} docs');
  });

// Log Cloud Function calls
print('Calling Cloud Function: $url');
```

---

## 📊 Performance Optimization

### Firestore Queries

```dart
// ❌ Bad - Gets all documents
collection('foodItems').snapshots()

// ✅ Good - Only today's items
collection('foodItems')
  .where('timestamp', isGreaterThanOrEqualTo: today)
  .where('timestamp', isLessThan: tomorrow)
  .snapshots()
```

### Image Handling

```dart
// ❌ Bad - Full resolution image
final bytes = await image.readAsBytes();

// ✅ Good - Compressed image
final compressedBytes = await _compressImage(imageBytes);
final base64 = base64Encode(compressedBytes);
```

---

## 🔒 Security Checklist

- [x] API keys on backend only
- [x] Firebase ID tokens for auth
- [x] Firestore security rules
- [x] HTTPS for all calls
- [x] Input validation
- [x] No sensitive data in logs
- [x] No hardcoded secrets

---

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Generative AI](https://ai.google.dev/)
- [Open Food Facts API](https://world.openfoodfacts.org/api)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/start)

---

## 💡 Tips for Developers

1. **Use Firestore Emulator locally** - Test rules without affecting production
2. **Enable debug logs** - Helps identify issues quickly
3. **Test error cases** - Network failures, invalid data, etc.
4. **Monitor Cloud Function costs** - Watch execution logs
5. **Use version control** - Commit frequently, use branches

---

**Questions? Check the code comments or refer to official documentation.**
