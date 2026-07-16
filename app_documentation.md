# CalorAI Technical Documentation

Welcome to the technical documentation for **CalorAI**, a Flutter-based nutritional tracking application specifically optimized for Malaysian and Southeast Asian cuisine. This document outlines the application's architecture, data models, state management, and core services.

## Architecture Overview
CalorAI is built using **Flutter** and **Dart**, utilizing a robust provider-based state management architecture. The app uses **Firebase** for backend services (Authentication, Firestore Database, Analytics, Crashlytics) and integrates with both **Google Gemini** and **OpenRouter** for AI-powered features.

### Core Stack
- **Framework**: Flutter (Dart)
- **State Management**: `provider` pattern
- **Routing**: `go_router` for deep linking and declarative navigation
- **Backend**: Firebase (Auth, Firestore, Crashlytics, Analytics)
- **AI Models**: Google Gemini Vision (image analysis), OpenRouter (Gemma 3 for conversational AI)
- **Food Databases**: MyFCD (Malaysian Food Composition Database), SG Focos, USDA (FOSS)

### Routing Table
The application utilizes `go_router` in `lib/core/router/app_router.dart` for declarative routing.

| Route Path | Screen / Widget | Type |
| :--- | :--- | :--- |
| `/login` | `LoginScreen` | Standalone |
| `/register` | `RegisterScreen` | Standalone |
| `/setup` | `ProfileSetupScreen` | Standalone |
| `/home` | `DashboardScreen` | ShellRoute (Bottom Nav) |
| `/history` | `MealHistoryScreen` | ShellRoute (Bottom Nav) |
| `/chatbot` | `ChatbotScreen` | ShellRoute (Bottom Nav) |
| `/profile` | `ProfileScreen` | ShellRoute (Bottom Nav) |
| `/log/photo` | `PhotoLoggingScreen` | Standalone Push |
| `/log/suggestions` | `SuggestionCardsScreen` | Standalone Push |
| `/log/portion` | `PortionSelectionScreen` | Standalone Push |
| `/log/search` | `ManualSearchScreen` | Standalone Push |
| `/log/barcode` | `BarcodeScannerScreen` | Standalone Push |
| `/log/create-meal` | `MealCreatorScreen` | Standalone Push |
| `/meal-detail` | `MealDetailScreen` | Standalone Push |

---

## Directory Structure
The application follows a feature-by-layer architectural pattern:

```text
lib/
├── core/             # Core utilities, constants (colors, typography), extensions
├── models/           # Data models (FoodItem, MealEntry, UserProfile, etc.)
├── providers/        # State management (ProfileProvider, MealProvider, etc.)
├── screens/          # UI layer, grouped by feature (logging, dashboard, etc.)
├── services/         # API integrations, Firebase logic, AI communication
├── utils/            # Helper functions (logging, formatting)
├── widgets/          # Reusable UI components
├── theme.dart        # Global styling, light/dark mode definitions
└── main.dart         # Entry point, Firebase init, provider setup
```

---

## Core Services

### 1. AI & Machine Learning Services
The AI layer is highly optimized for accuracy and context-awareness.

- **`gemini_service.dart`**: Handles multimodal tasks. It uses **Gemini Vision** to identify foods from user-uploaded images. The prompt explicitly instructs the model to estimate calories and macros directly in its response based on the visible portion, rather than relying exclusively on database cross-referencing. It also serves as the fallback conversational chatbot.
- **`openrouter_service.dart`**: The primary conversational engine. It communicates with OpenRouter (defaulting to a free-tier model like `google/gemma-3-27b-it:free`). It generates responses based on the user's daily progress, recent meals, and a highly detailed prompt optimized for realistic calorie estimations and Malaysian culinary nuances.

> [!IMPORTANT]
> **Prompt Accuracy**: Both AI services prioritize accuracy over false precision. They are instructed to ask clarifying questions if key calorie drivers (like oil, sugar, or portion sizes) are missing, and to provide estimate ranges rather than exact numbers when uncertain.

### 2. Database & API Services
- **`firestore_service.dart`**: Manages all CRUD operations with Firebase Firestore. It handles user profiles, meal logs, and custom food entries.
- **`myfcd_service.dart` & `usda_service.dart`**: Handle querying and parsing data from the regional (MyFCD) and global (USDA) food composition databases.
- **`auth_service.dart`**: Wrapper around Firebase Authentication (Email/Password, Google Sign-in).

---

## State Management (Providers)

CalorAI uses the `provider` package to manage application state efficiently. 

- **`auth_provider.dart`**: Listens to Firebase Auth state changes and manages user sessions.
- **`profile_provider.dart`**: Holds the current user's `UserProfile` (goals, macro targets, BMR, activity level). Automatically recalculates targets when profile data changes.
- **`meal_provider.dart`**: Caches and manages the user's daily `MealEntry` logs. It queries Firestore for "today's meals" by filtering against a stored `date` string (e.g., `YYYY-MM-DD`) rather than a timestamp range. It calculates daily macro summaries, tracks streaks, and handles offline caching.
- **`chatbot_provider.dart`**: Manages the conversational state of the AI assistant. It maintains the chat history, injects long-term memory into system prompts to provide continuity, and handles loading states during API calls.
- **`theme_provider.dart`**: Handles the toggle between light, dark, and system default themes.

