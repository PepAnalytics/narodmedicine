import 'package:flutter/material.dart';
import '../services/services.dart';
import '../utils/app_constants.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

/// Диалог согласия с юридическими документами
class ConsentDialog extends StatefulWidget {
  final Function(bool accepted) onResult;

  const ConsentDialog({super.key, required this.onResult});

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Нельзя закрыть без согласия
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.gavel,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Соглашение с условиями',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Для продолжения работы с приложением необходимо принять условия пользовательского соглашения и политики конфиденциальности.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'Я принимаю условия Пользовательского соглашения',
                ),
                subtitle: TextButton(
                  onPressed: _isLoading ? null : () => _showTerms(context),
                  child: const Text('Читать документ'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() => _termsAccepted = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Я принимаю Политику конфиденциальности'),
                subtitle: TextButton(
                  onPressed: _isLoading ? null : () => _showPrivacy(context),
                  child: const Text('Читать документ'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                value: _privacyAccepted,
                onChanged: (value) {
                  setState(() => _privacyAccepted = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: (_termsAccepted && _privacyAccepted)
                      ? _submitConsent
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Продолжить'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTerms(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  Future<void> _showPrivacy(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _submitConsent() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();
      await db.init();

      final userService = await UserService.init();
      final userId = await userService.getUserId();

      final legalService = LegalService(
        baseUrl: AppConstants.apiBaseUrl,
        databaseService: db,
      );

      // Загружаем версии документов
      final terms = await legalService.getTermsOfService();
      final privacy = await legalService.getPrivacyPolicy();

      // Отправляем согласие
      final success = await legalService.submitConsent(
        userId: userId,
        termsVersion: terms.version,
        privacyVersion: privacy.version,
      );

      if (success && mounted) {
        widget.onResult(true);
      } else if (mounted) {
        // Сохраняем локально если API недоступно
        await db.setConsent(terms.version);
        widget.onResult(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        setState(() => _isLoading = false);
      }
    }
  }
}
