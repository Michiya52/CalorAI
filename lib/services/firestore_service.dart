import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/meal_entry.dart';
import '../models/food_item.dart';
import '../models/weight_log.dart';

/// Mock FirestoreService that stores data locally in JSON files.
/// Simulates Firestore CRUD without a real Firebase connection.
class FirestoreService {
  // ── Helpers ─────────────────────────────────────────────────
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${directory.path}/calor_ai_data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir.path;
  }

  Future<Map<String, dynamic>> _readJsonFile(String filename) async {
    final path = await _localPath;
    final file = File('$path/$filename');
    if (await file.exists()) {
      final contents = await file.readAsString();
      if (contents.isNotEmpty) {
        return jsonDecode(contents) as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<void> _writeJsonFile(String filename, Map<String, dynamic> data) async {
    final path = await _localPath;
    final file = File('$path/$filename');
    // Ensure data is JSON-serializable
    await file.writeAsString(jsonEncode(_sanitizeMap(data)));
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      } else if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitizeMap(value));
      } else if (value is List) {
        return MapEntry(key, value.map((e) {
          if (e is Map<String, dynamic>) return _sanitizeMap(e);
          if (e is Timestamp) return e.toDate().toIso8601String();
          if (e is DateTime) return e.toIso8601String();
          return e;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }

  // ── User Profile ─────────────────────────────────────────────
  Future<void> createUserProfile(UserProfile profile) async {
    final users = await _readJsonFile('users.json');
    users[profile.uid] = profile.toLocalMap();
    await _writeJsonFile('users.json', users);
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final users = await _readJsonFile('users.json');
    if (users.containsKey(uid)) {
      final data = Map<String, dynamic>.from(users[uid] as Map);
      // Convert stored ISO string back to mock timestamp
      if (data['createdAt'] is String) {
        data['_createdAtString'] = data['createdAt'];
      }
      return UserProfile.fromLocalMap(uid, data);
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final users = await _readJsonFile('users.json');
    if (users.containsKey(uid)) {
      final existing = Map<String, dynamic>.from(users[uid] as Map);
      existing.addAll(data);
      users[uid] = existing;
      await _writeJsonFile('users.json', users);
    }
  }

  // ── Meals ─────────────────────────────────────────────────────
  Future<void> saveMealEntry(MealEntry entry) async {
    final meals = await _readJsonFile('meals_${entry.userId}.json');
    meals[entry.id] = entry.toLocalMap();
    await _writeJsonFile('meals_${entry.userId}.json', meals);
  }

  Future<List<MealEntry>> getMealsForDate(String uid, String date) async {
    final meals = await _readJsonFile('meals_$uid.json');
    final results = <MealEntry>[];
    for (final entry in meals.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      if (data['date'] == date) {
        results.add(MealEntry.fromLocalMap(entry.key, uid, data));
      }
    }
    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return results;
  }

  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String start, String end) async {
    final meals = await _readJsonFile('meals_$uid.json');
    final results = <MealEntry>[];
    for (final entry in meals.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      final date = data['date'] as String;
      if (date.compareTo(start) >= 0 && date.compareTo(end) <= 0) {
        results.add(MealEntry.fromLocalMap(entry.key, uid, data));
      }
    }
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  Future<void> updateMealEntry(
      String uid, String mealId, Map<String, dynamic> data) async {
    final meals = await _readJsonFile('meals_$uid.json');
    if (meals.containsKey(mealId)) {
      final existing = Map<String, dynamic>.from(meals[mealId] as Map);
      existing.addAll(data);
      meals[mealId] = existing;
      await _writeJsonFile('meals_$uid.json', meals);
    }
  }

  Future<void> deleteMealEntry(String uid, String mealId) async {
    final meals = await _readJsonFile('meals_$uid.json');
    meals.remove(mealId);
    await _writeJsonFile('meals_$uid.json', meals);
  }

  // ── Food Search (MyFCD) ───────────────────────────────────────
  // In-memory cache of foods loaded from asset
  static List<FoodItem>? _foodsCache;

  Future<void> loadFoodsFromAsset(String jsonString) async {
    final list = jsonDecode(jsonString) as List<dynamic>;
    _foodsCache = list.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final id = map['id'] as String? ?? 'food_${list.indexOf(e)}';
      return FoodItem.fromMap(id, map);
    }).toList();
  }

  Future<List<FoodItem>> searchFoods(String query) async {
    if (_foodsCache == null) return [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    return _foodsCache!
        .where((food) =>
            food.nameEn.toLowerCase().contains(q) ||
            food.nameMy.toLowerCase().contains(q))
        .take(10)
        .toList();
  }

  Future<FoodItem?> getFoodById(String foodId) async {
    if (_foodsCache == null) return null;
    try {
      return _foodsCache!.firstWhere((f) => f.id == foodId);
    } catch (_) {
      return null;
    }
  }

  Future<FoodItem?> getFoodByName(String name) async {
    if (_foodsCache == null) return null;
    final lower = name.toLowerCase();
    try {
      return _foodsCache!.firstWhere(
        (f) => f.nameEn.toLowerCase() == lower || f.nameMy.toLowerCase() == lower,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Weight Logs ───────────────────────────────────────────────
  Future<void> saveWeightLog(String uid, WeightLog log) async {
    final logs = await _readJsonFile('weight_logs_$uid.json');
    logs[log.id] = log.toMap();
    await _writeJsonFile('weight_logs_$uid.json', logs);
  }

  Future<List<WeightLog>> getWeightLogs(String uid, {int limitDays = 30}) async {
    final logs = await _readJsonFile('weight_logs_$uid.json');
    final cutoff = DateTime.now().subtract(Duration(days: limitDays));
    final cutoffStr = cutoff.toIso8601String().substring(0, 10);
    final results = <WeightLog>[];
    for (final entry in logs.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      if ((data['date'] as String).compareTo(cutoffStr) >= 0) {
        results.add(WeightLog.fromMap(entry.key, data));
      }
    }
    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }
}
