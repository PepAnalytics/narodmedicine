import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';
import '../utils/app_constants.dart';

/// Исключение для ошибок API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Сервис для работы с API бэкенда
class ApiService {
  final String baseUrl;
  final http.Client _client;
  final Future<String> Function() _getUserId;

  ApiService({
    String? baseUrl,
    http.Client? client,
    required Future<String> Function() getUserId,
  })  : baseUrl = baseUrl ?? AppConfig.apiUrl,
        _client = client ?? http.Client(),
        _getUserId = getUserId;

  /// Получить список всех симптомов для автодополнения
  Future<List<Symptom>> getSymptoms() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/symptoms/'))
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Symptom.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Ошибка загрузки симптомов: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Ошибка сети: ${e.message}');
    } on FormatException {
      throw ApiException('Ошибка формата ответа сервера');
    }
  }

  /// Поиск заболеваний по симптомам
  Future<List<Disease>> searchSymptoms(List<String> symptoms) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/search/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'symptoms': symptoms}),
          )
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> diseasesJson =
            jsonData['diseases'] as List<dynamic>;
        return diseasesJson.map((json) => Disease.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Ошибка поиска: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Ошибка сети: ${e.message}');
    } on FormatException {
      throw ApiException('Ошибка формата ответа сервера');
    }
  }

  /// Получение деталей заболевания по ID
  Future<Disease> getDisease(int id) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/diseases/$id/'))
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Disease.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw ApiException('Заболевание не найдено', statusCode: 404);
      } else {
        throw ApiException(
          'Ошибка загрузки заболевания: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Ошибка сети: ${e.message}');
    } on FormatException {
      throw ApiException('Ошибка формата ответа сервера');
    }
  }

  /// Получение деталей метода лечения по ID
  Future<Remedy> getRemedy(int id) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/remedies/$id/'))
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Remedy.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw ApiException('Метод лечения не найден', statusCode: 404);
      } else {
        throw ApiException(
          'Ошибка загрузки метода: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Ошибка сети: ${e.message}');
    } on FormatException {
      throw ApiException('Ошибка формата ответа сервера');
    }
  }

  /// Оценка метода лечения (лайк/дизлайк)
  Future<Map<String, dynamic>> rateRemedy(
    int remedyId,
    bool isLike,
    String? comment,
  ) async {
    try {
      final userId = await _getUserId();
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/remedies/$remedyId/rate/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'is_like': isLike,
              if (comment != null && comment.isNotEmpty) 'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          'Ошибка оценки: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Ошибка сети: ${e.message}');
    } on FormatException {
      throw ApiException('Ошибка формата ответа сервера');
    }
  }
}
