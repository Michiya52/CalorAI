import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _calorieController = TextEditingController();

  String _sex = 'male';
  String _activityLevel = 'sedentary';
  String _goal = 'maintain';
  bool _useRecommended = true;
  int _calculatedTarget = 2000;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _calorieController.dispose();
    super.dispose();
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
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final uid = auth.userId;
    if (uid == null) return;

    final profile = UserProfile(
      uid: uid,
      name: _nameController.text.trim(),
      email: auth.userEmail ?? '',
      heightCm: double.tryParse(_heightController.text) ?? 170,
      weightKg: double.tryParse(_weightController.text) ?? 70,
      age: int.tryParse(_ageController.text) ?? 25,
      sex: _sex,
      activityLevel: _activityLevel,
      goal: _goal,
      calorieTarget: _useRecommended
          ? _calculatedTarget
          : (int.tryParse(_calorieController.text) ?? _calculatedTarget),
      isCalorieTargetManual: !_useRecommended,
      createdAt: DateTime.now(),
    );

    await profileProvider.createProfile(profile);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),

          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildField('Name', _nameController, TextInputType.text),
          const SizedBox(height: 16),
          _buildField('Height (cm)', _heightController, TextInputType.number),
          const SizedBox(height: 16),
          _buildField('Weight (kg)', _weightController, TextInputType.number),
          const SizedBox(height: 16),
          _buildField('Age', _ageController, TextInputType.number),
          const SizedBox(height: 16),
          Text('Sex', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSexButton('Male', 'male'),
              const SizedBox(width: 12),
              _buildSexButton('Female', 'female'),
            ],
          ),
          const SizedBox(height: 24),
          _buildNextButton(() {
            if (_nameController.text.isEmpty ||
                _heightController.text.isEmpty ||
                _weightController.text.isEmpty ||
                _ageController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in all fields')),
              );
              return;
            }
            setState(() => _currentStep = 1);
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Select the goal that best describes you',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildGoalCard('Lose Weight', 'lose_weight', Icons.trending_down),
          _buildGoalCard('Maintain Weight', 'maintain', Icons.balance),
          _buildGoalCard('Gain Muscle', 'gain_muscle', Icons.fitness_center),
          _buildGoalCard('Eat Healthier', 'eat_healthier', Icons.eco),
          const SizedBox(height: 16),
          Text('Activity Level',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...['sedentary', 'lightly_active', 'moderately_active', 'very_active']
              .map((level) => _buildActivityOption(level)),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Back'),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: _buildNextButton(() {
                  _calculateTarget();
                  setState(() => _currentStep = 2);
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Recommended',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('$_calculatedTarget',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        )),
                const Text('kcal / day'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Use recommended target'),
            value: _useRecommended,
            onChanged: (v) => setState(() => _useRecommended = v),
            activeColor: AppColors.primary,
          ),
          if (!_useRecommended) ...[
            const SizedBox(height: 8),
            _buildField(
                'Custom Target (kcal)', _calorieController, TextInputType.number),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: const Text('Back'),
              ),
              const Spacer(),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Finish Setup',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSexButton(String label, String value) {
    final selected = _sex == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sex = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade300),
          ),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ))),
        ),
      ),
    );
  }

  Widget _buildGoalCard(String title, String value, IconData icon) {
    final selected = _goal == value;
    return GestureDetector(
      onTap: () => setState(() => _goal = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color:
                      selected ? AppColors.primaryDark : AppColors.textPrimary,
                )),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
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
      groupValue: _activityLevel,
      onChanged: (v) => setState(() => _activityLevel = v!),
      activeColor: AppColors.primary,
      dense: true,
    );
  }

  Widget _buildNextButton(VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Next',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
