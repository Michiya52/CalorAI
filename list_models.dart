import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final key = dotenv.env['GEMINI_API_KEY'];
  if (key == null) {
      print('api key null');
      return;
  }
  
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key');
  final res = await http.get(url);
  
  if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final models = json['models'] as List;
      for (var model in models) {
          if (model['name'].toString().contains('flash') || model['name'].toString().contains('2')) {
              print('Model: ${model['name']} (Vision: ${model['supportedGenerationMethods']?.contains('generateContent')})');
          }
      }
  } else {
      print('Error: ${res.statusCode} ${res.body}');
  }
}
