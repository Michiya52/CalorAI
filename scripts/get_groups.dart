import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/data/myfcd_full.json');
  final data = jsonDecode(file.readAsStringSync()) as List;
  final groups = data.map((e) => e['foodGroup']).toSet().toList();
  groups.sort();
  print(groups);
}
