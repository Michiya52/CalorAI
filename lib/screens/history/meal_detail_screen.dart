import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/meal_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';

class MealDetailScreen extends StatefulWidget {
  final MealEntry meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final _customGramsController = TextEditingController();
  late String _selectedPortion;
  bool _isSaving = false;
  late double _displayGrams;
  late int _displayCalories;
  late double _displayProtein;
  late double _displayCarbs;
  late double _displayFats;

  @override
  void initState() {
    super.initState();
    _selectedPortion = widget.meal.portionLabel;
    _customGramsController.text = widget.meal.portionGrams.toStringAsFixed(0);
    _updateNutrition();
  }

  @override
  void dispose() {
    _customGramsController.dispose();
    super.dispose();
  }

  double _targetGrams() {
    final base =
        widget.meal.portionGrams <= 0 ? 100.0 : widget.meal.portionGrams;
    return switch (_selectedPortion) {
      'Small' => base * 0.7,
      'Large' => base * 1.4,
      'Custom' => double.tryParse(_customGramsController.text) ?? base,
      _ => base,
    };
  }

  void _updateNutrition() {
    final baseGrams =
        widget.meal.portionGrams <= 0 ? 100.0 : widget.meal.portionGrams;
    final targetGrams = _targetGrams();
    final factor = targetGrams / baseGrams;

    _displayGrams = targetGrams;
    _displayCalories = (widget.meal.calories * factor).round();
    _displayProtein = widget.meal.proteinG * factor;
    _displayCarbs = widget.meal.carbsG * factor;
    _displayFats = widget.meal.fatsG * factor;
    if (mounted) setState(() {});
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final uid = context.read<AuthProvider>().userId;
    if (uid == null) return;

    setState(() => _isSaving = true);
    final updatedEntry = widget.meal.copyWith(
      portionLabel: _selectedPortion,
      portionGrams: _displayGrams,
      calories: _displayCalories,
      proteinG: _displayProtein,
      carbsG: _displayCarbs,
      fatsG: _displayFats,
    );

    try {
      await context.read<MealProvider>().updateMeal(uid, widget.meal.id, {
        'portionLabel': updatedEntry.portionLabel,
        'portionGrams': updatedEntry.portionGrams,
        'calories': updatedEntry.calories,
        'proteinG': updatedEntry.proteinG,
        'carbsG': updatedEntry.carbsG,
        'fatsG': updatedEntry.fatsG,
        'timestamp': updatedEntry.timestamp,
        'date': updatedEntry.date,
      });
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save changes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meal Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.meal.foodNameEn,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 4),
                  Text(widget.meal.foodNameMy,
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(widget.meal.source),
                      _pill(widget.meal.portionLabel),
                      _pill('${_displayGrams.round()} g'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Change portion size to adjust calories and macros.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Portion', style: Theme.of(context).textTheme.titleMedium),
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
              setState(() {
                _selectedPortion = selected.first;
                _updateNutrition();
              });
            },
          ),
          if (_selectedPortion == 'Custom') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customGramsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Custom grams',
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
          const SizedBox(height: 16),
          Text('Macro Breakdown',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _macroRow('Calories', '$_displayCalories kcal'),
                  _macroRow(
                      'Protein', '${_displayProtein.toStringAsFixed(1)} g'),
                  _macroRow('Carbs', '${_displayCarbs.toStringAsFixed(1)} g'),
                  _macroRow('Fats', '${_displayFats.toStringAsFixed(1)} g'),
                ],
              ),
            ),
          ),
          if (widget.meal.ingredients != null &&
              widget.meal.ingredients!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Recipe Ingredients',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.meal.ingredients!.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ing = widget.meal.ingredients![index];
                  // Scale the ingredient based on the overall factor
                  final baseGrams = widget.meal.portionGrams <= 0
                      ? 1.0
                      : widget.meal.portionGrams;
                  final factor = _displayGrams / baseGrams;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(ing.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    trailing: Text('${(ing.grams * factor).round()}g',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
