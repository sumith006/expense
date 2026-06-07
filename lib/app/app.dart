import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import '../theme/neobrutal_theme.dart';
import '../providers/settings_provider.dart';

class ExpenseTaskApp extends ConsumerWidget {
  const ExpenseTaskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Finance Pro',
      debugShowCheckedModeBanner: false,
      theme: NeoBrutalTheme.lightTheme,
      darkTheme: NeoBrutalTheme.darkTheme,
      themeMode: settings.themeMode,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _NoGlowBehavior(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

// Remove scroll glow for better performance and a cleaner look
class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
