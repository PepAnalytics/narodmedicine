import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

/// Экран избранных методов
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<RemedyBrief> _favorites = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Интеграция с API GET /api/favorites/
      // Пока используем моковые данные
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _favorites = [];
        _isLoading = false;
      });
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
      appBar: AppBar(title: const Text('Избранное')),
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
                      onPressed: _loadFavorites,
                      type: AppButtonType.outline,
                    ),
                  ],
                ),
              ),
            )
          : _favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppDesignTokens.textMuted,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMD),
                  const Text(
                    'Нет избранных методов',
                    style: TextStyle(
                      fontSize: AppDesignTokens.fontSizeH3,
                      fontWeight: AppDesignTokens.fontWeightBold,
                      color: AppDesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSM),
                  const Text(
                    'Добавляйте методы в избранное,\nчтобы они появились здесь',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppDesignTokens.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
              itemCount: _favorites.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDesignTokens.spacingMD),
              itemBuilder: (context, index) {
                final remedy = _favorites[index];
                return AppRemedyCard(
                  remedy: remedy,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/remedy',
                      arguments: remedy.id,
                    );
                  },
                );
              },
            ),
    );
  }
}
