import 'dart:convert';
import '../services/logger_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/food_item.dart';

class IngredientLibraryService {
  IngredientLibraryService._private();
  static final IngredientLibraryService instance =
      IngredientLibraryService._private();

  bool _isLoaded = false;
  List<FoodItem> _allRawItems = [];
  List<FoodItem> _allBrandedItems = [];
  Map<String, List<FoodItem>> _rawCategorizedItems = {};
  Map<String, List<FoodItem>> _brandedCategorizedItems = {};

  bool get isLoaded => _isLoaded;
  Map<String, List<FoodItem>> get rawCategorizedItems => _rawCategorizedItems;
  Map<String, List<FoodItem>> get brandedCategorizedItems =>
      _brandedCategorizedItems;
  List<FoodItem> get allRawItems => _allRawItems;
  List<FoodItem> get allBrandedItems => _allBrandedItems;

  Future<void> loadLibrary() async {
    if (_isLoaded) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/myfcd_full.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final allParsed = jsonList.map((map) {
        final m = map as Map<String, dynamic>;
        return FoodItem.fromMap(m['myfcdCode'] as String, m);
      }).toList();

      _allBrandedItems =
          allParsed.where((i) => i.source == 'MyFCD_Industry').toList();
      _allRawItems =
          allParsed.where((i) => i.source != 'MyFCD_Industry').toList();

      _rawCategorizedItems = _groupItems(_allRawItems);
      _brandedCategorizedItems = _groupItems(_allBrandedItems);
      _isLoaded = true;
    } catch (e, stack) {
      LoggerService()
          .error(e, stack, reason: 'Failed to load ingredient library');
    }
  }

  Map<String, List<FoodItem>> _groupItems(List<FoodItem> items) {
    final Map<String, List<FoodItem>> grouped = {};

    // foodGroup is already a human-readable category, normalized offline
    // by tool/merge_foods.py. Anything unnormalized (e.g. legacy "Group 12"
    // codes from a stale asset) falls back to the misc bucket instead of
    // leaking raw IDs into the UI.
    for (final item in items) {
      final group = item.foodGroup;
      final category = group.isEmpty || group.startsWith('Group')
          ? 'Other / Miscellaneous'
          : group;
      (grouped[category] ??= []).add(item);
    }

    // Sort items alphabetically within each category
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.nameEn.compareTo(b.nameEn));
    }

    return grouped;
  }

  List<FoodItem> searchLibrary(String query, {required bool isBranded}) {
    if (query.trim().isEmpty) return [];
    final searchTerms = query.toLowerCase().split(' ');
    final items = isBranded ? _allBrandedItems : _allRawItems;

    return items
        .where((item) {
          final nameStr = '${item.nameEn} ${item.nameMy}'.toLowerCase();
          // Simple AND matching
          return searchTerms.every((term) => nameStr.contains(term));
        })
        .take(30)
        .toList();
  }
}
