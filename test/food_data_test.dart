import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calor_ai/services/firestore_service.dart';
import 'package:calor_ai/services/ingredient_library_service.dart';

// Guards the offline-generated food asset (tool/merge_foods.py) and the
// search / ingredient-library paths that consume it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled food data is clean and complete', () async {
    final raw = await rootBundle.loadString('assets/data/myfcd_full.json');
    final foods = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    expect(foods.length, greaterThan(1900));

    final codes = foods.map((f) => f['myfcdCode']).toSet();
    expect(codes.length, foods.length, reason: 'codes must be unique');

    for (final f in foods) {
      final name = f['nameEn'] as String;
      expect(name, isNotEmpty);
      expect(name.contains(';'), isFalse, reason: 'junk in "$name"');
      expect(name == name.toUpperCase() && name.length > 3, isFalse,
          reason: 'ALL CAPS name "$name"');
      expect(f['foodGroup'], isNot(startsWith('Group ')),
          reason: 'unnormalized group for "$name"');
    }
  });

  test('search finds local staples by name', () async {
    final service = FirestoreService();
    for (final query in ['nasi lemak', 'kopi', 'chicken rice', 'you tiao']) {
      final results = await service.searchFoods(query, limit: 5);
      expect(results, isNotEmpty, reason: 'no results for "$query"');
    }
    final top = await service.searchFoods('nasi lemak', limit: 1);
    expect(top.first.nameEn.toLowerCase(), contains('nasi lemak'));
  });

  test('ingredient library groups by clean categories', () async {
    final lib = IngredientLibraryService.instance;
    await lib.loadLibrary();
    expect(lib.isLoaded, isTrue);

    final categories = lib.rawCategorizedItems.keys.toSet();
    expect(categories, contains('Meats, Poultry & Seafood'));
    expect(categories, contains('Fruits'));
    expect(categories, contains('Local & Mixed Dishes'));
    // The old broken mapping dumped hundreds of items here; now it's tiny.
    final misc = lib.rawCategorizedItems['Other / Miscellaneous'] ?? [];
    expect(misc.length, lessThan(20));

    final meats = lib.rawCategorizedItems['Meats, Poultry & Seafood']!;
    expect(meats.any((i) => i.nameEn == 'Chicken Breast'), isTrue);

    expect(lib.allBrandedItems, isNotEmpty);
  });
}
