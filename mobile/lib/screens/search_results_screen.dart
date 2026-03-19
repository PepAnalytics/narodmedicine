import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_design_tokens.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

/// Экран результатов поиска
class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<String>? symptoms;

  const SearchResultsScreen({super.key, required this.query, this.symptoms});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Disease> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final symptoms = widget.symptoms?.isNotEmpty == true
          ? widget.symptoms
          : widget.query.split(',').map((s) => s.trim()).toList();

      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:8000/api/search/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'symptoms': symptoms}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> diseasesJson =
            jsonData['diseases'] as List<dynamic>;

        setState(() {
          _results = diseasesJson
              .map((json) => Disease.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Ошибка поиска: ${response.statusCode}';
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
        title: const Text('Результаты поиска'),
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
                      onPressed: _search,
                      type: AppButtonType.outline,
                    ),
                  ],
                ),
              ),
            )
          : _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppDesignTokens.textMuted,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingMD),
                  const Text(
                    'Ничего не найдено',
                    style: TextStyle(
                      fontSize: AppDesignTokens.fontSizeH3,
                      fontWeight: AppDesignTokens.fontWeightBold,
                      color: AppDesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSM),
                  const Text(
                    'Попробуйте изменить запрос',
                    style: TextStyle(color: AppDesignTokens.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDesignTokens.spacingMD),
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDesignTokens.spacingMD),
              itemBuilder: (context, index) {
                final disease = _results[index];
                final score = disease.matchScore ?? 0.0;
                return AppDiseaseCard(
                  disease: disease,
                  score: score,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/disease',
                      arguments: disease,
                    );
                  },
                );
              },
            ),
    );
  }
}
