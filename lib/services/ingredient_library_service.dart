import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/food_item.dart';

class IngredientLibraryService {
  IngredientLibraryService._private();
  static final IngredientLibraryService instance = IngredientLibraryService._private();

  bool _isLoaded = false;
  List<FoodItem> _allRawItems = [];
  List<FoodItem> _allBrandedItems = [];
  Map<String, List<FoodItem>> _rawCategorizedItems = {};
  Map<String, List<FoodItem>> _brandedCategorizedItems = {};

  bool get isLoaded => _isLoaded;
  Map<String, List<FoodItem>> get rawCategorizedItems => _rawCategorizedItems;
  Map<String, List<FoodItem>> get brandedCategorizedItems => _brandedCategorizedItems;
  List<FoodItem> get allRawItems => _allRawItems;
  List<FoodItem> get allBrandedItems => _allBrandedItems;

  Future<void> loadLibrary() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/myfcd_full.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final allParsed = jsonList.map((map) {
        final m = map as Map<String, dynamic>;
        return FoodItem.fromMap(m['myfcdCode'] as String, m);
      }).toList();

      _allBrandedItems = allParsed.where((i) => i.source == 'MyFCD_Industry').toList();
      _allRawItems = allParsed.where((i) => i.source != 'MyFCD_Industry').toList();

      _rawCategorizedItems = _groupItems(_allRawItems);
      _brandedCategorizedItems = _groupItems(_allBrandedItems);
      _isLoaded = true;
    } catch (e) {
      debugPrint('Failed to load ingredient library: $e');
    }
  }

  Map<String, List<FoodItem>> _groupItems(List<FoodItem> items) {
    final Map<String, List<FoodItem>> grouped = {};

    for (final item in items) {
      // Remove calorie filter to allow spices, water, beverages, etc.
      final simplifiedItem = item.copyWith(
        nameEn: _simplifyName(item.nameEn),
        nameMy: _simplifyName(item.nameMy),
      );

      final category = _mapGroupToCategory(item.foodGroup);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(simplifiedItem);
    }

    // Sort items alphabetically within each category
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.nameEn.compareTo(b.nameEn));
    }

    return grouped;
  }

  String _simplifyName(String name) {
    if (name.isEmpty) return name;
    
    // Split by commas
    final parts = name.split(',').map((p) => p.trim()).toList();
    
    // If it's something like "CHICKEN, BREAST, RAW" -> "Chicken Breast, Raw"
    final cleanParts = parts.map((p) {
      if (p.isEmpty) return p;
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).toList();

    // Heuristic: If there are 3 parts, the middle one is often the specific type
    // e.g. "CABBAGE, CHINESE, RAW" -> "Chinese Cabbage, Raw"
    if (parts.length >= 2) {
      // Common pattern: Main Item, Subtype, Detail
      return cleanParts.join(', ');
    }

    return cleanParts.first;
  }

  String _mapGroupToCategory(String groupId) {
    if (groupId.startsWith('Group 1.') || groupId == 'Group 1') {
      return 'Grains, Noodles & Starches';
    } else if (groupId.startsWith('Group 2.') || groupId == 'Group 2' || groupId == 'Group 4') {
      return 'Vegetables & Legumes';
    } else if (groupId == 'Group 3') {
      return 'Fruits';
    } else if (groupId == 'Group 5') {
      return 'Nuts & Seeds';
    } else if (groupId == 'Group 6' || groupId == 'Group 7') {
      return 'Meats, Poultry & Seafood';
    } else if (groupId == 'Group 8' || groupId == 'Group 9') {
      return 'Dairy & Eggs';
    } else if (groupId == 'Group 10') {
      return 'Fats & Oils';
    } else if (groupId == 'Group 12') {
      return 'Beverages';
    } else if (groupId == 'Group 13') {
      return 'Spices, Condiments & Sauces';
    } else if (groupId == 'Group 11' || groupId.startsWith('Group 23') || groupId.startsWith('Group 24') || groupId.startsWith('Group 25')) {
      return 'Desserts & Sweets';
    } else {
      return 'Other / Miscellaneous';
    }
  }

  List<FoodItem> searchLibrary(String query, {required bool isBranded}) {
    if (query.trim().isEmpty) return [];
    final searchTerms = query.toLowerCase().split(' ');
    final items = isBranded ? _allBrandedItems : _allRawItems;
    
    return items.where((item) {
      final nameStr = '${item.nameEn} ${item.nameMy}'.toLowerCase();
      // Simple AND matching
      return searchTerms.every((term) => nameStr.contains(term));
    }).take(30).toList();
  }
}
