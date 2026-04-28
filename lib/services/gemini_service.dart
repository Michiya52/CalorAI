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
  static const String _modelName = 'gemini-2.5-flash';
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
        temperature: 0.4,
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
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
You are a world-class Malaysian and Southeast Asian food identification expert with deep knowledge of regional cuisine variations.

ANALYZE this food image using the following steps:

STEP 1 — VISUAL FEATURE ANALYSIS:
Before identifying, carefully observe and note:
- Broth/sauce: color (clear, reddish, orange/coconut, dark soy, brown), consistency (watery, thick, creamy)
- Protein: type visible (prawns, chicken, beef, fish, egg, tofu), preparation (whole, sliced, shredded)
- Base: noodle type (yellow mee, flat kuey teow, thin mihun/bihun, glass noodles) or rice (white, fried, compressed)
- Toppings/garnishes: bean sprouts, kangkung, cucumber, sambal, fried shallots, lime, chili, peanuts, anchovies
- Cooking style: soupy, dry/stir-fried, steamed, grilled, deep-fried, wrapped
- Vessel/presentation: banana leaf, bowl, plate, claypot, skewer

STEP 2 — DISTINGUISH SIMILAR DISHES:
Use these visual differentiators for commonly confused Malaysian dishes:
- Mee Udang (Prawn Noodle): REDDISH-ORANGE clear broth from prawn heads, yellow noodles, whole prawns on top, sometimes with hard-boiled egg
- Curry Mee: COCONUT-based creamy/opaque broth (orange-yellow), cockles and tofu puffs common, mint leaves, sometimes with blood cubes
- Laksa Lemak: THICK coconut curry broth, shredded chicken or prawns, thick vermicelli (laksa noodles), daun kesum (laksa leaf)
- Laksa Penang/Asam Laksa: SOUR tamarind-based broth (darker, no coconut), mackerel flakes, torch ginger flower, thick round noodles
- Char Kuey Teow: DARK soy-stained FLAT rice noodles, stir-fried, cockles, prawns, Chinese sausage, bean sprouts, chives
- Pad Thai: THINNER rice noodles, lighter color, peanuts on top, lime wedge, different noodle texture than CKT
- Nasi Lemak: Coconut rice (often triangle-shaped), sambal, fried anchovies, peanuts, cucumber, hard-boiled egg, served on banana leaf
- Nasi Goreng: Fried rice, darker color from kicap/soy, often with fried egg on top, no sambal side
- Mee Goreng: Fried YELLOW noodles (not rice), often with red chili sauce, potato cubes, tofu
- Roti Canai: Flaky layered flatbread, golden-brown, served with dhal or curry
- Chapati: Thin, uniform flatbread, NOT flaky, whole wheat color
- Hokkien Mee (KL): DARK soy braised thick yellow noodles in dark sauce with pork lard, prawns, pork slices
- Hokkien Mee (Penang): PRAWN-based SOUP with yellow noodles and rice vermicelli mix, clear reddish broth
- Wan Tan Mee: Yellow noodles, char siu on top, served with wonton dumplings, dark soy sauce or clear soup
- Bak Kut Teh: Herbal PORK RIB SOUP, clear dark broth, pork ribs visible, served in claypot
- Rendang: DRY curry, dark brown, thick caramelized coconut coating, usually beef or chicken
- Nasi Kandar: Rice with MULTIPLE curries/gravies mixed, vibrant colors, originated from Penang

STEP 3 — OUTPUT:
Return a JSON array of EXACTLY 4 suggestions ranked from most to least likely.
Each suggestion MUST have distinct dish names (do not repeat the same dish).

[
  {
    "rank": 1,
    "dishNameEn": "Prawn Noodle Soup (Mee Udang)",
    "dishNameMy": "Mee Udang",
    "mainIngredients": ["yellow noodles", "prawns", "prawn broth", "hard-boiled egg", "kangkung"],
    "estimatedPortionGrams": 450,
    "confidence": "high",
    "confidencePercent": 88,
    "cookingMethod": "boiled noodles in prawn head broth",
    "visualEvidence": "reddish-orange clear broth, whole prawns, yellow mee noodles"
  }
]

