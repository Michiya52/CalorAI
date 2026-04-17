class CalorieCalculator {
  /// BMR in kcal/day
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String sex, // 'male' | 'female'
  }) {
    if (sex == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'lightly_active': 1.375,
    'moderately_active': 1.55,
    'very_active': 1.725,
  };

  static const Map<String, int> goalAdjustments = {
    'lose_weight': -500,
    'maintain': 0,
    'gain_muscle': 300,
    'eat_healthier': 0,
  };

  /// Recommended daily kcal target
  static int calculateTarget({
    required double weightKg,
    required double heightCm,
    required int age,
    required String sex,
    required String activityLevel,
    required String goal,
  }) {
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      sex: sex,
    );
    final tdee = bmr * (activityMultipliers[activityLevel] ?? 1.2);
    final adjustment = goalAdjustments[goal] ?? 0;
    return (tdee + adjustment).round();
  }
}
