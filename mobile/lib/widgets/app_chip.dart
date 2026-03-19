import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

/// Чипс (симптом/фильтр)
/// Высота: 32px, padding: 0 12px, radius: 999px, bg: bgMuted
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? AppDesignTokens.primaryGreen
        : AppDesignTokens.bgMuted;
    final textColor = isSelected
        ? Colors.white
        : AppDesignTokens.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusXL),
      child: Container(
        height: AppDesignTokens.chipHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingSM + 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppDesignTokens.iconSizeSmall,
                color: textColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppDesignTokens.fontSizeSmall,
                fontWeight: isSelected
                    ? AppDesignTokens.fontWeightMedium
                    : AppDesignTokens.fontWeightRegular,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Фильтр-чипс с эмодзи (для регионов)
class AppRegionChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppRegionChip({
    super.key,
    required this.label,
    this.emoji,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? AppDesignTokens.primaryGreen
        : AppDesignTokens.bgMuted;
    final textColor = isSelected
        ? Colors.white
        : AppDesignTokens.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusXL),
      child: Container(
        height: AppDesignTokens.chipHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingSM + 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(
                emoji!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: AppDesignTokens.fontSizeSmall,
                fontWeight: isSelected
                    ? AppDesignTokens.fontWeightMedium
                    : AppDesignTokens.fontWeightRegular,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
