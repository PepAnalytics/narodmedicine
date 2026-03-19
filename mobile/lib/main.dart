import 'package:flutter/material.dart';
import 'models/models.dart';
import 'screens/screens.dart';
import 'utils/utils.dart';

void main() {
  runApp(const NarodMedicineApp());
}

/// Основное приложение
class NarodMedicineApp extends StatelessWidget {
  const NarodMedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Народная Медицина',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppConstants.homeRoute,
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppConstants.searchResultsRoute:
        final diseases = settings.arguments as List<Disease>;
        return MaterialPageRoute(
          builder: (_) => SearchResultsScreen(diseases: diseases),
        );
      case AppConstants.diseaseDetailRoute:
        final disease = settings.arguments as Disease;
        return MaterialPageRoute(
          builder: (_) => DiseaseDetailScreen(disease: disease),
        );
      case AppConstants.remedyDetailRoute:
        final remedyId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => RemedyDetailScreen(remedyId: remedyId),
        );
      case AppConstants.aboutRoute:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Экран не найден: ${settings.name}')),
          ),
        );
    }
  }
}
