import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Сервис для управления идентификатором пользователя
class UserService {
  static const String _userIdKey = 'user_id';
  final SharedPreferences _prefs;

  UserService(this._prefs);

  /// Инициализация сервиса
  static Future<UserService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return UserService(prefs);
  }

  /// Получить ID пользователя (создать новый если не существует)
  Future<String> getUserId() async {
    String? userId = _prefs.getString(_userIdKey);
    if (userId == null || userId.isEmpty) {
      userId = const Uuid().v4();
      await _prefs.setString(_userIdKey, userId);
    }
    return userId;
  }

  /// Очистить ID пользователя (для тестирования)
  Future<void> clearUserId() async {
    await _prefs.remove(_userIdKey);
  }
}
