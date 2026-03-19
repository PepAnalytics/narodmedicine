import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase
  await Firebase.initializeApp();
  final analytics = FirebaseAnalytics.instance;

  // Инициализация базы данных
  final databaseService = DatabaseService();
  await databaseService.init();

  // Проверка необходимости синхронизации
  if (databaseService.needsSync) {
    final syncService = SyncService(
      baseUrl: AppConstants.apiBaseUrl,
      databaseService: databaseService,
    );
    syncService.sync().then((result) {
      if (result.success) {
        debugPrint(
          'Синхронизация: ${result.symptomsCount} симптомов, ${result.diseasesCount} болезней',
        );
        analytics.logEvent(name: 'sync_success');
      } else {
        debugPrint('Ошибка синхронизации: ${result.error}');
        analytics.logEvent(name: 'sync_error');
      }
    });
  }

  // Кэширование юридических документов
  final legalService = LegalService(
    baseUrl: AppConstants.apiBaseUrl,
    databaseService: databaseService,
  );
  legalService.cacheLegalDocuments().catchError(
    (e) => debugPrint('Error caching legal: $e'),
  );

  runApp(
    NarodMedicineApp(databaseService: databaseService, analytics: analytics),
  );
}

class NarodMedicineApp extends StatelessWidget {
  final DatabaseService databaseService;
  final FirebaseAnalytics analytics;

  const NarodMedicineApp({
    super.key,
    required this.databaseService,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Народная Медицина',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MainScreen(databaseService: databaseService, analytics: analytics),
    );
  }
}

class MainScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final FirebaseAnalytics analytics;

  const MainScreen({
    super.key,
    required this.databaseService,
    required this.analytics,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  bool _needsConsent = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(databaseService: widget.databaseService),
      const FavoritesScreen(),
      const HistoryScreen(),
      AboutScreen(databaseService: widget.databaseService),
    ];
    _checkConsent();
    _initConnectivity();
  }

  Future<void> _checkConsent() async {
    final needs =
        await widget.databaseService.needsSync; // TODO: proper consent check
    setState(() => _needsConsent = needs);
  }

  Future<void> _initConnectivity() async {
    final connectivityService = ConnectivityService();
    await connectivityService.init();
    setState(() => _isOffline = !connectivityService.isConnected);

    connectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() => _isOffline = !isConnected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Офлайн-режим',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          widget.analytics.logScreenView(screenName: 'tab_$index');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Поиск',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'История',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'О приложении',
          ),
        ],
      ),
    );
  }
}
