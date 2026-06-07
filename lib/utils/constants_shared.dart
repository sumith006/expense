import 'package:flutter/material.dart';

class AppConstants {
  // Noir Elegance Palette - Light Mode Support
  static const Color primaryLight = Color(0xFF0A2647);
  static const Color secondaryLight = Color(0xFFE94560);
  static const Color successLight = Color(0xFF00D09E);
  static const Color dangerLight = Color(0xFFFF4757);
  static const Color warningLight = Color(0xFFFFB347);
  static const Color infoLight = Color(0xFF4A9EFF);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Noir Elegance Palette - Dark Mode
  static const Color primaryDark = Color(0xFF2C74B3);
  static const Color secondaryDark = Color(0xFFE94560);
  static const Color successDark = Color(0xFF00A884);
  static const Color dangerDark = Color(0xFFFF4757);
  static const Color warningDark = Color(0xFFFFB347);
  static const Color infoDark = Color(0xFF4A9EFF);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF475569);

  static const Color warningColor = warningLight;

  // Priority Colors
  static const Color priorityHigh = Color(0xFFFF4757);
  static const Color priorityMedium = Color(0xFFFFB347);
  static const Color priorityLow = Color(0xFF00D09E);

  // Category Colors
  static const Color catFood = Color(0xFFFF6B6B);
  static const Color catTravel = Color(0xFF4ECDC4);
  static const Color catShopping = Color(0xFFFFB347);
  static const Color catBills = Color(0xFFA8E6CF);
  static const Color catEntertainment = Color(0xFFFF9F1C);
  static const Color catHealth = Color(0xFFC77DFF);
  static const Color catWork = Color(0xFF4A9EFF);
  static const Color catPersonal = Color(0xFFFF6B9D);
  static const Color catEducation = Color(0xFF00D09E);
  static const Color catHome = Color(0xFF9C89B8);

  // Spacing System
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;
  static const double spacingXxxl = 48.0;

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;

  static final BorderRadius cardBorderRadius = BorderRadius.circular(
    radiusLarge,
  );
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(
    radiusSmall,
  );

  // Deprecated (Kept for compatibility during refactoring)
  static const Color primaryColor = primaryLight;
  static const Color secondaryColor = secondaryLight;
  static const Color expenseColor = dangerLight;
  static const Color lightBgColor = backgroundLight;
  static const Color darkBgColor = backgroundDark;
  static const Color lightCardColor = surfaceLight;
  static const Color darkCardColor = surfaceDark;
  static const double paddingSmall = spacingS;
  static const double paddingMedium = spacingL;
  static const double paddingLarge = spacingXl;
  static const double borderRadiusSmall = radiusSmall;
  static const double borderRadiusMedium = radiusMedium;
  static const double borderRadiusLarge = radiusLarge;

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> darkShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];
}
