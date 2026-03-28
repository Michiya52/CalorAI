import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/calorie_ring.dart';
import '../../widgets/macro_bar.dart';
import '../../widgets/meal_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final uid = context.read<AuthProvider>().userId;
    if (uid == null) return;

    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profile == null) {
      await profileProvider.loadProfile(uid);
    }

    if (mounted) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await context.read<MealProvider>().loadMealsForDate(uid, today);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CalorAI',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer2<ProfileProvider, MealProvider>(
        builder: (context, profileProv, mealProv, _) {
          final profile = profileProv.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final consumed = mealProv.totalCaloriesToday;
          final target = profile.calorieTarget;
          final macros = mealProv.totalMacrosToday;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Hello, ${profile.name} 👋',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s your daily summary',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Calorie Ring
                  Center(
                    child: CalorieRing(consumed: consumed, target: target),
                  ),
                  const SizedBox(height: 24),

                  // Macro Bars
                  Text(
                    'Macronutrients',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MacroBar(
                    label: 'Protein',
                    current: macros['proteinG']!,
                    target: profile.macroTargets?.proteinG.toDouble() ?? 50.0,
                    color: const Color(0xFF42A5F5),
                  ),
                  const SizedBox(height: 8),
                  MacroBar(
                    label: 'Carbs',
                    current: macros['carbsG']!,
                    target: profile.macroTargets?.carbsG.toDouble() ?? 250.0,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 8),
                  MacroBar(
                    label: 'Fats',
                    current: macros['fatsG']!,
                    target: profile.macroTargets?.fatsG.toDouble() ?? 65.0,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 24),

                  // Today's Meals
                  Text(
                    'Today\'s Meals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (mealProv.todaysMeals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.restaurant_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No meals logged today',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the camera button to get started!',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...mealProv.todaysMeals.map(
                      (meal) => Padding(
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
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Meal'),
                                content: Text('Remove ${meal.foodNameEn}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            final uid = context.read<AuthProvider>().userId;
                            if (uid != null) {
                              await context.read<MealProvider>().deleteMeal(
                                uid,
                                meal.id,
                              );
                            }
                          },
                          child: MealCard(meal: meal),
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
