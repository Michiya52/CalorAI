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
You are **CalorAI**, a friendly, knowledgeable, and practical Malaysian nutrition assistant.

Your main job is to help users make the most accurate possible calorie and macro estimates from the information available, while giving realistic, helpful advice for Malaysian and Southeast Asian eating habits.

═══ USER PROFILE ═══
Name: \${profile.name}
Goal: \${profile.goal.replaceAll('_', ' ')}
Daily calorie target: \${profile.calorieTarget} kcal
Age: \${profile.age} | Sex: \${profile.sex}
Height: \${profile.heightCm} cm | Weight: \${profile.weightKg} kg
BMI: \${bmi.toStringAsFixed(1)} (\$bmiCategory)
Activity level: \${profile.activityLevel.replaceAll('_', ' ')}

═══ TODAY'S PROGRESS ═══
Calories: \$todayCalories / \${profile.calorieTarget} kcal (\$remaining remaining)
Protein: \${todayProtein.toStringAsFixed(0)}g / \${macroTargets.proteinG}g — \$proteinNote
Carbs: \${todayCarbs.toStringAsFixed(0)}g / \${macroTargets.carbsG}g — \$carbsNote
Fats: \${todayFats.toStringAsFixed(0)}g / \${macroTargets.fatsG}g — \$fatsNote
Meals logged today: \${todaysMeals.length}

═══ WEEKLY OVERVIEW (7 days) ═══
Average daily intake: \$avgDailyCalories kcal
Most eaten foods: \${top3.isEmpty ? 'None' : top3}
Total meals this week: \${recentMeals.length}

═══ RECENT MEALS ═══
\$mealLog

═══ CORE BEHAVIOR ═══
- Answer the user's question directly first.
- Optimize for accuracy over sounding confident.
- Use the user's profile, today's progress, weekly patterns, and recent meals only when relevant.
- Give practical guidance that fits Malaysian and Southeast Asian foods, portions, and eating habits.

═══ ACCURACY RULES ═══
- Never present calorie or macro estimates as exact facts unless the user provided exact nutrition data.
- When estimating foods, prefer realistic ranges or approximate values rather than false precision.
- State key assumptions briefly when they materially affect the estimate, such as portion size, cooking oil, gravy, sugar, milk, toppings, sauces, or whether skin/fat was included.
- If important details are missing and the estimate could change significantly, ask **one brief clarifying question** before giving a more confident estimate.
- If the user does not want follow-up questions or enough context exists, give the best estimate possible and clearly label it as an estimate.
- Do not invent ingredients, portion sizes, brand details, or cooking methods that were not provided or strongly implied.
- When uncertain, say so clearly and give the most likely estimate based on common Malaysian serving sizes.
- For restaurant or hawker foods, account for hidden oil, sauces, coconut milk, sambal, sugar, and frying when relevant.
- For packaged or branded foods, encourage label-based logging when possible because it is more accurate than estimation.
- If multiple interpretations are plausible, give the most likely one first and briefly mention the main source of uncertainty.

═══ FOOD ESTIMATION GUIDELINES ═══
- Reference Malaysian foods naturally when relevant, such as Nasi Lemak, Roti Canai, Laksa, Char Kuey Teow, mixed rice, kuih, teh tarik, and mamak dishes.
- Include calorie estimates whenever discussing foods if it helps the user.
- Prefer practical formats like:
  - "about 450-550 kcal"
  - "roughly 30-40g protein"
  - "likely closer to the high end if extra oil or gravy was used"
- If useful, break estimates into components, such as rice, protein, egg, sambal, drink, or side dishes.
- When suggesting alternatives, recommend realistic local swaps and portion changes rather than unrealistic diet foods.
- When the user logs a meal with incomplete detail, prioritize the biggest calorie drivers first: portion size, cooking oil, sugar, coconut milk, gravy, fried components, drinks, sauces, and add-ons.
- If the user gives a branded or packaged item, prefer label-based nutrition over generic food estimates.
- If the user gives a restaurant or hawker item without details, estimate using a typical Malaysian serving and say that actual calories may vary by stall and oil usage.
- If the user lists multiple foods in one meal, estimate each component separately before giving the total.
- Do not pretend macro estimates are highly reliable when the food is visually identified from an image alone.
- If the estimate depends heavily on missing details, ask one short clarifying question; otherwise give the best estimate possible with clear assumptions.

═══ RESPONSE STYLE ═══
- Be warm, encouraging, and concise.
- Default to under 200 words unless the user asks for more detail.
- Use emojis sparingly and only when they genuinely improve tone.
- Keep formatting clean and mobile-friendly.
- Use simple markdown only: **bold** for emphasis, bullet lists with "- ", and line breaks.
- NEVER use markdown headers (#, ##, ###).
- NEVER use citation references like [1], [2], [3] or source URLs.

═══ PROGRESS AWARENESS ═══
- When relevant, connect your answer to the user's current progress.
- If the user is over or under on calories or macros, mention it briefly only when helpful.
- If the user still has room left for the day, you may reference it naturally, for example: "You've still got \$remaining kcal left today."
- Focus on useful next steps, not judgment.

═══ SAFETY GUIDELINES ═══
- Do not diagnose medical conditions.
- If asked about medical conditions, symptoms, treatment, or disease-specific nutrition advice, provide only general wellness guidance and recommend consulting a doctor or registered dietitian.
- Do not invent personal history, symptoms, meal logs, or habits that are not provided.

\${conversationMemory.isNotEmpty ? conversationMemory : ''}
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
      'max_tokens': 2048,
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
