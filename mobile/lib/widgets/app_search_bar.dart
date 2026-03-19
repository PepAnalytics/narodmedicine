import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';

/// Поле поиска (SearchBar)
/// Высота: 52px, radius: 16px, bg: белый, border: 1px #E0E5E3
class AppSearchBar extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearch;
  final TextEditingController? controller;
  final bool enabled;

  const AppSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSearch,
    this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDesignTokens.inputHeight,
      decoration: BoxDecoration(
        color: AppDesignTokens.bgCard,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
        border: Border.all(color: AppDesignTokens.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppDesignTokens.spacingMD),
            child: Icon(
              Icons.search_outlined,
              color: AppDesignTokens.textMuted,
              size: AppDesignTokens.iconSizeLarge,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              onSubmitted: (_) => onSearch?.call(),
              style: const TextStyle(
                fontSize: AppDesignTokens.fontSizeBody,
                color: AppDesignTokens.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText ?? 'Введите симптомы...',
                hintStyle: const TextStyle(
                  color: AppDesignTokens.textMuted,
                  fontSize: AppDesignTokens.fontSizeBody,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.spacingSM,
                  vertical: AppDesignTokens.spacingMD,
                ),
              ),
            ),
          ),
          if (onSearch != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDesignTokens.spacingSM),
              child: InkWell(
                onTap: enabled ? onSearch : null,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSM),
                child: Container(
                  width: AppDesignTokens.minTapSize,
                  height: AppDesignTokens.minTapSize,
                  decoration: BoxDecoration(
                    color: AppDesignTokens.primaryGreen,
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusSM,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: AppDesignTokens.iconSizeMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
