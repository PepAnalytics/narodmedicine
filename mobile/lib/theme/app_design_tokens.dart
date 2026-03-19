import 'package:flutter/material.dart';

/// Дизайн-токены приложения v2 (Warmth & Nature)
/// Философия: Healing + Warmth + Nature + Trust
class AppDesignTokens {
  AppDesignTokens._();

  // ============================================================
  // ЦВЕТА - Новая палитра
  // ============================================================

  // Primary цвета
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF668864);
  static const Color lightGreen = Color(0xFFF3E559);
  static const Color warmCream = Color(0xFFFAF772);

  // Градиенты
  static const LinearGradient gradientFresh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8F5E9),
      Color(0xFFF1F8E9),
    ],
  );

  static const LinearGradient gradientCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF9FBF9),
    ],
  );

  // Background цвета
  static const Color bgMain = Color(0xFFF5F7F6);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgMuted = Color(0xFFF1F3F2);
  static const Color bgWarm = Color(0xFFFFF8E7); // Для предупреждений

  // Text цвета
  static const Color textPrimary = Color(0xFF1B1F1D);
  static const Color textSecondary = Color(0xFF5F6B66);
  static const Color textMuted = Color(0xFF8A9590);

  // Accent (тепло)
  static const Color accentWarm = Color(0xFFFFCC80);

  // Border цвета
  static const Color borderColor = Color(0xFFE0E5E3);

  // Status цвета
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);

  // Evidence уровни - фон (обновлённые)
  static const Map<String, Color> evidenceBg = {
    'A': Color(0xFFC8E6C9), // Зелёный мягкий
    'B': Color(0xFFDCEDC8), // Оливковый
    'C': Color(0xFFFFF8E1), // Тёплый жёлтый
    'D': Color(0xFFFFE0B2), // Оранжевый
    'E': Color(0xFFFFCDD2), // Красный
  };

  // Evidence уровни - текст
  static const Map<String, Color> evidenceText = {
    'A': Color(0xFF2E7D32),
    'B': Color(0xFF558B2F),
    'C': Color(0xFFF9A825),
    'D': Color(0xFFEF6C00),
    'E': Color(0xFFC62828),
  };

  // Evidence текстовые описания
  static const Map<String, String> evidenceLabels = {
    'A': 'Хорошо изучено',
    'B': 'Частично подтверждено',
    'C': 'Требует исследований',
    'D': 'Традиционное использование',
    'E': 'Нет подтверждений',
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
      color: const Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: const Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
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

  // ============================================================
  // АНИМАЦИИ
  // ============================================================

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  static const Curve animationCurve = Curves.easeInOut;
}
