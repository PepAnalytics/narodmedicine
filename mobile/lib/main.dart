import 'package:flutter/material.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация базы данных
  final databaseService = DatabaseService();
  await databaseService.init();

  // Проверка необходимости синхронизации
  if (databaseService.needsSync) {
    // Синхронизация в фоне
    final syncService = SyncService(
      baseUrl: AppConstants.apiBaseUrl,
      databaseService: databaseService,
    );
    syncService.sync().then((result) {
      if (result.success) {
        debugPrint(
          'Синхронизация успешна: ${result.symptomsCount} симптомов, ${result.diseasesCount} болезней',
        );
      } else {
        debugPrint('Ошибка синхронизации: ${result.error}');
      }
    });
  }

  runApp(NarodMedicineApp(databaseService: databaseService));
}

/// Основное приложение
class NarodMedicineApp extends StatelessWidget {
  final DatabaseService databaseService;

  const NarodMedicineApp({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Народная Медицина',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MainScreen(databaseService: databaseService),
    );
  }
}

/// Главный экран с нижней навигацией
class MainScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const MainScreen({super.key, required this.databaseService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(databaseService: widget.databaseService),
      const FavoritesScreen(),
      const HistoryScreen(),
      const AboutScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
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
