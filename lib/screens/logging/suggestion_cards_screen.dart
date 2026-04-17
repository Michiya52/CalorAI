import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_suggestion.dart';
import '../../services/firestore_service.dart';
import '../../services/myfcd_service.dart';
import '../../widgets/suggestion_card.dart';

class SuggestionCardsScreen extends StatelessWidget {
  final List<FoodSuggestion> suggestions;
  final MyFCDService _referenceService = MyFCDService(FirestoreService());

  SuggestionCardsScreen({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Your Meal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'AI best guesses: ${suggestions.length} possible matches',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SuggestionCard(
                    suggestion: suggestions[index],
                    onTap: () async {
                      final enrichedSuggestion =
                          await _referenceService.crossReference(
                        suggestions[index],
                      );
                      if (!context.mounted) return;
                      context.push(
                        '/log/portion',
                        extra: enrichedSuggestion,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: () => context.push('/log/search'),
                icon: const Icon(Icons.search),
                label: const Text('None of these — search manually'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
