import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

/// Service for accessing Open Food Facts (OFF) via robust HTTP calls.
/// Replaces the potentially unreliable SDK with direct API interaction.
class OpenFoodFactsService {
  static final OpenFoodFactsService instance = OpenFoodFactsService._internal();
  OpenFoodFactsService._internal();

  static const String _baseUrl = 'api.openfoodfacts.org';
  static const String _userAgent =
      'CalorAI - Malaysian Nutrition Tracker - Version 1.0 (info@calor.ai)';

  /// Search for foods by query with Malaysian focus.
  Future<List<FoodItem>> searchFoods(String query, {int page = 1}) async {
    final uri = Uri.https(_baseUrl, '/cgi/search.pl', {
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page': '$page',
      'page_size': '20',
      'cc': 'my', // Malaysian products priority
    });

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body);
      final products = data['products'] as List?;
      if (products == null) return const [];

      return products
          .map((p) => _mapOffToFoodItem(p))
          .whereType<FoodItem>()
          .toList();
    } catch (e) {
      debugPrint('OFF search failed: $e');
      return const [];
    }
  }

  /// Look up a single product by barcode.
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final uri = Uri.https(_baseUrl, '/api/v2/product/$barcode.json');

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 1) return null;

      return _mapOffToFoodItem(data['product']);
    } catch (e) {
      debugPrint('OFF barcode lookup failed: $e');
      return null;
    }
  }

  FoodItem? _mapOffToFoodItem(Map<String, dynamic> p) {
    final name = (p['product_name'] as String?)?.trim() ??
        (p['generic_name'] as String?)?.trim() ??
        '';
    if (name.isEmpty) return null;

    final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};

    // OFF uses 'energy-kcal_100g' or 'energy-kj_100g'
    final kcal = (nutriments['energy-kcal_100g'] as num?)?.toDouble() ??
        ((nutriments['energy-kj_100g'] as num?)?.toDouble() ?? 0) / 4.184;

    if (kcal <= 0) return null;

    final id = 'off_${p['code'] ?? name.hashCode}';
    final servingSize =
        _parseServingSize(p['serving_size'] as String? ?? '150g');

    return FoodItem(
      id: id,
      nameEn: name,
      nameMy: name,
      foodGroup: (p['categories_tags'] as List?)
              ?.first
              ?.toString()
              .replaceAll('en:', '') ??
          'General',
      caloriesPer100g: kcal,
      proteinPer100g: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
      fatsPer100g: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0,
      sodiumPer100g: (nutriments['sodium_100g'] as num?)?.toDouble() ?? 0,
      sugarPer100g: (nutriments['sugars_100g'] as num?)?.toDouble() ?? 0,
      portionSizes: PortionSizes(
        smallGrams: (servingSize * 0.6).roundToDouble(),
        mediumGrams: servingSize.roundToDouble(),
        largeGrams: (servingSize * 1.5).roundToDouble(),
      ),
      source: 'OpenFoodFacts',
      myfcdCode: p['code'] ?? id,
    );
  }

  double _parseServingSize(String text) {
    final match = RegExp(r'(\d+)\s*g').firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 150.0;
    }
    return 150.0;
  }
}
