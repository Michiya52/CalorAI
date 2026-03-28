import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../models/meal_entry.dart';
import '../../widgets/meal_card.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  List<MealEntry> _allMeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final uid = context.read<AuthProvider>().userId;
    if (uid == null) return;

    setState(() => _isLoading = true);
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    _allMeals = await context.read<MealProvider>().getMealsForDateRange(
          uid,
          thirtyDaysAgo.toIso8601String().substring(0, 10),
          today.toIso8601String().substring(0, 10),
        );
    if (mounted) setState(() => _isLoading = false);
  }

  Map<String, List<MealEntry>> _groupByDate() {
    final grouped = <String, List<MealEntry>>{};
    for (final meal in _allMeals) {
      grouped.putIfAbsent(meal.date, () => []).add(meal);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meal History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMeals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text('No meals logged yet',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _groupByDate().entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              entry.key,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                          ...entry.value.map((meal) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Dismissible(
                                  key: Key(meal.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (_) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Meal'),
                                        content: Text(
                                            'Remove ${meal.foodNameEn}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (_) async {
                                    final uid =
                                        context.read<AuthProvider>().userId;
                                    if (uid != null) {
                                      await context
                                          .read<MealProvider>()
                                          .deleteMeal(uid, meal.id);
                                      _allMeals.removeWhere(
                                          (m) => m.id == meal.id);
                                      setState(() {});
                                    }
                                  },
                                  child: MealCard(meal: meal),
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
