import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/weight_log.dart';
import '../../widgets/weight_chart.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isEditing = false;
  late Future<List<WeightLog>> _weightLogsFuture;

  @override
  void initState() {
    super.initState();
    _loadWeightLogs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
        final uid = context.read<AuthProvider>().userId;
        final profileProv = context.read<ProfileProvider>();
        if (profileProv.profile == null && uid != null) {
          profileProv.loadProfile(uid).then((_) {
            if (mounted) _loadProfile();
          });
        }
      }
    });
  }

  Future<void> _refreshProfile() async {
    HapticFeedback.lightImpact();
    final uid = context.read<AuthProvider>().userId;
    if (uid != null) {
      final profileProv = context.read<ProfileProvider>();
      final mealProv = context.read<MealProvider>();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await Future.wait([
        profileProv.loadProfile(uid),
        mealProv.loadMealsForDate(uid, today),
      ]);
      if (mounted) _loadProfile();
      setState(() {
        _loadWeightLogs();
      });
    }
  }

  void _loadWeightLogs() {
    final uid = context.read<AuthProvider>().userId;
    if (uid != null) {
      _weightLogsFuture = FirestoreService().getWeightLogs(uid);
    } else {
      _weightLogsFuture = Future.value([]);
    }
  }

  void _loadProfile() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null) {
      _nameController.text = profile.name;
      _heightController.text = profile.heightCm.toString();
      _weightController.text = profile.weightKg.toString();
      _ageController.text = profile.age.toString();
    }
  }

  Future<void> _saveChanges() async {
    final uid = context.read<AuthProvider>().userId;
    final profileProv = context.read<ProfileProvider>();
    final profile = profileProv.profile;
    if (uid == null || profile == null) return;

    final ht = double.tryParse(_heightController.text);
    final wt = double.tryParse(_weightController.text);
    final age = int.tryParse(_ageController.text);

    if (_nameController.text.trim().isEmpty ||
        ht == null ||
        ht <= 0 ||
        wt == null ||
        wt <= 0 ||
        age == null ||
        age <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter valid numeric details'),
              backgroundColor: AppColors.error),
        );
      }
      return;
    }

    await profileProv.updateProfile(uid, {
      'name': _nameController.text.trim(),
      'heightCm': ht,
      'weightKg': wt,
      'age': age,
    });

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _recalculateTarget() async {
    final provider = context.read<ProfileProvider>();
    final profile = provider.profile;
    if (profile == null) return;

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recalculate target'),
        content: const Text(
          'Do you want to re-enter your details first (including activity level and goal)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('edit'),
            child: const Text('Re-enter details'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop('recalculate'),
            child: const Text('Use current details'),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == 'cancel') return;
    if (action == 'edit') {
      await context.push('/setup', extra: profile);
      if (mounted) {
        _loadProfile();
        setState(() {});
      }
      return;
    }

    final previousTarget = await provider.recalculateTarget();

    if (!mounted || previousTarget == null) return;
    final newTarget = provider.profile?.calorieTarget ?? previousTarget;
    _loadProfile();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Target updated: $previousTarget -> $newTarget kcal/day'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _logWeight() async {
    final uid = context.read<AuthProvider>().userId;
    if (uid == null) return;

    final controller = TextEditingController();
    final weightStr = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Current Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'e.g. 70.5',
            suffixText: 'kg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (weightStr == null || weightStr.isEmpty) return;
    final weight = double.tryParse(weightStr);
    if (weight == null || weight <= 0 || weight > 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    try {
      final log = WeightLog(
        id: '',
        date: DateTime.now().toIso8601String().substring(0, 10),
        weightKg: weight,
      );
      await FirestoreService().saveWeightLog(uid, log);

      HapticFeedback.lightImpact();
      setState(() {
        _loadWeightLogs();
      });

      // Also update profile weight
      if (!mounted) return;
      await context.read<ProfileProvider>().updateProfile(uid, {'weightKg': weight});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight logged successfully!'), backgroundColor: AppColors.success),
        );
        _loadProfile();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log weight'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild on theme change
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.edit_rounded,
                    size: 18, color: AppColors.textSecondary),
                onPressed: () {
                  _loadProfile();
                  setState(() => _isEditing = true);
                },
                padding: EdgeInsets.zero,
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text('Save',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProv, _) {
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
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          final uid = context.read<AuthProvider>().userId;
                          if (uid != null) {
                            context
                                .read<ProfileProvider>()
                                .loadProfile(uid)
                                .then((_) {
                              if (mounted) _loadProfile();
                            });
                          }
                        },
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
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar with gradient ring
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                profile.name.isNotEmpty
                                    ? profile.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(profile.email,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ),
                const SizedBox(height: 24),

                // Editable fields card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppColors.premiumCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Info',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      _buildProfileField('Name', _nameController, _isEditing),
                      _buildProfileField(
                          'Height (cm)', _heightController, _isEditing,
                          keyboardType: TextInputType.number),
                      _buildProfileField(
                          'Weight (kg)', _weightController, _isEditing,
                          keyboardType: TextInputType.number),
                      _buildProfileField('Age', _ageController, _isEditing,
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Read-only info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppColors.premiumCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Goals & Targets',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                          'Sex', profile.sex == 'male' ? 'Male' : 'Female'),
                      _buildInfoRow('Activity',
                          profile.activityLevel.replaceAll('_', ' ')),
                      _buildInfoRow('Goal', profile.goal.replaceAll('_', ' ')),
                      _buildInfoRow(
                          'Daily Target', '${profile.calorieTarget} kcal'),
                      _buildInfoRow(
                        'Calorie Mode',
                        profile.isCalorieTargetManual ? 'Manual' : 'Auto',
                      ),
                      if (profile.macroTargets != null) ...[
                        _buildInfoRow(
                            'Protein', '${profile.macroTargets!.proteinG}g'),
                        _buildInfoRow(
                            'Carbs', '${profile.macroTargets!.carbsG}g'),
                        _buildInfoRow(
                            'Fats', '${profile.macroTargets!.fatsG}g'),
                      ],
                      _buildInfoRow(
                        'Macro Mode',
                        profile.isMacroTargetsManual ? 'Manual' : 'Auto',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Weight Progress Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppColors.premiumCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight Progress',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      FutureBuilder<List<WeightLog>>(
                        future: _weightLogsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final logs = snapshot.data ?? [];
                          return WeightChart(logs: logs);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Theme card
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppColors.premiumCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appearance',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('System'),
                                icon: Icon(Icons.brightness_auto, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Light'),
                                icon: Icon(Icons.light_mode, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                                icon: Icon(Icons.dark_mode, size: 18),
                              ),
                            ],
                            selected: {themeProvider.themeMode},
                            onSelectionChanged: (selection) {
                              themeProvider.setThemeMode(selection.first);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Action buttons
                OutlinedButton.icon(
                  onPressed: () => context.push('/setup', extra: profile),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Set My Own Goals'),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _recalculateTarget,
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Recalculate Target'),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _logWeight,
                  icon: const Icon(Icons.scale_rounded),
                  label: const Text('Log Current Weight'),
                ),
                const SizedBox(height: 24),

                // Footer
                Center(
                  child: Text(
                    'Nutritional data powered by MyFCD 2026',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Logout
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      context.read<ProfileProvider>().clear();
                      context.read<MealProvider>().clear();
                      context.read<ChatbotProvider>().clear();

                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    label: const Text('Log Out',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _buildProfileField(
      String label, TextEditingController controller, bool editable,
      {TextInputType? keyboardType, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: editable,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          filled: true,
          fillColor:
              editable ? AppColors.surfaceContainer : AppColors.background,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
