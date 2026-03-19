import 'dart:async';
import '../models/local/local.dart';
import 'database_service.dart';

/// Сервис для управления историей просмотров
class HistoryService {
  final DatabaseService _databaseService;

  HistoryService({required DatabaseService databaseService})
    : _databaseService = databaseService;

  /// Поток для уведомления об изменениях в истории
  final _changeController = StreamController<void>.broadcast();
  Stream<void> get changes => _changeController.stream;

  /// Получить историю просмотров
  List<LocalHistoryItem> getHistory({int limit = 20}) {
    return _databaseService.getHistory(limit: limit);
  }

  /// Добавить в историю
  Future<void> addToHistory({
    required int remedyId,
    required String name,
    required int diseaseId,
    required String diseaseName,
  }) async {
    try {
      final item = LocalHistoryItem(
        remedyId: remedyId,
        name: name,
        diseaseId: diseaseId,
        diseaseName: diseaseName,
        viewedAt: DateTime.now(),
      );
      await _databaseService.addToHistory(item);
      _changeController.add(null);
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  /// Очистить историю
  Future<void> clearHistory() async {
    await _databaseService.clearHistory();
    _changeController.add(null);
  }

  /// Закрыть сервис
  void dispose() {
    _changeController.close();
  }
}
