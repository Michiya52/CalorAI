import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../core/utils/calorie_calculator.dart';

/// Manages the state of the user's personal profile and macro targets.
///
/// This provider handles loading and saving the [UserProfile] from Firestore,
/// automatically recalculating daily calorie goals (using [CalorieCalculator])
/// when the user's weight or activity level changes.
class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    _error = null;
    _hasLoaded = false;
    notifyListeners();
  }

  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _firestore.getUserProfile(uid);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProfile(UserProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.createUserProfile(profile);
      _profile = profile;
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to create profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestore.updateUserProfile(uid, data);
      _profile = await _firestore.getUserProfile(uid);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to update profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  Future<int?> recalculateTarget({
    double? weightKg,
    double? heightCm,
    int? age,
  }) async {
    if (_profile == null) return null;
    final newTarget = CalorieCalculator.calculateTarget(
      weightKg: weightKg ?? _profile!.weightKg,
      heightCm: heightCm ?? _profile!.heightCm,
      age: age ?? _profile!.age,
      sex: _profile!.sex,
      activityLevel: _profile!.activityLevel,
      goal: _profile!.goal,
    );
    final previousTarget = _profile!.calorieTarget;
    final shouldAutoUpdateMacros = !_profile!.isMacroTargetsManual;
    _profile = _profile!.copyWith(
      weightKg: weightKg ?? _profile!.weightKg,
      heightCm: heightCm ?? _profile!.heightCm,
      age: age ?? _profile!.age,
      calorieTarget: newTarget,
      isCalorieTargetManual: false,
      isMacroTargetsManual: shouldAutoUpdateMacros ? false : true,
      macroTargets: shouldAutoUpdateMacros
          ? MacroTargets.fromCalories(newTarget)
          : _profile!.macroTargets,
    );

    final data = <String, dynamic>{
      'weightKg': _profile!.weightKg,
      'heightCm': _profile!.heightCm,
      'age': _profile!.age,
      'calorieTarget': newTarget,
      'isCalorieTargetManual': false,
      'isMacroTargetsManual': _profile!.isMacroTargetsManual,
    };
    if (shouldAutoUpdateMacros) {
      data['macroTargets'] = MacroTargets.fromCalories(newTarget).toMap();
    }

    await _firestore.updateUserProfile(_profile!.uid, data);

    notifyListeners();
    return previousTarget;
  }
}
