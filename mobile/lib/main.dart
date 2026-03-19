import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Инициализация Firebase
  // await Firebase.initializeApp();

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
      home: const HomeScreen(),
    );
  }
}

/// Временный главный экран для демонстрации темы
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Народная Медицина'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            const Text(
              'Добро пожаловать',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1F1D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Найдите народные методы лечения по симптомам',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5F6B66),
              ),
            ),
            const SizedBox(height: 24),

            // SearchBar
            const Text(
              'SearchBar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const AppSearchBar(
              hintText: 'Введите симптомы...',
            ),
            const SizedBox(height: 24),

            // Кнопки
            const Text(
              'Кнопки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            AppButton(
              text: 'Primary Button',
              onPressed: () {},
              type: AppButtonType.primary,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Secondary Button',
              onPressed: () {},
              type: AppButtonType.secondary,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Outline Button',
              onPressed: () {},
              type: AppButtonType.outline,
            ),
            const SizedBox(height: 24),

            // Evidence Badge
            const Text(
              'Evidence Badges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppEvidenceBadge(code: 'A'),
                AppEvidenceBadge(code: 'B'),
                AppEvidenceBadge(code: 'C'),
                AppEvidenceBadge(code: 'D'),
                AppEvidenceBadge(code: 'E'),
              ],
            ),
            const SizedBox(height: 24),

            // Chips
            const Text(
              'Chips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppChip(label: 'Головная боль'),
                AppChip(label: 'Температура', isSelected: true),
                AppChip(label: 'Кашель'),
                AppChip(label: 'Насморк'),
              ],
            ),
            const SizedBox(height: 24),

            // Region Chips
            const Text(
              'Region Chips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppRegionChip(label: 'Все', isSelected: true),
                AppRegionChip(label: 'Арабский', emoji: '🇸🇦'),
                AppRegionChip(label: 'Индийский', emoji: '🇮🇳'),
                AppRegionChip(label: 'Китайский', emoji: '🇨🇳'),
              ],
            ),
            const SizedBox(height: 24),

            // Warning Block
            const Text(
              'Warning Block',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const AppWarningBlock(
              title: 'Важное предупреждение',
              message:
                  'Данное приложение не ставит диагноз и не заменяет консультацию врача.',
            ),
          ],
        ),
      ),
    );
  }
}
