import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/calorie_ring.dart';
import 'package:flutter/services.dart';
import '../../widgets/macro_bar.dart';
import '../../widgets/meal_card.dart';
import '../../services/notification_service.dart';

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

  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      HapticFeedback.lightImpact();
    }
    final uid = context.read<AuthProvider>().userId;
    if (uid == null) return;

    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profile == null ||
        profileProvider.profile!.uid != uid) {
      await profileProvider.loadProfile(uid);
    }

    if (mounted) {
      if (profileProvider.profile == null && profileProvider.error == null) {
        context.go('/setup');
        return;
      }
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final mealProvider = context.read<MealProvider>();
      await mealProvider.loadMealsForDate(uid, today);

      final profile = profileProvider.profile;
      if (profile != null) {
        bool ateDinner = mealProvider.todaysMeals.any((m) =>
            m.timestamp.hour >= 19 ||
            m.foodNameEn.toLowerCase().contains('dinner'));

        NotificationService().scheduleDailySummary(
            mealProvider.totalCaloriesToday, profile.calorieTarget, ateDinner);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Consumer2<ProfileProvider, MealProvider>(
        builder: (context, profileProv, mealProv, _) {
          final profile = profileProv.profile;
          if (profile == null) {
            if (profileProv.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Unable to connect',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          profileProv.error ??
                              'Please check your connection and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _loadData(isRefresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (profileProv.hasLoaded && !profileProv.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  context.go('/setup');
                }
              });
            }
            return const Center(child: CircularProgressIndicator());
          }

          final consumed = mealProv.totalCaloriesToday;
          final target = profile.calorieTarget;
          final macros = mealProv.totalMacrosToday;
          final targetMacros =
              profile.macroTargets ?? MacroTargets.fromCalories(target);

          return RefreshIndicator(
            onRefresh: () => _loadData(isRefresh: true),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
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
                        decoration: AppColors.premiumCard(context),
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
                            color: const Color(0xFF8B5CF6), // Distinct Purple
                          ),
                          const SizedBox(height: 8),
                          MacroBar(
                            label: 'Carbs',
                            current: macros['carbsG']!,
                            target: targetMacros.carbsG.toDouble(),
                            color: AppColors.accent, // Orange
                          ),
                          const SizedBox(height: 8),
                          MacroBar(
                            label: 'Fats',
                            current: macros['fatsG']!,
                            target: targetMacros.fatsG.toDouble(),
                            color: AppColors.aura, // Blue
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
                        decoration: AppColors.premiumCard(context),
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
                                color: AppColors.textSecondary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the camera button to get started!',
                              style: TextStyle(
                                color: AppColors.textSecondary(context)
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
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.white),
                            ),
                            // confirmDismiss (not onDismissed) so a failed
                            // delete snaps the row back instead of leaving a
                            // dismissed widget whose meal is still in the list.
                            confirmDismiss: (_) async {
                              final uid = context.read<AuthProvider>().userId;
                              if (uid == null) return false;
                              try {
                                await context
                                    .read<MealProvider>()
                                    .deleteMeal(uid, meal.id);
                                HapticFeedback.lightImpact();
                                return true;
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Could not delete meal.')),
                                  );
                                }
                                return false;
                              }
                            },
                            child: MealCard(
                              meal: meal,
                              onTap: () =>
                                  context.push('/meal-detail', extra: meal),
                            ),
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

  Widget _buildHeader(BuildContext context, UserProfile profile, int consumed,
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
                        color: AppColors.textSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Search button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.search_rounded,
                            size: 20, color: AppColors.textSecondary(context)),
                        onPressed: () => context.push('/log/search'),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Refresh button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh_rounded,
                            size: 20, color: AppColors.textSecondary(context)),
                        onPressed: _loadData,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
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
