import 'package:flutter/material.dart';
import '../../models/meal_entry.dart';
import '../../core/constants/app_colors.dart';

class MealIngredientTile extends StatefulWidget {
  final IngredientDetail ingredient;
  final VoidCallback onRemove;
  final ValueChanged<double> onWeightChanged;

  const MealIngredientTile({
    super.key,
    required this.ingredient,
    required this.onRemove,
    required this.onWeightChanged,
  });

  @override
  State<MealIngredientTile> createState() => _MealIngredientTileState();
}

class _MealIngredientTileState extends State<MealIngredientTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.ingredient.grams.round().toString());
  }

  @override
  void didUpdateWidget(MealIngredientTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if changed externally (e.g. +/- buttons)
    if (widget.ingredient.grams.round().toString() != _controller.text) {
      _controller.text = widget.ingredient.grams.round().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ingredient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _macroChip('🔥', '${widget.ingredient.calories} kcal',
                        AppColors.primary),
                    const SizedBox(width: 8),
                    _macroChip(
                        'P',
                        '${widget.ingredient.proteinG.toStringAsFixed(1)}g',
                        Colors.blue),
                    const SizedBox(width: 8),
                    _macroChip(
                        'C',
                        '${widget.ingredient.carbsG.toStringAsFixed(1)}g',
                        AppColors.accent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () {
                        if (widget.ingredient.grams > 10) {
                          widget.onWeightChanged(widget.ingredient.grams - 10);
                        } else if (widget.ingredient.grams > 1) {
                          widget.onWeightChanged(widget.ingredient.grams - 1);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    SizedBox(
                      width: 45,
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          suffixText: 'g',
                          suffixStyle: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey),
                        ),
                        onChanged: (val) {
                          final double? grams = double.tryParse(val);
                          if (grams != null && grams > 0) {
                            widget.onWeightChanged(grams);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () =>
                          widget.onWeightChanged(widget.ingredient.grams + 10),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: widget.onRemove,
                child: const Text(
                  'Remove',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: 10, color: color)),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
