import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/meal_entry.dart';
import '../services/openrouter_service.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String,
        isUser: json['isUser'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// A saved chat session with a title, messages, and compressed summary.
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  /// Compressed bullet-point summary of the conversation for AI memory.
  final String summary;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
    this.summary = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'summary': summary,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        summary: json['summary'] as String? ?? '',
      );
}

class ChatbotProvider extends ChangeNotifier {
  final OpenRouterService _openRouter = OpenRouterService();
  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();

  static const String _storageKey = 'chat_sessions';
  static const int _maxSessions = 25;

  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];
  List<ChatSession> _savedSessions = [];
  String? _currentSessionId;
  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatSession> get savedSessions => List.unmodifiable(_savedSessions);
  bool get isTyping => _isTyping;
  bool get hasActiveChat => _messages.isNotEmpty;

  ChatbotProvider() {
    _loadSessions();
  }

  // ── Memory / Summaries ──────────────────────────────────────────

  /// Build a compressed summary string from all saved sessions
  /// for injection into the system prompt.
  String get conversationMemory {
    final sessionsWithSummary =
        _savedSessions.where((s) => s.summary.isNotEmpty).toList();
    if (sessionsWithSummary.isEmpty) return '';

    // Most recent first, limit to keep prompt size reasonable
    final relevant = sessionsWithSummary.take(15);
    final lines = relevant.map((s) {
      final date = '${s.createdAt.day}/${s.createdAt.month}';
      return '[$date] ${s.summary}';
    }).join('\n');

    return '''
═══ PAST CONVERSATION MEMORY ═══
The user has chatted before. Key points from recent conversations:
$lines
- Use this memory to provide continuity (e.g., "Last time you asked about..." or "You mentioned...")
- Do NOT repeat this memory back to the user unless relevant to their question
''';
  }

  /// Compress a chat into bullet-point summary for long-term memory.
  /// This is done client-side to avoid burning API calls.
  String _compressChat(List<ChatMessage> messages) {
    final points = <String>[];

    // Extract user questions/topics
    final userMessages = messages.where((m) => m.isUser).toList();
    for (final msg in userMessages) {
      final text = msg.text.trim();
      if (text.length <= 60) {
        points.add('Asked: "$text"');
      } else {
        points.add('Asked: "${text.substring(0, 57)}..."');
      }
    }

    // Extract key facts from AI responses (look for calorie numbers,
    // food names, and specific advice)
    final aiMessages = messages.where((m) => !m.isUser).toList();
    for (final msg in aiMessages) {
      final text = msg.text;

      // Extract calorie mentions (e.g., "300-500 kcal")
      final calMatch = RegExp(r'(\d{2,4})\s*(?:kcal|calories)', caseSensitive: false)
          .firstMatch(text);
      if (calMatch != null) {
        // Get surrounding context (the sentence containing the calorie info)
        final start = text.lastIndexOf(RegExp(r'[.!?\n]'), calMatch.start);
        final end = text.indexOf(RegExp(r'[.!?\n]'), calMatch.end);
        final sentence = text.substring(
          start == -1 ? 0 : start + 1,
          end == -1 ? text.length : end,
        ).trim();
        if (sentence.length <= 80) {
          points.add('Info: $sentence');
        }
      }

      // Extract food recommendations (sentences with "try", "recommend",
      // "suggest", "instead", "alternative")
      final adviceMatch = RegExp(
        r'[^.!?\n]*(?:try|recommend|suggest|instead|alternative|swap|reduce)[^.!?\n]*',
        caseSensitive: false,
      ).firstMatch(text);
      if (adviceMatch != null) {
        final advice = adviceMatch.group(0)!.trim();
        if (advice.length <= 80) {
          points.add('Advice: $advice');
        } else {
          points.add('Advice: ${advice.substring(0, 77)}...');
        }
      }
    }

    // Limit to 4 points per session to keep memory compact
    return points.take(4).join(' | ');
  }

  // ── Persistence ──────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        _savedSessions = list
            .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
            .toList();
        _savedSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load chat sessions: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Enforce max sessions — oldest gets evicted, its memory is lost
      if (_savedSessions.length > _maxSessions) {
        _savedSessions = _savedSessions.sublist(0, _maxSessions);
      }
      final jsonStr =
          jsonEncode(_savedSessions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save chat sessions: $e');
    }
  }

  Future<void> _autoSaveCurrentChat() async {
    if (_messages.isEmpty) return;

    // Generate title from first user message
    final firstUserMsg = _messages.firstWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(text: 'Chat', isUser: true),
    );
    final title = firstUserMsg.text.length > 40
        ? '${firstUserMsg.text.substring(0, 40)}...'
        : firstUserMsg.text;

    final sessionId =
        _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _currentSessionId = sessionId;

    // Compress the conversation into memory points
    final summary = _compressChat(_messages);

    // Update or create session
    _savedSessions.removeWhere((s) => s.id == sessionId);
    _savedSessions.insert(
      0,
      ChatSession(
        id: sessionId,
        title: title,
        createdAt: _messages.first.timestamp,
        messages: List.from(_messages),
        summary: summary,
      ),
    );

    await _saveSessions();
  }

  // ── Session management ───────────────────────────────────────────

  /// Load a previous chat session.
  void loadSession(ChatSession session) {
    _messages
      ..clear()
      ..addAll(session.messages);
    _history.clear();
    _currentSessionId = session.id;

    // Rebuild history from messages for AI context
    for (final msg in _messages) {
      _history.add({
        'role': msg.isUser ? 'user' : 'model',
        'text': msg.text,
      });
    }
    notifyListeners();
  }

  /// Start a new chat, auto-saving the current one.
  Future<void> startNewChat() async {
    if (_messages.isNotEmpty) {
      await _autoSaveCurrentChat();
    }
    _messages.clear();
    _history.clear();
    _currentSessionId = null;
    notifyListeners();
  }

  /// Delete a saved session.
  Future<void> deleteSession(String sessionId) async {
    _savedSessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions();
    notifyListeners();
  }

  // ── Chat ─────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String text,
    required UserProfile profile,
    required String uid,
    List<MealEntry> todaysMeals = const [],
  }) async {
    _messages.add(ChatMessage(text: text, isUser: true));
    _isTyping = true;
    notifyListeners();

    try {
      // Fetch last 7 days of meals for context injection
      final today = DateTime.now();
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      final recentMeals = await _firestore.getMealsForDateRange(
        uid,
        sevenDaysAgo.toIso8601String().substring(0, 10),
        today.toIso8601String().substring(0, 10),
      );

      // If todaysMeals wasn't passed, extract from recent meals
      final todayStr = today.toIso8601String().substring(0, 10);
      final effectiveTodaysMeals = todaysMeals.isNotEmpty
          ? todaysMeals
          : recentMeals.where((m) => m.date == todayStr).toList();

      // Primary: OpenRouter (free tier)
      // Fallback: Gemini (if OpenRouter fails or is not configured)
      final response = await _openRouter.chat(
        userMessage: text,
        profile: profile,
        recentMeals: recentMeals,
        todaysMeals: effectiveTodaysMeals,
        history: _history,
        conversationMemory: conversationMemory,
        fallbackChat: () => _gemini.chat(
          userMessage: text,
          profile: profile,
          recentMeals: recentMeals,
          history: _history,
        ),
      );

      _messages.add(ChatMessage(text: response, isUser: false));
    } catch (e) {
      String errorMsg;
      final errorStr = e.toString();
      if (errorStr.contains('429') ||
          errorStr.contains('Too Many Requests') ||
          errorStr.contains('quota') ||
          errorStr.contains('Rate limit') ||
          errorStr.contains('RESOURCE_EXHAUSTED')) {
        errorMsg =
            'Rate limit reached — please wait about 60 seconds and try again. (Free tier has limited requests per minute.)';
      } else if (errorStr.contains('not configured') ||
          errorStr.contains('API key')) {
        errorMsg =
            'AI API key is not configured. Please add OPENROUTER_API_KEY or GEMINI_API_KEY to your .env file.';
      } else {
        errorMsg =
            'Sorry, I could not respond right now. Error: ${e.toString().split('\n').first}';
      }
      debugPrint('ChatbotProvider error: $e');
      _messages.add(ChatMessage(
        text: errorMsg,
        isUser: false,
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
      // Auto-save after each exchange
      _autoSaveCurrentChat();
    }
  }

  void clearHistory() {
    _messages.clear();
    _history.clear();
    _currentSessionId = null;
    notifyListeners();
  }
}
