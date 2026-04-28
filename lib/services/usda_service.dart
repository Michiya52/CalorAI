import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

/// Service for accessing USDA FoodData Central.
/// Provides high-accuracy nutritional data for branded and foundation foods.
class UsdaService {
  static final UsdaService instance = UsdaService._internal();
  UsdaService._internal();

  String get _apiKey => dotenv.env['USDA_API_KEY'] ?? '';
  static const String _baseUrl = 'api.nal.usda.gov';

  /// Search for foods by generic query or barcode.
  Future<List<FoodItem>> searchFoods(String query) async {
    final uri = Uri.https(_baseUrl, '/fdc/v1/foods/search', {
      'api_key': _apiKey,
      'query': query,
      'pageSize': '25',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body);
      final foods = data['foods'] as List?;
      if (foods == null) return const [];

      return foods
          .map((f) => _mapUsdaToFoodItem(f))
          .whereType<FoodItem>()
          .toList();
    } catch (e) {
      debugPrint('USDA search failed: $e');
      return const [];
    }
  }

  /// Specialized barcode lookup for USDA.
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    // USDA search can take a GTIN/UPC directly in the query.
    final results = await searchFoods(barcode);
    return results.isNotEmpty ? results.first : null;
  }

  FoodItem? _mapUsdaToFoodItem(Map<String, dynamic> f) {
    final name = f['description'] as String? ?? '';
    if (name.isEmpty) return null;

    final nutrients = f['foodNutrients'] as List?;
    if (nutrients == null) return null;

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;
    double sodium = 0;
    double sugar = 0;

    for (final n in nutrients) {
      final id = n['nutrientId'] ?? n['number'];
      final value = (n['value'] as num?)?.toDouble() ?? 0.0;

      // USDA Nutrient IDs:
      // 208: Energy (kcal)
      // 203: Protein
      // 205: Carbohydrate
      // 204: Total lipid (fat)
      // 307: Sodium
      // 269: Sugars
      switch (id.toString()) {
        case '208':
        case '1008':
          calories = value;
          break;
        case '203':
        case '1003':
          protein = value;
          break;
        case '205':
        case '1005':
          carbs = value;
          break;
        case '204':
        case '1004':
          fats = value;
          break;
        case '307':
        case '1093':
          sodium = value / 1000.0; // mg to g for our model
          break;
        case '269':
        case '2000':
          sugar = value;
          break;
      }
    }

    // Removed 'if (calories <= 0) return null;' filter to allow zero-calorie items like water

    final id = 'usda_${f['fdcId']}';

    // USDA usually provides data per 100g/100ml.
    // We'll estimate portion sizes if not provided.
    final servingSize = (f['servingSize'] as num?)?.toDouble() ?? 150.0;

    return FoodItem(
      id: id,
      nameEn: name,
      nameMy: name,
      foodGroup: f['foodCategory'] ?? 'General',
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatsPer100g: fats,
      sodiumPer100g: sodium,
      sugarPer100g: sugar,
      ingredients: (f['ingredients'] as String?)
              ?.split(',')
              .map((i) => i.trim())
              .where((i) => i.isNotEmpty)
              .toList() ??
          [],
      portionSizes: PortionSizes(
        smallGrams: (servingSize * 0.6).roundToDouble(),
        mediumGrams: servingSize.roundToDouble(),
        largeGrams: (servingSize * 1.5).roundToDouble(),
      ),
      source: 'USDA',
      myfcdCode: f['gtinUpc'] ?? id,
    );
  }
}
