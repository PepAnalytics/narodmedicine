import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../utils/app_constants.dart';

/// Виджет карточки заболевания в списке
class DiseaseCard extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const DiseaseCard({super.key, required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      disease.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (disease.matchScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        disease.matchScore!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                disease.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (disease.symptoms.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: disease.symptoms.take(3).map((symptom) {
                    return Chip(
                      label: Text(
                        symptom.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
