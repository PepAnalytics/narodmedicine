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
  static const String _remediesBoxName = 'remedies';
  static const String _ingredientsBoxName = 'ingredients';
  static const String _legalBoxName = 'legal';

  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _isInitializedKey = 'is_initialized';
  static const String _consentGivenKey = 'consent_given';
  static const String _consentVersionKey = 'consent_version';

  late Box<LocalSymptom> _symptomsBox;
  late Box<LocalDisease> _diseasesBox;
  late Box<LocalEvidenceLevel> _evidenceLevelsBox;
  late Box<LocalFavorite> _favoritesBox;
  late Box<LocalHistoryItem> _historyBox;
  late Box<dynamic> _settingsBox;
  late Box<LocalRemedy> _remediesBox;
  late Box<LocalIngredient> _ingredientsBox;
  late Box<LegalDocument> _legalBox;

  /// Инициализация базы данных
  Future<void> init() async {
    await Hive.initFlutter();

    // Регистрация адаптеров
    Hive.registerAdapter(LocalSymptomAdapter());
    Hive.registerAdapter(LocalDiseaseAdapter());
    Hive.registerAdapter(LocalEvidenceLevelAdapter());
    Hive.registerAdapter(LocalFavoriteAdapter());
    Hive.registerAdapter(LocalHistoryItemAdapter());
    Hive.registerAdapter(LocalRemedyAdapter());
    Hive.registerAdapter(LocalIngredientAdapter());
    Hive.registerAdapter(LegalDocumentAdapter());

    // Открытие боксов
    _symptomsBox = await Hive.openBox<LocalSymptom>(_symptomsBoxName);
    _diseasesBox = await Hive.openBox<LocalDisease>(_diseasesBoxName);
    _evidenceLevelsBox = await Hive.openBox<LocalEvidenceLevel>(
      _evidenceLevelsBoxName,
    );
    _favoritesBox = await Hive.openBox<LocalFavorite>(_favoritesBoxName);
    _historyBox = await Hive.openBox<LocalHistoryItem>(_historyBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _remediesBox = await Hive.openBox<LocalRemedy>(_remediesBoxName);
    _ingredientsBox = await Hive.openBox<LocalIngredient>(_ingredientsBoxName);
    _legalBox = await Hive.openBox<LegalDocument>(_legalBoxName);
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

  // ==================== Согласие на юридические документы ====================

  /// Проверка, дано ли согласие
  bool get hasConsent =>
      _settingsBox.get(_consentGivenKey, defaultValue: false) as bool;

  /// Получить версию согласия
  String? get consentVersion => _settingsBox.get(_consentVersionKey) as String?;

  /// Установить согласие
  Future<void> setConsent(String version) async {
    await _settingsBox.put(_consentGivenKey, true);
    await _settingsBox.put(_consentVersionKey, version);
  }

  /// Сбросить согласие
  Future<void> clearConsent() async {
    await _settingsBox.put(_consentGivenKey, false);
    await _settingsBox.put(_consentVersionKey, null);
  }

  // ==================== Симптомы ====================

  List<LocalSymptom> getAllSymptoms() => _symptomsBox.values.toList();

  Future<void> saveSymptoms(List<LocalSymptom> symptoms) async {
    await _symptomsBox.clear();
    for (final symptom in symptoms) {
      await _symptomsBox.put(symptom.id, symptom);
    }
  }

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

  List<LocalDisease> getAllDiseases() => _diseasesBox.values.toList();

  Future<void> saveDiseases(List<LocalDisease> diseases) async {
    await _diseasesBox.clear();
    for (final disease in diseases) {
      await _diseasesBox.put(disease.id, disease);
    }
  }

  LocalDisease? getDiseaseById(int id) => _diseasesBox.get(id);

  // ==================== Уровни доказательности ====================

  List<LocalEvidenceLevel> getAllEvidenceLevels() =>
      _evidenceLevelsBox.values.toList();

  Future<void> saveEvidenceLevels(List<LocalEvidenceLevel> levels) async {
    await _evidenceLevelsBox.clear();
    for (final level in levels) {
      await _evidenceLevelsBox.put(level.id, level);
    }
  }

  // ==================== Избранное ====================

  List<LocalFavorite> getAllFavorites() =>
      _favoritesBox.values.toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  Future<void> addFavorite(LocalFavorite favorite) async {
    await _favoritesBox.put(favorite.remedyId, favorite);
  }

  Future<void> removeFavorite(int remedyId) async {
    await _favoritesBox.delete(remedyId);
  }

  bool isFavorite(int remedyId) => _favoritesBox.containsKey(remedyId);

  // ==================== История ====================

  List<LocalHistoryItem> getHistory({int limit = 20}) {
    final items = _historyBox.values.toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return items.take(limit).toList();
  }

  Future<void> addToHistory(LocalHistoryItem item) async {
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
    await _historyBox.put(item.remedyId, item);

    final allItems = _historyBox.values.toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    if (allItems.length > AppConstants.maxHistoryItems) {
      for (var i = AppConstants.maxHistoryItems; i < allItems.length; i++) {
        await _historyBox.delete(allItems[i].remedyId);
      }
    }
  }

  Future<void> clearHistory() async => await _historyBox.clear();

  // ==================== Методы лечения ====================

  List<LocalRemedy> getAllRemedies() => _remediesBox.values.toList();

  Future<void> saveRemedies(List<LocalRemedy> remedies) async {
    await _remediesBox.clear();
    for (final remedy in remedies) {
      await _remediesBox.put(remedy.id, remedy);
    }
  }

  LocalRemedy? getRemedyById(int id) => _remediesBox.get(id);

  List<LocalRemedy> getRemediesByDisease(int diseaseId) {
    return _remediesBox.values.where((r) => r.diseaseId == diseaseId).toList();
  }

  List<LocalRemedy> getRemediesByRegion(String region) {
    return _remediesBox.values.where((r) => r.region == region).toList();
  }

  // ==================== Ингредиенты ====================

  List<LocalIngredient> getAllIngredients() => _ingredientsBox.values.toList();

  Future<void> saveIngredients(List<LocalIngredient> ingredients) async {
    await _ingredientsBox.clear();
    for (final ingredient in ingredients) {
      await _ingredientsBox.put(ingredient.id, ingredient);
    }
  }

  LocalIngredient? getIngredientById(int id) => _ingredientsBox.get(id);

  // ==================== Юридические документы ====================

  Future<void> saveLegalDocument(LegalDocument document) async {
    await _legalBox.put(document.type, document);
  }

  LegalDocument? getLegalDocument(String type) => _legalBox.get(type);

  LegalDocument? getCachedTerms() => _legalBox.get('terms_of_service');

  LegalDocument? getCachedPrivacy() => _legalBox.get('privacy_policy');

  /// Закрыть базу данных
  Future<void> close() async {
    await _symptomsBox.close();
    await _diseasesBox.close();
    await _evidenceLevelsBox.close();
    await _favoritesBox.close();
    await _historyBox.close();
    await _settingsBox.close();
    await _remediesBox.close();
    await _ingredientsBox.close();
    await _legalBox.close();
  }
}
