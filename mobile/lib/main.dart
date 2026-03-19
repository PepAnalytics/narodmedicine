import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'widgets/widgets.dart';
import 'screens/screens.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NarodMedicineApp());
}

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
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case '/search-results':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => SearchResultsScreen(
            query: args['query'] as String,
            symptoms: args['symptoms'] as List<String>?,
          ),
        );
      
      case '/disease':
        final disease = settings.arguments as Disease;
        return MaterialPageRoute(
          builder: (_) => DiseaseDetailScreen(disease: disease),
        );
      
      case '/remedy':
        final remedyId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => RemedyDetailScreen(remedyId: remedyId),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Экран не найден: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
