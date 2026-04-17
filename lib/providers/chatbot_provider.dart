import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final FirestoreService _firestore = FirestoreService();

  final List<ChatMessage> _messages = [];
  final List<dynamic> _history = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  Future<void> sendMessage({
    required String text,
    required UserProfile profile,
    required String uid,
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

      final response = await _gemini.chat(
        userMessage: text,
        profile: profile,
        recentMeals: recentMeals,
        history: _history,
      );

      _messages.add(ChatMessage(text: response, isUser: false));
    } catch (e) {
      String errorMsg;
      final errorStr = e.toString();
      if (errorStr.contains('429') || errorStr.contains('Too Many Requests') || errorStr.contains('quota') || errorStr.contains('RESOURCE_EXHAUSTED')) {
        errorMsg = 'Rate limit reached — please wait about 60 seconds and try again. (Free Gemini API tier has limited requests per minute.)';
      } else if (errorStr.contains('not configured') || errorStr.contains('API key')) {
        errorMsg = 'Gemini API key is not configured. Please check your .env file.';
      } else {
        errorMsg = 'Sorry, I could not respond right now. Error: ${e.toString().split('\n').first}';
      }
      debugPrint('ChatbotProvider error: $e');
      _messages.add(ChatMessage(
        text: errorMsg,
        isUser: false,
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _messages.clear();
    _history.clear();
    notifyListeners();
  }
}
