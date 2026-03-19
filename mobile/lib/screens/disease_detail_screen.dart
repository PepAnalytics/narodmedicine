import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
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
  ApiService? _apiService;
  UserService? _userService;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _userService = await UserService.init();
    setState(() {});
    _loadRemedies();
  }

  ApiService _getApiService() {
    if (_apiService == null) {
      _apiService = ApiService(
        baseUrl: AppConstants.apiBaseUrl,
        getUserId: () async => _userService?.getUserId() ?? '',
      );
    }
    return _apiService!;
  }

  Future<void> _loadRemedies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = _getApiService();
      await apiService.getDisease(widget.disease.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Для Sprint 1 используем моковые данные, но с реальной структурой
    // В следующем спринте заменим на реальные данные из API
    final mockRemedies = [
      RemedyBrief(
        id: 1,
        name: 'Чай с медом и лимоном',
        shortDescription: 'Классическое народное средство при простуде.',
        evidenceLevel: widget.disease.id == 1
            ? const EvidenceLevel(
                id: 1,
                code: 'B',
                description: 'Средний',
                color: '#FFC107',
                rank: 2,
              )
            : widget.disease.id == 2
            ? const EvidenceLevel(
                id: 2,
                code: 'A',
                description: 'Высокий',
                color: '#4CAF50',
                rank: 1,
              )
            : const EvidenceLevel(
                id: 3,
                code: 'C',
                description: 'Низкий',
                color: '#F44336',
                rank: 3,
              ),
        likesCount: 42,
        dislikesCount: 5,
      ),
      RemedyBrief(
        id: 2,
        name: 'Ингаляция с эвкалиптом',
        shortDescription: 'Помогает при заложенности носа и кашле.',
        evidenceLevel: const EvidenceLevel(
          id: 2,
          code: 'A',
          description: 'Высокий',
          color: '#4CAF50',
          rank: 1,
        ),
        likesCount: 38,
        dislikesCount: 3,
      ),
      RemedyBrief(
        id: 3,
        name: 'Компресс из капусты',
        shortDescription: 'Народное средство при кашле и бронхите.',
        evidenceLevel: const EvidenceLevel(
          id: 3,
          code: 'C',
          description: 'Низкий',
          color: '#F44336',
          rank: 3,
        ),
        likesCount: 15,
        dislikesCount: 8,
      ),
    ];

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
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadRemedies,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
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
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mockRemedies.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final remedy = mockRemedies[index];
                      return RemedyCard(
                        remedy: remedy,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.remedyDetailRoute,
                            arguments: remedy.id,
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
