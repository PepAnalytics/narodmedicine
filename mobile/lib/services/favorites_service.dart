import 'dart:async';
import '../models/local/local.dart';
import 'database_service.dart';

/// Сервис для управления избранными методами
class FavoritesService {
  final String baseUrl;
  final DatabaseService _databaseService;

  FavoritesService({
    required this.baseUrl,
    required DatabaseService databaseService,
  }) : _databaseService = databaseService;

  /// Поток для уведомления об изменениях в избранном
  final _changeController = StreamController<void>.broadcast();
  Stream<void> get changes => _changeController.stream;

  /// Получить все избранные методы
  List<LocalFavorite> getFavorites() {
    return _databaseService.getAllFavorites();
  }

  /// Проверить, есть ли метод в избранном
  bool isFavorite(int remedyId) {
    return _databaseService.isFavorite(remedyId);
  }

  /// Добавить в избранное
  Future<bool> addFavorite({
    required int remedyId,
    required String name,
    required int diseaseId,
    required String diseaseName,
    required String evidenceLevelCode,
  }) async {
    try {
      // Сохраняем локально
      final favorite = LocalFavorite(
        remedyId: remedyId,
        name: name,
        diseaseId: diseaseId,
        diseaseName: diseaseName,
        evidenceLevelCode: evidenceLevelCode,
        addedAt: DateTime.now(),
      );
      await _databaseService.addFavorite(favorite);

      // Отправляем на сервер (в фоне)
      _sendToServer(remedyId, isLike: true).catchError((_) {});

      _changeController.add(null);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Удалить из избранного
  Future<bool> removeFavorite(int remedyId) async {
    try {
      // Удаляем локально
      await _databaseService.removeFavorite(remedyId);

      // Отправляем на сервер (в фоне)
      _removeFromServer(remedyId).catchError((_) {});

      _changeController.add(null);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Переключить статус избранного
  Future<bool> toggleFavorite({
    required int remedyId,
    required String name,
    required int diseaseId,
    required String diseaseName,
    required String evidenceLevelCode,
  }) async {
    if (isFavorite(remedyId)) {
      return await removeFavorite(remedyId);
    } else {
      return await addFavorite(
        remedyId: remedyId,
        name: name,
        diseaseId: diseaseId,
        diseaseName: diseaseName,
        evidenceLevelCode: evidenceLevelCode,
      );
    }
  }

  /// Отправить добавление на сервер
  Future<void> _sendToServer(int remedyId, {required bool isLike}) async {
    // TODO: Реализовать когда будет эндпоинт /api/favorites/
    // final response = await _client.post(
    //   Uri.parse('$baseUrl/api/favorites/'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({'remedy_id': remedyId}),
    // );
    print('Add to favorites: $remedyId');
  }

  /// Удалить с сервера
  Future<void> _removeFromServer(int remedyId) async {
    // TODO: Реализовать когда будет эндпоинт /api/favorites/{id}/
    // final response = await _client.delete(
    //   Uri.parse('$baseUrl/api/favorites/$remedyId/'),
    // );
    print('Remove from favorites: $remedyId');
  }

  /// Закрыть сервис
  void dispose() {
    _changeController.close();
  }
}
