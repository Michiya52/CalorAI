import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/portion_scaler.dart';
import '../../models/food_suggestion.dart';
import '../../models/meal_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/density_badge.dart';

class PortionSelectionScreen extends StatefulWidget {
  final FoodSuggestion suggestion;
  const PortionSelectionScreen({super.key, required this.suggestion});

  @override
  State<PortionSelectionScreen> createState() => _PortionSelectionScreenState();
}

class _PortionSelectionScreenState extends State<PortionSelectionScreen> {
  String _selectedPortion = 'Medium';
  final _customGramsController = TextEditingController();
  bool _isSubmitting = false;
  late int _displayCalories;
  late double _displayProtein;
  late double _displayCarbs;
  late double _displayFats;
  late double _displaySodium;
  late double _displaySugar;
  late double _displayGrams;

  @override
  void initState() {
    super.initState();

    // For all AI-aided suggestions (photo log), default to 'Custom'
    // using the AI's estimated portion weight.
    if (widget.suggestion.confidence.isNotEmpty) {
      _selectedPortion = 'Custom';
      _customGramsController.text =
          widget.suggestion.estimatedPortionGrams.round().toString();
    }

    _updateNutrition();
  }

  @override
  void dispose() {
    _customGramsController.dispose();
    super.dispose();
  }

  void _updateNutrition() {
    final suggestion = widget.suggestion;
    if (suggestion.myfcdMatch != null) {
      final scaled = PortionScaler.scale(
        food: suggestion.myfcdMatch!,
        portionLabel: _selectedPortion,
        customGrams: double.tryParse(_customGramsController.text),
      );
      _displayCalories = scaled['calories'] as int;
      _displayProtein = scaled['proteinG'] as double;
      _displayCarbs = scaled['carbsG'] as double;
      _displayFats = scaled['fatsG'] as double;
      _displaySodium = scaled['sodiumG'] as double? ?? 0.0;
      _displaySugar = scaled['sugarG'] as double? ?? 0.0;
      _displayGrams = scaled['portionGrams'] as double;
    } else {
      // AI estimate - use estimated portion grams directly
      final estimatedBase = suggestion.estimatedPortionGrams <= 0
          ? 1.0
          : suggestion.estimatedPortionGrams;
      final portionMultiplier = switch (_selectedPortion) {
        'Small' => 0.7,
        'Large' => 1.4,
        'Custom' =>
          (double.tryParse(_customGramsController.text) ?? estimatedBase) /
              estimatedBase,
        _ => 1.0,
      };
      _displayGrams = estimatedBase * portionMultiplier;
      _displayCalories = suggestion.resolvedCalories != null
          ? (suggestion.resolvedCalories! * portionMultiplier).round()
          : (_displayGrams * 1.5).round(); // rough estimate
      _displayProtein = (suggestion.resolvedProteinG ?? _displayGrams * 0.1) *
          portionMultiplier;
      _displayCarbs = (suggestion.resolvedCarbsG ?? _displayGrams * 0.5) *
          portionMultiplier;
      _displayFats = (suggestion.resolvedFatsG ?? _displayGrams * 0.15) *
          portionMultiplier;
      _displaySodium = 0.0; // AI rarely estimates sodium accurately yet
      _displaySugar = 0.0;
    }
    setState(() {});
  }

