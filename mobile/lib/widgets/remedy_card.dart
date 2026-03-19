import 'package:flutter/material.dart';
import '../models/remedy.dart';
import '../utils/app_constants.dart';
import 'evidence_level_badge.dart';

/// Виджет карточки метода лечения в списке
class RemedyCard extends StatelessWidget {
  final RemedyBrief remedy;
  final VoidCallback onTap;

  const RemedyCard({super.key, required this.remedy, required this.onTap});

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
                      remedy.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  EvidenceLevelBadge(level: remedy.evidenceLevel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                remedy.shortDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatIcon(
                    context,
                    Icons.thumb_up_outlined,
                    remedy.likesCount.toString(),
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildStatIcon(
                    context,
                    Icons.thumb_down_outlined,
                    remedy.dislikesCount.toString(),
                    Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
