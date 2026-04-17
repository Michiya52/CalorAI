import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_profile.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<ProfileProvider, MealProvider>(
        builder: (context, profileProv, mealProv, _) {
          final profile = profileProv.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final consumed = mealProv.totalCaloriesToday;
          final target = profile.calorieTarget;
          final macros = mealProv.totalMacrosToday;
          final targetMacros =
              profile.macroTargets ?? MacroTargets.fromCalories(target);

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ─── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: _buildHeader(
                          context, profile, consumed, target, isDark),
                    ),
                  ),
                ),

                // ─── Calorie Ring ────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppColors.premiumCard(),
                        child: Center(
                          child:
                              CalorieRing(consumed: consumed, target: target),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ─── Macros ──────────────────────────────────
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Macronutrients',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          MacroBar(
                            label: 'Protein',
                            current: macros['proteinG']!,
                            target: targetMacros.proteinG.toDouble(),
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(height: 8),
                          MacroBar(
                            label: 'Carbs',
                            current: macros['carbsG']!,
                            target: targetMacros.carbsG.toDouble(),
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 8),
                          MacroBar(
                            label: 'Fats',
                            current: macros['fatsG']!,
                            target: targetMacros.fatsG.toDouble(),
                            color: AppColors.aura,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ─── Today's Meals ───────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Today\'s Meals',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                if (mealProv.todaysMeals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: AppColors.premiumCard(),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(Icons.restaurant_outlined,
                                  size: 32,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No meals logged today',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the camera button to get started!',
                              style: TextStyle(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
                      itemCount: mealProv.todaysMeals.length,
                      itemBuilder: (context, index) {
                        final meal = mealProv.todaysMeals[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: MealCard(
                            meal: meal,
                            onDelete: () async {
                              final uid = context.read<AuthProvider>().userId;
                              if (uid != null) {
                                await context
                                    .read<MealProvider>()
                                    .deleteMeal(uid, meal.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profile, int consumed,
      int target, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${profile.name} 👋',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s your daily summary',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Refresh button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: _loadData,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
