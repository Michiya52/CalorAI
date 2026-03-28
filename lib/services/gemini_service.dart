import 'dart:typed_data';
import '../models/food_suggestion.dart';
import '../models/user_profile.dart';
import '../models/meal_entry.dart';

/// GeminiService — currently returns mock data for prototype testing.
/// When ready to connect, replace mock responses with real Gemini API calls.
class GeminiService {

  /// Simulates Gemini Vision food identification.
  /// Returns mock Malaysian food suggestions for testing.
  Future<List<FoodSuggestion>> identifyFoodFromImage(Uint8List imageBytes) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Return mock suggestions for testing
    return [
      const FoodSuggestion(
        rank: 1,
        dishNameEn: 'Nasi Lemak',
        dishNameMy: 'Nasi Lemak',
        mainIngredients: ['coconut rice', 'sambal', 'anchovies', 'peanuts', 'egg'],
        estimatedPortionGrams: 350,
        confidence: 'high',
        cookingMethod: 'steamed rice with coconut milk',
      ),
      const FoodSuggestion(
        rank: 2,
        dishNameEn: 'Nasi Goreng',
        dishNameMy: 'Nasi Goreng',
        mainIngredients: ['fried rice', 'egg', 'vegetables', 'soy sauce'],
        estimatedPortionGrams: 300,
        confidence: 'medium',
        cookingMethod: 'stir-fried',
      ),
      const FoodSuggestion(
        rank: 3,
        dishNameEn: 'Chicken Rice',
        dishNameMy: 'Nasi Ayam',
        mainIngredients: ['steamed rice', 'poached chicken', 'ginger', 'cucumber'],
        estimatedPortionGrams: 400,
        confidence: 'low',
        cookingMethod: 'steamed and poached',
      ),
    ];
  }

  /// Simulates Gemini chatbot response.
  /// Returns context-aware mock responses for testing.
  Future<String> chat({
    required String userMessage,
    required UserProfile profile,
    required List<MealEntry> recentMeals,
    required List<dynamic> history,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final msg = userMessage.toLowerCase();

    if (msg.contains('alternative') || msg.contains('healthier')) {
      return 'Great question! If you\'re looking for a healthier alternative, '
          'try **Nasi Kerabu** (Nasi Kerabu) — it\'s a herb rice dish with '
          'about 350 kcal per serving. It\'s lower in fat than Nasi Lemak '
          'and packed with herbs and vegetables. You could also try **Sup Ayam** '
          '(chicken soup) at around 150 kcal per bowl as a lighter option! 🥗';
    }

    if (msg.contains('meal plan') || msg.contains('plan')) {
      return '**Sample Meal Plan for ${profile.calorieTarget} kcal:**\n\n'
          '🌅 **Breakfast:** Roti Canai with Dhal (~350 kcal)\n'
          '🌞 **Lunch:** Chicken Rice (~550 kcal)\n'
          '🍎 **Snack:** Pisang (banana) (~90 kcal)\n'
          '🌙 **Dinner:** Pan Mee Soup (~400 kcal)\n\n'
          'Total: ~1,390 kcal\n'
          'This leaves room for a Teh Tarik (~100 kcal) or light snack! ☕';
    }

    if (msg.contains('calorie') || msg.contains('kcal')) {
      return 'Based on your profile, your daily target is **${profile.calorieTarget} kcal**. '
          'A bowl of Laksa typically has around 400-500 kcal depending on the coconut milk content. '
          'Asam Laksa is a lighter option at about 300 kcal! 🍜';
    }

    if (msg.contains('medical') || msg.contains('doctor') || msg.contains('diagnosis')) {
      return 'I\'m not qualified to give medical advice. Please consult a '
          'registered dietitian or doctor for medical-related questions. '
          'I\'m happy to help with food choices and nutrition information though! 🏥';
    }

    return 'That\'s a great question! Based on your goal of "${profile.goal.replaceAll('_', ' ')}" '
        'and your ${profile.calorieTarget} kcal daily target, I\'d suggest focusing on '
        'balanced Malaysian meals with plenty of vegetables. Would you like me to suggest '
        'specific dishes or create a meal plan? 😊';
  }
}
