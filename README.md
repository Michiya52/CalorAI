# CalorAI 🥗🤖

An intelligent, AI-powered nutrition and calorie tracking mobile application built with **Flutter**, **Firebase**, and **Google Gemini AI**.

---

## 🌟 Overview

**CalorAI** simplifies meal logging and macro tracking by combining generative AI vision and text processing with verified ground-truth food databases (such as MyFCD). Users can log meals by snapping photos or typing descriptions, receive instant macro breakdowns, track daily targets, and analyze nutrition trends over time.

---

## ✨ Features

- 📸 **AI Meal Recognition**: Log food via photo or text input powered by Google Gemini AI.
- 🇲🇾 **Multilingual Food Matching**: Intelligent cross-referencing supporting English and Malay dish names against local food composition databases.
- 📊 **Nutrition Dashboard**: Visual breakdown of calories, proteins, carbs, and fats using dynamic charts (`fl_chart`).
- 🔍 **Barcode & Food Scanner**: Quick lookup with integrated scanner (`mobile_scanner`).
- 🔔 **Smart Reminders**: Local scheduled notifications for regular meal logging (`flutter_local_notifications`).
- ☁️ **Cloud Synchronization**: Secure authentication and real-time cloud data storage via Firebase (Firestore & Auth).

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: Flutter 3.6+ (Dart 3.6+)
- **State Management**: Provider
- **Backend & Database**: Firebase Core, Auth, Firestore, Crashlytics, Analytics
- **AI Engine**: `google_generative_ai` (Gemini API)
- **UI Components**: Material Design 3, `google_fonts`, `fl_chart`, `cached_network_image`
- **Device Capabilities**: `image_picker`, `mobile_scanner`, `flutter_local_notifications`

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.6.0`
- Dart SDK `^3.6.0`
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/CalorAI.git
   cd CalorAI/CalorAI
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the root of `CalorAI/` with your API keys:
   ```env
   GEMINI_API_KEY=your_gemini_api_key
   FIREBASE_PROJECT_ID=your_firebase_project_id
   FIREBASE_API_KEY=your_firebase_api_key
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📦 Building for Production

To build a release APK for Android:

```bash
flutter build apk --release
```

The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📂 Project Structure

```text
CalorAI/
├── android/               # Android native configurations
├── ios/                   # iOS native configurations
├── lib/
│   ├── main.dart          # Application entry point
│   ├── models/            # Data models & schemas
│   ├── providers/         # State management providers
│   ├── screens/           # UI views & screens
│   ├── services/          # Firebase, AI & MyFCD services
│   └── widgets/           # Reusable UI components
├── assets/                # App icons, fonts & offline datasets
├── pubspec.yaml           # Flutter dependencies & configurations
└── README.md
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
