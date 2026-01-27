# 🥗 KalorienTracker

**AI-powered calorie tracking for Android & iPhone. Completely free. $0/month.**

Analyze food with AI, scan barcodes, track nutrition in real-time. Sign up with Google or Email.

## ✨ Features

- 🤖 **AI Image Analysis** - Photo → Gemini AI → Nutrition extracted automatically
- 📊 **Barcode Scanning** - Scan EAN/UPC codes for instant nutrition data
- 📱 **Cross-Platform** - Android & iPhone from single Flutter codebase
- 🔐 **Dual Auth** - Google Sign-In or Email/Password
- ☁️ **Cloud Sync** - Firestore-backed, works across all devices
- 💰 **Free Forever** - $0/month using free tier APIs
- 🔒 **Privacy First** - No tracking, no ads, no data sales

## 🚀 Quick Start

### Prerequisites

- Flutter 3.0+
- Firebase account (free)
- Google Cloud Project

### Setup (5 minutes)

1. **Firebase Setup**

   ```bash
   # Create Firebase project at firebase.google.com
   # Enable: Firestore, Authentication (Google + Email), Cloud Functions
   # Get Gemini API key from Google Cloud Console
   ```

2. **Configure App**

   ```bash
   cd flutter_app
   flutter pub get
   # Edit lib/firebase_options.dart with your config
   ```

3. **Deploy Cloud Functions**

   ```bash
   cd firebase/functions
   npm install
   firebase functions:secrets:set GEMINI_API_KEY
   firebase deploy --only functions
   ```

4. **Run**
   ```bash
   flutter run -d android    # or -d ios
   ```

## 📁 Project Structure

```
flutter_app/                    # Flutter Code (Android + iPhone)
├── lib/
│   ├── models/               # Data classes
│   ├── services/             # Firebase, Firestore, Cloud Functions
│   ├── screens/              # UI (Login, Home, Scanner, etc)
│   └── main.dart
├── pubspec.yaml
├── android/
└── ios/

firebase/functions/            # Cloud Functions Backend
├── index.js                  # analyzeFood, getBarcodeData
└── package.json

firebase/firestore.rules       # Database Security
```

## 🔐 Security

- API keys stored only on Cloud Functions backend
- Per-user data isolation via Firestore Security Rules
- Firebase ID tokens for API authorization
- HTTPS for all communications

## 💻 Tech Stack

**Frontend**

- Flutter 3.0+ (Dart)
- Firebase Auth, Firestore
- Image Picker, ML Kit Barcode Scanner

**Backend**

- Cloud Functions (Node.js)
- Firebase Firestore

**APIs**

- Google Generative AI (Gemini)
- Open Food Facts (Barcode data)

## 📊 Cost Analysis

| Service         | Free Tier      | Status       |
| --------------- | -------------- | ------------ |
| Firebase Auth   | Unlimited      | ✅ $0        |
| Cloud Firestore | 50k reads/day  | ✅ $0        |
| Cloud Functions | 2M calls/month | ✅ $0        |
| Gemini API      | 1500 calls/day | ✅ $0        |
| **Total**       |                | **$0/month** |

## 📖 Documentation

- **[DEVELOPER.md](DEVELOPER.md)** - Complete technical guide for developers
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Detailed setup instructions
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture & design

## 🤝 Contributing

This is a personal project. Feel free to fork and customize!

## 📄 License

MIT License - Feel free to use as you wish.

## 🎯 Features Coming Soon

- [ ] Meal plans
- [ ] Workout tracking
- [ ] Weight progress charts
- [ ] Offline mode with sync
- [ ] Password reset

---

**Made with ❤️ for free calorie tracking**
