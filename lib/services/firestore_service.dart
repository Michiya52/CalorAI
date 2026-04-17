import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/meal_entry.dart';
import '../models/food_item.dart';
import '../models/weight_log.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

/// FirestoreService handles all data persistence via Cloud Firestore.
class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static List<_CachedFoodRecord>? _foodCache;

  // Singleton
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // ── User Profile ─────────────────────────────────────────────

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap());
    } catch (e, stack) {
      debugPrint('Firestore Error [createUserProfile]: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(uid, doc.data()!);
      }
    } catch (e, stack) {
      debugPrint('Firestore Error [getUserProfile]: $e');
      debugPrint(stack.toString());
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e, stack) {
      debugPrint('Firestore Error [updateUserProfile]: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ── Meals ─────────────────────────────────────────────────────

  Future<void> saveMealEntry(MealEntry entry) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(entry.userId)
          .collection('meals')
          .doc(entry.id.isEmpty ? null : entry.id);

      final finalEntry =
          entry.id.isEmpty ? entry.copyWith(id: docRef.id) : entry;

      await docRef.set(finalEntry.toMap());
    } catch (e, stack) {
      debugPrint('Firestore Error [saveMealEntry]: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<List<MealEntry>> getMealsForDate(String uid, String date) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .where('date', isEqualTo: date)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MealEntry.fromMap(doc.id, uid, doc.data()))
          .toList();
    } catch (e, stack) {
      debugPrint('Firestore Error [getMealsForDate]: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String start, String end) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MealEntry.fromMap(doc.id, uid, doc.data()))
          .toList();
    } catch (e, stack) {
      debugPrint('Firestore Error [getMealsForDateRange]: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<void> updateMealEntry(
      String uid, String mealId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(mealId)
          .update(data);
    } catch (e, stack) {
      debugPrint('Firestore Error [updateMealEntry]: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> deleteMealEntry(String uid, String mealId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(mealId)
          .delete();
    } catch (e, stack) {
      debugPrint('Firestore Error [deleteMealEntry]: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ── Food Search (Global `foods` Collection) ───────────────────

  Future<List<FoodItem>> searchFoods(
    String query, {
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return [];

      final foods = await _loadFoodCache();
      final scored = foods
          .map((record) => _ScoredFood(
                food: record.food,
                score: _scoreFoodMatch(q, record),
              ))
          .where((record) => record.score > 0)
          .toList()
        ..sort((a, b) {
          final scoreComparison = b.score.compareTo(a.score);
          if (scoreComparison != 0) return scoreComparison;
          return a.food.nameEn.compareTo(b.food.nameEn);
        });

      if (limit <= 0) return [];
      final safeOffset = offset < 0 ? 0 : offset;
      if (safeOffset >= scored.length) return [];
      final end = (safeOffset + limit) > scored.length
          ? scored.length
          : (safeOffset + limit);

      return scored
          .sublist(safeOffset, end)
          .map((record) => record.food)
          .toList();
    } catch (e, stack) {
      debugPrint('Firestore Error [searchFoods]: $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<List<_CachedFoodRecord>> _loadFoodCache() async {
    final cache = _foodCache;
    if (cache != null) return cache;

    final snapshot = await _firestore.collection('foods').get();
    final foods = snapshot.docs.map((doc) {
      final data = doc.data();
      return _CachedFoodRecord(
        food: FoodItem.fromMap(doc.id, data),
        searchTerms:
            List<String>.from(data['searchTerms'] as List? ?? const []),
      );
    }).toList();

    _foodCache = foods;
    return foods;
  }

  int _scoreFoodMatch(String query, _CachedFoodRecord record) {
    final nameEn = record.food.nameEn.toLowerCase();
    final nameMy = record.food.nameMy.toLowerCase();
    final q = query.toLowerCase().trim();

    // 1. Exact Match (Highest)
    if (nameEn == q || nameMy == q) return 100;

    // 2. Prefix Match (High)
    if (nameEn.startsWith(q) || nameMy.startsWith(q)) return 95;

    // 3. Whole Word Contains (Medium-High)
    // Avoids "water" in "watermelon" matching "mineral water" too highly
    final wordsEn = nameEn.split(RegExp(r'\s+'));
    final wordsMy = nameMy.split(RegExp(r'\s+'));
    if (wordsEn.contains(q) || wordsMy.contains(q)) return 90;

    // 4. Token Set Ratio
    final tsScore = tokenSetRatio(q, nameEn) > tokenSetRatio(q, nameMy)
        ? tokenSetRatio(q, nameEn)
        : tokenSetRatio(q, nameMy);

    // 5. Weighted Ratio (Broader fallback)
    final wScore = weightedRatio(q, nameEn) > weightedRatio(q, nameMy)
        ? weightedRatio(q, nameEn)
        : weightedRatio(q, nameMy);

    final finalScore = tsScore > wScore ? tsScore : wScore;

    // Threshold Check: Lowered to 50 for better availability
    if (finalScore < 50) {
      for (final term in record.searchTerms) {
        if (term.toLowerCase().contains(q)) return 65;
      }
      return 0;
    }

    return finalScore;
  }

  Future<FoodItem?> getFoodById(String foodId) async {
    try {
      final doc = await _firestore.collection('foods').doc(foodId).get();
      if (doc.exists) {
        return FoodItem.fromMap(doc.id, doc.data()!);
      }
    } catch (e, stack) {
      debugPrint('Firestore Error [getFoodById]: $e');
      debugPrint(stack.toString());
    }
    return null;
  }

  Future<FoodItem?> getFoodByName(String name) async {
    try {
      final lower = name.toLowerCase();

      var snapshot = await _firestore
          .collection('foods')
          .where('nameEnLower', isEqualTo: lower)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return FoodItem.fromMap(doc.id, doc.data());
      }

      snapshot = await _firestore
          .collection('foods')
          .where('nameMyLower', isEqualTo: lower)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return FoodItem.fromMap(doc.id, doc.data());
      }
    } catch (e, stack) {
      debugPrint('Firestore Error [getFoodByName]: $e');
      debugPrint(stack.toString());
    }
    return null;
  }

  // ── Weight Logs ───────────────────────────────────────────────

  Future<void> saveWeightLog(String uid, WeightLog log) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('weight_logs')
          .doc(log.id.isEmpty ? null : log.id);

      final finalLog = log.id.isEmpty ? log.copyWith(id: docRef.id) : log;

      await docRef.set(finalLog.toMap());
    } catch (e, stack) {
      debugPrint('Firestore Error [saveWeightLog]: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<List<WeightLog>> getWeightLogs(String uid,
      {int limitDays = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: limitDays));
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('weight_logs')
          .where('date',
              isGreaterThanOrEqualTo: cutoff.toIso8601String().substring(0, 10))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => WeightLog.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e, stack) {
      debugPrint('Firestore Error [getWeightLogs]: $e');
      debugPrint(stack.toString());
      return [];
    }
  }
}

class _CachedFoodRecord {
  final FoodItem food;
  final List<String> searchTerms;

  const _CachedFoodRecord({required this.food, required this.searchTerms});
}

class _ScoredFood {
  final FoodItem food;
  final int score;

  const _ScoredFood({required this.food, required this.score});
}
