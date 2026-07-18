import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../models/meal_entry.dart';
import '../../widgets/meal_card.dart';
import 'package:flutter/services.dart';

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

    HapticFeedback.lightImpact();

    // Refresh today's meals globally so dashboard updates too
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    context.read<MealProvider>().loadMealsForDate(uid, todayStr);

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
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Meal History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded,
                  size: 18, color: AppColors.textSecondary(context)),
              onPressed: _loadHistory,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMeals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: _groupByDate().entries.map((entry) {
                      final totalCals = entry.value
                          .fold<int>(0, (sum, m) => sum + m.calories);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$totalCals kcal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
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
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete_rounded,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (_) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Meal'),
                                        content:
                                            Text('Remove ${meal.foodNameEn}?'),
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
                                                    color: AppColors.error)),
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
                                      _allMeals
                                          .removeWhere((m) => m.id == meal.id);
                                      setState(() {});
                                    }
                                  },
                                  child: MealCard(
                                    meal: meal,
                                    onTap: () async {
                                      final changed = await context.push<bool>(
                                        '/meal-detail',
                                        extra: meal,
                                      );
                                      if (changed == true && mounted) {
                                        await _loadHistory();
                                      }
                                    },
                                  ),
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.history_rounded,
                size: 36, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            'No meals logged yet',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your meal history will appear here',
            style: TextStyle(
              color: AppColors.textSecondary(context).withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
