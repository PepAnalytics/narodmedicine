import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/remedy.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../widgets/evidence_level_badge.dart';

/// Экран деталей метода лечения
class RemedyDetailScreen extends StatefulWidget {
  final Remedy remedy;

  const RemedyDetailScreen({super.key, required this.remedy});

  @override
  State<RemedyDetailScreen> createState() => _RemedyDetailScreenState();
}

class _RemedyDetailScreenState extends State<RemedyDetailScreen> {
  final _apiService = ApiService();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isLikePressed = false;
  bool _isDislikePressed = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((message) {
      setState(() {
        _isSpeaking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка озвучки: $message'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakRecipe() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    } else {
      final textToSpeak =
          '${widget.remedy.name}. ${widget.remedy.description}. Рецепт: ${widget.remedy.recipe}';
      await _flutterTts.speak(textToSpeak);
    }
  }

  Future<void> _handleLike() async {
    setState(() {
      _isLikePressed = !_isLikePressed;
      if (_isLikePressed) {
        _isDislikePressed = false;
      }
    });

    await _apiService.rateRemedy(widget.remedy.id, _isLikePressed, '');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLikePressed ? 'Спасибо за лайк!' : 'Лайк удален'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDislike() async {
    setState(() {
      _isDislikePressed = !_isDislikePressed;
      if (_isDislikePressed) {
        _isLikePressed = false;
      }
    });

    await _apiService.rateRemedy(widget.remedy.id, !_isDislikePressed, '');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDislikePressed ? 'Спасибо за отзыв!' : 'Дизлайк удален',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showReviewDialog() async {
    final reviewController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оставить отзыв'),
        content: TextField(
          controller: reviewController,
          decoration: const InputDecoration(
            hintText: 'Ваш комментарий',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    if (result == true && reviewController.text.isNotEmpty) {
      await _apiService.rateRemedy(
        widget.remedy.id,
        true,
        reviewController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отзыв отправлен!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remedy = widget.remedy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Метод лечения'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
            onPressed: _speakRecipe,
            tooltip: _isSpeaking ? 'Остановить' : 'Озвучить',
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

            // Описание
            Text(
              'Описание',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              remedy.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

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
              _buildSectionCard(
                context,
                title: 'Ингредиенты',
                icon: Icons.shopping_basket,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: remedy.ingredients.map((ingredient) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
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
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Риски
            if (remedy.risks.isNotEmpty) ...[
              _buildSectionCard(
                context,
                title: 'Возможные риски',
                icon: Icons.warning_amber,
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
              icon: Icons.book,
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

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Лайк
                _buildActionButton(
                  context,
                  icon: _isLikePressed
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  label: 'Лайк',
                  onPressed: _handleLike,
                  isPressed: _isLikePressed,
                ),
                // Дизлайк
                _buildActionButton(
                  context,
                  icon: _isDislikePressed
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  label: 'Дизлайк',
                  onPressed: _handleDislike,
                  isPressed: _isDislikePressed,
                ),
                // Отзыв
                _buildActionButton(
                  context,
                  icon: Icons.rate_review,
                  label: 'Отзыв',
                  onPressed: _showReviewDialog,
                ),
              ],
            ),
            const SizedBox(height: 32),
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

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPressed = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPressed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isPressed
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
