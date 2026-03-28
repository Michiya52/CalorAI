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
                      backgroundImage: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuC0UkBgBFaHS1uBHwwRAW2TscOdJWWRBQoj-gXN8OwDOCnzgqHH4K7WqXaCydKuWU6IVHu4hGVwPpdmSyInFRDtLGtzDGMBLPzEAcjJWtVVJt8KoygG7Rlky9xmVffJIZSVvYsI5NH5rdMHUXk1SE5eLdnokiv4s5DD6FQbhieVuRYygeelgy9jWCt65z5ovWw5vFT-YW9YQVpjBVp8wymasWAIUdZFfFTIEvLAXW5Cx5ny3ujRWOBV3Jaz9iJr1YVh5flJaOdPsyyr',
                      ),
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
                color: Colors.emerald[900],
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
              color: Colors.emerald[800],
            ),
            onPressed: () {},
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
