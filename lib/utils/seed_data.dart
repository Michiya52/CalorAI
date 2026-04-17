import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

Future<void> seedFoodsDatabase() async {
  if (!(kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows)) {
    debugPrint('Firestore seeding skipped on unsupported platform.');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final foodsRef = firestore.collection('foods');

  debugPrint(
      'Seeding Firestore Database with multi-source government food data...');

  final List<Map<String, dynamic>> initialFoods = [
    {
      'nameEn': 'Nasi Lemak',
      'nameMy': 'Nasi Lemak',
      'nameEnLower': 'nasi lemak',
      'nameMyLower': 'nasi lemak',
      'searchTerms': ['nasi', 'lemak', 'nasi lemak'],
      'foodGroup': 'Rice Dishes',
      'myfcdCode': 'MFC001',
      'caloriesPer100g': 162.5,
      'proteinPer100g': 4.2,
      'carbsPer100g': 22.1,
      'fatsPer100g': 6.8,
      'sodiumPer100g': 280.0,
      'sugarPer100g': 1.2,
      'portionSizes': {
        'smallGrams': 200,
        'mediumGrams': 350,
        'largeGrams': 500,
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Roti Canai',
      'nameMy': 'Roti Canai',
      'nameEnLower': 'roti canai',
      'nameMyLower': 'roti canai',
      'searchTerms': ['roti', 'canai', 'roti canai', 'prata'],
      'foodGroup': 'Breads',
      'myfcdCode': 'MFC002',
      'caloriesPer100g': 301.0,
      'proteinPer100g': 6.5,
      'carbsPer100g': 45.0,
      'fatsPer100g': 10.2,
      'sodiumPer100g': 320.0,
      'sugarPer100g': 2.5,
      'portionSizes': {
        'smallGrams': 80, // 1 piece
        'mediumGrams': 160, // 2 pieces
        'largeGrams': 240, // 3 pieces
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Mee Goreng',
      'nameMy': 'Mee Goreng',
      'nameEnLower': 'mee goreng',
      'nameMyLower': 'mee goreng',
      'searchTerms': ['mee', 'goreng', 'mee goreng', 'fried', 'noodles'],
      'foodGroup': 'Noodle Dishes',
      'myfcdCode': 'MFC003',
      'caloriesPer100g': 180.0,
      'proteinPer100g': 5.0,
      'carbsPer100g': 24.0,
      'fatsPer100g': 7.5,
      'sodiumPer100g': 450.0,
      'sugarPer100g': 3.0,
      'portionSizes': {
        'smallGrams': 250,
        'mediumGrams': 350,
        'largeGrams': 500,
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Teh Tarik',
      'nameMy': 'Teh Tarik',
      'nameEnLower': 'teh tarik',
      'nameMyLower': 'teh tarik',
      'searchTerms': ['teh', 'tarik', 'teh tarik', 'milk', 'tea', 'sweet'],
      'foodGroup': 'Beverages',
      'myfcdCode': 'MFC004',
      'caloriesPer100g': 45.0,
      'proteinPer100g': 0.8,
      'carbsPer100g': 8.5,
      'fatsPer100g': 0.9,
      'sodiumPer100g': 30.0,
      'sugarPer100g': 8.0,
      'portionSizes': {
        'smallGrams': 150,
        'mediumGrams': 250, // Standard glass
        'largeGrams': 400,
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Chicken Satay',
      'nameMy': 'Sate Ayam',
      'nameEnLower': 'chicken satay',
      'nameMyLower': 'sate ayam',
      'searchTerms': ['sate', 'ayam', 'satay', 'chicken', 'skewers', 'peanut'],
      'foodGroup': 'Meats',
      'myfcdCode': 'MFC005',
      'caloriesPer100g': 200.0,
      'proteinPer100g': 18.0,
      'carbsPer100g': 5.0,
      'fatsPer100g': 12.0,
      'sodiumPer100g': 350.0,
      'sugarPer100g': 4.0,
      'portionSizes': {
        'smallGrams': 75, // 5 sticks
        'mediumGrams': 150, // 10 sticks
        'largeGrams': 225, // 15 sticks
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Laksa',
      'nameMy': 'Laksa',
      'nameEnLower': 'laksa',
      'nameMyLower': 'laksa',
      'searchTerms': ['laksa', 'curry', 'noodles', 'soup', 'spicy'],
      'foodGroup': 'Noodle Dishes',
      'myfcdCode': 'MFC006',
      'caloriesPer100g': 110.0,
      'proteinPer100g': 4.5,
      'carbsPer100g': 12.0,
      'fatsPer100g': 5.0,
      'sodiumPer100g': 400.0,
      'sugarPer100g': 2.0,
      'portionSizes': {
        'smallGrams': 300,
        'mediumGrams': 450,
        'largeGrams': 600,
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Beef Rendang',
      'nameMy': 'Rendang Daging',
      'nameEnLower': 'beef rendang',
      'nameMyLower': 'rendang daging',
      'searchTerms': ['rendang', 'daging', 'beef', 'curry', 'spicy', 'meat'],
      'foodGroup': 'Meats',
      'myfcdCode': 'MFC007',
      'caloriesPer100g': 240.0,
      'proteinPer100g': 20.0,
      'carbsPer100g': 6.0,
      'fatsPer100g': 15.0,
      'sodiumPer100g': 400.0,
      'sugarPer100g': 3.0,
      'portionSizes': {
        'smallGrams': 100,
        'mediumGrams': 150,
        'largeGrams': 250,
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Hainanese Chicken Rice',
      'nameMy': 'Nasi Ayam Hainan',
      'nameEnLower': 'hainanese chicken rice',
      'nameMyLower': 'nasi ayam hainan',
      'searchTerms': ['hainan', 'chicken', 'rice', 'nasi', 'ayam', 'roasted'],
      'foodGroup': 'Rice Dishes',
      'myfcdCode': 'MFC008',
      'caloriesPer100g': 160.0,
      'proteinPer100g': 6.0,
      'carbsPer100g': 20.0,
      'fatsPer100g': 6.0,
      'sodiumPer100g': 300.0,
      'sugarPer100g': 1.0,
      'portionSizes': {
        'smallGrams': 250,
        'mediumGrams': 380,
        'largeGrams': 500,
      },
      'source': 'MyFCD_2026',
    },
    {
      'nameEn': 'Oatmeal, Cooked',
      'nameMy': 'Bubur Oat',
      'nameEnLower': 'oatmeal, cooked',
      'nameMyLower': 'bubur oat',
      'searchTerms': ['oatmeal', 'oat', 'porridge', 'bubur oat'],
      'foodGroup': 'Cereals',
      'myfcdCode': 'USDA001',
      'caloriesPer100g': 68.0,
      'proteinPer100g': 2.4,
      'carbsPer100g': 12.0,
      'fatsPer100g': 1.4,
      'sodiumPer100g': 49.0,
      'sugarPer100g': 0.5,
      'portionSizes': {
        'smallGrams': 120,
        'mediumGrams': 180,
        'largeGrams': 250,
      },
      'source': 'USDA_FDC_2024',
    },
    {
      'nameEn': 'Grilled Chicken Breast',
      'nameMy': 'Dada Ayam Bakar',
      'nameEnLower': 'grilled chicken breast',
      'nameMyLower': 'dada ayam bakar',
      'searchTerms': ['grilled chicken', 'chicken breast', 'ayam bakar'],
      'foodGroup': 'Meats',
      'myfcdCode': 'USDA002',
      'caloriesPer100g': 165.0,
      'proteinPer100g': 31.0,
      'carbsPer100g': 0.0,
      'fatsPer100g': 3.6,
      'sodiumPer100g': 74.0,
      'sugarPer100g': 0.0,
      'portionSizes': {
        'smallGrams': 90,
        'mediumGrams': 140,
        'largeGrams': 220,
      },
      'source': 'USDA_FDC_2024',
    },
    {
      'nameEn': 'Kaya Toast',
      'nameMy': 'Roti Kaya',
      'nameEnLower': 'kaya toast',
      'nameMyLower': 'roti kaya',
      'searchTerms': ['kaya toast', 'roti kaya', 'toast'],
      'foodGroup': 'Breads',
      'myfcdCode': 'SG001',
      'caloriesPer100g': 294.0,
      'proteinPer100g': 7.2,
      'carbsPer100g': 44.0,
      'fatsPer100g': 9.8,
      'sodiumPer100g': 340.0,
      'sugarPer100g': 13.0,
      'portionSizes': {
        'smallGrams': 60,
        'mediumGrams': 95,
        'largeGrams': 140,
      },
      'source': 'SG_FOCOS_2024',
    },
    {
      'nameEn': 'Fishball Noodles',
      'nameMy': 'Mi Bebola Ikan',
      'nameEnLower': 'fishball noodles',
      'nameMyLower': 'mi bebola ikan',
      'searchTerms': ['fishball noodles', 'mee', 'mi', 'bebola ikan'],
      'foodGroup': 'Noodle Dishes',
      'myfcdCode': 'SG002',
      'caloriesPer100g': 132.0,
      'proteinPer100g': 6.3,
      'carbsPer100g': 19.0,
      'fatsPer100g': 3.1,
      'sodiumPer100g': 470.0,
      'sugarPer100g': 1.8,
      'portionSizes': {
        'smallGrams': 220,
        'mediumGrams': 330,
        'largeGrams': 460,
      },
      'source': 'SG_FOCOS_2024',
    },
    {
      'nameEn': 'Chicken Curry Puff',
      'nameMy': 'Karipap Ayam',
      'nameEnLower': 'chicken curry puff',
      'nameMyLower': 'karipap ayam',
      'searchTerms': ['curry puff', 'karipap', 'chicken curry puff'],
      'foodGroup': 'Snacks',
      'myfcdCode': 'SG003',
      'caloriesPer100g': 321.0,
      'proteinPer100g': 8.2,
      'carbsPer100g': 29.0,
      'fatsPer100g': 18.4,
      'sodiumPer100g': 390.0,
      'sugarPer100g': 2.4,
      'portionSizes': {
        'smallGrams': 45,
        'mediumGrams': 70,
        'largeGrams': 110,
      },
      'source': 'SG_FOCOS_2024',
    },
    {
      'nameEn': 'Avocado Toast',
      'nameMy': 'Roti Bakar Avokado',
      'nameEnLower': 'avocado toast',
      'nameMyLower': 'roti bakar avokado',
      'searchTerms': ['avocado toast', 'toast', 'roti bakar avokado'],
      'foodGroup': 'Breads',
      'myfcdCode': 'AUS001',
      'caloriesPer100g': 210.0,
      'proteinPer100g': 6.1,
      'carbsPer100g': 23.5,
      'fatsPer100g': 10.2,
      'sodiumPer100g': 280.0,
      'sugarPer100g': 2.3,
      'portionSizes': {
        'smallGrams': 70,
        'mediumGrams': 115,
        'largeGrams': 170,
      },
      'source': 'AUSNUT_2011_13',
    },
    {
      'nameEn': 'Pumpkin Soup',
      'nameMy': 'Sup Labu',
      'nameEnLower': 'pumpkin soup',
      'nameMyLower': 'sup labu',
      'searchTerms': ['pumpkin soup', 'soup', 'sup labu'],
      'foodGroup': 'Soups',
      'myfcdCode': 'AUS002',
      'caloriesPer100g': 55.0,
      'proteinPer100g': 1.6,
      'carbsPer100g': 8.7,
      'fatsPer100g': 1.4,
      'sodiumPer100g': 210.0,
      'sugarPer100g': 3.8,
      'portionSizes': {
        'smallGrams': 180,
        'mediumGrams': 280,
        'largeGrams': 420,
      },
      'source': 'AUSNUT_2011_13',
    },
    {
      'nameEn': 'Baked Beans on Toast',
      'nameMy': 'Roti Bakar Kacang Panggang',
      'nameEnLower': 'baked beans on toast',
      'nameMyLower': 'roti bakar kacang panggang',
      'searchTerms': ['baked beans', 'toast', 'beans on toast'],
      'foodGroup': 'Breads',
      'myfcdCode': 'UK001',
      'caloriesPer100g': 142.0,
      'proteinPer100g': 6.0,
      'carbsPer100g': 22.0,
      'fatsPer100g': 2.7,
      'sodiumPer100g': 320.0,
      'sugarPer100g': 4.8,
      'portionSizes': {
        'smallGrams': 120,
        'mediumGrams': 190,
        'largeGrams': 270,
      },
      'source': 'UK_MCCANCE_2021',
    },
    {
      'nameEn': 'Lentil Soup',
      'nameMy': 'Sup Lentil',
      'nameEnLower': 'lentil soup',
      'nameMyLower': 'sup lentil',
      'searchTerms': ['lentil soup', 'lentil', 'sup lentil'],
      'foodGroup': 'Soups',
      'myfcdCode': 'UK002',
      'caloriesPer100g': 78.0,
      'proteinPer100g': 4.3,
      'carbsPer100g': 12.0,
      'fatsPer100g': 1.1,
      'sodiumPer100g': 250.0,
      'sugarPer100g': 1.6,
      'portionSizes': {
        'smallGrams': 180,
        'mediumGrams': 280,
        'largeGrams': 420,
      },
      'source': 'UK_MCCANCE_2021',
    },
  ];

  final myfcdFull = await _loadFoodAsset('assets/data/myfcd_full.json');
  final sgfocosFull = await _loadFoodAsset('assets/data/sgfocos_full.json');

  final mergedByCode = <String, Map<String, dynamic>>{};
  for (final food in [...initialFoods, ...myfcdFull, ...sgfocosFull]) {
    final code = (food['myfcdCode'] as String?)?.trim();
    if (code == null || code.isEmpty) continue;
    mergedByCode[code] = food;
  }

  final foodsToSeed = mergedByCode.values.toList();

  if (foodsToSeed.isEmpty) {
    debugPrint('No foods available to seed.');
    return;
  }

  const chunkSize = 400;
  var seededCount = 0;
  try {
    for (var i = 0; i < foodsToSeed.length; i += chunkSize) {
      final end = (i + chunkSize < foodsToSeed.length)
          ? i + chunkSize
          : foodsToSeed.length;
      final chunk = foodsToSeed.sublist(i, end);
      final batch = firestore.batch();

      for (final food in chunk) {
        final docRef = foodsRef.doc(food['myfcdCode'] as String);
        batch.set(docRef, food, SetOptions(merge: true));
      }

      await batch.commit();
      seededCount += chunk.length;
    }

    debugPrint(
        'Successfully seeded $seededCount foods into Firestore (multi-source government collection).');
  } catch (e) {
    debugPrint('FAILED to seed MyFCD database: $e');
    debugPrint(
        'Please check your internet connection or Firestore permissions.');
  }
}

Future<List<Map<String, dynamic>>> _loadFoodAsset(String assetPath) async {
  try {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  } catch (_) {
    return [];
  }
}
