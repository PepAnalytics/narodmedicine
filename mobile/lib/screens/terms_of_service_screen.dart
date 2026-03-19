import 'package:flutter/material.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';

/// Экран пользовательского соглашения
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользовательское соглашение')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пользовательское соглашение',
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
            const SizedBox(height: AppDesignTokens.spacingXL),
            const AppWarningBlock(
              title: 'Важно',
              message:
                  'Принимая условия данного соглашения, вы подтверждаете своё согласие с условиями использования приложения.',
            ),
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
          title: '1. Общие положения',
          content: '''
1.1. Настоящее Пользовательское соглашение (далее — Соглашение) регулирует отношения между пользователем и приложением «Народная Медицина».

1.2. Используя приложение, вы подтверждаете, что ознакомлены с данным Соглашением и принимаете его условия.

1.3. Приложение предоставляет информацию о народных методах лечения исключительно в ознакомительных целях.
''',
        ),
        _Section(
          title: '2. Цели приложения',
          content: '''
2.1. Приложение предназначено для предоставления информации о народных методах лечения.

2.2. Приложение не является медицинским средством и не предназначено для диагностики или лечения заболеваний.

2.3. Вся информация носит справочный характер и не может заменять консультацию квалифицированного врача.
''',
        ),
        _Section(
          title: '3. Ограничения ответственности',
          content: '''
3.1. Разработчики приложения не несут ответственности за любые последствия, связанные с использованием информации из приложения.

3.2. Пользователь самостоятельно принимает решения о применении тех или иных методов лечения.

3.3. Перед применением любых народных методов необходимо проконсультироваться с врачом.
''',
        ),
        _Section(
          title: '4. Конфиденциальность',
          content: '''
4.1. Приложение собирает минимально необходимые данные для своей работы.

4.2. Персональные данные пользователя защищаются в соответствии с Политикой конфиденциальности.

4.3. Пользователь соглашается на обработку своих данных в рамках функционала приложения.
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
