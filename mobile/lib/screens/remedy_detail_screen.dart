import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/app_constants.dart';
import '../widgets/evidence_level_badge.dart';

/// Экран деталей метода лечения
class RemedyDetailScreen extends StatefulWidget {
  final int remedyId;

  const RemedyDetailScreen({super.key, required this.remedyId});

  @override
  State<RemedyDetailScreen> createState() => _RemedyDetailScreenState();
}

class _RemedyDetailScreenState extends State<RemedyDetailScreen> {
  Remedy? _remedy;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRemedy();
  }

  Future<void> _loadRemedy() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Загрузка из API или кэша
      final db = DatabaseService();
      await db.init();

      final cached = db.getRemedyById(widget.remedyId);
      if (cached != null) {
        setState(() {
          _remedy = Remedy(
            id: cached.id,
            name: cached.name,
            description: cached.description,
            recipe: cached.recipe,
            risks: cached.risks,
            source: cached.source,
            evidenceLevel: EvidenceLevel(
              id: cached.evidenceLevelId,
              code: 'B',
              description: 'Средний',
              color: '#FFC107',
              rank: 2,
            ),
            likesCount: cached.likesCount,
            dislikesCount: cached.dislikesCount,
            region: cached.region,
            culturalContext: cached.culturalContext,
          );
          _isLoading = false;
        });
        return;
      }

      final apiService = ApiService(
        baseUrl: AppConstants.apiBaseUrl,
        getUserId: () async => '',
      );
      final remedy = await apiService.getRemedy(widget.remedyId);

      if (mounted) {
        setState(() {
          _remedy = remedy;
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

  Future<void> _shareRemedy() async {
    if (_remedy == null) return;

    final shareText =
        '''
${_remedy!.name}

${_remedy!.description}

📝 Рецепт:
${_remedy!.recipe}

🛒 Ингредиенты:
${_remedy!.ingredients.map((i) => '• ${i.name}${i.amount != null ? ' (${i.amount})' : ''}').join('\n')}

${_remedy!.risks.isNotEmpty ? '⚠️ Риски:\n${_remedy!.risks}' : ''}

Источник: ${_remedy!.source}
''';

    await Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Метод лечения')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Метод лечения')),
        body: Center(
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
                  onPressed: _loadRemedy,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final remedy = _remedy!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Метод лечения'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRemedy,
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и уровень доказательности
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    remedy.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                EvidenceLevelBadge(level: remedy.evidenceLevel),
              ],
            ),
            const SizedBox(height: 16),

            // Регион и культурный контекст
            if (remedy.region.isNotEmpty || remedy.culturalContext != null) ...[
              _buildRegionCard(context, remedy),
              const SizedBox(height: 16),
            ],

            // Описание
            _buildSectionCard(
              context,
              title: 'Описание',
              icon: Icons.description_outlined,
              child: Text(
                remedy.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),

            // Рецепт
            _buildSectionCard(
              context,
              title: 'Рецепт',
              icon: Icons.restaurant_menu,
              child: Text(
                remedy.recipe,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),

            // Ингредиенты
            if (remedy.ingredients.isNotEmpty) ...[
              _buildIngredientsCard(context, remedy),
              const SizedBox(height: 16),
            ],

            // Риски
            if (remedy.risks.isNotEmpty) ...[
              _buildSectionCard(
                context,
                title: 'Возможные риски',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                child: Text(
                  remedy.risks,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.deepOrange.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Источник
            _buildSectionCard(
              context,
              title: 'Источник',
              icon: Icons.book_outlined,
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remedy.source,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionCard(BuildContext context, Remedy remedy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getRegionEmoji(remedy.region),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  _getRegionName(remedy.region),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (remedy.culturalContext != null &&
                remedy.culturalContext!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                remedy.culturalContext!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsCard(BuildContext context, Remedy remedy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ингредиенты',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...remedy.ingredients.map((ingredient) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ingredient.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        if (ingredient.amount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ingredient.amount!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    // Альтернативные названия
                    if (ingredient.alternativeNames != null &&
                        ingredient.alternativeNames!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Wrap(
                          spacing: 6,
                          children: ingredient.alternativeNames!.entries.map((
                            entry,
                          ) {
                            return Chip(
                              label: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String _getRegionName(String region) {
    switch (region.toLowerCase()) {
      case 'arab':
        return 'Арабский';
      case 'persian':
        return 'Персидский';
      case 'caucasian':
        return 'Кавказский';
      case 'turkic':
        return 'Тюркский';
      case 'chinese':
        return 'Китайский';
      case 'indian':
        return 'Индийский (Аюрведа)';
      default:
        return 'Другой';
    }
  }

  String _getRegionEmoji(String region) {
    switch (region.toLowerCase()) {
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
