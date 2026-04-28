import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/meal_entry.dart';
import '../core/utils/app_logger.dart';

/// OpenRouterService — connects to OpenRouter's free-tier models for
/// text-based nutritional chatbot via the OpenAI-compatible API.
///
/// Vision is NOT supported on the free tier; image recognition stays on
/// Gemini (see [GeminiService]).
class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Primary model — use a capable free model.
  /// Falls back to auto-routing if the free model is unavailable.
  static const String _defaultModel = 'google/gemma-3-27b-it:free';
  static const String _fallbackModel = 'openrouter/auto';

  static const String _appName = 'CalorAI';
  static const String _appUrl = 'https://calor.ai';

  // Singleton
  static final OpenRouterService _instance = OpenRouterService._internal();
  factory OpenRouterService() => _instance;
  OpenRouterService._internal();

  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Build the full system prompt with enriched context.
  String buildSystemPrompt({
    required UserProfile profile,
    required List<MealEntry> recentMeals,
    required List<MealEntry> todaysMeals,
    String conversationMemory = '',
  }) {
    // ── Today's progress ──────────────────────────────────────────
    final todayCalories = todaysMeals.fold<int>(0, (s, m) => s + m.calories);
    final todayProtein = todaysMeals.fold<double>(0, (s, m) => s + m.proteinG);
    final todayCarbs = todaysMeals.fold<double>(0, (s, m) => s + m.carbsG);
    final todayFats = todaysMeals.fold<double>(0, (s, m) => s + m.fatsG);
    final remaining = profile.calorieTarget - todayCalories;

    final macroTargets =
        profile.macroTargets ?? MacroTargets.fromCalories(profile.calorieTarget);

    // ── Weekly stats ──────────────────────────────────────────────
    final weeklyCalories = <int>[];
    final foodFrequency = <String, int>{};
    for (final meal in recentMeals) {
      weeklyCalories.add(meal.calories);
      final name = meal.foodNameEn.toLowerCase();
      foodFrequency[name] = (foodFrequency[name] ?? 0) + 1;
    }
    final avgDailyCalories = weeklyCalories.isEmpty
        ? 0
        : (weeklyCalories.reduce((a, b) => a + b) / 7).round();

    final topFoods = foodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topFoods.take(3).map((e) => '${e.key} (×${e.value})').join(', ');

    // ── BMI ───────────────────────────────────────────────────────
    final heightM = profile.heightCm / 100;
    final bmi = profile.weightKg / (heightM * heightM);
    final bmiCategory = bmi < 18.5
        ? 'underweight'
        : bmi < 25
            ? 'normal'
            : bmi < 30
                ? 'overweight'
                : 'obese';

    // ── Macro balance ─────────────────────────────────────────────
    String macroNote(String name, double current, int target) {
      if (target == 0) return '';
      final pct = (current / target * 100).round();
      if (pct > 120) return '$name is significantly OVER target ($pct%)';
      if (pct > 100) return '$name is slightly over target ($pct%)';
      if (pct < 50) return '$name is very LOW ($pct% of target)';
      return '$name at $pct% of target';
    }

    final proteinNote =
        macroNote('Protein', todayProtein, macroTargets.proteinG);
    final carbsNote = macroNote('Carbs', todayCarbs, macroTargets.carbsG);
    final fatsNote = macroNote('Fats', todayFats, macroTargets.fatsG);

    // ── Meal log (richer than before) ─────────────────────────────
    final mealLog = recentMeals.isEmpty
        ? 'No meals logged recently.'
        : recentMeals.take(15).map((m) {
            return '- ${m.foodNameEn} | ${m.calories} kcal | '
                'P:${m.proteinG.toStringAsFixed(0)}g '
                'C:${m.carbsG.toStringAsFixed(0)}g '
                'F:${m.fatsG.toStringAsFixed(0)}g | '
                '${m.portionLabel} (${m.portionGrams.toStringAsFixed(0)}g) | ${m.date}';
          }).join('\n');

    return '''
You are CalorAI, a friendly and knowledgeable Malaysian nutrition assistant.
You help users track their diet and make healthier food choices, with deep expertise in Malaysian and Southeast Asian cuisine.

═══ USER PROFILE ═══
Name: ${profile.name}
Goal: ${profile.goal.replaceAll('_', ' ')}
Daily calorie target: ${profile.calorieTarget} kcal
Age: ${profile.age} | Sex: ${profile.sex}
Height: ${profile.heightCm} cm | Weight: ${profile.weightKg} kg
BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)
Activity level: ${profile.activityLevel.replaceAll('_', ' ')}

═══ TODAY'S PROGRESS ═══
Calories: $todayCalories / ${profile.calorieTarget} kcal ($remaining remaining)
Protein: ${todayProtein.toStringAsFixed(0)}g / ${macroTargets.proteinG}g — $proteinNote
Carbs: ${todayCarbs.toStringAsFixed(0)}g / ${macroTargets.carbsG}g — $carbsNote
Fats: ${todayFats.toStringAsFixed(0)}g / ${macroTargets.fatsG}g — $fatsNote
Meals logged today: ${todaysMeals.length}

═══ WEEKLY OVERVIEW (7 days) ═══
Average daily intake: $avgDailyCalories kcal
Most eaten foods: ${top3.isEmpty ? 'None' : top3}
Total meals this week: ${recentMeals.length}

═══ RECENT MEALS ═══
$mealLog

═══ GUIDELINES ═══
- Be warm, encouraging, and concise (under 200 words)
- Use emojis sparingly for friendliness
- Reference Malaysian foods specifically (Nasi Lemak, Roti Canai, Laksa, Char Kuey Teow, etc.)
- Always provide calorie estimates when discussing foods
- When suggesting alternatives, consider locally available Malaysian ingredients
- Reference the user's current progress data when relevant (e.g., "You've still got $remaining kcal left today!")
- If the user is consistently over/under on a macro, proactively mention it
- If asked about medical conditions, politely decline and recommend consulting a doctor
- Use simple markdown: **bold** for emphasis, bullet lists with "- " prefix, and line breaks
- NEVER use citation references like [1], [2], [3] or source URLs — the user cannot click them
- NEVER use markdown headers (#, ##, ###) — use **bold text** instead
- Keep formatting clean and readable in a mobile chat bubble

${conversationMemory.isNotEmpty ? conversationMemory : ''}
''';
  }

  /// Sends a chat message via OpenRouter.
  /// Strategy: free model → paid auto-route → Gemini (last resort).
  Future<String> chat({
    required String userMessage,
    required UserProfile profile,
    required List<MealEntry> recentMeals,
    required List<MealEntry> todaysMeals,
    required List<Map<String, String>> history,
    String conversationMemory = '',
    Future<String> Function()? fallbackChat,
  }) async {
    // If no OpenRouter key configured, use fallback immediately
    if (!isConfigured) {
      AppLogger.instance.log('OpenRouter: No API key, using Gemini fallback');
      if (fallbackChat != null) return fallbackChat();
      throw Exception(
          'OpenRouter API key is not configured and no fallback available.');
    }

    final systemPrompt = buildSystemPrompt(
      profile: profile,
      recentMeals: recentMeals,
      todaysMeals: todaysMeals,
      conversationMemory: conversationMemory,
    );

    // Build messages array in OpenAI format
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Add conversation history (last 6 messages)
    final recentHistory =
        history.length > 6 ? history.sublist(history.length - 6) : history;
    for (final msg in recentHistory) {
      final role = msg['role'] == 'model' ? 'assistant' : (msg['role'] ?? 'user');
      messages.add({
        'role': role,
        'content': msg['text'] ?? '',
      });
    }

    // Add current message
    messages.add({'role': 'user', 'content': userMessage});

    // Try free model first, then paid auto-route
    final modelsToTry = [_defaultModel, _fallbackModel];

    for (final model in modelsToTry) {
      try {
        final result = await _callOpenRouter(
          model: model,
          messages: messages,
        );

        if (result != null) {
          history.add({'role': 'user', 'text': userMessage});
          history.add({'role': 'model', 'text': result});
          return result;
        }
      } catch (e) {
        AppLogger.instance.log('OpenRouter model $model failed: $e');
        // Continue to next model
      }
    }

    // All OpenRouter models failed — use Gemini as absolute last resort
    if (fallbackChat != null) {
      AppLogger.instance.log('All OpenRouter models failed, using Gemini');
      return fallbackChat();
    }

    throw Exception(
        'Could not get a response. Please try again in a moment.');
  }

  /// Low-level call to OpenRouter API.
  Future<String?> _callOpenRouter({
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'max_tokens': 1024,
      'temperature': 0.7,
    });

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': _appUrl,
            'X-Title': _appName,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'] as String?;
      if (text != null && text.isNotEmpty) return text;
    }

    final statusCode = response.statusCode;
    AppLogger.instance
        .log('OpenRouter [$model] returned $statusCode: ${response.body.take(200)}');

    if (statusCode == 429) {
      // Rate limited on this model — let caller try next
      throw Exception('Rate limit on $model');
    }

    // Other errors — return null to try next model
    return null;
  }
}

extension _StringTake on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
