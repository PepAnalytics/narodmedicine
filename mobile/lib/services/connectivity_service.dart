import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Сервис для мониторинга подключения к интернету
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  final _connectionController = StreamController<bool>.broadcast();

  bool _isConnected = true;

  /// Поток состояния подключения
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Текущее состояние подключения
  bool get isConnected => _isConnected;

  /// Инициализация сервиса
  Future<void> init() async {
    // Проверка текущего состояния
    await _updateConnectionStatus(ConnectivityResult.none);

    // Подписка на изменения
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  /// Обновление статуса подключения
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final wasConnected = _isConnected;

    _isConnected = result != ConnectivityResult.none;

    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected);
    }
  }

  /// Проверка подключения
  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Закрыть сервис
  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
  }
}
