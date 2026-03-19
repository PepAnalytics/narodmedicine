import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/local/legal_document.dart';
import 'database_service.dart';

/// Сервис для работы с юридическими документами
class LegalService {
  final String baseUrl;
  final DatabaseService _databaseService;
  final http.Client _client;

  LegalService({
    required this.baseUrl,
    required DatabaseService databaseService,
    http.Client? client,
  }) : _databaseService = databaseService,
       _client = client ?? http.Client();

  /// Получить пользовательское соглашение
  Future<LegalDocument> getTermsOfService() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/legal/terms/'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load terms: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body);
    return LegalDocument(
      type: 'terms_of_service',
      version: jsonData['version'] as String,
      content: jsonData['content'] as String,
      effectiveFrom: DateTime.parse(jsonData['effective_from'] as String),
      createdAt: DateTime.parse(jsonData['created_at'] as String),
    );
  }

  /// Получить политику конфиденциальности
  Future<LegalDocument> getPrivacyPolicy() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/legal/privacy/'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load privacy policy: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body);
    return LegalDocument(
      type: 'privacy_policy',
      version: jsonData['version'] as String,
      content: jsonData['content'] as String,
      effectiveFrom: DateTime.parse(jsonData['effective_from'] as String),
      createdAt: DateTime.parse(jsonData['created_at'] as String),
    );
  }

  /// Отправить согласие пользователя
  Future<bool> submitConsent({
    required String userId,
    required String termsVersion,
    required String privacyVersion,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/legal/consent/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'terms_version': termsVersion,
              'privacy_version': privacyVersion,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Сохраняем локально
        await _databaseService.setConsent(termsVersion);
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting consent: $e');
      return false;
    }
  }

  /// Проверить, нужно ли показывать согласие
  Future<bool> needsConsent() async {
    // Проверяем локальное согласие
    if (!_databaseService.hasConsent) {
      return true;
    }

    // Проверяем актуальность версий
    try {
      final terms = await getTermsOfService();
      final localConsentVersion = _databaseService.consentVersion;

      // Если версия документа новее, чем версия согласия
      if (localConsentVersion == null || terms.version != localConsentVersion) {
        return true;
      }
    } catch (e) {
      // Если не удалось загрузить документы, используем локальное согласие
      print('Error checking consent: $e');
    }

    return false;
  }

  /// Сохранить юридические документы локально
  Future<void> cacheLegalDocuments() async {
    try {
      final terms = await getTermsOfService();
      final privacy = await getPrivacyPolicy();

      await _databaseService.saveLegalDocument(terms);
      await _databaseService.saveLegalDocument(privacy);
    } catch (e) {
      print('Error caching legal documents: $e');
    }
  }

  /// Получить кэшированные документы
  LegalDocument? getCachedTerms() =>
      _databaseService.getLegalDocument('terms_of_service');

  LegalDocument? getCachedPrivacy() =>
      _databaseService.getLegalDocument('privacy_policy');
}
