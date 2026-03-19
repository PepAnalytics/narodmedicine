import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

/// Бейдж уровня доказательности v2
/// Обновлённые цвета и текстовые описания
class AppEvidenceBadge extends StatelessWidget {
  final String code; // A, B, C, D, E
  final bool showIcon;

  const AppEvidenceBadge({
    super.key,
    required this.code,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppDesignTokens.evidenceBg[code.toUpperCase()] ??
        AppDesignTokens.evidenceBg['E']!;
    final textColor = AppDesignTokens.evidenceText[code.toUpperCase()] ??
        AppDesignTokens.evidenceText['E']!;
    final label = AppDesignTokens.evidenceLabels[code.toUpperCase()] ?? code;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingSM,
        vertical: AppDesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSM),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getIconForCode(code),
              color: textColor,
              size: AppDesignTokens.iconSizeSmall,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: AppDesignTokens.fontSizeCaption,
              fontWeight: AppDesignTokens.fontWeightBold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCode(String code) {
    switch (code.toUpperCase()) {
      case 'A':
        return Icons.auto_stories;
      case 'B':
        return Icons.menu_book;
      case 'C':
        return Icons.psychology_outlined;
      case 'D':
        return Icons.history_edu;
      case 'E':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }
}