  Future<void> _confirmAndLog() async {
    if (_isSubmitting) return;

    final uid = context.read<AuthProvider>().userId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session expired. Please sign in again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final entry = MealEntry(
      id: const Uuid().v4(),
      userId: uid,
      date: now.toIso8601String().substring(0, 10),
      timestamp: now,
      foodNameEn: widget.suggestion.dishNameEn,
      foodNameMy: widget.suggestion.dishNameMy,
      myfcdId: widget.suggestion.myfcdMatch?.id,
      source: widget.suggestion.source,
      calories: _displayCalories,
      proteinG: _displayProtein,
      carbsG: _displayCarbs,
      fatsG: _displayFats,
      sodiumG: _displaySodium,
      sugarG: _displaySugar,
      portionLabel: _selectedPortion,
      portionGrams: _displayGrams,
      aiConfidence: widget.suggestion.confidence,
      imageDeleted: true,
    );

    try {
      await context.read<MealProvider>().addMeal(entry);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save meal: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Portion Size'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food name
            Text(
              widget.suggestion.dishNameEn,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              widget.suggestion.dishNameMy,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              widget.suggestion.confidence.isNotEmpty
                  ? 'Estimated portion: ${widget.suggestion.estimatedPortionGrams.toStringAsFixed(0)}g • AI confidence: ${widget.suggestion.effectiveConfidencePercent}%'
                  : 'Estimated portion: ${widget.suggestion.estimatedPortionGrams.toStringAsFixed(0)}g',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.suggestion.source == 'MyFCD'
                    ? AppColors.myfcdBadge
                    : AppColors.aiBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.suggestion.source,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.suggestion.myfcdMatch?.ingredients.isNotEmpty ==
                true) ...[
              Text('Ingredients',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                widget.suggestion.myfcdMatch!.ingredients.join(', '),
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 24),
            ] else if (widget.suggestion.mainIngredients.isNotEmpty &&
                !['General', 'Other']
                    .contains(widget.suggestion.mainIngredients.first)) ...[
              Text('Main Ingredients',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                widget.suggestion.mainIngredients.join(', '),
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const SizedBox(height: 8),
            ],

            // Portion selector
            Text('Select Portion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Small', label: Text('S')),
                ButtonSegment(value: 'Medium', label: Text('M')),
                ButtonSegment(value: 'Large', label: Text('L')),
                ButtonSegment(value: 'Custom', label: Text('Custom')),
              ],
              selected: {_selectedPortion},
              onSelectionChanged: (selected) {
                _selectedPortion = selected.first;
                _updateNutrition();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return AppColors.surface;
                }),
              ),
            ),

            if (_selectedPortion == 'Custom') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customGramsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'GRAMS',
                  hintText: 'Enter weight in grams',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => _updateNutrition(),
              ),
            ],
            const SizedBox(height: 24),

            // Nutrition display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_displayGrams.round()}g',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                      if (widget.suggestion.myfcdMatch != null)
                        DensityBadge(
                            density:
                                widget.suggestion.myfcdMatch!.caloriesPer100g /
                                    100.0),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('$_displayCalories',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              )),
                  const Text('kcal',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),

                  // Macro Distribution Bar
                  _buildMacroBar(),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _macroColumn(
                          'Protein',
                          '${_displayProtein.toStringAsFixed(1)}g',
                          const Color(0xFF42A5F5)),
                      _macroColumn(
                          'Carbs',
                          '${_displayCarbs.toStringAsFixed(1)}g',
                          AppColors.accent),
                      _macroColumn(
                          'Fats',
                          '${_displayFats.toStringAsFixed(1)}g',
                          AppColors.warning),
                    ],
                  ),

                  const Divider(height: 40),

                  // Detailed Nutrients Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _detailTile(
                          'Sodium',
                          '${_displaySodium.toStringAsFixed(0)}mg',
                          Icons.waves_rounded),
                      _detailTile(
                          'Sugar',
                          '${_displaySugar.toStringAsFixed(1)}g',
                          Icons.bakery_dining_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmAndLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm & Log',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMacroBar() {
    final proteinCals = _displayProtein * 4.0;
    final carbsCals = _displayCarbs * 4.0;
    final fatsCals = _displayFats * 9.0;

    final totalCals = proteinCals + carbsCals + fatsCals;
    if (totalCals == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart_outline_rounded,
                size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('MACRO BREAKDOWN',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (proteinCals * 10).round(),
                  child: Container(color: const Color(0xFF42A5F5)),
                ),
                Expanded(
                  flex: (carbsCals * 10).round(),
                  child: Container(color: AppColors.accent),
                ),
                Expanded(
                  flex: (fatsCals * 10).round(),
                  child: Container(color: AppColors.warning),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.withValues(alpha: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
