import 'package:hive_flutter/hive_flutter.dart';
import '../models/local/local.dart';
import '../utils/app_constants.dart';

/// Сервис для работы с локальной базой данных Hive
class DatabaseService {
  static const String _symptomsBoxName = 'symptoms';
  static const String _diseasesBoxName = 'diseases';
  static const String _evidenceLevelsBoxName = 'evidence_levels';
  static const String _favoritesBoxName = 'favorites';
  static const String _historyBoxName = 'history';
  static const String _settingsBoxName = 'settings';

  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _isInitializedKey = 'is_initialized';

  late Box<LocalSymptom> _symptomsBox;
  late Box<LocalDisease> _diseasesBox;
  late Box<LocalEvidenceLevel> _evidenceLevelsBox;
  late Box<LocalFavorite> _favoritesBox;
  late Box<LocalHistoryItem> _historyBox;
  late Box<dynamic> _settingsBox;

  /// Инициализация базы данных
  Future<void> init() async {
    await Hive.initFlutter();

    // Регистрация адаптеров
    Hive.registerAdapter(LocalSymptomAdapter());
    Hive.registerAdapter(LocalDiseaseAdapter());
    Hive.registerAdapter(LocalEvidenceLevelAdapter());
    Hive.registerAdapter(LocalFavoriteAdapter());
    Hive.registerAdapter(LocalHistoryItemAdapter());

    // Открытие боксов
    _symptomsBox = await Hive.openBox<LocalSymptom>(_symptomsBoxName);
    _diseasesBox = await Hive.openBox<LocalDisease>(_diseasesBoxName);
    _evidenceLevelsBox = await Hive.openBox<LocalEvidenceLevel>(
      _evidenceLevelsBoxName,
    );
    _favoritesBox = await Hive.openBox<LocalFavorite>(_favoritesBoxName);
    _historyBox = await Hive.openBox<LocalHistoryItem>(_historyBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  /// Проверка, инициализирована ли БД
  bool get isInitialized =>
      _settingsBox.get(_isInitializedKey, defaultValue: false) as bool;

  /// Установка флага инициализации
  Future<void> setInitialized() async {
    await _settingsBox.put(_isInitializedKey, true);
  }

  /// Получить время последней синхронизации
  DateTime? get lastSyncTime {
    final timestamp = _settingsBox.get(_lastSyncTimeKey);
    if (timestamp == null) return null;
    return timestamp as DateTime;
  }

  /// Установить время последней синхронизации
  Future<void> setLastSyncTime(DateTime time) async {
    await _settingsBox.put(_lastSyncTimeKey, time);
  }

  /// Проверка, устарели ли данные (старше 7 дней)
  bool get isDataStale {
    final lastSync = lastSyncTime;
    if (lastSync == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inDays >= AppConstants.syncStaleDays;
  }

  /// Проверка необходимости синхронизации
  bool get needsSync => !isInitialized || isDataStale;

  // ==================== Симптомы ====================

  /// Получить все симптомы
  List<LocalSymptom> getAllSymptoms() {
    return _symptomsBox.values.toList();
  }

  /// Сохранить симптомы
  Future<void> saveSymptoms(List<LocalSymptom> symptoms) async {
    await _symptomsBox.clear();
    for (final symptom in symptoms) {
      await _symptomsBox.put(symptom.id, symptom);
    }
  }

  /// Найти симптомы по названию (нечёткий поиск)
  List<LocalSymptom> searchSymptoms(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return [];

    return _symptomsBox.values.where((symptom) {
        final normalizedName = symptom.name.toLowerCase();
        return normalizedName.contains(normalizedQuery);
      }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // ==================== Болезни ====================

  /// Получить все болезни
  List<LocalDisease> getAllDiseases() {
    return _diseasesBox.values.toList();
  }

  /// Сохранить болезни
  Future<void> saveDiseases(List<LocalDisease> diseases) async {
    await _diseasesBox.clear();
    for (final disease in diseases) {
      await _diseasesBox.put(disease.id, disease);
    }
  }

  /// Получить болезнь по ID
  LocalDisease? getDiseaseById(int id) {
    return _diseasesBox.get(id);
  }

  // ==================== Уровни доказательности ====================

  /// Получить все уровни доказательности
  List<LocalEvidenceLevel> getAllEvidenceLevels() {
    return _evidenceLevelsBox.values.toList();
  }

  /// Сохранить уровни доказательности
  Future<void> saveEvidenceLevels(List<LocalEvidenceLevel> levels) async {
    await _evidenceLevelsBox.clear();
    for (final level in levels) {
      await _evidenceLevelsBox.put(level.id, level);
    }
  }

  /// Получить уровень доказательности по коду
  LocalEvidenceLevel? getEvidenceLevelByCode(String code) {
    return _evidenceLevelsBox.values.firstWhere(
      (level) => level.code.toUpperCase() == code.toUpperCase(),
      orElse: () => LocalEvidenceLevel(
        id: 0,
        code: 'UNKNOWN',
        description: 'Неизвестный',
        color: '#9E9E9E',
        rank: 0,
      ),
    );
  }

  // ==================== Избранное ====================

  /// Получить все избранные методы
  List<LocalFavorite> getAllFavorites() {
    return _favoritesBox.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  /// Добавить в избранное
  Future<void> addFavorite(LocalFavorite favorite) async {
    await _favoritesBox.put(favorite.remedyId, favorite);
  }

  /// Удалить из избранного
  Future<void> removeFavorite(int remedyId) async {
    await _favoritesBox.delete(remedyId);
  }

  /// Проверить, есть ли в избранном
  bool isFavorite(int remedyId) {
    return _favoritesBox.containsKey(remedyId);
  }

  // ==================== История ====================

  /// Получить историю просмотров
  List<LocalHistoryItem> getHistory({int limit = 20}) {
    final items = _historyBox.values.toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return items.take(limit).toList();
  }

  /// Добавить в историю
  Future<void> addToHistory(LocalHistoryItem item) async {
    // Удаляем старую запись если есть
    final existing = _historyBox.values.firstWhere(
      (i) => i.remedyId == item.remedyId,
      orElse: () => LocalHistoryItem(
        remedyId: 0,
        name: '',
        diseaseId: 0,
        diseaseName: '',
        viewedAt: DateTime.now(),
      ),
    );
    if (existing.remedyId != 0) {
      await _historyBox.delete(existing.remedyId);
    }

    // Добавляем новую запись
    await _historyBox.put(item.remedyId, item);

    // Оставляем только последние 50 записей
    final allItems = _historyBox.values.toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    if (allItems.length > 50) {
      for (var i = 50; i < allItems.length; i++) {
        await _historyBox.delete(allItems[i].remedyId);
      }
    }
  }

  /// Очистить историю
  Future<void> clearHistory() async {
    await _historyBox.clear();
  }

  /// Закрыть базу данных
  Future<void> close() async {
    await _symptomsBox.close();
    await _diseasesBox.close();
    await _evidenceLevelsBox.close();
    await _favoritesBox.close();
    await _historyBox.close();
    await _settingsBox.close();
  }
}
