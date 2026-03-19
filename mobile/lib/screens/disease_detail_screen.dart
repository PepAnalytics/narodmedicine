import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

/// Экран деталей заболевания с фильтрацией по регионам
class DiseaseDetailScreen extends StatefulWidget {
  final Disease disease;

  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  String? _selectedRegion;
  List<RemedyBrief> _remedies = [];
  bool _isLoading = false;
  String? _error;

  final List<MapEntry<String, String>> _regions = [
    const MapEntry('all', 'Все'),
    const MapEntry('arab', 'Арабский'),
    const MapEntry('persian', 'Персидский'),
    const MapEntry('caucasian', 'Кавказский'),
    const MapEntry('turkic', 'Тюркский'),
    const MapEntry('chinese', 'Китайский'),
    const MapEntry('indian', 'Индийский'),
    const MapEntry('other', 'Другой'),
  ];

  @override
  void initState() {
    super.initState();
    _loadRemedies();
  }

  Future<void> _loadRemedies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = _selectedRegion == null || _selectedRegion == 'all'
          ? 'http://10.0.2.2:8000/api/diseases/${widget.disease.id}/'
          : 'http://10.0.2.2:8000/api/diseases/${widget.disease.id}/?region=$_selectedRegion';

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> remediesJson = jsonData['remedies'] as List<dynamic>;

        setState(() {
          _remedies = remediesJson.map((json) => RemedyBrief.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Ошибка загрузки: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.disease.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Описание болезни
                  Text(
                    widget.disease.description,
                    style: const TextStyle(
                      fontSize: AppDesignTokens.fontSizeBody,
                      color: AppDesignTokens.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingLG),

                  // Симптомы
                  if (widget.disease.symptoms.isNotEmpty) ...[
                    const Text(
                      'Симптомы',
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
                      children: widget.disease.symptoms.map((symptom) {
                        return AppChip(
                          label: symptom.name,
                          icon: Icons.local_fire_department_outlined,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingLG),
                  ],

                  // Фильтр по регионам
                  const Text(
                    'Регион',
                    style: TextStyle(
                      fontSize: AppDesignTokens.fontSizeH3,
                      fontWeight: AppDesignTokens.fontWeightBold,
                      color: AppDesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSM),
                  SizedBox(
                    height: AppDesignTokens.chipHeight + 8,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _regions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppDesignTokens.spacingSM),
                      itemBuilder: (context, index) {
                        final region = _regions[index];
                        final isSelected = _selectedRegion == region.key;
                        return AppRegionChip(
                          label: region.value,
                          emoji: _getRegionEmoji(region.key),
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedRegion = region.key == 'all' ? null : region.key;
                            });
                            _loadRemedies();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingLG),

                  // Методы лечения
                  const Text(
                    'Методы лечения',
                    style: TextStyle(
                      fontSize: AppDesignTokens.fontSizeH2,
                      fontWeight: AppDesignTokens.fontWeightBold,
                      color: AppDesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSM),
                ],
              ),
            ),
          ),

          // Список методов
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
                  ? SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDesignTokens.spacingLG),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppDesignTokens.danger,
                                size: 64,
                              ),
                              const SizedBox(height: AppDesignTokens.spacingMD),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppDesignTokens.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppDesignTokens.spacingLG),
                              AppButton(
                                text: 'Повторить',
                                onPressed: _loadRemedies,
                                type: AppButtonType.outline,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _remedies.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'Методы не найдены',
                              style: TextStyle(color: AppDesignTokens.textMuted),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final remedy = _remedies[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDesignTokens.spacingMD,
                                  vertical: AppDesignTokens.spacingXS,
                                ),
                                child: AppRemedyCard(
                                  remedy: remedy,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/remedy',
                                      arguments: remedy.id,
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: _remedies.length,
                          ),
                        ),

          // Отступ снизу
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDesignTokens.spacingXL),
          ),
        ],
      ),
    );
  }

  String _getRegionEmoji(String? region) {
    if (region == null) return '';
    switch (region) {
      case 'arab':
        return '🇸🇦';
      case 'persian':
        return '🇮🇷';
      case 'caucasian':
        return '🏔️';
      case 'turkic':
        return '🇹🇷';
      case 'chinese':
        return '🇨🇳';
      case 'indian':
        return '🇮🇳';
      default:
        return '🌍';
    }
  }
}
