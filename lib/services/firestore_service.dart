import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/user_profile.dart';
import '../models/meal_entry.dart';
import '../models/food_item.dart';
import '../models/weight_log.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'logger_service.dart';

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
      LoggerService().error(e, stack, reason: 'Firestore Error [createUserProfile]');
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
      LoggerService().error(e, stack, reason: 'Firestore Error [getUserProfile]');
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'Firestore Error [updateUserProfile]');
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
      LoggerService().error(e, stack, reason: 'Firestore Error [saveMealEntry]');
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
          .map((doc) {
            try {
              return MealEntry.fromMap(doc.id, uid, doc.data());
            } catch (e, stack) {
              LoggerService().error(e, stack, reason: 'Error parsing meal ${doc.id}');
              return null;
            }
          })
          .whereType<MealEntry>()
          .toList();
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'Firestore Error [getMealsForDate]');
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
          .map((doc) {
            try {
              return MealEntry.fromMap(doc.id, uid, doc.data());
            } catch (e, stack) {
              LoggerService().error(e, stack, reason: 'Error parsing meal range ${doc.id}');
              return null;
            }
          })
          .whereType<MealEntry>()
          .toList();
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'Firestore Error [getMealsForDateRange]');
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
      LoggerService().error(e, stack, reason: 'Firestore Error [updateMealEntry]');
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
      LoggerService().error(e, stack, reason: 'Firestore Error [deleteMealEntry]');
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

      // Perform fuzzy math synchronously; for 1400 items it's extremely fast (~10ms)
      // and avoids Isolate spawning overhead/serialization errors.
      final scored = _runFuzzySearch(q, foods);

      scored.sort((a, b) {
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
      LoggerService().error(e, stack, reason: 'Firestore Error [searchFoods]');
      return [];
    }
  }

  Future<List<_CachedFoodRecord>> _loadFoodCache() async {
    final cache = _foodCache;
    // Keep in memory indefinitely to avoid redundant asset parsing
    if (cache != null) return cache;

    try {
      // Load bundled dataset instead of expensive Firestore reads
      final jsonString =
          await rootBundle.loadString('assets/data/myfcd_full.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final foods = jsonList.map((data) {
        final map = data as Map<String, dynamic>;
        final id = map['myfcdCode']?.toString() ?? map['id']?.toString() ?? '';
        return _CachedFoodRecord(
          food: FoodItem.fromMap(id, map),
          searchTerms:
              List<String>.from(map['searchTerms'] as List? ?? const []),
        );
      }).toList();

      _foodCache = foods;
      return foods;
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'Error loading local JSON cache');
      return [];
    }
  }

  /// Forces the food cache to be reloaded on the next search.
  void invalidateFoodCache() {
    _foodCache = null;
  }

  Future<FoodItem?> getFoodById(String foodId) async {
    try {
      final doc = await _firestore.collection('foods').doc(foodId).get();
      if (doc.exists) {
        return FoodItem.fromMap(doc.id, doc.data()!);
      }
    } catch (e, stack) {
      LoggerService().error(e, stack, reason: 'Firestore Error [getFoodById]');
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
      LoggerService().error(e, stack, reason: 'Firestore Error [getFoodByName]');
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
      LoggerService().error(e, stack, reason: 'Firestore Error [saveWeightLog]');
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
      LoggerService().error(e, stack, reason: 'Firestore Error [getWeightLogs]');
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

// ── Background Isolate Handlers ─────────────────────────────────

List<_ScoredFood> _runFuzzySearch(String query, List<_CachedFoodRecord> foods) {
  final scored = <_ScoredFood>[];
  for (final record in foods) {
    final score = _scoreFoodMatchStatic(query, record);
    if (score > 0) {
      scored.add(_ScoredFood(food: record.food, score: score));
    }
  }
  return scored;
}

// Normalizes strings by stripping all punctuation and special characters.
// This prevents fuzzy matching failures when the AI outputs "(Maggi Goreng)"
// but the database contains "Maggi Goreng".
String _normalize(String s) {
  return s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
}

int _scoreFoodMatchStatic(String query, _CachedFoodRecord record) {
  final nameEn = _normalize(record.food.nameEn);
  final nameMy = _normalize(record.food.nameMy);
  final q = _normalize(query);

  // 1. Exact Match (Highest)
  if (nameEn == q || nameMy == q) return 100;

  // 2. Prefix Match (High)
  if (nameEn.startsWith(q) || nameMy.startsWith(q)) return 95;

  // 3. Whole Word Contains (Medium-High)
  if (nameEn.split(RegExp(r'\s+')).contains(q) ||
      nameMy.split(RegExp(r'\s+')).contains(q)) {
    return 90;
  }

  // 4. Fuzzy matching
  final tsEn = tokenSetRatio(q, nameEn);
  final tsMy = tokenSetRatio(q, nameMy);
  final tsScore = tsEn > tsMy ? tsEn : tsMy;

  final wEn = weightedRatio(q, nameEn);
  final wMy = weightedRatio(q, nameMy);
  final wScore = wEn > wMy ? wEn : wMy;

  final finalScore = tsScore > wScore ? tsScore : wScore;

  // Threshold Check
  if (finalScore < 50) {
    for (final term in record.searchTerms) {
      if (term.toLowerCase().contains(q)) return 65;
    }
    return 0;
  }

  return finalScore;
}
