import 'dart:convert';
import 'dart:io';

void main() {
  final all = jsonDecode(File('c:/Users/User/Desktop/CalorAI/CalorAI/assets/data/myfcd_full.json').readAsStringSync()) as List;
  final search = ['kuey teow', 'kway teow', 'bak kut teh', 'wantan', 'wonton', 'nasi kandar', 'murtabak'];
  
  for (final s in search) {
    final matches = all.where((f) => f['nameEn'].toString().toLowerCase().contains(s)).toList();
    print('$s: ${matches.length} matches');
    if (matches.isNotEmpty) {
      print('  Example: ${matches.first['nameEn']}');
    }
  }
}