> [!NOTE]
> State clearing (`clear()` methods) is implemented across all providers and is triggered upon user logout to ensure sensitive health data doesn't leak between sessions.

---

## Data Models

### `UserProfile`
Stores the user's biometric data and goals.
- `id`: String (Firebase UID)
- `name`, `age`, `sex`, `heightCm`, `weightKg`
- `goal`: Enum (lose_weight, maintain, gain_muscle)
- `activityLevel`: Enum
- `calorieTarget`: Integer
- `macroTargets`: Nested object mapping protein/carbs/fats to gram values.

### `MealEntry`
Represents a logged meal or food item.
- `id`: String (UUID)
- `userId`: String
- `name`: String
- `calories`: Integer
- `proteinG`, `carbsG`, `fatsG`: Doubles
- `timestamp`: DateTime
- `source`: String (e.g., 'MyFCD', 'USDA', 'AI Estimate', 'Manual')
- `imageDeleted`: bool (Always `true`. Confirming that the identification photo is immediately dropped from memory and never persisted).

### `WeightLog`
Tracks historical weight changes over time.
- **Status**: The model, Firestore sub-collection, and service methods exist, but **no frontend UI currently uses them**. This is a known unimplemented feature gap.

### `FoodItem` & `FoodSuggestion`
- `FoodItem`: Represents a raw database entry from MyFCD or USDA.
- `FoodSuggestion`: A wrapper used by the AI when suggesting food matches from an image. Includes confidence scores and portion estimates.

---

## Key Features & Workflows

### Image-based Food Logging
1. User takes a photo or uploads an image via `image_picker`.
2. Image is passed to `GeminiService.identifyFoodFromImage`.
3. Gemini returns a strict JSON array of the top 4 most likely dishes, including estimated portions, confidence scores, and **direct macro/calorie estimates based on the image**.
4. User selects the correct dish, adjusts the portion size (the `ConfidenceBadge` dynamically reflects the AI's confidence level color logic), and saves it.
5. The entry is saved via `MealProvider`, which syncs to Firestore.
6. The user can view the saved item in the `MealDetailScreen` (`/meal-detail`).

### Composite Meal Builder / Meal Creator
A feature allowing users to assemble custom dishes from raw ingredients or branded products.
1. User navigates to `/log/create-meal` (`MealCreatorScreen`).
2. User searches and adds individual ingredients via `ingredient_library_browser.dart`.
3. Ingredients are rendered as `MealIngredientTile` widgets.
4. User scales the individual weights of each ingredient.
5. The combined macros are aggregated, and the entire creation is saved as a single `MealEntry` (containing a nested list of `IngredientDetail` objects).

### Conversational Chatbot
1. User opens the Chatbot drawer (`showModalBottomSheet` with `useRootNavigator: true` to prevent UI clipping).
2. The `ChatbotProvider` gathers the user's recent meals, daily macro progress, and past conversation memory.
3. This context is injected into the system prompt.
4. `OpenRouterService` streams the response back to the UI.

### Barcode & Manual Search
- Users can scan barcodes via `mobile_scanner`. The app queries the FOSS USDA database. (Open Food Facts was previously integrated but has been removed to streamline the experience).
- Manual search queries the local/regional JSON files (MyFCD/SG) and the USDA database via fuzzy matching.

---

## UI Components & Logic

- **Caloric Density Indicator**: Foods are visually tagged with a Low, Med, or High density label based on their kcal per gram logic housed in `core/constants/app_colors.dart` (`densityColor` and `densityLabel`).
- **AI Confidence Badge**: AI suggestions include a `ConfidenceBadge` widget that utilizes `confidenceColor` logic (green for high, yellow for medium, red for low).

---

## Testing

The application includes basic automated testing setups:
- `test/registration_flow_test.dart`: Contains unit tests validating Provider state cleanup behavior across `ProfileProvider`, `MealProvider`, and `ChatbotProvider`.
- `test/widget_test.dart`: The default Flutter initialization test.
- `integration_test/monkey_test.dart`: An integration test designed to bypass authentication for UI monkey testing.

---

## Deployment & Build

### Environment Setup
To run the project locally, a `.env` file must be created at the project root with the following keys:
- `GEMINI_API_KEY`
- `USDA_API_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_API_KEY`
- `FIREBASE_ANDROID_API_KEY`
- `FIREBASE_IOS_API_KEY`
- `OPENROUTER_API_KEY`

### Configuration
- Firebase configurations are handled via standard Firebase initialization (`firebase_options.dart`).
- **Android**: Requires `minSdk = 26` (verified in `build.gradle.kts`).
- **iOS**: Minimum deployment target is `13.0` (verified in `project.pbxproj`).
- **Web/iOS**: Fully supported. (Note: Firebase Crashlytics and Messaging are guarded with `!kIsWeb` to prevent initialization crashes on Flutter Web).
- **Localization**: The application UI is completely English-only, though Malay language strings inherently exist within the regional food databases.
