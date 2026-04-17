import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  final String id;
  final String userId;
  final String date; // 'YYYY-MM-DD'
  final DateTime timestamp;
  final String foodNameEn;
  final String foodNameMy;
  final String? myfcdId;
  final String source; // 'MyFCD' | 'AI Estimate' | 'Manual'
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final String portionLabel; // 'Small' | 'Medium' | 'Large' | 'Custom'
  final double portionGrams;
  final String? aiConfidence; // 'low' | 'medium' | 'high' | null
  final bool imageDeleted; // Always true
  final double? caloricDensity;

  const MealEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.timestamp,
    required this.foodNameEn,
    required this.foodNameMy,
    this.myfcdId,
    required this.source,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.portionLabel,
    required this.portionGrams,
    this.aiConfidence,
    required this.imageDeleted,
    this.caloricDensity,
  });

  factory MealEntry.fromMap(
    String id,
    String userId,
    Map<String, dynamic> map,
  ) => MealEntry(
    id: id,
    userId: userId,
    date: map['date'] as String,
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    foodNameEn: map['foodNameEn'] as String,
    foodNameMy: map['foodNameMy'] as String,
    myfcdId: map['myfcdId'] as String?,
    source: map['source'] as String,
    calories: map['calories'] as int,
    proteinG: (map['proteinG'] as num).toDouble(),
    carbsG: (map['carbsG'] as num).toDouble(),
    fatsG: (map['fatsG'] as num).toDouble(),
    portionLabel: map['portionLabel'] as String,
    portionGrams: (map['portionGrams'] as num).toDouble(),
    aiConfidence: map['aiConfidence'] as String?,
    imageDeleted: map['imageDeleted'] as bool? ?? true,
    caloricDensity: (map['caloricDensity'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'date': date,
    'timestamp': Timestamp.fromDate(timestamp),
    'foodNameEn': foodNameEn,
    'foodNameMy': foodNameMy,
    'myfcdId': myfcdId,
    'source': source,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatsG': fatsG,
    'portionLabel': portionLabel,
    'portionGrams': portionGrams,
    'aiConfidence': aiConfidence,
    'imageDeleted': imageDeleted,
    'caloricDensity': caloricDensity,
  };

  MealEntry copyWith({
    String? id,
    String? userId,
    String? date,
    DateTime? timestamp,
    String? foodNameEn,
    String? foodNameMy,
    String? myfcdId,
    String? source,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatsG,
    String? portionLabel,
    double? portionGrams,
    String? aiConfidence,
    bool? imageDeleted,
    double? caloricDensity,
  }) => MealEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    timestamp: timestamp ?? this.timestamp,
    foodNameEn: foodNameEn ?? this.foodNameEn,
    foodNameMy: foodNameMy ?? this.foodNameMy,
    myfcdId: myfcdId ?? this.myfcdId,
    source: source ?? this.source,
    calories: calories ?? this.calories,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatsG: fatsG ?? this.fatsG,
    portionLabel: portionLabel ?? this.portionLabel,
    portionGrams: portionGrams ?? this.portionGrams,
    aiConfidence: aiConfidence ?? this.aiConfidence,
    imageDeleted: imageDeleted ?? this.imageDeleted,
    caloricDensity: caloricDensity ?? this.caloricDensity,
  );

  double get effectiveCaloricDensity =>
      caloricDensity ?? (portionGrams > 0 ? calories / portionGrams : 0.0);
}
