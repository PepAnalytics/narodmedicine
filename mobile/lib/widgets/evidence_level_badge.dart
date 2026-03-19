import 'package:flutter/material.dart';
import '../models/evidence_level.dart';

/// Виджет отображения уровня доказательности
class EvidenceLevelBadge extends StatelessWidget {
  final EvidenceLevel level;
  final bool showLabel;

  const EvidenceLevelBadge({
    super.key,
    required this.level,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = level.colorValue;
    final backgroundColor = color.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconForLevel(level), color: color, size: 16),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              level.name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconForLevel(EvidenceLevel level) {
    switch (level.code.toUpperCase()) {
      case 'A':
        return Icons.star;
      case 'B':
        return Icons.star_half;
      case 'C':
        return Icons.star_outline;
      default:
        return Icons.help_outline;
    }
  }
}
