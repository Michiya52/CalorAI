import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../services/logger_service.dart';

class OpenFoodFactsService {
  static final OpenFoodFactsService instance = OpenFoodFactsService._internal();
  OpenFoodFactsService._internal();

  static const String _baseUrl = 'world.openfoodfacts.org';

  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    try {
      final item = await _fetchFromApi(cleanBarcode);
      if (item != null) return item;

      // Try 13-digit EAN if 12-digit UPC-A
      if (cleanBarcode.length == 12) {
        final padded = await _fetchFromApi('0$cleanBarcode');
        if (padded != null) return padded;
      }

      // Try 12-digit UPC if 13-digit starting with 0
      if (cleanBarcode.length == 13 && cleanBarcode.startsWith('0')) {
        final stripped = await _fetchFromApi(cleanBarcode.substring(1));
        if (stripped != null) return stripped;
      }
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'Open Food Facts lookup failed');
    }

    return null;
  }

  Future<FoodItem?> _fetchFromApi(String barcode) async {
    final uri = Uri.parse('https://$_baseUrl/api/v0/product/$barcode.json');
    final response = await http.get(uri, headers: {
      'User-Agent': 'CalorAI - Android/iOS - https://calor.ai'
    }).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data['status'] != 1 || data['product'] == null) return null;

    final product = data['product'] as Map<String, dynamic>;
    final name = product['product_name'] as String? ??
        product['product_name_en'] as String? ??
        product['generic_name'] as String? ??
        '';
    if (name.trim().isEmpty) return null;

    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    double calories = _parseNutriment(nutriments, ['energy-kcal_100g', 'energy-kcal', 'energy-kcal_value']);
    if (calories == 0) {
      final kj = _parseNutriment(nutriments, ['energy-kj_100g', 'energy_100g', 'energy']);
      if (kj > 0) calories = kj / 4.184;
    }

    double protein = _parseNutriment(nutriments, ['proteins_100g', 'proteins']);
    double carbs = _parseNutriment(nutriments, ['carbohydrates_100g', 'carbohydrates']);
    double fats = _parseNutriment(nutriments, ['fat_100g', 'fat']);
    double sodium = _parseNutriment(nutriments, ['sodium_100g', 'sodium']);
    if (sodium == 0) {
      final salt = _parseNutriment(nutriments, ['salt_100g', 'salt']);
      if (salt > 0) sodium = salt * 400.0;
    } else if (sodium < 100 && sodium > 0) {
      // If sodium in OFF is in grams (usually <= 10g per 100g), convert to mg
      sodium = sodium * 1000.0;
    }
    double sugar = _parseNutriment(nutriments, ['sugars_100g', 'sugars']);

    double servingGrams = 150.0;
    final servingQuantity = product['serving_quantity'];
    if (servingQuantity != null && (servingQuantity is num) && servingQuantity > 0) {
      servingGrams = servingQuantity.toDouble();
    } else if (product['serving_size'] != null && product['serving_size'] is String) {
      final sStr = product['serving_size'] as String;
      final numMatch = RegExp(r'(\d+)\s*(g|ml|G|ML)').firstMatch(sStr);
      if (numMatch != null) {
        final parsedG = double.tryParse(numMatch.group(1)!);
        if (parsedG != null && parsedG > 0) servingGrams = parsedG;
      }
    }

    String foodGroup = product['categories'] != null && (product['categories'] as String).isNotEmpty
        ? (product['categories'] as String).split(',').first.trim()
        : 'Packaged Food';

    List<String> ingredients = [];
    if (product['ingredients_text'] != null && (product['ingredients_text'] as String).isNotEmpty) {
      ingredients = (product['ingredients_text'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return FoodItem(
      id: 'off_$barcode',
      nameEn: name.trim(),
      nameMy: name.trim(),
      foodGroup: foodGroup,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatsPer100g: fats,
      sodiumPer100g: sodium,
      sugarPer100g: sugar,
      ingredients: ingredients,
      portionSizes: PortionSizes(
        smallGrams: (servingGrams * 0.6).roundToDouble(),
        mediumGrams: servingGrams.roundToDouble(),
        largeGrams: (servingGrams * 1.5).roundToDouble(),
      ),
      source: 'OpenFoodFacts',
      myfcdCode: barcode,
    );
  }

  double _parseNutriment(Map<String, dynamic> nutriments, List<String> keys) {
    for (final key in keys) {
      final val = nutriments[key];
      if (val != null) {
        if (val is num) return val.toDouble();
        if (val is String) {
          final parsed = double.tryParse(val);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0.0;
  }
}
