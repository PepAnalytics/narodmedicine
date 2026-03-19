import 'package:flutter/material.dart';
import 'app_design_tokens.dart';

/// Тема приложения v2 (Warmth & Nature)
class AppTheme {
  AppTheme._();

  /// Светлая тема
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Цветовая схема
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppDesignTokens.primaryGreen,
        brightness: Brightness.light,
        primary: AppDesignTokens.primaryGreen,
        secondary: AppDesignTokens.secondaryGreen,
        surface: AppDesignTokens.bgMain,
        error: AppDesignTokens.danger,
      ),

      // Фон приложения
      scaffoldBackgroundColor: AppDesignTokens.bgMain,

      // Типографика
      textTheme: _buildTextTheme(),

      // AppBar тема
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppDesignTokens.bgMain,
        foregroundColor: AppDesignTokens.textPrimary,
        titleTextStyle: TextStyle(
          color: AppDesignTokens.textPrimary,
          fontSize: AppDesignTokens.fontSizeH2,
          fontWeight: AppDesignTokens.fontWeightBold,
        ),
      ),

      // Карточки
      cardTheme: CardThemeData(
        color: AppDesignTokens.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLG),
          side: BorderSide(
            color: AppDesignTokens.borderColor,
            width: 1,
          ),
        ),
      ),

      // Поля ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesignTokens.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingMD,
          vertical: AppDesignTokens.spacingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
          borderSide: BorderSide(
            color: AppDesignTokens.borderColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
          borderSide: BorderSide(
            color: AppDesignTokens.borderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
          borderSide: BorderSide(
            color: AppDesignTokens.primaryGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
          borderSide: BorderSide(
            color: AppDesignTokens.danger,
            width: 1,
          ),
        ),
        hintStyle: const TextStyle(
          color: AppDesignTokens.textMuted,
          fontSize: AppDesignTokens.fontSizeBody,
        ),
      ),

      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignTokens.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppDesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: AppDesignTokens.fontSizeBody,
            fontWeight: AppDesignTokens.fontWeightBold,
          ),
          elevation: 0,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDesignTokens.primaryGreen,
          minimumSize: const Size(AppDesignTokens.minTapSize, AppDesignTokens.minTapSize),
          textStyle: const TextStyle(
            fontSize: AppDesignTokens.fontSizeBody,
            fontWeight: AppDesignTokens.fontWeightMedium,
          ),
        ),
      ),

      // Outline buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignTokens.primaryGreen,
          minimumSize: const Size(double.infinity, AppDesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMD),
          ),
          side: BorderSide(
            color: AppDesignTokens.primaryGreen,
            width: 1.5,
          ),
          textStyle: const TextStyle(
            fontSize: AppDesignTokens.fontSizeBody,
            fontWeight: AppDesignTokens.fontWeightBold,
          ),
        ),
      ),

      // Чипсы
      chipTheme: ChipThemeData(
        backgroundColor: AppDesignTokens.bgMuted,
        selectedColor: AppDesignTokens.primaryGreen,
        labelStyle: const TextStyle(
          fontSize: AppDesignTokens.fontSizeSmall,
          fontWeight: AppDesignTokens.fontWeightRegular,
          color: AppDesignTokens.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingSM,
          vertical: AppDesignTokens.spacingXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusXL),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppDesignTokens.borderColor,
        thickness: 1,
        space: AppDesignTokens.spacingMD,
      ),

      // Иконки
      iconTheme: const IconThemeData(
        color: AppDesignTokens.textPrimary,
        size: AppDesignTokens.iconSizeMedium,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppDesignTokens.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDesignTokens.bgCard,
        selectedItemColor: AppDesignTokens.primaryGreen,
        unselectedItemColor: AppDesignTokens.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Тёмная тема (адаптированная)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppDesignTokens.primaryGreen,
        brightness: Brightness.dark,
        primary: AppDesignTokens.secondaryGreen,
        surface: const Color(0xFF1A1F1D),
      ),
      scaffoldBackgroundColor: const Color(0xFF121514),
      textTheme: _buildTextTheme().apply(
        bodyColor: const Color(0xFFE0E5E3),
        displayColor: const Color(0xFFE0E5E3),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1A1F1D),
        foregroundColor: Color(0xFFE0E5E3),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1F1D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLG),
          side: const BorderSide(
            color: Color(0xFF2A302D),
            width: 1,
          ),
        ),
      ),
    );
  }

  /// Текстовая тема
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Заголовки
      headlineLarge: TextStyle(
        fontSize: AppDesignTokens.fontSizeH1,
        fontWeight: AppDesignTokens.fontWeightBold,
        color: AppDesignTokens.textPrimary,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: AppDesignTokens.fontSizeH2,
        fontWeight: AppDesignTokens.fontWeightBold,
        color: AppDesignTokens.textPrimary,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: AppDesignTokens.fontSizeH3,
        fontWeight: AppDesignTokens.fontWeightBold,
        color: AppDesignTokens.textPrimary,
        height: 1.3,
      ),

      // Основной текст
      bodyLarge: TextStyle(
        fontSize: AppDesignTokens.fontSizeBody,
        fontWeight: AppDesignTokens.fontWeightRegular,
        color: AppDesignTokens.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: AppDesignTokens.fontSizeBody,
        fontWeight: AppDesignTokens.fontWeightRegular,
        color: AppDesignTokens.textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: AppDesignTokens.fontSizeSmall,
        fontWeight: AppDesignTokens.fontWeightRegular,
        color: AppDesignTokens.textSecondary,
        height: 1.5,
      ),

      // Вспомогательный текст
      labelLarge: TextStyle(
        fontSize: AppDesignTokens.fontSizeSmall,
        fontWeight: AppDesignTokens.fontWeightMedium,
        color: AppDesignTokens.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: AppDesignTokens.fontSizeCaption,
        fontWeight: AppDesignTokens.fontWeightRegular,
        color: AppDesignTokens.textMuted,
      ),
    );
  }
}
