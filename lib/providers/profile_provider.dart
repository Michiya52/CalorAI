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

  void recalculateTarget() {
    if (_profile == null) return;
    final newTarget = CalorieCalculator.calculateTarget(
      weightKg: _profile!.weightKg,
      heightCm: _profile!.heightCm,
      age: _profile!.age,
      sex: _profile!.sex,
      activityLevel: _profile!.activityLevel,
      goal: _profile!.goal,
    );
    _profile = _profile!.copyWith(
      calorieTarget: newTarget,
      isCalorieTargetManual: false,
    );
    notifyListeners();
  }
}
