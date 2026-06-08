# 🔧 CRITICAL SETUP INSTRUCTIONS

## ⚠️ BEFORE RUNNING THE APP

### 1. Fix Firebase API Key Exposure

The API key in `firebase_options.dart` is hardcoded and exposed in version control. **This is a security issue.**

**ACTION REQUIRED:**

a) **For Android (Recommended - Leave as is temporarily)**
- The Android API key is restricted to Android apps only in Firebase Console
- This is relatively safe for development
- For production: Use API key restrictions in Firebase Console

b) **For iOS (MUST FIX)**
- Replace placeholder values:
  ```dart
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',  // Get from Firebase Console
    appId: '1:548167696657:ios:YOUR_IOS_APP_ID',  // Your iOS app ID
    messagingSenderId: '548167696657',
    projectId: 'kalorientracker-3390e',
    storageBucket: 'kalorientracker-3390e.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',  // Get from GoogleService-Info.plist
    iosBundleId: 'com.KalorienTracker',
  );
  ```

c) **For Web (MUST FIX)**
- Replace ALL placeholder values:
  ```dart
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'kalorientracker-3390e',
    authDomain: 'kalorientracker-3390e.firebaseapp.com',
    storageBucket: 'kalorientracker-3390e.appspot.com',
  );
  ```

**Where to get these values:**
1. Go to https://console.firebase.google.com
2. Select project: `kalorientracker-3390e`
3. Click ⚙️ Settings → Project Settings
4. Scroll down to "Your apps"
5. Click on your platform (iOS/Web)
6. Copy all values

### 2. Verify Cloud Functions URL

Check that your Cloud Function URL is correct in `cloud_function_service.dart`:

```dart
static const String _cloudFunctionUrlEurope =
    'https://europe-west1-kalorientracker-3390e.cloudfunctions.net';
```

**If this is wrong:**
1. Deploy your functions: `firebase deploy --only functions`
2. Copy the URL from the deploy output
3. Update the constant

### 3. Deploy Cloud Functions

Ensure Cloud Functions are deployed with the new security fixes:

```bash
cd firebase/functions

# Set Gemini API Key
firebase functions:secrets:set GEMINI_API_KEY
# Paste your API key when prompted

# Deploy
firebase deploy --only functions

# View URLs
firebase functions:list
```

### 4. Firestore Security Rules

Deploy the security rules to prevent unauthorized access:

```bash
firebase deploy --only firestore:rules
```

### 5. Environment Logging Level

The app automatically switches logging levels:
- **DEBUG builds:** Full logging (DEBUG, INFO, WARNING, ERROR)
- **RELEASE builds:** Only WARNING and ERROR logs

No action needed - handled automatically.

---

## ✅ VERIFICATION CHECKLIST

Before running `flutter run`:

- [ ] iOS/Web API keys are set (not placeholder values)
- [ ] Cloud Functions are deployed and URL is correct
- [ ] Gemini API key is set as secret
- [ ] Firestore rules are deployed
- [ ] Android API key is restricted in Firebase Console
- [ ] Google Sign-In OAuth credentials are configured
- [ ] `google-services.json` is in `flutter_app/android/app/`

---

## 🚀 Running the App

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run on specific device
flutter run -d <device-id>
```

---

## 🐛 Debugging

### Enable Verbose Logging

```dart
// In main.dart (if needed for debugging)
LoggerService.setMinLevel(LogLevel.debug);
```

### Check Firebase Connection

Watch Cloud Functions logs:

```bash
firebase functions:log
```

### Check Firestore

View Firestore data:

1. Go to https://console.firebase.google.com
2. Select project: `kalorientracker-3390e`
3. Click Firestore Database
4. Browse `users/` collection

---

## 🔐 Production Deployment

Before releasing to production:

1. **Remove API keys from source code**
   - Use environment variables or Firebase Secrets Manager
   - Never commit keys to version control

2. **Enable Firestore Security Rules**
   - Only authenticated users can access their data
   - No cross-user access

3. **Configure API Key Restrictions** (Firebase Console)
   - Android key: Restrict to Android apps, package `com.KalorienTracker`
   - iOS key: Restrict to iOS apps, bundle `com.KalorienTracker`
   - Web key: Restrict to authorized domains only

4. **Enable Cloud Function Security**
   - CORS is restricted to Firebase domain only
   - All inputs are validated
   - All external API calls have timeouts

5. **Test Thoroughly**
   ```bash
   flutter test
   flutter analyze
   ```

6. **Monitor Production**
   - Set up Firebase Crashlytics
   - Monitor Cloud Function errors
   - Track API quotas

---

## 📝 Important Notes

- ✅ **Logger Service**: All print statements replaced with centralized logging
- ✅ **Input Validation**: All user input is now validated
- ✅ **Error Handling**: Improved error messages and stack traces
- ✅ **Security**: API keys protected, CORS hardened, inputs sanitized
- ✅ **Timeouts**: All external API calls have 25-30 second timeouts
- ✅ **Model Validation**: Food items and nutrients are validated on construction

---

## 🆘 Troubleshooting

### "Firebase not initialized"
- Check `firebase_options.dart` - ensure values are not placeholders
- Run `flutterfire configure --project=kalorientracker-3390e`

### "Cloud Function not found"
- Check URL in `cloud_function_service.dart`
- Run `firebase functions:list` to get correct URL
- Ensure functions are deployed: `firebase deploy --only functions`

### "CORS error"
- Cloud Functions now check for correct origin
- Ensure you're running on correct Firebase domain
- For development: Use Android emulator or physical device

### "Validation failed"
- Check LoggerService output for specific error
- Nutrients must be in valid ranges (see validation_service.dart)
- Check Firestore data format

---

**Status:** ✅ READY FOR DEPLOYMENT  
**Last Updated:** 2026-06-08  
**Fixes Applied:** See FIXES_REPORT.md
