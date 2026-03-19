import 'package:flutter/material.dart';

/// Дизайн-токены приложения
/// Все цвета, типографика, отступы и радиусы согласно UI-киту
class AppDesignTokens {
  AppDesignTokens._();

  // ============================================================
  // ЦВЕТА
  // ============================================================

  // Primary цвета
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color lightGreen = Color(0xFFE8F5E9);

  // Background цвета
  static const Color bgMain = Color(0xFFF5F7F6);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgMuted = Color(0xFFF1F3F2);

  // Text цвета
  static const Color textPrimary = Color(0xFF1B1F1D);
  static const Color textSecondary = Color(0xFF5F6B66);
  static const Color textMuted = Color(0xFF8A9590);

  // Border цвета
  static const Color borderColor = Color(0xFFE0E5E3);

  // Status цвета
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);

  // Evidence уровни - фон
  static const Map<String, Color> evidenceBg = {
    'A': Color(0xFFE8F5E9),
    'B': Color(0xFFF1F8E9),
    'C': Color(0xFFFFF8E1),
    'D': Color(0xFFFFF3E0),
    'E': Color(0xFFFFEBEE),
  };

  // Evidence уровни - текст
  static const Map<String, Color> evidenceText = {
    'A': Color(0xFF2E7D32),
    'B': Color(0xFF558B2F),
    'C': Color(0xFFF9A825),
    'D': Color(0xFFEF6C00),
    'E': Color(0xFFC62828),
  };

  // ============================================================
  // ТИПОГРАФИКА
  // ============================================================

  // Размеры шрифтов
  static const double fontSizeH1 = 28.0;
  static const double fontSizeH2 = 22.0;
  static const double fontSizeH3 = 18.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeCaption = 12.0;

  // Веса шрифтов
  static const FontWeight fontWeightBold = FontWeight.w600;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightRegular = FontWeight.w400;

  // ============================================================
  // ОТСТУПЫ (spacing)
  // ============================================================

  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // ============================================================
  // РАДИУСЫ (radius)
  // ============================================================

  static const double radiusSM = 10.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 999.0; // Для чипсов

  // ============================================================
  // ТЕНИ (shadows)
  // ============================================================

  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  // ============================================================
  // РАЗМЕРЫ КОМПОНЕНТОВ
  // ============================================================

  // Кнопки и поля ввода
  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;
  static const double chipHeight = 32.0;

  // Иконки
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;

  // Минимальная область нажатия (accessibility)
  static const double minTapSize = 44.0;
}
