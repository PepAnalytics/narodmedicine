import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

/// Главный экран v2 (Warmth & Nature)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedSymptoms = [];
  List<Disease> _popularDiseases = [];
  bool _isLoadingPopular = false;
  String? _error;

  // Популярные симптомы
  final List<String> _popularSymptoms = [
    'Головная боль',
    'Температура',
    'Кашель',
    'Насморк',
  ];

  @override
  void initState() {
    super.initState();
    _loadPopularDiseases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularDiseases() async {
    setState(() => _isLoadingPopular = true);

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/diseases/popular/'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> diseasesJson = jsonData['diseases'] as List<dynamic>;
        
        setState(() {
          _popularDiseases = diseasesJson.map((json) => Disease.fromJson(json)).toList();
          _isLoadingPopular = false;
        });
      } else {
        setState(() {
          _error = 'Ошибка загрузки: ${response.statusCode}';
          _isLoadingPopular = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingPopular = false;
      });
    }
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    Navigator.pushNamed(
      context,
      '/search-results',
      arguments: {'query': query, 'symptoms': _selectedSymptoms},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDesignTokens.spacingLG),
              
              // Приветствие
              Text(
                'Как вы себя чувствуете сегодня?',
                style: const TextStyle(
                  fontSize: AppDesignTokens.fontSizeH1,
                  fontWeight: AppDesignTokens.fontWeightBold,
                  color: AppDesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingSM),
              const Text(
                'Найдите народные методы лечения с научной оценкой эффективности',
                style: TextStyle(
                  fontSize: AppDesignTokens.fontSizeBody,
                  color: AppDesignTokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingLG),

              // Поиск
              AppSearchBar(
                controller: _searchController,
                hintText: 'Введите симптомы...',
                onSearch: _handleSearch,
              ),
              const SizedBox(height: AppDesignTokens.spacingLG),

              // Популярные симптомы
              const Text(
                'Популярные симптомы',
                style: TextStyle(
                  fontSize: AppDesignTokens.fontSizeH3,
                  fontWeight: AppDesignTokens.fontWeightBold,
                  color: AppDesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingSM),
              Wrap(
                spacing: AppDesignTokens.spacingSM,
                runSpacing: AppDesignTokens.spacingSM,
                children: _popularSymptoms.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return AppChip(
                    label: symptom,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSymptoms.remove(symptom);
                        } else {
                          _selectedSymptoms.add(symptom);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDesignTokens.spacingLG),

              // Популярные болезни
              const Text(
                'Популярные болезни',
                style: TextStyle(
                  fontSize: AppDesignTokens.fontSizeH2,
                  fontWeight: AppDesignTokens.fontWeightBold,
                  color: AppDesignTokens.textPrimary,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingSM),
              
              if (_isLoadingPopular)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDesignTokens.spacingLG),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignTokens.spacingLG),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppDesignTokens.danger,
                          size: 48,
                        ),
                        const SizedBox(height: AppDesignTokens.spacingSM),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppDesignTokens.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDesignTokens.spacingMD),
                        AppButton(
                          text: 'Повторить',
                          onPressed: _loadPopularDiseases,
                          type: AppButtonType.outline,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_popularDiseases.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDesignTokens.spacingLG),
                    child: Text(
                      'Нет популярных болезней',
                      style: TextStyle(color: AppDesignTokens.textMuted),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularDiseases.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppDesignTokens.spacingMD),
                    itemBuilder: (context, index) {
                      final disease = _popularDiseases[index];
                      return SizedBox(
                        width: 280,
                        child: AppDiseaseCard(
                          disease: disease,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/disease',
                              arguments: disease,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppDesignTokens.spacingLG),

              // Мягкое предупреждение
              const AppSoftWarning(
                message: 'Перед применением рекомендуется проконсультироваться с врачом',
              ),
              const SizedBox(height: AppDesignTokens.spacingXL),
            ],
          ),
        ),
      ),
    );
  }
}
