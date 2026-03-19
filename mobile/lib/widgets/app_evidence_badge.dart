import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

/// Бейдж уровня доказательности
/// Padding: 4px 10px, radius: 12px, font-size: 12px, weight: 600
class AppEvidenceBadge extends StatelessWidget {
  final String code; // A, B, C, D, E
  final String? label;
  final bool showIcon;

  const AppEvidenceBadge({
    super.key,
    required this.code,
    this.label,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppDesignTokens.evidenceBg[code.toUpperCase()] ??
        AppDesignTokens.evidenceBg['E']!;
    final textColor = AppDesignTokens.evidenceText[code.toUpperCase()] ??
        AppDesignTokens.evidenceText['E']!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingSM,
        vertical: AppDesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSM),
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
            label ?? _getLabelForCode(code),
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

  String _getLabelForCode(String code) {
    switch (code.toUpperCase()) {
      case 'A':
        return 'Высокий';
      case 'B':
        return 'Средний';
      case 'C':
        return 'Низкий';
      case 'D':
        return 'Очень низкий';
      case 'E':
        return 'Нет данных';
      default:
        return code;
    }
  }

  IconData _getIconForCode(String code) {
    switch (code.toUpperCase()) {
      case 'A':
        return Icons.star;
      case 'B':
        return Icons.star_half;
      case 'C':
        return Icons.star_outline;
      case 'D':
        return Icons.info_outline;
      case 'E':
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }
}
