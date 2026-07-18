# CalorAI Complete System Architecture & Repository Data

This document serves as an exhaustive extraction of the CalorAI application's architecture, data models, state management, and service layers. It is designed to provide complete context for generating class diagrams, activity diagrams, and understanding the codebase down to the method and property level.

---

## 1. Directory Structure

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # Primary color definitions (green/black themes)
│   │   └── app_typography.dart    # Text styles
│   └── utils/
│       ├── app_logger.dart        # Custom debug logging
│       └── formatters.dart        # Number/Date formatting extensions
├── models/                        # Core data structures (See Section 2)
├── providers/                     # ChangeNotifiers for state (See Section 3)
├── screens/                       # UI Views
│   ├── dashboard/                 # Home screen, progress rings
│   ├── logging/                   # Manual search, Barcode scanner, Camera/Portion UI, Composite meal creator
│   ├── chatbot/                   # Chat interface
│   ├── profile/                   # Settings, Goal adjustment
│   └── onboarding/                # Initial setup flow
├── services/                      # API/Firebase interactions (See Section 4)
├── widgets/                       # Reusable UI components
├── theme.dart                     # Global MaterialApp theme configuration
└── main.dart                      # Entry point, Firebase initialization, Provider injection
```

---

## 2. Data Models (`lib/models/`)

### `UserProfile` (`user_profile.dart`)
Represents the authenticated user's physical profile and nutritional targets.
- **Properties**:
  - `String id` (Firebase UID)
  - `String name`
  - `int age`
  - `String sex` ('male' or 'female')
  - `int heightCm`
  - `double weightKg`
  - `String goal` ('lose_weight', 'maintain', 'gain_muscle')
  - `String activityLevel` ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active')
  - `int calorieTarget` (Daily limit calculated via Mifflin-St Jeor)
  - `MacroTargets macroTargets` (Nested object: `proteinG`, `carbsG`, `fatsG`)
  - `DateTime createdAt`
- **Methods**:
  - `factory UserProfile.fromJson(Map<String, dynamic> json)`
  - `Map<String, dynamic> toJson()`
  - `UserProfile copyWith(...)`

### `MealEntry` (`meal_entry.dart`)
Represents a logged consumption instance. Supports standard items or complex recipes with multiple sub-ingredients.
- **Properties**:
  - `String id` (UUID v4)
  - `String userId`
  - `String name`
  - `int calories`
  - `double proteinG`, `double carbsG`, `double fatsG`
  - `DateTime timestamp`
  - `String source` ('MyFCD', 'USDA', 'AI Estimate', 'Manual')
  - `bool imageDeleted` (Always true. The identification photo is never persisted to disk or Firebase Storage.)
  - `List<IngredientDetail>? ingredients` (Nested details for composite custom recipes)
- **Methods**:
  - `factory MealEntry.fromJson(Map<String, dynamic> json)`
  - `Map<String, dynamic> toJson()`

### `IngredientDetail` (`meal_entry.dart` / `ingredient_detail.dart`)
Nested inside `MealEntry` for custom homecooked recipes via the Meal Creator.
- **Properties**: Contains scaling factors, names, and macro fractions tied back to a base `FoodItem`.

### `FoodItem` (`food_item.dart`)
Represents a raw entry from a food composition database (MyFCD/USDA).
- **Properties**:
  - `String id`
  - `String nameEn`, `String nameMy`
  - `String foodGroup`
  - `double caloriesPer100g`, `double proteinPer100g`, `double carbsPer100g`, `double fatsPer100g`
  - `double sodiumPer100g`, `double sugarPer100g`
  - `List<String> ingredients`
  - `PortionSizes portionSizes` (Nested object: `smallGrams`, `mediumGrams`, `largeGrams`)
  - `String source`
  - `String myfcdCode`

### `FoodSuggestion` (`food_suggestion.dart`)
Wrapper used primarily for AI image identification results.
- **Properties**:
  - `int rank`
  - `String dishNameEn`, `String dishNameMy`
  - `List<String> mainIngredients`
  - `double estimatedPortionGrams`
  - `String confidence` ('high', 'medium', 'low')
  - `int? confidencePercent`
  - `String cookingMethod`
  - `String? visualEvidence`
  - `FoodItem? myfcdMatch`
  - `int resolvedCalories`
  - `double resolvedProteinG`, `double resolvedCarbsG`, `double resolvedFatsG`
  - `String source`

### `WeightLog` (`weight_log.dart`)
Tracks historical weight changes over time.
- **Status Gap**: The data model and Firestore operations exist in the backend layer, but no active frontend UI integrates or uses them currently. 

---

## 3. State Management Layer (`lib/providers/`)

CalorAI uses `ChangeNotifier` combined with `provider` for global state.

### `ProfileProvider`
- **Dependencies**: `FirestoreService`, `AuthService`.
- **State**: `UserProfile? _profile`, `bool _isLoading`.
- **Key Methods**:
  - `fetchProfile(String uid)`: Reads from Firestore.
  - `updateProfile(...)`: Modifies goals/weight, recalculates BMR and macros, saves to Firestore, calls `notifyListeners()`.
  - `clear()`: Resets state on logout.

### `MealProvider`
- **Dependencies**: `FirestoreService`.
- **State**: `List<MealEntry> _todayMeals`, `bool _isLoading`.
- **Key Properties (Getters)**:
  - `int get totalCaloriesToday`
  - `double get totalProteinToday`, `double get totalCarbsToday`, `double get totalFatsToday`
- **Key Methods**:
  - `fetchTodayMeals(String uid)`: Queries Firestore for entries for the current day.
  - `addMeal(MealEntry meal)`: Saves to Firestore and updates local list.
  - `deleteMeal(String mealId)`: Removes from Firestore and local list.
  - `clear()`: Resets state on logout.

### `ChatbotProvider`
- **Dependencies**: `OpenRouterService`, `SharedPreferences` (for local chat persistence).
- **State**: `List<ChatSession> _savedSessions`, `List<ChatMessage> _currentMessages`, `bool _isTyping`.
- **Key Methods**:
  - `sendMessage(String text, UserProfile profile, MealProvider mealProv)`: 
    1. Appends user message.
    2. Compiles daily macro context + memory.
    3. Streams response from `OpenRouterService`.
  - `clear()`: Clears chat state on logout.

### `AuthProvider`
- **Dependencies**: `AuthService`.
- **State**: `User? _user`, `bool _isLoading`.
- **Key Methods**:
  - Listens to `FirebaseAuth.instance.authStateChanges()`.
  - Maps to routing logic (e.g., redirecting unauthenticated users to Login).

---

## 4. Service Layer (`lib/services/`)

### `FirestoreService`
Centralized Firebase database interactions.
- **Collections**: `users`, `meals`, `weight_logs`.
- **Key Methods**:
  - `Future<void> saveUserProfile(UserProfile profile)`
  - `Future<UserProfile?> getUserProfile(String uid)`
  - `Future<void> addMealEntry(MealEntry entry)`
  - `Future<List<MealEntry>> getMealsForDateRange(String uid, DateTime start, DateTime end)`

### `GeminiService`
Handles multimodal AI vision tasks via `google_generative_ai` SDK.
- **Model used**: `gemini-2.5-flash`.
- **Key Methods**:
  - `Future<List<FoodSuggestion>> identifyFoodFromImage(Uint8List imageBytes)`: 
    - Takes image bytes.
    - Sends an accuracy-optimized prompt forcing the AI to use strictly visible evidence.
    - Returns exactly 4 `FoodSuggestion` objects parsed from a JSON array response.
  - `Future<String> chat(...)`: Fallback text chat service if OpenRouter fails.

### `OpenRouterService`
Handles standard text-based conversational AI.
- **Model used**: `google/gemma-3-27b-it:free`.
- **Key Methods**:
  - `Stream<String> streamChat(...)`: Uses REST `http` calls to stream SSE (Server-Sent Events) chunks.
  - `String buildSystemPrompt(...)`: Injects detailed accuracy rules, missing detail protocols, user biometrics, and today's macro intake.

### `MyfcdService` & `UsdaService`
Food composition database handlers.
- **Key Methods**:
  - `Future<List<FoodItem>> searchFoods(String query)`: Uses `fuzzywuzzy` for string matching.

---

## 5. UI & Flow Mappings (`lib/screens/`)

### Image-based Food Logging Flow
1. **Camera/Image Picker** (`logging/camera_screen.dart`): User captures an image.
2. **AI Processing**: Image is sent to `GeminiService`.
3. **Suggestion Selection**: UI displays 4 `FoodSuggestion` items. User taps one.
4. **Portion Adjustment** (`logging/portion_screen.dart`): A slider scales `resolvedCalories` and macros. Density logic (`core/constants/app_colors.dart`) displays Low/Med/High UI indicators.
5. **Save**: Tapping "Log" triggers `MealProvider.addMeal()`. The created meal can then be viewed on `MealDetailScreen`.

### Composite Meal Builder Flow
1. **Meal Creator UI** (`logging/meal_creator_screen.dart`): Navigates to a "kitchen workspace".
2. **Ingredient Addition**: The user browses `ingredient_library_browser.dart` and adds items, rendered as `meal_ingredient_tile.dart` components.
3. **Portion Scaling**: Each ingredient's individual weight is modified, which recalculates the composite total.
4. **Save**: The aggregated recipe is saved as a single `MealEntry` encapsulating `IngredientDetail`s.

### Manual Search Flow
1. **Search UI** (`logging/manual_search_screen.dart`): User types a string.
2. **Database Toggle**: Toggles between `regional` and `usda`. 
3. **Processing**: Calls Firestore or the USDA API.
4. **Selection & Save**: Transitions to `portion_screen.dart`.

### Chatbot Integration
- **Component** (`chatbot/chatbot_screen.dart`): Showcased as a modal bottom sheet.
- **Z-Index Fix**: Triggered via `showModalBottomSheet(useRootNavigator: true)` to ensure it renders above the main `BottomNavigationBar`.

---

## 6. Routing Table (`lib/core/router/app_router.dart`)

| Route | View |
| :--- | :--- |
| `/login` | `LoginScreen` |
| `/register` | `RegisterScreen` |
| `/setup` | `ProfileSetupScreen` |
| `/home` | `DashboardScreen` (ShellRoute child) |
| `/history` | `MealHistoryScreen` (ShellRoute child) |
| `/chatbot` | `ChatbotScreen` (ShellRoute child) |
| `/profile` | `ProfileScreen` (ShellRoute child) |
| `/log/photo` | `PhotoLoggingScreen` |
| `/log/suggestions` | `SuggestionCardsScreen` |
| `/log/portion` | `PortionSelectionScreen` |
| `/log/search` | `ManualSearchScreen` |
| `/log/barcode` | `BarcodeScannerScreen` |
| `/log/create-meal` | `MealCreatorScreen` |
| `/meal-detail` | `MealDetailScreen` |

---

## 7. Data Access & Security

The Firebase Firestore instance is protected by Security Rules (`firestore.rules`). 
- User Profiles, Meals, and Weight Logs are strictly scoped to the `request.auth.uid`.
- **Global `/foods` Collection:** Retired. Client writes are denied (`allow write: if false;`); reads remain open but nothing in the app queries it.

### Food Data Workflow
Startup seeding has been removed (`lib/utils/seed_data.dart` is a stub). All food data ships as a single bundled asset, `assets/data/myfcd_full.json` (~2,000 entries), generated offline by `tool/merge_foods.py`, which merges MyFCD (1997/Current/Industry), SGFOCOS 2025, the "backed" USDA/MY sets, and a curated additions list; it cleans names, normalizes `foodGroup` to human-readable categories, dedupes by name with curated data winning, and rebuilds `searchTerms`. Search (`FirestoreService.searchFoods`) and the meal-creator ingredient library both read this asset — no Firestore involved.

---

## 8. Global Configuration

### `pubspec.yaml` & `main.dart` Setup
- **State/UI**: `provider`, `go_router`
- **Firebase Core**: `firebase_core`, `firebase_auth`, `cloud_firestore`
- **Firebase Telemetry**: `firebase_crashlytics`, `firebase_performance`. Both are initialized globally with `recordFlutterFatalError` and `setPerformanceCollectionEnabled(true)`. No custom traces exist.
- **Firebase Security/Config**: 
  - `firebase_remote_config` is used in `main.dart` to fetch remote values for `ai_confidence_threshold` and `maintenance_mode`.
  - `firebase_app_check` is declared in `pubspec.yaml` but its activation code in `main.dart` is currently commented out. 
- **AI**: `google_generative_ai`

### Build Config
- **Android (`android/app/build.gradle.kts`)**: `minSdk = 26`, MultiDex enabled.
- **iOS (`ios/Runner.xcodeproj`)**: `IPHONEOS_DEPLOYMENT_TARGET = 13.0`.

---

## 9. Known Technical Limitations
- **Weight Tracking UI**: Full backend logic is present for `WeightLog`, but there is no UI element connected to read or write this data.
- **Food DB Write Rules**: As outlined in Section 7, the `firestore.rules` for `/foods` allow write operations for any authenticated user.
- **App Check Inactive**: App Check is included as a dependency but initialization is disabled. 

---
*End of Complete Architecture Documentation.*
