import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

/// Типы кнопок
enum AppButtonType { primary, secondary, outline }

/// Кнопка приложения
/// Высота: 52px, radius: 16px
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final foregroundColor = _getForegroundColor();
    final borderColor = _getBorderColor();

    return SizedBox(
      height: AppDesignTokens.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
            side: BorderSide(
              color: borderColor ?? Colors.transparent,
              width: 1.5,
            ),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.spacingLG,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppDesignTokens.iconSizeMedium),
                    const SizedBox(width: AppDesignTokens.spacingSM),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: AppDesignTokens.fontSizeBody,
                      fontWeight: AppDesignTokens.fontWeightBold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isLoading) return AppDesignTokens.textMuted;

    switch (type) {
      case AppButtonType.primary:
        return AppDesignTokens.primaryGreen;
      case AppButtonType.secondary:
        return AppDesignTokens.lightGreen;
      case AppButtonType.outline:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    if (isLoading) return Colors.white;

    switch (type) {
      case AppButtonType.primary:
        return Colors.white;
      case AppButtonType.secondary:
        return AppDesignTokens.primaryGreen;
      case AppButtonType.outline:
        return AppDesignTokens.primaryGreen;
    }
  }

  Color? _getBorderColor() {
    if (isLoading) return AppDesignTokens.textMuted;

    switch (type) {
      case AppButtonType.primary:
        return null;
      case AppButtonType.secondary:
        return null;
      case AppButtonType.outline:
        return AppDesignTokens.primaryGreen;
    }
  }
}
