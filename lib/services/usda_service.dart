import 'dart:convert';
import '../services/logger_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import 'open_food_facts_service.dart';

/// Service for accessing USDA FoodData Central.
/// Provides high-accuracy nutritional data for branded and foundation foods.
class UsdaService {
  static final UsdaService instance = UsdaService._internal();
  UsdaService._internal();

  String get _apiKey => dotenv.env['USDA_API_KEY'] ?? '';
  static const String _baseUrl = 'api.nal.usda.gov';

  /// Search for foods by generic query or barcode.
  Future<List<FoodItem>> searchFoods(String query) async {
    if (_apiKey.isEmpty) {
      LoggerService().error(
        'USDA_API_KEY missing',
        null,
        reason: 'USDA search skipped: no API key in .env',
      );
      return const [];
    }
    final uri = Uri.https(_baseUrl, '/fdc/v1/foods/search', {
      'api_key': _apiKey,
      'query': query,
      'dataType': 'Branded,Foundation,SR Legacy',
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
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'USDA search failed');
      return const [];
    }
  }

  /// Specialized barcode lookup via Open Food Facts & USDA.
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    LoggerService().info('Looking up barcode: $cleanBarcode');

    // 1. Open Food Facts barcode endpoint (best coverage for MY/global EANs)
    final offItem =
        await OpenFoodFactsService.instance.getProductByBarcode(cleanBarcode);
    if (offItem != null) {
      LoggerService().info('Found in Open Food Facts: ${offItem.nameEn}');
      return offItem;
    }

    // 2. Fallback to USDA FoodData Central (for US branded/foundation foods),
    // trying EAN-13 vs UPC-A variants of the code.
    final candidates = [
      cleanBarcode,
      if (cleanBarcode.length == 12) '0$cleanBarcode',
      if (cleanBarcode.length == 13 && cleanBarcode.startsWith('0'))
        cleanBarcode.substring(1),
    ];
    for (final code in candidates) {
      final item = await _usdaByGtin(code);
      if (item != null) return item;
    }

    LoggerService().info(
        'Barcode $cleanBarcode not found in Open Food Facts or USDA.');
    return null;
  }

  /// USDA lookup by GTIN: the gtinUpc:-prefixed query is an exact-field match,
  /// so its first hit is trusted. The plain full-text fallback can match the
  /// digits anywhere, so a result is only accepted if its gtinUpc equals the
  /// scanned code.
  Future<FoodItem?> _usdaByGtin(String code) async {
    final prefixed = await searchFoods('gtinUpc:$code');
    if (prefixed.isNotEmpty) return prefixed.first;

    final plain = await searchFoods(code);
    for (final item in plain) {
      if (item.myfcdCode == code) return item;
    }
    return null;
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
          sodium = value; // USDA reports mg; the app uses mg throughout
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
    // servingSize can be labelled in oz; g and ml are treated as-is.
    var servingSize = (f['servingSize'] as num?)?.toDouble() ?? 150.0;
    final servingUnit = (f['servingSizeUnit'] as String? ?? '').toLowerCase();
    if (servingUnit.contains('oz')) servingSize *= 28.35;

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
