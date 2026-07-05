import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Bump this when you update the food dataset to force a re-seed.
const String _seedVersion = 'v16';
const String _seedVersionKey = 'food_seed_version';

Future<void> seedFoodsDatabase() async {
  if (!(kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows)) {
    debugPrint('Firestore seeding skipped on unsupported platform.');
    return;
  }

  // ── Guard: skip if already seeded at this version ──────────────
  final prefs = await SharedPreferences.getInstance();
  final seededVersion = prefs.getString(_seedVersionKey);
  if (seededVersion == _seedVersion) {
    debugPrint('Food database already seeded (v$_seedVersion). Skipping.');
    return;
  }

  final firestore = FirebaseFirestore.instance;
  final foodsRef = firestore.collection('foods');

  debugPrint('Refining and Seeding Firestore Database (v13)...');

  // ── 0. CLEAR OLD DATA TO PREVENT DUPLICATES ───────────────
  debugPrint('Clearing old food documents before re-seeding...');
  try {
    final oldDocs = await foodsRef.get();
    var deletedCount = 0;
    const deleteChunkSize = 400;
    for (var i = 0; i < oldDocs.docs.length; i += deleteChunkSize) {
      final end = (i + deleteChunkSize < oldDocs.docs.length)
          ? i + deleteChunkSize
          : oldDocs.docs.length;
      final chunk = oldDocs.docs.sublist(i, end);
      final batch = firestore.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deletedCount += chunk.length;
    }
    debugPrint('Cleared $deletedCount old documents. Database is clean.');
  } catch (e) {
    debugPrint('FAILED to clear old documents: $e');
  }

  // ── 1. Malaysian & Singaporean Essentials (Hawker & Packaged) ──
  // Hand-curated list with precise local portion sizes and ingredients.
  final List<Map<String, dynamic>> curatedEssentials = [
    {
      "nameEn": "Beef Rendang",
      "nameMy": "Rendang Daging",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 195.0,
      "proteinPer100g": 14.0,
      "carbsPer100g": 8.0,
      "fatsPer100g": 11.5,
      "sodiumPer100g": 340.0,
      "sugarPer100g": 3.0,
      "ingredients": [
        "Beef chunks",
        "Coconut milk",
        "Lemongrass",
        "Galangal",
        "Kerisik",
        "Chili paste"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 150,
        "largeGrams": 250
      },
      "source": "Curated",
      "myfcdCode": "ESS031"
    },
    {
      "nameEn": "Kaya Toast",
      "nameMy": "Roti Bakar Kaya",
      "foodGroup": "Breads",
      "caloriesPer100g": 380.0,
      "proteinPer100g": 7.0,
      "carbsPer100g": 52.0,
      "fatsPer100g": 16.0,
      "sodiumPer100g": 420.0,
      "sugarPer100g": 18.0,
      "ingredients": ["White Bread", "Butter", "Kaya (Coconut Jam)"],
      "portionSizes": {"smallGrams": 50, "mediumGrams": 100, "largeGrams": 150},
      "source": "Curated",
      "myfcdCode": "ESS032"
    },
    {
      "nameEn": "Teh Tarik",
      "nameMy": "Teh Tarik",
      "foodGroup": "Beverages",
      "caloriesPer100g": 65.0,
      "proteinPer100g": 1.5,
      "carbsPer100g": 11.0,
      "fatsPer100g": 1.8,
      "sodiumPer100g": 45.0,
      "sugarPer100g": 10.5,
      "ingredients": [
        "Black Tea",
        "Condensed Milk",
        "Evaporated Milk",
        "Hot Water"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 300,
        "largeGrams": 450
      },
      "source": "Curated",
      "myfcdCode": "ESS033"
    },
    {
      "nameEn": "Ayam Penyet",
      "nameMy": "Ayam Penyet",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 265.0,
      "proteinPer100g": 18.5,
      "carbsPer100g": 10.0,
      "fatsPer100g": 16.5,
      "sodiumPer100g": 510.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Chicken piece",
        "Spices",
        "Sambal",
        "Tempeh",
        "Tofu",
        "Cabbage",
        "Cooking Oil"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS034"
    },
    {
      "nameEn": "Bak Kut Teh",
      "nameMy": "Bak Kut Teh",
      "foodGroup": "Soups",
      "caloriesPer100g": 115.0,
      "proteinPer100g": 10.5,
      "carbsPer100g": 4.0,
      "fatsPer100g": 6.5,
      "sodiumPer100g": 420.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Pork Ribs",
        "Herbal Broth",
        "Garlic",
        "Tofu Puffs",
        "Enoki Mushrooms"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 500,
        "largeGrams": 750
      },
      "source": "Curated",
      "myfcdCode": "ESS035"
    },
    {
      "nameEn": "Chicken Rice (Steamed/Roasted)",
      "nameMy": "Nasi Ayam",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 155.0,
      "proteinPer100g": 8.5,
      "carbsPer100g": 22.0,
      "fatsPer100g": 4.5,
      "sodiumPer100g": 280.0,
      "sugarPer100g": 0.8,
      "ingredients": [
        "White Rice",
        "Chicken Fat/Broth",
        "Chicken (Steamed or Roasted)",
        "Cucumber",
        "Chili Sauce",
        "Dark Soy Sauce",
        "Ginger Paste"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 550
      },
      "source": "Curated",
      "myfcdCode": "ESS022"
    },
    {
      "nameEn": "Penang Asam Laksa",
      "nameMy": "Asam Laksa",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 95.0,
      "proteinPer100g": 4.5,
      "carbsPer100g": 16.0,
      "fatsPer100g": 1.5,
      "sodiumPer100g": 320.0,
      "sugarPer100g": 2.5,
      "ingredients": [
        "Thick Rice Noodles",
        "Mackerel Fish",
        "Tamarind",
        "Pineapple",
        "Cucumber",
        "Mint Leaves",
        "Torch Ginger Flower",
        "Prawn Paste"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS023"
    },
    {
      "nameEn": "Curry Mee",
      "nameMy": "Mee Kari",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 135.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 15.0,
      "fatsPer100g": 6.5,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 1.2,
      "ingredients": [
        "Yellow Noodles",
        "Coconut Milk",
        "Curry Spices",
        "Tofu Puffs",
        "Cockles",
        "Chicken",
        "Long Beans"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS024"
    },
    {
      "nameEn": "Char Kuey Teow",
      "nameMy": "Kuey Teow Goreng",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 195.0,
      "proteinPer100g": 6.5,
      "carbsPer100g": 24.0,
      "fatsPer100g": 8.0,
      "sodiumPer100g": 400.0,
      "sugarPer100g": 1.0,
      "ingredients": [
        "Flat Rice Noodles",
        "Prawns",
        "Cockles",
        "Egg",
        "Bean Sprouts",
        "Chives",
        "Dark Soy Sauce",
        "Lard/Oil"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS025"
    },
    {
      "nameEn": "Hokkien Mee (KL)",
      "nameMy": "Hokkien Mee",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 185.0,
      "proteinPer100g": 7.0,
      "carbsPer100g": 23.0,
      "fatsPer100g": 7.5,
      "sodiumPer100g": 420.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Thick Yellow Noodles",
        "Dark Soy Sauce",
        "Pork Slices",
        "Prawns",
        "Cabbage",
        "Crispy Pork Lard"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 550
      },
      "source": "Curated",
      "myfcdCode": "ESS026"
    },
    {
      "nameEn": "Laksa Lemak",
      "nameMy": "Laksa Nyonya",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 145.0,
      "proteinPer100g": 5.5,
      "carbsPer100g": 14.5,
      "fatsPer100g": 7.5,
      "sodiumPer100g": 360.0,
      "sugarPer100g": 2.0,
      "ingredients": [
        "Thick Rice Noodles",
        "Coconut Milk",
        "Curry Paste",
        "Prawns",
        "Fish Cake",
        "Bean Sprouts",
        "Laksa Leaves"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS027"
    },
    {
      "nameEn": "Roti Canai",
      "nameMy": "Roti Prata",
      "foodGroup": "Breads",
      "caloriesPer100g": 302.0,
      "proteinPer100g": 6.8,
      "carbsPer100g": 41.5,
      "fatsPer100g": 11.2,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 1.5,
      "ingredients": ["Wheat Flour", "Ghee", "Water", "Salt", "Condensed Milk"],
      "portionSizes": {"smallGrams": 80, "mediumGrams": 120, "largeGrams": 200},
      "source": "Curated",
      "myfcdCode": "ESS028"
    },
    {
      "nameEn": "Mee Goreng Mamak",
      "nameMy": "Mee Goreng",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 182.0,
      "proteinPer100g": 5.8,
      "carbsPer100g": 21.0,
      "fatsPer100g": 8.5,
      "sodiumPer100g": 410.0,
      "sugarPer100g": 2.2,
      "ingredients": [
        "Yellow Noodles",
        "Tofu",
        "Potatoes",
        "Fritters",
        "Egg",
        "Soy Sauce",
        "Tomato Ketchup",
        "Chili Paste"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS029"
    },
    {
      "nameEn": "Nasi Goreng Kampung",
      "nameMy": "Nasi Goreng",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 175.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 22.0,
      "fatsPer100g": 7.0,
      "sodiumPer100g": 320.0,
      "sugarPer100g": 0.8,
      "ingredients": [
        "White Rice",
        "Anchovies",
        "Water Spinach (Kangkung)",
        "Bird's Eye Chili",
        "Shrimp Paste",
        "Egg",
        "Oil"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS030"
    },
    {
      "nameEn": "Wan Tan Mee (Dry)",
      "nameMy": "Mee Wantan",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 190.0,
      "proteinPer100g": 8.0,
      "carbsPer100g": 25.0,
      "fatsPer100g": 6.5,
      "sodiumPer100g": 450.0,
      "sugarPer100g": 1.2,
      "ingredients": [
        "Egg Noodles",
        "Char Siew (BBQ Pork/Chicken)",
        "Wontons",
        "Choy Sum",
        "Dark Soy Sauce",
        "Lard/Oil"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 300,
        "largeGrams": 450
      },
      "source": "Curated",
      "myfcdCode": "ESS031"
    },
    {
      "nameEn": "Bak Kut Teh",
      "nameMy": "Bak Kut Teh",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 125.0,
      "proteinPer100g": 12.0,
      "carbsPer100g": 2.5,
      "fatsPer100g": 7.5,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Pork Ribs",
        "Herbal Broth",
        "Garlic",
        "Enoki Mushrooms",
        "Tofu Puffs",
        "Lettuce",
        "Soy Sauce"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 650
      },
      "source": "Curated",
      "myfcdCode": "ESS032"
    },
    {
      "nameEn": "Chicken Satay",
      "nameMy": "Sate Ayam",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 210.0,
      "proteinPer100g": 18.5,
      "carbsPer100g": 11.0,
      "fatsPer100g": 10.0,
      "sodiumPer100g": 350.0,
      "sugarPer100g": 7.5,
      "ingredients": [
        "Chicken",
        "Lemongrass",
        "Turmeric",
        "Sugar",
        "Peanut Sauce",
        "Cucumber",
        "Onion"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "ESS033"
    },
    {
      "nameEn": "Kaya Toast",
      "nameMy": "Roti Bakar Kaya",
      "foodGroup": "Breads",
      "caloriesPer100g": 355.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 52.0,
      "fatsPer100g": 13.5,
      "sodiumPer100g": 290.0,
      "sugarPer100g": 15.0,
      "ingredients": ["White Bread", "Kaya (Coconut Jam)", "Butter"],
      "portionSizes": {"smallGrams": 60, "mediumGrams": 120, "largeGrams": 180},
      "source": "Curated",
      "myfcdCode": "ESS034"
    },
    {
      "nameEn": "Teh Tarik",
      "nameMy": "Teh Tarik",
      "foodGroup": "Beverages",
      "caloriesPer100g": 52.0,
      "proteinPer100g": 1.2,
      "carbsPer100g": 8.5,
      "fatsPer100g": 1.5,
      "sodiumPer100g": 35.0,
      "sugarPer100g": 8.0,
      "ingredients": [
        "Black Tea",
        "Condensed Milk",
        "Evaporated Milk",
        "Water"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 300,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS035"
    },
    {
      "nameEn": "Cendol",
      "nameMy": "Cendol",
      "foodGroup": "Desserts",
      "caloriesPer100g": 115.0,
      "proteinPer100g": 1.5,
      "carbsPer100g": 18.0,
      "fatsPer100g": 4.5,
      "sodiumPer100g": 85.0,
      "sugarPer100g": 12.0,
      "ingredients": [
        "Shaved Ice",
        "Coconut Milk",
        "Palm Sugar (Gula Melaka)",
        "Green Jelly Noodles",
        "Red Beans"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 300,
        "largeGrams": 450
      },
      "source": "Curated",
      "myfcdCode": "ESS036"
    },
    {
      "nameEn": "Pan Mee",
      "nameMy": "Pan Mee",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 145.0,
      "proteinPer100g": 6.5,
      "carbsPer100g": 19.5,
      "fatsPer100g": 4.0,
      "sodiumPer100g": 320.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Hand-torn Wheat Noodles",
        "Anchovy Broth",
        "Fried Anchovies",
        "Minced Pork/Chicken",
        "Sayur Manis",
        "Mushrooms"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS037"
    },
    {
      "nameEn": "Roti Jala",
      "nameMy": "Roti Jala",
      "foodGroup": "Breads",
      "caloriesPer100g": 195.0,
      "proteinPer100g": 4.5,
      "carbsPer100g": 26.0,
      "fatsPer100g": 7.5,
      "sodiumPer100g": 210.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Wheat Flour",
        "Coconut Milk",
        "Egg",
        "Turmeric Powder",
        "Water"
      ],
      "portionSizes": {"smallGrams": 50, "mediumGrams": 100, "largeGrams": 150},
      "source": "Curated",
      "myfcdCode": "ESS038"
    },
    {
      "nameEn": "Curry Puff",
      "nameMy": "Karipap / Epok-Epok",
      "foodGroup": "Snacks",
      "caloriesPer100g": 330.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 36.0,
      "fatsPer100g": 18.0,
      "sodiumPer100g": 350.0,
      "sugarPer100g": 2.5,
      "ingredients": [
        "Wheat Flour",
        "Margarine",
        "Potatoes",
        "Curry Powder",
        "Chicken",
        "Egg"
      ],
      "portionSizes": {"smallGrams": 40, "mediumGrams": 80, "largeGrams": 120},
      "source": "Curated",
      "myfcdCode": "ESS039"
    },
    {
      "nameEn": "Sambal Udang",
      "nameMy": "Sambal Udang",
      "foodGroup": "Seafood Dishes",
      "caloriesPer100g": 165.0,
      "proteinPer100g": 12.0,
      "carbsPer100g": 8.0,
      "fatsPer100g": 9.5,
      "sodiumPer100g": 480.0,
      "sugarPer100g": 4.0,
      "ingredients": [
        "Prawns",
        "Chili Paste",
        "Onion",
        "Shrimp Paste (Belacan)",
        "Tamarind Juice",
        "Sugar"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 150,
        "largeGrams": 200
      },
      "source": "Curated",
      "myfcdCode": "ESS040"
    },
    {
      "nameEn": "Dim Sum (Siew Mai)",
      "nameMy": "Siew Mai",
      "foodGroup": "Snacks",
      "caloriesPer100g": 220.0,
      "proteinPer100g": 10.5,
      "carbsPer100g": 18.0,
      "fatsPer100g": 11.5,
      "sodiumPer100g": 420.0,
      "sugarPer100g": 1.0,
      "ingredients": [
        "Minced Pork",
        "Shrimp",
        "Wonton Wrapper",
        "Mushrooms",
        "Sesame Oil"
      ],
      "portionSizes": {"smallGrams": 50, "mediumGrams": 100, "largeGrams": 150},
      "source": "Curated",
      "myfcdCode": "ESS041"
    },
    {
      "nameEn": "Dim Sum (Har Gow)",
      "nameMy": "Hakau",
      "foodGroup": "Snacks",
      "caloriesPer100g": 160.0,
      "proteinPer100g": 8.5,
      "carbsPer100g": 16.5,
      "fatsPer100g": 6.5,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Shrimp",
        "Wheat Starch",
        "Tapioca Starch",
        "Bamboo Shoots",
        "Sesame Oil"
      ],
      "portionSizes": {"smallGrams": 50, "mediumGrams": 100, "largeGrams": 150},
      "source": "Curated",
      "myfcdCode": "ESS042"
    },
    {
      "nameEn": "Rojak (Fruit)",
      "nameMy": "Rojak Buah",
      "foodGroup": "Snacks",
      "caloriesPer100g": 120.0,
      "proteinPer100g": 2.5,
      "carbsPer100g": 22.0,
      "fatsPer100g": 3.0,
      "sodiumPer100g": 250.0,
      "sugarPer100g": 14.0,
      "ingredients": [
        "Pineapple",
        "Cucumber",
        "Jicama",
        "Dough Fritters",
        "Shrimp Paste Sauce",
        "Peanuts",
        "Sugar"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "ESS043"
    },
    {
      "nameEn": "Ice Kacang (ABC)",
      "nameMy": "Ais Kacang / ABC",
      "foodGroup": "Desserts",
      "caloriesPer100g": 95.0,
      "proteinPer100g": 1.2,
      "carbsPer100g": 18.5,
      "fatsPer100g": 1.8,
      "sodiumPer100g": 45.0,
      "sugarPer100g": 15.0,
      "ingredients": [
        "Shaved Ice",
        "Red Beans",
        "Sweet Corn",
        "Grass Jelly",
        "Palm Sugar Syrup",
        "Condensed Milk",
        "Rose Syrup"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS044"
    },
    {
      "nameEn": "Nasi Briyani (Chicken)",
      "nameMy": "Nasi Briyani Ayam",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 165.0,
      "proteinPer100g": 7.5,
      "carbsPer100g": 20.0,
      "fatsPer100g": 6.0,
      "sodiumPer100g": 280.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Basmati Rice",
        "Chicken",
        "Ghee",
        "Yogurt",
        "Briyani Spices",
        "Onions",
        "Mint Leaves"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 650
      },
      "source": "Curated",
      "myfcdCode": "ESS045"
    },
    {
      "nameEn": "Murtabak",
      "nameMy": "Murtabak",
      "foodGroup": "Breads",
      "caloriesPer100g": 255.0,
      "proteinPer100g": 11.5,
      "carbsPer100g": 21.0,
      "fatsPer100g": 13.5,
      "sodiumPer100g": 410.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Wheat Flour",
        "Minced Meat (Chicken/Mutton/Beef)",
        "Egg",
        "Onions",
        "Ghee/Oil",
        "Curry Spices"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS046"
    },
    {
      "nameEn": "Tandoori Chicken",
      "nameMy": "Ayam Tandoori",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 155.0,
      "proteinPer100g": 22.0,
      "carbsPer100g": 3.5,
      "fatsPer100g": 5.5,
      "sodiumPer100g": 390.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Chicken",
        "Yogurt",
        "Tandoori Spices",
        "Lemon Juice",
        "Garlic",
        "Ginger"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "ESS047"
    },
    {
      "nameEn": "Fish Head Curry",
      "nameMy": "Kari Kepala Ikan",
      "foodGroup": "Seafood Dishes",
      "caloriesPer100g": 140.0,
      "proteinPer100g": 8.0,
      "carbsPer100g": 4.5,
      "fatsPer100g": 10.0,
      "sodiumPer100g": 340.0,
      "sugarPer100g": 1.0,
      "ingredients": [
        "Fish Head",
        "Curry Spices",
        "Coconut Milk",
        "Tamarind Juice",
        "Okra",
        "Eggplant",
        "Tomatoes"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 500,
        "largeGrams": 800
      },
      "source": "Curated",
      "myfcdCode": "ESS048"
    },
    {
      "nameEn": "Maggi Goreng",
      "nameMy": "Maggi Goreng",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 220.0,
      "proteinPer100g": 6.5,
      "carbsPer100g": 28.0,
      "fatsPer100g": 9.0,
      "sodiumPer100g": 550.0,
      "sugarPer100g": 2.5,
      "ingredients": [
        "Instant Noodles",
        "Egg",
        "Tofu",
        "Cabbage",
        "Soy Sauce",
        "Curry Seasoning",
        "Oil"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 300,
        "largeGrams": 450
      },
      "source": "Curated",
      "myfcdCode": "ESS049"
    },
    {
      "nameEn": "Kway Chap",
      "nameMy": "Kway Chap",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 105.0,
      "proteinPer100g": 4.0,
      "carbsPer100g": 11.5,
      "fatsPer100g": 4.5,
      "sodiumPer100g": 320.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Flat Rice Noodles",
        "Pork Broth",
        "Soy Sauce",
        "Pork Offal",
        "Tofu Puffs",
        "Hard-boiled Egg"
      ],
      "portionSizes": {
        "smallGrams": 350,
        "mediumGrams": 500,
        "largeGrams": 700
      },
      "source": "Curated",
      "myfcdCode": "ESS050"
    },
    {
      "nameEn": "Lontong",
      "nameMy": "Lontong / Sayur Lodeh",
      "foodGroup": "Soups",
      "caloriesPer100g": 130.0,
      "proteinPer100g": 3.5,
      "carbsPer100g": 12.0,
      "fatsPer100g": 7.5,
      "sodiumPer100g": 240.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Compressed Rice Cake (Nasi Impit)",
        "Coconut Milk",
        "Cabbage",
        "Long Beans",
        "Tempeh",
        "Tofu"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS051"
    },
    {
      "nameEn": "Mee Rebus",
      "nameMy": "Mee Rebus",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 145.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 22.0,
      "fatsPer100g": 4.0,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 4.5,
      "ingredients": [
        "Yellow Noodles",
        "Sweet Potato Gravy",
        "Hard-boiled Egg",
        "Bean Sprouts",
        "Fried Shallots",
        "Tofu",
        "Lime"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS052"
    },
    {
      "nameEn": "Mee Soto",
      "nameMy": "Mee Soto",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 95.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 12.0,
      "fatsPer100g": 3.0,
      "sodiumPer100g": 350.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Yellow Noodles",
        "Chicken Broth",
        "Shredded Chicken",
        "Bean Sprouts",
        "Fried Shallots",
        "Celery Leaves"
      ],
      "portionSizes": {
        "smallGrams": 350,
        "mediumGrams": 500,
        "largeGrams": 700
      },
      "source": "Curated",
      "myfcdCode": "ESS053"
    },
    {
      "nameEn": "Soto Ayam",
      "nameMy": "Soto Ayam",
      "foodGroup": "Soups",
      "caloriesPer100g": 75.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 5.0,
      "fatsPer100g": 3.5,
      "sodiumPer100g": 320.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Chicken Broth",
        "Shredded Chicken",
        "Compressed Rice Cake",
        "Bean Sprouts",
        "Fried Shallots"
      ],
      "portionSizes": {
        "smallGrams": 350,
        "mediumGrams": 500,
        "largeGrams": 700
      },
      "source": "Curated",
      "myfcdCode": "ESS054"
    },
    {
      "nameEn": "Beef Rendang",
      "nameMy": "Rendang Daging",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 255.0,
      "proteinPer100g": 16.0,
      "carbsPer100g": 8.5,
      "fatsPer100g": 17.0,
      "sodiumPer100g": 410.0,
      "sugarPer100g": 2.5,
      "ingredients": [
        "Beef",
        "Coconut Milk",
        "Kerisik (Toasted Coconut)",
        "Lemongrass",
        "Galangal",
        "Chili Paste",
        "Spices"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 200,
        "largeGrams": 350
      },
      "source": "Curated",
      "myfcdCode": "ESS055"
    },
    {
      "nameEn": "Putu Piring",
      "nameMy": "Putu Piring",
      "foodGroup": "Snacks",
      "caloriesPer100g": 265.0,
      "proteinPer100g": 2.5,
      "carbsPer100g": 52.0,
      "fatsPer100g": 5.0,
      "sodiumPer100g": 180.0,
      "sugarPer100g": 22.0,
      "ingredients": [
        "Rice Flour",
        "Palm Sugar (Gula Melaka)",
        "Grated Coconut",
        "Pandan Leaves",
        "Salt"
      ],
      "portionSizes": {"smallGrams": 40, "mediumGrams": 80, "largeGrams": 160},
      "source": "Curated",
      "myfcdCode": "ESS056"
    },
    {
      "nameEn": "Onde-Onde",
      "nameMy": "Onde-Onde / Buah Melaka",
      "foodGroup": "Snacks",
      "caloriesPer100g": 285.0,
      "proteinPer100g": 2.5,
      "carbsPer100g": 55.0,
      "fatsPer100g": 6.0,
      "sodiumPer100g": 110.0,
      "sugarPer100g": 28.0,
      "ingredients": [
        "Glutinous Rice Flour",
        "Pandan Juice",
        "Palm Sugar",
        "Grated Coconut"
      ],
      "portionSizes": {"smallGrams": 50, "mediumGrams": 100, "largeGrams": 200},
      "source": "Curated",
      "myfcdCode": "ESS057"
    },
    {
      "nameEn": "Popiah (Fresh)",
      "nameMy": "Popiah Basah",
      "foodGroup": "Snacks",
      "caloriesPer100g": 140.0,
      "proteinPer100g": 4.5,
      "carbsPer100g": 18.0,
      "fatsPer100g": 5.5,
      "sodiumPer100g": 310.0,
      "sugarPer100g": 5.0,
      "ingredients": [
        "Popiah Skin",
        "Jicama (Turnip)",
        "Carrots",
        "Lettuce",
        "Sweet Sauce",
        "Crushed Peanuts",
        "Egg"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 200,
        "largeGrams": 300
      },
      "source": "Curated",
      "myfcdCode": "ESS058"
    },
    {
      "nameEn": "Chai Tow Kway (Black)",
      "nameMy": "Lobak Goreng (Hitam)",
      "foodGroup": "Snacks",
      "caloriesPer100g": 185.0,
      "proteinPer100g": 4.5,
      "carbsPer100g": 24.0,
      "fatsPer100g": 8.0,
      "sodiumPer100g": 450.0,
      "sugarPer100g": 5.5,
      "ingredients": [
        "Radish Cake",
        "Dark Sweet Soy Sauce",
        "Egg",
        "Preserved Radish (Chai Poh)",
        "Garlic",
        "Oil"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS059"
    },
    {
      "nameEn": "Chai Tow Kway (White)",
      "nameMy": "Lobak Goreng (Putih)",
      "foodGroup": "Snacks",
      "caloriesPer100g": 175.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 18.0,
      "fatsPer100g": 9.5,
      "sodiumPer100g": 480.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Radish Cake",
        "Egg",
        "Preserved Radish (Chai Poh)",
        "Garlic",
        "Oil",
        "Fish Sauce"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS060"
    },
    {
      "nameEn": "Nasi Kandar (Mixed Rice)",
      "nameMy": "Nasi Kandar",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 180.0,
      "proteinPer100g": 6.5,
      "carbsPer100g": 20.0,
      "fatsPer100g": 8.0,
      "sodiumPer100g": 350.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "White Rice",
        "Mixed Curries (Kuah Campur)",
        "Fried Chicken",
        "Cabbage",
        "Okra"
      ],
      "portionSizes": {
        "smallGrams": 350,
        "mediumGrams": 550,
        "largeGrams": 750
      },
      "source": "Curated",
      "myfcdCode": "ESS061"
    },
    {
      "nameEn": "Thosai (Dosa)",
      "nameMy": "Tosei",
      "foodGroup": "Breads",
      "caloriesPer100g": 165.0,
      "proteinPer100g": 4.5,
      "carbsPer100g": 28.0,
      "fatsPer100g": 3.5,
      "sodiumPer100g": 220.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Rice Batter",
        "Lentil Batter",
        "Oil",
        "Coconut Chutney",
        "Sambar"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 200,
        "largeGrams": 300
      },
      "source": "Curated",
      "myfcdCode": "ESS062"
    },
    {
      "nameEn": "Fried Chicken (Local Style)",
      "nameMy": "Ayam Goreng",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 260.0,
      "proteinPer100g": 18.0,
      "carbsPer100g": 8.0,
      "fatsPer100g": 17.0,
      "sodiumPer100g": 350.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Chicken",
        "Turmeric Powder",
        "Coriander Powder",
        "Fennel Powder",
        "Salt",
        "Palm Oil",
        "Rice Flour"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 200,
        "largeGrams": 350
      },
      "source": "Curated",
      "myfcdCode": "ESS021"
    },
    {
      "nameEn": "Nasi Lemak",
      "nameMy": "Nasi Lemak",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 162.5,
      "proteinPer100g": 4.2,
      "carbsPer100g": 22.1,
      "fatsPer100g": 6.8,
      "sodiumPer100g": 210.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "White Rice",
        "Coconut Milk",
        "Pandan Leaves",
        "Dried Anchovies",
        "Peanuts",
        "Egg",
        "Sambal",
        "Cucumber"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS001"
    },
    {
      "nameEn": "Char Kuey Teow",
      "nameMy": "Char Kuey Teow",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 185.0,
      "proteinPer100g": 5.5,
      "carbsPer100g": 23.0,
      "fatsPer100g": 8.2,
      "sodiumPer100g": 350.0,
      "sugarPer100g": 2.0,
      "ingredients": [
        "Flat Rice Noodles",
        "Dark Soy Sauce",
        "Prawns",
        "Cockles",
        "Egg",
        "Bean Sprouts",
        "Chives",
        "Pork Lard or Palm Oil"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 550
      },
      "source": "Curated",
      "myfcdCode": "ESS002"
    },
    {
      "nameEn": "Bak Kut Teh",
      "nameMy": "Bak Kut Teh",
      "foodGroup": "Soups",
      "caloriesPer100g": 85.0,
      "proteinPer100g": 12.0,
      "carbsPer100g": 1.0,
      "fatsPer100g": 4.0,
      "sodiumPer100g": 300.0,
      "sugarPer100g": 0.5,
      "ingredients": [
        "Pork Ribs",
        "Dong Quai",
        "Star Anise",
        "Cinnamon",
        "Garlic",
        "Soy Sauce",
        "Tofu Puffs",
        "Enoki Mushrooms"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 500,
        "largeGrams": 750
      },
      "source": "Curated",
      "myfcdCode": "ESS003"
    },
    {
      "nameEn": "Nasi Kandar",
      "nameMy": "Nasi Kandar",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 170.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 24.0,
      "fatsPer100g": 6.5,
      "sodiumPer100g": 320.0,
      "sugarPer100g": 1.8,
      "ingredients": [
        "White Rice",
        "Mixed Curry Gravies (Kuah Campur)",
        "Fried Chicken or Beef",
        "Okra",
        "Hard-boiled Egg"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS004"
    },
    {
      "nameEn": "Wantan Mee (Dry)",
      "nameMy": "Wantan Mee",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 155.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 22.0,
      "fatsPer100g": 4.8,
      "sodiumPer100g": 410.0,
      "sugarPer100g": 3.0,
      "ingredients": [
        "Egg Noodles",
        "Dark Soy Sauce",
        "Char Siew (BBQ Pork or Chicken)",
        "Wontons",
        "Choy Sum",
        "Pork Lard or Shallot Oil"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS005"
    },
    {
      "nameEn": "Murtabak",
      "nameMy": "Murtabak",
      "foodGroup": "Breads",
      "caloriesPer100g": 210.0,
      "proteinPer100g": 9.0,
      "carbsPer100g": 18.0,
      "fatsPer100g": 11.5,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 2.2,
      "ingredients": [
        "Wheat Flour",
        "Minced Chicken/Beef",
        "Egg",
        "Onions",
        "Curry Powder",
        "Ghee/Oil"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "ESS006"
    },
    {
      "nameEn": "Pan Mee (Dry)",
      "nameMy": "Pan Mee",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 175.0,
      "proteinPer100g": 6.5,
      "carbsPer100g": 25.0,
      "fatsPer100g": 5.5,
      "sodiumPer100g": 390.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Flat Flour Noodles",
        "Minced Pork or Chicken",
        "Fried Anchovies",
        "Sayur Manis",
        "Wood Ear Mushrooms",
        "Dark Soy Sauce",
        "Dried Chili Flakes"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 550
      },
      "source": "Curated",
      "myfcdCode": "ESS007"
    },
    {
      "nameEn": "Assam Laksa",
      "nameMy": "Assam Laksa",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 95.0,
      "proteinPer100g": 4.0,
      "carbsPer100g": 16.0,
      "fatsPer100g": 1.8,
      "sodiumPer100g": 310.0,
      "sugarPer100g": 4.5,
      "ingredients": [
        "Thick Rice Noodles",
        "Mackerel Fish",
        "Tamarind Juice",
        "Torch Ginger Flower (Bunga Kantan)",
        "Pineapple",
        "Cucumber",
        "Mint Leaves",
        "Shrimp Paste (Petis Udang)"
      ],
      "portionSizes": {
        "smallGrams": 350,
        "mediumGrams": 500,
        "largeGrams": 700
      },
      "source": "Curated",
      "myfcdCode": "ESS008"
    },
    {
      "nameEn": "Hokkien Mee (KL)",
      "nameMy": "Hokkien Mee",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 190.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 21.0,
      "fatsPer100g": 9.5,
      "sodiumPer100g": 420.0,
      "sugarPer100g": 3.5,
      "ingredients": [
        "Thick Yellow Noodles",
        "Dark Caramel Soy Sauce",
        "Pork Lard",
        "Prawns",
        "Cabbage",
        "Pork Slices",
        "Squid"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS009"
    },
    {
      "nameEn": "Curry Mee",
      "nameMy": "Mee Kari",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 135.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 14.0,
      "fatsPer100g": 7.0,
      "sodiumPer100g": 310.0,
      "sugarPer100g": 3.0,
      "ingredients": [
        "Yellow Noodles",
        "Coconut Milk Curry Broth",
        "Tofu Puffs",
        "Chicken Slices",
        "Cockles",
        "Bean Sprouts",
        "Mint",
        "Chili Paste"
      ],
      "portionSizes": {
        "smallGrams": 350,
        "mediumGrams": 500,
        "largeGrams": 700
      },
      "source": "Curated",
      "myfcdCode": "ESS010"
    },
    {
      "nameEn": "Rojak Mamak",
      "nameMy": "Rojak Mamak",
      "foodGroup": "Snacks",
      "caloriesPer100g": 180.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 22.0,
      "fatsPer100g": 7.5,
      "sodiumPer100g": 250.0,
      "sugarPer100g": 8.0,
      "ingredients": [
        "Fried Dough Fritters",
        "Hard-boiled Egg",
        "Cucumber",
        "Jicama",
        "Tofu",
        "Sweet Peanut Sauce",
        "Cuttlefish"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS011"
    },
    {
      "nameEn": "Apam Balik",
      "nameMy": "Apam Balik",
      "foodGroup": "Snacks",
      "caloriesPer100g": 280.0,
      "proteinPer100g": 5.5,
      "carbsPer100g": 45.0,
      "fatsPer100g": 8.5,
      "sodiumPer100g": 150.0,
      "sugarPer100g": 18.0,
      "ingredients": [
        "Wheat Flour",
        "Sugar",
        "Eggs",
        "Baking Powder",
        "Roasted Peanuts",
        "Sweetened Corn",
        "Margarine"
      ],
      "portionSizes": {"smallGrams": 80, "mediumGrams": 150, "largeGrams": 250},
      "source": "Curated",
      "myfcdCode": "ESS012"
    },
    {
      "nameEn": "Yong Tau Foo",
      "nameMy": "Yong Tau Foo",
      "foodGroup": "Soups",
      "caloriesPer100g": 70.0,
      "proteinPer100g": 5.0,
      "carbsPer100g": 3.0,
      "fatsPer100g": 4.0,
      "sodiumPer100g": 210.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Tofu",
        "Eggplant",
        "Bitter Gourd",
        "Okra",
        "Fish Paste",
        "Clear Broth",
        "Sweet Sauce",
        "Chili Sauce"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 300,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "ESS015"
    },
    {
      "nameEn": "Chee Cheong Fun",
      "nameMy": "Chee Cheong Fun",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 120.0,
      "proteinPer100g": 2.0,
      "carbsPer100g": 26.0,
      "fatsPer100g": 1.5,
      "sodiumPer100g": 190.0,
      "sugarPer100g": 4.5,
      "ingredients": [
        "Rice Noodle Rolls",
        "Sweet Sauce",
        "Chili Sauce",
        "Sesame Seeds",
        "Fried Shallots",
        "Curry Broth (optional)"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "ESS016"
    },
    {
      "nameEn": "Cendol",
      "nameMy": "Cendol",
      "foodGroup": "Desserts",
      "caloriesPer100g": 110.0,
      "proteinPer100g": 1.0,
      "carbsPer100g": 18.0,
      "fatsPer100g": 4.0,
      "sodiumPer100g": 45.0,
      "sugarPer100g": 12.0,
      "ingredients": [
        "Shaved Ice",
        "Coconut Milk",
        "Gula Melaka (Palm Sugar)",
        "Pandan Jelly Noodles",
        "Red Beans"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 300,
        "largeGrams": 450
      },
      "source": "Curated",
      "myfcdCode": "ESS017"
    },
    {
      "nameEn": "ABC (Ais Kacang)",
      "nameMy": "Ais Kacang",
      "foodGroup": "Desserts",
      "caloriesPer100g": 95.0,
      "proteinPer100g": 1.5,
      "carbsPer100g": 20.0,
      "fatsPer100g": 1.2,
      "sodiumPer100g": 50.0,
      "sugarPer100g": 14.0,
      "ingredients": [
        "Shaved Ice",
        "Red Beans",
        "Sweet Corn",
        "Grass Jelly",
        "Evaporated Milk",
        "Rose Syrup",
        "Palm Sugar Syrup",
        "Roasted Peanuts"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "ESS018"
    },
    {
      "nameEn": "Popiah",
      "nameMy": "Popiah",
      "foodGroup": "Snacks",
      "caloriesPer100g": 185.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 22.0,
      "fatsPer100g": 8.0,
      "sodiumPer100g": 260.0,
      "sugarPer100g": 4.0,
      "ingredients": [
        "Popiah Wrapper",
        "Jicama (Sengkuang)",
        "Carrot",
        "French Beans",
        "Fried Shallots",
        "Crushed Peanuts",
        "Sweet Sauce",
        "Chili Sauce",
        "Egg"
      ],
      "portionSizes": {"smallGrams": 80, "mediumGrams": 160, "largeGrams": 240},
      "source": "Curated",
      "myfcdCode": "ESS019"
    },
    {
      "nameEn": "Roti Canai",
      "nameMy": "Roti Canai",
      "foodGroup": "Breads",
      "caloriesPer100g": 301.0,
      "proteinPer100g": 6.5,
      "carbsPer100g": 45.0,
      "fatsPer100g": 10.2,
      "sodiumPer100g": 320.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Wheat Flour",
        "Water",
        "Ghee/Margarine",
        "Salt",
        "Condensed Milk (trace)"
      ],
      "portionSizes": {"smallGrams": 80, "mediumGrams": 160, "largeGrams": 240},
      "source": "Curated",
      "myfcdCode": "ESS014"
    },
    {
      "nameEn": "Teh Tarik",
      "nameMy": "Teh Tarik",
      "foodGroup": "Beverages",
      "caloriesPer100g": 45.0,
      "proteinPer100g": 0.8,
      "carbsPer100g": 8.5,
      "fatsPer100g": 0.9,
      "sodiumPer100g": 25.0,
      "sugarPer100g": 8.0,
      "ingredients": [
        "Black Tea Dust",
        "Sweetened Condensed Milk",
        "Evaporated Milk",
        "Hot Water"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "ESS013"
    },
    {
      "nameEn": "Milo Dinosaur",
      "nameMy": "Milo Dinosaur",
      "foodGroup": "Beverages",
      "caloriesPer100g": 120.0,
      "proteinPer100g": 3.5,
      "carbsPer100g": 18.0,
      "fatsPer100g": 4.5,
      "sodiumPer100g": 60.0,
      "sugarPer100g": 14.0,
      "ingredients": [
        "Iced Milo Drink",
        "Extra Undissolved Milo Powder on top",
        "Sweetened Condensed Milk",
        "Ice"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "GAP001"
    },
    {
      "nameEn": "Sirap Bandung",
      "nameMy": "Sirap Bandung",
      "foodGroup": "Beverages",
      "caloriesPer100g": 75.0,
      "proteinPer100g": 1.2,
      "carbsPer100g": 14.0,
      "fatsPer100g": 2.0,
      "sodiumPer100g": 30.0,
      "sugarPer100g": 12.0,
      "ingredients": [
        "Rose Syrup",
        "Evaporated Milk",
        "Condensed Milk",
        "Ice",
        "Water"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "GAP002"
    },
    {
      "nameEn": "Limau Ais",
      "nameMy": "Limau Ais",
      "foodGroup": "Beverages",
      "caloriesPer100g": 30.0,
      "proteinPer100g": 0.1,
      "carbsPer100g": 8.0,
      "fatsPer100g": 0.0,
      "sodiumPer100g": 5.0,
      "sugarPer100g": 7.5,
      "ingredients": [
        "Calamansi Lime (Limau Kasturi)",
        "Sugar Syrup",
        "Ice",
        "Water"
      ],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 350,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "GAP003"
    },
    {
      "nameEn": "Curry Puff",
      "nameMy": "Karipap",
      "foodGroup": "Snacks",
      "caloriesPer100g": 320.0,
      "proteinPer100g": 6.0,
      "carbsPer100g": 35.0,
      "fatsPer100g": 18.0,
      "sodiumPer100g": 250.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Wheat Flour Pastry",
        "Margarine/Oil",
        "Potatoes",
        "Curry Powder",
        "Onions",
        "Chicken (optional)",
        "Egg (optional)"
      ],
      "portionSizes": {"smallGrams": 40, "mediumGrams": 120, "largeGrams": 240},
      "source": "Curated",
      "myfcdCode": "GAP004"
    },
    {
      "nameEn": "Satay (Chicken/Beef)",
      "nameMy": "Sate",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 200.0,
      "proteinPer100g": 15.0,
      "carbsPer100g": 5.0,
      "fatsPer100g": 12.0,
      "sodiumPer100g": 310.0,
      "sugarPer100g": 4.5,
      "ingredients": [
        "Chicken or Beef chunks",
        "Turmeric",
        "Lemongrass",
        "Sugar",
        "Salt",
        "Coriander",
        "Peanut Sauce",
        "Cucumber",
        "Onion"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 200,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "GAP005"
    },
    {
      "nameEn": "Otak-otak",
      "nameMy": "Otak-otak",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 160.0,
      "proteinPer100g": 12.0,
      "carbsPer100g": 8.0,
      "fatsPer100g": 9.0,
      "sodiumPer100g": 290.0,
      "sugarPer100g": 2.5,
      "ingredients": [
        "Fish Paste (Mackerel)",
        "Coconut Milk",
        "Chili Paste",
        "Lemongrass",
        "Galangal",
        "Banana Leaves or Attap Leaves",
        "Tapioca Starch"
      ],
      "portionSizes": {"smallGrams": 50, "mediumGrams": 125, "largeGrams": 250},
      "source": "Curated",
      "myfcdCode": "GAP006"
    },
    {
      "nameEn": "Kuih Seri Muka",
      "nameMy": "Seri Muka",
      "foodGroup": "Desserts",
      "caloriesPer100g": 190.0,
      "proteinPer100g": 2.5,
      "carbsPer100g": 35.0,
      "fatsPer100g": 4.5,
      "sodiumPer100g": 80.0,
      "sugarPer100g": 15.0,
      "ingredients": [
        "Glutinous Rice",
        "Coconut Milk",
        "Pandan Extract",
        "Sugar",
        "Eggs",
        "Wheat Flour",
        "Tapioca Flour",
        "Salt"
      ],
      "portionSizes": {"smallGrams": 60, "mediumGrams": 120, "largeGrams": 240},
      "source": "Curated",
      "myfcdCode": "GAP007"
    },
    {
      "nameEn": "Ondeh-ondeh",
      "nameMy": "Ondeh-ondeh",
      "foodGroup": "Desserts",
      "caloriesPer100g": 220.0,
      "proteinPer100g": 2.0,
      "carbsPer100g": 45.0,
      "fatsPer100g": 3.5,
      "sodiumPer100g": 45.0,
      "sugarPer100g": 20.0,
      "ingredients": [
        "Glutinous Rice Flour",
        "Pandan Juice Extract",
        "Gula Melaka (Palm Sugar)",
        "Grated Fresh Coconut",
        "Salt"
      ],
      "portionSizes": {"smallGrams": 60, "mediumGrams": 120, "largeGrams": 240},
      "source": "Curated",
      "myfcdCode": "GAP008"
    },
    {
      "nameEn": "Nasi Goreng Kampung",
      "nameMy": "Nasi Goreng Kampung",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 175.0,
      "proteinPer100g": 6.5,
      "carbsPer100g": 24.0,
      "fatsPer100g": 6.0,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 1.2,
      "ingredients": [
        "White Rice",
        "Fried Anchovies (Ikan Bilis)",
        "Water Spinach (Kangkung)",
        "Bird's Eye Chili (Cili Padi)",
        "Belacan (Shrimp Paste)",
        "Egg",
        "Shallots",
        "Garlic"
      ],
      "portionSizes": {
        "smallGrams": 300,
        "mediumGrams": 450,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "GAP009"
    },
    {
      "nameEn": "Durian",
      "nameMy": "Durian",
      "foodGroup": "Fruits",
      "caloriesPer100g": 147.0,
      "proteinPer100g": 1.5,
      "carbsPer100g": 27.0,
      "fatsPer100g": 5.3,
      "sodiumPer100g": 2.0,
      "sugarPer100g": 18.0,
      "ingredients": ["Durian Flesh"],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 300,
        "largeGrams": 600
      },
      "source": "Curated",
      "myfcdCode": "GAP010"
    },
    {
      "nameEn": "Kopi-O",
      "nameMy": "Kopi-O",
      "foodGroup": "Beverages",
      "caloriesPer100g": 25.0,
      "proteinPer100g": 0.2,
      "carbsPer100g": 6.0,
      "fatsPer100g": 0.0,
      "sodiumPer100g": 10.0,
      "sugarPer100g": 5.5,
      "ingredients": [
        "Local Coffee Grounds (Roasted with sugar/margarine)",
        "Sugar",
        "Hot Water"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "GAP011"
    },
    {
      "nameEn": "Cham (Coffee + Tea)",
      "nameMy": "Cham",
      "foodGroup": "Beverages",
      "caloriesPer100g": 50.0,
      "proteinPer100g": 1.0,
      "carbsPer100g": 9.0,
      "fatsPer100g": 1.2,
      "sodiumPer100g": 35.0,
      "sugarPer100g": 8.5,
      "ingredients": [
        "Black Tea",
        "Local Coffee",
        "Sweetened Condensed Milk",
        "Evaporated Milk",
        "Hot Water"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "GAP012"
    },
    {
      "nameEn": "Tauhuay",
      "nameMy": "Tauhuay",
      "foodGroup": "Desserts",
      "caloriesPer100g": 60.0,
      "proteinPer100g": 3.0,
      "carbsPer100g": 8.0,
      "fatsPer100g": 2.0,
      "sodiumPer100g": 15.0,
      "sugarPer100g": 7.0,
      "ingredients": [
        "Soybean Milk",
        "Coagulant (Glucono delta-lactone)",
        "Sugar Syrup (Clear or Palm Sugar)",
        "Pandan Leaves"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "GAP013"
    },
    {
      "nameEn": "Kuih Talam",
      "nameMy": "Kuih Talam",
      "foodGroup": "Desserts",
      "caloriesPer100g": 200.0,
      "proteinPer100g": 2.0,
      "carbsPer100g": 38.0,
      "fatsPer100g": 5.0,
      "sodiumPer100g": 120.0,
      "sugarPer100g": 16.0,
      "ingredients": [
        "Rice Flour",
        "Green Pea Flour",
        "Coconut Milk",
        "Pandan Juice",
        "Sugar",
        "Salt"
      ],
      "portionSizes": {"smallGrams": 60, "mediumGrams": 120, "largeGrams": 240},
      "source": "Curated",
      "myfcdCode": "GAP014"
    },
    {
      "nameEn": "Rojak Buah",
      "nameMy": "Rojak Buah",
      "foodGroup": "Snacks",
      "caloriesPer100g": 120.0,
      "proteinPer100g": 2.0,
      "carbsPer100g": 28.0,
      "fatsPer100g": 1.0,
      "sodiumPer100g": 210.0,
      "sugarPer100g": 18.0,
      "ingredients": [
        "Pineapple",
        "Jicama",
        "Cucumber",
        "Green Mango",
        "Guava",
        "Shrimp Paste (Kuah Rojak)",
        "Crushed Peanuts",
        "Sesame Seeds"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 300,
        "largeGrams": 500
      },
      "source": "Curated",
      "myfcdCode": "GAP015"
    },
    {
      "nameEn": "Milo (Drink)",
      "nameMy": "Milo",
      "foodGroup": "Beverages",
      "caloriesPer100g": 405.0,
      "proteinPer100g": 11.0,
      "carbsPer100g": 68.0,
      "fatsPer100g": 9.0,
      "sodiumPer100g": 150.0,
      "sugarPer100g": 45.0,
      "ingredients": [
        "Malt Extract (Barley)",
        "Skimmed Milk Powder",
        "Sugar",
        "Cocoa",
        "Palm Oil",
        "Vitamins",
        "Minerals"
      ],
      "portionSizes": {"smallGrams": 33, "mediumGrams": 66, "largeGrams": 200},
      "source": "Curated",
      "myfcdCode": "PKG001"
    },
    {
      "nameEn": "Maggi Curry Mee",
      "nameMy": "Maggi Kari",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 445.0,
      "proteinPer100g": 9.5,
      "carbsPer100g": 62.0,
      "fatsPer100g": 18.0,
      "sodiumPer100g": 1800.0,
      "sugarPer100g": 2.5,
      "ingredients": [
        "Wheat Flour",
        "Palm Oil",
        "Salt",
        "Curry Flavour Pack (Chili, Coriander, Cumin, MSG, Sugar, Onion, Garlic)"
      ],
      "portionSizes": {"smallGrams": 79, "mediumGrams": 158, "largeGrams": 237},
      "source": "Curated",
      "myfcdCode": "PKG002"
    },
    {
      "nameEn": "Maggi Chicken Mee",
      "nameMy": "Maggi Ayam",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 430.0,
      "proteinPer100g": 9.0,
      "carbsPer100g": 65.0,
      "fatsPer100g": 15.0,
      "sodiumPer100g": 1750.0,
      "sugarPer100g": 2.0,
      "ingredients": [
        "Wheat Flour",
        "Palm Oil",
        "Salt",
        "Chicken Flavour Pack (MSG, Sugar, Onion, Garlic, Celery Seed, Artificial Chicken Flavor)"
      ],
      "portionSizes": {"smallGrams": 77, "mediumGrams": 154, "largeGrams": 231},
      "source": "Curated",
      "myfcdCode": "PKG007"
    },
    {
      "nameEn": "Hup Seng Cream Crackers",
      "nameMy": "Biskut Hup Seng",
      "foodGroup": "Snacks",
      "caloriesPer100g": 490.0,
      "proteinPer100g": 7.5,
      "carbsPer100g": 68.0,
      "fatsPer100g": 21.0,
      "sodiumPer100g": 450.0,
      "sugarPer100g": 2.0,
      "ingredients": [
        "Wheat Flour",
        "Vegetable Oil (Palm Oil)",
        "Sugar",
        "Corn Starch",
        "Salt",
        "Milk Powder",
        "Yeast"
      ],
      "portionSizes": {"smallGrams": 22, "mediumGrams": 44, "largeGrams": 88},
      "source": "Curated",
      "myfcdCode": "PKG003"
    },
    {
      "nameEn": "Gardenia White Bread",
      "nameMy": "Roti Gardenia",
      "foodGroup": "Breads",
      "caloriesPer100g": 260.0,
      "proteinPer100g": 8.5,
      "carbsPer100g": 48.0,
      "fatsPer100g": 3.5,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 4.5,
      "ingredients": [
        "Wheat Flour",
        "Water",
        "Sugar",
        "Vegetable Shortening",
        "Yeast",
        "Salt",
        "Milk Powder",
        "Calcium Propionate"
      ],
      "portionSizes": {"smallGrams": 30, "mediumGrams": 60, "largeGrams": 120},
      "source": "Curated",
      "myfcdCode": "PKG004"
    },
    {
      "nameEn": "100 Plus",
      "nameMy": "100 Plus",
      "foodGroup": "Beverages",
      "caloriesPer100g": 27.0,
      "proteinPer100g": 0.0,
      "carbsPer100g": 6.8,
      "fatsPer100g": 0.0,
      "sodiumPer100g": 48.0,
      "sugarPer100g": 6.5,
      "ingredients": [
        "Carbonated Water",
        "Sucrose",
        "Glucose",
        "Citric Acid",
        "Sodium Chloride",
        "Potassium Phosphate",
        "Calcium Phosphate",
        "Flavorings"
      ],
      "portionSizes": {
        "smallGrams": 325,
        "mediumGrams": 500,
        "largeGrams": 1500
      },
      "source": "Curated",
      "myfcdCode": "PKG005"
    },
    {
      "nameEn": "Dutch Lady Full Cream Milk",
      "nameMy": "Susu Dutch Lady",
      "foodGroup": "Beverages",
      "caloriesPer100g": 65.0,
      "proteinPer100g": 3.2,
      "carbsPer100g": 4.8,
      "fatsPer100g": 3.7,
      "sodiumPer100g": 45.0,
      "sugarPer100g": 4.8,
      "ingredients": ["Cow's Milk"],
      "portionSizes": {
        "smallGrams": 200,
        "mediumGrams": 500,
        "largeGrams": 1000
      },
      "source": "Curated",
      "myfcdCode": "PKG006"
    },
    {
      "nameEn": "Vitagen",
      "nameMy": "Vitagen",
      "foodGroup": "Beverages",
      "caloriesPer100g": 66.0,
      "proteinPer100g": 0.8,
      "carbsPer100g": 15.5,
      "fatsPer100g": 0.0,
      "sodiumPer100g": 15.0,
      "sugarPer100g": 14.5,
      "ingredients": [
        "Water",
        "Sucrose",
        "Skimmed Milk Powder",
        "Glucose",
        "Flavoring",
        "Live Lactobacillus Cultures"
      ],
      "portionSizes": {
        "smallGrams": 125,
        "mediumGrams": 250,
        "largeGrams": 625
      },
      "source": "Curated",
      "myfcdCode": "PKG008"
    },
    {
      "nameEn": "Yakult",
      "nameMy": "Yakult",
      "foodGroup": "Beverages",
      "caloriesPer100g": 70.0,
      "proteinPer100g": 1.2,
      "carbsPer100g": 16.0,
      "fatsPer100g": 0.0,
      "sodiumPer100g": 16.0,
      "sugarPer100g": 15.0,
      "ingredients": [
        "Water",
        "Sugar",
        "Skimmed Milk Powder",
        "Glucose",
        "Natural Flavoring",
        "Live Lactobacillus casei Shirota strain"
      ],
      "portionSizes": {"smallGrams": 80, "mediumGrams": 160, "largeGrams": 400},
      "source": "Curated",
      "myfcdCode": "PKG009"
    },
    {
      "nameEn": "Mamee Monster",
      "nameMy": "Mamee",
      "foodGroup": "Snacks",
      "caloriesPer100g": 510.0,
      "proteinPer100g": 9.0,
      "carbsPer100g": 62.0,
      "fatsPer100g": 25.0,
      "sodiumPer100g": 950.0,
      "sugarPer100g": 3.0,
      "ingredients": [
        "Wheat Flour",
        "Palm Oil",
        "Salt",
        "Seasoning Powder (MSG, Sugar, Spices, Disodium Inosinate)"
      ],
      "portionSizes": {"smallGrams": 25, "mediumGrams": 50, "largeGrams": 200},
      "source": "Curated",
      "myfcdCode": "PKG010"
    },
    {
      "nameEn": "Julie's Peanut Butter Sandwich",
      "nameMy": "Biskut Julie's",
      "foodGroup": "Snacks",
      "caloriesPer100g": 520.0,
      "proteinPer100g": 10.0,
      "carbsPer100g": 58.0,
      "fatsPer100g": 28.0,
      "sodiumPer100g": 350.0,
      "sugarPer100g": 18.0,
      "ingredients": [
        "Wheat Flour",
        "Peanut Butter",
        "Sugar",
        "Vegetable Oil (Palm Oil)",
        "Corn Starch",
        "Salt",
        "Leavening Agent"
      ],
      "portionSizes": {"smallGrams": 30, "mediumGrams": 60, "largeGrams": 150},
      "source": "Curated",
      "myfcdCode": "PKG011"
    },
    {
      "nameEn": "OldTown White Coffee (3-in-1)",
      "nameMy": "OldTown Coffee",
      "foodGroup": "Beverages",
      "caloriesPer100g": 450.0,
      "proteinPer100g": 4.0,
      "carbsPer100g": 75.0,
      "fatsPer100g": 15.0,
      "sodiumPer100g": 110.0,
      "sugarPer100g": 50.0,
      "ingredients": [
        "Non-Dairy Creamer",
        "Sugar",
        "Instant Coffee",
        "Maltodextrin",
        "Skimmed Milk Powder"
      ],
      "portionSizes": {"smallGrams": 38, "mediumGrams": 76, "largeGrams": 200},
      "source": "Curated",
      "myfcdCode": "PKG012"
    },
    {
      "nameEn": "Beef Rendang",
      "nameMy": "Rendang Daging",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 240.0,
      "proteinPer100g": 16.0,
      "carbsPer100g": 8.5,
      "fatsPer100g": 15.5,
      "sodiumPer100g": 400.0,
      "sugarPer100g": 2.5,
      "ingredients": [
        "Beef",
        "Coconut Milk",
        "Kerisik (Toasted Coconut)",
        "Lemongrass",
        "Galangal",
        "Garlic",
        "Shallots",
        "Chili Paste",
        "Turmeric Leaves",
        "Salt",
        "Sugar"
      ],
      "portionSizes": {
        "smallGrams": 100,
        "mediumGrams": 200,
        "largeGrams": 300
      },
      "source": "Curated",
      "myfcdCode": "GAP016"
    },
    {
      "nameEn": "Grilled Fish (Ikan Bakar)",
      "nameMy": "Ikan Bakar",
      "foodGroup": "Meat Dishes",
      "caloriesPer100g": 130.0,
      "proteinPer100g": 18.0,
      "carbsPer100g": 3.0,
      "fatsPer100g": 4.5,
      "sodiumPer100g": 380.0,
      "sugarPer100g": 1.5,
      "ingredients": [
        "Stingray or Mackerel",
        "Sambal Paste",
        "Calamansi Juice",
        "Banana Leaves (for grilling)",
        "Onions",
        "Belacan"
      ],
      "portionSizes": {
        "smallGrams": 150,
        "mediumGrams": 250,
        "largeGrams": 400
      },
      "source": "Curated",
      "myfcdCode": "GAP017"
    },
    {
      "nameEn": "Nasi Kerabu",
      "nameMy": "Nasi Kerabu",
      "foodGroup": "Rice Dishes",
      "caloriesPer100g": 150.0,
      "proteinPer100g": 4.5,
      "carbsPer100g": 25.0,
      "fatsPer100g": 3.0,
      "sodiumPer100g": 220.0,
      "sugarPer100g": 1.0,
      "ingredients": [
        "Blue Rice (Butterfly Pea Flower)",
        "Grated Coconut (Kerisik)",
        "Fish Sauce (Budu)",
        "Long Beans",
        "Cabbage",
        "Torch Ginger",
        "Fried Fish or Chicken",
        "Salted Egg",
        "Fish Crackers"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 550
      },
      "source": "Curated",
      "myfcdCode": "GAP018"
    },
    {
      "nameEn": "Mee Goreng Mamak",
      "nameMy": "Mee Goreng Mamak",
      "foodGroup": "Noodle Dishes",
      "caloriesPer100g": 180.0,
      "proteinPer100g": 5.8,
      "carbsPer100g": 24.0,
      "fatsPer100g": 7.2,
      "sodiumPer100g": 450.0,
      "sugarPer100g": 3.5,
      "ingredients": [
        "Yellow Noodles",
        "Sweet Soy Sauce",
        "Chili Paste",
        "Tofu",
        "Potatoes",
        "Fritters (Cucur)",
        "Egg",
        "Tomato Sauce",
        "Peanut Sauce",
        "Mustard Greens"
      ],
      "portionSizes": {
        "smallGrams": 250,
        "mediumGrams": 400,
        "largeGrams": 550
      },
      "source": "Curated",
      "myfcdCode": "GAP019"
    },
    {
      "nameEn": "Banana Fritters",
      "nameMy": "Pisang Goreng",
      "foodGroup": "Snacks",
      "caloriesPer100g": 250.0,
      "proteinPer100g": 2.5,
      "carbsPer100g": 38.0,
      "fatsPer100g": 10.0,
      "sodiumPer100g": 120.0,
      "sugarPer100g": 15.0,
      "ingredients": [
        "Bananas",
        "Rice Flour",
        "Wheat Flour",
        "Turmeric Powder",
        "Sugar",
        "Salt",
        "Palm Oil for deep frying"
      ],
      "portionSizes": {"smallGrams": 50, "mediumGrams": 150, "largeGrams": 250},
      "source": "Curated",
      "myfcdCode": "GAP020"
    }
  ];

  // ── 3. Load, Sanitize and Deduplicate ──────────────────────────
  final myfcdRaw = await _loadFoodAsset('assets/data/myfcd_full.json');
  final sgfocosRaw = await _loadFoodAsset('assets/data/sgfocos_full.json');
  final backedRaw = await _loadFoodAsset('assets/data/backed_foods.json');
  final backedMyRaw = await _loadFoodAsset('assets/data/backed_my_foods.json');

  final allSourceFoods = [...myfcdRaw, ...sgfocosRaw, ...backedRaw, ...backedMyRaw];
  final mergedFoods = <String, Map<String, dynamic>>{};

  /// Sanitizes food data (handles outliers and name cleaning)
  Map<String, dynamic>? sanitize(Map<String, dynamic> f) {
    try {
      final rawNameEn = f['nameEn']?.toString() ?? '';
      if (rawNameEn.isEmpty) return null;
      final nameEn = _cleanName(rawNameEn);

      final rawNameMy = f['nameMy']?.toString() ?? nameEn;
      final nameMy = _cleanName(rawNameMy);

      double cal = (f['caloriesPer100g'] as num?)?.toDouble() ?? 0.0;
      double pro = (f['proteinPer100g'] as num?)?.toDouble() ?? 0.0;
      double carb = (f['carbsPer100g'] as num?)?.toDouble() ?? 0.0;
      double fat = (f['fatsPer100g'] as num?)?.toDouble() ?? 0.0;
      double sodium = (f['sodiumPer100g'] as num?)?.toDouble() ?? 0.0;
      double sugar = (f['sugarPer100g'] as num?)?.toDouble() ?? 0.0;

      // Filter extreme outliers
      if (cal > 900 || cal < 0) return null;
      if (pro + carb + fat > 102) return null;

      // Inject standard portion sizes if missing
      final portionSizes = f['portionSizes'] ??
          {
            'smallGrams': 100.0,
            'mediumGrams': 250.0,
            'largeGrams': 400.0,
          };

      return {
        ...f,
        'nameEn': nameEn,
        'nameEnLower': nameEn.toLowerCase(),
        'nameMy': nameMy,
        'nameMyLower': nameMy.toLowerCase(),
        'foodGroup': f['foodGroup'] ?? 'Other',
        'caloriesPer100g': cal,
        'proteinPer100g': pro,
        'carbsPer100g': carb,
        'fatsPer100g': fat,
        'sodiumPer100g': sodium,
        'sugarPer100g': sugar,
        'ingredients': f['ingredients'] ?? [],
        'portionSizes': portionSizes,
        'source': f['source'] ?? 'General Database',
        'myfcdCode': f['myfcdCode'] ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // Deduplication Priority: Curated > SG FOCOS > MyFCD
  for (final food in curatedEssentials) {
    final s = sanitize(food);
    if (s != null) {
      // Use nameEnLower as the UNIQUE key in mergedFoods
      mergedFoods[s['nameEnLower']] = s;
    }
  }

  for (final food in allSourceFoods) {
    final s = sanitize(food);
    if (s == null) continue;
    final lowerName = s['nameEnLower'] as String;

    if (mergedFoods.containsKey(lowerName)) {
      final existing = mergedFoods[lowerName]!;
      // Never overwrite Curated entries
      if (existing['source'] == 'Curated') continue;

      // SG FOCOS usually has better macro data than basic MyFCD
      if (s['source']?.toString().contains('SG') == true &&
          existing['source']?.toString().contains('MyFCD') == true) {
        mergedFoods[lowerName] = s;
      }
    } else {
      mergedFoods[lowerName] = s;
    }
  }

  final foodsToSeed = mergedFoods.values.toList();
  debugPrint('Final refined food count: ${foodsToSeed.length}');

  // ── 4. Batch Seed to Firestore ────────────────────────────────
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
        // CRITICAL: Use nameEnLower (slugified) as the document ID
        // This ensures that if we have "Nasi Lemak" in Curated and MyFCD,
        // they both map to the SAME document ID, effectively overwriting
        // the old data and PREVENTING DUPLICATES in Firestore.
        final id = (food['nameEnLower'] as String)
            .replaceAll(' ', '_')
            .replaceAll('/', '_')
            .replaceAll('(', '')
            .replaceAll(')', '');

        batch.set(
            foodsRef.doc(id),
            food,
            SetOptions(
                merge:
                    false)); // Use merge: false to fully replace with standardized data
      }

      await batch.commit();
      seededCount += chunk.length;
    }

    debugPrint('Successfully seeded $seededCount refined foods (v12).');
    await prefs.setString(_seedVersionKey, _seedVersion);
  } catch (e) {
    debugPrint('FAILED to seed refined database: $e');
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

/// Cleans long, convoluted names from raw data sources.
String _cleanName(String name) {
  var cleaned = name;

  // Remove Brand Prefixes often found in MyFCD/SG data
  final brands = [
    'Nestle, ',
    'Cadbury, ',
    'Kellogg\'s, ',
    'Julie\'s, ',
    'Milo, ',
    'Maggi, ',
    'Dutch Lady, ',
    'Munchy\'s, ',
    'Mamee, '
  ];
  for (final brand in brands) {
    if (cleaned.startsWith(brand)) cleaned = cleaned.replaceFirst(brand, '');
  }

  // Remove common long descriptive tags
  cleaned = cleaned
      .replaceAll(
          RegExp(
              r', (?:whole grain|ready to eat|cooked|raw|fresh|dried|standard|fortified|sweetened|unsweetened|instant)',
              caseSensitive: false),
          '')
      .trim();

  // Remove scientific names usually separated by a semicolon
  // e.g., "Watermelon (Tembikai) ; Citrullus Vulgaris" -> "Watermelon (Tembikai)"
  if (cleaned.contains(';')) {
    cleaned = cleaned.split(';').first.trim();
  }

  // Standardize capitalization to Title Case
  return _toTitleCase(cleaned);
}

/// Helper to convert string to Title Case
String _toTitleCase(String text) {
  if (text.isEmpty) return 'Unknown Food';

  // Handle ALL CAPS names (common in MyFCD)
  final isAllCap = text == text.toUpperCase() && text.length > 3;
  final workingText = isAllCap ? text.toLowerCase() : text;

  return workingText.split(' ').map((word) {
    if (word.isEmpty) return word;
    // Find first alphabetical character
    final firstLetterIdx = word.indexOf(RegExp(r'[a-zA-Z]'));
    if (firstLetterIdx == -1) return word.toLowerCase();

    return word.substring(0, firstLetterIdx) +
        word[firstLetterIdx].toUpperCase() +
        word.substring(firstLetterIdx + 1).toLowerCase();
  }).join(' ');
}
