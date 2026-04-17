import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../core/utils/calorie_calculator.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  UserProfile? _profile;
  bool _isLoading = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    notifyListeners();
    _profile = await _firestore.getUserProfile(uid);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();
    await _firestore.createUserProfile(profile);
    _profile = profile;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.updateUserProfile(uid, data);
    await loadProfile(uid);
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
