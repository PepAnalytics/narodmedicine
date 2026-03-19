import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';

/// Экран политики конфиденциальности
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Политика конфиденциальности')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Политика конфиденциальности',
              style: TextStyle(
                fontSize: AppDesignTokens.fontSizeH1,
                fontWeight: AppDesignTokens.fontWeightBold,
                color: AppDesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMD),
            const Text(
              'Версия 1.0.0 от 01.01.2026',
              style: TextStyle(
                fontSize: AppDesignTokens.fontSizeSmall,
                color: AppDesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingLG),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: '1. Сбор данных',
          content: '''
1.1. Приложение собирает минимально необходимые данные для своей работы.

1.2. Собираемые данные включают:
• Уникальный идентификатор пользователя
• История просмотров методов лечения
• Избранные методы
• Данные об оценках (лайки/дизлайки)

1.3. Приложение не собирает персональные данные без явного согласия пользователя.
''',
        ),
        _Section(
          title: '2. Использование данных',
          content: '''
2.1. Собранные данные используются исключительно для улучшения функционала приложения.

2.2. Данные могут использоваться для:
• Персонализации контента
• Улучшения рекомендаций
• Анализа использования приложения

2.3. Данные не передаются третьим лицам без согласия пользователя.
''',
        ),
        _Section(
          title: '3. Хранение данных',
          content: '''
3.1. Данные хранятся локально на устройстве пользователя.

3.2. При наличии интернет-соединения данные могут синхронизироваться с сервером.

3.3. Пользователь может удалить свои данные в любой момент через настройки приложения.
''',
        ),
        _Section(
          title: '4. Безопасность',
          content: '''
4.1. Мы принимаем все необходимые меры для защиты данных пользователя.

4.2. Данные передаются по защищённым каналам связи (HTTPS).

4.3. Доступ к данным имеют только уполномоченные лица.
''',
        ),
        _Section(
          title: '5. Права пользователя',
          content: '''
5.1. Пользователь имеет право:
• Получить копию своих данных
• Исправить неточные данные
• Удалить свои данные
• Отозвать согласие на обработку данных

5.2. Для реализации своих прав пользователь может связаться с поддержкой.
''',
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDesignTokens.fontSizeH3,
                fontWeight: AppDesignTokens.fontWeightBold,
                color: AppDesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingSM),
            Text(
              content,
              style: const TextStyle(
                fontSize: AppDesignTokens.fontSizeBody,
                color: AppDesignTokens.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
