import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  final UserProfile? initialProfile;

  const ProfileSetupScreen({super.key, this.initialProfile});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _calorieController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();

  String _sex = 'male';
  String _activityLevel = 'sedentary';
  String _goal = 'maintain';
  bool _useCustomCalories = false;
  bool _useCustomMacros = false;
  int _calculatedTarget = 2000;

  late AnimationController _stepAnimController;
  late Animation<double> _stepFade;

  bool get _isEditingExistingProfile => widget.initialProfile != null;

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stepFade = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    );
    _stepAnimController.forward();
    _hydrateFromInitialProfile();
  }

  void _hydrateFromInitialProfile() {
    final profile = widget.initialProfile;
    if (profile == null) return;

    _nameController.text = profile.name;
    _heightController.text = profile.heightCm.toStringAsFixed(1);
    _weightController.text = profile.weightKg.toStringAsFixed(1);
    _ageController.text = profile.age.toString();
    _sex = profile.sex;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
    _calculatedTarget = profile.calorieTarget;
    _useCustomCalories = profile.isCalorieTargetManual;
    _useCustomMacros = profile.isMacroTargetsManual;
    _calorieController.text = profile.calorieTarget.toString();

    final macros = profile.macroTargets ??
        MacroTargets.fromCalories(profile.calorieTarget);
    _proteinController.text = macros.proteinG.toString();
    _carbsController.text = macros.carbsG.toString();
    _fatsController.text = macros.fatsG.toString();
  }

  @override
  void dispose() {
    _stepAnimController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _calorieController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _stepAnimController.forward(from: 0);
    setState(() => _currentStep = step);
  }

  void _calculateTarget() {
    final height = double.tryParse(_heightController.text) ?? 170;
    final weight = double.tryParse(_weightController.text) ?? 70;
    final age = int.tryParse(_ageController.text) ?? 25;
    _calculatedTarget = CalorieCalculator.calculateTarget(
      weightKg: weight,
      heightCm: height,
      age: age,
      sex: _sex,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    _calorieController.text = _calculatedTarget.toString();
    _fillRecommendedMacros();
  }

  void _fillRecommendedMacros() {
    final recommended = MacroTargets.fromCalories(_calculatedTarget);
    if (!_useCustomMacros) {
      _proteinController.text = recommended.proteinG.toString();
      _carbsController.text = recommended.carbsG.toString();
      _fatsController.text = recommended.fatsG.toString();
    }
  }

  int _resolvedCalorieTarget() {
    if (!_useCustomCalories) return _calculatedTarget;
    return int.tryParse(_calorieController.text) ?? _calculatedTarget;
  }

  MacroTargets _resolvedMacroTargets(int calorieTarget) {
    if (!_useCustomMacros) {
      return MacroTargets.fromCalories(calorieTarget);
    }

    final recommended = MacroTargets.fromCalories(calorieTarget);
    final protein =
        int.tryParse(_proteinController.text) ?? recommended.proteinG;
    final carbs = int.tryParse(_carbsController.text) ?? recommended.carbsG;
    final fats = int.tryParse(_fatsController.text) ?? recommended.fatsG;
    return MacroTargets(proteinG: protein, carbsG: carbs, fatsG: fats);
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final uid = auth.userId;
    if (uid == null) return;

    final calorieTarget = _resolvedCalorieTarget();
    final macroTargets = _resolvedMacroTargets(calorieTarget);

    final existing = widget.initialProfile;
    final profile = UserProfile(
      uid: uid,
      name: _nameController.text.trim(),
      email: auth.userEmail ?? existing?.email ?? '',
      heightCm: double.tryParse(_heightController.text) ?? 170,
      weightKg: double.tryParse(_weightController.text) ?? 70,
      age: int.tryParse(_ageController.text) ?? 25,
      sex: _sex,
      activityLevel: _activityLevel,
      goal: _goal,
      calorieTarget: calorieTarget,
      isCalorieTargetManual: _useCustomCalories,
      isMacroTargetsManual: _useCustomMacros,
      macroTargets: macroTargets,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    if (_isEditingExistingProfile) {
      await profileProvider.updateProfile(uid, {
        'name': profile.name,
        'email': profile.email,
        'heightCm': profile.heightCm,
        'weightKg': profile.weightKg,
        'age': profile.age,
        'sex': profile.sex,
        'activityLevel': profile.activityLevel,
        'goal': profile.goal,
        'calorieTarget': profile.calorieTarget,
        'isCalorieTargetManual': profile.isCalorieTargetManual,
        'isMacroTargetsManual': profile.isMacroTargetsManual,
        'macroTargets': profile.macroTargets?.toMap(),
      });
      if (mounted) context.go('/profile');
      return;
    }

    await profileProvider.createProfile(profile);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            _isEditingExistingProfile ? 'Update Profile' : 'Profile Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Animated step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(
                  3,
                  (i) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: i <= _currentStep
                                ? AppColors.primaryGradient
                                : null,
                            color: i <= _currentStep
                                ? null
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),
            ),
          ),

          Expanded(
            child: FadeTransition(
              opacity: _stepFade,
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Basic Information',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tell us about yourself',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildField('Name', _nameController, TextInputType.text),
          const SizedBox(height: 16),
          _buildField('Height (cm)', _heightController, TextInputType.number),
          const SizedBox(height: 16),
          _buildField('Weight (kg)', _weightController, TextInputType.number),
          const SizedBox(height: 16),
          _buildField('Age', _ageController, TextInputType.number),
          const SizedBox(height: 20),
          Text('Sex', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSexButton('Male', 'male', Icons.male_rounded),
              const SizedBox(width: 12),
              _buildSexButton('Female', 'female', Icons.female_rounded),
            ],
          ),
          const SizedBox(height: 28),
          _buildNextButton(() {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter valid details')),
              );
              return;
            }
            _goToStep(1);
          }),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your Health Goal',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Select the goal that best describes you',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildGoalCard(
              'Lose Weight', 'lose_weight', Icons.trending_down_rounded),
          _buildGoalCard(
              'Maintain Weight', 'maintain', Icons.balance_rounded),
          _buildGoalCard(
              'Gain Muscle', 'gain_muscle', Icons.fitness_center_rounded),
          _buildGoalCard(
              'Eat Healthier', 'eat_healthier', Icons.eco_rounded),
          const SizedBox(height: 20),
          Text('Activity Level',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          RadioGroup<String>(
            groupValue: _activityLevel,
            onChanged: (v) {
              if (v != null) setState(() => _activityLevel = v);
            },
            child: Column(
              children: [
                'sedentary',
                'lightly_active',
                'moderately_active',
                'very_active'
              ].map((level) => _buildActivityOption(level)).toList(),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              TextButton(
                onPressed: () => _goToStep(0),
                child: const Text('Back'),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: _buildNextButton(() {
                  _calculateTarget();
                  _goToStep(2);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Daily Calorie Target',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Recommended',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
                const SizedBox(height: 8),
                Text('$_calculatedTarget',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                    )),
                const Text('kcal / day',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: AppColors.premiumCard(radius: 16),
            child: SwitchListTile(
              title: const Text('Set my own calorie goal',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text('Turn off automatic calorie targeting',
                  style: TextStyle(fontSize: 12)),
              value: _useCustomCalories,
              onChanged: (v) => setState(() {
                _useCustomCalories = v;
                if (v && _calorieController.text.isEmpty) {
                  _calorieController.text = _calculatedTarget.toString();
                }
              }),
              activeTrackColor: AppColors.primary,
            ),
          ),
          if (_useCustomCalories) ...[
            const SizedBox(height: 12),
            _buildField('Custom Target (kcal)', _calorieController,
                TextInputType.number),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: AppColors.premiumCard(radius: 16),
            child: SwitchListTile(
              title: const Text('Set my own macro breakdown',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text('Protein, carbs, and fats in grams',
                  style: TextStyle(fontSize: 12)),
              value: _useCustomMacros,
              onChanged: (v) {
                setState(() {
                  _useCustomMacros = v;
                  if (v) {
                    final target = _resolvedCalorieTarget();
                    final recommended = MacroTargets.fromCalories(target);
                    _proteinController.text = recommended.proteinG.toString();
                    _carbsController.text = recommended.carbsG.toString();
                    _fatsController.text = recommended.fatsG.toString();
                  }
                });
              },
              activeTrackColor: AppColors.primary,
            ),
          ),
          if (_useCustomMacros) ...[
            const SizedBox(height: 12),
            _buildField(
                'Protein Target (g)', _proteinController, TextInputType.number),
            const SizedBox(height: 12),
            _buildField(
                'Carbs Target (g)', _carbsController, TextInputType.number),
            const SizedBox(height: 12),
            _buildField(
                'Fats Target (g)', _fatsController, TextInputType.number),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppColors.premiumCard(radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recommended macro split',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    '${MacroTargets.fromCalories(_resolvedCalorieTarget()).proteinG}g protein • ${MacroTargets.fromCalories(_resolvedCalorieTarget()).carbsG}g carbs • ${MacroTargets.fromCalories(_resolvedCalorieTarget()).fatsG}g fats',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: () => _goToStep(1),
                child: const Text('Back'),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _finish,
                    child: Text(
                      _isEditingExistingProfile
                          ? 'Save Changes'
                          : 'Finish Setup',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        hintText: 'Enter $label',
      ),
    );
  }

  Widget _buildSexButton(String label, String value, IconData icon) {
    final selected = _sex == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sex = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? null
                : Border.all(color: AppColors.surfaceContainer),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(String title, String value, IconData icon) {
    final selected = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? null
              : Border.all(color: AppColors.surfaceContainer),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : AppColors.primary,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: selected ? Colors.white : AppColors.textPrimary,
                )),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityOption(String level) {
    final labels = {
      'sedentary': 'Sedentary (little exercise)',
      'lightly_active': 'Lightly Active (1-3 days/week)',
      'moderately_active': 'Moderately Active (3-5 days/week)',
      'very_active': 'Very Active (6-7 days/week)',
    };
    return RadioListTile<String>(
      title: Text(labels[level]!, style: const TextStyle(fontSize: 14)),
      value: level,
      dense: true,
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text('Next',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
