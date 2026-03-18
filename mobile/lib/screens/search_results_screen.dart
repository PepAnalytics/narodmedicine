import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../utils/app_constants.dart';
import '../widgets/disease_card.dart';

/// Экран результатов поиска заболеваний
class SearchResultsScreen extends StatelessWidget {
  final List<Disease> diseases;

  const SearchResultsScreen({super.key, required this.diseases});

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
      body: diseases.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ничего не найдено',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуйте изменить запрос',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: diseases.length,
              itemBuilder: (context, index) {
                final disease = diseases[index];
                return DiseaseCard(
                  disease: disease,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppConstants.diseaseDetailRoute,
                      arguments: disease,
                    );
                  },
                );
              },
            ),
    );
  }
}
