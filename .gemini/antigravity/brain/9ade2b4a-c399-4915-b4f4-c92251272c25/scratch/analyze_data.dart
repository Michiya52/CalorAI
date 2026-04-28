import 'dart:convert';
import 'dart:io';

void main() {
  final myfcdPath = 'c:/Users/User/Desktop/CalorAI/CalorAI/assets/data/myfcd_full.json';
  final sgfocosPath = 'c:/Users/User/Desktop/CalorAI/CalorAI/assets/data/sgfocos_full.json';

  final myfcd = jsonDecode(File(myfcdPath).readAsStringSync()) as List;
  final sgfocos = jsonDecode(File(sgfocosPath).readAsStringSync()) as List;

  final allFoods = [...myfcd, ...sgfocos];
  print('Total foods in JSON: ${allFoods.length}');

  final outliers = [];
  final duplicates = <String, List<String>>{};
  final seenNames = <String, String>{};

  for (final food in allFoods) {
    final name = food['nameEn']?.toString().toLowerCase() ?? '';
    final code = food['myfcdCode']?.toString() ?? 'unknown';
    
    // Duplicate check
    if (seenNames.containsKey(name)) {
      duplicates.putIfAbsent(name, () => [seenNames[name]!]).add(code);
    } else {
      seenNames[name] = code;
    }

    // Outlier check
    final calories = (food['caloriesPer100g'] as num?)?.toDouble() ?? 0.0;
    final protein = (food['proteinPer100g'] as num?)?.toDouble() ?? 0.0;
    final carbs = (food['carbsPer100g'] as num?)?.toDouble() ?? 0.0;
    final fats = (food['fatsPer100g'] as num?)?.toDouble() ?? 0.0;

    final macroSum = protein + carbs + fats;

    if (calories > 900 || calories < 0) {
      outliers.add({'name': name, 'code': code, 'issue': 'Calories: $calories'});
    } else if (macroSum > 105) { // 5g tolerance for water/minerals/fiber overlap in raw data
      outliers.add({'name': name, 'code': code, 'issue': 'Macro sum: $macroSum'});
    } else if (protein > 100 || carbs > 100 || fats > 100) {
      outliers.add({'name': name, 'code': code, 'issue': 'Individual macro > 100'});
    }
  }

  print('\n--- OUTLIERS (${outliers.length}) ---');
  for (var i = 0; i < outliers.length && i < 20; i++) {
    print('${outliers[i]['name']} (${outliers[i]['code']}): ${outliers[i]['issue']}');
  }

  print('\n--- POTENTIAL DUPLICATES (${duplicates.length}) ---');
  final duplicateList = duplicates.entries.toList();
  for (var i = 0; i < duplicateList.length && i < 20; i++) {
    print('${duplicateList[i].key}: ${duplicateList[i].value}');
  }
}
