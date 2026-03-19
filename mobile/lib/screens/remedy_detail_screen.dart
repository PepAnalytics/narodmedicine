import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/remedy.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
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
  final FlutterTts _flutterTts = FlutterTts();
  ApiService? _apiService;
  UserService? _userService;

  Remedy? _remedy;
  bool _isLoading = true;
  String? _error;

  bool _isSpeaking = false;
  bool? _userRating; // true = like, false = dislike
  int _likesCount = 0;
  int _dislikesCount = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadRemedy();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((message) {
      setState(() => _isSpeaking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка озвучки: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initServices() async {
    if (_userService == null) {
      _userService = await UserService.init();
    }
    if (_apiService == null) {
      _apiService = ApiService(
        baseUrl: AppConstants.apiBaseUrl,
        getUserId: () async => _userService?.getUserId() ?? '',
      );
    }
  }

  Future<void> _loadRemedy() async {
    await _initServices();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = _apiService!;
      final remedy = await apiService.getRemedy(widget.remedyId);

      if (mounted) {
        setState(() {
          _remedy = remedy;
          _likesCount = remedy.likesCount;
          _dislikesCount = remedy.dislikesCount;
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

  Future<void> _speakRecipe() async {
    if (_remedy == null) return;

    if (_isSpeaking) {
      await _flutterTts.stop();
    } else {
      final textToSpeak =
          '${_remedy!.name}. ${_remedy!.description}. Рецепт: ${_remedy!.recipe}';
      await _flutterTts.speak(textToSpeak);
    }
  }

  Future<void> _handleRate(bool isLike) async {
    if (_apiService == null) return;

    final newRating = _userRating == true && isLike ? null : isLike;

    try {
      final result = await _apiService!.rateRemedy(
        widget.remedyId,
        isLike,
        null,
      );

      if (mounted) {
        setState(() {
          _userRating = newRating;
          _likesCount = result['likes_count'] as int;
          _dislikesCount = result['dislikes_count'] as int;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLike ? 'Спасибо за лайк!' : 'Спасибо за отзыв!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    if (result == true && _apiService != null) {
      try {
        await _apiService!.rateRemedy(
          widget.remedyId,
          true,
          reviewController.text,
        );

        if (mounted) {
          setState(() {
            _userRating = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Отзыв отправлен!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

            // Счётчики лайков/дизлайков
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_likesCount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.thumb_down_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_dislikesCount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
              _buildSectionCard(
                context,
                title: 'Ингредиенты',
                icon: Icons.shopping_basket_outlined,
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

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Лайк
                _buildActionButton(
                  context,
                  icon: _userRating == true
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  label: 'Лайк',
                  onPressed: () => _handleRate(true),
                  isActive: _userRating == true,
                ),
                // Дизлайк
                _buildActionButton(
                  context,
                  icon: _userRating == false
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  label: 'Дизлайк',
                  onPressed: () => _handleRate(false),
                  isActive: _userRating == false,
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
    bool isActive = false,
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
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive
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
