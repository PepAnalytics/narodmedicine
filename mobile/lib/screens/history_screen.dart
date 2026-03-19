import 'package:flutter/material.dart';
import '../models/local/local.dart';
import '../services/services.dart';

/// Экран истории просмотров
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryService _historyService;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _databaseService = DatabaseService();
    _historyService = HistoryService(databaseService: _databaseService);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        centerTitle: true,
        actions: [
          if (_historyService.getHistory().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearDialog(),
              tooltip: 'Очистить историю',
            ),
        ],
      ),
      body: StreamBuilder(
        stream: _historyService.changes,
        builder: (context, snapshot) {
          final history = _historyService.getHistory();

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'История пуста',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Просмотренные методы\nпоявятся здесь',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryItem(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(LocalHistoryItem item) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(item.name),
      subtitle: Text(item.diseaseName),
      trailing: Text(
        _formatTime(item.viewedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        // Переход к деталям метода
        // Navigator.pushNamed(context, AppConstants.remedyDetailRoute, arguments: item.remedyId);
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _historyService.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
