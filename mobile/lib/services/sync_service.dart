import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/local/local.dart';
import 'database_service.dart';

/// Сервис для синхронизации данных с бэкендом
class SyncService {
  final String baseUrl;
  final DatabaseService _databaseService;
  final http.Client _client;

  SyncService({
    required this.baseUrl,
    required DatabaseService databaseService,
    http.Client? client,
  }) : _databaseService = databaseService,
       _client = client ?? http.Client();

  /// Проверка необходимости синхронизации
  bool get needsSync =>
      !_databaseService.isInitialized || _databaseService.isDataStale;

  /// Синхронизация всех данных
  Future<SyncResult> sync() async {
    try {
      // Загружаем данные с бэкенда
      final symptoms = await _fetchSymptoms();
      final diseases = await _fetchDiseases();
      final evidenceLevels = await _fetchEvidenceLevels();

      // Сохраняем в локальную БД
      await _databaseService.saveSymptoms(symptoms);
      await _databaseService.saveDiseases(diseases);
      await _databaseService.saveEvidenceLevels(evidenceLevels);

      // Обновляем время синхронизации
      await _databaseService.setLastSyncTime(DateTime.now());
      await _databaseService.setInitialized();

      return SyncResult(
        success: true,
        symptomsCount: symptoms.length,
        diseasesCount: diseases.length,
        evidenceLevelsCount: evidenceLevels.length,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Загрузка симптомов
  Future<List<LocalSymptom>> _fetchSymptoms() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/symptoms/'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load symptoms: ${response.statusCode}');
    }

    final List<dynamic> jsonData = json.decode(response.body);
    return jsonData
        .map(
          (item) => LocalSymptom.fromMap({
            'id': item['id'] as int,
            'name': item['name'] as String,
          }),
        )
        .toList();
  }

  /// Загрузка болезней
  Future<List<LocalDisease>> _fetchDiseases() async {
    // Пока используем заглушку, так как эндпоинт /api/sync/ ещё не готов
    // В будущем здесь будет вызов /api/sync/
    final response = await _client
        .get(Uri.parse('$baseUrl/api/diseases/'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData
          .map(
            (item) => LocalDisease.fromMap({
              'id': item['id'] as int,
              'name': item['name'] as String,
              'description': item['description'] as String,
            }),
          )
          .toList();
    } else if (response.statusCode == 404) {
      // Эндпоинт ещё не реализован, возвращаем пустой список
      return [];
    } else {
      throw Exception('Failed to load diseases: ${response.statusCode}');
    }
  }

  /// Загрузка уровней доказательности
  Future<List<LocalEvidenceLevel>> _fetchEvidenceLevels() async {
    // Пока используем предустановленные значения
    // В будущем можно загружать с бэкенда
    return [
      LocalEvidenceLevel(
        id: 1,
        code: 'A',
        description: 'Высокий уровень доказательности',
        color: '#4CAF50',
        rank: 1,
      ),
      LocalEvidenceLevel(
        id: 2,
        code: 'B',
        description: 'Средний уровень доказательности',
        color: '#FFC107',
        rank: 2,
      ),
      LocalEvidenceLevel(
        id: 3,
        code: 'C',
        description: 'Низкий уровень доказательности',
        color: '#F44336',
        rank: 3,
      ),
      LocalEvidenceLevel(
        id: 4,
        code: 'D',
        description: 'Очень низкий уровень доказательности',
        color: '#9E9E9E',
        rank: 4,
      ),
      LocalEvidenceLevel(
        id: 5,
        code: 'E',
        description: 'Недостаточно данных',
        color: '#607D8B',
        rank: 5,
      ),
    ];
  }
}

/// Результат синхронизации
class SyncResult {
  final bool success;
  final int? symptomsCount;
  final int? diseasesCount;
  final int? evidenceLevelsCount;
  final String? error;

  SyncResult({
    required this.success,
    this.symptomsCount,
    this.diseasesCount,
    this.evidenceLevelsCount,
    this.error,
  });
}
