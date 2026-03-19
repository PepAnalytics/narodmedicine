import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

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
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/remedies/${widget.remedyId}/'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        setState(() {
          _remedy = Remedy.fromJson(jsonData);
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

  Future<void> _shareRemedy() async {
    if (_remedy == null) return;

    final shareText = '''
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

    if (_error != null || _remedy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Метод лечения')),
        body: Center(
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
                  _error ?? 'Метод не найден',
                  style: const TextStyle(color: AppDesignTokens.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesignTokens.spacingLG),
                AppButton(
                  text: 'Повторить',
                  onPressed: _loadRemedy,
                  type: AppButtonType.outline,
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
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareRemedy,
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок + EvidenceBadge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    remedy.name,
                    style: const TextStyle(
                      fontSize: AppDesignTokens.fontSizeH1,
                      fontWeight: AppDesignTokens.fontWeightBold,
                      color: AppDesignTokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppDesignTokens.spacingSM),
                AppEvidenceBadge(code: remedy.evidenceLevel.code),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLG),

            // Блок культуры
            if (remedy.region.isNotEmpty || remedy.culturalContext != null) ...[
              _buildCultureCard(remedy),
              const SizedBox(height: AppDesignTokens.spacingLG),
            ],

            // Описание
            _buildSection(
              icon: Icons.description_outlined,
              title: 'Описание',
              child: Text(
                remedy.description,
                style: const TextStyle(
                  fontSize: AppDesignTokens.fontSizeBody,
                  color: AppDesignTokens.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMD),

            // Рецепт
            _buildSection(
              icon: Icons.restaurant_menu,
              title: 'Рецепт',
              child: Text(
                remedy.recipe,
                style: const TextStyle(
                  fontSize: AppDesignTokens.fontSizeBody,
                  color: AppDesignTokens.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingMD),

            // Ингредиенты
            if (remedy.ingredients.isNotEmpty) ...[
              _buildSection(
                icon: Icons.shopping_basket_outlined,
                title: 'Ингредиенты',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: remedy.ingredients.map((ingredient) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingXS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: AppDesignTokens.iconSizeSmall,
                            color: AppDesignTokens.success,
                          ),
                          const SizedBox(width: AppDesignTokens.spacingSM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ingredient.name,
                                  style: const TextStyle(
                                    fontSize: AppDesignTokens.fontSizeBody,
                                    color: AppDesignTokens.textPrimary,
                                    fontWeight: AppDesignTokens.fontWeightMedium,
                                  ),
                                ),
                                // Альтернативные названия
                                if (ingredient.alternativeNames != null &&
                                    ingredient.alternativeNames!.isNotEmpty) ...[
                                  const SizedBox(height: AppDesignTokens.spacingXS),
                                  Wrap(
                                    spacing: AppDesignTokens.spacingXS,
                                    runSpacing: AppDesignTokens.spacingXS,
                                    children: ingredient.alternativeNames!.entries.map((entry) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDesignTokens.spacingSM,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppDesignTokens.bgMuted,
                                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSM),
                                        ),
                                        child: Text(
                                          '${entry.key}: ${entry.value}',
                                          style: const TextStyle(
                                            fontSize: AppDesignTokens.fontSizeCaption,
                                            color: AppDesignTokens.textMuted,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (ingredient.amount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDesignTokens.spacingSM,
                                vertical: AppDesignTokens.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesignTokens.lightGreen,
                                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSM),
                              ),
                              child: Text(
                                ingredient.amount!,
                                style: const TextStyle(
                                  fontSize: AppDesignTokens.fontSizeCaption,
                                  fontWeight: AppDesignTokens.fontWeightBold,
                                  color: AppDesignTokens.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMD),
            ],

            // Риски
            if (remedy.risks.isNotEmpty) ...[
              _buildSection(
                icon: Icons.warning_amber_outlined,
                title: 'Возможные риски',
                child: Text(
                  remedy.risks,
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeBody,
                    color: AppDesignTokens.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMD),
            ],

            // Источник
            _buildSection(
              icon: Icons.book_outlined,
              title: 'Источник',
              child: Row(
                children: [
                  const Icon(
                    Icons.link,
                    size: AppDesignTokens.iconSizeSmall,
                    color: AppDesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: AppDesignTokens.spacingSM),
                  Expanded(
                    child: Text(
                      remedy.source,
                      style: const TextStyle(
                        fontSize: AppDesignTokens.fontSizeBody,
                        color: AppDesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingXL),

            // Warning Block - дисклеймер
            const AppWarningBlock(
              title: 'Важное предупреждение',
              message: 'Данное приложение не ставит диагноз и не заменяет консультацию врача. Все материалы носят ознакомительный характер.',
            ),
            const SizedBox(height: AppDesignTokens.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildCultureCard(Remedy remedy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getRegionEmoji(remedy.region),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: AppDesignTokens.spacingSM),
                Text(
                  _getRegionName(remedy.region),
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeH3,
                    fontWeight: AppDesignTokens.fontWeightBold,
                    color: AppDesignTokens.textPrimary,
                  ),
                ),
              ],
            ),
            if (remedy.culturalContext != null && remedy.culturalContext!.isNotEmpty) ...[
              const SizedBox(height: AppDesignTokens.spacingSM),
              Text(
                remedy.culturalContext!,
                style: const TextStyle(
                  fontSize: AppDesignTokens.fontSizeBody,
                  color: AppDesignTokens.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppDesignTokens.primaryGreen,
                  size: AppDesignTokens.iconSizeMedium,
                ),
                const SizedBox(width: AppDesignTokens.spacingSM),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDesignTokens.fontSizeH3,
                    fontWeight: AppDesignTokens.fontWeightBold,
                    color: AppDesignTokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingSM),
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
