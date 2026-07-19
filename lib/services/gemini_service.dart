import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/utils/app_logger.dart';
import '../models/food_suggestion.dart';

/// GeminiService — connects to Google Gemini API for food identification
/// (vision) and nutritional chatbot (text).
class GeminiService {
  String? get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty || key == 'your_api_key_here') return null;
    return key;
  }

  /// Uses Gemini Vision to identify food from an image.
  /// Returns a list of FoodSuggestion parsed from structured JSON output.
  Future<List<FoodSuggestion>> identifyFoodFromImage(
      Uint8List imageBytes) async {
    if (_apiKey == null) {
      throw Exception(
          'Gemini API key is not configured. Check your .env file.');
    }

    final prompt = '''
You are a world-class Malaysian and Southeast Asian food identification expert with deep knowledge of regional cuisine variations.

Your task is to identify the **main visible dish** in this image and return the 4 most likely dish guesses ranked from most likely to least likely.

Base your answer only on visible evidence in the image and common regional presentation patterns. Do not invent details that are not visible.

STEP 1 — VISUAL FEATURE ANALYSIS
Before identifying the dish, carefully inspect and reason from visible evidence only:
- Broth or sauce: color (clear, reddish, orange/coconut, dark soy, brown), opacity, thickness, oiliness
- Protein: visible type (prawns, chicken, beef, fish, egg, tofu), amount, and preparation style (whole, sliced, shredded, minced, fried)
- Base: noodle type (yellow mee, flat kuey teow, thin mihun/bihun, glass noodles, thick laksa noodles) or rice type (white rice, coconut rice, fried rice, compressed rice)
- Toppings and garnishes: bean sprouts, kangkung, cucumber, sambal, fried shallots, lime, chili, peanuts, anchovies, herbs, cockles, tofu puffs
- Cooking style: soupy, dry, stir-fried, grilled, steamed, deep-fried, braised, wrapped
- Vessel or presentation: banana leaf, bowl, plate, claypot, skewer, takeaway container

STEP 2 — DISTINGUISH SIMILAR DISHES CAREFULLY
Use these visual differentiators:

- Mee Udang (Prawn Noodle): reddish-orange clearer prawn-based broth, yellow noodles, whole prawns, sometimes hard-boiled egg
- Curry Mee: creamy orange-yellow coconut-based broth, tofu puffs and cockles common, often mint leaves
- Laksa Lemak: thick coconut curry broth, shredded chicken or prawns, thicker laksa noodles, daun kesum may appear
- Asam Laksa / Penang Laksa: darker sour tamarind broth, no coconut, mackerel flakes, torch ginger, thick round noodles
- Char Kuey Teow: dark stir-fried flat rice noodles, cockles, prawns, bean sprouts, chives, wok-fried appearance
- Pad Thai: thinner rice noodles, usually lighter color, peanuts and lime more typical, more distinctly Thai presentation
- Nasi Lemak: coconut rice, sambal, anchovies, peanuts, cucumber, hard-boiled egg, often banana leaf presentation
- Nasi Goreng: fried rice, darker from soy or kicap, often topped with fried egg, usually not plated as separate sambal set components
- Mee Goreng: fried yellow noodles, often reddish from chili sauce, tofu and potato cubes common
- Roti Canai: flaky layered flatbread, golden-brown, usually served with dhal or curry
- Chapati: thinner, more uniform, less flaky, whole-wheat appearance
- Prawn Mee: prawn-based soup with yellow noodles and rice vermicelli in clearer reddish broth
- Wan Tan Mee: yellow noodles, char siu, wontons, often dry dark soy style or served with light soup
- Bak Kut Teh: herbal pork rib soup, dark herbal broth, often in claypot
- Rendang: dry dark brown curry coating, thick caramelized coconut-spice paste, usually beef or chicken
- Nasi Kandar: rice with multiple curries or gravies mixed over it, colorful layered presentation
- Hokkien Mee (Singapore): pale stir-fried yellow noodles with bee hoon in prawn stock, lime and sambal on the side; KL Hokkien Mee is dark soy-braised thick noodles
- Bak Chor Mee: flat mee pok tossed in vinegar-chili with minced pork and liver; Wan Tan Mee has char siu and wontons instead
- Chai Tow Kway (Carrot Cake): black version is coated in sweet dark soy; white version is pale with an egg crust
- Economy Rice / Cai Fan / Nasi Campur: plate of white rice with 2-3 distinct scooped dishes on top
- Chicken Rice: pale poached or roasted chicken slices over glossy oily rice with chili and ginger sauces

STEP 3 — UNCERTAINTY AND RANKING
- Rank suggestions by actual visual likelihood, not by popularity.
- If the image is blurry, cropped, obstructed, poorly lit, or contains multiple foods, reduce confidence realistically.
- All 4 suggestions must be different dishes.
- Prefer Malaysian or Southeast Asian dishes when the visual evidence supports them.
- If the dish is clearly from another cuisine (Western, Japanese, Korean, Chinese, Indian, Middle Eastern, etc.), identify it by its common international name — do NOT force a Southeast Asian interpretation onto foreign food.
- Do not force high confidence if the visual evidence is weak.
- If multiple dishes are visually similar, use lower confidencePercent and explain the ambiguity in visualEvidence.
- Focus on the dominant visible dish if multiple items are present.

STEP 4 — PORTION ESTIMATION
Estimate the visible portion as realistically as possible:
- Use the visible bowl, plate, container size, fill level, and food density
- Soups often fall around 400-500g
- Dry noodle or rice dishes often fall around 250-350g
- Breads, snacks, and smaller side items may be much lower
- Do not overestimate portion weight for partially visible servings
- Do not assume extra unseen sides or drinks

STEP 5 — OUTPUT FORMAT
Return a JSON array of EXACTLY 4 objects, ranked from most likely to least likely, using this schema:

[
  {
    "rank": 1,
    "dishNameEn": "Prawn Mee",
    "dishNameMy": "Mee Udang",
    "mainIngredients": ["yellow noodles", "prawns", "prawn broth", "hard-boiled egg", "kangkung"],
    "estimatedPortionGrams": 450,
    "estimatedCalories": 520,
    "estimatedProteinG": 32.5,
    "estimatedCarbsG": 65.0,
    "estimatedFatsG": 14.0,
    "estimatedSodiumG": 1200.0,
    "estimatedSugarG": 3.5,
    "confidence": "high",
    "confidencePercent": 88,
    "cookingMethod": "boiled noodles in prawn head broth",
    "visualEvidence": "reddish-orange clear broth, whole prawns, yellow mee noodles"
  }
]

CRITICAL RULES:
- Return ONLY the JSON array.
- Do NOT use markdown.
- Do NOT include explanations before or after the JSON.
- Output EXACTLY 4 suggestion objects.
- 'rank' must be 1, 2, 3, 4 in order.
- 'confidence' must be exactly one of: "high", "medium", "low"
- 'confidencePercent' must be a realistic integer from 1 to 99.
- Use confidencePercent honestly:
  - 80-99 only if the dish is strongly supported by clear visible evidence
  - 50-79 if likely but not certain
  - 1-49 if the image is ambiguous or low quality
- 'estimatedPortionGrams' must reflect the visible portion only.
- 'estimatedCalories', 'estimatedProteinG', 'estimatedCarbsG', 'estimatedFatsG', 'estimatedSodiumG' (in mg), and 'estimatedSugarG' must reflect realistically calculated macros for the estimated portion.
- Ensure that the sum of protein, carbs, and fats in grams does not exceed the estimatedPortionGrams.
- 'dishNameEn' must be the short, common menu name of the dish (e.g. "Char Kuey Teow", "Chicken Rice", "Nasi Lemak", "Carbonara") — NOT a long description. Put the local-language name in 'dishNameMy'. Short canonical names match the nutrition database; decorated names do not.
- 'mainIngredients' should list only the most likely core ingredients.
- 'visualEvidence' must describe the visible features that support that specific guess.
- Do not claim ingredients, garnishes, or side dishes unless they are visible or strongly implied by the dish's core identity.
- If uncertain, reflect uncertainty through lower confidence instead of inventing certainty.
''';

    final content = Content.multi([
      TextPart(prompt),
      DataPart('image/jpeg', imageBytes),
    ]);

    GenerateContentResponse? response;
    Object? lastError;

    // Define the fallback chain: Start with the most capable model (3.5 Flash),
    // and gracefully degrade to older/more available models if quotas are hit.
    final modelsToTry = [
      'gemini-3.5-flash',
      'gemini-3.0-flash',
      'gemini-2.5-flash'
    ];

    // Attempt generation across the fallback chain
    for (final modelId in modelsToTry) {
      try {
        final tempModel = GenerativeModel(
          model: modelId,
          apiKey: _apiKey!,
          generationConfig: GenerationConfig(
            temperature: 0.4,
            maxOutputTokens: 4096,
            responseMimeType: 'application/json',
          ),
        );

        response = await tempModel
            .generateContent([content]).timeout(const Duration(seconds: 15));
        AppLogger.instance.log('Gemini vision success using model: $modelId');
        break; // Success, exit the fallback loop
      } on GenerativeAIException catch (e) {
        lastError = e;
        final msg = e.message.toLowerCase();

        // If the error is a rate limit, quota exhaustion, or high demand,
        // we swallow the error and allow the loop to try the next model.
        if (msg.contains('429') ||
            msg.contains('quota') ||
            msg.contains('limit') ||
            msg.contains('503') ||
            msg.contains('high demand') ||
            msg.contains('not found')) {
          AppLogger.instance
              .log('Gemini model $modelId failed ($msg). Falling back...');
          continue; // Try next model in the chain
        }

        // If it's a fatal error (like invalid API key), crash immediately
        rethrow;
      } catch (e) {
        lastError = e;
        final msg = e.toString().toLowerCase();
        AppLogger.instance
            .log('Gemini model $modelId network/timeout error ($msg). Falling back...');
        continue;
      }
    }

    // If all models failed, surface the most relevant error to the user
    if (response == null && lastError != null) {
      final errStr = lastError.toString().toLowerCase();
      if (errStr.contains('503') || errStr.contains('high demand')) {
        throw Exception(
            'The AI is currently busy (high demand). Please try again in a few seconds.');
      } else if (errStr.contains('timeout')) {
        throw Exception(
            'Vision analysis timed out after multiple attempts. Please check your network connection and try again.');
      }
      if (lastError is Exception) throw lastError;
      throw Exception(lastError.toString());
    }

    final text = response?.text;

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

    final estimatedCalories = (map['estimatedCalories'] as num?)?.toInt() ??
        (estimatedPortionGrams * 1.5).round();
    final estimatedProteinG = (map['estimatedProteinG'] as num?)?.toDouble() ??
        (estimatedPortionGrams * 0.1);
    final estimatedCarbsG = (map['estimatedCarbsG'] as num?)?.toDouble() ??
        (estimatedPortionGrams * 0.5);
    final estimatedFatsG = (map['estimatedFatsG'] as num?)?.toDouble() ??
        (estimatedPortionGrams * 0.15);
    final estimatedSodiumG =
        (map['estimatedSodiumG'] as num?)?.toDouble() ?? 0.0;
    final estimatedSugarG = (map['estimatedSugarG'] as num?)?.toDouble() ?? 0.0;

    return <String, dynamic>{
      'rank': rank,
      'dishNameEn': dishNameEn,
      'dishNameMy': dishNameMy,
      'mainIngredients': ingredients,
      'estimatedPortionGrams': estimatedPortionGrams,
      'confidence': confidence,
      'confidencePercent': confidencePercent,
      'cookingMethod': cookingMethod,
      'estimatedCalories': estimatedCalories,
      'estimatedProteinG': estimatedProteinG,
      'estimatedCarbsG': estimatedCarbsG,
      'estimatedFatsG': estimatedFatsG,
      'estimatedSodiumG': estimatedSodiumG,
      'estimatedSugarG': estimatedSugarG,
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
      ('hokkien mee', 'Prawn Noodle Soup', 'Mee Udang'),
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
        // Macros must roughly add up to the calories (4/4/9 kcal per gram):
        // 20*4 + 55*4 + 16*9 = 444 ≈ 450 kcal.
        estimatedCalories: 450,
        estimatedProteinG: 20.0,
        estimatedCarbsG: 55.0,
        estimatedFatsG: 16.0,
        estimatedSodiumG: 0.0,
        estimatedSugarG: 0.0,
        confidence: 'medium',
        confidencePercent: 60,
        cookingMethod: 'Estimated from image',
      ),
    ];
  }

  /// Sends a chat message to Gemini with nutritional context.
  ///
  /// [systemPrompt] is built by the caller (see
  /// [OpenRouterService.buildSystemPrompt]) so the primary and fallback
  /// chat services always share one prompt instead of drifting apart.
  Future<String> chat({
    required String userMessage,
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      throw Exception(
          'Gemini API key is not configured. Check your .env file.');
    }

    // Define the fallback chain for the chatbot.
    // Matches the vision fallback chain to ensure high availability.
    final modelsToTry = [
      'gemini-3.5-flash',
      'gemini-3.0-flash',
      'gemini-2.5-flash'
    ];

    GenerateContentResponse? response;
    GenerativeAIException? lastError;

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

    for (final modelId in modelsToTry) {
      try {
        final chatModel = GenerativeModel(
          model: modelId,
          apiKey: apiKey,
          systemInstruction: Content.system(systemPrompt),
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 2048,
          ),
        );
        response = await chatModel.generateContent(contents);
        AppLogger.instance.log('Gemini chat success using model: $modelId');
        break; // Success, exit the fallback loop
      } on GenerativeAIException catch (e) {
        lastError = e;
        final msg = e.message.toLowerCase();

        // If the error is a rate limit, quota exhaustion, or high demand,
        // we swallow the error and allow the loop to try the next model.
        if (msg.contains('429') ||
            msg.contains('quota') ||
            msg.contains('limit') ||
            msg.contains('503') ||
            msg.contains('high demand') ||
            msg.contains('not found')) {
          AppLogger.instance
              .log('Gemini chat model $modelId failed ($msg). Falling back...');
          continue; // Try next model in the chain
        }

        // If it's a fatal error (like invalid API key), crash immediately
        rethrow;
      }
    }

    // If all models failed, surface the most relevant error to the user
    if (response == null && lastError != null) {
      throw lastError;
    }

    final text = response?.text;

    if (text == null || text.isEmpty) {
      return 'Sorry, I couldn\'t generate a response. Please try again.';
    }

    // Store in history for future context
    history.add({'role': 'user', 'text': userMessage});
    history.add({'role': 'model', 'text': text});

    return text;
  }
}
