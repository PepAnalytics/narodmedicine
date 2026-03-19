import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

/// Блок предупреждения
/// bg: #FFF3E0, border: 1px #FFCC80, radius: 16px, padding: 16px
class AppWarningBlock extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;

  const AppWarningBlock({
    super.key,
    required this.title,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
        border: Border.all(
          color: const Color(0xFFFFCC80),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.warning_amber_outlined,
            color: const Color(0xFFF9A825),
            size: AppDesignTokens.iconSizeLarge,
          ),
          const SizedBox(width: AppDesignTokens.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeBody,
                    fontWeight: AppDesignTokens.fontWeightBold,
                    color: AppDesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingXS),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeSmall,
                    color: AppDesignTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Простой текст предупреждения (без иконки)
class AppWarningText extends StatelessWidget {
  final String text;

  const AppWarningText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
        border: Border.all(
          color: const Color(0xFFFFCC80),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppDesignTokens.warning,
            size: AppDesignTokens.iconSizeMedium,
          ),
          const SizedBox(width: AppDesignTokens.spacingSM),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppDesignTokens.fontSizeSmall,
                color: AppDesignTokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
