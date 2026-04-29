import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _routes = ['/home', '/history', '/chatbot', '/profile'];

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/chatbot')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    _selectedIndex = _locationToIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: _GlassBottomBar(
        selectedIndex: _selectedIndex,
        isDark: isDark,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          context.go(_routes[index]);
        },
        onAddTap: _showLogMenu,
      ),
    );
  }

  void _showLogMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LogMenuSheet(),
    );
  }
}

class _LogMenuSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What do you want to log?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LogOption(
                  icon: Icons.add_a_photo_rounded,
                  label: 'AI Scanner',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/log/photo');
                  },
                ),
                _LogOption(
                  icon: Icons.search_rounded,
                  label: 'Manual',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/log/search');
                  },
                ),
                _LogOption(
                  icon: Icons.soup_kitchen_rounded,
                  label: 'Cook Meal',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/log/create-meal');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LogOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LogOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _GlassBottomBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  const _GlassBottomBar({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), // Dynamic Floating!
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  isDark: isDark,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'History',
                  isSelected: selectedIndex == 1,
                  isDark: isDark,
                  onTap: () => onTap(1),
                ),
                // The Add Button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAddTap,
                      customBorder: const CircleBorder(),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'AI Chat',
                  isSelected: selectedIndex == 2,
                  isDark: isDark,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 3,
                  isDark: isDark,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveColor = AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
