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
│   ├── logging/                   # Manual search, Barcode scanner, Camera/Portion UI
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
Represents a logged consumption instance.
- **Properties**:
  - `String id` (UUID v4)
  - `String userId`
  - `String name`
  - `int calories`
  - `double proteinG`, `double carbsG`, `double fatsG`
  - `DateTime timestamp`
  - `String source` ('MyFCD', 'USDA', 'AI Estimate', 'Manual')
  - `String? imageUrl`
- **Methods**:
  - `factory MealEntry.fromJson(Map<String, dynamic> json)`
  - `Map<String, dynamic> toJson()`

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
- **Properties**:
  - `String id`
  - `String userId`
  - `double weightKg`
  - `DateTime date`

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
  - `fetchTodayMeals(String uid)`: Queries Firestore for entries between 00:00 and 23:59 today.
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
  - `Future<List<FoodItem>> searchFoods(String query)`: Uses `fuzzywuzzy` for string matching against local JSON assets (`assets/data/myfcd_full.json`, `assets/data/sgfocos_full.json`) or via REST for USDA.

### `AuthService`
- Wrapper for `FirebaseAuth.instance.signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, and Google Sign-in.

---

## 5. UI & Flow Mappings (`lib/screens/`)

### Logging Flow
1. **Camera/Image Picker** (`logging/camera_screen.dart`): User captures an image.
2. **AI Processing**: Image is sent to `GeminiService`.
3. **Suggestion Selection**: UI displays the 4 `FoodSuggestion` items. User taps one.
4. **Portion Adjustment** (`logging/portion_screen.dart`): A slider (e.g., 0.5x to 2.0x of base portion) dynamically updates `resolvedCalories` and macros on screen.
5. **Save**: Tapping "Log" triggers `MealProvider.addMeal()`.

### Manual Search Flow
1. **Search UI** (`logging/manual_search_screen.dart`): User types a string.
2. **Database Toggle**: A `SegmentedButton` toggles between `regional` (MyFCD/SG) and `usda` (FOSS). *(Note: Open Food Facts was removed)*.
3. **Processing**: Calls `MyfcdService` or `UsdaService`.
4. **Selection & Save**: Transitions to `portion_screen.dart` identical to the Image workflow.

### Chatbot Integration
- **Component** (`chatbot/chatbot_screen.dart`): Implemented as a persistent sheet or full screen.
- **Z-Index Fix**: Triggered via `showModalBottomSheet(useRootNavigator: true)` to ensure it renders above the main `BottomNavigationBar`.

---

## 6. Global Configuration

### `pubspec.yaml` Keys
- State: `provider`, `go_router`
- Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_crashlytics`, `firebase_analytics`, `firebase_messaging`
- AI: `google_generative_ai`
- Utility: `http`, `shared_preferences`, `flutter_dotenv`, `fuzzywuzzy`, `mobile_scanner`, `image_picker`

### Build Config (`android/app/build.gradle.kts`)
- `minSdk = 24`
- MultiDex enabled.

---
*End of Complete Architecture Documentation.*
