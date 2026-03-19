import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

/// Экран истории просмотров
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Интеграция с API GET /api/history/
      // Пока используем моковые данные
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _history = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Очистить',
              style: TextStyle(color: AppDesignTokens.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _history = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Очистить историю',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
                      onPressed: _loadHistory,
                      type: AppButtonType.outline,
                    ),
                  ],
                ),
              ),
            )
          : _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: AppDesignTokens.textMuted,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMD),
                  const Text(
                    'История пуста',
                    style: TextStyle(
                      fontSize: AppDesignTokens.fontSizeH3,
                      fontWeight: AppDesignTokens.fontWeightBold,
                      color: AppDesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSM),
                  const Text(
                    'Просмотренные методы\nпоявятся здесь',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppDesignTokens.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
              itemCount: _history.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDesignTokens.spacingSM),
              itemBuilder: (context, index) {
                final item = _history[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.history,
                      color: AppDesignTokens.primaryGreen,
                    ),
                    title: Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                        fontSize: AppDesignTokens.fontSizeBody,
                        fontWeight: AppDesignTokens.fontWeightMedium,
                        color: AppDesignTokens.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item['disease_name'] ?? '',
                      style: const TextStyle(
                        fontSize: AppDesignTokens.fontSizeSmall,
                        color: AppDesignTokens.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      _formatTime(item['viewed_at']),
                      style: const TextStyle(
                        fontSize: AppDesignTokens.fontSizeCaption,
                        color: AppDesignTokens.textMuted,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/remedy',
                        arguments: item['remedy_id'],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(dynamic viewedAt) {
    // TODO: Форматирование времени
    return 'Недавно';
  }
}
