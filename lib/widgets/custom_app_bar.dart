import 'package:flutter/material.dart';
import '../utils/constants_shared.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const StandardAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String greeting;
  final String motivationalMessage;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const DashboardAppBar({
    super.key,
    required this.greeting,
    required this.motivationalMessage,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: onNotificationTap,
                      color: theme.iconTheme.color,
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle_outlined),
                      onPressed: onProfileTap,
                      color: theme.iconTheme.color,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              motivationalMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(96.0 + 24.0); // 96 + status bar approx
}