CRITICAL RULES:
- Return ONLY the JSON array — no markdown, no explanation, no extra text.
- 'confidence' must be one of: "high", "medium", "low"
- 'confidencePercent' must be a realistic integer 1–99 reflecting your ACTUAL confidence for each guess. Vary these significantly.
- 'estimatedPortionGrams' must be realistic for the visible portion (soups are heavier 400-500g, dry dishes 250-350g).
- 'visualEvidence' must describe the specific visual features that led to this identification.
- Focus on Malaysian/Southeast Asian cuisine. If unsure, prefer the Malaysian variant.
- All 4 suggestions must be DIFFERENT dishes.
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

    // Malaysian dishes with English name → Malay name mapping
    const knownDishes = <(String, String, String)>[
      // (search key, English name, Malay name)
      ('mee udang', 'Prawn Noodle Soup', 'Mee Udang'),
      ('prawn noodle', 'Prawn Noodle Soup', 'Mee Udang'),
      ('prawn mee', 'Prawn Noodle Soup', 'Mee Udang'),
      ('curry mee', 'Curry Noodle', 'Mee Kari'),
      ('curry noodle', 'Curry Noodle', 'Mee Kari'),
      ('nasi lemak', 'Nasi Lemak', 'Nasi Lemak'),
      ('roti canai', 'Roti Canai', 'Roti Canai'),
      ('char kuey teow', 'Char Kuey Teow', 'Kuey Teow Goreng'),
      ('char kway teow', 'Char Kuey Teow', 'Kuey Teow Goreng'),
      ('laksa lemak', 'Curry Laksa', 'Laksa Lemak'),
      ('asam laksa', 'Asam Laksa', 'Laksa Asam'),
      ('laksa', 'Laksa', 'Laksa'),
      ('mee goreng', 'Fried Noodles', 'Mee Goreng'),
      ('nasi goreng', 'Fried Rice', 'Nasi Goreng'),
      ('chicken rice', 'Chicken Rice', 'Nasi Ayam'),
      ('nasi ayam', 'Chicken Rice', 'Nasi Ayam'),
      ('satay', 'Satay', 'Satai'),
      ('rendang', 'Rendang', 'Rendang'),
      ('nasi kandar', 'Nasi Kandar', 'Nasi Kandar'),
      ('bak kut teh', 'Pork Rib Soup', 'Bak Kut Teh'),
      ('wan tan mee', 'Wanton Noodles', 'Wan Tan Mee'),
      ('wonton', 'Wanton Noodles', 'Wan Tan Mee'),
      ('hokkien mee', 'Hokkien Noodles', 'Hokkien Mee'),
      ('teh tarik', 'Pulled Milk Tea', 'Teh Tarik'),
      ('cendol', 'Cendol', 'Cendol'),
      ('rojak', 'Rojak', 'Rojak'),
      ('popiah', 'Spring Roll', 'Popiah'),
      ('nasi kerabu', 'Blue Rice', 'Nasi Kerabu'),
      ('ayam goreng', 'Fried Chicken', 'Ayam Goreng'),
      ('ikan bakar', 'Grilled Fish', 'Ikan Bakar'),
      ('tom yam', 'Tom Yam Soup', 'Tom Yam'),
      ('curry', 'Curry', 'Kari'),
      ('soup', 'Soup', 'Sup'),
      ('rice', 'Rice dish', 'Hidangan nasi'),
      ('noodle', 'Noodle dish', 'Hidangan mi'),
    ];

    String dishNameEn = 'Unknown dish';
    String dishNameMy = 'Hidangan tidak dikenali';
    for (final (key, en, my) in knownDishes) {
      if (lower.contains(key)) {
        dishNameEn = en;
        dishNameMy = my;
        break;
      }
    }

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
    required List<Map<String, String>> history,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
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
- Use simple markdown: **bold** for emphasis, bullet lists with "- " prefix
- NEVER use citation references like [1], [2], [3] or source URLs
- NEVER use markdown headers (#, ##, ###) — use **bold text** instead
''';

    // A per-call model is necessary here because the system instruction
    // includes dynamic user profile and meal context that changes each call.
    final chatModel = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );

    // Build conversation history for multi-turn chat
    final contents = <Content>[];

    // Add conversation history (last 6 messages for context window)
    final recentHistory =
        history.length > 6 ? history.sublist(history.length - 6) : history;
    for (final msg in recentHistory) {
      final role = msg['role'];
      final text = msg['text'];
      if (role != null && text != null) {
        contents.add(Content(role, [TextPart(text)]));
      }
    }

    // Add the current user message
    contents.add(Content.text(userMessage));

    final response = await chatModel.generateContent(contents);
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
