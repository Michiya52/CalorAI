import 'package:cloud_firestore/cloud_firestore.dart';

class MacroTargets {
  final int proteinG;
  final int carbsG;
  final int fatsG;

  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  factory MacroTargets.fromMap(Map<String, dynamic> map) => MacroTargets(
    proteinG: map['proteinG'] as int,
    carbsG: map['carbsG'] as int,
    fatsG: map['fatsG'] as int,
  );

  Map<String, dynamic> toMap() => {
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatsG': fatsG,
  };
}

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final double heightCm;
  final double weightKg;
  final int age;
  final String sex; // 'male' | 'female'
  final String
  activityLevel; // 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active'
  final String
  goal; // 'lose_weight' | 'maintain' | 'gain_muscle' | 'eat_healthier'
  final int calorieTarget;
  final bool isCalorieTargetManual;
  final MacroTargets? macroTargets;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.sex,
    required this.activityLevel,
    required this.goal,
    required this.calorieTarget,
    required this.isCalorieTargetManual,
    this.macroTargets,
    required this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) =>
      UserProfile(
        uid: uid,
        name: map['name'] as String,
        email: map['email'] as String,
        heightCm: (map['heightCm'] as num).toDouble(),
        weightKg: (map['weightKg'] as num).toDouble(),
        age: map['age'] as int,
        sex: map['sex'] as String,
        activityLevel: map['activityLevel'] as String,
        goal: map['goal'] as String,
        calorieTarget: map['calorieTarget'] as int,
        isCalorieTargetManual: map['isCalorieTargetManual'] as bool? ?? false,
        macroTargets: map['macroTargets'] != null
            ? MacroTargets.fromMap(map['macroTargets'] as Map<String, dynamic>)
            : null,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  /// Local JSON deserialization (no Firestore Timestamp)
  factory UserProfile.fromLocalMap(String uid, Map<String, dynamic> map) =>
      UserProfile(
        uid: uid,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170.0,
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70.0,
        age: map['age'] as int? ?? 25,
        sex: map['sex'] as String? ?? 'male',
        activityLevel: map['activityLevel'] as String? ?? 'sedentary',
        goal: map['goal'] as String? ?? 'maintain',
        calorieTarget: map['calorieTarget'] as int? ?? 2000,
        isCalorieTargetManual: map['isCalorieTargetManual'] as bool? ?? false,
        macroTargets: map['macroTargets'] != null
            ? MacroTargets.fromMap(Map<String, dynamic>.from(map['macroTargets'] as Map))
            : null,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'age': age,
    'sex': sex,
    'activityLevel': activityLevel,
    'goal': goal,
    'calorieTarget': calorieTarget,
    'isCalorieTargetManual': isCalorieTargetManual,
    if (macroTargets != null) 'macroTargets': macroTargets!.toMap(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// Local JSON serialization (ISO string instead of Timestamp)
  Map<String, dynamic> toLocalMap() => {
    'name': name,
    'email': email,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'age': age,
    'sex': sex,
    'activityLevel': activityLevel,
    'goal': goal,
    'calorieTarget': calorieTarget,
    'isCalorieTargetManual': isCalorieTargetManual,
    if (macroTargets != null) 'macroTargets': macroTargets!.toMap(),
    'createdAt': createdAt.toIso8601String(),
  };

  UserProfile copyWith({
    String? name,
    String? email,
    double? heightCm,
    int? calorieTarget,
    bool? isCalorieTargetManual,
    MacroTargets? macroTargets,
    double? weightKg,
    int? age,
    String? sex,
    String? goal,
    String? activityLevel,
  }) => UserProfile(
    uid: uid,
    name: name ?? this.name,
    email: email ?? this.email,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    activityLevel: activityLevel ?? this.activityLevel,
    goal: goal ?? this.goal,
    calorieTarget: calorieTarget ?? this.calorieTarget,
    isCalorieTargetManual: isCalorieTargetManual ?? this.isCalorieTargetManual,
    macroTargets: macroTargets ?? this.macroTargets,
    createdAt: createdAt,
  );
}
