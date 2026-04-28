import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/food_suggestion.dart';
import '../../services/firestore_service.dart';
import '../../services/myfcd_service.dart';
import '../../widgets/suggestion_card.dart';

class SuggestionCardsScreen extends StatefulWidget {
  final List<FoodSuggestion> suggestions;
  const SuggestionCardsScreen({super.key, required this.suggestions});

  @override
  State<SuggestionCardsScreen> createState() => _SuggestionCardsScreenState();
}

class _SuggestionCardsScreenState extends State<SuggestionCardsScreen> {
  final MyFCDService _referenceService = MyFCDService(FirestoreService());
  int? _loadingIndex;

  Future<void> _onSuggestionTap(int index) async {
    if (_loadingIndex != null) return; // prevent double taps

    setState(() => _loadingIndex = index);
    try {
      final enrichedSuggestion = await _referenceService.crossReference(
        widget.suggestions[index],
      );
      if (!mounted) return;
      context.push('/log/portion', extra: enrichedSuggestion);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load food data: ${e.toString().split('\n').first}'),
          action: SnackBarAction(
            label: 'Try again',
            onPressed: () => _onSuggestionTap(index),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingIndex = null);
    }
  }

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
              'AI best guesses: ${widget.suggestions.length} possible matches',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    children: [
                      SuggestionCard(
                        suggestion: widget.suggestions[index],
                        onTap: () => _onSuggestionTap(index),
                      ),
                      if (_loadingIndex == index)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
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
