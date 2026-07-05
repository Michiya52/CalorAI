import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:calor_ai/providers/profile_provider.dart';
import 'package:calor_ai/providers/meal_provider.dart';
import 'package:calor_ai/providers/chatbot_provider.dart';
import 'package:calor_ai/models/user_profile.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'OPENROUTER_API_KEY=test\nGEMINI_API_KEY=test');
  });
  group('Provider State Cleanup Tests', () {
    test('ProfileProvider clear resets profile and error', () {
      final provider = ProfileProvider();

      final profile = UserProfile(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        heightCm: 170,
        weightKg: 70,
        age: 25,
        sex: 'male',
        activityLevel: 'sedentary',
        goal: 'maintain',
        calorieTarget: 2000,
        isCalorieTargetManual: false,
        isMacroTargetsManual: false,
        createdAt: DateTime.now(),
      );

      provider.setProfile(profile);
      expect(provider.profile, isNotNull);
      expect(provider.profile!.uid, 'test_uid');

      provider.clear();
      expect(provider.profile, isNull);
      expect(provider.error, isNull);
    });

    test('MealProvider clear resets todaysMeals', () {
      final provider = MealProvider();
      expect(provider.todaysMeals, isEmpty);

      provider.clear();
      expect(provider.todaysMeals, isEmpty);
    });

    test('ChatbotProvider clear resets history, messages, and sessions', () {
      final provider = ChatbotProvider();
      expect(provider.messages, isEmpty);
      expect(provider.savedSessions, isEmpty);

      provider.clear();
      expect(provider.messages, isEmpty);
      expect(provider.savedSessions, isEmpty);
    });
  });
}
