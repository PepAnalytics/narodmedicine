import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../models/remedy.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../widgets/remedy_card.dart';

/// Экран деталей заболевания
class DiseaseDetailScreen extends StatefulWidget {
  final Disease disease;

  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  final _apiService = ApiService();
  List<Remedy> _remedies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRemedies();
  }

  Future<void> _loadRemedies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final remedies = await _apiService.getRemediesForDisease(
        widget.disease.id,
      );
      if (mounted) {
        setState(() {
          _remedies = remedies;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки методов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Описание болезни
                  Text(
                    'Описание',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.disease.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Симптомы
                  if (widget.disease.symptoms.isNotEmpty) ...[
                    Text(
                      'Симптомы',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.disease.symptoms.map((symptom) {
                        return Chip(
                          label: Text(symptom.name),
                          avatar: const Icon(
                            Icons.local_fire_department,
                            size: 18,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Методы лечения
                  Text(
                    'Методы лечения',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_remedies.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.healing_outlined,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Методы лечения не найдены',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _remedies.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final remedy = _remedies[index];
                        return RemedyCard(
                          remedy: remedy,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.remedyDetailRoute,
                              arguments: remedy,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
