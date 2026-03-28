import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
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
    if (uid == null || profileProv.profile == null) return;

    await profileProv.updateProfile(uid, {
      'name': _nameController.text.trim(),
      'heightCm': double.tryParse(_heightController.text) ?? profileProv.profile!.heightCm,
      'weightKg': double.tryParse(_weightController.text) ?? profileProv.profile!.weightKg,
      'age': int.tryParse(_ageController.text) ?? profileProv.profile!.age,
    });

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success),
      );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProv, _) {
          final profile = profileProv.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(profile.email,
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 24),

                // Editable fields
                _buildProfileField('Name', _nameController, _isEditing),
                _buildProfileField('Height (cm)', _heightController, _isEditing,
                    keyboardType: TextInputType.number),
                _buildProfileField('Weight (kg)', _weightController, _isEditing,
                    keyboardType: TextInputType.number),
                _buildProfileField('Age', _ageController, _isEditing,
                    keyboardType: TextInputType.number),

                const SizedBox(height: 16),

                // Read-only info
                _buildInfoRow('Sex', profile.sex == 'male' ? 'Male' : 'Female'),
                _buildInfoRow('Activity',
                    profile.activityLevel.replaceAll('_', ' ')),
                _buildInfoRow(
                    'Goal', profile.goal.replaceAll('_', ' ')),
                _buildInfoRow('Daily Target', '${profile.calorieTarget} kcal'),
                if (profile.macroTargets != null) ...[
                  _buildInfoRow('Protein Target',
                      '${profile.macroTargets!.proteinG}g'),
                  _buildInfoRow(
                      'Carbs Target', '${profile.macroTargets!.carbsG}g'),
                  _buildInfoRow(
                      'Fats Target', '${profile.macroTargets!.fatsG}g'),
                ],
                const SizedBox(height: 24),

                // Recalculate
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<ProfileProvider>().recalculateTarget();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calorie target recalculated!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('Recalculate Target'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),

                // Footer
                Center(
                  child: Text(
                    'Nutritional data powered by MyFCD 2026',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // Logout
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Log Out',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileField(
      String label, TextEditingController controller, bool editable,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: editable,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          filled: true,
          fillColor: editable ? Colors.white : AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
