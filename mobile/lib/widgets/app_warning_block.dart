import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

/// Блок предупреждения v2 (мягкий, тёплый)
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
        color: AppDesignTokens.bgWarm,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
        border: Border.all(
          color: AppDesignTokens.accentWarm.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.medical_services_outlined,
            color: AppDesignTokens.accentWarm,
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

/// Простое предупреждение (для главного экрана)
class AppSoftWarning extends StatelessWidget {
  final String message;

  const AppSoftWarning({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
      decoration: BoxDecoration(
        color: AppDesignTokens.bgWarm,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppDesignTokens.accentWarm,
            size: AppDesignTokens.iconSizeMedium,
          ),
          const SizedBox(width: AppDesignTokens.spacingSM),
          Expanded(
            child: Text(
              message,
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
