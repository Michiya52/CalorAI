class CitizenScienceProject {
  final int id;
  final String name;
  final String url;
  final String description;
  final String aim;
  final String equipment;
  final String imageUrl;
  final String status;
  final String difficulty;
  final String locality;
  final List<String> keywords;
  final List<String> participationTasks;
  final List<String> tags;

  const CitizenScienceProject({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.aim,
    required this.equipment,
    required this.imageUrl,
    required this.status,
    required this.difficulty,
    required this.locality,
    required this.keywords,
    required this.participationTasks,
    required this.tags,
  });

  factory CitizenScienceProject.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic value, String key) {
      if (value is! List) return const [];
      return value
          .map((item) => item is Map ? item[key]?.toString() : item.toString())
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return CitizenScienceProject(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString().trim(),
      url: _extractUrl(json['url']?.toString() ?? ''),
      description: _htmlToText(json['description_en']?.toString() ??
          json['description']?.toString() ??
          ''),
      aim: _htmlToText(
          json['aim_en']?.toString() ?? json['aim']?.toString() ?? ''),
      equipment: _htmlToText(json['equipment_en']?.toString() ??
          json['equipment']?.toString() ??
          ''),
      imageUrl: _extractUrl(json['image1']?.toString() ?? ''),
      status: _cleanText(json['status'] is Map
          ? (json['status']['status_en'] ?? json['status']['status'] ?? '')
              .toString()
          : ''),
      difficulty: _cleanText(json['difficultyLevel'] is Map
          ? (json['difficultyLevel']['difficultyLevel'] ??
                  json['difficultyLevel']['difficultyLevel_en'] ??
                  '')
              .toString()
          : ''),
      locality: _cleanText(json['projectlocality']?.toString() ?? ''),
      keywords: toStringList(json['keywords'], 'keyword'),
      participationTasks:
          toStringList(json['participationTask'], 'participationTask_en'),
      tags: toStringList(json['hasTag'], 'hasTag_en'),
    );
  }

  static String _htmlToText(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  static String _cleanText(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _extractUrl(String input) {
    final match = RegExp(r'https?://[^\s\]\)]+').firstMatch(input);
    if (match != null) {
      return match.group(0)!.trim();
    }
    return _cleanText(input);
  }
}
