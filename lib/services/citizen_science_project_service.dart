import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/citizen_science_project.dart';

class CitizenScienceProjectService {
  CitizenScienceProjectService._();

  static final CitizenScienceProjectService instance =
      CitizenScienceProjectService._();

  static CitizenScienceProject? _cachedProject;

  Future<CitizenScienceProject> getOpenFoodFactsProject() async {
    final cached = _cachedProject;
    if (cached != null) return cached;

    try {
      final response = await http
          .get(Uri.parse('https://citizenscience.eu/api/project/430'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final project = CitizenScienceProject.fromJson(decoded);
          _cachedProject = project;
          return project;
        }
      }

      throw Exception('Unexpected project response: ${response.statusCode}');
    } catch (e) {
      debugPrint('CitizenScienceProjectService error: $e');
      final fallback = CitizenScienceProject(
        id: 430,
        name: 'Open Food Facts - world\'s largest open food database !',
        url: 'https://world.openfoodfacts.org/',
        description:
            'Open Food Facts is a collaborative, free and open database of food products from around the world.',
        aim:
            'Advance food transparency and help people make better food choices.',
        equipment: 'Food products with barcodes, a smartphone, or a computer.',
        imageUrl:
            'https://citizenscience.eu/media/images/2023-07-31_040407070505_854_EXE_LOGO_OFF_CMJN_Plan%20de%20travail%201%20copie%208.jpg',
        status: 'Active',
        difficulty: 'Easy',
        locality: 'Global',
        keywords: const ['food', 'environment', 'health'],
        participationTasks: const [
          'Classification or tagging',
          'Data analysis',
          'Data Entry',
          'Photography',
        ],
        tags: const ['Participate from home'],
      );
      _cachedProject = fallback;
      return fallback;
    }
  }
}
