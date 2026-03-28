import 'package:flutter/material.dart';
import '../theme.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;

  const TopAppBar({super.key, this.title = 'CalorAI', this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      centerTitle: showBack,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
      leadingWidth: showBack ? 56 : 72,
      title: showBack && title != 'CalorAI'
          ? Text(
              title,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : !showBack
          ? Text(
              title,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            )
          : null,
      actions: [
        if (!showBack)
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppTheme.primary,
            ),
            onPressed: () {},
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
