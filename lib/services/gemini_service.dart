import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/utils/app_logger.dart';
import '../models/food_suggestion.dart';
import '../models/user_profile.dart';
import '../models/meal_entry.dart';

/// GeminiService — connects to Google Gemini API for food identification
/// (vision) and nutritional chatbot (text).
class GeminiService {
  static const String _modelName = 'gemini-1.5-flash';
  static GenerativeModel? _visionModel;
  static GenerativeModel? _chatModel;

  GeminiService() {
    _initModels();
  }

  void _initModels() {
    if (_visionModel != null) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      AppLogger.instance.log('WARNING: GEMINI_API_KEY not set in .env');
      return;
    }

    _visionModel = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 2048,
      ),
    );

    _chatModel = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Verifies if the Gemini API is reachable and the key is valid.
  Future<bool> checkConnection() async {
    try {
      if (_chatModel == null) _initModels();
      if (_chatModel == null) return false;

      // Simple test prompt to verify the connection
      final response =
          await _chatModel!.generateContent([Content.text('ping')]);
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      AppLogger.instance.log('Gemini Connection Check Failed: $e');
      return false;
    }
  }

  /// Uses Gemini Vision to identify food from an image.
  /// Returns a list of FoodSuggestion parsed from structured JSON output.
  Future<List<FoodSuggestion>> identifyFoodFromImage(
      Uint8List imageBytes) async {
    if (_visionModel == null) {
      throw Exception(
          'Gemini API key is not configured. Check your .env file.');
    }

    final prompt = '''
You are a Malaysian food identification expert. Analyze this food image and identify the dish(es).

Return a JSON array of up to 3 suggestions, ranked by confidence. Use this exact format:
[
  {
    "rank": 1,
    "dishNameEn": "English name",
    "dishNameMy": "Malay name",
    "mainIngredients": ["ingredient1", "ingredient2"],
    "estimatedPortionGrams": 350,
    "confidence": "high",
    "confidencePercent": 88,
    "cookingMethod": "cooking method description"
  }
]

Rules:
- confidence must be one of: "high", "medium", "low"
- confidencePercent must be an integer from 0 to 100 that matches the confidence level
- estimatedPortionGrams should be a realistic weight for the visible portion
- Focus on Malaysian/Southeast Asian cuisine when possible
- Return ONLY the JSON array, no other text
''';

    final content = Content.multi([
      TextPart(prompt),
      DataPart('image/jpeg', imageBytes),
    ]);

    final GenerateContentResponse response;
    try {
      response = await _visionModel!.generateContent([content]);
    } on GenerativeAIException catch (e) {
      if (e.message.contains('503') || e.message.contains('high demand')) {
        throw Exception(
            'The AI is currently busy (high demand). Please try again in a few seconds.');
      }
      rethrow;
    }
    final text = response.text;

    _logResponse('Gemini vision raw response', text);

    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    final suggestions = _parseSuggestions(text);
    if (suggestions.isEmpty) {
      final fallbackSuggestions = _fallbackSuggestionsFromText(text);
      if (fallbackSuggestions.isNotEmpty) {
        AppLogger.instance.log(
            'Gemini fallback suggestion used: ${fallbackSuggestions.first.dishNameEn}');
        return fallbackSuggestions;
      }
      throw Exception('No food suggestions could be parsed from model output.');
    }
    return suggestions;
  }

  /// Parses the JSON response from Gemini Vision into FoodSuggestion objects.
  List<FoodSuggestion> _parseSuggestions(String responseText) {
    var cleaned = responseText.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (initialError) {
      // Try to repair truncated JSON
      try {
        final repaired = _repairJson(cleaned);
        AppLogger.instance
            .log('JSON repair attempted. Original error: $initialError');
        decoded = jsonDecode(repaired);
        AppLogger.instance.log('JSON repair successful.');
      } catch (repairError) {
        final firstArray = cleaned.indexOf('[');
        final lastArray = cleaned.lastIndexOf(']');
        if (firstArray >= 0 && lastArray > firstArray) {
          decoded = jsonDecode(cleaned.substring(firstArray, lastArray + 1));
        } else {
          final firstObject = cleaned.indexOf('{');
          final lastObject = cleaned.lastIndexOf('}');
          if (firstObject >= 0 && lastObject > firstObject) {
            decoded =
                jsonDecode(cleaned.substring(firstObject, lastObject + 1));
          } else {
            rethrow;
          }
        }
      }
    }

    List<dynamic> rawItems;
    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded['suggestions'] is List) {
      rawItems = List<dynamic>.from(decoded['suggestions'] as List);
    } else if (decoded is Map<String, dynamic>) {
      rawItems = <dynamic>[decoded];
    } else {
      return const [];
    }

    final parsed = <FoodSuggestion>[];
    for (var i = 0; i < rawItems.length; i++) {
      final map = _toSuggestionMap(rawItems[i], i + 1);
      if (map == null) continue;
      try {
        parsed.add(FoodSuggestion.fromMap(map));
      } catch (e) {
        AppLogger.instance.log('Skipping malformed suggestion item: $e');
      }
    }
    return parsed;
  }

  void _logResponse(String label, String? text) {
    if (text == null) {
      AppLogger.instance.log('$label: <null>');
      return;
    }

    AppLogger.instance.log('$label (${text.length} chars)');
    const chunkSize = 800;
    for (var i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      AppLogger.instance.log(text.substring(i, end));
    }
  }

  Map<String, dynamic>? _toSuggestionMap(dynamic item, int defaultRank) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);

    final dishNameEn = (map['dishNameEn'] ??
            map['dish_name_en'] ??
            map['nameEn'] ??
            map['name'] ??
            map['dish'])
        ?.toString()
        .trim();
    if (dishNameEn == null || dishNameEn.isEmpty) {
      return null;
    }

    final dishNameMy = (map['dishNameMy'] ??
            map['dish_name_my'] ??
            map['nameMy'] ??
            map['name_ms'] ??
            dishNameEn)
        .toString()
        .trim();

    List<String> ingredients = const [];
    final rawIngredients = map['mainIngredients'] ?? map['ingredients'];
    if (rawIngredients is List) {
      ingredients = rawIngredients
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawIngredients is String) {
      ingredients = rawIngredients
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (ingredients.isEmpty) {
      ingredients = <String>[dishNameEn];
    }

    final portionRaw = map['estimatedPortionGrams'] ?? map['portionGrams'];
    var estimatedPortionGrams = 300.0;
    if (portionRaw is num) {
      estimatedPortionGrams = portionRaw.toDouble();
    } else if (portionRaw is String) {
      final parsed = double.tryParse(portionRaw);
      if (parsed != null) estimatedPortionGrams = parsed;
    }
    if (estimatedPortionGrams <= 0) estimatedPortionGrams = 300.0;

    final confidenceRaw =
        (map['confidence'] ?? 'medium').toString().toLowerCase();
    final confidence = confidenceRaw.contains('high')
        ? 'high'
        : confidenceRaw.contains('low')
            ? 'low'
            : 'medium';

    final confidencePercentRaw =
        map['confidencePercent'] ?? map['confidence_score'] ?? map['score'];
    int? confidencePercent;
    if (confidencePercentRaw is num) {
      confidencePercent = confidencePercentRaw.round();
    } else if (confidencePercentRaw is String) {
      final cleaned = confidencePercentRaw.replaceAll('%', '').trim();
      confidencePercent = int.tryParse(cleaned);
    }
    confidencePercent ??= switch (confidence) {
      'high' => 85,
      'low' => 45,
      _ => 65,
    };
    confidencePercent = confidencePercent.clamp(0, 100);

    final cookingMethod =
        (map['cookingMethod'] ?? map['method'] ?? '').toString().trim();

    final rankRaw = map['rank'];
    var rank = defaultRank;
    if (rankRaw is num) {
      rank = rankRaw.toInt();
    } else if (rankRaw is String) {
      rank = int.tryParse(rankRaw) ?? defaultRank;
    }

    return <String, dynamic>{
      'rank': rank,
      'dishNameEn': dishNameEn,
      'dishNameMy': dishNameMy,
      'mainIngredients': ingredients,
      'estimatedPortionGrams': estimatedPortionGrams,
      'confidence': confidence,
      'confidencePercent': confidencePercent,
      'cookingMethod': cookingMethod,
    };
  }

  /// Attempts to repair truncated JSON strings by balancing braces and quotes.
  String _repairJson(String json) {
    var repaired = json.trim();

    // 1. Handle unclosed quotes at the end
    var insideString = false;
    for (var i = 0; i < repaired.length; i++) {
      if (repaired[i] == '"' && (i == 0 || repaired[i - 1] != '\\')) {
        insideString = !insideString;
      }
    }
    if (insideString) {
      repaired += '"';
    }

    // 2. Remove trailing comma (common in truncated arrays/objects)
    final lastCharMatch = RegExp(r'[^\s\n\r]').allMatches(repaired).lastOrNull;
    if (lastCharMatch != null) {
      final lastCharIndex = lastCharMatch.start;
      if (repaired[lastCharIndex] == ',') {
        repaired = repaired.substring(0, lastCharIndex) +
            repaired.substring(lastCharIndex + 1);
      }
    }

    // 3. Balance braces and brackets
    final stack = <String>[];
    insideString = false;

    for (var i = 0; i < repaired.length; i++) {
      final char = repaired[i];
      if (char == '"' && (i == 0 || repaired[i - 1] != '\\')) {
        insideString = !insideString;
        continue;
      }

      if (!insideString) {
        if (char == '{' || char == '[') {
          stack.add(char);
        } else if (char == '}') {
          if (stack.isNotEmpty && stack.last == '{') stack.removeLast();
        } else if (char == ']') {
          if (stack.isNotEmpty && stack.last == '[') stack.removeLast();
        }
      }
    }

    // Close in reverse order of opening
    while (stack.isNotEmpty) {
      final open = stack.removeLast();
      if (open == '{') {
        repaired += '}';
      } else if (open == '[') {
        repaired += ']';
      }
    }

    return repaired;
  }

  List<FoodSuggestion> _fallbackSuggestionsFromText(String responseText) {
    final lower = responseText.toLowerCase();

    final knownDishes = <MapEntry<String, String>>[
      const MapEntry('nasi lemak', 'Nasi lemak'),
      const MapEntry('roti canai', 'Roti canai'),
      const MapEntry('laksa', 'Laksa'),
      const MapEntry('mee goreng', 'Mee goreng'),
      const MapEntry('nasi goreng', 'Nasi goreng'),
      const MapEntry('chicken rice', 'Chicken rice'),
      const MapEntry('satay', 'Satay'),
      const MapEntry('curry', 'Curry dish'),
      const MapEntry('soup', 'Soup'),
    ];

    String dishNameEn = 'Unknown dish';
    for (final entry in knownDishes) {
      if (lower.contains(entry.key)) {
        dishNameEn = entry.value;
        break;
      }
    }

    final dishNameMy =
        dishNameEn == 'Unknown dish' ? 'Hidangan tidak dikenali' : dishNameEn;

    return [
      FoodSuggestion(
        rank: 1,
        dishNameEn: dishNameEn,
        dishNameMy: dishNameMy,
        mainIngredients: [dishNameEn],
        estimatedPortionGrams: 300,
        confidence: 'medium',
        confidencePercent: 60,
        cookingMethod: 'Estimated from image',
      ),
    ];
  }

  /// Sends a chat message to Gemini with nutritional context.
  Future<String> chat({
    required String userMessage,
    required UserProfile profile,
    required List<MealEntry> recentMeals,
    required List<dynamic> history,
  }) async {
    if (_chatModel == null) {
      throw Exception(
          'Gemini API key is not configured. Check your .env file.');
    }

    // Build context about the user's profile and recent meals
    final mealSummary = recentMeals.isEmpty
        ? 'No meals logged recently.'
        : recentMeals
            .take(10)
            .map((m) => '- ${m.foodNameEn} (${m.calories} kcal, ${m.date})')
            .join('\n');

    final systemPrompt = '''
You are CalorAI, a friendly and knowledgeable Malaysian nutrition assistant. 
You help users track their diet and make healthier food choices, with a focus on Malaysian cuisine.

User Profile:
- Name: ${profile.name}
- Goal: ${profile.goal.replaceAll('_', ' ')}
- Daily calorie target: ${profile.calorieTarget} kcal
- Age: ${profile.age}, Sex: ${profile.sex}
- Height: ${profile.heightCm} cm, Weight: ${profile.weightKg} kg
- Activity level: ${profile.activityLevel.replaceAll('_', ' ')}

Recent meals (last 7 days):
$mealSummary

Guidelines:
- Be warm, encouraging, and use emojis sparingly
- Reference Malaysian foods specifically (Nasi Lemak, Roti Canai, Laksa, etc.)
- Provide calorie estimates when discussing foods
- If asked about medical conditions, politely decline and recommend consulting a doctor
- Keep responses concise (under 200 words)
- Use Markdown formatting for lists and emphasis
''';

    // Build conversation history for multi-turn chat
    final contents = <Content>[
      Content.text(systemPrompt),
    ];

    // Add conversation history (last 6 messages for context window)
    final recentHistory =
        history.length > 6 ? history.sublist(history.length - 6) : history;
    for (final msg in recentHistory) {
      if (msg is Map<String, dynamic>) {
        final role = msg['role'] as String?;
        final text = msg['text'] as String?;
        if (role != null && text != null) {
          contents.add(Content(role, [TextPart(text)]));
        }
      }
    }

    // Add the current user message
    contents.add(Content.text(userMessage));

    final response = await _chatModel!.generateContent(contents);
    final text = response.text;

    if (text == null || text.isEmpty) {
      return 'Sorry, I couldn\'t generate a response. Please try again.';
    }

    // Store in history for future context
    history.add({'role': 'user', 'text': userMessage});
    history.add({'role': 'model', 'text': text});

    return text;
  }
}
