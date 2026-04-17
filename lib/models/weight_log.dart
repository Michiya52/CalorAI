class WeightLog {
  final String id;
  final String date; // 'YYYY-MM-DD'
  final double weightKg;

  const WeightLog({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  factory WeightLog.fromMap(String id, Map<String, dynamic> map) => WeightLog(
        id: id,
        date: map['date'] as String,
        weightKg: (map['weightKg'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {'date': date, 'weightKg': weightKg};

  WeightLog copyWith({
    String? id,
    String? date,
    double? weightKg,
  }) =>
      WeightLog(
        id: id ?? this.id,
        date: date ?? this.date,
        weightKg: weightKg ?? this.weightKg,
      );
}
