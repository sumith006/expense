import 'package:flutter/material.dart';
import '../utils/constants_shared.dart';

class DatePickerTrigger extends StatelessWidget {
  final String label;
  final String text;
  final VoidCallback onTap;
  final Widget? prefixIcon;
  final String? errorText;

  const DatePickerTrigger({
    super.key,
    required this.label,
    required this.text,
    required this.onTap,
    this.prefixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6), // Text Secondary
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56, // Fixed height for 56dp spec
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingL,
              vertical: AppConstants.spacingM,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium), // 8dp
              border: Border.all(
                color: errorText != null 
                    ? AppConstants.dangerLight 
                    : (theme.colorScheme.outlineVariant ?? AppConstants.borderLight),
                width: errorText != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: AppConstants.spacingM),
                ],
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.dangerLight,
              ),
            ),
          ),
        ]
      ],
    );
  }
}
