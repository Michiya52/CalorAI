class PortionSizes {
  final double smallGrams;
  final double mediumGrams;
  final double largeGrams;

  const PortionSizes({
    required this.smallGrams,
    required this.mediumGrams,
    required this.largeGrams,
  });

  factory PortionSizes.fromMap(Map<String, dynamic> map) => PortionSizes(
        smallGrams: (map['smallGrams'] as num? ?? 100).toDouble(),
        mediumGrams: (map['mediumGrams'] as num? ?? 250).toDouble(),
        largeGrams: (map['largeGrams'] as num? ?? 400).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'smallGrams': smallGrams,
        'mediumGrams': mediumGrams,
        'largeGrams': largeGrams,
      };
}

class FoodItem {
  final String id;
  final String nameEn;
  final String nameMy;
  final String foodGroup;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final double sodiumPer100g;
  final double sugarPer100g;
  final List<String> ingredients;
  final PortionSizes portionSizes;
  final String source; // Always 'MyFCD_2026'
  final String myfcdCode;

  const FoodItem({
    required this.id,
    required this.nameEn,
    required this.nameMy,
    required this.foodGroup,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.sodiumPer100g,
    required this.sugarPer100g,
    required this.ingredients,
    required this.portionSizes,
    required this.source,
    required this.myfcdCode,
  });

  factory FoodItem.fromMap(String id, Map<String, dynamic> map) => FoodItem(
        id: id,
        nameEn: map['nameEn'] as String? ?? 'Unknown Food',
        nameMy: map['nameMy'] as String? ?? map['nameEn'] as String? ?? '',
        foodGroup: map['foodGroup'] as String? ?? 'Other',
        caloriesPer100g: (map['caloriesPer100g'] as num? ?? 0).toDouble(),
        proteinPer100g: (map['proteinPer100g'] as num? ?? 0).toDouble(),
        carbsPer100g: (map['carbsPer100g'] as num? ?? 0).toDouble(),
        fatsPer100g: (map['fatsPer100g'] as num? ?? 0).toDouble(),
        sodiumPer100g: (map['sodiumPer100g'] as num? ?? 0).toDouble(),
        sugarPer100g: (map['sugarPer100g'] as num? ?? 0).toDouble(),
        ingredients: (map['ingredients'] as List? ?? []).cast<String>(),
        portionSizes: map['portionSizes'] != null
            ? PortionSizes.fromMap(map['portionSizes'] as Map<String, dynamic>)
            : const PortionSizes(smallGrams: 100, mediumGrams: 250, largeGrams: 400),
        source: map['source'] as String? ?? 'Unknown',
        myfcdCode: map['myfcdCode'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'nameEn': nameEn,
        'nameMy': nameMy,
        'foodGroup': foodGroup,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatsPer100g': fatsPer100g,
        'sodiumPer100g': sodiumPer100g,
        'sugarPer100g': sugarPer100g,
        'ingredients': ingredients,
        'portionSizes': portionSizes.toMap(),
        'source': source,
        'myfcdCode': myfcdCode,
      };

  FoodItem copyWith({
    String? nameEn,
    String? nameMy,
    String? foodGroup,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatsPer100g,
    double? sodiumPer100g,
    double? sugarPer100g,
    List<String>? ingredients,
    PortionSizes? portionSizes,
    String? source,
    String? myfcdCode,
  }) =>
      FoodItem(
        id: id,
        nameEn: nameEn ?? this.nameEn,
        nameMy: nameMy ?? this.nameMy,
        foodGroup: foodGroup ?? this.foodGroup,
        caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
        proteinPer100g: proteinPer100g ?? this.proteinPer100g,
        carbsPer100g: carbsPer100g ?? this.carbsPer100g,
        fatsPer100g: fatsPer100g ?? this.fatsPer100g,
        sodiumPer100g: sodiumPer100g ?? this.sodiumPer100g,
        sugarPer100g: sugarPer100g ?? this.sugarPer100g,
        ingredients: ingredients ?? this.ingredients,
        portionSizes: portionSizes ?? this.portionSizes,
        source: source ?? this.source,
        myfcdCode: myfcdCode ?? this.myfcdCode,
      );
}
