import 'package:flutter/foundation.dart';

/// Конфигурация приложения
class AppConfig {
  AppConfig._();

  /// Базовый URL API
  /// Для эмулятора Android: http://10.0.2.2:8000
  /// Для реального устройства: http://<IP_компьютера>:8000
  /// Для web: http://localhost:8000
  static String get apiUrl {
    // Переопределяется через --dart-define=API_URL=...
    const definedUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: '',
    );

    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }

    // Автоопределение платформы
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    // По умолчанию для Android эмулятора
    return 'http://10.0.2.2:8000';
  }

  /// Таймаут для запросов (секунды)
  static const int networkTimeoutSeconds = 30;
}
