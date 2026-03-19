import 'package:flutter/material.dart';

/// Константы приложения
class AppConstants {
  AppConstants._();

  // Цвета бренда
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF8BC34A);
  static const Color accentColor = Color(0xFFFFC107);

  // Цвета уровней доказательности
  static const Color evidenceHighColor = Color(0xFF4CAF50);
  static const Color evidenceMediumColor = Color(0xFFFFC107);
  static const Color evidenceLowColor = Color(0xFFF44336);
  static const Color evidenceUnknownColor = Color(0xFF9E9E9E);

  // Размеры
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;

  // Названия экранов для навигации
  static const String homeRoute = '/';
  static const String searchResultsRoute = '/search-results';
  static const String diseaseDetailRoute = '/disease';
  static const String remedyDetailRoute = '/remedy';
  static const String aboutRoute = '/about';
  static const String favoritesRoute = '/favorites';
  static const String historyRoute = '/history';

  // Индексы вкладок нижней навигации
  static const int tabSearch = 0;
  static const int tabFavorites = 1;
  static const int tabHistory = 2;
  static const int tabAbout = 3;

  // Сетевые настройки
  static const int networkTimeoutSeconds = 30;

  // Базовый URL API
  // Android эмулятор: http://10.0.2.2:8000
  // iOS эмулятор / Web / Desktop: http://localhost:8000
  static const String apiBaseUrl = 'http://10.0.2.2:8000';

  // Настройки синхронизации
  static const int syncStaleDays = 7;
  static const int maxHistoryItems = 50;
}
